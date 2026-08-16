#!/usr/bin/env python3
"""Unit tests for visual PDF audit sampling."""

from __future__ import annotations

import unittest

from render_pdf_audit_samples import sample_pages


class PdfAuditSampleTest(unittest.TestCase):
    def test_samples_front_middle_and_back_without_duplicates(self) -> None:
        self.assertEqual([5, 50, 95], sample_pages(100))
        self.assertEqual([1, 2], sample_pages(3))

    def test_rejects_empty_pdf_count(self) -> None:
        with self.assertRaises(ValueError):
            sample_pages(0)


if __name__ == "__main__":
    unittest.main()
