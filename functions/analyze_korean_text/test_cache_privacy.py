"""Unit tests for source-free, expiring translation cache documents."""

from __future__ import annotations

import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


class _DocumentReference:
    def __init__(self, document_id: str):
        self.id = document_id


class _CollectionReference:
    def document(self, document_id: str) -> _DocumentReference:
        return _DocumentReference(document_id)


class _Snapshot:
    def __init__(self, document_id: str, data: dict[str, object] | None):
        self.id = document_id
        self.exists = data is not None
        self._data = data

    def to_dict(self) -> dict[str, object] | None:
        return self._data


class _Batch:
    def __init__(self):
        self.writes: list[tuple[_DocumentReference, dict[str, object]]] = []
        self.commits = 0

    def set(
        self,
        reference: _DocumentReference,
        payload: dict[str, object],
    ) -> None:
        self.writes.append((reference, payload))

    def commit(self) -> None:
        self.commits += 1


class _Firestore:
    def __init__(self, documents: dict[str, dict[str, object]] | None = None):
        self.documents = documents or {}
        self.last_batch: _Batch | None = None

    def collection(self, _name: str) -> _CollectionReference:
        return _CollectionReference()

    def get_all(self, references: list[_DocumentReference]) -> list[_Snapshot]:
        return [
            _Snapshot(reference.id, self.documents.get(reference.id))
            for reference in references
        ]

    def batch(self) -> _Batch:
        self.last_batch = _Batch()
        return self.last_batch


class TranslationCachePrivacyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        try:
            import main as endpoint
        except ModuleNotFoundError as error:
            raise unittest.SkipTest(f"function runtime dependency unavailable: {error}")
        cls.endpoint = endpoint

    def _assert_source_free_ttl_payload(
        self,
        payload: dict[str, object],
        target: str,
        translation: str,
    ) -> None:
        endpoint = self.endpoint
        self.assertEqual(
            set(payload), {"t", "lang", "version", "expiresAt"}
        )
        self.assertEqual(payload["t"], translation)
        self.assertEqual(payload["lang"], target)
        self.assertEqual(payload["version"], endpoint._CACHE_VERSION)
        expires_at = payload["expiresAt"]
        self.assertIsInstance(expires_at, datetime)
        now = datetime.now(timezone.utc)
        self.assertGreater(expires_at, now + timedelta(days=29, hours=23))
        self.assertLess(expires_at, now + timedelta(days=30, minutes=1))

    def test_runtime_never_loads_a_source_local_dotenv_file(self):
        endpoint = self.endpoint
        source = Path(endpoint.__file__).read_text(encoding="utf-8")

        self.assertFalse(hasattr(endpoint, "_load_dotenv"))
        self.assertNotIn("def _load_dotenv", source)
        self.assertNotIn('os.path.dirname(__file__), ".env"', source)

    def test_sentence_cache_write_contains_no_source_and_expires_in_30_days(self):
        endpoint = self.endpoint
        firestore = _Firestore()
        translator = mock.Mock()
        translator.translate_text.return_value = [
            SimpleNamespace(text="Ich bin Schüler.")
        ]

        with mock.patch.object(
            endpoint, "_get_firestore", return_value=firestore
        ), mock.patch.object(endpoint, "_get_deepl", return_value=translator):
            result = endpoint.translate_batch(["저는 학생이에요."], "DE")

        self.assertEqual(result["저는 학생이에요."], "Ich bin Schüler.")
        self.assertIsNotNone(firestore.last_batch)
        reference, payload = firestore.last_batch.writes[0]
        self.assertNotIn("저는 학생이에요.", reference.id)
        self._assert_source_free_ttl_payload(payload, "DE", "Ich bin Schüler.")

    def test_word_cache_write_also_contains_no_source_text(self):
        endpoint = self.endpoint
        firestore = _Firestore()
        translator = mock.Mock()
        translator.translate_text.return_value = [SimpleNamespace(text="Schüler")]
        words = [{"korean": "학생", "stem": "학생", "pos": "Nomen"}]

        with mock.patch.object(
            endpoint, "_get_firestore", return_value=firestore
        ), mock.patch.object(endpoint, "_get_deepl", return_value=translator):
            result = endpoint.translate_words_with_context(
                words, ["저는 학생이에요."], "DE"
            )

        self.assertEqual(result["학생"], "Schüler")
        self.assertIsNotNone(firestore.last_batch)
        _, payload = firestore.last_batch.writes[0]
        self._assert_source_free_ttl_payload(payload, "DE", "Schüler")
        self.assertNotIn("src", payload)
        self.assertNotIn("sourceLang", payload)

    def test_expired_or_legacy_cache_entries_are_misses(self):
        endpoint = self.endpoint
        source = "저는 학생이에요."
        document_id = endpoint._cache_key(source, "DE")
        firestore = _Firestore(
            {
                document_id: {
                    "t": "stale",
                    "lang": "DE",
                    "version": endpoint._CACHE_VERSION,
                    "expiresAt": datetime.now(timezone.utc) - timedelta(seconds=1),
                }
            }
        )
        translator = mock.Mock()
        translator.translate_text.return_value = [SimpleNamespace(text="fresh")]

        with mock.patch.object(
            endpoint, "_get_firestore", return_value=firestore
        ), mock.patch.object(endpoint, "_get_deepl", return_value=translator):
            result = endpoint.translate_batch([source], "DE")

        self.assertEqual(result[source], "fresh")
        translator.translate_text.assert_called_once()

    def test_current_cache_entry_skips_deepl(self):
        endpoint = self.endpoint
        source = "저는 학생이에요."
        document_id = endpoint._cache_key(source, "DE")
        firestore = _Firestore(
            {
                document_id: {
                    "t": "cached",
                    "lang": "DE",
                    "version": endpoint._CACHE_VERSION,
                    "expiresAt": datetime.now(timezone.utc) + timedelta(days=1),
                }
            }
        )

        with mock.patch.object(
            endpoint, "_get_firestore", return_value=firestore
        ), mock.patch.object(endpoint, "_get_deepl") as deepl:
            result = endpoint.translate_batch([source], "DE")

        self.assertEqual(result[source], "cached")
        deepl.assert_not_called()


if __name__ == "__main__":
    unittest.main()
