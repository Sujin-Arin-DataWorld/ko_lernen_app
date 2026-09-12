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

    def test_content_shard_change_selects_app_and_content_gates(self):
        # Content shards are also canonical TTS inputs after the origin/main
        # merge, so they now pull in `tts` alongside `app` and `content`.
        self.assert_enabled(["assets/data/scenarios_a1.json"], "app", "tts", "content")
        self.assert_enabled(["assets/data/cloze.json"], "app", "tts", "content")
        self.assert_enabled(["assets/data/korean_vocab.csv"], "app", "tts", "content")

    def test_unlisted_assets_data_file_selects_app_and_tts(self):
        self.assert_enabled(["assets/data/foo.json"], "app", "tts")

    def test_tts_function_change_is_not_conflated_with_content_scope(self):
        self.assert_enabled(["functions/tts/index.js"], "tts")

    def test_canonical_tts_inputs_also_verify_server_allowlist(self):
        # assets/data/scenarios_a1.json is also a content shard (see
        # test_content_shard_change_selects_app_and_content_gates above), so
        # it additionally selects `content`; the other canonical inputs are
        # not content shards and stay at app+tts.
        self.assert_enabled(["assets/data/scenarios_a1.json"], "app", "tts", "content")
        for path in ["assets/data/tts_canonical_manifest.json",
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
        for path in ["functions/gye/access_policy.js", "test/fixtures/access_policy/v2.json"]:
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
        for path in [
            "docs/account-deletion-page.js",
            "docs/account-deletion.html",
            "docs/impressum.html",
            "docs/index.html",
            "docs/privacy.html",
            "docs/support.html",
            "docs/terms.html",
        ]:
            self.assert_enabled([path], "app")
        self.assert_enabled(["docs/screenshots/sori-stage-today-390.png"], "app")

    def test_live_asset_contracts_select_app(self):
        for path in (
            "docs/assets/STYLE_LOCK.json",
            "docs/assets/CARD_STYLE_BASELINE.json",
            "docs/assets/VOCAB_PACK_CARD_MANIFEST.json",
            "docs/assets/PHASE_ARTWORK_PRODUCTION.json",
            "docs/assets/SFX_README.md",
            "docs/assets/recipes/listening-card.md",
        ):
            self.assert_enabled([path], "app")

    def test_retired_hanok_provenance_is_docs_only(self):
        for path in (
            "docs/assets/HANOK_V1_ASSET_PROVENANCE.json",
            "docs/assets/hanok_a1_kit/stage_01.json",
            "docs/assets/hanok_a2_overlays/overlays.json",
            "docs/assets/hanok_estate_kit/anchae_stages.json",
        ):
            self.assert_enabled([path])

    def test_curriculum_audit_inputs_and_outputs_select_validation(self):
        for path in [
            "docs/data/level_bible/F1b_grammar_grade12_manual.md",
            "docs/data/level_bible/F1_grammar_map.md",
            "docs/data/curriculum_matrix_report.md",
            "docs/data/cefr_curriculum_matrix.md",
            "docs/data/curriculum_completion_backlog.md",
            "tool/build_curriculum_backlog.py",
            "tool/curriculum_completion_backlog.json",
            "tools/content_factory/cefr_matrix/grammar_correspondence.json",
        ]:
            with self.subTest(path=path):
                self.assert_enabled([path], "app")

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
