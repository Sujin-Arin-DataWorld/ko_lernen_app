This directory vendors the MIT-licensed `micromatch/braces` 3.0.3 runtime.
`UPSTREAM_SHA256.json` records the original installed package bytes; the upstream
license and attribution are retained. The package is named
`@hangulsori/braces-depth-guard` and installed through an explicit npm override.

GitHub advisory GHSA-vfj7-8cjw-p6xm (CVE-2026-93687) currently lists no patched
upstream release: https://github.com/advisories/GHSA-vfj7-8cjw-p6xm.

The local patch rejects parser stack depth 128 or greater before AST construction
can reach a recursive walker. Compile, expand and stringify independently inspect
caller-supplied ASTs with an iterative depth/node/cycle guard before recursion.
The guards cannot be disabled by options. Deep input fails with a controlled
SyntaxError; ordinary glob and range output remains covered by compatibility tests.
This patch targets the reported recursion issue; it is not a claim that arbitrary
brace expansion can consume unlimited resources safely.

Keep the standard `npm audit --audit-level=high` release gate and the adversarial
`tests/braces-depth.test.mjs` tests. Replace this temporary vendor and override
when an upstream fixed release is available and passes the same regression tests.
