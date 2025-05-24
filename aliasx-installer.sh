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
            
            # Force unset the function and any existing alias
            unset -f "$2" 2>/dev/null || true
            unalias "$2" 2>/dev/null || true
            
            # Show success message before reloading
            printf "\033[1;32mRemoved alias:\033[0m %s\n" "$2"
            
            # Return early without reloading all aliases
            return 0
            ;;
        # ... rest of the cases ...
    esac
}
