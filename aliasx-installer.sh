#!/usr/bin/env bash

# AliasX Installer - Enhanced Bash Aliases with Parameters
# Version: 1.2.4

### Configuration
readonly ALIAS_FILE="${HOME}/.aliasx_aliases"
readonly LOADER_FILE="${HOME}/.aliasx_loader"
readonly UNINSTALLER_FILE="${HOME}/.aliasx_uninstaller"
readonly VERSION="1.2.4"
readonly BACKUP_EXT=".bak"
readonly GITHUB_URL="https://raw.githubusercontent.com/wqttzicue/AliasX/experimental/aliasx-installer.sh"
readonly SUPPORTED_SHELLS=(
    "${HOME}/.bashrc"
    "${HOME}/.zshrc"
    "${HOME}/.bash_profile"
    "${HOME}/.zprofile"
    "${HOME}/.zshrc.local"
)

### Logging Utilities
print_error() {
    printf "\033[1;31mError:\033[0m %s\n" "$1" >&2
}

print_success() {
    printf "\033[1;32mSuccess:\033[0m %s\n" "$1"
}

print_info() {
    printf "\033[1;34mInfo:\033[0m %s\n" "$1"
}

print_warning() {
    printf "\033[1;33mWarning:\033[0m %s\n" "$1"
}

### File Management
create_backup() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    if ! cp -f "$file" "${file}${BACKUP_EXT}"; then
        print_error "Failed to create backup for ${file}"
        return 1
    fi
}

### Installation Components
install_loader() {
    create_backup "$LOADER_FILE" || return 1

    cat > "$LOADER_FILE" <<'LOADER_EOF'
#!/usr/bin/env bash
# AliasX Loader v1.2.4

readonly ALIAS_FILE="${HOME}/.aliasx_aliases"
readonly VERSION="1.2.4"

aliasx_error() {
    printf "\033[1;31mAliasX Error:\033[0m %s\n" "$1" >&2
    return 1
}

safe_eval() {
    local cmd="$1"
    [[ "$cmd" =~ ^[[:space:]]*$ ]] && {
        aliasx_error "Empty command"
        return 1
    }
    eval "$cmd"
}

validate_alias_name() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        aliasx_error "Invalid alias name: '$1'. Must start with letter/underscore and contain only alphanumerics."
        return 1
    }
}

load_aliases() {
    [[ -f "$ALIAS_FILE" ]] || return 0

    while IFS='|' read -r name _; do
        unset -f "$name" 2>/dev/null
    done < "$ALIAS_FILE"

    while IFS='|' read -r name command; do
        [[ -z "$name" || -z "$command" ]] && continue
        validate_alias_name "$name" || {
            aliasx_error "Skipping invalid alias: $name"
            continue
        }

        eval "$(printf '%s() {
            local args=("$@")
            local cmd="%s"
            
            for ((i=1; i<=9; i++)); do
                if (( i <= ${#args[@]} )); then
                    cmd="${cmd//\{$i\}/${args[$((i-1))]}}"
                fi
            done
            
            if [[ "$cmd" == *"{*}"* ]]; then
                cmd="${cmd//\{\*\}/\"${args[@]}\"}"
            fi
            
            printf "\033[1;36m➔ Running:\033[0m \033[1;33m%s\033[0m\n" "$cmd"
            eval "$cmd"
        }' "$name" "$(sed 's/"/\\"/g' <<<"$command")")"
    done < "$ALIAS_FILE"
}

aliasx() {
    case "$1" in
        -R|--remove)
            [[ -z "$2" ]] && { aliasx_error "Missing alias name"; return 1; }
            [[ -f "$ALIAS_FILE" ]] || { aliasx_error "No aliases file"; return 1; }
            grep -q "^$2|" "$ALIAS_FILE" || { aliasx_error "Alias not found: $2"; return 1; }
            
            grep -v "^$2|" "$ALIAS_FILE" > "${ALIAS_FILE}.tmp" &&
            mv -f "${ALIAS_FILE}.tmp" "$ALIAS_FILE"
            
            unset -f "$2" 2>/dev/null
            load_aliases
            printf "\033[1;32mRemoved alias:\033[0m %s\n" "$2"
            ;;
            
        -L|--list)
            if [[ -f "$ALIAS_FILE" ]]; then
                printf "\033[1;34mDefined Aliases:\033[0m\n"
                column -t -s'|' "$ALIAS_FILE" | sed 's/|/ => /' | \
                while read -r line; do
                    printf "  \033[1;35m%s\033[0m => %s\n" "${line%% =>*}" "${line#* => }"
                done
            else
                printf "No aliases defined\n"
            fi
            ;;
            
        -H|--help)
            cat <<HELP
AliasX - Enhanced Bash Aliases v${VERSION}

Usage:
  aliasx <name> <command>   Create/update alias
  aliasx -R <name>          Remove alias
  aliasx -L                 List all aliases
  aliasx -H                 Show this help
  aliasx -V                 Show version
  aliasx -U                 Uninstall AliasX

Placeholders:
  {1}-{9}    Positional arguments
  {*}        All arguments as one string

Examples:
  aliasx lsdir 'ls -l {1} | grep ^d'
  aliasx findf 'find {1} -name "{2}"'
  aliasx grepi 'grep -i "{*}"'
HELP
            ;;
            
        -V|--version)
            printf "AliasX v%s\n" "$VERSION"
            ;;
            
        -U|--uninstall)
            source "${HOME}/.aliasx_uninstaller" && aliasx_uninstall || {
                aliasx_error "Uninstall failed. Try: bash <(curl -sSL ${GITHUB_URL}) --uninstall"
                return 1
            }
            ;;
            
        *)
            [[ $# -ge 2 ]] || { aliasx_error "Invalid usage"; return 1; }
            validate_alias_name "$1" || return 1
            
            local temp_file
            temp_file="$(mktemp)"
            [[ -f "$ALIAS_FILE" ]] && grep -v "^$1|" "$ALIAS_FILE" > "$temp_file"
            printf '%s|%s\n' "$1" "${*:2}" >> "$temp_file"
            mv -f "$temp_file" "$ALIAS_FILE"
            
            load_aliases
            printf "\033[1;32mAdded alias:\033[0m %s => %s\n" "$1" "${*:2}"
            ;;
    esac
}

[[ -f "$ALIAS_FILE" ]] || touch "$ALIAS_FILE"
load_aliases
LOADER_EOF

    chmod +x "$LOADER_FILE"
}

install_uninstaller() {
    create_backup "$UNINSTALLER_FILE" || return 1

    cat > "$UNINSTALLER_FILE" <<'UNINSTALLER_EOF'
#!/usr/bin/env bash

aliasx_uninstall() {
    local shell_files=(
        "${HOME}/.bashrc"
        "${HOME}/.zshrc"
        "${HOME}/.bash_profile"
        "${HOME}/.zprofile"
        "${HOME}/.zshrc.local"
    )

    for rcfile in "${shell_files[@]}"; do
        [[ -f "$rcfile" ]] && sed -i".bak" '/aliasx_loader/d' "$rcfile"
    done

    [[ -f "${HOME}/.aliasx_aliases" ]] && while IFS='|' read -r name _; do
        unset -f "$name" 2>/dev/null
    done < "${HOME}/.aliasx_aliases"

    rm -f "${HOME}/.aliasx_aliases"* \
          "${HOME}/.aliasx_loader"* \
          "${HOME}/.aliasx_uninstaller"* 2>/dev/null

    hash -r 2>/dev/null
    printf "\033[1;32mAliasX completely uninstalled\033[0m\n"
}

aliasx_uninstall "$@"
UNINSTALLER_EOF

    chmod +x "$UNINSTALLER_FILE"
}

configure_shell_integration() {
    local modified=0
    for rcfile in "${SUPPORTED_SHELLS[@]}"; do
        [[ -f "$rcfile" ]] || continue
        if ! grep -q "aliasx_loader" "$rcfile"; then
            printf "\n# AliasX Configuration\n" >> "$rcfile"
            printf "[ -f '%s' ] && source '%s'\n" "$LOADER_FILE" "$LOADER_FILE" >> "$rcfile"
            ((modified++))
        fi
    done
    [[ $modified -gt 0 ]] && return 0
    return 1
}

### Main Installation
perform_installation() {
    install_loader || return 1
    install_uninstaller || return 1
    create_backup "$ALIAS_FILE" || return 1
    touch "$ALIAS_FILE"

    if ! configure_shell_integration; then
        print_warning "AliasX already configured in shell files"
    fi

    print_success "AliasX v${VERSION} installed successfully!"
    cat <<INSTRUCTIONS

Usage:
  Create alias: \033[1maliasx <name> <command>\033[0m
  List aliases: \033[1maliasx -L\033[0m
  Remove alias: \033[1maliasx -R <name>\033[0m
  Uninstall:    \033[1maliasx -U\033[0m

INSTRUCTIONS

    if [[ $- == *i* ]]; then
        source "$LOADER_FILE"
        printf "\n\033[1;33mNote:\033[0m Restart your shell or run: \033[1;36mexec %s\033[0m\n" "$SHELL"
    fi
}

### Uninstallation
perform_uninstallation() {
    if [[ -f "$UNINSTALLER_FILE" ]]; then
        "$UNINSTALLER_FILE"
    else
        print_warning "Missing uninstaller. Cleaning manually..."
        for rcfile in "${SUPPORTED_SHELLS[@]}"; do
            [[ -f "$rcfile" ]] && sed -i".bak" '/aliasx_loader/d' "$rcfile"
        done
        rm -f "${ALIAS_FILE}"* "${LOADER_FILE}"* "${UNINSTALLER_FILE}"*
        print_success "Removed AliasX components"
    fi
}

### Main Flow
main() {
    case "$1" in
        --install)
            perform_installation
            ;;
        --uninstall)
            perform_uninstallation
            ;;
        *)
            if [[ "$0" == "$BASH_SOURCE" ]]; then
                cat <<USAGE
\033[1;34mAliasX Installer v${VERSION}\033[0m

Install:
  bash <(curl -sSL ${GITHUB_URL}) --install

Uninstall:
  bash <(curl -sSL ${GITHUB_URL}) --uninstall

Post-install:
  aliasx -U  # Uninstall from command line
USAGE
            else
                print_error "This script must be executed directly"
                exit 1
            fi
            ;;
    esac
}

main "$@"
