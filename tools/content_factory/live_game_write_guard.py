"""Keep historical bootstrap writers away from curated runtime corpora."""
import json
from pathlib import Path


def protect_curated_game_asset(destination):
    path = Path(destination)
    if not path.exists():
        return
    try:
        payload = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SystemExit(f'{path.name}: existing data is unreadable; preserved unchanged') from error
    items = payload.get('items') if isinstance(payload, dict) else payload
    if not isinstance(items, list) or any(not isinstance(row, dict) for row in items):
        raise SystemExit(f'{path.name}: existing data has an unknown structure; preserved unchanged')
    protected = ('id', 'sourceVocabId', 'courseUnitIds', 'copyRevision')
    if any(any(field in row for field in protected) for row in items):
        raise SystemExit(
            f'{path.name}: refusing to replace curated data with a legacy bootstrap. '
            'Stable IDs, links and editorial choices are preserved. '
            'Use the validated batch promotion pipeline for live updates.'
        )
    if items:
        raise SystemExit(
            f'{path.name}: existing rows cannot be verified as an empty bootstrap; '
            'preserved unchanged. Use the validated batch promotion pipeline for updates.'
        )
