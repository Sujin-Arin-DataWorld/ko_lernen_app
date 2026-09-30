"""Build the offline positive noun index; never infer invalidity from absence.

Source: NIKL 2023 basic vocabulary, KOGL Type 1, attribution in Settings and
docs/data/level_bible/SOURCES.md. No definitions or translations are copied.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools/content_factory/lexicon/nikl_basic_2023_vocab.csv'
OUTPUT = ROOT / 'assets/data/kkeunmari_nouns.json'
SERVER_OUTPUT = ROOT / 'functions/analyze_korean_text/kkeunmari_nouns.json'


def build():
    with SOURCE.open(encoding='utf-8-sig', newline='') as stream:
        words = sorted({row['headword'] for row in csv.DictReader(stream)
                        if row['pos'] == '명사'
                        and re.fullmatch(r'[가-힣]{1,20}', row['headword'])})
    # Independent attestation; only the headword is used, not its definition.
    # Homonyms are valid in this game; no meaning is assigned from this index.
    words = sorted(set(words) | {'러너'})
    return json.dumps({
        'source': '국립국어원, 2023년 국어 기초 어휘 선정 및 어휘 등급화 연구, 어휘 목록',
        'url': 'https://www.korean.go.kr/front/reportData/reportDataView.do?report_seq=1160',
        'license': 'KOGL Type 1',
        'supplement': {'러너': {
            'source': '국립국어원 온용어 / 한국전력공사 전력 용어 사전',
            'url': 'https://kli.korean.go.kr/term/trgtWord/indexTrgtWord.do?trgtWordNo=102155',
            'license': 'KOGL Type 1',
        }},
        'source_sha256': hashlib.sha256(SOURCE.read_bytes().replace(b'\r\n', b'\n')).hexdigest(),
        'words': words,
    }, ensure_ascii=False, indent=2) + '\n'


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    expected = build()
    if args.check:
        if any(not path.exists() or path.read_text(encoding='utf-8') != expected
               for path in (OUTPUT, SERVER_OUTPUT)):
            raise SystemExit('Offline noun index is stale')
    else:
        for path in (OUTPUT, SERVER_OUTPUT):
            path.write_text(expected, encoding='utf-8', newline='\n')
