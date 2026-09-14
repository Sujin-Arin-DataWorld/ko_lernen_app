"""Test-vector suite for rr_romanize.romanize_korean (task C2a).

Vectors come from two sources, both required by the C2a brief:
  1. The rule list itself (국어의 로마자 표기법 2000, §1/§2/§3) -- vowels,
     consonants, and each named sound change (assimilation, palatalization,
     aspiration merging + the 체언 exception, tensification-not-written,
     liaison, word-final codas, ㄹㄹ).
  2. The 10 sampled defects found in assets/data/korean_vocab.csv romanization
     (C2a sampling: 17/30 vocab romanization errors traced to missing RR
     sound-change rules).

Run standalone: `python tools/content_factory/test_rr_romanize.py`.
"""

from __future__ import annotations

import unittest

from rr_romanize import romanize_korean


class VowelTests(unittest.TestCase):
    def test_simple_vowels(self):
        cases = {
            "아": "a", "어": "eo", "오": "o", "우": "u", "으": "eu", "이": "i",
            "애": "ae", "에": "e", "외": "oe", "위": "wi",
        }
        for korean, expected in cases.items():
            with self.subTest(korean=korean):
                self.assertEqual(romanize_korean(korean), expected)

    def test_y_glide_vowels(self):
        cases = {
            "야": "ya", "여": "yeo", "요": "yo", "유": "yu", "얘": "yae", "예": "ye",
        }
        for korean, expected in cases.items():
            with self.subTest(korean=korean):
                self.assertEqual(romanize_korean(korean), expected)

    def test_w_glide_vowels(self):
        cases = {"와": "wa", "왜": "wae", "워": "wo", "웨": "we"}
        for korean, expected in cases.items():
            with self.subTest(korean=korean):
                self.assertEqual(romanize_korean(korean), expected)

    def test_ui_is_always_ui(self):
        # 의 romanizes "ui" even when pronounced [이] (희망 -> huimang, not
        # himang) -- the notation's own explicit example.
        self.assertEqual(romanize_korean("희망"), "huimang")


class ConsonantTests(unittest.TestCase):
    def test_initial_consonants(self):
        cases = {
            "가": "ga", "까": "kka", "다": "da", "따": "tta", "바": "ba",
            "빠": "ppa", "자": "ja", "짜": "jja", "차": "cha", "카": "ka",
            "타": "ta", "파": "pa", "하": "ha", "사": "sa", "싸": "ssa",
            "나": "na", "마": "ma", "라": "ra",
        }
        for korean, expected in cases.items():
            with self.subTest(korean=korean):
                self.assertEqual(romanize_korean(korean), expected)

    def test_final_consonants(self):
        # ㄱk ㄷt ㅂp ㄹl word-final.
        self.assertEqual(romanize_korean("각"), "gak")
        self.assertEqual(romanize_korean("갇"), "gat")
        self.assertEqual(romanize_korean("갑"), "gap")
        self.assertEqual(romanize_korean("갈"), "gal")


class SoundChangeVectorTests(unittest.TestCase):
    """One vector per bullet in the C2a brief's rule list."""

    def test_assimilation(self):
        self.assertEqual(romanize_korean("백마"), "baengma")
        self.assertEqual(romanize_korean("신문로"), "sinmunno")
        self.assertEqual(romanize_korean("종로"), "jongno")
        self.assertEqual(romanize_korean("왕십리"), "wangsimni")
        self.assertEqual(romanize_korean("별내"), "byeollae")
        self.assertEqual(romanize_korean("신라"), "silla")
        self.assertEqual(romanize_korean("설날"), "seollal")
        self.assertEqual(romanize_korean("학여울"), "hangnyeoul")
        self.assertEqual(romanize_korean("담요"), "damnyo")
        self.assertEqual(romanize_korean("알약"), "allyak")

    def test_palatalization(self):
        self.assertEqual(romanize_korean("해돋이"), "haedoji")
        self.assertEqual(romanize_korean("같이"), "gachi")
        self.assertEqual(romanize_korean("굳히다"), "guchida")

    def test_aspiration_merge_verbs(self):
        # Verb/adjective POS -> ㅎ merges with the adjacent stop.
        self.assertEqual(romanize_korean("좋고", pos="Verb"), "joko")
        self.assertEqual(romanize_korean("놓다", pos="Verb"), "nota")
        self.assertEqual(romanize_korean("잡혀", pos="Verb"), "japyeo")
        self.assertEqual(romanize_korean("낳지", pos="Verb"), "nachi")
        self.assertEqual(romanize_korean("반박하다", pos="Verb"), "banbakada")
        self.assertEqual(romanize_korean("타협하다", pos="Verb"), "tahyeopada")

    def test_aspiration_merge_skipped_for_cheoneon_nouns(self):
        # Noun/expression POS -> ㅎ stays, preceding stop keeps its coda form.
        self.assertEqual(romanize_korean("묵호", pos="Nomen"), "mukho")
        self.assertEqual(romanize_korean("집현전", pos="Nomen"), "jiphyeonjeon")
        self.assertEqual(romanize_korean("역할", pos="Nomen"), "yeokhal")

    def test_tensification_not_written(self):
        self.assertEqual(romanize_korean("압구정"), "apgujeong")
        self.assertEqual(romanize_korean("낙동강"), "nakdonggang")

    def test_liaison(self):
        self.assertEqual(romanize_korean("할인"), "harin")
        self.assertEqual(romanize_korean("특약"), "teugyak")
        self.assertEqual(romanize_korean("무리해서"), "murihaeseo")

    def test_word_final_codas(self):
        self.assertEqual(romanize_korean("카톡"), "katok")
        self.assertEqual(romanize_korean("시댁"), "sidaek")
        self.assertEqual(romanize_korean("기억"), "gieok")

    def test_ll_assimilation(self):
        self.assertEqual(romanize_korean("결론"), "gyeollon")
        self.assertEqual(romanize_korean("올리기"), "olligi")
        self.assertEqual(romanize_korean("물리"), "mulli")


class SampledDefectTests(unittest.TestCase):
    """The 10 vocab.csv rows sampled as RR-rule-caused romanization defects."""

    def test_ban_bak_ha_da(self):
        self.assertEqual(romanize_korean("반박하다", pos="Verb"), "banbakada")

    def test_ta_hyeop_ha_da(self):
        self.assertEqual(romanize_korean("타협하다", pos="Verb"), "tahyeopada")

    def test_muri_haeseo(self):
        self.assertEqual(romanize_korean("무리해서"), "murihaeseo")

    def test_sidaek(self):
        self.assertEqual(romanize_korean("시댁", pos="Nomen"), "sidaek")

    def test_olligi(self):
        self.assertEqual(romanize_korean("올리기", pos="Verb"), "olligi")

    def test_harin(self):
        self.assertEqual(romanize_korean("할인", pos="Nomen"), "harin")

    def test_katok(self):
        self.assertEqual(romanize_korean("카톡", pos="Nomen"), "katok")

    def test_bokjumeoni(self):
        self.assertEqual(romanize_korean("복주머니", pos="Nomen"), "bokjumeoni")

    def test_teugyak(self):
        self.assertEqual(romanize_korean("특약", pos="Nomen"), "teugyak")

    def test_jamjeong_gyeollon(self):
        self.assertEqual(romanize_korean("잠정 결론", pos="Nomen"), "jamjeong gyeollon")

    def test_yeokhal_eoneo(self):
        self.assertEqual(romanize_korean("역할 언어", pos="Nomen"), "yeokhal eoneo")

    def test_gongdong_gieok(self):
        self.assertEqual(romanize_korean("공동 기억", pos="Nomen"), "gongdong gieok")


if __name__ == "__main__":
    unittest.main()
