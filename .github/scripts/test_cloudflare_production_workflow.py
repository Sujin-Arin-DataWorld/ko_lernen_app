import pathlib
import unittest


class CloudflareProductionWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = pathlib.Path(".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )
        cls.release = cls.workflow.split("  release-website:", 1)[1].split(
            "\n  book-analysis-security:", 1
        )[0]

    def test_shared_glossary_is_a_workflow_trigger(self):
        self.assertGreaterEqual(
            self.workflow.count("'docs/data/cultural_glossary.json'"),
            2,
        )

    def test_release_waits_for_website_gate_and_explicit_enablement(self):
        self.assertIn("needs: [changes, website]", self.release)
        self.assertIn("needs.website.result == 'success'", self.release)
        self.assertIn("github.ref == 'refs/heads/main'", self.release)
        self.assertIn(
            "vars.WEBSITE_PRODUCTION_RELEASE_ENABLED == 'true'",
            self.release,
        )
        self.assertIn("name: cloudflare-production", self.release)

    def test_release_uses_exact_commit_and_production_credentials(self):
        self.assertIn("fetch-depth: 0", self.release)
        self.assertIn("WORKERS_CI_COMMIT_SHA: ${{ github.sha }}", self.release)
        self.assertIn("CLOUDFLARE_API_TOKEN", self.release)
        self.assertIn("CLOUDFLARE_ACCOUNT_ID", self.release)
        self.assertIn("npm run deploy", self.release)


if __name__ == "__main__":
    unittest.main()
