from __future__ import annotations

import copy
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from tool import hanok_asset_delivery as delivery


class _Response:
    def __init__(self, url: str, payload: bytes, *, status: int = 200, final_url: str | None = None):
        self.status = status
        self._url = final_url or url
        self._stream = io.BytesIO(payload)
        self.headers: dict[str, str] = {}

    def read(self, size: int = -1) -> bytes:
        return self._stream.read(size)

    def geturl(self) -> str:
        return self._url

    def close(self) -> None:
        self._stream.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, traceback):
        self.close()


class DeliveryFixture(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary = tempfile.TemporaryDirectory()
        self.root = Path(self._temporary.name)
        self._create_fixture()
        self.manifest = delivery.build_manifest(self.root)

    def tearDown(self) -> None:
        self._temporary.cleanup()

    def _write(self, relative: str, data: bytes) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def _write_json(self, relative: str, value: dict) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")

    def _create_fixture(self) -> None:
        construction_ids = [
            "hyeopmun",
            "changgo",
            "jungmunganchae",
            "araechae",
            "anchae",
            "anchae-store",
            "ansarangchae",
            "sadangmun",
            "sadang",
        ]
        series = []
        for building_id in construction_ids:
            suffix = "png" if building_id not in {"hyeopmun", "changgo"} else "webp"
            asset = (
                "assets/illustrations/personal_hanok_v3/construction/"
                f"{building_id}/stage_01.{suffix}"
            )
            series.append(
                {
                    "buildingId": building_id,
                    "name": {"ko": building_id, "en": building_id, "de": building_id},
                    "stages": [{"asset": asset}],
                }
            )
            self._write(asset, f"construction:{building_id}".encode())
        self._write_json(
            delivery.CONSTRUCTION_CATALOG.as_posix(),
            {"schemaVersion": 1, "series": series},
        )

        world = {
            "canvas": {"asset": "canvas.png"},
            "gates": [
                {"id": "west", "asset": "gate.png"},
                {"id": "east", "asset": "gate.png"},
            ],
            "buildings": [{"id": "house", "asset": "house.webp"}],
            "decorations": [{"id": "tree", "asset": "tree.png"}],
        }
        self._write_json(delivery.WORLD_CATALOG.as_posix(), world)
        for name in {"canvas.png", "gate.png", "house.webp", "tree.png"}:
            self._write(
                f"assets/illustrations/personal_hanok_v3/world/{name}",
                f"world:{name}".encode(),
            )

        frame_groups = [
            "anchae",
            "anchae_store",
            "ansarangchae",
            "araechae",
            "changgo",
            "gokgan",
            "jungmunganchae",
            "sadang",
            "sadang_hyeopmun",
            "sadangmun",
            "sotdaeulmun",
            "toilet",
        ]
        dart_lines = ["// literal frame fixture"]
        for group in frame_groups:
            name = f"ildu_{group}_00_front.png"
            dart_lines.append(f"final frame{len(dart_lines)} = _frame('{name}', 1, 1, 0, 0, 1, 1);")
            payload = f"turntable:{group}".encode()
            if group == "anchae":
                payload = b"construction:anchae"  # distinct PNG paths, shared immutable object
            self._write(
                f"assets/illustrations/personal_hanok_v3/turnarounds/{name}", payload
            )
        dart = self.root / delivery.TURNTABLE_CATALOG
        dart.parent.mkdir(parents=True, exist_ok=True)
        dart.write_text("\n".join(dart_lines) + "\n", encoding="utf-8")

        # Unreferenced siblings prove they stay bundled but never enter the manifest.
        self._write(
            "assets/illustrations/personal_hanok_v3/turnarounds/unreferenced.png", b"stray-image"
        )
        self._write(
            "assets/illustrations/personal_hanok_v3/turnarounds/README.txt", b"retain-me"
        )
        self._write(
            "assets/illustrations/personal_hanok_v3/construction/changgo/notes.txt", b"retain-me-too"
        )
        self._write("assets/illustrations/personal_hanok_v3/sarangchae/stage_16.png", b"starter")
        self._write("assets/illustrations/unrelated/keep.png", b"unrelated")
        self._write("assets/fonts/test.ttf", b"font")

        pubspec = [
            "name: fixture\n",
            "flutter:\n",
            "  assets:\n",
            "    - assets/data/\n",
            "    - assets/illustrations/personal_hanok_v3/world/\n",
            "    - assets/illustrations/personal_hanok_v3/turnarounds/ # retained comment\n",
            "    - assets/illustrations/personal_hanok_v3/sarangchae/\n",
            "    - assets/illustrations/personal_hanok_v3/construction/hyeopmun/\n",
        ]
        for building_id in construction_ids:
            if building_id == "hyeopmun":
                continue
            pubspec.append(
                f"    - assets/illustrations/personal_hanok_v3/construction/{building_id}/\n"
            )
        pubspec.extend(
            [
                "    # unrelated asset comment\n",
                "    - assets/illustrations/unrelated/\n",
                "  fonts:\n",
                "    - family: Fixture\n",
                "      fonts:\n",
                "        - asset: assets/fonts/test.ttf\n",
            ]
        )
        (self.root / delivery.PUBSPEC_PATH).write_text("".join(pubspec), encoding="utf-8")

    def _persist_manifest(self, manifest: dict | None = None) -> Path:
        path = self.root / delivery.MANIFEST_PATH
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(manifest or self.manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        return path

    def _payloads_by_url(self) -> dict[str, bytes]:
        payloads: dict[str, bytes] = {}
        for _pack_id, asset in delivery.iter_assets(self.manifest):
            path = self.root / Path(*Path(asset["asset"]).parts)
            payloads[delivery.firebase_media_url(asset["storagePath"])] = path.read_bytes()
        return payloads


class ManifestTests(DeliveryFixture):
    def test_manifest_is_deterministic_and_uses_exact_storage_schema(self) -> None:
        self.assertEqual(self.manifest, delivery.build_manifest(self.root))
        self.assertEqual(13, len(self.manifest["packs"]))
        self.assertEqual(delivery.STORAGE_BUCKET, self.manifest["storageBucket"])
        assets = [asset for _pack, asset in delivery.iter_assets(self.manifest)]
        self.assertEqual(23, len(assets))
        for asset in assets:
            self.assertRegex(asset["sha256"], r"^[0-9a-f]{64}$")
            extension = Path(asset["asset"]).suffix.lstrip(".")
            self.assertEqual(
                f"learning-art/v1/{asset['sha256']}.{extension}", asset["storagePath"]
            )
            source = self.root / Path(*Path(asset["asset"]).parts)
            self.assertEqual(source.stat().st_size, asset["bytes"])
        manifest_paths = {asset["asset"] for asset in assets}
        self.assertNotIn(
            "assets/illustrations/personal_hanok_v3/turnarounds/unreferenced.png",
            manifest_paths,
        )
        self.assertNotIn(
            "assets/illustrations/personal_hanok_v3/construction/hyeopmun/stage_01.webp",
            manifest_paths,
        )
        self.assertNotIn(
            "assets/illustrations/personal_hanok_v3/world/tree.png",
            manifest_paths,
        )
        hyeopmun = next(pack for pack in self.manifest["packs"] if pack["id"] == "hyeopmun")
        self.assertEqual(1, len(hyeopmun["assets"]))
        self.assertIn("sadang_hyeopmun", hyeopmun["assets"][0]["asset"])

    def test_duplicate_source_path_is_rejected(self) -> None:
        invalid = copy.deepcopy(self.manifest)
        invalid["packs"][1]["assets"].append(copy.deepcopy(invalid["packs"][0]["assets"][0]))
        with self.assertRaises(delivery.ManifestError):
            delivery.validate_manifest(invalid)

    def test_local_verification_rejects_stale_manifest(self) -> None:
        source = self.root / self.manifest["packs"][0]["assets"][0]["asset"]
        source.write_bytes(source.read_bytes() + b"changed")
        with self.assertRaises(delivery.VerificationError):
            delivery.verify_local_assets(self.root, self.manifest)
        with self.assertRaises(delivery.VerificationError):
            delivery.verify_manifest_current(self.root, self.manifest)

    def test_shared_digest_uses_one_remote_object(self) -> None:
        assets = [asset for _pack, asset in delivery.iter_assets(self.manifest)]
        shared = [asset for asset in assets if asset["sha256"] == hashlib.sha256(b"construction:anchae").hexdigest()]
        self.assertEqual(2, len(shared))
        self.assertEqual(1, len({asset["storagePath"] for asset in shared}))


class PubspecTests(DeliveryFixture):
    def test_candidate_excludes_exact_manifest_and_retains_starters_and_strays(self) -> None:
        original = (self.root / delivery.PUBSPEC_PATH).read_text(encoding="utf-8")
        candidate = delivery.hybrid_pubspec(self.root, self.manifest)
        before = delivery.pubspec_asset_paths(self.root, original)
        after = delivery.pubspec_asset_paths(self.root, candidate)
        manifest_paths = {asset["asset"] for _pack, asset in delivery.iter_assets(self.manifest)}
        self.assertEqual(manifest_paths, before - after)
        self.assertFalse(after - before)
        self.assertIn(
            "assets/illustrations/personal_hanok_v3/sarangchae/stage_16.png", after
        )
        self.assertIn(
            "assets/illustrations/personal_hanok_v3/construction/hyeopmun/stage_01.webp",
            after,
        )
        self.assertIn(
            "assets/illustrations/personal_hanok_v3/turnarounds/unreferenced.png", after
        )
        self.assertIn(
            "assets/illustrations/personal_hanok_v3/turnarounds/README.txt", after
        )
        self.assertIn("# retained comment", candidate)
        self.assertIn("# unrelated asset comment", candidate)
        self.assertIn("fonts:\n    - family: Fixture", candidate.replace("\r\n", "\n"))
        self.assertEqual(original, (self.root / delivery.PUBSPEC_PATH).read_text(encoding="utf-8"))

    def test_report_separates_nonimage_strays(self) -> None:
        report = delivery.packaging_report(self.root, self.manifest)
        self.assertTrue(report["candidateExcludesExactlyManifest"])
        self.assertEqual(1, report["fontFileCount"])
        self.assertEqual(
            report["beforeBundledRawBytes"] + report["fontRawBytes"],
            report["beforeProjectAssetAndFontRawBytes"],
        )
        self.assertIn(
            "assets/illustrations/personal_hanok_v3/turnarounds/README.txt",
            report["nonImageFilesRetained"],
        )
        self.assertIn(
            "assets/illustrations/personal_hanok_v3/turnarounds/unreferenced.png",
            report["unreferencedImagesRetained"],
        )


class StagingTests(DeliveryFixture):
    def test_stage_deduplicates_objects_and_never_needs_a_network(self) -> None:
        output = self.root / "build/hanok-delivery"
        result = delivery.stage_upload_objects(self.root, self.manifest, output)
        metadata = json.loads((output / "staging/metadata.json").read_text(encoding="utf-8"))
        self.assertEqual(result["objectCount"], len(metadata["objects"]))
        self.assertLess(result["objectCount"], 23)
        shared = [item for item in metadata["objects"] if len(item["sourceAssets"]) == 2]
        self.assertEqual(1, len(shared))
        self.assertEqual({"canonical": "true"}, shared[0]["customMetadata"])
        for item in metadata["objects"]:
            staged = output / "staging/objects" / item["storagePath"]
            self.assertEqual(item["bytes"], staged.stat().st_size)


class AppCheckTests(DeliveryFixture):
    def test_token_is_attached_only_to_fixed_no_redirect_requests(self) -> None:
        payloads = self._payloads_by_url()
        token = "fixture.token.signature"

        def receive(request, *, timeout):
            self.assertIn(request.full_url, payloads)
            self.assertEqual(token, request.get_header("X-firebase-appcheck"))
            self.assertGreater(timeout, 0)
            return _Response(request.full_url, payloads[request.full_url])

        opener = mock.Mock()
        opener.open.side_effect = receive
        with mock.patch.object(delivery, "build_opener", return_value=opener) as factory:
            result = delivery.verify_remote_assets(self.manifest, app_check_token=token)
        self.assertGreater(result["objectCount"], 0)
        self.assertNotIn(token, json.dumps(result))
        self.assertTrue(all(call.args == (delivery._NoRedirect,) for call in factory.call_args_list))

    def test_missing_or_invalid_env_token_fails_without_exposing_value(self) -> None:
        with mock.patch.dict(delivery.os.environ, {}, clear=True):
            with self.assertRaises(delivery.VerificationError):
                delivery._app_check_token_from_env("HANOK_TEST_TOKEN")
        for value in ("", "secret\r\nHeader: injected", "secret with space"):
            with mock.patch.dict(delivery.os.environ, {"HANOK_TEST_TOKEN": value}):
                with self.assertRaises(delivery.VerificationError) as error:
                    delivery._app_check_token_from_env("HANOK_TEST_TOKEN")
                if value:
                    self.assertNotIn(value, str(error.exception))
        self.assertIsNone(delivery._app_check_token_from_env(None))

    def test_remote_failure_never_echoes_response_or_token(self) -> None:
        token = "fixture.token.signature"
        with self.assertRaises(delivery.VerificationError) as error:
            delivery.verify_remote_assets(
                self.manifest, app_check_token=token,
                open_url=mock.Mock(side_effect=OSError("untrusted response " + token)),
            )
        self.assertNotIn(token, str(error.exception))


class ActivationTests(DeliveryFixture):
    def setUp(self) -> None:
        super().setUp()
        self._persist_manifest()

    def _activation(self, opener, output_name: str = "activation"):
        original = (self.root / delivery.PUBSPEC_PATH).read_bytes()
        fingerprint = hashlib.sha256(original).hexdigest()
        with mock.patch.object(delivery, "ensure_non_main_worktree"):
            return delivery.activate(
                self.root,
                self.manifest,
                expected_pubspec_sha256=fingerprint,
                output_dir=self.root / "build" / output_name,
                open_url=opener,
            )

    def test_each_remote_failure_leaves_pubspec_unchanged(self) -> None:
        payloads = self._payloads_by_url()
        first_url = sorted(payloads)[0]
        original = (self.root / delivery.PUBSPEC_PATH).read_bytes()

        def missing(url: str, timeout: float):
            raise OSError("missing")

        def incorrect(url: str, timeout: float):
            data = payloads[url]
            if url == first_url:
                data = bytes([data[0] ^ 0xFF]) + data[1:]
            return _Response(url, data)

        def redirected(url: str, timeout: float):
            return _Response(url, payloads[url], final_url="https://example.invalid/redirect")

        def oversized(url: str, timeout: float):
            data = payloads[url] + (b"x" if url == first_url else b"")
            return _Response(url, data)

        for name, opener in (
            ("missing", missing),
            ("incorrect", incorrect),
            ("redirected", redirected),
            ("oversized", oversized),
        ):
            with self.subTest(name=name):
                with self.assertRaises(delivery.VerificationError):
                    self._activation(opener, output_name=name)
                self.assertEqual(original, (self.root / delivery.PUBSPEC_PATH).read_bytes())

    def test_success_writes_backup_candidate_receipt_then_pubspec(self) -> None:
        payloads = self._payloads_by_url()

        def exact(url: str, timeout: float):
            return _Response(url, payloads[url])

        receipt = self._activation(exact)
        output = self.root / "build/activation"
        self.assertTrue((output / "pubspec.full-bundle.yaml").is_file())
        self.assertTrue((output / "candidate-pubspec.yaml").is_file())
        self.assertTrue((output / "activation-receipt.json").is_file())
        self.assertEqual(
            receipt["candidatePubspecSha256"],
            hashlib.sha256((self.root / delivery.PUBSPEC_PATH).read_bytes()).hexdigest(),
        )

    def test_shipped_manifest_must_match_even_when_alternate_manifest_is_valid(self) -> None:
        stale = copy.deepcopy(self.manifest)
        stale["packs"].pop()
        self._persist_manifest(stale)
        original = (self.root / delivery.PUBSPEC_PATH).read_bytes()
        with self.assertRaises(delivery.ActivationRefused):
            self._activation(lambda url, timeout: self.fail("network must not be reached"))
        self.assertEqual(original, (self.root / delivery.PUBSPEC_PATH).read_bytes())

    def test_edit_during_remote_verification_is_preserved(self) -> None:
        payloads = self._payloads_by_url()
        pubspec = self.root / delivery.PUBSPEC_PATH
        edited = pubspec.read_bytes() + b"\n# concurrent local edit\n"

        def edit_then_respond(url, timeout):
            pubspec.write_bytes(edited)
            return _Response(url, payloads[url])

        with self.assertRaises(delivery.ActivationRefused):
            self._activation(edit_then_respond)
        self.assertEqual(edited, pubspec.read_bytes())

    def test_manifest_edit_during_remote_verification_refuses_activation(self) -> None:
        payloads = self._payloads_by_url()
        original = (self.root / delivery.PUBSPEC_PATH).read_bytes()
        stale = copy.deepcopy(self.manifest)
        stale["packs"].pop()

        def edit_then_respond(url, timeout):
            self._persist_manifest(stale)
            return _Response(url, payloads[url])

        with self.assertRaises(delivery.ActivationRefused):
            self._activation(edit_then_respond)
        self.assertEqual(original, (self.root / delivery.PUBSPEC_PATH).read_bytes())

    def test_slow_object_deadline_closes_response_and_preserves_pubspec(self) -> None:
        payloads = self._payloads_by_url()
        original = (self.root / delivery.PUBSPEC_PATH).read_bytes()
        responses = []
        clock = [0.0]

        class SlowResponse(_Response):
            def read1(self, size):
                clock[0] += 21.0
                return self._stream.read(size)

        def slow(url, timeout):
            response = SlowResponse(url, payloads[url])
            responses.append(response)
            return response

        with mock.patch.object(delivery.time, "monotonic", side_effect=lambda: clock[0]):
            with self.assertRaises(delivery.VerificationError):
                self._activation(slow)
        self.assertTrue(responses[0]._stream.closed)
        self.assertEqual(original, (self.root / delivery.PUBSPEC_PATH).read_bytes())

    def test_stale_manifest_rejection_leaves_pubspec_unchanged(self) -> None:
        original = (self.root / delivery.PUBSPEC_PATH).read_bytes()
        stale = copy.deepcopy(self.manifest)
        stale["packs"][0]["title"]["en"] += " stale"
        with mock.patch.object(delivery, "ensure_non_main_worktree"):
            with self.assertRaises(delivery.VerificationError):
                delivery.activate(
                    self.root,
                    stale,
                    expected_pubspec_sha256=hashlib.sha256(original).hexdigest(),
                    output_dir=self.root / "build/stale",
                    open_url=lambda url, timeout: self.fail("network must not be reached"),
                )
        self.assertEqual(original, (self.root / delivery.PUBSPEC_PATH).read_bytes())

    def test_main_worktree_is_rejected(self) -> None:
        (self.root / ".git").write_text("gitdir: fixture", encoding="utf-8")
        with mock.patch.object(delivery, "_git_output", side_effect=[str(self.root), "main"]):
            with self.assertRaises(delivery.ActivationRefused):
                delivery.ensure_non_main_worktree(self.root)


if __name__ == "__main__":
    unittest.main()
