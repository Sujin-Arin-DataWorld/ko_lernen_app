import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const source = fileURLToPath(
  new URL("../../docs/data/cultural_glossary.json", import.meta.url),
);
const destination = fileURLToPath(
  new URL("../public/data/cultural_glossary.json", import.meta.url),
);

const canonical = await readFile(source);
let current;
try {
  current = await readFile(destination);
} catch (error) {
  if (error?.code !== "ENOENT") throw error;
}

if (!current || !current.equals(canonical)) {
  await mkdir(dirname(destination), { recursive: true });
  await writeFile(destination, canonical);
}
