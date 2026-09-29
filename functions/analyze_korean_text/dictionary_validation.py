"""Exact noun lookup against the Korean Basic Dictionary Open API.

The game only needs to know whether a submitted Hangul string is an exact
dictionary headword. Definitions and translations are intentionally not used
here: homonyms are safe for word-chain validity, but not for teaching a
specific meaning without context.
"""

from __future__ import annotations

from functools import lru_cache
import os
import json
from pathlib import Path
import urllib.parse
import urllib.request
import xml.etree.ElementTree as element_tree


_SEARCH_URL = "https://krdict.korean.go.kr/api/search"
_NOUN_POS = "\uba85\uc0ac"


@lru_cache(maxsize=1)
def _offline_nouns() -> frozenset[str]:
    data = json.loads(Path(__file__).with_name('kkeunmari_nouns.json').read_text(encoding='utf-8'))
    return frozenset(data['words'])


def _exact_noun_in_response(payload: bytes, word: str) -> bool:
    root = element_tree.fromstring(payload)
    if root.tag != 'channel' or root.find('.//error') is not None:
        raise ValueError('Dictionary did not return a search result')
    for item in root.findall(".//item"):
        headword = (item.findtext("word") or "").strip()
        part_of_speech = (item.findtext("pos") or "").strip()
        if headword == word and part_of_speech == _NOUN_POS:
            return True
    return False


def validate_exact_noun(word: str) -> bool | None:
    """Returns True/False, or None when the protected API cannot be used."""
    try:
        if word in _offline_nouns():
            return True
    except (OSError, ValueError, KeyError, TypeError):
        pass
    api_key = os.environ.get("KRDIC_API_KEY", "").strip()
    if not api_key:
        return None
    query = urllib.parse.urlencode(
        {
            "key": api_key,
            "q": word,
            "part": "word",
            "translated": "y",
            "trans_lang": "1",
        }
    )
    try:
        with urllib.request.urlopen(f"{_SEARCH_URL}?{query}", timeout=4) as response:
            payload = response.read(256 * 1024 + 1)
            if len(payload) > 256 * 1024:
                return None
            return _exact_noun_in_response(payload, word)
    except (OSError, ValueError, element_tree.ParseError):
        return None
