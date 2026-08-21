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

    def test_post_clone_prepares_rive_after_installing_pods(self):
        repository_root = 'cd "${CI_PRIMARY_REPOSITORY_PATH}"'
        pub_get = "flutter pub get"
        rive_setup = (
            "dart run rive_native:setup --verbose --clean --platform ios"
        )
        ios_root = 'cd "${CI_PRIMARY_REPOSITORY_PATH}/ios"'
        commands = [line.strip() for line in self.post_clone.splitlines()]
        pod_install_index = next(
            index
            for index, command in enumerate(commands)
            if command.startswith("if pod install;")
        )

        self.assertLess(
            commands.index(repository_root),
            commands.index(pub_get),
        )
        self.assertLess(commands.index(pub_get), commands.index(ios_root))
        self.assertLess(commands.index(ios_root), pod_install_index)
        self.assertLess(pod_install_index, commands.index(rive_setup))

    def test_post_clone_marks_the_exact_rive_cocoapods_source_as_ready(self):
        self.assertIn(
            'RIVE_NATIVE_IOS_ROOT="${CI_PRIMARY_REPOSITORY_PATH}/ios/'
            '.symlinks/plugins/rive_native"',
            self.post_clone,
        )
        self.assertIn(
            'RIVE_NATIVE_IOS_MARKER="${RIVE_NATIVE_IOS_ROOT}/ios/'
            'rive_marker_ios_setup_complete"',
            self.post_clone,
        )
        self.assertIn(
            'RIVE_NATIVE_DEVICE_LIBRARY="${RIVE_NATIVE_IOS_ROOT}/native/build/'
            'iphoneos/bin/release/librive_native.a"',
            self.post_clone,
        )
        self.assertIn(
            'RIVE_NATIVE_SIMULATOR_LIBRARY="${RIVE_NATIVE_IOS_ROOT}/native/'
            'build/iphoneos/bin/emulator/librive_native.a"',
            self.post_clone,
        )
        self.assertIn('touch "${RIVE_NATIVE_IOS_MARKER}"', self.post_clone)

    def test_post_clone_retries_transient_cocoapods_download_failures(self):
        self.assertIn('while [ "${POD_INSTALL_ATTEMPT}" -le 3 ]; do', self.post_clone)
        self.assertIn("if pod install; then", self.post_clone)
        self.assertIn('if [ "${POD_INSTALL_ATTEMPT}" -eq 3 ]; then', self.post_clone)
        self.assertIn('sleep "${POD_INSTALL_RETRY_DELAY}"', self.post_clone)


if __name__ == "__main__":
    unittest.main()
