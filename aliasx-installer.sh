#!/usr/bin/env bash

# AliasX - Enhanced Bash Aliases with Parameters
# Version: 1.0.0

### Configuration
ALIAS_FILE="$HOME/.aliasx_aliases"
LOADER_FILE="$HOME/.aliasx_loader"
VERSION="1.0.0"

### Main Installation Function
install_aliasx() {
    # Create the loader file
    cat > "$LOADER_FILE" <<'EOF'
#!/usr/bin/env bash
# AliasX Loader

# Create aliases file if it doesn't exist
[ -f "$HOME/.aliasx_aliases" ] || touch "$HOME/.aliasx_aliases"

# Load all aliases
load_aliases() {
    while IFS='|' read -r name command; do
        [ -n "$name" ] && [ -n "$command" ] && eval "$name() {
            local args=("\$@")
            local cmd=\"$command\"
            for i in {1..9}; do
                if [ \$((i-1)) -lt \${#args[@]} ]; then
                    cmd=\${cmd//{\$i}/\${args[\$((i-1))]}}
                fi
            done
            cmd=\${cmd//{\*}/\"\${args[@]}\"}
            echo "➔ Running: \$cmd"
            eval "\$cmd"
        }"
    done < "$HOME/.aliasx_aliases"
}

# Main aliasx function
aliasx() {
    case "$1" in
        -R|--remove)
            grep -v "^$2|" "$HOME/.aliasx_aliases" > "$HOME/.aliasx_aliases.tmp"
            mv "$HOME/.aliasx_aliases.tmp" "$HOME/.aliasx_aliases"
            unset -f "$2" 2>/dev/null
            echo "Removed alias: $2"
            load_aliases
            ;;
        -L|--list)
            column -t -s'|' "$HOME/.aliasx_aliases" | sed 's/|/ => /'
            ;;
        -H|--help)
            cat <<HELP
AliasX - Enhanced Bash Aliases

Usage:
  aliasx <name> <command>   Create/update alias
  aliasx -R <name>          Remove alias
  aliasx -L                 List all aliases
  aliasx -H                 Show this help
  aliasx -V                 Show version

Placeholders:
  {1}-{9}    Positional arguments
  {*}        All arguments as one string
HELP
            ;;
        -V|--version)
            echo "AliasX v$VERSION"
            ;;
        *)
            if [ $# -ge 2 ]; then
                grep -v "^$1|" "$HOME/.aliasx_aliases" > "$HOME/.aliasx_aliases.tmp"
                echo "$1|${*:2}" >> "$HOME/.aliasx_aliases.tmp"
                mv "$HOME/.aliasx_aliases.tmp" "$HOME/.aliasx_aliases"
                load_aliases
                echo "Added alias: $1 => ${*:2}"
            else
                echo "Usage: aliasx <name> <command>"
                return 1
            fi
            ;;
    esac
}

# Load aliases on startup
load_aliases
EOF

    # Add to .bashrc if not already present
    if ! grep -q "source \"$LOADER_FILE\"" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "\n# AliasX Configuration" >> "$HOME/.bashrc"
        echo "[ -f \"$LOADER_FILE\" ] && source \"$LOADER_FILE\"" >> "$HOME/.bashrc"
    fi

    # Create empty aliases file
    touch "$ALIAS_FILE"

    # Make loader executable
    chmod +x "$LOADER_FILE"

    # Source it immediately
    source "$LOADER_FILE"

    echo "AliasX v$VERSION installed successfully!"
    echo "You can now use the 'aliasx' command."
    echo "Try: aliasx -H"
}

### Run installer if executed directly
if [ "$0" = "$BASH_SOURCE" ]; then
    install_aliasx
else
    echo "This script should be executed directly, not sourced."
    echo "Run: bash aliasx-installer.sh"
fi
