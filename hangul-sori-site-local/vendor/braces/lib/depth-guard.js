'use strict';

// CVE-2026-93687: bound the AST before any upstream recursive walker runs.
// Options cannot raise this limit. Ordinary repository build globs are shallow.
const MAX_DEPTH = 128;
const MAX_NODES = 65536;

const assertBoundedAst = ast => {
  const pending = [[ast, 0]];
  const seen = new WeakSet();
  let count = 0;
  while (pending.length) {
    const [node, depth] = pending.pop();
    if (!node || typeof node !== 'object') continue;
    if (depth >= MAX_DEPTH) {
      throw new SyntaxError('Brace AST exceeds maximum nesting depth');
    }
    if (seen.has(node)) {
      throw new SyntaxError('Cyclic or repeated brace AST node');
    }
    seen.add(node);
    if (++count > MAX_NODES) {
      throw new SyntaxError('Brace AST exceeds maximum node count');
    }
    if (Array.isArray(node.nodes)) {
      if (node.nodes.length + pending.length > MAX_NODES) {
        throw new SyntaxError('Brace AST exceeds maximum node count');
      }
      for (const child of node.nodes) pending.push([child, depth + 1]);
    }
  }
};

module.exports = { MAX_DEPTH, assertBoundedAst };
