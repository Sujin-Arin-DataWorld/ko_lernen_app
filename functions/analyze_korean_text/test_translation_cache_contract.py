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

    def test_legacy_and_quota_collections_are_server_only(self):
        rules = (REPO_ROOT / "firestore.rules").read_text(encoding="utf-8")
        for path in (
            r"match\s+/cache/\{document=\*\*\}",
            r"match\s+/usage/\{document=\*\*\}",
            r"match\s+/service_quotas/\{document=\*\*\}",
            r"match\s+/service_quota_ledgers/\{document=\*\*\}",
        ):
            self.assertRegex(
                rules,
                re.compile(
                    path + r"\s*\{\s*allow\s+read,\s*write:\s*if\s+false;\s*\}",
                    re.DOTALL,
                ),
            )

    def test_usage_and_quota_ledgers_have_ttl_overrides(self):
        indexes = json.loads(
            (REPO_ROOT / "firestore.indexes.json").read_text(encoding="utf-8")
        )
        ttl_groups = {
            (
                override.get("collectionGroup"),
                override.get("fieldPath"),
                override.get("ttl"),
            )
            for override in indexes.get("fieldOverrides", [])
        }
        self.assertIn(("usage", "expiresAt", True), ttl_groups)
        self.assertIn(("service_quota_ledgers", "expiresAt", True), ttl_groups)
