# react-compiler

A tool that analyzes and reorganizes TypeScript/React project files into a structured directory layout using AST parsing.

## What it does

1. Recursively scans a source React/TypeScript project for `.ts` and `.tsx` files
2. Parses each file's AST to detect its type (component, hook, page, DTO, API service, etc.)
3. Copies files into a categorized output directory structure
4. Copies all remaining project files (configs, assets, etc.) preserving their relative paths, excluding `components`, `hooks`, `pages`, `utils`, `dto`, `node_modules`, `.git`, and `dist`

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

### Advanced: run compile.sh directly

```bash
./compile.sh <source-repo-path> <output-dir>
```

## Requirements

- Node.js
- npm

Dependencies are installed automatically on each run via `npm install`.

## Dependencies

- `@babel/parser` — parses TypeScript/JSX into an AST
- `@babel/traverse` — walks the AST to detect file characteristics
- `@babel/types` — AST node type utilities
- `openai` — used by `invokeApi.js` for AI-assisted post-processing
