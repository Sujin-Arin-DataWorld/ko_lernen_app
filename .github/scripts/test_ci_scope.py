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
        self.assert_enabled(["functions/tts/index.js"], "tts")
        self.assert_enabled(
            ["functions/auth_cleanup/bridge.js"],
            "auth_cleanup",
        )

    def test_canonical_tts_inputs_also_verify_server_allowlist(self):
        for path in ["assets/data/scenarios_a1.json",
                     "assets/data/tts_canonical_manifest.json",
                     "tool/generate_tts.py", "tool/polish_tts.py",
                     "lib/data/hangul_data.dart",
                     "lib/services/placement_diagnostic.dart"]:
            self.assert_enabled([path], "app", "tts")

    def test_ios_native_and_plugin_contracts_require_unsigned_build(self):
        for path in ["ios/Runner/AppDelegate.swift", "ios/Runner/PrivateTtsPlayer.swift",
                     "ios/Podfile.lock", "pubspec.yaml", "pubspec.lock",
                     "test/support/native_test_host.dart"]:
            self.assert_enabled([path], "app", "ios")

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

    def test_storage_privacy_selects_rules_and_callable_consumers(self):
        self.assert_enabled(["storage.rules"], "app", "gye", "tts")

    def test_canonical_access_policy_selects_all_contract_consumers(self):
        for path in ["functions/gye/access_policy.js", "test/fixtures/access_policy/v1.json"]:
            self.assert_enabled([path], "app", "book", "gye", "pronunciation")

    def test_cost_contract_selects_deployment_local_mirrors(self):
        for path in ["functions/pronunciation/service_cost_policy.js",
                     "functions/tts/service_cost_policy.js",
                     "functions/analyze_korean_text/ai_policy.py"]:
            self.assert_enabled([path], "book", "pronunciation", "tts")

    def test_cost_fixture_only_change_includes_tts_consumer(self):
        self.assert_enabled(
            ["test/fixtures/access_policy/cost-v1.json"],
            "app", "book", "gye", "pronunciation", "tts",
        )

    def test_firebase_config_selects_declared_runtime_contracts(self):
        # auth_cleanup is a gen-1 Auth trigger and is not in firebase.json's
        # functions codebases array, so it must stay excluded here.
        self.assert_enabled(
            ["firebase.json"],
            "app",
            "gye",
            "pronunciation",
            "tts",
        )

    def test_product_docs_consumed_by_flutter_tests_are_not_skipped(self):
        self.assert_enabled(["docs/store/listing-de.md"], "app")
        self.assert_enabled(["docs/privacy.html"], "app")
        self.assert_enabled(["docs/screenshots/sori-stage-today-390.png"], "app")

    def test_hanok_provenance_docs_are_not_skipped(self):
        # docs/assets/ carries the provenance JSON and estate/A1 kit stage
        # specs test/hanok_v1_asset_provenance_test.dart asserts against — a
        # provenance-only change must still run the app gate.
        self.assert_enabled(
            ["docs/assets/HANOK_V1_ASSET_PROVENANCE.json"], "app"
        )
        self.assert_enabled(
            ["docs/assets/hanok_estate_kit/anchae_stages.json"], "app"
        )

    def test_website_root_contracts_select_website(self):
        self.assert_enabled(["docs/CNAME"], "website")
        self.assert_enabled(["wrangler.legacy-docs.jsonc"], "website")

    def test_cultural_glossary_selects_both_shipped_consumers(self):
        self.assert_enabled(
            ["docs/data/cultural_glossary.json"],
            "app",
            "website",
        )

    def test_ci_definition_change_fails_open_to_all_scopes(self):
        self.assert_enabled([".github/workflows/ci.yml"], *SCOPES)

    def test_manual_task_mapping(self):
        self.assertIsNone(scopes_for_task("ci"))
        self.assertEqual(scopes_for_task("full"), {scope: True for scope in SCOPES})
        self.assertEqual(
            scopes_for_task("flutter"),
            {scope: scope == "app" for scope in SCOPES},
        )
        self.assertEqual(
            scopes_for_task("release-internal"),
            {scope: scope == "app" for scope in SCOPES},
        )
        self.assertEqual(
            scopes_for_task("release-website"),
            {scope: scope == "website" for scope in SCOPES},
        )
        self.assertEqual(
            scopes_for_task("tts"),
            {scope: scope == "tts" for scope in SCOPES},
        )
        self.assertEqual(
            scopes_for_task("auth-cleanup"),
            {scope: scope == "auth_cleanup" for scope in SCOPES},
        )


if __name__ == "__main__":
    unittest.main()
