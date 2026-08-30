# V05 validated manifest

## Immutable final lock

The source, the top-level preservation copy, and the generation reference copy are byte-identical.

SHA-256: `6B1D0BDE0E0F9DEE72F9E313F10FFD294A6799A5D281EE10143FF8187E44EC0D`

Files:

- `jungmunganchae_try06_final_openmaru.png` in the main pending-review folder
- `00_front_source_exact.png`
- `references/source_final_exact.png`

## Final 28-degree transparent directions

Camera optical axis: 28 degrees from vertical downward, equivalent to 62 degrees above the horizontal ground plane. Azimuth interval: 45 degrees.

All files are RGBA PNG. All four corner alpha values are 0, and every file has zero partial-alpha pixels.

| Direction file | Size | Transparent | Opaque | SHA-256 |
|---|---:|---:|---:|---|
| `00_front_000.png` | 1792×878 | 754,869 | 818,507 | `BC7021EF7BA05F5C21746626E1B3DDEC2E82609DB40D55171C65860256D17909` |
| `01_front_right_045.png` | 1454×1082 | 672,100 | 901,128 | `386B0D951D5264F83F7A304F58ED7382F42C952DEFFAEB9199979D5470EFE1A8` |
| `02_right_090.png` | 1400×1123 | 988,565 | 583,635 | `14C5704C581487D7A4230922065964A1742FE909A0BC28455BFB1CD42FBBC51F` |
| `03_rear_right_135.png` | 1453×1082 | 626,779 | 945,367 | `81156FADE5C8905CA2978B16C71E1C98D99FE9775B6B0EACCF0C243677E75DF9` |
| `04_rear_180.png` | 1791×878 | 660,465 | 912,033 | `025E66CB5A7139CF7C5E26F09DAB845A6AFB546999677A2AD75F3A790EDD48E7` |
| `05_rear_left_225.png` | 1571×1001 | 621,824 | 950,747 | `3821497538DCC8FDB13C54121FEB09F952ACE8EBAE34C073DFBCEF812FB29611` |
| `06_left_270.png` | 1525×1031 | 1,106,576 | 465,699 | `B19BF5169FA449AF885938938EC6FC113CEEAC81559095190FE8905EF55DD0AE` |
| `07_front_left_315.png` | 1493×1054 | 718,417 | 855,205 | `174C41FC54D5D40C4D094FF2006AC7A8F6B5F9EB128612317CAE61E723D710BC` |

## Sheets

- Review sheet: 3840×2160 RGBA, SHA-256 `1CA7CDC4BDE38F8C7C78982065FFB601F84BF8C50860F260ABBFDD8A0C8F51B1`
- Transparent sheet: 3840×2160 RGBA, SHA-256 `D688DEAA70C096906FE07615275268A6E3B709EB13073AA4B9DD0E83B2585BBA`

Status: user-approved V05 source archive. Runtime turntable PNGs were promoted
separately by PR #216. This tracked archive intentionally excludes V01~V04,
`generated_images/`, and `rejected_variants/`. No Firebase promotion.
