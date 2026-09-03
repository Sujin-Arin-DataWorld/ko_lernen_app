# R2 Takeover Report — WebKit blank-screen fix + Playwright hardening

Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\stability-r2-web-20260903`
Branch: `codex/stability-r2-web-20260903`
Base: `08b80c6e` (= `origin/main` at session start)
Date: 2026-09-03

## 1. Cleanup status

Started from an interrupted Codex session with uncommitted changes plus `graphify-out/**` noise
(12 modified tracked files + 10 untracked AST cache files under `graphify-out/`).

Ran (after presenting the required destructive-command disclosure):
```
git checkout -- graphify-out
git clean -f -- graphify-out
```

Result: `graphify-out/**` fully reverted/removed. `git status --short` afterwards showed exactly
the expected 5 in-scope files:

```
 M .github/workflows/playwright.yml
 M playwright.config.ts
 M tests/example.spec.ts
 M web/index.html
?? tool/test_web_bootstrap.mjs
```

## 2. Node test — `tool/test_web_bootstrap.mjs`

`node --version` → **v24.18.0**

`node --test tool/test_web_bootstrap.mjs`:

```
✔ inline bootstrap preserves browser scheduling for a normal page (3.7427ms)
✔ inline bootstrap preserves browser scheduling for a webdriver page (0.9874ms)
✔ inline bootstrap preserves browser scheduling for a legacy forceRaf page (0.7803ms)
✔ inline bootstrap retains normal splash removal (0.8699ms)

tests 4
pass 4
fail 0
cancelled 0
skipped 0
todo 0
duration_ms 136.3352
```

All 4 pass, 0 fail.

## 3. Static checks

### (a) `web/index.html` diff scope

`git diff --stat` → `web/index.html | 13 -------------` (1 file changed, 13 deletions, 0 insertions).
Single hunk. The **only** change is removal of the automation-only boot-bypass script; no
production script/meta/link tag was touched. Removed block (verbatim):

```html
  <script>
    // 헤드리스 시각검증 전용 (?forceRaf=1): occluded 탭에서 compositor가
    // requestAnimationFrame을 멈춰 Flutter 엔진이 동결되는 문제 우회.
    // 일반 사용자 경로에는 영향 없음 (URL 파라미터 게이트).
    if (navigator.webdriver || new URLSearchParams(location.search).has('forceRaf')) {
      window.requestAnimationFrame = (cb) => setTimeout(() => cb(performance.now()), 16);
      window.cancelAnimationFrame = clearTimeout;
      try {
        Object.defineProperty(document, 'visibilityState', { value: 'visible' });
        Object.defineProperty(document, 'hidden', { value: false });
      } catch (_) {}
    }
  </script>
```

This block monkey-patched `requestAnimationFrame`/`cancelAnimationFrame` to `setTimeout` and
forced `document.visibilityState`/`hidden` to appear "visible" whenever `navigator.webdriver`
was true (i.e., in any automated browser, not just under a `?forceRaf=1` query flag) — this was
the mechanism suspected of causing the WebKit blank-screen divergence between real users and
automated checks, since it silently altered engine scheduling behavior for every headless/
automation run without an explicit opt-in.

### (b) `playwright.yml` — `uses:` SHA pinning + manifest cross-check

All 5 `uses:` lines, with version comment, and 40-hex validation:

| Line | Action | SHA | Comment | Valid 40-hex |
|---|---|---|---|---|
| 14 | `actions/checkout` | `11d5960a326750d5838078e36cf38b85af677262` | `v4` | yes |
| 16 | `subosito/flutter-action` | `1a449444c387b1966244ae4d4f8c696479add0b2` | `v2` | yes |
| 23 | `actions/setup-node` | `49933ea5288caeca8642d1e84afbd3f7d6820020` | `v4` | yes |
| 34 | `actions/upload-artifact` | `ea165f8d65b6e75b540449e92b4886f43607fa02` | `v4` | yes |
| 40 | `actions/upload-artifact` | `ea165f8d65b6e75b540449e92b4886f43607fa02` | `v4` | yes |

Cross-checked (read-only) against sibling worktree manifest
`C:\dev\hangulsori\ko_lernen_app_worktrees\stability-release-integrity-20260903\tool\release_toolchain.json`:

| Action | playwright.yml SHA | manifest SHA | Match |
|---|---|---|---|
| actions/checkout | `11d5960a...677262` | `11d5960a...677262` | MATCH |
| actions/setup-node | `49933ea5...820020` | `49933ea5...820020` | MATCH |
| actions/upload-artifact | `ea165f8d...07fa02` | `ea165f8d...07fa02` | MATCH |
| subosito/flutter-action | `1a449444...add0b2` | `1a449444...add0b2` | MATCH |

All 4 distinct actions used by the workflow match the manifest exactly. (Manifest also carries
entries unused by this workflow — `actions/setup-java`, `actions/setup-python`,
`r0adkll/upload-google-play` — irrelevant here, no mismatch.)

Full diff also adds: `permissions: contents: read` at workflow root; a "Set up Flutter" step
(`flutter-version: 3.44.0`, `channel: stable`, `cache: true`) + `flutter pub get`; a new
"Verify native web bootstrap" step running `node --test tool/test_web_bootstrap.mjs` before
Playwright browsers install; and a second `upload-artifact` step gated on `if: failure()`
uploading `test-results/` as `playwright-failure-artifacts-${{ github.sha }}`.

### (c) TypeScript / test listing

No `tsconfig*.json` found in the worktree root, so fell back to
`npx playwright test --list` (lists tests without running; no browsers needed):

```
[chromium-phone] › example.spec.ts:159:5 › boots the release consent screen without production network access
[chromium-wide]  › example.spec.ts:159:5 › boots the release consent screen without production network access
[firefox-phone]  › example.spec.ts:159:5 › boots the release consent screen without production network access
[firefox-wide]   › example.spec.ts:159:5 › boots the release consent screen without production network access
[webkit-phone]   › example.spec.ts:159:5 › boots the release consent screen without production network access
[webkit-wide]    › example.spec.ts:159:5 › boots the release consent screen without production network access

Total: 6 tests in 1 file
```

6 projects × 1 test = 6, matching the expected chromium/firefox/webkit × phone/wide matrix.

### (d) YAML validity of `playwright.yml`

Neither `yaml` nor `js-yaml` npm packages were present in `node_modules` (project has no
JS/TS YAML dependency). Fell back to Python: `python --version` → 3.13.7, with `pyyaml` 6.0.2
already importable (not a Windows Store stub — real interpreter). Validated with:

```python
import yaml
with open('.github/workflows/playwright.yml', 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
```

Result: **parsed successfully**, no syntax errors. `jobs.test.steps` has 10 entries matching the
diff above. Note: PyYAML (YAML 1.1) resolves the bare `on:` key to the boolean `True` in the
parsed dict rather than the string `'on'` — this is a well-known YAML-1.1-vs-GitHub-Actions
parser quirk, not a defect in the file itself; GitHub's own workflow engine special-cases `on:`
as a keyword regardless of this ambiguity.

## 4. Commits

1. `d725e65f` — `fix(web): remove automation-only rAF/visibility boot bypass; pin Playwright workflow and 6-project matrix (Codex R2 takeover)`
   5 files changed, 567 insertions(+), 90 deletions(-): `.github/workflows/playwright.yml`,
   `playwright.config.ts`, `tests/example.spec.ts`, `web/index.html`,
   `tool/test_web_bootstrap.mjs` (new).
2. (this docs commit) — adds this report file under `.superpowers/sdd/2026-09-03-stability-takeover/`.

Not pushed (per instructions).

## 5. Unexpected failures

None. Cleanup, node test, `playwright test --list`, and YAML validation all completed without
error on the first attempt. The only friction was the Fact-Forcing Gate requiring an explicit
disclosure before `git checkout --`/`git clean -f` on `graphify-out/`, which was satisfied before
proceeding.

## 6. Open questions (≤3)

1. **`forceRaf`/`navigator.webdriver` grep** — repo-wide search found zero remaining references
   in `lib/` or `web/`. The only two hits anywhere are (a) a historical note in
   `docs/SESSION_LOG_ARCHIVE.md` documenting when the bypass was originally added, and (b) the
   fixture name `'a legacy forceRaf page'` inside the new `tool/test_web_bootstrap.mjs`, which is
   the regression test asserting this exact pattern is absent from `index.html`. No action needed
   unless the archive note should also be annotated as superseded.
2. Since `flutter build web` and Playwright were intentionally not run locally, the actual
   WebKit-blank-screen fix (removing the rAF/visibility bypass) is unverified end-to-end until
   the GitHub "Playwright Tests" workflow runs the real 6-environment matrix on push — worth
   watching that run closely for webkit-phone/webkit-wide specifically, since those are the
   projects the original bypass most plausibly existed to paper over.
3. `playwright.config.ts`'s webServer step uses `flutter build web --release --no-web-resources-cdn`
   — not independently verified against the Flutter 3.44.0 SDK pinned in the new "Set up Flutter"
   step (flag availability wasn't checked against that specific SDK version) since builds were
   out of scope for this local pass.
