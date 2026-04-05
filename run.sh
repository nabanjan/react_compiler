#!/bin/bash -x

usage() {
    { set +x; } 2>/dev/null
    echo "Usage: $0 <source-repo-path>"
    echo "  Output is written to: <script-dir>/../output/<repo-name>-refactored"
    echo "  Example: $0 ../my-react-app"
    echo "           Output -> $(cd "$(dirname "$0")/../output" 2>/dev/null && pwd)/my-react-app-refactored"
    exit 1
}

get_node_major() {
    node -p "process.versions.node.split('.')[0]"
}

get_react_scripts_version() {
    local package_json="$1"
    node -e "const pkg = require(process.argv[1]); const version = (pkg.dependencies && pkg.dependencies['react-scripts']) || (pkg.devDependencies && pkg.devDependencies['react-scripts']) || ''; process.stdout.write(version);" "$package_json"
}

get_semver_major() {
    local version="$1"
    node -e "const version = process.argv[1]; const match = version.match(/[0-9]+/); process.stdout.write(match ? match[0] : '');" "$version"
}

find_compatible_runtime_bin() {
    local candidate

    for candidate in "$HOME"/.nvm/versions/node/v20*/bin; do
        if [[ -x "$candidate/node" && -x "$candidate/npm" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

patch_legacy_react_scripts_install() {
    local app_dir="$1"
    local node_bin="$2"

    "$node_bin" - "$app_dir" <<'EOF'
const fs = require("fs");
const path = require("path");

const appDir = process.argv[2];
const safeParserPath = path.join(
  appDir,
  "node_modules",
  "postcss-safe-parser",
  "lib",
  "safe-parser.js"
);
const postcssPackagePath = path.join(
  appDir,
  "node_modules",
  "postcss-safe-parser",
  "node_modules",
  "postcss",
  "package.json"
);

if (fs.existsSync(postcssPackagePath)) {
  const pkg = JSON.parse(fs.readFileSync(postcssPackagePath, "utf8"));
  pkg.exports = pkg.exports || {};
  pkg.exports["./lib/*"] = "./lib/*";
  fs.writeFileSync(postcssPackagePath, JSON.stringify(pkg, null, 2) + "\n");
}

if (fs.existsSync(safeParserPath)) {
  const original = fs.readFileSync(safeParserPath, "utf8");
  const patched = original
    .replace("require('postcss/lib/tokenize')", "require('postcss/lib/tokenize.js')")
    .replace("require('postcss/lib/comment')", "require('postcss/lib/comment.js')")
    .replace("require('postcss/lib/parser')", "require('postcss/lib/parser.js')");

  if (patched !== original) {
    fs.writeFileSync(safeParserPath, patched);
  }
}
EOF
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

if [ "$#" -eq 0 ]; then
    { set +x; } 2>/dev/null
    echo "Error: No arguments provided."
    usage
fi

if [ "$#" -gt 1 ]; then
    { set +x; } 2>/dev/null
    echo "Error: Too many arguments ($# provided, expected 1)."
    usage
fi

src="$1"

if [[ "$src" == -* ]]; then
    { set +x; } 2>/dev/null
    echo "Error: Unknown option '$src'."
    usage
fi

if [[ ! -e "$src" ]]; then
    { set +x; } 2>/dev/null
    echo "Error: '$src' does not exist."
    exit 1
fi

if [[ ! -d "$src" ]]; then
    { set +x; } 2>/dev/null
    echo "Error: '$src' is not a directory."
    exit 1
fi

dir_name=$(basename "$src")
output_dir="$(dirname "$0")/../output/${dir_name}-refactored"

echo "Output will be written to: $(cd "$(dirname "$output_dir")" 2>/dev/null && pwd)/$(basename "$output_dir")"

bash "$(dirname "$0")/compile.sh" "$src" "$output_dir"

abs_output_dir="$(cd "$(dirname "$output_dir")" && pwd)/$(basename "$output_dir")"
if [[ -f "$abs_output_dir/package.json" ]]; then
    react_scripts_version="$(get_react_scripts_version "$abs_output_dir/package.json")"
    node_major="$(get_node_major)"
    runtime_bin=""
    runtime_node="node"
    runtime_npm="npm"
    legacy_react_scripts=0

    if [[ -n "$react_scripts_version" ]]; then
        react_scripts_major="$(get_semver_major "$react_scripts_version")"

        if [[ -n "$react_scripts_major" ]] && (( react_scripts_major <= 4 )); then
            legacy_react_scripts=1

            if (( node_major >= 21 )); then
                runtime_bin="$(find_compatible_runtime_bin)"

                if [[ -n "$runtime_bin" ]]; then
                    { set +x; } 2>/dev/null
                    echo "Detected react-scripts $react_scripts_version with Node $(node -v)."
                    echo "Using compatible runtime: $("$runtime_bin/node" -v) from $runtime_bin"
                    set -x
                else
                    { set +x; } 2>/dev/null
                    echo "Error: Detected react-scripts $react_scripts_version with Node $(node -v)."
                    echo "No compatible Node runtime was found automatically."
                    echo "Install Node 16 or 20 via nvm, or upgrade the generated project off react-scripts 4."
                    echo "The generated output is available at: $abs_output_dir"
                    exit 1
                fi
            fi
        fi
    fi

    if [[ -n "$runtime_bin" ]]; then
        runtime_node="$runtime_bin/node"
        runtime_npm="$runtime_bin/npm"
    fi

    echo "Running npm install in $abs_output_dir"
    if [[ -n "$runtime_bin" ]]; then
        PATH="$runtime_bin:$PATH" "$runtime_npm" --prefix "$abs_output_dir" install
    else
        "$runtime_npm" --prefix "$abs_output_dir" install
    fi

    if (( legacy_react_scripts )); then
        echo "Applying react-scripts compatibility patches in $abs_output_dir"
        patch_legacy_react_scripts_install "$abs_output_dir" "$runtime_node"
    fi

    echo "Running npm start in $abs_output_dir"
    if (( legacy_react_scripts )); then
        if [[ -n "$runtime_bin" ]]; then
            PATH="$runtime_bin:$PATH" NODE_OPTIONS=--openssl-legacy-provider "$runtime_npm" --prefix "$abs_output_dir" run dev
        else
            NODE_OPTIONS=--openssl-legacy-provider "$runtime_npm" --prefix "$abs_output_dir" run dev
        fi
    else
        if [[ -n "$runtime_bin" ]]; then
            PATH="$runtime_bin:$PATH" "$runtime_npm" --prefix "$abs_output_dir" run dev
        else
            "$runtime_npm" --prefix "$abs_output_dir" run dev
        fi
    fi
fi
