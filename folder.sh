#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

temp_file=$(mktemp)

while IFS= read -r line; do
    [ -z "$line" ] && break
    echo "$line" >> "$temp_file"
done

declare -A paths
current_depth=0

process_line() {
    local line=$1
    [[ -z "$line" || $line =~ ^\.$ ]] && return
    
    # Calculate depth from indentation
    local spaces=$(echo "$line" | grep -o '^[ │]*' | wc -c)
    local depth=$((spaces / 4))
    
    # Extract directory name
    if [[ $line =~ [├└]──[[:space:]](.+)/?$ ]]; then
        local dir="${BASH_REMATCH[1]}"
        dir="${dir%/}"
        
        # Build path
        if [ $depth -eq 0 ]; then
            paths[$depth]="$dir"
        else
            paths[$depth]="${paths[$((depth-1))]}/$dir"
        fi
        
        # Create directory if not a placeholder
        if [[ $dir != "..." ]]; then
            echo "Creating: ${paths[$depth]}"
            mkdir -p "${paths[$depth]}"
        fi
    fi
}

while IFS= read -r line; do
    process_line "$line"
done < "$temp_file"

rm "$temp_file"
echo "Done"
