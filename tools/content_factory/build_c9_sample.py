#!/usr/bin/env python3
"""Build the fixed C9-1 10% sample from current canonical notes. No approvals."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'docs/data/review_packets/c9_1_usage_notes_jin_sample.md'
# Fixed batch membership, independent of order or future additions.
BATCH_IDS = '''vocab_a2_0237 vocab_a2_0449 vocab_a2_0367 vocab_a2_0435
vocab_b1_0003 vocab_b1_0009 vocab_b1_0010 vocab_b1_0011 vocab_b1_0018
vocab_b1_0019 vocab_b1_0020 vocab_b1_0023 vocab_b1_0025 vocab_b1_0026
vocab_b1_0034 vocab_b1_0036 vocab_b1_0040 vocab_b1_0043 vocab_b1_0053
vocab_b1_0057 vocab_b1_0058 vocab_b1_0064 vocab_b1_0065 vocab_b1_0067
vocab_b1_0069 vocab_b1_0070 vocab_b1_0076 vocab_b1_0081 vocab_b1_0082
vocab_b1_0084 vocab_b1_0085 vocab_b1_0086 vocab_b1_0087 vocab_b1_0099
vocab_b1_0110 vocab_b1_0111 vocab_b1_0131 vocab_b1_0132 vocab_b1_0134
vocab_b1_0135 vocab_b1_0133 vocab_b1_0138 vocab_b1_0139 vocab_b1_0141
vocab_b1_0154 vocab_b1_0159 vocab_b1_0160 vocab_b1_0165 vocab_b1_0168
vocab_b1_0169 vocab_b1_0171 vocab_b1_0172 vocab_b1_0174 vocab_b1_0186
vocab_b1_0185 vocab_b1_0187 vocab_b1_0189 vocab_b1_0193 vocab_b1_0194
vocab_b1_0209 vocab_b1_0212 vocab_b1_0213 vocab_b1_0237 vocab_b1_0240
vocab_b2_0109 vocab_b2_0118 vocab_b1_0253 vocab_b1_0257 vocab_b1_0271
vocab_a1_0290 vocab_a2_0307 vocab_b1_0290 vocab_b1_0314 vocab_b1_0321
vocab_b1_0335 vocab_b1_0337 vocab_b1_0348 vocab_a2_0414 vocab_a2_0437
vocab_b1_0379 vocab_b1_0389 vocab_b1_0392 vocab_b1_0395 vocab_b1_0430
vocab_b1_0431 vocab_b1_0445 vocab_b1_0452 vocab_b1_0458 vocab_b1_0462
vocab_b1_0465 vocab_a2_0473 vocab_b1_0469 vocab_b1_0471 vocab_b1_0472
vocab_b1_0475 vocab_b1_0478 vocab_b1_0480 vocab_b1_0484 vocab_b1_0487
vocab_b1_0488'''.split()


def sample_ids():
    if len(BATCH_IDS) != 100 or len(set(BATCH_IDS)) != 100:
        raise ValueError('C9-1 must contain exactly 100 distinct IDs')
    return sorted(BATCH_IDS)[::10]


def render(notes, vocab):
    by_id = {note['id']: note for note in notes}
    if len(by_id) != len(notes):
        raise ValueError('Duplicate note IDs')
    missing = set(BATCH_IDS) - (by_id.keys() & vocab.keys())
    if missing:
        raise ValueError(f'Missing batch IDs: {sorted(missing)}')
    lines = ['# C9-1 B1 100단어 배치 1 -- Jin 10% 표본 검수 패킷', '',
        '> 자동 생성: `python tools/content_factory/build_c9_sample.py`. 고정 배치 100 IDs를 정렬하여 인덱스 0, 10, ..., 90의 10건을 수록합니다.',
        '> 현재 JSON의 전문을 옮긴 미승인 검수 자료입니다. 자동 검사나 모델 검수는 Jin의 승인 또는 언어 품질 승인을 대신하지 않습니다.',
        '> 검수: KO 의미와 상황, DE/EN의 같은 사건, 대조어 정확성, 앞면과 다른 두 예문, 실제 격식 차이, B1 적합성.', '']
    for ident in sample_ids():
        note=by_id[ident]; word=vocab[ident]
        lines.extend([f"## `{ident}` -- {word['korean']} ({word['german']})", '',
                      f"- 레벨: {note['level']} / register: {note['register']}"])
        for field, label in [('nuance','뉘앙스'), ('situation','전형 상황')]:
            lines.append(f'- {label}:')
            lines.extend(f'  - {lang.upper()}: {note[field][lang]}' for lang in ('ko','de','en'))
        for field, label in [('patterns','패턴'), ('collocations','연어'), ('contrasts','대조어'), ('examples','예문 2개')]:
            lines.append(f'- {label}:')
            for entry in note[field]:
                if field=='contrasts':
                    lines.append(f"  - {entry['headword']} [vocabId: {entry.get('vocabId') or 'null'}]")
                if field=='examples': lines.append(f"  - [{entry['register']}]")
                lines.extend(f'    - {lang.upper()}: {entry[lang]}' for lang in ('ko','de','en'))
        lines.extend(['', '**Jin 판정:** ', ''])
    return '\n'.join(lines)


def build():
    notes=json.loads((ROOT/'assets/data/usage_notes.json').read_text(encoding='utf-8'))['notes']
    with (ROOT/'assets/data/korean_vocab.csv').open(encoding='utf-8-sig', newline='') as handle:
        vocab={row['id']:row for row in csv.DictReader(handle)}
    return render(notes,vocab)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args=parser.parse_args()
    expected=build()
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding='utf-8') != expected:
            raise SystemExit('C9-1 sample packet is stale')
        print('C9-1 sample packet: verified (10 unapproved notes)')
    else:
        OUTPUT.write_text(expected, encoding='utf-8', newline='\n')
        print('C9-1 sample packet: generated (10 unapproved notes)')


if __name__=='__main__': main()
