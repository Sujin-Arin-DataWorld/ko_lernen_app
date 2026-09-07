#!/usr/bin/env python3
"""Tests for tool/refresh_can_do_vocab_fingerprints.py.

Run with:
    python -m unittest tool.test_refresh_can_do_vocab_fingerprints -v

Only covers the T2.3-R2 LF-write regression -- there was no test module for
this tool before. A tiny synthetic fixture (not the real, large repo
assets) is enough: `main()` is exercised end to end by monkeypatching its
three module-level path constants onto a temp dir.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import refresh_can_do_vocab_fingerprints as rcv  # noqa: E402


class MainWritesLfOnlyTest(unittest.TestCase):
    """`main()` rewrote can_do_content_authorities.json via write_text,
    which on Windows retranslates every "\\n" it had just read (the file is
    `eol=lf` in .gitattributes) back into "\\r\\n" -- even for fingerprint
    lines that did not actually change. Proves the fix without touching the
    real (large) repo assets."""

    def test_main_rewrites_authority_file_with_no_cr(self) -> None:
        with tempfile.TemporaryDirectory(prefix="refresh-fp-test-") as tmp:
            root = Path(tmp)

            vocab_path = root / "korean_vocab.csv"
            vocab_path.write_text("id,korean\nvocab_a1_0010,안녕\n", encoding="utf-8")

            smalltalk_path = root / "smalltalk.json"
            smalltalk_path.write_text(
                json.dumps({"phrases": [{"id": "phrase_0001", "ko": "안녕"}]}),
                encoding="utf-8",
            )

            stub_digest = "0" * 64
            authority_path = root / "can_do_content_authorities.json"
            authority_path.write_text(
                "{\n"
                '  "entries": [\n'
                "    {\n"
                '      "sourceVocabId": "vocab_a1_0010",\n'
                f'      "sourceVocabFingerprintSha256": "{stub_digest}"\n'
                "    },\n"
                "    {\n"
                '      "phraseId": "phrase_0001",\n'
                f'      "phraseFingerprintSha256": "{stub_digest}"\n'
                "    }\n"
                "  ]\n"
                "}\n",
                encoding="utf-8",
            )

            with (
                mock.patch.object(rcv, "VOCAB_PATH", vocab_path),
                mock.patch.object(rcv, "SMALLTALK_PATH", smalltalk_path),
                mock.patch.object(rcv, "AUTHORITY_PATH", authority_path),
            ):
                exit_code = rcv.main()

            self.assertEqual(exit_code, 0)
            rewritten = authority_path.read_bytes()
            self.assertNotIn(b"\r", rewritten)
            # both stub fingerprints (deliberately wrong) were refreshed
            self.assertNotIn(stub_digest.encode("ascii"), rewritten)


if __name__ == "__main__":
    unittest.main()
