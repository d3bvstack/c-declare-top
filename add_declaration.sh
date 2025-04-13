#!/bin/bash

# Script to parse .c files and add function declarations at the top
# Created: April 13, 2025

process_file() {
    local file="$1"
    echo "Processing file: $file"
    
    # Create temporary files
    temp_file=$(mktemp)
    declarations_file=$(mktemp)
    
    # Use awk to extract function signatures more reliably
    # This will find lines that match function definitions and aren't followed by a semicolon
    awk '
    # Match potential function definitions (return type, name, parameters)
    /^[a-zA-Z0-9_* \t]+[a-zA-Z0-9_*]+\s*\([^;{]*\)(\s*|(\s*\/\*.*\*\/\s*))$/ { 
        # Store the line
        line = $0;
        # Get the next line to check if its a function body
        getline;
        # If the next line has an opening brace, its a function definition
        if ($0 ~ /\s*{/) {
            # Remove trailing comments or whitespace from the signature
            gsub(/\/\*.*\*\//, "", line);
            gsub(/\s+$/, "", line);
            # Print the clean signature
            print line;
        }
    }
    ' "$file" > "$temp_file"
    
    # If no functions found, skip
    if [ ! -s "$temp_file" ]; then
        echo "No functions found in $file"
        rm "$temp_file" "$declarations_file"
        return
    fi
    
    # Process each function definition and create declarations
    declarations=""
    while IFS= read -r line; do
        # Add semicolon at end to make it a declaration
        declaration="$line;"
        # Add newlines between declarations
        if [ -z "$declarations" ]; then
            declarations="$declaration"
        else
            declarations="$declarations\n$declaration"
        fi
    done < "$temp_file"
    
    # Add exactly one newline after the declarations
    declarations="$declarations\n"
    
    # Check if we already have declarations in the file to avoid duplicates
    if grep -q "\/\* Function declarations \*\/" "$file"; then
        # Remove old declarations section
        awk '
        BEGIN { printing = 1; }
        /\/\* Function declarations \*\// { printing = 0; }
        /^[a-zA-Z0-9_* \t]+[a-zA-Z0-9_*]+\s*\([^;]*\);$/ { if (printing == 0) next; }
        /^$/ { if (printing == 0) { printing = 1; next; } }
        { if (printing) print; }
        ' "$file" > "$declarations_file"
        
        # Now we work with the cleaned file
        file_to_process="$declarations_file"
    else
        file_to_process="$file"
    fi
    
    # Check if file has include statements to insert after them
    if grep -q "#include" "$file_to_process"; then
        # Insert after the last include statement
        last_include_line=$(grep -n "#include" "$file_to_process" | tail -1 | cut -d':' -f1)
        
        # Create new content with declarations
        head -n "$last_include_line" "$file_to_process" > "$temp_file"
        echo -e "\n/* Function declarations */" >> "$temp_file"
        echo -n -e "$declarations" >> "$temp_file"
        tail -n +$((last_include_line + 1)) "$file_to_process" >> "$temp_file"
    else
        # Insert after the header comment if no includes
        # Look for the end of the header comment block
        if grep -q "/\* \*/" "$file_to_process"; then
            header_end_line=$(grep -n "/\* \*/" "$file_to_process" | tail -1 | cut -d':' -f1)
            
            head -n "$header_end_line" "$file_to_process" > "$temp_file"
            echo -e "\n/* Function declarations */" >> "$temp_file"
            echo -n -e "$declarations" >> "$temp_file"
            tail -n +$((header_end_line + 1)) "$file_to_process" >> "$temp_file"
        else
            # If no comment block found, just add at the top
            echo -n -e "/* Function declarations */\n$declarations" > "$temp_file"
            cat "$file_to_process" >> "$temp_file"
        fi
    fi
    
    # Backup original file
    cp "$file" "${file}.bak"
    
    # Replace original file with new content
    mv "$temp_file" "$file"
    
    # Clean up temporary files
    if [ -f "$declarations_file" ]; then
        rm "$declarations_file"
    fi
    
    echo "Added declarations to $file"
}

main() {
    # Check if argument is provided
    if [ $# -eq 0 ]; then
        # No argument, process all .c files in src directory
        dir="src"
        
        # Ensure the directory exists
        if [ ! -d "$dir" ]; then
            echo "Directory $dir does not exist."
            exit 1
        fi
        
        # Process each .c file
        find "$dir" -name "*.c" -type f | while read -r file; do
            process_file "$file"
        done
    else
        # Check if argument is a file or directory
        if [ -f "$1" ]; then
            # It's a file, process it directly
            process_file "$1"
        elif [ -d "$1" ]; then
            # It's a directory, process all .c files in it
            find "$1" -name "*.c" -type f | while read -r file; do
                process_file "$file"
            done
        else
            echo "File or directory $1 does not exist."
            exit 1
        fi
    fi
    
    echo "All files processed."
}

# Run the main function
main "$@"
