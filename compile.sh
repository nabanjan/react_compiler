#!/bin/bash -x

# Define a function to display usage instructions
usage() {
    echo "Usage: $0 <dir1> [<dir2> ...]"
    echo "Checks if all provided arguments are valid directories."
    exit 1
}

copy_project_files() {
    local src_root="${1%/}"
    local dest_root="${2%/}"
    local count=0

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#"$src_root"/}"
        local dest_file="$dest_root/$rel_path"

        mkdir -p "$(dirname "$dest_file")"
        cp "$src_file" "$dest_file"
        count=$((count + 1))
    done < <(
        find "$src_root" \
            \( -path "$src_root/node_modules" -o -path "$src_root/.git" -o -path "$src_root/dist" \) -prune -o \
            -type f -print0
    )

    echo "Copied $count project file(s) to $dest_root"
}

# 1. Check for the number of arguments
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided."
    usage
fi

echo "Success: All $# arguments are valid."

npm install

rm -rf "$2"
mkdir -p "$2"


# 2. Check that all parameters are directories
for dir_path in "$@"; do
    if [[ ! -d "$dir_path" ]]; then
        echo "Error: '$dir_path' is not a valid directory or does not exist."
        exit 1
    fi
done

echo "Starting to translating source files from $1 to $2"

node index.js $1 $2
if [ $? -eq 1 ]; then
  echo "Error: Command specifically returned 1" >&2
  exit 1
fi

export $(grep -v '^#' .env | xargs)
pwd=$(pwd)

copy_project_files "$1" "$2"
echo "Done compiling source files from $1 to $2"

cd $pwd
