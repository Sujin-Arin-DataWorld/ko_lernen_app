#!/usr/bin/env python3
"""P1: every recurring character must carry a speech-style spec.

Guards `tools/content_factory/canonical_scenarios/character_profiles.json`
so authors always have a `speechStyle` block (ko/de/en + byLevel) and the
top-level `speechStylePolicy` line for every one of the 11 recurring
characters (the 7 original leads plus minho/dongsun/byeongcheol/jun added
for relationship density), and that `relationshipGraph` stays internally
consistent (edges reference real ids, no duplicate unordered pairs,
hiddenLinks point at real edges, every character appears in >=1 edge,
storyArcs cover A1/A2/B1/B2/C1+).

Run with:
    python3 -m unittest tools/content_factory/test_character_profiles_speech_style.py
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PROFILES_PATH = (
    REPO_ROOT
    / "tools"
    / "content_factory"
    / "canonical_scenarios"
    / "character_profiles.json"
)

REQUIRED_LANG_KEYS = {"baseRegister", "markers", "sentenceHabits", "avoid"}
REQUIRED_LEVEL_KEYS = {"A1", "A2", "B1+"}
EXPECTED_CHARACTER_COUNT = 11
EXPECTED_STORY_ARC_LEVELS = {"A1", "A2", "B1", "B2", "C1+"}

# R8 (Fable review of PR #337): A1 = 국제통용 1급 45항목 ONLY
# (docs/CONTENT_LEVEL_BIBLE.md §B.1 ③). Anything past that grammar set is
# A2+ even if it "sounds simple": -을/ㄹ게요 (2급 intention), 반말 -냐/-야
# questions (2급 banmal), -으면 (2급 conditional), -을 줄 알다 (3급), and the
# sentence-enders -네요/-는데/-지요·죠/-을래요.
#
# -(으)ㄹ게요/-(으)ㄹ래요 attach their ㄹ/을 as the BATCHIM of a single
# precomposed syllable for vowel- or ㄹ-final stems (할게요, 갈래요) rather
# than as a separate character, so a literal "(ㄹ|을)" class only catches
# the consonant-stem spelling (먹을게요) and silently misses the contracted
# one that our own draft actually used (할게요, 줄게요). We therefore check
# the endings themselves against the line with trailing sentence punctuation
# stripped, with one documented allowlist entry: "그래요" (from the
# irregular verb 그렇다, a common 1급 reply) coincidentally ends in "래요"
# but is not the -(으)ㄹ래요 grammar.
_TRAILING_PUNCT = re.compile(r"[\s.!?…]+$")
_A1_ALLOWLIST_CORES = {"그래요"}
_FORBIDDEN_A1_SUFFIXES = ("게요", "래요", "네요", "죠")
_FORBIDDEN_A1_BANMAL_Q_SUFFIXES = ("냐", "야")
FORBIDDEN_A1_MIDSENTENCE = re.compile(r"으?면 |줄 알|는데|지요")


def _forbidden_a1_pattern(line: str) -> str | None:
    """Return the offending A2+ pattern in `line`, or None if it is 1급-safe."""
    core = _TRAILING_PUNCT.sub("", line)
    if core not in _A1_ALLOWLIST_CORES:
        for suffix in _FORBIDDEN_A1_SUFFIXES:
            if core.endswith(suffix):
                return f"-{suffix}"
        for suffix in _FORBIDDEN_A1_BANMAL_Q_SUFFIXES:
            if core.endswith(suffix):
                return f"반말 -{suffix}"
    match = FORBIDDEN_A1_MIDSENTENCE.search(line)
    if match:
        return match.group()
    return None
# Retired persona drafts / facts that the owner explicitly replaced. Kept
# here so a future edit can't silently reintroduce a superseded detail.
RETIRED_STRINGS = (
    "youngsook",  # renamed to dongsun
    "전주",  # sujin's parents live in Suwon, not Jeonju
    "반찬 가게",  # dongsun sells jewelry, not banchan
    "체육 교사",  # byeongcheol is an electrical engineer, not a retired PE teacher
)


class CharacterProfilesSpeechStyleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        with PROFILES_PATH.open(encoding="utf-8") as handle:
            cls.payload = json.load(handle)

    def test_speech_style_policy_line_exists(self) -> None:
        policy = self.payload.get("speechStylePolicy")
        self.assertIsInstance(policy, str)
        self.assertTrue(policy.strip())
        # The policy must actually name all three level bands, otherwise it
        # is not doing its job of scoping markers to level grammar.
        for band in ("A1", "A2", "B1+"):
            self.assertIn(band, policy, msg=f"policy string must mention {band}")

    def test_every_recurring_character_has_speech_style(self) -> None:
        characters = self.payload.get("recurringCharacters")
        self.assertIsInstance(characters, list)
        self.assertEqual(
            len(characters),
            EXPECTED_CHARACTER_COUNT,
            f"expected the {EXPECTED_CHARACTER_COUNT} canonical recurring characters",
        )

        for character in characters:
            char_id = character.get("id")
            with self.subTest(character=char_id):
                speech_style = character.get("speechStyle")
                self.assertIsInstance(
                    speech_style, dict, msg=f"{char_id} is missing speechStyle"
                )

                for lang in ("ko", "de", "en"):
                    with self.subTest(character=char_id, lang=lang):
                        lang_block = speech_style.get(lang)
                        self.assertIsInstance(
                            lang_block,
                            dict,
                            msg=f"{char_id}.speechStyle.{lang} must be an object",
                        )
                        missing = REQUIRED_LANG_KEYS - lang_block.keys()
                        self.assertFalse(
                            missing,
                            msg=f"{char_id}.speechStyle.{lang} missing keys {missing}",
                        )

                        base_register = lang_block.get("baseRegister")
                        self.assertIsInstance(base_register, str)
                        self.assertTrue(base_register.strip())

                        for list_field in ("markers", "sentenceHabits", "avoid"):
                            values = lang_block.get(list_field)
                            self.assertIsInstance(
                                values,
                                list,
                                msg=f"{char_id}.speechStyle.{lang}.{list_field} must be a list",
                            )
                            self.assertTrue(
                                values,
                                msg=(
                                    f"{char_id}.speechStyle.{lang}.{list_field} "
                                    "must not be empty"
                                ),
                            )
                            for entry in values:
                                self.assertIsInstance(entry, str)
                                self.assertTrue(entry.strip())

                by_level = speech_style.get("byLevel")
                self.assertIsInstance(
                    by_level, dict, msg=f"{char_id}.speechStyle.byLevel must be an object"
                )
                missing_levels = REQUIRED_LEVEL_KEYS - by_level.keys()
                self.assertFalse(
                    missing_levels,
                    msg=f"{char_id}.speechStyle.byLevel missing levels {missing_levels}",
                )
                for level in REQUIRED_LEVEL_KEYS:
                    with self.subTest(character=char_id, level=level):
                        lines = by_level.get(level)
                        self.assertIsInstance(
                            lines,
                            list,
                            msg=f"{char_id}.speechStyle.byLevel.{level} must be a list",
                        )
                        self.assertTrue(
                            lines,
                            msg=f"{char_id}.speechStyle.byLevel.{level} must not be empty",
                        )
                        for entry in lines:
                            self.assertIsInstance(entry, str)
                            self.assertTrue(entry.strip())

    def test_no_leftover_typo_in_괜찮아요(self) -> None:
        # The Fable spec draft mistakenly wrote "괜찬" (sujin/daniel) twice;
        # guard the corrected file against regressing back to the typo.
        raw = PROFILES_PATH.read_text(encoding="utf-8")
        self.assertNotIn("괜찬", raw)

    def test_no_retired_persona_drafts_survive(self) -> None:
        raw = PROFILES_PATH.read_text(encoding="utf-8")
        for retired in RETIRED_STRINGS:
            with self.subTest(retired=retired):
                self.assertNotIn(retired, raw)

    def test_a1_samples_use_only_international_grade1_grammar(self) -> None:
        # R8 (Fable review of PR #337): every byLevel.A1 line must stay
        # inside the 국제통용 1급 45항목 grammar set (§B.1 ③ of
        # docs/CONTENT_LEVEL_BIBLE.md). A2+ endings (-을게요, -으면, 반말
        # -냐/-야, -을 줄 알다, -네요/-는데/-지요·죠/-을래요, ...) belong in
        # byLevel.A2 or later, never in A1.
        for character in self.payload.get("recurringCharacters", []):
            char_id = character.get("id")
            a1_lines = character["speechStyle"]["byLevel"]["A1"]
            for line in a1_lines:
                with self.subTest(character=char_id, line=line):
                    reason = _forbidden_a1_pattern(line)
                    self.assertIsNone(
                        reason,
                        msg=(
                            f"{char_id} byLevel.A1 line {line!r} contains an "
                            f"A2+ pattern ({reason!r}); move it to "
                            "A2/B1+ and give A1 a 1급-only replacement"
                        ),
                    )


class RelationshipGraphTest(unittest.TestCase):
    """Guards the top-level `relationshipGraph` added alongside speechStyle
    (dense, realistic connections across the cast, incl. hidden links and
    per-level story-arc seeds)."""

    @classmethod
    def setUpClass(cls) -> None:
        with PROFILES_PATH.open(encoding="utf-8") as handle:
            cls.payload = json.load(handle)
        cls.character_ids = {
            c["id"] for c in cls.payload.get("recurringCharacters", [])
        }
        cls.graph = cls.payload.get("relationshipGraph")

    def test_relationship_graph_exists(self) -> None:
        self.assertIsInstance(self.graph, dict)
        for key in ("edges", "hiddenLinks", "storyArcs", "consistencyRules"):
            self.assertIn(key, self.graph, msg=f"relationshipGraph missing {key}")

    def _edge_key(self, edge: dict) -> tuple:
        return tuple(sorted((edge["a"], edge["b"])))

    def test_edges_reference_existing_ids_and_have_required_fields(self) -> None:
        edges = self.graph["edges"]
        self.assertIsInstance(edges, list)
        self.assertTrue(edges)
        for index, e in enumerate(edges):
            with self.subTest(index=index, edge=e.get("a"), b=e.get("b")):
                for field in ("a", "b", "type", "knownTo", "since", "koLabel", "byLevel"):
                    self.assertIn(field, e, msg=f"edge[{index}] missing {field}")
                self.assertIn(e["a"], self.character_ids, msg=f"edge[{index}].a unknown id")
                self.assertIn(e["b"], self.character_ids, msg=f"edge[{index}].b unknown id")
                self.assertNotEqual(e["a"], e["b"], msg=f"edge[{index}] is a self-loop")
                self.assertIn(e["knownTo"], {"both", "one", "none"})
                by_level = e["byLevel"]
                self.assertIsInstance(by_level, dict)
                for level in ("A1", "A2", "B1+"):
                    self.assertIn(level, by_level, msg=f"edge[{index}].byLevel missing {level}")
                    self.assertTrue(by_level[level], msg=f"edge[{index}].byLevel.{level} empty")

    def test_no_duplicate_unordered_edge_pairs(self) -> None:
        edges = self.graph["edges"]
        seen: dict = {}
        for e in edges:
            key = self._edge_key(e)
            self.assertNotIn(
                key,
                seen,
                msg=f"duplicate unordered pair {key} (edges are undirected)",
            )
            seen[key] = e

    def test_every_recurring_character_appears_in_at_least_one_edge(self) -> None:
        edges = self.graph["edges"]
        covered = set()
        for e in edges:
            covered.add(e["a"])
            covered.add(e["b"])
        missing = self.character_ids - covered
        self.assertFalse(missing, msg=f"characters with no relationship edge: {missing}")

    def test_hidden_links_reference_real_edges(self) -> None:
        edges = self.graph["edges"]
        edge_pairs = {self._edge_key(e) for e in edges}
        hidden_links = self.graph["hiddenLinks"]
        self.assertIsInstance(hidden_links, list)
        self.assertTrue(hidden_links)
        for index, link in enumerate(hidden_links):
            with self.subTest(index=index):
                for field in ("edges", "knownTo", "fact", "revealLevel", "revealScene"):
                    self.assertIn(field, link, msg=f"hiddenLinks[{index}] missing {field}")
                self.assertTrue(link["edges"], msg=f"hiddenLinks[{index}].edges empty")
                for ref in link["edges"]:
                    parts = tuple(sorted(ref.split("-")))
                    self.assertEqual(
                        len(parts),
                        2,
                        msg=f"hiddenLinks[{index}] edge ref {ref!r} must be 'a-b'",
                    )
                    self.assertIn(
                        parts,
                        edge_pairs,
                        msg=f"hiddenLinks[{index}] references unknown edge {ref!r}",
                    )

    def test_story_arcs_cover_all_levels_with_nonempty_seeds(self) -> None:
        story_arcs = self.graph["storyArcs"]
        self.assertIsInstance(story_arcs, dict)
        self.assertEqual(set(story_arcs.keys()), EXPECTED_STORY_ARC_LEVELS)
        for level, seeds in story_arcs.items():
            with self.subTest(level=level):
                self.assertIsInstance(seeds, list)
                self.assertGreaterEqual(len(seeds), 3, msg=f"storyArcs.{level} needs >=3 seeds")
                for seed in seeds:
                    self.assertIsInstance(seed, str)
                    self.assertTrue(seed.strip())

    def test_consistency_rules_has_fixed_facts_for_every_character(self) -> None:
        rules = self.graph["consistencyRules"]
        self.assertIsInstance(rules, dict)
        fixed_facts = rules.get("fixedFacts")
        self.assertIsInstance(fixed_facts, dict)
        missing = self.character_ids - fixed_facts.keys()
        self.assertFalse(missing, msg=f"consistencyRules.fixedFacts missing {missing}")
        self.assertIn("timeAxis", rules)
        self.assertTrue(rules.get("rules"))


if __name__ == "__main__":
    unittest.main()
