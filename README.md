# react-compiler

A tool that analyzes and reorganizes TypeScript/React project files into a structured directory layout using AST parsing.

## What it does

1. Recursively scans a source React/TypeScript project for `.ts` and `.tsx` files
2. Parses each file's AST to detect its type (component, hook, page, DTO, API service, etc.)
3. Copies files into a categorized output directory structure
4. Copies the rest of the project files into the output directory, preserving their relative paths and excluding only `node_modules`, `.git`, and `dist`

## Output structure

| Source file type | Output path |
|---|---|
| Custom hook (`use*`) | `hooks/` |
| Page component | `pages/` |
| Layout component | `components/layout/` |
| Common UI component | `components/common/` |
| Other JSX component | `components/domain/<domain>/` |
| Types/interfaces only | `dto/` |
| API/service file | `api/atomic/` |
| Mock file | `mock/` |
| Style/theme file | `styles/` |
| Everything else | `utils/` |

## Usage

Use `run.sh` as the entry point — it resolves the output path automatically:

```bash
./run.sh <source-repo-path>
```

Output is written to `../output/<repo-name>-refactored` relative to the script location.

**Example:**
```bash
./run.sh ../my-react-app
# Output -> /path/to/output/my-react-app-refactored
```

**Options:**
```
-h, --help    Show usage information
```

**Error handling:**
- Exits with an error if no argument or more than one argument is provided
- Exits with an error if the argument is not a valid existing directory

**Legacy CRA compatibility:**
- If the generated app uses `react-scripts` 4, `run.sh` will try to use a compatible Node runtime automatically when your current shell is on a newer Node version
- After install, `run.sh` applies a small compatibility patch for the generated CRA 4 dependency tree and starts the dev server with `NODE_OPTIONS=--openssl-legacy-provider`

### Advanced: run compile.sh directly

```bash
./compile.sh <source-repo-path> <output-dir>
```

## Requirements

- Node.js
- npm

The tool installs its own dependencies via `npm install`, and `run.sh` also installs dependencies for the generated output app before starting it.

## Dependencies

- `@babel/parser` — parses TypeScript/JSX into an AST
- `@babel/traverse` — walks the AST to detect file characteristics
- `@babel/types` — AST node type utilities
- `openai` — used by the standalone `invokeApi.js` helper, not by the default `run.sh` / `compile.sh` flow
