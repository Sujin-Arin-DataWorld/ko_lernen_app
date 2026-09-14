# Committed asset declaration check

Run this local, read-only preflight before a costly build when a commit may
have deleted files that remain declared in `pubspec.yaml`:

```powershell
python tool/check_committed_assets.py --repo . --ref HEAD
python tool/check_committed_assets.py --repo C:\dev\hangulsori\ko_lernen_app --ref <commit-sha>
```

The command resolves the ref once, then reads `pubspec.yaml` and the recursive
Git tree from that exact commit. It prints JSON containing the resolved commit,
declaration counts, `missingPaths`, and `declarationPresence`. A missing
declared path returns exit code 1 with JSON whose verdict is `missing`; invalid
refs or unsupported/malformed declarations return exit code 1 with a fixed
diagnostic on stderr and no JSON success result.

Git reads run with `GIT_NO_LAZY_FETCH=1`, so a partial clone with a missing
promisor object fails locally instead of downloading it.

It checks scalar `flutter.assets` entries and scalar
`flutter.fonts[].fonts[].asset` files. An asset entry ending in `/` is treated
as a directory declaration and passes only when that committed directory has a
regular file immediately inside it. Files only in nested directories do not
satisfy this conservative presence check. Git tree symlinks and submodules do
not count as files.

This does not scan Dart consumers, emulate Flutter asset-bundle semantics,
validate image contents, restore files, change a checkout, fetch, build, or
claim that a release is ready. Use a build and the applicable release gates
after this limited check passes.

Each result describes only the selected committed tree. It says nothing about
uncommitted fixes or assets in another checkout.
