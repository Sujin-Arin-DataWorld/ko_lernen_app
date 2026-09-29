"""Positive offline nouns and exact lookup in two protected NIKL APIs.

The game only needs to know whether a submitted Hangul string is an exact
dictionary headword. Definitions and translations are intentionally not used
here: homonyms are safe for word-chain validity, but not for teaching a
specific meaning without context.
"""

from __future__ import annotations

from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor, as_completed, TimeoutError
import os
import json
import re
from pathlib import Path
import urllib.parse
import urllib.request
import xml.etree.ElementTree as element_tree


_SEARCH_URL = "https://krdict.korean.go.kr/api/search"
_STANDARD_SEARCH_URL = "https://stdict.korean.go.kr/api/search.do"
_NOUN_POS = "\uba85\uc0ac"
_LOOKUPS = ThreadPoolExecutor(max_workers=4)


@lru_cache(maxsize=1)
def _offline_nouns() -> frozenset[str]:
    data = json.loads(Path(__file__).with_name('kkeunmari_nouns.json').read_text(encoding='utf-8'))
    return frozenset(data['words'])


def _exact_noun_in_response(payload: bytes, word: str, *, standard: bool = False) -> bool:
    root = element_tree.fromstring(payload)
    channel = root if root.tag == 'channel' else root.find('channel')
    if channel is None or root.find('.//error') is not None:
        raise ValueError('Dictionary did not return a search result')
    items = channel.findall('item')
    for item in items:
        headword = (item.findtext("word") or "").strip()
        if standard:
            # Dictionary syllable separators are not part of the spelling.
            # Keep spaces/carets and leading/trailing affix markers intact.
            headword = re.sub(r'(?<=[가-힣])-(?=[가-힣])', '', headword)
        part_of_speech = (item.findtext("pos") or "").strip()
        if headword == word and part_of_speech == _NOUN_POS:
            return True
    total_text = channel.findtext('total')
    if total_text is None:
        raise ValueError('Dictionary result count is missing')
    total = int(total_text)
    if total < 0 or total != len(items):
        raise ValueError('Incomplete dictionary results cannot reject a word')
    return False


def validate_exact_noun(word: str) -> bool | None:
    """Returns True/False, or None when the protected API cannot be used."""
    try:
        if word in _offline_nouns():
            return True
    except (OSError, ValueError, KeyError, TypeError):
        pass
    providers = [(endpoint, os.environ.get(name, '').strip(), standard)
                 for endpoint, name, standard in (
                     (_SEARCH_URL, 'KRDIC_API_KEY', False),
                     (_STANDARD_SEARCH_URL, 'STDICT_API_KEY', True))]
    providers = [provider for provider in providers if provider[1]]
    if not providers:
        return None
    futures = [_LOOKUPS.submit(_lookup_noun, endpoint, key, word, standard)
               for endpoint, key, standard in providers]
    results = []
    try:
        # Both providers share one server deadline, inside the mobile deadline.
        # A positive result wins; a failed provider must never imply invalidity.
        for future in as_completed(futures, timeout=4):
            result = future.result()
            if result is True:
                return True
            results.append(result)
        return None if None in results else False
    except (TimeoutError, OSError, ValueError):
        return None
    finally:
        for future in futures:
            future.cancel()


def _lookup_noun(endpoint: str, api_key: str, word: str, standard: bool) -> bool | None:
    query = urllib.parse.urlencode(
        {
            "key": api_key,
            "q": word,
            "part": "word",
            "advanced": "y",
            "target": "1",
            "method": "exact",
            "pos": "1",
            "num": "100",
        }
    )
    try:
        with urllib.request.urlopen(f"{endpoint}?{query}", timeout=3) as response:
            payload = response.read(256 * 1024 + 1)
            if len(payload) > 256 * 1024:
                return None
            return _exact_noun_in_response(payload, word, standard=standard)
    except (OSError, ValueError, element_tree.ParseError):
        return None
