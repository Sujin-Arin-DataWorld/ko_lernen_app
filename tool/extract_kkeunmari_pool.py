#!/usr/bin/env python3
"""
한글소리 끝말잇기 단어 풀 추출기

Input:  assets/data/korean_vocab.csv (526 entries)
Output: assets/data/kkeunmari_pool.json

Rules:
- 명사만 (POS = Nomen)
- 단어 길이 2글자 이상
- 외래어 제외 (히라가나/카타카나/Latin 포함 단어)
- 한방단어 (dead-end) 식별: 마지막 글자로 시작하는 다른 단어가 없는 것
- 두음법칙은 학습자 친화로 적용 안 함 (정확 매칭)

Usage: python3 tool/extract_kkeunmari_pool.py
"""
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_CSV = REPO / "assets/data/korean_vocab.csv"
OUT_JSON = REPO / "assets/data/kkeunmari_pool.json"

# 외래어/혼종 제외: 한글이 아닌 문자(영어, 일본어 가나, 숫자, 띄어쓰기 포함) 있으면 skip
NON_HANGUL = re.compile(r'[^가-힣]')


def is_pure_hangul(s: str) -> bool:
    return bool(s) and not NON_HANGUL.search(s)


def load_nouns(csv_path: Path):
    """vocab CSV에서 명사 + 순수 한글 + 2글자 이상 추출."""
    nouns = []
    with csv_path.open(encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            korean = row['korean'].strip()
            pos = row['pos_de'].strip()
            level = row['level'].strip()
            german = row['german'].strip()
            topic = row['topic'].strip()
            if pos != 'Nomen':
                continue
            if not is_pure_hangul(korean):
                continue
            if len(korean) < 2:
                continue
            nouns.append({
                'word': korean,
                'first': korean[0],
                'last': korean[-1],
                'level': level,
                'german': german,
                'topic': topic,
            })
    return nouns


def build_pool(nouns):
    """Adjacency map + dead-end detection."""
    by_first = defaultdict(list)
    for n in nouns:
        by_first[n['first']].append(n['word'])

    dead_ends = []
    chain_capable = []
    for n in nouns:
        if not by_first.get(n['last']):
            dead_ends.append(n['word'])
        else:
            chain_capable.append(n['word'])

    # 시작 단어 후보: chain_capable 중 last syllable이 dead-end가 아닌 단어
    safe_starters = [
        n['word'] for n in nouns
        if n['word'] in chain_capable and n['last'] in by_first
    ]

    # 단어별 가능한 다음 단어 수 (chain depth proxy)
    depth = {n['word']: len(by_first[n['last']]) for n in nouns}

    return {
        'version': 1,
        'generated_from': 'assets/data/korean_vocab.csv',
        'rules': {
            'pos_filter': 'Nomen only',
            'pure_hangul_only': True,
            'min_length': 2,
            'dueum_rule_applied': False,
            'note_de': 'Lernerfreundlich: Sackgassen-Wörter (한방단어) sind markiert, aber nicht entfernt.',
            'note_en': 'Learner-friendly: dead-end words are flagged but not removed.',
        },
        'stats': {
            'total_nouns': len(nouns),
            'chain_capable': len(chain_capable),
            'dead_ends': len(dead_ends),
            'safe_starters': len(safe_starters),
            'unique_first_syllables': len(by_first),
        },
        'words': [
            {
                **n,
                'next_count': len(by_first.get(n['last'], [])),
                'is_dead_end': n['word'] in dead_ends,
            }
            for n in nouns
        ],
        'by_first': dict(by_first),
        'dead_ends': dead_ends,
        'safe_starters_sample': safe_starters[:30],
    }


def main():
    if not VOCAB_CSV.exists():
        print(f"FATAL: {VOCAB_CSV} not found", file=sys.stderr)
        sys.exit(1)
    nouns = load_nouns(VOCAB_CSV)
    pool = build_pool(nouns)
    OUT_JSON.write_text(json.dumps(pool, ensure_ascii=False, indent=2), encoding='utf-8')

    s = pool['stats']
    print(f"✓ Written {OUT_JSON.relative_to(REPO)}")
    print(f"  명사 총: {s['total_nouns']}")
    print(f"  체인 가능: {s['chain_capable']} ({s['chain_capable']*100//s['total_nouns']}%)")
    print(f"  한방단어: {s['dead_ends']}")
    print(f"  안전한 시작 단어: {s['safe_starters']}")
    print(f"  고유 첫 글자: {s['unique_first_syllables']}")


if __name__ == '__main__':
    main()
