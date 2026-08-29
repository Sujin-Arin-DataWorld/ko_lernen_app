# W6 Cloze 8개 주제 그룹 Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** canonical `cloze.json`의 1,805개 항목·125개 topic을 정확히 8개 현지화 그룹으로 분류하고, 기존 level/deep-link 여정을 보존한 채 그룹 필터를 추가한다.

**Architecture:** cloze item ID는 계속 `assets/data/cloze.json` 한 곳에서만 정의한다. 새 Dart authority는 exact topic-string → stable group-ID 매핑과 표시 순서만 소유한다. 로더가 canonical items에서 그룹별 item IDs를 파생하므로 ID 목록을 두 번째 데이터셋에 복제하지 않는다. 알 수 없는 topic은 All로 조용히 섞지 않고 테스트/개발에서 실패한다.

**Tech Stack:** Dart immutable data, Flutter, ARB l10n, flutter_test/data contract tests.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §8.3 and §9.

## Global Constraints

- Start from fresh main after the audio/TTS PR merge.
- Preserve all-level start behavior, route/deep links, score, progress, and W5 level filter semantics.
- Group IDs are stable ASCII; DE/EN labels are independent localization values.
- A canonical topic must map to exactly one group. Duplicate, unmapped, or dangling data fails tests.
- When a selected level yields no items for a group, render the group disabled with count 0 and a semantic explanation; do not show a false completion state.

### Task 1: define the exact eight-group authority

**Files:**

- Create: `lib/data/cloze_topic_groups.dart`
- Create: `test/cloze_topic_groups_test.dart`

**Types:**

```dart
enum ClozeTopicGroupId {
  everydayHome,
  peopleRelationships,
  travelServices,
  workEducation,
  languageMedia,
  societyInstitutions,
  technologyScience,
  healthNatureLeisure,
}

final class ClozeTopicGroups {
  static List<ClozeTopicGroupId> get ordered;
  static ClozeTopicGroupId? groupForTopic(String topic);
  static Map<ClozeTopicGroupId, List<ClozeItem>> partition(
    Iterable<ClozeItem> items,
  );
}
```

**Exact mapping:**

- `everydayHome`: 결제와 배달; 도시 생활; 생활 종합; 약속과 일정; 집 구하기; Alltag; Einkaufen; Essen & Trinken; Farben; Feststand; Geld; Hausordnung; Menge; Nachbarschaft; Reparaturwortschatz; WG-Gespräch; Wochenendzusage; Wohnen; Wohnen & Vertrag; Zahlen; Zeit.
- `peopleRelationships`: 자기소개; 첫인사; Begrüßung; Beziehungen; Entschuldigung; Familie; Gefühle; Höflichkeit; Kommunikation; Motivation; Partnerschaft & koreanische Familie; Person.
- `travelServices`: Amtgang; Bankschalter; Friseursalon; Fundsachen; Handytarif; Postamt; Reise; Reiseänderung; U-Bahnkarte; Verkehr; Versicherungsfall.
- `workEducation`: 취업과 근무 조건; Arbeitskoordination & Termine; Beruf; Betriebslast; Beurteilung; Bildung; Dienstmail; Ehrenamtsschicht; Elterngespräch; Kurzreferat; Nebenjob; Schultasche; Teamarbeit & Feedback; Teamverhandlung.
- `languageMedia`: 다시 묻기; 은는과 이가; Autoritätssprache; Beschreibung; Denken; Diskurs & Macht; Entscheidungen & Perspektiven; Erinnerung & Erzählperspektive; Erinnerungsnarrativ; Framinganalyse; Kurzlage; Lesen & Reaktionen; Medien & Evidenz; Medienkompetenz; Narrativ & Perspektive; Position; Sprache & Gesellschaft; Sprache, Deutung & Macht.
- `societyInstitutions`: 인구 담론과 제도 책임; 주거비와 사회 통합; Beteiligungsdesign; Bürgerversammlung; Diskurs, Macht & Verantwortung; Einspruchsweg; Eskalation; Formelle Beschwerde & Abhilfe; Formelle Vereinbarungen; Gemeinsame Räume & Rücksicht; Gesellschaft; Gesellschaft & Alltag 2026; Gesellschaft im Wandel; Institutionelle Vermittlung; Institutionsstimme; Öffentliche Lage; Regulierung & Nebenwirkung; Sanktion & Rechenschaft; Widerrufsrecht; Wohnstreit; Zugänglichkeit & Teilhabe; Zugangskosten.
- `technologyScience`: AI 투명성과 문화 노동; Automatenfolgen; Automatisierung & Rechtsweg; Digitale Aufmerksamkeit; Erhebungsdesign; Evidenzvorbehalt; Forschung & Evidenz; Geographie; Nachhaltige Entscheidungen vor Ort; Ortliche Abwägung; Prüfspur; Risiko & öffentliche Information; Risikosprache; Technikethik & Verantwortung; Technologie; Wissenschaft.
- `healthNatureLeisure`: Apotheke; Fanarbeit & Belastung; Fitnesskurs; Freizeit; Gesundheit; Körper; Rhythmus & Grenzen; Sicherheit & Grenzen; Umwelt; Wetter; Wetterschicht.

**TDD steps:**

1. Load `assets/data/cloze.json` in the test and assert exactly 1,805 items and 125 distinct nonempty topics at the accepted baseline; if the source legitimately changes, update mapping and evidence together rather than weakening counts.
2. Assert exactly eight ordered IDs, unique enum/name/label keys, every one of the 125 topics mapped once, no mapping key absent from canonical data, every item ID partitioned once, and no duplicate/dangling ID.
3. Add a direct assertion for every mapping group above so a fuzzy keyword classifier cannot replace it.
4. Confirm tests fail because the authority does not exist.
5. Implement a const exact map and partition from canonical objects; throw `StateError` in debug/test for an unknown topic instead of silently assigning it.
6. Run `flutter test --no-pub test/cloze_topic_groups_test.dart test/cloze_content_guard_test.dart test/cloze_test.dart`.

**Commit:** `feat(cloze): classify canonical topics into eight exact groups`

### Task 2: localize group labels and descriptions

**Files:**

- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/generated/app_localizations*.dart`
- Modify: l10n parity tests

**Keys:** `clozeGroupAll`, then label and description keys for `EverydayHome`, `PeopleRelationships`, `TravelServices`, `WorkEducation`, `LanguageMedia`, `SocietyInstitutions`, `TechnologyScience`, and `HealthNatureLeisure`.

**TDD steps:**

1. Add parity tests requiring every group ID to resolve one DE label/description and one EN label/description.
2. Add distinctness tests within each locale and no Korean fallback in DE/EN UI labels.
3. Add ARB entries, run `flutter gen-l10n`, and rerun parity tests.

**Commit:** `feat(l10n): name eight cloze learning domains`

### Task 3: integrate group filtering after the W5 level filter

**Files:**

- Modify: `lib/screens/cloze_game_screen.dart`
- Modify: `test/cloze_game_screen_ui_test.dart`
- Modify: `test/cloze_prompt_test.dart`
- Verify: `test/level_filter_guard_test.dart`

**State contract:** selected level is applied first; group counts are computed from that level-filtered pool. The default is All and preserves the current queue order. Selecting a group resets only the current cloze queue/index, not stored mastery. Changing level recomputes counts; if the current group becomes empty, keep it selected and show a recoverable localized empty-for-filter state with actions to choose All or another group.

**TDD steps:**

1. Add tests for All parity with the old item sequence, level→group counts, group→level recomputation, zero-count disabled semantics, filter reset behavior, deep-link/default level, keyboard navigation, 48 dp controls, and text scale 2.0.
2. Confirm current screen has no group UI.
3. Add one browse-style `SoriLevelFilterBar`/compact group sheet arrangement without reintroducing the chrome stack removed in W5-A.
4. Render the selected group's localized label/count in the existing meta row and keep the canonical Korean prompt unchanged.
5. Run `flutter test --no-pub test/cloze_game_screen_ui_test.dart test/cloze_prompt_test.dart test/level_filter_guard_test.dart test/chrome_stack_guard_test.dart`.

**Commit:** `feat(cloze): filter play queue by eight localized domains`

### Task 4: W6 cloze and final automated wave proof

Run every cloze data/UI test, `git diff --check`, `flutter analyze --no-pub`, and the full Flutter suite serially. Run scene/audio/TTS check-mode scripts again so final W6 does not regress earlier PRs. Run the standard unsigned local Android or web build supported by the repository, then `graphify update .`. Push and prove exact-head PR CI; after merge, prove the final `main` full suite and web build. Do not report Linux-only goldens or Jin's device checklist as locally passed.
