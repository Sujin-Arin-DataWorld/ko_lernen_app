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

    def test_aspiration_merge_stem_final_h(self):
        # Case (a), Fable ruling 2026-09-15: stem-final ㅎ/ㄶ/ㅀ + ㄱ/ㄷ/ㅈ
        # ending always merges -- this shape only occurs at a native
        # verb/adjective stem's own final consonant. No POS gate needed.
        self.assertEqual(romanize_korean("좋고", pos="Verb"), "joko")
        self.assertEqual(romanize_korean("놓다", pos="Verb"), "nota")
        self.assertEqual(romanize_korean("낳지", pos="Verb"), "nachi")
        self.assertEqual(romanize_korean("많다", pos="Adjektiv"), "manta")
        self.assertEqual(romanize_korean("싫다", pos="Adjektiv"), "silta")
        self.assertEqual(romanize_korean("않다", pos="Verb"), "anta")
        self.assertEqual(romanize_korean("괜찮다", pos="Adjektiv"), "gwaenchanta")
        self.assertEqual(romanize_korean("옳지", pos="Adjektiv"), "olchi")

    def test_aspiration_merge_passive_causative_infix(self):
        # Case (b), Fable ruling 2026-09-15: stop coda + verb-stem's own
        # -히-/-혀- passive/causative infix merges.
        self.assertEqual(romanize_korean("잡혀", pos="Verb"), "japyeo")
        self.assertEqual(romanize_korean("굳히다", pos="Verb"), "guchida")
        self.assertEqual(romanize_korean("먹히다", pos="Verb"), "meokida")
        self.assertEqual(romanize_korean("막히다", pos="Verb"), "makida")
        self.assertEqual(romanize_korean("밟히다", pos="Verb"), "balpida")
        self.assertEqual(romanize_korean("업히다", pos="Verb"), "eopida")

    def test_aspiration_merge_skipped_for_hada_and_cheoneon(self):
        # Fable ruling 2026-09-15 (표기법 §3-1-4 다만 + NIKL/Wiktionary RR
        # module: 축하하다 chukhahada, 도착하다 dochakhada; Cornell/LibGuides
        # haengbokhada): a stop coda before the noun-forming auxiliary 하다
        # (하/해/했) or a 하다-stem's own word-final -히 adverb keeps ㅎ --
        # POS-independent, so this holds even when the whole word is
        # tagged Verb (반박하다, 타협하다, 협력하다 all conjugate as verbs).
        self.assertEqual(romanize_korean("도착하다", pos="Verb"), "dochakhada")
        self.assertEqual(romanize_korean("행복하다", pos="Adjektiv"), "haengbokhada")
        self.assertEqual(romanize_korean("축하하다", pos="Verb"), "chukhahada")
        self.assertEqual(romanize_korean("반박하다", pos="Verb"), "banbakhada")
        self.assertEqual(romanize_korean("타협하다", pos="Verb"), "tahyeophada")
        self.assertEqual(romanize_korean("협력하다", pos="Verb"), "hyeomnyeokhada")
        self.assertEqual(romanize_korean("정확하다", pos="Adjektiv"), "jeonghwakhada")
        self.assertEqual(romanize_korean("정확히", pos="Adverb"), "jeonghwakhi")
        self.assertEqual(romanize_korean("입학", pos="Nomen"), "iphak")
        self.assertEqual(romanize_korean("입학하다", pos="Verb"), "iphakhada")
        # `is_cheoneon_pos` fallback: neither surface pattern above catches
        # these (vowel 오/여, not word-final), only the POS tag does.
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
        # Fable ruling 2026-09-15: the original brief's "banbakada" vector
        # was wrong -- 하다 here is the noun-forming auxiliary on the
        # Sino-Korean root 반박, so ㅎ is kept (표기법 §3-1-4 다만).
        self.assertEqual(romanize_korean("반박하다", pos="Verb"), "banbakhada")

    def test_ta_hyeop_ha_da(self):
        # Fable ruling 2026-09-15: same correction as 반박하다.
        self.assertEqual(romanize_korean("타협하다", pos="Verb"), "tahyeophada")

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
