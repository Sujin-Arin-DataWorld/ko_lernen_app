"""Check the built install-time artwork split, exact bytes, and Play size margin."""

import argparse
import csv
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

if __package__:
    from .android_artwork_manifest import check_manifest, file_digest
else:
    from android_artwork_manifest import check_manifest, file_digest

DIST = '{http://schemas.android.com/apk/distribution}'
ANDROID = '{http://schemas.android.com/apk/res/android}'
MAX_BASE_BYTES = 490_000_000  # Leave room below Play's 500 MB calculation.


def check_delivery(xml):
    manifest = ET.fromstring(xml)
    if manifest.get('split') != 'c_artwork':
        raise ValueError('Wrong artwork module')
    install = manifest.find(f'{DIST}module/{DIST}delivery/{DIST}install-time')
    removable = None if install is None else install.find(f'{DIST}removable')
    if (install is None or removable is None
            or removable.get(f'{DIST}value') != 'true'
            or [child.tag for child in install] != [f'{DIST}removable']):
        raise ValueError('Artwork must be an unconditional separate install-time split')
    module = manifest.find(f'{DIST}module')
    if module.find(f'{DIST}delivery/{DIST}on-demand') is not None:
        raise ValueError('Artwork must be available without an on-demand request')
    fusing = module.find(f'{DIST}fusing')
    if fusing is None or fusing.get(f'{DIST}include') != 'true':
        raise ValueError('Universal APKs must include artwork')
    application = manifest.find('application')
    if application is None or application.get(f'{ANDROID}hasCode') != 'false':
        raise ValueError('Artwork module must contain assets only')


def check_payloads(aab, expected):
    if not expected:
        raise ValueError('Empty artwork catalog')
    with zipfile.ZipFile(aab) as bundle:
        prefix = 'c_artwork/assets/flutter_assets/'
        names = [entry.filename for entry in bundle.infolist() if not entry.is_dir()]
        actual = {name[len(prefix):] for name in names if name.startswith(prefix)}
        if actual != set(expected):
            raise ValueError('Artwork split differs from the complete catalog')
        for path, record in expected.items():
            copies = [name for name in names if name.endswith('/assets/flutter_assets/' + path)]
            if copies != [prefix + path]:
                raise ValueError(f'Missing or duplicated artwork: {path}')
            if (bundle.getinfo(prefix + path).file_size != record.bytes
                    or hashlib.sha256(bundle.read(prefix + path)).hexdigest() != record.sha256):
                raise ValueError(f'Artwork bytes changed: {path}')
        if 'base/assets/flutter_assets/AssetManifest.bin' not in names:
            raise ValueError('Flutter asset index missing from base')
        return sum(bundle.getinfo(prefix + path).file_size for path in expected)


def artwork_apk_minimum(report, aab_digest, apks_digest, asset_count, manifest_digest):
    """Bind the exact vendor/TOC verifier's report to this AAB and APK set."""
    if (report.get('aabSha256') != aab_digest or report.get('apksSha256') != apks_digest
            or report.get('artworkManifestSha256') != manifest_digest
            or report.get('module') != 'c_artwork' or report.get('assetCount') != asset_count
            or report.get('baseMinSdk') != 24 or report.get('artworkMinSdk') != 24
            or report.get('noPackagedApplicationCode') is not True):
        raise ValueError('APK module-size evidence is for a different artifact')
    variants, masters = report.get('variants', []), report.get('masters', [])
    if not variants or not masters or report.get('variantCount') != len(variants):
        raise ValueError('Missing complete APK variant evidence')
    by_path = {row['path']: row for row in masters}
    if len(by_path) != len(masters) or {row['master'] for row in variants} != set(by_path):
        raise ValueError('APK master evidence differs from its variants')
    if any(row['assetCount'] != asset_count
           or row.get('codeEntries') not in ([], ['classes.dex'])
           or not 0 < row['vendorDownloadBytes'] <= row['rawApkBytes'] for row in masters):
        raise ValueError('Invalid vendor module-size evidence')
    minimum = min(row['vendorDownloadBytes'] for row in masters)
    if report.get('moduleLowerBoundBytes') != minimum:
        raise ValueError('Invalid mandatory module lower bound')
    return minimum


def check_size(csv_text, artwork_minimum=0):
    rows = list(csv.DictReader(csv_text.splitlines()))
    if not rows or any('MAX' not in row for row in rows):
        raise ValueError('Missing bundletool download-size evidence')
    maximum = max(int(row['MAX']) for row in rows)
    bound = maximum - artwork_minimum
    if not 0 <= artwork_minimum < maximum or not 0 < bound <= MAX_BASE_BYTES:
        raise ValueError(f'Base download bound {bound} exceeds the {MAX_BASE_BYTES} byte release margin')
    return bound


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aab', type=Path, required=True)
    parser.add_argument('--apks', type=Path, required=True)
    parser.add_argument('--apk-sizes', type=Path, required=True)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--artwork-manifest', type=Path, required=True)
    parser.add_argument('--initial-size', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    expected = check_manifest(args.artwork_manifest)
    manifest_digest = file_digest(args.artwork_manifest)
    check_delivery(args.manifest.read_text(encoding='utf-8'))
    byte_count = check_payloads(args.aab, expected)
    aab_digest = file_digest(args.aab)
    apks_digest = file_digest(args.apks)
    module_sizes = json.loads(args.apk_sizes.read_text(encoding='utf-8'))
    artwork_minimum = artwork_apk_minimum(module_sizes, aab_digest, apks_digest, len(expected), manifest_digest)
    size = check_size(args.initial_size.read_text(encoding='utf-8'), artwork_minimum)
    report = {
        'aabSha256': aab_digest,
        'apksSha256': apks_digest,
        'artworkManifestSha256': manifest_digest,
        'groups': {group: sum(row.group == group for row in expected.values())
                   for group in sorted({row.group for row in expected.values()})},
        'module': 'c_artwork', 'delivery': 'unconditional install-time',
        'fusing': True, 'sourceBytesUnchanged': True,
        'assetCount': len(expected), 'assetBytes': byte_count,
        'noPackagedApplicationCode': True,
        'noPackagedDexOrNativeCode': module_sizes['noPackagedDexOrNativeCode'],
        'initialMaxDownloadBytes': size + artwork_minimum,
        'artworkMinVendorDownloadBytes': artwork_minimum,
        'baseDownloadUpperBoundBytes': size, 'baseReleaseLimitBytes': MAX_BASE_BYTES,
        'measurement': 'max initial download minus min mandatory artwork vendor size; includes other install-time modules',
        'passed': True,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
