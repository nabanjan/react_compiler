#!/bin/bash -x

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <source-repo-path>"
    exit 1
fi

src="$1"

if [[ ! -d "$src" ]]; then
    echo "Error: '$src' is not a valid directory."
    exit 1
fi

dir_name=$(basename "$src")
output_dir="$(dirname "$0")/../output/${dir_name}-refactored"

bash "$(dirname "$0")/compile.sh" "$src" "$output_dir"
