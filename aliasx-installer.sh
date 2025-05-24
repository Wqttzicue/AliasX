load_aliases() {
    [ -f "$ALIAS_FILE" ] || return 0
    
    # First unset all existing aliasx functions
    if [ -f "$ALIAS_FILE" ]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            name="${line%%|*}"
            unset -f "$name" 2>/dev/null
        done < "$ALIAS_FILE"
    fi
    
    # Then load fresh
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        name="${line%%|*}"
        command="${line#*|}"
        [[ -z "$name" || -z "$command" ]] && continue
        
        if ! validate_alias_name "$name"; then
            aliasx_error "Skipping invalid alias name: '$name'"
            continue
        fi
        
        eval "$(printf '%s() {
            local args=("$@")
            local cmd="%s"
            
            # Replace numbered placeholders
            for ((i=1; i<=9; i++)); do
                if (( i <= ${#args[@]} )); then
                    cmd="${cmd//{%d\}/${args[$((i-1))]}}"
                fi
            done
            
            # Replace {*} placeholder with all arguments
            if [[ "$cmd" == *"{*}"* ]]; then
                cmd="${cmd//{\*}/\"${args[@]}\"}"
            fi
            
            printf "\033[1;36m➔ Running:\033[0m \033[1;33m%s\033[0m\n" "$cmd"
            eval "$cmd"
        }' "$name" "$(sed 's/"/\\"/g' <<<"$command")")"
    done < "$ALIAS_FILE"
}
