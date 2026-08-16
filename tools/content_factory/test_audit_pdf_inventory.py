#!/usr/bin/env python3
"""Unit tests for source-free PDF inventory classification helpers."""

from __future__ import annotations

import unittest

from audit_pdf_inventory import classify_text_layer


class PdfInventoryClassificationTest(unittest.TestCase):
    def test_text_requires_broad_and_substantial_page_coverage(self) -> None:
        self.assertEqual("text", classify_text_layer([180] * 9 + [30]))

    def test_image_requires_nearly_empty_text_layer(self) -> None:
        self.assertEqual("image", classify_text_layer([0] * 9 + [5]))

    def test_partial_or_shallow_coverage_is_mixed(self) -> None:
        self.assertEqual("mixed", classify_text_layer([150] * 5 + [0] * 5))
        self.assertEqual("mixed", classify_text_layer([30] * 10))
        self.assertEqual("mixed", classify_text_layer([150, 150] + [0] * 18))


if __name__ == "__main__":
    unittest.main()
