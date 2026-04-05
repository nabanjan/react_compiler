#!/bin/bash -x

if [ "$#" -ne 1 ]; then
    { set +x; } 2>/dev/null
    echo "Usage: $0 <source-repo-path>"
    echo "  Output is written to: <script-dir>/../output/<repo-name>-refactored"
    echo "  Example: $0 ../my-react-app"
    echo "           Output -> $(cd "$(dirname "$0")/../output" 2>/dev/null && pwd)/my-react-app-refactored"
    exit 1
fi

src="$1"

if [[ ! -d "$src" ]]; then
    echo "Error: '$src' is not a valid directory."
    exit 1
fi

dir_name=$(basename "$src")
output_dir="$(dirname "$0")/../output/${dir_name}-refactored"

echo "Output will be written to: $(cd "$(dirname "$output_dir")" 2>/dev/null && pwd)/$(basename "$output_dir")"

bash "$(dirname "$0")/compile.sh" "$src" "$output_dir"
