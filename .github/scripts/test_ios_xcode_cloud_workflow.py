import pathlib
import re
import unittest


class IosXcodeCloudWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pubspec = pathlib.Path("pubspec.yaml").read_text(encoding="utf-8")
        cls.post_clone = pathlib.Path(
            "ios/ci_scripts/ci_post_clone.sh"
        ).read_text(encoding="utf-8")

    def test_cocoapods_only_project_disables_flutter_swiftpm(self):
        flutter_section = self.pubspec.split("\nflutter:\n", 1)[1].split(
            "\nflutter_launcher_icons:", 1
        )[0]

        self.assertRegex(
            flutter_section,
            re.compile(
                r"^  config:\n"
                r"    enable-swift-package-manager: false$",
                re.MULTILINE,
            ),
            "The iOS project removed FlutterGeneratedPluginSwiftPackage, so "
            "Flutter 3.44+ must resolve every iOS plugin through CocoaPods.",
        )

    def test_post_clone_reads_project_config_before_installing_pods(self):
        repository_root = 'cd "${CI_PRIMARY_REPOSITORY_PATH}"'
        pub_get = "flutter pub get"
        ios_root = 'cd "${CI_PRIMARY_REPOSITORY_PATH}/ios"'
        pod_install = "pod install"
        commands = [line.strip() for line in self.post_clone.splitlines()]

        self.assertLess(
            commands.index(repository_root),
            commands.index(pub_get),
        )
        self.assertLess(commands.index(pub_get), commands.index(ios_root))
        self.assertLess(commands.index(ios_root), commands.index(pod_install))


if __name__ == "__main__":
    unittest.main()
