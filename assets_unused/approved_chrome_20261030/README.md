# Preserved previous chrome images

These exact PNG bytes were moved out of the Flutter bundle after the approved
image navigation and settings gear replaced their last production references.
No image was edited or discarded. Both matched the tracked originals at
`8841f12cbbfc9f82dc26efea860d62038ad6eeed` immediately before the move.

| Preserved file | Previous bundle path | SHA-256 |
| --- | --- | --- |
| `icon-192.png` | `assets/icons/icon-192.png` | `5f6773061a54c1e99a1a71ea362450b93381713744c9acb21d295968fb18731b` |
| `tactile_settings.png` | `assets/icons/tactile_settings.png` | `7db025816a5225d92a58a642f5ecc5085369c0838085173cd54bba0fd9ce59e4` |

To restore an image, verify its SHA-256 and move the preserved file back to its
previous path. The existing `assets/icons/` pubspec registration covers that
path. Restore it to the bundle only when an actual production consumer needs
the image; an unused constant or orphan-guard exemption is not a consumer.

The loading accessibility test now uses the retained `assets/icons/HanLogo.png`
for its optional-image fixture. Web/PWA icons and launcher sources are unchanged.
The move and byte-copy verification are recorded in
`docs/assets/PRESERVED_CHROME_20261030.json`.
