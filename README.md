# Function Declarations Script

A bash script that automatically parses C files, extracts function definitions, and adds their declarations at the top of the file. This helps maintain proper function prototypes in C codebases and avoid implicit declarations.

## Purpose

The `add_declaration.sh` script helps C developers maintain clean code by:
- Automatically finding all function definitions in C files
- Creating appropriate function declarations (prototypes)
- Adding these declarations at the top of the file in an organized manner
- Avoiding duplicate declarations by managing existing declaration sections

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/declarations_script.git
   cd declarations_script
   ```

2. Make the script executable:
   ```
   chmod +x add_declaration.sh
   ```

## Usage

The script can be used in several ways:

### 1. Process all C files in the src directory:

```bash
./add_declaration.sh
```

This will process all `.c` files found in the `src` directory (the directory must exist).

### 2. Process a specific C file:

```bash
./add_declaration.sh path/to/your/file.c
```

### 3. Process all C files in a specific directory:

```bash
./add_declaration.sh path/to/directory
```

## How It Works

The script performs the following operations:

1. Locates C files based on the provided arguments
2. For each file:
   - Uses AWK to extract function definitions
   - Converts these definitions into proper declarations by adding semicolons
   - Checks if the file already has a declarations section
   - If it exists, removes the old declarations to avoid duplicates
   - Inserts the new declarations section at the appropriate location:
     - After the last `#include` statement if includes exist
     - After header comments if no includes exist
     - At the beginning of the file otherwise
   - Creates a backup of the original file (`.bak` extension)

## Example

Given a C file like this:

```c
#include <stdio.h>

void print_hello() {
    printf("Hello, world!\n");
}

int calculate_sum(int a, int b) {
    return a + b;
}
```

The script will transform it to:

```c
#include <stdio.h>

/* Function declarations */
void print_hello();
int calculate_sum(int a, int b);

void print_hello() {
    printf("Hello, world!\n");
}

int calculate_sum(int a, int b) {
    return a + b;
}
```

## Notes

- The script creates backup files with `.bak` extension before making changes
- It handles multiple function formatting styles
- It properly manages existing declaration sections
- Comments in function definitions are properly removed from declarations

## Requirements

- Bash shell
- AWK (comes pre-installed on most Unix-like systems)
- Standard Unix tools (grep, find, etc.)

## License

See the [LICENSE](LICENSE) file for details.

## Created

April 13, 2025
