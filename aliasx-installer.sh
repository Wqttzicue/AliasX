#!/usr/bin/env bash
# AliasX - Robust Parameterized Aliases
# Version: 2.0.0

set -eo pipefail
shopt -s extglob

### Constants
readonly VERSION="2.0.0"
readonly CONFIG_DIR="${HOME}/.aliasx"
readonly ALIAS_DB="${CONFIG_DIR}/aliases.db"
readonly LOADER="${CONFIG_DIR}/loader.bash"
readonly UNINSTALLER="${CONFIG_DIR}/uninstall.bash"
readonly SUPPORTED_RC_FILES=(
    "${HOME}/.bashrc"
    "${HOME}/.zshrc"
    "${HOME}/.bash_profile"
    "${HOME}/.zprofile"
)

### Formatting Utilities
fmt_error() { printf "\033[1;31mError:\033[0m %s\n" "$1" >&2; }
fmt_success() { printf "\033[1;32mSuccess:\033[0m %s\n" "$1"; }
fmt_info() { printf "\033[1;34mInfo:\033[0m %s\n" "$1"; }
fmt_cmd() { printf "\033[1;36m➔ Running:\033[0m \033[1;33m%s\033[0m\n" "$1"; }

### Validation Functions
validate_alias_name() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || {
        fmt_error "Invalid alias name: '$1' - must be alphanumeric with initial letter/underscore"
        return 1
    }
}

### Core Functionality
generate_loader() {
    cat <<'LOADER_EOF'
#!/usr/bin/env bash
# AliasX Loader v2.0.0

readonly CONFIG_DIR="${HOME}/.aliasx"
readonly ALIAS_DB="${CONFIG_DIR}/aliases.db"

aliasx() {
    case "$1" in
        -R|--remove)
            shift && aliasx_remove "$@" ;;
        -L|--list)
            aliasx_list ;;
        -H|--help)
            aliasx_help ;;
        -V|--version)
            echo "AliasX v2.0.0" ;;
        -U|--uninstall)
            aliasx_uninstall ;;
        *)
            aliasx_add "$@" ;;
    esac
}

aliasx_add() {
    (( $# >= 2 )) || { aliasx_error "Usage: aliasx <name> <command>"; return 1; }
    local name="$1" cmd="${*:2}"
    
    validate_alias_name "$name" || return 1
    
    # Atomic update of alias database
    local temp_db
    temp_db="$(mktemp)"
    [[ -f "${ALIAS_DB}" ]] && grep -v "^${name}|" "${ALIAS_DB}" > "${temp_db}"
    printf "%s|%s\n" "${name}" "${cmd}" >> "${temp_db}"
    mv -f "${temp_db}" "${ALIAS_DB}"
    
    fmt_success "Added alias: ${name} => ${cmd}"
    source "${LOADER}"  # Reload aliases
}

aliasx_remove() {
    (( $# == 1 )) || { aliasx_error "Usage: aliasx -R <name>"; return 1; }
    [[ -f "${ALIAS_DB}" ]] || { aliasx_error "No aliases defined"; return 1; }
    
    if grep -q "^${1}|" "${ALIAS_DB}"; then
        # Atomic removal
        local temp_db
        temp_db="$(mktemp)"
        grep -v "^${1}|" "${ALIAS_DB}" > "${temp_db}"
        mv -f "${temp_db}" "${ALIAS_DB}"
        
        unset -f "${1}" 2>/dev/null || true
        fmt_success "Removed alias: ${1}"
    else
        aliasx_error "Alias not found: ${1}"
        return 1
    fi
}

aliasx_list() {
    [[ -s "${ALIAS_DB}" ]] || { echo "No aliases defined"; return 0; }
    printf "\033[1;34mRegistered Aliases:\033[0m\n"
    column -t -s'|' "${ALIAS_DB}" | sed 's/^/  /'
}

aliasx_uninstall() {
    "${CONFIG_DIR}/uninstall.bash"
}

aliasx_help() {
    cat <<HELP
AliasX - Enhanced Bash Aliases v2.0.0

Usage:
  aliasx <name> <command>   Create/update parameterized alias
  aliasx -R <name>          Remove existing alias
  aliasx -L                 List all registered aliases
  aliasx -H                 Show this help
  aliasx -V                 Show version
  aliasx -U                 Uninstall AliasX

Placeholders:
  {1}-{9}    Positional arguments
  {*}        All arguments as single string

Examples:
  aliasx findf 'find {1} -name "{2}"'
  aliasx grepi 'grep -i "{*}"'
HELP
}

load_aliases() {
    [[ -f "${ALIAS_DB}" ]] || return 0
    
    # Cleanup previous functions
    while IFS='|' read -r name _; do
        unset -f "${name}" 2>/dev/null || true
    done < "${ALIAS_DB}" 2>/dev/null
    
    # Create new functions
    while IFS='|' read -r name cmd; do
        eval "${name}() {
            local args=(\"\$@\")
            local processed_cmd='${cmd}'
            
            # Replace numbered placeholders
            for i in {1..9}; do
                if (( \${#args[@]} >= i )); then
                    processed_cmd=\"\${processed_cmd//\{${i}\}/\${args[\$((i-1))]}}\"
                fi
            done
            
            # Replace {*} placeholder
            processed_cmd=\"\${processed_cmd//\{\*\}/\"\${args[@]}\"}\"
            
            fmt_cmd \"\${processed_cmd}\"
            eval \"\${processed_cmd}\"
        }"
    done < "${ALIAS_DB}"
}

aliasx_error() {
    fmt_error "$1"
    return 1
}

# Initial load
load_aliases
LOADER_EOF
}

generate_uninstaller() {
    cat <<UNINSTALLER_EOF
#!/usr/bin/env bash
# AliasX Uninstaller v2.0.0

# Remove from shell configuration
find "${HOME}" -maxdepth 1 -type f \( -name '.bashrc' -o -name '.zshrc' -o -name '.bash_profile' \) \
    -exec sed -i.bak '/aliasx/d' {} \;

# Remove generated functions
while IFS='|' read -r name _; do
    unset -f "${name}" 2>/dev/null
done < "${ALIAS_DB}" 2>/dev/null

# Remove configuration files
rm -rf "${CONFIG_DIR}"

echo "AliasX successfully uninstalled. Restart your shell to complete removal."
UNINSTALLER_EOF
}

### Installation Functions
install_shell_integration() {
    for rcfile in "${SUPPORTED_RC_FILES[@]}"; do
        [[ -f "${rcfile}" ]] || continue
        if ! grep -q "aliasx/loader" "${rcfile}"; then
            printf "\n# AliasX Integration\n" >> "${rcfile}"
            echo "[[ -f '${LOADER}' ]] && source '${LOADER}'" >> "${rcfile}"
        fi
    done
}

perform_installation() {
    fmt_info "Installing AliasX v${VERSION}..."
    
    # Clean previous installations
    rm -rf "${CONFIG_DIR}"
    mkdir -p "${CONFIG_DIR}"
    
    generate_loader > "${LOADER}"
    generate_uninstaller > "${UNINSTALLER}"
    touch "${ALIAS_DB}"
    
    install_shell_integration
    
    chmod +x "${LOADER}" "${UNINSTALLER}"
    source "${LOADER}"
    
    fmt_success "Installation complete!"
    fmt_info "Restart your shell or run: exec \$SHELL"
}

### Main Execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        install)
            perform_installation
            ;;
        uninstall)
            bash "${UNINSTALLER}"
            ;;
        *)
            echo "Usage: $0 [install|uninstall]"
            exit 1
            ;;
    esac
fi
