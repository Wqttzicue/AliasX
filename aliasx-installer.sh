#!/usr/bin/env bash

# AliasX - Enhanced Bash Aliases with Parameters
# Version: 1.2.1

### Configuration
ALIAS_FILE="${HOME}/.aliasx_aliases"
LOADER_FILE="${HOME}/.aliasx_loader"
VERSION="1.2.1"
BACKUP_EXT=".bak"
GITHUB_URL="https://raw.githubusercontent.com/wqttzicue/AliasX/experimental/aliasx-installer.sh"

### Helper Functions
show_error() {
    echo -e "\033[1;31mError:\033[0m $1" >&2
}

show_success() {
    echo -e "\033[1;32mSuccess:\033[0m $1"
}

show_info() {
    echo -e "\033[1;34mInfo:\033[0m $1"
}

show_warning() {
    echo -e "\033[1;33mWarning:\033[0m $1"
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

validate_alias_name() {
    local name="$1"
    [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        show_error "Invalid alias name: '$name'. Must start with letter/underscore and contain only alphanumerics."
        return 1
    }
    return 0
}

### Installation Functions
install_aliasx() {
    # Create the loader file with proper error handling
    backup_file "$LOADER_FILE" || return 1
    
    cat > "$LOADER_FILE" <<'EOF'
#!/usr/bin/env bash
# AliasX Loader v1.2.1

ALIAS_FILE="${HOME}/.aliasx_aliases"
VERSION="1.2.1"

aliasx_error() {
    echo -e "\033[1;31mAliasX Error:\033[0m $1" >&2
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

load_aliases() {
    [ -f "$ALIAS_FILE" ] || return 0
    
    while IFS='|' read -r name command; do
        [[ -z "$name" || -z "$command" ]] && continue
        [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || continue
        
        eval "$(printf '%s() {
            local args=("$@")
            local cmd="%s"
            
            for i in {1..9}; do
                (( i-1 < ${#args[@]} )) && cmd="${cmd//{\$i}/${args[$((i-1))]}}"
            done
            
            cmd="${cmd//{\*}/\"${args[@]}\"}"
            
            echo -e "\\033[1;36m➔ Running:\\033[0m \\033[1;33m%s\\033[0m" "$cmd"
            safe_eval "$cmd"
        }' "$name" "$(sed 's/"/\\"/g' <<<"$command")" "$name")"
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
            
            grep -v "^$2|" "$ALIAS_FILE" > "${ALIAS_FILE}.tmp" && \
            mv -f "${ALIAS_FILE}.tmp" "$ALIAS_FILE"
            
            unset -f "$2" 2>/dev/null
            echo -e "\\033[1;32mRemoved alias:\\033[0m $2"
            load_aliases
            ;;
            
        -L|--list)
            [ -f "$ALIAS_FILE" ] || {
                echo "No aliases defined yet"
                return 0
            }
            
            echo -e "\\033[1;34mDefined Aliases:\\033[0m"
            column -t -s'|' "$ALIAS_FILE" | sed 's/|/ => /' | \
            while read -r line; do
                echo -e "  \\033[1;35m${line%% =>*}\\033[0m => ${line#* => }"
            done
            ;;
            
        -H|--help)
            cat <<HELP
\033[1;34mAliasX - Enhanced Bash Aliases v${VERSION}\033[0m

\033[1mUsage:\033[0m
  aliasx <name> <command>   Create/update alias
  aliasx -R <name>          Remove alias
  aliasx -L                 List all aliases
  aliasx -H                 Show this help
  aliasx -V                 Show version
  aliasx -U                 Uninstall AliasX

\033[1mPlaceholders:\033[0m
  {1}-{9}    Positional arguments
  {*}        All arguments as one string

\033[1mExamples:\033[0m
  aliasx lsdir 'ls -l {1} | grep ^d'
  aliasx findf 'find {1} -name \"{2}\"'
  aliasx grepi 'grep -i \"{*}\"'
HELP
            ;;
            
        -V|--version)
            echo "AliasX v${VERSION}"
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
            echo -e "\\033[1;32mAdded alias:\\033[0m $1 => ${*:2}"
            ;;
    esac
}

[ -f "$ALIAS_FILE" ] || touch "$ALIAS_FILE"
load_aliases
EOF

    # Create uninstaller with complete cleanup
    cat > "${HOME}/.aliasx_uninstaller" <<'EOF'
#!/usr/bin/env bash

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

    echo -e "\\033[1;32mAliasX completely uninstalled\\033[0m"
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
            echo -e "\n# AliasX Configuration" >> "$rcfile"
            echo "[ -f \"${LOADER_FILE}\" ] && source \"${LOADER_FILE}\"" >> "$rcfile"
            shell_updated=1
        fi
    done

    chmod +x "$LOADER_FILE"

    show_success "AliasX v${VERSION} installed successfully!"
    show_info "Usage:"
    echo -e "  Create alias: \033[1maliasx <name> <command>\033[0m"
    echo -e "  List aliases: \033[1maliasx -L\033[0m"
    echo -e "  Remove alias: \033[1maliasx -R <name>\033[0m"
    echo -e "  Uninstall:    \033[1maliasx -U\033[0m"
    
    if [[ $- == *i* ]]; then
        source "$LOADER_FILE"
        echo -e "\n\033[1;33mNote:\033[0m For full integration, restart your shell or run:"
        echo -e "  \033[1;36mexec ${SHELL}\033[0m"
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
            echo -e "\033[1;34mAliasX Installer v${VERSION}\033[0m"
            echo "Usage:"
            echo "  Install and restart shell:"
            echo "    bash <(curl -sSL ${GITHUB_URL}) --install && exec bash"
            echo "  Uninstall:"
            echo "    bash <(curl -sSL ${GITHUB_URL}) --uninstall"
            echo "  After installation, you can also use:"
            echo "    aliasx -U  # to uninstall"
        else
            show_error "This script should be executed directly, not sourced."
            show_info "Run: bash <(curl -sSL ${GITHUB_URL}) --install"
        fi
        ;;
esac
