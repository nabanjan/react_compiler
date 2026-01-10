import * as parser from "@babel/parser";
import _traverse from "@babel/traverse";
const traverse = _traverse.default;
import * as t from "@babel/types";
import * as fs from "fs";
import * as path from "path";

const repoPath = process.argv[2];
const outputDir = process.argv[3];

if (!repoPath || !outputDir) {
  console.error("Please provide the path to the react repo and the output directory.");
  process.exit(1);
}

const getAllFiles = (dirPath, arrayOfFiles) => {
  const files = fs.readdirSync(dirPath);

  arrayOfFiles = arrayOfFiles || [];

  files.forEach((file) => {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isDirectory()) {
      if (file !== "node_modules" && file !== ".git") {
        getAllFiles(fullPath, arrayOfFiles);
      }
    } else {
      if (file.endsWith(".tsx") || file.endsWith(".ts")) {
        arrayOfFiles.push(fullPath);
      }
    }
  });

  return arrayOfFiles;
};

const files = getAllFiles(repoPath);

files.forEach((file) => {
  const tsxCode = fs.readFileSync(file, "utf-8");

  try {
    // Parse the TSX code into an AST
    const ast = parser.parse(tsxCode, {
      sourceType: "module",
      plugins: ["typescript", "jsx"], // Enable TS and JSX support
    });

    let fileType = "utils"; // Default
    const fileName = path.basename(file, path.extname(file));

    let hasJSX = false;
    let isHook = fileName.startsWith("use");
    let hasTypes = false;
    let hasFunctions = false;

    traverse(ast, {
      JSXElement() {
        hasJSX = true;
      },
      JSXFragment() {
        hasJSX = true;
      },
      TSInterfaceDeclaration() {
        hasTypes = true;
      },
      TSTypeAliasDeclaration() {
        hasTypes = true;
      },
      FunctionDeclaration() {
        hasFunctions = true;
      },
      ArrowFunctionExpression() {
        hasFunctions = true;
      },
    });

    if (isHook) {
      fileType = "hooks";
    } else if (hasJSX) {
      if (fileName.endsWith("Page") || file.includes("pages")) {
        fileType = "pages";
      } else if (
        ["AppShell", "Sidebar", "Header", "PageLayout", "Layout"].some((k) =>
          fileName.includes(k)
        )
      ) {
        fileType = "components/layout";
      } else if (["Button", "Card", "Modal", "Table"].includes(fileName)) {
        fileType = "components/common";
      } else {
        const domain = fileName.split(/(?=[A-Z])/)[0] || "Shared";
        fileType = `components/domain/${domain}`;
      }
    } else if (hasTypes && !hasFunctions) {
      fileType = "dto";
    } else if (fileName.toLowerCase().includes("mock")) {
      fileType = "mock";
    } else if (
      fileName.toLowerCase().includes("api") ||
      fileName.toLowerCase().includes("service")
    ) {
      fileType = "api/atomic";
    } else if (
      fileName.toLowerCase().includes("style") ||
      fileName.toLowerCase().includes("theme")
    ) {
      fileType = "styles";
    }

    const destPath = path.join(outputDir, fileType, path.basename(file));
    const destDir = path.dirname(destPath);

    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir, { recursive: true });
    }

    fs.copyFileSync(file, destPath);
    console.log(`${file} -> ${destPath}`);
  } catch (error) {
    console.error(`Error parsing ${file}:`, error.message);
  }
});
