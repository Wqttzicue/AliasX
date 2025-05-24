#!/usr/bin/env bash

# AliasX - Enhanced Bash Aliases with Parameters
# Version: 1.2.5  # Updated version number

### Configuration
ALIAS_FILE="${HOME}/.aliasx_aliases"
LOADER_FILE="${HOME}/.aliasx_loader"
VERSION="1.2.5"  # Updated version number
BACKUP_EXT=".bak"
GITHUB_URL="https://raw.githubusercontent.com/wqttzicue/AliasX/experimental/aliasx-installer.sh"

### Helper Functions
show_error() {
    printf "\033[1;31mError:\033[0m %s\n" "$1" >&2
}

show_success() {
    printf "\033[1;32mSuccess:\033[0m %s\n" "$1"
}

show_info() {
    printf "\033[1;34mInfo:\033[0m %s\n" "$1"
}

show_warning() {
    printf "\033[1;33mWarning:\033[0m %s\n" "$1"
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp -f "$file" "${file}${BACKUP_EXT}" || {
            show_error "Failed to backup ${file}"
            return 1
        }
    fi
    return 0
}

### Installation Functions
install_aliasx() {
    # Create the loader file with proper error handling
    backup_file "$LOADER_FILE" || return 1
    
    cat > "$LOADER_FILE" <<'EOF'
#!/usr/bin/env bash
# AliasX Loader v1.2.5  # Updated version number

ALIAS_FILE="${HOME}/.aliasx_aliases"
VERSION="1.2.5"  # Updated version number

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
    return 0
}

load_aliases() {
    # First completely unset all existing aliasx functions
    if [ -f "$ALIAS_FILE" ]; then
        while IFS='|' read -r name _; do
            # Force unset both function and alias
            unset -f "$name" 2>/dev/null || true
            unalias "$name" 2>/dev/null || true
        done < "$ALIAS_FILE"
    fi

    # Then load fresh only if file exists
    [ -f "$ALIAS_FILE" ] || return 0
    
    while IFS='|' read -r name command; do
        [[ -z "$name" || -z "$command" ]] && continue
        
        if ! validate_alias_name "$name"; then
            aliasx_error "Skipping invalid alias name: '$name'"
            continue
        fi
        
        # Escape special characters in command (but don't escape $)
        local escaped_cmd
        escaped_cmd=$(sed 's/["`\\]/\\&/g' <<<"$command")
        
        eval "$(printf '%s() {
            local args=("$@")
            local cmd="%s"
            
            # Replace numbered placeholders
            for ((i=1; i<=9; i++)); do
                if (( i <= ${#args[@]} )); then
                    cmd="${cmd//\{$i\}/${args[$((i-1))]}}"
                fi
            done
            
            # Replace {*} placeholder with all arguments
            if [[ "$cmd" == *"{*}"* ]]; then
                cmd="${cmd//\{\*\}/\"${args[@]}\"}"
            fi
            
            printf "\\033[1;36m➔ Running:\\033[0m \\033[1;33m%s\\033[0m\\n" "$cmd"
            eval "$cmd"
        }' "$name" "$escaped_cmd")"
    done < "$ALIAS_FILE"
}

aliasx() {
    case "$1" in
        -R|--remove)
            [ -z "$2" ] && {
                aliasx_error "Missing alias name for removal"
                return 1
            }
    
            [ -f "$ALIAS_FILE" ] || {
                aliasx_error "No aliases file found"
                return 1
            }
    
            grep -q "^$2|" "$ALIAS_FILE" || {
                aliasx_error "Alias '$2' not found"
                return 1
            }
    
    # Create temp file without the alias
    grep -v "^$2|" "$ALIAS_FILE" > "${ALIAS_FILE}.tmp" && \
    mv -f "${ALIAS_FILE}.tmp" "$ALIAS_FILE"
    
    # Force unset the function completely
    unset -f "$2" 2>/dev/null || true
    unalias "$2" 2>/dev/null || true
    
    printf "\\033[1;32mRemoved alias:\\033[0m %s\\n" "$2"
    return 0
    ;;
            
        -L|--list)
            [ -f "$ALIAS_FILE" ] || {
                printf "No aliases defined yet\n"
                return 0
            }
            
            printf "\033[1;34mDefined Aliases:\033[0m\n"
            column -t -s'|' "$ALIAS_FILE" | sed 's/|/ => /' | \
            while read -r line; do
                printf "  \033[1;35m%s\033[0m => %s\n" "${line%% =>*}" "${line#* => }"
            done
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
            source "${HOME}/.aliasx_uninstaller" && \
            aliasx_uninstall || {
                aliasx_error "Uninstall failed. Try running: bash <(curl -sSL ${GITHUB_URL}) --uninstall"
                return 1
            }
            ;;
            
        *)
            [ $# -ge 2 ] || {
                aliasx_error "Usage: aliasx <name> <command> or aliasx [option]"
                return 1
            }
            
            validate_alias_name "$1" || return 1
            
            [ -f "$ALIAS_FILE" ] || touch "$ALIAS_FILE"
            
            grep -v "^$1|" "$ALIAS_FILE" > "${ALIAS_FILE}.tmp"
            printf '%s|%s\n' "$1" "${*:2}" >> "${ALIAS_FILE}.tmp"
            mv -f "${ALIAS_FILE}.tmp" "$ALIAS_FILE"
            
            load_aliases
            printf "\033[1;32mAdded alias:\033[0m %s => %s\n" "$1" "${*:2}"
            ;;
    esac
}

[ -f "$ALIAS_FILE" ] || touch "$ALIAS_FILE"
load_aliases
EOF

    # Create uninstaller with BACKUP_EXT defined
    cat > "${HOME}/.aliasx_uninstaller" <<'EOF'
#!/usr/bin/env bash

BACKUP_EXT=".bak"

aliasx_uninstall() {
    # Remove loader from all shell configs
    local shell_files=(
        "${HOME}/.bashrc" 
        "${HOME}/.zshrc" 
        "${HOME}/.bash_profile"
        "${HOME}/.zprofile"
        "${HOME}/.zshrc.local"
    )
    
    for rcfile in "${shell_files[@]}"; do
        [ -f "$rcfile" ] && \
        sed -i".${BACKUP_EXT}" '/aliasx_loader/d' "$rcfile" 2>/dev/null
    done

    # Remove all alias functions from current session
    if [ -f "${HOME}/.aliasx_aliases" ]; then
        while IFS='|' read -r name _; do
            unset -f "$name" 2>/dev/null
        done < "${HOME}/.aliasx_aliases"
        unset -f aliasx 2>/dev/null
    fi

    # Remove all created files including backups
    rm -f "${HOME}/.aliasx_aliases"* \
          "${HOME}/.aliasx_loader"* \
          "${HOME}/.aliasx_uninstaller"* 2>/dev/null

    # Clear shell hash table
    hash -r 2>/dev/null

    printf "\033[1;32mAliasX completely uninstalled\033[0m\n"
    return 0
}

aliasx_uninstall "$@"
EOF

    chmod +x "${HOME}/.aliasx_uninstaller"

    # Create or update aliases file
    backup_file "$ALIAS_FILE" || return 1
    touch "$ALIAS_FILE"

    # Add to shell configuration files
    local shell_updated=0
    for rcfile in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile"; do
        [ -f "$rcfile" ] || continue
        
        if ! grep -q "aliasx_loader" "$rcfile" 2>/dev/null; then
            printf "\n# AliasX Configuration\n" >> "$rcfile"
            printf "[ -f \"%s\" ] && source \"%s\"\n" "$LOADER_FILE" "$LOADER_FILE" >> "$rcfile"
            shell_updated=1
        fi
    done

    chmod +x "$LOADER_FILE"

    show_success "AliasX v${VERSION} installed successfully!"
    printf "\033[1mUsage:\033[0m\n"
    printf "  Create alias: \033[1maliasx <name> <command>\033[0m\n"
    printf "  List aliases: \033[1maliasx -L\033[0m\n"
    printf "  Remove alias: \033[1maliasx -R <name>\033[0m\n"
    printf "  Uninstall:    \033[1maliasx -U\033[0m\n"
    
    if [[ $- == *i* ]]; then
        source "$LOADER_FILE"
        printf "\n\033[1;33mNote:\033[0m For full integration, restart your shell or run:\n"
        printf "  \033[1;36mexec %s\033[0m\n" "$SHELL"
    fi
}

### Uninstallation Function
uninstall_aliasx() {
    if [ -f "${HOME}/.aliasx_uninstaller" ]; then
        bash "${HOME}/.aliasx_uninstaller"
    else
        show_warning "Uninstaller not found. Trying to remove files manually..."
        
        # Remove from shell configs
        for rcfile in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile"; do
            [ -f "$rcfile" ] && \
            sed -i".${BACKUP_EXT}" '/aliasx_loader/d' "$rcfile" 2>/dev/null
        done
        
        # Remove all files
        rm -f "${HOME}/.aliasx_aliases"* \
              "${HOME}/.aliasx_loader"* \
              "${HOME}/.aliasx_uninstaller"* 2>/dev/null
        
        show_success "AliasX files removed"
    fi
}

### Main Execution
case "$1" in
    --install)
        install_aliasx
        ;;
    --uninstall)
        uninstall_aliasx
        ;;
    *)
        if [ "$0" = "$BASH_SOURCE" ]; then
            printf "\033[1;34mAliasX Installer v%s\033[0m\n" "$VERSION"
            printf "Usage:\n"
            printf "  Install and restart shell:\n"
            printf "    bash <(curl -sSL %s) --install && exec %s\n" "$GITHUB_URL" "$SHELL"
            printf "  Uninstall:\n"
            printf "    bash <(curl -sSL %s) --uninstall\n" "$GITHUB_URL"
            printf "  After installation, you can also use:\n"
            printf "    aliasx -U  # to uninstall\n"
        else
            show_error "This script should be executed directly, not sourced."
            printf "Run: bash <(curl -sSL %s) --install\n" "$GITHUB_URL"
        fi
        ;;
esac
