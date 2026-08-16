import json
import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


class TranslationCacheInfrastructureContractTest(unittest.TestCase):
    def test_firestore_rules_explicitly_deny_all_client_access(self):
        rules = (REPO_ROOT / "firestore.rules").read_text(encoding="utf-8")

        self.assertRegex(
            rules,
            re.compile(
                r"match\s+/translation_cache/\{document=\*\*\}\s*\{\s*"
                r"allow\s+read,\s*write:\s*if\s+false;\s*\}",
                re.DOTALL,
            ),
        )

    def test_translation_cache_expires_at_has_ttl_override(self):
        indexes = json.loads(
            (REPO_ROOT / "firestore.indexes.json").read_text(encoding="utf-8")
        )
        matches = [
            override
            for override in indexes.get("fieldOverrides", [])
            if override.get("collectionGroup") == "translation_cache"
            and override.get("fieldPath") == "expiresAt"
        ]

        self.assertEqual(matches, [{
            "collectionGroup": "translation_cache",
            "fieldPath": "expiresAt",
            "ttl": True,
            "indexes": [],
        }])
