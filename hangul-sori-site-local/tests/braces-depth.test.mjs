import assert from 'node:assert/strict';
import braces from 'braces';
import test from 'node:test';

for (const method of ['parse', 'compile', 'expand', 'stringify', 'create']) {
  test(`${method} rejects deeply nested brace and parenthesis patterns before recursion`, () => {
    for (const [open, close] of [['{', '}'], ['(', ')']]) {
      const pattern = open.repeat(3500) + 'a' + close.repeat(3500);
      assert.throws(() => braces[method](pattern), {
        name: 'SyntaxError', message: /nesting depth/i,
      });
    }
  });
}

for (const method of ['compile', 'expand', 'stringify']) {
  test(`${method} bounds externally supplied ASTs and rejects child cycles`, () => {
    let ast = { type: 'text', value: 'a' };
    for (let i = 0; i < 256; i++) ast = { type: 'root', nodes: [ast] };
    assert.throws(() => braces[method](ast), { name: 'SyntaxError', message: /nesting depth/i });
    const cycle = { type: 'root', nodes: [] };
    cycle.nodes.push(cycle);
    assert.throws(() => braces[method](cycle), { name: 'SyntaxError', message: /cyclic|repeated/i });
  });
}

test('ordinary build globs, ranges, escaping and AST operations retain their output', () => {
  assert.equal(braces.compile('src/{app,lib}/**/*.{js,ts}'), 'src/(app|lib)/**/*.(js|ts)');
  assert.deepEqual(braces.expand('item-{1..3}'), ['item-1', 'item-2', 'item-3']);
  const pattern = 'a/{b,c}/d';
  assert.equal(braces.stringify(braces.parse(pattern)), pattern);
  assert.equal(braces.compile(braces.parse(pattern)), 'a/(b|c)/d');
  assert.deepEqual(braces.expand(braces.parse(pattern)), ['a/b/d', 'a/c/d']);
  assert.deepEqual(braces(['{a,b}', '{b,c}'], { expand: true, nodupes: true }), ['a', 'b', 'c']);
  assert.equal(braces.stringify(braces.parse(String.raw`a/\{literal\}/b`)), 'a/{literal}/b');
});
