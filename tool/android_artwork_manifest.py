"""Resolve only reviewed artwork authorities into one exact Android payload lock."""

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = Path('android/c_artwork/artwork_manifest.tsv')
VERSION = '# c-artwork-manifest-v1'
COLUMNS = 'asset\tsha256\tbytes\tgroup'


@dataclass(frozen=True)
class Family:
    group: str
    authority: str
    root: str
    count: int


# Adding a family requires a reviewed source declaration here, then regeneration.
# Neither a caller-supplied prefix nor a directory scan can promote new artwork.
FAMILIES = (
    Family('r16-originals', 'assets/data/ildu_r16_art_v1.json',
           'assets/illustrations/ildu_r16/', 135),
    Family('c5-originals', 'docs/assets/C5_SCENE_ORIGINALS_20261030.json',
           'assets/illustrations/concept_c/c5_scenes/', 6),
    Family('r16-layers', 'assets/data/ildu_r16_sarang_layers_v1.json',
           'assets/illustrations/ildu_r16_layers/', 31),
)


@dataclass(frozen=True)
class Artwork:
    sha256: str
    bytes: int
    group: str


def safe_path(value):
    if (not isinstance(value, str) or not value or any(char in value for char in '\\:*?[]<>"|')
            or any(part in ('', '.', '..') for part in value.split('/'))
            or any(ord(char) < 32 or ord(char) == 127 for char in value)):
        raise ValueError(f'Unsafe artwork path: {value!r}')
    return value


def identity(digest, size, group):
    if (not isinstance(digest, str) or re.fullmatch('[0-9a-f]{64}', digest) is None
            or type(size) is not int or size <= 0):
        raise ValueError('Invalid artwork SHA-256/byte length')
    return Artwork(digest, size, group)


def file_digest(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def authority_digest(path):
    """Git's JSON eol=lf contract; only text line endings are normalized."""
    return hashlib.sha256(path.read_text(encoding='utf-8').encode('utf-8')).hexdigest()


def source_records(value, family):
    result = {}

    def visit(node):
        if isinstance(node, dict):
            if 'asset' in node:
                key = safe_path(node['asset'])
                if not key.startswith(family.root):
                    raise ValueError(f'Asset outside reviewed family {family.group}: {key}')
                row = identity(node.get('sha256'), node.get('bytes'), family.group)
                if key in result and result[key] != row:
                    raise ValueError(f'Conflicting artwork identity: {key}')
                result[key] = row
            for child in node.values():
                visit(child)
        elif isinstance(node, list):
            for child in node:
                visit(child)

    visit(value)
    if len(result) != family.count or not result:
        raise ValueError(f'{family.group} must contain exactly {family.count} unique assets')
    return result


def resolve_sources(root=ROOT, families=FAMILIES):
    expected, authorities = {}, []
    for family in families:
        safe_path(family.authority)
        safe_path(family.root.rstrip('/'))
        if not family.root.startswith('assets/') or not family.root.endswith('/'):
            raise ValueError('Reviewed family root must be a relative assets directory')
        authority = root / family.authority
        records = source_records(json.loads(authority.read_text(encoding='utf-8')), family)
        managed = root / family.root
        actual = {file.relative_to(root).as_posix() for file in managed.rglob('*') if file.is_file()}
        if actual != set(records):
            raise ValueError(f'{family.group} folder differs from its reviewed exact set')
        for key, record in records.items():
            source = root / key
            if not source.resolve().is_relative_to(managed.resolve()):
                raise ValueError(f'Artwork escapes its managed directory: {key}')
            if source.stat().st_size != record.bytes or file_digest(source) != record.sha256:
                raise ValueError(f'Artwork source bytes changed: {key}')
            if key in expected and expected[key] != record:
                raise ValueError(f'Conflicting family ownership: {key}')
            expected[key] = record
        authorities.append((family, authority_digest(authority)))
    return expected, authorities


def render_manifest(expected, authorities):
    lines = [VERSION]
    for family, digest in authorities:
        lines.append('\t'.join(('# authority', family.group, family.authority,
                                digest, family.root, str(family.count))))
    lines.append(COLUMNS)
    lines.extend(f'{key}\t{row.sha256}\t{row.bytes}\t{row.group}'
                 for key, row in sorted(expected.items()))
    return '\n'.join(lines) + '\n'


def parse_manifest(text):
    lines = text.splitlines()
    if not lines or lines.pop(0) != VERSION:
        raise ValueError('Unsupported artwork manifest')
    groups = {}
    while lines and lines[0].startswith('# authority\t'):
        fields = lines.pop(0).split('\t')
        if len(fields) != 6:
            raise ValueError('Invalid artwork authority header')
        _, group, authority, digest, prefix, count = fields
        safe_path(authority)
        safe_path(prefix.rstrip('/'))
        identity(digest, int(count), group)
        if (re.fullmatch('[a-z0-9-]+', group) is None or group in groups
                or not prefix.startswith('assets/') or not prefix.endswith('/')):
            raise ValueError('Invalid artwork authority group/root')
        groups[group] = (prefix, int(count))
    if not groups or not lines or lines.pop(0) != COLUMNS:
        raise ValueError('Missing artwork authority/columns')
    result = {}
    for line in lines:
        fields = line.split('\t')
        if len(fields) != 4:
            raise ValueError('Invalid artwork row')
        key, digest, size, group = fields
        safe_path(key)
        if group not in groups or not key.startswith(groups[group][0]) or key in result:
            raise ValueError(f'Unregistered/duplicate artwork: {key}')
        result[key] = identity(digest, int(size), group)
    if list(result) != sorted(result):
        raise ValueError('Artwork manifest must be sorted')
    if any(sum(row.group == group for row in result.values()) != count
           for group, (_, count) in groups.items()):
        raise ValueError('Artwork group count differs from authority')
    return result


def check_manifest(path, root=ROOT, families=FAMILIES):
    expected, authorities = resolve_sources(root, families)
    text = path.read_text(encoding='utf-8')
    if text != render_manifest(expected, authorities):
        raise ValueError('Stale artwork manifest; review authorities and regenerate explicitly')
    return parse_manifest(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    expected, authorities = resolve_sources()
    output = ROOT / MANIFEST
    text = render_manifest(expected, authorities)
    if args.check:
        check_manifest(output)
    else:
        output.write_text(text, encoding='utf-8', newline='\n')
    duplicates = {}
    for key, row in expected.items():
        duplicates.setdefault(row.sha256, []).append(key)
    print(json.dumps({'manifestSha256': file_digest(output), 'assetCount': len(expected),
                      'assetBytes': sum(row.bytes for row in expected.values()),
                      'groups': {f.group: f.count for f, _ in authorities},
                      'sameBytesDifferentKeys': [keys for keys in duplicates.values() if len(keys) > 1]}))


if __name__ == '__main__':
    main()
