# Hanok World System Design

**Status:** Approved by Jin on 2026-08-05.

## Product promise

Hangul Sori is a Korean-learning app in which a learner gradually inhabits a
traditional Hanok. The Hanok is not a second progression game and does not
invent a second curriculum. It makes verified learning feel like a place: the
learner goes to the Sarangbang for today's next lesson, sees rooms become useful
as Korean grows, and can optionally participate in a separate shared Gye
courtyard.

The learner must always be able to answer: what should I study now; how is my
personal Hanok growing; and what is shared with my Gye versus what remains mine.

## End-to-end information architecture

### First and returning sessions

Splash → character/level onboarding → Home (today's Madang) → Sarangbang →
existing recommendation route → result → Sarangbang/Home.

Onboarding never requires building, placing, donating, or joining a Gye before
the first learning action. Home is today's Madang, not an inventory dashboard.
Its fixed visual order is:

1. one primary Sarangbang card using the current TodayLearningSnapshot;
2. a compact personal-Hanok growth preview leading to /hanok;
3. secondary routines: review, daily challenge, difficult words;
4. optional discovery.

The four existing navigation roles stay intact:

| Destination | Job |
|---|---|
| Home | One next-learning action and personal-Hanok preview |
| Practice | Free practice and library discovery |
| Gye | Optional shared community courtyard |
| Profile | Identity, settings, records, and account state |

The personal Hanok is a route rather than a fifth competing tab. It is reachable
from Home, the learning-path preview, and the Sarangbang AppBar.

### Personal Hanok map

The map is a long-term place chooser. Viewing it or entering a building never
writes course progress, rewards, ownership, or social state.

| Place | Meaning | Existing destination |
|---|---|---|
| Sarangchae / Sarangbang | Today's recommended study | /sarangbang |
| Daecheongmaru | Structured course journey | /path |
| Anchae | Personal collection and books | /bookshelf |
| Haengrangchae | Free practice library | /practice |
| Sadang | Stamps and achievements | /dojangcheop |
| Rear garden | Daily challenge and quests | /daily, /quests |
| Gye bridge | Contextual doorway only | /gye/hub |

Painted bounds and interactive hit bounds are independent catalog data. No two
interactive target rectangles overlap. Every place is additionally present in a
localized accessible place list, so a learner never has to target a roof pixel.

Phone UI shows the 4:3 map plus one selected-place card and a full-map state.
Tablet UI uses the same map plus a persistent side panel. The only active status
marker is today's Sarangbang; completed buildings stay calm and legible.

### Study venues and furnishing

PersonalRoomFurnishScreen remains collection management and is never a
prerequisite to study. A venue study view may render the room shell plus current
decor, but it is read-only and cannot open a picker or write placement.

| Venue | Study role | Furnish role |
|---|---|---|
| Sarangbang | Today's recommendation | Collectible study room |
| Anbang | Books and learner history | Collectible private room |
| Daecheongmaru | Course journey and milestones | Collectible open hall |

Locked rooms show a localized progress explanation and return to /hanok. They
must not instantiate a picker or read/write placement state.

## Single-source state boundaries

| Concern | Owner | Rule |
|---|---|---|
| Next-learning decision | mission_recommender.dart | Existing priority and 70% evidence remain unchanged |
| UI-ready next learning | TodayLearningSnapshotLoader | Home and Sarangbang use the same facade |
| Hanok construction | HanokStageService + PersonalHanokProjection | Deterministic read-only projection |
| Decor award/recovery | DecorationRewardService | Map and venue code never claims rewards |
| Personal placement | RoomPlacementService | One decor appears in one personal room |
| Owned-decor backup | CloudSync | Preserve current union; placements stay local-only |
| Gye membership/moderation | GyeService, rules, Cloud Functions | Personal map code never bypasses it |

TodayLearningSnapshot contains the existing MissionPick, optional scenario
metadata, canonical destination, and presentation revision. The loader may be
called by Home and Sarangbang independently, but both call the same facade and
refresh after a learning route returns. It delegates all priority decisions to
the existing recommendMission function.

## Visual system contract

The direction is **high-density modern Minhwa**: a wide traditional estate,
clear contemporary type, quiet Hanji surfaces, and purposeful Dancheong accents.
Traditional character comes from architecture, texture, ornament, and pacing,
not small serif type, busy chrome, or icon-heavy buttons.

- Use SoriScreenBackground, SoriSurfaces, SoriTextTheme, SoriCard, SoriButton,
  SoriContentClamp, and SoriAdaptiveNavigation.
- Body/UI type remains Pretendard. No new raw user-visible TextStyle, literal
  font weights, or hard-coded user copy.
- Buttons are text-first. An icon belongs in a map label, card header, or AppBar
  only when it adds meaning absent from its label.
- Phone controls stay at least 44dp. The 308–1280dp and 1.3× text-scale matrix
  is mandatory.
- All new copy is DE/EN ARB followed by flutter gen-l10n.

## P4b-MVP: Gye 공동 전시 헌정

P4b-MVP is a **community exhibition dedication**, not physical ownership
transfer. The user retains ownedDecor and can keep placing the item in a private
room. This preserves local union sync, placement, and reward-journal contracts.

### User flow

Gye courtyard → shared exhibition → select owned decor → confirm dedication →
callable success → Firestore stream renders exhibit.

A member may hold one exhibition per Gye, replace it, or withdraw it. There are
at most ten fixed shared slots. MVP has no public feed event, score, XP, or
notification; it is social atmosphere, not competition.

### Server contract

~~~
gye/{gyeId}/decor_dedications/{uid}
  schemaVersion: 1
  uid: string
  membershipId: string
  decorationSlug: string
  slotIndex: 0..9
  revision: int
  lastOperationId: string
  createdAt: server timestamp
  updatedAt: server timestamp
~~~

Clients may read active dedications, but Firestore rules deny every direct
write. The App-Check-protected callable accepts only gyeId,
decorationSlug|null, expectedRevision, and operationId and runs an Admin
transaction. It validates active membership, ban/suspension/deletion state,
Gye lifecycle, slug allowlist, operation id, and expected revision.

The callable is idempotent for the same operation and returns a conflict for a
stale revision. It retains an existing slot on replacement, then chooses the
first free slot. A server throttle prevents visual spam. Leave, ban, account
deletion, and Gye deletion clean only documents with matching membershipId,
preventing an old leave cleanup from deleting a later rejoin.

### Deferred true transfer

Real donation requires server-authoritative individual inventory, tombstones,
server-issued reward receipts, private-room removal, conflict-aware device sync,
and one operation journal across all effects. It is explicitly P4b-II. MVP copy
says “dedicate to the shared exhibition,” never “give away” or “lose.”

## Acceptance criteria

1. Home and Sarangbang show the same next-learning identity after refresh and
   launch the same existing route without changing mastery rules.
2. Every map destination has a disjoint target and accessible list action;
   Daecheong never opens Anchae.
3. Phone/tablet/1.3× text have no overflow or inaccessible map controls.
4. Venue context never causes award, ownership, placement, or course writes.
5. P4b-MVP cannot remove/revive personal decor, cannot be directly written in
   Firestore, and safely handles duplicate calls, stale screens, leave/rejoin,
   ban, account deletion, and Gye deletion.
