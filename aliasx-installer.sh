#!/usr/bin/env bash
# AliasX - Parameterized Bash Aliases Manager
# Original Implementation v1.3.0

set -eo pipefail
shopt -s extglob

### Constants
readonly VERSION="1.3.0"
readonly CONFIG_HOME="${HOME}/.config/aliasx"
readonly ALIAS_DB="${CONFIG_HOME}/aliases.db"
readonly LOADER="${CONFIG_HOME}/loader.bash"
readonly UNINSTALLER="${CONFIG_HOME}/uninstall.bash"
readonly SUPPORTED_SHELLS=("bash" "zsh")
declare -a SHELL_RC_FILES=()

### Text Formatting
fmt_error() { printf "\033[1;31mError:\033[0m %s\n" "$1" >&2; }
fmt_success() { printf "\033[1;32mSuccess:\033[0m %s\n" "$1"; }
fmt_info() { printf "\033[1;34mInfo:\033[0m %s\n" "$1"; }
fmt_warning() { printf "\033[1;33mWarning:\033[0m %s\n" "$1"; }

### Validation Functions
valid_alias_name() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && return 0
    fmt_error "Invalid alias name: '$1' - must match ^[a-zA-Z_][a-zA-Z0-9_]*$"
    return 1
}

### Core Functions
generate_loader() {
    cat <<'LOADER_EOF'
#!/usr/bin/env bash
# AliasX Loader v1.3.0

aliasx() {
    case "$1" in
        -a|--add)
            shift && aliasx-add "$@" ;;
        -r|--remove)
            shift && aliasx-remove "$@" ;;
        -l|--list)
            aliasx-list ;;
        -u|--uninstall)
            aliasx-uninstall ;;
        -v|--version)
            echo "AliasX v1.3.0" ;;
        *)
            aliasx-help ;;
    esac
}

aliasx-add() {
    (( $# >= 2 )) || { echo "Usage: aliasx add <name> <command>"; return 1; }
    local name="$1" cmd="${*:2}"
    
    [[ "${name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        echo "Invalid alias name: ${name}" >&2
        return 1
    }
    
    awk -v name="${name}" -v cmd="${cmd}" '
        BEGIN { FS=OFS="|"; replaced=0 }
        $1 == name { print name OFS cmd; replaced=1; next }
        { print }
        END { if (!replaced) print name OFS cmd }
    ' "${ALIAS_DB}" > "${ALIAS_DB}.tmp"
    
    mv "${ALIAS_DB}.tmp" "${ALIAS_DB}"
    echo "Added alias: ${name} => ${cmd}"
}

aliasx-remove() {
    (( $# == 1 )) || { echo "Usage: aliasx remove <name>"; return 1; }
    [ -s "${ALIAS_DB}" ] || { echo "No aliases defined"; return 1; }
    
    if grep -q "^$1|" "${ALIAS_DB}"; then
        grep -v "^$1|" "${ALIAS_DB}" > "${ALIAS_DB}.tmp"
        mv "${ALIAS_DB}.tmp" "${ALIAS_DB}"
        echo "Removed alias: $1"
    else
        echo "Alias not found: $1" >&2
        return 1
    fi
}

aliasx-list() {
    if [ -s "${ALIAS_DB}" ]; then
        printf "\033[1;34mRegistered Aliases:\033[0m\n"
        column -t -s'|' "${ALIAS_DB}" | sed 's/^/  /'
    else
        echo "No aliases defined"
    fi
}

aliasx-uninstall() {
    source "${UNINSTALLER}"
}

aliasx-help() {
    cat <<HELP
AliasX - Enhanced Bash Aliases Manager v1.3.0

Usage:
  aliasx add <name> <command>    Register new parameterized alias
  aliasx remove <name>          Delete an existing alias
  aliasx list                   Show all registered aliases
  aliasx uninstall              Remove AliasX from system
  aliasx version                Show version information
  aliasx help                   Display this help message

Placeholders:
  {1}-{9}    Positional arguments
  {*}        All arguments as single string

Examples:
  aliasx add findf 'find {1} -name "{2}"'
  aliasx add lsd 'ls -l {1} | grep ^d'
HELP
}

load-aliases() {
    [ -r "${ALIAS_DB}" ] || return 0
    
    while IFS='|' read -r name cmd; do
        eval "${name}() {
            local args=(\"\$@\")
            local processed_cmd=\"${cmd}\"
            
            for i in {1..9}; do
                if (( \${#args[@]} >= i )); then
                    processed_cmd=\${processed_cmd//\{$i\}/\${args[\$((i-1))]}}
                fi
            done
            
            processed_cmd=\${processed_cmd//\{\*\}/\"\${args[@]}\"}
            echo \"\033[1;36mExecuting:\033[0m \033[1;33m\${processed_cmd}\033[0m\"
            eval \"\${processed_cmd}\"
        }"
    done < "${ALIAS_DB}"
}

load-aliases
LOADER_EOF
}

generate_uninstaller() {
    cat <<UNINSTALLER_EOF
#!/usr/bin/env bash
# AliasX Uninstaller v1.3.0

remove_shell_integration() {
    local rc_file
    for rc_file in ${SHELL_RC_FILES[@]}; do
        [ -f "\${rc_file}" ] && sed -i '/aliasx/d' "\${rc_file}"
    done
}

purge_files() {
    rm -rf "${CONFIG_HOME}"
}

main() {
    remove_shell_integration
    purge_files
    echo "AliasX successfully uninstalled"
    exec "\${SHELL}"
}

main
UNINSTALLER_EOF
}

### Installation Functions
setup_config_dir() {
    mkdir -p "${CONFIG_HOME}" || {
        fmt_error "Failed to create config directory"
        return 1
    }
    touch "${ALIAS_DB}"
}

configure_shell_rc() {
    local shell_rc
    for shell in "${SUPPORTED_SHELLS[@]}"; do
        shell_rc="${HOME}/.${shell}rc"
        [ -f "${shell_rc}" ] || continue
        SHELL_RC_FILES+=("${shell_rc}")
        
        if ! grep -q "aliasx loader" "${shell_rc}"; then
            printf "\n# AliasX Integration\n" >> "${shell_rc}"
            echo "[ -f '${LOADER}' ] && source '${LOADER}'" >> "${shell_rc}"
        fi
    done
}

install_aliasx() {
    fmt_info "Starting AliasX installation..."
    
    setup_config_dir || return 1
    generate_loader > "${LOADER}" || return 1
    generate_uninstaller > "${UNINSTALLER}" || return 1
    configure_shell_rc || return 1
    
    chmod +x "${LOADER}" "${UNINSTALLER}"
    fmt_success "Installation completed successfully"
    
    fmt_info "Restart your shell or run:"
    echo "  exec \$SHELL"
}

### Main Execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        install)
            install_aliasx
            ;;
        uninstall)
            [ -f "${UNINSTALLER}" ] && bash "${UNINSTALLER}"
            ;;
        *)
            echo "Usage: $0 [install|uninstall]"
            ;;
    esac
fi
