import unittest

from ci_scope import SCOPES, scopes_for_paths, scopes_for_task


class CiScopeTest(unittest.TestCase):
    def assert_enabled(self, paths, *expected):
        scopes = scopes_for_paths(paths)
        self.assertEqual(
            {name for name, enabled in scopes.items() if enabled},
            set(expected),
        )

    def test_session_log_only_uses_no_runner_gate(self):
        self.assert_enabled(["docs/SESSION_LOG.md", "AGENTS.md"])

    def test_flutter_change_ignores_accompanying_session_log(self):
        self.assert_enabled(
            [r"lib\main.dart", "docs/SESSION_LOG.md"],
            "app",
        )

    def test_isolated_product_areas_select_only_their_gate(self):
        self.assert_enabled(["hangul-sori-site-local/README.md"], "website")
        self.assert_enabled(["functions/analyze_korean_text/main.py"], "book")
        self.assert_enabled(["functions/gye/index.js"], "gye")
        self.assert_enabled(
            ["functions/pronunciation/pronunciation_request_guard.js"],
            "pronunciation",
        )

    def test_shared_firestore_contract_selects_consumers(self):
        self.assert_enabled(
            ["firestore.rules"],
            "app",
            "book",
            "gye",
        )
        self.assert_enabled(
            ["firestore.indexes.json"],
            "book",
            "gye",
        )

    def test_firebase_config_selects_declared_runtime_contracts(self):
        self.assert_enabled(
            ["firebase.json"],
            "app",
            "gye",
            "pronunciation",
        )

    def test_product_docs_consumed_by_flutter_tests_are_not_skipped(self):
        self.assert_enabled(["docs/store/listing-de.md"], "app")
        self.assert_enabled(["docs/privacy.html"], "app")
        self.assert_enabled(["docs/screenshots/sori-stage-today-390.png"], "app")

    def test_website_root_contracts_select_website(self):
        self.assert_enabled(["docs/CNAME"], "website")
        self.assert_enabled(["wrangler.legacy-docs.jsonc"], "website")

    def test_ci_definition_change_fails_open_to_all_scopes(self):
        self.assert_enabled([".github/workflows/ci.yml"], *SCOPES)

    def test_manual_task_mapping(self):
        self.assertIsNone(scopes_for_task("ci"))
        self.assertEqual(scopes_for_task("full"), {scope: True for scope in SCOPES})
        self.assertEqual(
            scopes_for_task("flutter"),
            {scope: scope == "app" for scope in SCOPES},
        )


if __name__ == "__main__":
    unittest.main()
