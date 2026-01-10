#!/bin/bash

# Define a function to display usage instructions
usage() {
    echo "Usage: $0 <dir1> [<dir2> ...]"
    echo "Checks if all provided arguments are valid directories."
    exit 1
}

# 1. Check for the number of arguments
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided."
    usage
fi

echo "Success: All $# arguments are valid."

npm install
npm run build

rm -rf $2
mkdir -p $2


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
cp $1/package.json $2/package.json
cp $1/tsconfig.json $2/tsconfig.json
cp $1/*.html $2/

echo "Done compiling source files from $1 to $2"

export $(grep -v '^#' .env | xargs)
pwd=$(pwd)
node invokeApi.js "Recreate the React project files here again." $2
node invokeApi.js "Do npm install and npm run dev, and fix the errors." $2
node invokeApi.js "Remove duplicate files." $2
cd $pwd
