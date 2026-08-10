"""Exact noun lookup against the Korean Basic Dictionary Open API.

The game only needs to know whether a submitted Hangul string is an exact
dictionary headword. Definitions and translations are intentionally not used
here: homonyms are safe for word-chain validity, but not for teaching a
specific meaning without context.
"""

from __future__ import annotations

from functools import lru_cache
import os
import urllib.parse
import urllib.request
import xml.etree.ElementTree as element_tree


_SEARCH_URL = "https://krdict.korean.go.kr/api/search"
_NOUN_POS = "\uba85\uc0ac"


def _exact_noun_in_response(payload: bytes, word: str) -> bool:
    root = element_tree.fromstring(payload)
    for item in root.findall(".//item"):
        headword = (item.findtext("word") or "").strip()
        part_of_speech = (item.findtext("pos") or "").strip()
        if headword == word and part_of_speech == _NOUN_POS:
            return True
    return False


@lru_cache(maxsize=512)
def validate_exact_noun(word: str) -> bool | None:
    """Returns True/False, or None when the protected API cannot be used."""
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
            return _exact_noun_in_response(response.read(), word)
    except (OSError, ValueError, element_tree.ParseError):
        return None
