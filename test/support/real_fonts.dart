import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;

/// Loads Hangul Sori's real display fonts (Paperlogy + MaruBuri + Material
/// Icons) into the test binding.
///
/// §W-F3 root cause: `flutter_test`'s default binding renders every glyph as
/// a fixed 1em-wide square (the "test font") unless a real font is loaded —
/// every character, in every script, at the same width. For layout-budget
/// assertions (fold checks, line-count checks) that inflates measured text
/// width/height by roughly 2-3× versus the real, proportionally-spaced
/// MaruBuri/Paperlogy faces, which silently invents a much taller header and
/// wrongly implies the layout doesn't fit. Any test that measures rects or
/// line counts against real copy must call this first — a rendering
/// smoke/existence test (does it build, is a key present) does not need it.
///
/// Mirrors `sori_stage_visual_evidence_test.dart`'s `_loadRealFonts`
/// (~L80-106), minus its `_captureEvidence` env-flag gate — this helper
/// always loads, since fold/line-count tests need real metrics on every run,
/// not just golden capture.
///
/// Idempotent: safe to call from multiple `setUpAll`s or multiple times in
/// one file.
///
/// [materialIcons] defaults to `false` — layout-budget tests (fold checks,
/// line-count checks) size every `Icon` from its fixed `size:` argument, not
/// glyph metrics, so the Material Icons face is never actually needed for
/// them. It's opt-in and best-effort: CI (Linux) has no guarantee of a
/// `flutter precache`'d `material_fonts` cache (no `ci.yml` step does this,
/// and this loader's search-upward-from-`Platform.resolvedExecutable`
/// pattern — copied from `sori_stage_visual_evidence_test.dart`'s
/// `_loadRealFonts`, ~L80-106 — has only ever run locally, gated behind that
/// file's own `CAPTURE_SORI_STAGE_EVIDENCE` flag). Pass `true` only for
/// pixel-evidence/golden work that actually paints icon glyphs; if the font
/// isn't found there, this silently skips it rather than throwing.
bool _loaded = false;
bool _materialIconsLoaded = false;

Future<void> loadSoriRealFonts({bool materialIcons = false}) async {
  if (!_loaded) {
    _loaded = true;
    await _loadTextFonts();
  }
  if (materialIcons && !_materialIconsLoaded) {
    _materialIconsLoaded = true;
    await _loadMaterialIconsIfFound();
  }
}

Future<void> _loadTextFonts() async {
  final loader = FontLoader('Paperlogy');
  for (final path in const <String>[
    'assets/fonts/Paperlogy/Paperlogy-Regular.ttf',
    'assets/fonts/Paperlogy/Paperlogy-Medium.ttf',
    'assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf',
    'assets/fonts/Paperlogy/Paperlogy-Bold.ttf',
  ]) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  // hero/h1/h2/numeral 은 MaruBuri(culture)로 렌더된다 — Paperlogy만 로드하면
  // 헤드라인이 tofu(폰트 없음 네모)로 나와 폭/줄수가 또 달라진다.
  final cultureLoader = FontLoader('MaruBuri');
  for (final path in const <String>[
    'assets/fonts/MaruBuri/MaruBuri-Regular.otf',
    'assets/fonts/MaruBuri/MaruBuri-SemiBold.otf',
  ]) {
    final bytes = File(path).readAsBytesSync();
    cultureLoader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await cultureLoader.load();
}

/// Best-effort only — pixel-evidence tests opt in via `materialIcons: true`;
/// layout-budget tests never call this. If the cache isn't found (e.g. CI
/// with no `flutter precache`), this returns quietly instead of throwing.
Future<void> _loadMaterialIconsIfFound() async {
  var flutterRoot = File(Platform.resolvedExecutable).parent;
  File? materialPath;
  while (true) {
    final materialDirectory =
        '${flutterRoot.path}/bin/cache/artifacts/material_fonts';
    final candidates = <File>[
      File('$materialDirectory/MaterialIcons-Regular.otf'),
      File('$materialDirectory/materialicons-regular.otf'),
    ];
    final found = candidates.where((c) => c.existsSync()).firstOrNull;
    if (found != null) {
      materialPath = found;
      break;
    }
    final parent = flutterRoot.parent;
    if (parent.path == flutterRoot.path) {
      // Not found anywhere up to the filesystem root — skip silently
      // instead of throwing (§W-F4 §1: golden/evidence-only, not needed for
      // layout-budget assertions).
      return;
    }
    flutterRoot = parent;
  }
  final materialBytes = materialPath.readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future<ByteData>.value(ByteData.view(materialBytes.buffer))))
      .load();
}
