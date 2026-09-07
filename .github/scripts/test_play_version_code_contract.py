"""versionCode 는 트랙마다 칸이 갈린다 — 두 업로더가 같은 번호를 두고 다투지 않는다.

2026-09-06: 같은 SHA 를 main CI(내부 테스트)와 play_closed.yml(비공개 테스트)이
각각 빌드하면, 커밋 수를 그대로 쓰던 versionCode 가 겹쳐 두 번째 업로드가
"Version code N has already been used." 로 거부됐다. 그래서 릴리스마다 자동
내부배포를 껐다 되돌리는 수작업이 생겼고, 되돌리기를 잊자 내부 테스트 트랙이
2251 에서 멈춰 그 뒤 병합된 Hören 카드 그리드(#274)가 그 트랙 빌드에 없었다.

이제 gradle 이 `커밋 수 × 2 + 트랙 오프셋`을 쓴다. 워크플로의 아티팩트 이름과
심볼 증거 게이트는 같은 식을 bash 로 다시 계산하므로, 두 식이 어긋나면 릴리스가
엉뚱한 번호로 기록된다(증거 게이트가 켜져 있으면 version_mismatch 로 죽는다).
이 테스트가 그 드리프트를 CI 에서 잡는다.
"""

import pathlib
import re
import unittest

GRADLE = pathlib.Path("android/app/build.gradle.kts")
CI = pathlib.Path(".github/workflows/ci.yml")
CLOSED = pathlib.Path(".github/workflows/play_closed.yml")

# bash 쪽 식: version_code="$(( $(git rev-list --count HEAD) * <배수> + <오프셋> ))"
BASH_FORMULA = re.compile(
    r'version_code="\$\(\(\s*\$\(git rev-list --count HEAD\)\s*\*\s*'
    r"(?P<factor>\d+)\s*\+\s*(?P<offset>\d+)\s*\)\)\""
)


class PlayVersionCodeContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gradle = GRADLE.read_text(encoding="utf-8")
        cls.ci = CI.read_text(encoding="utf-8")
        cls.closed = CLOSED.read_text(encoding="utf-8")

    def test_gradle_splits_the_version_code_space_by_track(self):
        gradle = self.gradle
        self.assertIn('System.getenv("PLAY_TRACK")', gradle)
        # 비공개(alpha/closed)만 홀수 칸을 쓴다.
        self.assertRegex(gradle, r'"alpha",\s*"closed"\s*->\s*1')
        self.assertRegex(gradle, r"else\s*->\s*0")
        self.assertRegex(
            gradle, r"commitCount\s*\*\s*2\s*\+\s*playTrackVersionOffset"
        )

    def test_each_workflow_declares_the_track_it_builds_for(self):
        internal = self.ci.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        self.assertIn("PLAY_TRACK: internal", internal)
        self.assertNotIn("PLAY_TRACK: alpha", internal)
        self.assertIn("PLAY_TRACK: alpha", self.closed)
        self.assertNotIn("PLAY_TRACK: internal", self.closed)

    def test_bash_and_gradle_compute_the_same_number(self):
        gradle_factor = int(
            re.search(
                r"commitCount\s*\*\s*(\d+)\s*\+\s*playTrackVersionOffset",
                self.gradle,
            ).group(1)
        )
        internal = self.ci.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        internal_match = BASH_FORMULA.search(internal)
        closed_match = BASH_FORMULA.search(self.closed)
        self.assertIsNotNone(internal_match, "ci.yml lost the versionCode formula")
        self.assertIsNotNone(closed_match, "play_closed.yml lost the formula")
        for match in (internal_match, closed_match):
            self.assertEqual(int(match.group("factor")), gradle_factor)
        # 오프셋은 gradle 의 트랙 매핑과 같아야 한다: internal 0, alpha 1.
        self.assertEqual(int(internal_match.group("offset")), 0)
        self.assertEqual(int(closed_match.group("offset")), 1)

    def test_internal_upload_is_opt_out_so_the_track_cannot_freeze(self):
        release = self.ci.split("  release-internal:", 1)[1].split(
            "  release-website:", 1
        )[0]
        self.assertIn("vars.PLAY_INTERNAL_RELEASE_DISABLED != 'true'", release)
        # opt-in 변수는 되돌리기를 잊는 순간 트랙을 멈춘다 — 되살리지 않는다.
        # (주석에서 옛 이름을 설명하는 건 괜찮다. 금지되는 건 실제 참조다.)
        self.assertNotIn("vars.PLAY_INTERNAL_RELEASE_ENABLED", self.ci)
        self.assertNotIn("vars.PLAY_INTERNAL_RELEASE_ENABLED", self.closed)

    def test_release_names_carry_track_and_version_code(self):
        self.assertIn("· internal · v${version_code} ·", self.ci)
        self.assertIn("· closed · v${version_code} ·", self.closed)


if __name__ == "__main__":
    unittest.main()
