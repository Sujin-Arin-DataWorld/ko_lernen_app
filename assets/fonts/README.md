# Bundled interface fonts

Before Flutter tests or a build, prepare the English interface fonts:

```sh
python3 tool/prepare_fontshare_fonts.py
python3 tool/prepare_fontshare_fonts.py --check
```

On Windows, use `python` if that is the installed interpreter command. Python's
standard library is sufficient. Valid local files are reused without network
access or rewriting. A SHA-256 mismatch stops preparation; the tool never
silently updates a font version or overwrites a different local file.

English headings use Chubbo Bold 700; body copy uses Supreme Regular 400 with
its actual Medium 500 and Bold 700 for emphasis. These are official,
unmodified Fontshare originals. The font files and vendor FFL text stay in
the local build workspace and compiled app, outside Git. CI downloads missing
inputs directly from Fontshare and verifies the per-file hashes recorded in
[locale_fonts_sources.json](locale_fonts_sources.json). ZIPs are kept only in
memory; raw font files are not published separately or added to CI caches.

Official sources:

- [Chubbo download](https://api.fontshare.com/v2/fonts/download/chubbo)
- [Supreme download](https://api.fontshare.com/v2/fonts/download/supreme)
- [Fontshare license reference](https://www.fontshare.com/licenses)

The downloaded ITF Free Font License 2.0 (17 August 2026), section 01, permits
self-hosting for the licensee's own websites/apps and mobile/desktop app
embedding. Section 02 restricts raw-font redistribution, including through
repositories, and modification, subsetting or format conversion. It also
requires external service providers who need the font itself to obtain their
own copy from Fontshare. The preparation step makes no font modifications.
Public provenance records contain only source URLs, archive member names and
checksums. The full vendor license is obtained with the fonts and bundled in
the app; it is not reproduced in this public source package.

German headings use Belgrano Regular 400, its only supplied weight; body copy
uses Encode Sans Condensed Regular 400 and its actual 500/600/700 faces. These
font files may remain in Git with their respective copyright notices and SIL
Open Font License 1.1 in [Belgrano/OFL.txt](Belgrano/OFL.txt) and
[EncodeSansCondensed/OFL.txt](EncodeSansCondensed/OFL.txt). Existing Noto Sans KR
continues to provide Korean learning text and mixed-script fallback.
