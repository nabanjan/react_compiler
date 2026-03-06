import OpenAI from "openai";
import fs from "fs";
import path from "node:path";
import { exit } from "node:process";



function getCommandLineString() {
    const args = process.argv;

    // The actual arguments provided by the user start at index 2.
    const arbitraryString = args[2];

    if (arbitraryString) {
        console.log("The arbitrary string is:", arbitraryString);
    } else {
        console.log("No string provided.");
    }
    return arbitraryString;
}

function writeFiles(baseDir, files) {
  console.log("Writing files to", baseDir);
  for (const [filePath, content] of Object.entries(files)) {
    const fullPath = path.join(baseDir, filePath);
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });
    fs.writeFileSync(fullPath, content);
  }
  console.log("Wrote", Object.keys(files).length, "files to", baseDir);
}

/**
 * Writes files from a string that uses:
 * --- relative/file/path ---
 * <file contents>
 */
function extractFileBlock(block, delim) {
  const firstLineEnd = block.indexOf(delim);
  if (firstLineEnd === -1) return null;

  const filePath = block.slice(0, firstLineEnd).trim();
  const content = block.slice(firstLineEnd + delim.length).replace(/^\n/, "");

  if (!filePath) return null;
  return { filePath, content };
}

function extractMarkdownBlock(block) {
  const headerMatch = block.match(/^\s*###\s+`([^`]+)`/m);
  if (!headerMatch) return null;
  const filePath = headerMatch[1].trim();
  if (!filePath) return null;

  const fenceMatch = block.match(/```[a-zA-Z0-9_-]*\n([\s\S]*?)```/m);
  if (!fenceMatch) return null;
  const content = fenceMatch[1].replace(/\n$/, "");

  return { filePath, content };
}

function writeFilesFromDelimitedString(input, delim, baseDir = process.cwd()) {
  const fileBlocks = input.split(/^---\s*$/gm).filter(Boolean);

  for (const block of fileBlocks) {
    console.log("Processing block:\n", block.slice(0, 100) + (block.length > 100 ? "\n...[truncated]" : ""));
    const extracted =
      extractFileBlock(block, delim) ||
      extractMarkdownBlock(block);

    if (!extracted) {
      console.warn("Skipping block; could not parse file path/content.");
      continue;
    }

    const { filePath, content } = extracted;

    const absolutePath = path.join(baseDir, filePath);
    const dir = path.dirname(absolutePath);

    if (fs.existsSync(absolutePath) && fs.statSync(absolutePath).isDirectory()) {
      console.warn("Skipping write; path is a directory:", absolutePath);
      continue;
    }

    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(absolutePath, content, "utf8");

    console.log(`✔ Written: ${filePath}`);
  }
}

async function main() {
  try {
    console.log("Reached here and openai key is:", process.env.OPENAI_API_KEY);
    exit(0);
    // Using the 2025 Responses API (recommended)
    const argsInput = getCommandLineString();
    let inputText = argsInput;
    if (process.argv[3]) {
      const p = process.argv[3];
      try {
        const stat = fs.statSync(p);
        if (stat.isFile()) {
          const fileData = fs.readFileSync(p, "utf8");
          inputText = argsInput ? argsInput + "\n\n" + fileData : fileData;
        } else if (stat.isDirectory()) {
          const exts = ['.ts', '.tsx', '.js', '.jsx', '.json', '.css', '.html', '.md', '.txt'];
          const collected = [];
            function walk(dir) {
            for (const name of fs.readdirSync(dir)) {
              const full = path.join(dir, name);
              const s = fs.statSync(full);
              if (s.isDirectory()) walk(full);
              else {
                const ext = path.extname(name).toLowerCase();
                if (exts.includes(ext)) {
                  const content = fs.readFileSync(full, 'utf8');
                  const rel = path.relative(p, full).replace(/\\/g, '/');
                  collected.push({ path: rel, content });
                }
              }
            }
          }
          walk(p);
          if (collected.length === 0) {
            console.error("No matching files found in directory:", p);
          } else {
            let combined = collected.map(f => `--- ${f.path} ---\n${f.content}`).join('\n\n');
            const MAX = 200 * 1024; // 200 KB
            if (combined.length > MAX) {
              combined = combined.slice(0, MAX) + "\n\n...[truncated]";
              console.warn("Directory contents truncated to", MAX, "bytes");
            }
            inputText = argsInput ? argsInput + "\n\n" + combined : combined;
          }
        } else {
          console.error("Provided path is not a file or directory:", p);
        }
      } catch (e) {
        console.error("Could not read file/directory:", e);
      }
    }
    
    // If no API key present, print the prepared input instead of calling the API (handy for debugging)
    if (!process.env.OPENAI_API_KEY) {
      console.log("Prepared input (no OPENAI_API_KEY set):");
      if (!inputText) {
        console.log("<empty input>");
      } else {
        console.log("Found open api key:", process.env.OPENAI_API_KEY);
        console.log(inputText.slice(0, 2000));
        if (inputText.length > 2000) console.log("\n...[truncated] (length=" + inputText.length + ")");
      }
      return;
    }

    // Lazily create the OpenAI client now that we have an API key
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
      dangerouslyAllowBrowser: true,
    });

    console.log("Input:", inputText.slice(0, 1000));
    let outputText;
    const response = await openai.responses.create({
      model: "gpt-5.1-codex",
      input: inputText,
      //max_output_tokens: 500,
    });

    outputText = response.output_text;
    console.log(outputText);
    writeFilesFromDelimitedString(outputText, "###", process.argv[3]);
    console.log("API call completed successfully and files written to : " + process.argv[3]);
  } catch (error) {
    console.error("Error calling API:", error);
  }
}

main();
