# react-compiler

A tool that analyzes and reorganizes TypeScript/React project files into a structured directory layout using AST parsing.

## What it does

1. Recursively scans a source React/TypeScript project for `.ts` and `.tsx` files
2. Parses each file's AST to detect its type (component, hook, page, DTO, API service, etc.)
3. Copies files into a categorized output directory structure
4. Also copies config/asset files (`.json`, `.html`, `tsconfig.json`) preserving their relative paths

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

```bash
./compile.sh <source-repo-path> <output-dir>
```

**Example:**
```bash
./compile.sh ../my-react-app ./output
```

## Requirements

- Node.js
- npm

Dependencies are installed automatically by `compile.sh` via `npm install`.

## Dependencies

- `@babel/parser` — parses TypeScript/JSX into an AST
- `@babel/traverse` — walks the AST to detect file characteristics
- `@babel/types` — AST node type utilities
