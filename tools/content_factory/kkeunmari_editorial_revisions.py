"""Preserve authored noun-sense copies without treating quarantine as invalidity."""
import copy
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / 'tools/content_factory/review/kkeunmari_editorial_revisions_20261002.json'


def apply_review(entries):
    if not LEDGER.exists():
        return entries
    reviews = json.loads(LEDGER.read_text(encoding='utf-8'))['entries']
    by_word = {r['word']: r for r in reviews}
    if len(by_word) != len(reviews):
        raise ValueError('Duplicate kkeunmari editorial word')
    result = []
    for entry in entries:
        row = copy.deepcopy(entry)
        review = by_word.get(row['word'])
        if review:
            if review['result'] == 'quarantined_wrong_or_unresolved_noun_sense':
                continue
            if review['result'] != 'reviewed_bilingual_copy':
                raise ValueError('Unknown kkeunmari editorial decision')
            if set(review['copy']) != {'german', 'english'}:
                raise ValueError('Copy review cannot change level or dictionary status')
            row.update(review['copy'])
        result.append(row)
    counts = Counter(row['word'][0] for row in result)
    for row in result:
        word = row['word']
        row.update(first=word[0], last=word[-1],
                   next_count=counts[word[-1]] - (word[0] == word[-1]))
        row['is_dead_end'] = row['next_count'] == 0
    return result
