import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { createRequire } from "node:module";
import { runInThisContext } from "node:vm";

const requireDependency = createRequire(import.meta.url);
const ts = requireDependency("typescript");
const React = requireDependency("react");
const { renderToStaticMarkup } = requireDependency("react-dom/server");
const moduleCache = new Map();

function Link({ href, children, ...props }) {
  return React.createElement("a", { ...props, href }, children);
}

const siteStub = {
  Header: ({ locale }) => React.createElement("header", { "data-locale": locale }),
  Footer: ({ locale }) => React.createElement("footer", { "data-locale": locale }),
};

function loadTsx(filePath) {
  const absolutePath = resolve(filePath);
  if (moduleCache.has(absolutePath)) return moduleCache.get(absolutePath).exports;

  const loadedModule = { exports: {} };
  moduleCache.set(absolutePath, loadedModule);
  const source = readFileSync(absolutePath, "utf8");
  const compiled = ts.transpileModule(source, {
    compilerOptions: {
      jsx: ts.JsxEmit.ReactJSX,
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      esModuleInterop: true,
    },
    fileName: absolutePath,
  }).outputText;

  function localRequire(specifier) {
    if (specifier === "next/link") return { __esModule: true, default: Link };
    if (specifier === "./site") return siteStub;
    if (specifier.startsWith(".")) {
      const target = resolve(dirname(absolutePath), specifier);
      return loadTsx(target.endsWith(".tsx") ? target : `${target}.tsx`);
    }
    return requireDependency(specifier);
  }

  const execute = runInThisContext(`(function(require, module, exports) {${compiled}\n})`, {
    filename: absolutePath,
  });
  execute(localRequire, loadedModule, loadedModule.exports);
  return loadedModule.exports;
}

export async function renderSourcePage(relativePath, lang) {
  const filePath = resolve(import.meta.dirname, "..", relativePath);
  const loaded = loadTsx(filePath);
  const element = await loaded.default({ searchParams: Promise.resolve({ lang }) });
  return { html: renderToStaticMarkup(element), loaded };
}
