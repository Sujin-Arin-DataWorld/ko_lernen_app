"""Batch 10 scene seeds: Korean is the source, never an English slug."""

from __future__ import annotations

import re
from typing import Any

from batch_10_scene_beats import BEATS, beat_for

LATIN_IN_KO = re.compile(r"[A-Za-z]{3,}")
TEMPLATE_LEFTOVERS = (
    "해결해야 합니다",
    "상황을 짧게 말해 주세요",
    "접수를 확인했습니다",
    "오전 처리가 가능합니다",
)
SLANG_PASSWORD = re.compile(r"비번(?!호)")
GENERIC_SERVICE_SHELL = (
    "안녕하세요. 무엇을 도와드릴까요?",
    "네, 그렇게 해 주세요.",
    "알겠습니다. 지금 바로 확인하겠습니다.",
    "감사합니다. 얼마나 걸려요?",
    "알겠습니다. 감사합니다.",
)
HUMANIZER_SHELL_KO = (
    "진행해",
    "살펴보",
    "잘 부탁",
    "때문에 오셨",
    "관련해서",
    "확인해 드릴까요",
    "처리하겠습니다",
)
HUMANIZER_SHELL_EN = (
    "Understood",
    "Are you here about",
    "in advance",
    "Can I help with",
    "I will check",
    "I will handle",
    "I will look",
    "Shall I check",
    "Shall I",
    "I will ",
)
SEED_KO_LEFTOVERS = (
    "진행하지",
    "할 수 있는",
    "을 위해",
    "를 위해",
)
HUMANIZER_SHELL_DE = (
    "im Voraus",
    "Sind Sie wegen",
    "Alles klar",
)


def hangul_has_batchim(ch: str) -> bool:
    code = ord(ch)
    if not (0xAC00 <= code <= 0xD7A3):
        return False
    return (code - 0xAC00) % 28 != 0


def batchim_plus_reul(text: str) -> list[str]:
    hits: list[str] = []
    for index, char in enumerate(text):
        if char == "를" and index > 0 and hangul_has_batchim(text[index - 1]):
            start = max(0, index - 2)
            hits.append(text[start : index + 1])
    return hits


def collect_korean_fields(payload: Any) -> list[str]:
    found: list[str] = []
    if isinstance(payload, dict):
        for key, value in payload.items():
            if key in {"ko", "korean", "targetKo", "audioKo", "sentence", "prefix", "suffix"}:
                if isinstance(value, str) and value.strip():
                    found.append(value)
            else:
                found.extend(collect_korean_fields(value))
    elif isinstance(payload, list):
        for item in payload:
            found.extend(collect_korean_fields(item))
    return found


def _t(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


def _line(speaker: str, ko: str, de: str, en: str) -> dict[str, str]:
    return {"speaker": speaker, "ko": ko, "de": de, "en": en}


def _pattern_index(ident: str, count: int) -> int:
    return sum(ord(char) for char in ident) % count


def _is_polite(text: str) -> bool:
    """Read the register off a line the seed already authored."""
    tail = text.rstrip(" .?!…")
    return tail.endswith(("요", "죠", "니다", "세요", "습니까", "십니까"))


def _asks_other_to_act(text: str) -> bool:
    """True when the user's take hands the work to Jieun instead of taking it on."""
    tail = text.rstrip(" .?!…")
    return (
        "주세요" in tail
        or "주시" in tail
        or "부탁" in tail
        or "좋겠" in tail
        or tail.endswith("줘")
        or tail.endswith("두세요")
    )


# Frame lines carry no scene title. A greeting, an acknowledgement and a sign-off
# repeat across scenes because they repeat at real counters and kitchen tables. The
# lines that have to be scene-specific live in the seed (need/ask/wait) and in
# batch_10_scene_beats (take/probe). "check_do" answers a take that asked Jieun to
# act; "check_ok" answers a take where the user does it themselves.
FRAME_POOLS: dict[tuple[str, bool], dict[str, tuple[tuple[str, str, str], ...]]] = {
    ("service", True): {
        "open": (
            ("어서 오세요. 어떤 일로 오셨어요?", "Guten Tag. Was können wir für Sie tun?", "Welcome. What brings you in?"),
            ("네, 말씀하세요.", "Ja, bitte?", "Yes, go ahead."),
            ("안녕하세요. 무엇부터 도와드릴까요?", "Hallo. Wo fangen wir an?", "Hello. Where should we start?"),
            ("어서 오세요. 편하게 말씀해 주세요.", "Guten Tag. Sagen Sie ruhig, was Sie brauchen.", "Welcome. Just tell me what you need."),
            ("네, 다음 분. 이쪽으로 오세요.", "Der Nächste bitte. Kommen Sie hierher.", "Next, please. Come this way."),
            ("안녕하세요. 어떤 것부터 볼까요?", "Hallo. Was schauen wir zuerst an?", "Hello. What should we look at first?"),
        ),
        "check_do": (
            ("네, 바로 해 드리겠습니다.", "Ja, ich mache das gleich.", "Yes, I'll do that right away."),
            ("네, 지금 해 드릴게요.", "Gut. Ich erledige es jetzt.", "Sure. I'll handle it now."),
            ("네, 그렇게 해 드리겠습니다.", "Ja, das mache ich so.", "Yes, I'll do it that way."),
            ("알겠습니다. 잠시만 기다려 주세요.", "Gut. Einen Moment bitte.", "Sure. One moment, please."),
        ),
        "check_ok": (
            ("네, 확인해 보겠습니다.", "Ja, ich sehe nach.", "Yes, let me check."),
            ("네, 좋습니다.", "Ja, in Ordnung.", "Yes, that works."),
            ("알겠습니다. 그렇게 하시면 됩니다.", "Gut. So können Sie es machen.", "Sure. That is the way to do it."),
            ("네, 그렇게 하세요.", "Ja, machen Sie das.", "Yes, go ahead."),
        ),
    },
    ("class", True): {
        "open": (
            ("네, 말씀하세요.", "Ja, bitte.", "Yes, go ahead."),
            ("무슨 일이에요?", "Was gibt es?", "What is it?"),
            ("네, 편하게 물어보세요.", "Fragen Sie ruhig.", "Go ahead and ask."),
            ("네, 듣고 있어요.", "Ja, ich höre.", "Yes, I'm listening."),
        ),
        "check_do": (
            ("네, 그렇게 해 줄게요.", "Ja, das mache ich.", "Yes, I'll do that."),
            ("알겠어요. 지금 해 줄게요.", "Gut. Ich mache es jetzt.", "Okay. I'll do it now."),
            ("네, 바로 해 줄게요.", "Ja, gleich.", "Yes, right away."),
        ),
        "check_ok": (
            ("네, 그렇게 하세요.", "Ja, machen Sie das.", "Yes, go ahead."),
            ("네, 좋아요.", "Ja, gut.", "Yes, that is fine."),
            ("알겠어요. 그렇게 하면 돼요.", "Gut. So passt es.", "Okay. That works."),
        ),
    },
    ("coworker", True): {
        "open": (
            ("네, 말씀하세요.", "Ja, bitte?", "Yes, go ahead."),
            ("지금 시간 괜찮아요. 어떤 건이에요?", "Ich habe Zeit. Um welchen Fall geht es?", "I have time. Which case is it?"),
            ("네, 편하게 말씀하세요.", "Sie können mir ruhig sagen.", "Go ahead, tell me."),
            ("듣고 있어요. 말씀하세요.", "Ich höre. Ja, bitte?", "I'm listening. Go ahead."),
            ("네, 어디부터 볼까요?", "Ja, wo fangen wir an?", "Sure, where should we start?"),
        ),
        "check_do": (
            ("알겠습니다. 그렇게 반영하겠습니다.", "Gut. Ich übernehme es so.", "Sure. I'll apply it that way."),
            ("네, 제가 그렇게 맞춰 두겠습니다.", "Ja, ich passe es entsprechend an.", "Yes, I'll line it up like that."),
            ("알겠습니다. 바로 정리하겠습니다.", "Gut. Ich sortiere es gleich.", "Sure. I'll sort it right away."),
            ("네, 그렇게 하겠습니다.", "Ja, mache ich.", "Yes, I'll do that."),
        ),
        "check_ok": (
            ("알겠습니다. 그렇게 하죠.", "Gut. Machen wir so.", "Sure. Let us do that."),
            ("네, 좋습니다.", "Ja, in Ordnung.", "Yes, that works."),
            ("알겠어요. 그럼 그 방향으로 가죠.", "Gut. Dann in diese Richtung.", "Okay. We will go that way then."),
            ("네, 그렇게 알고 있겠습니다.", "Ja, so halte ich es fest.", "Yes, I'll note it that way."),
        ),
    },
    ("home", True): {
        "open": (
            ("네, 말씀하세요.", "Ja, bitte.", "Yes, go ahead."),
            ("안녕하세요. 무슨 일이세요?", "Hallo. Worum geht es?", "Hello. What is it about?"),
            ("네, 듣고 있어요.", "Ja, ich höre.", "Yes, I'm listening."),
            ("아, 안녕하세요. 어떤 일이세요?", "Ah, hallo. Was gibt es?", "Oh, hello. What can I do?"),
        ),
        "check_do": (
            ("네, 그렇게 하겠습니다.", "Ja, mache ich so.", "Yes, I'll do that."),
            ("알겠습니다. 바로 그렇게 할게요.", "Gut, ich mache es gleich so.", "Sure, I'll do it that way now."),
            ("네, 지금 해 두겠습니다.", "Ja, ich mache es jetzt.", "Yes, I'll get it done now."),
        ),
        "check_ok": (
            ("네, 그렇게 하시면 됩니다.", "Ja, so können Sie es machen.", "Yes, that is the way to do it."),
            ("네, 맞습니다.", "Ja, genau.", "Yes, that is right."),
            ("알겠습니다. 그렇게 하세요.", "Gut. Machen Sie das.", "Sure. Go ahead."),
        ),
    },
    ("home", False): {
        "open": (
            ("왜, 무슨 일이야?", "Was ist denn?", "What is up?"),
            ("응, 말해.", "Ja, sag.", "Yeah, go ahead."),
            ("어, 지금 괜찮아. 말해 봐.", "Ja, ich habe Zeit. Sag ruhig.", "Sure, I'm free. Tell me."),
            ("응? 왜 그래?", "Hm? Was ist los?", "Hm? What is it?"),
        ),
        "check_do": (
            ("응, 그렇게 할게.", "Ja, mache ich.", "Yeah, I'll do that."),
            ("알았어. 내가 할게.", "Okay. Ich mache es.", "Okay. I'll do it."),
            ("응, 지금 해 둘게.", "Ja, ich mache es jetzt.", "Yeah, I'll get it done now."),
        ),
        "check_ok": (
            ("응, 알았어.", "Ja, verstanden.", "Yeah, got it."),
            ("그래, 알았어.", "Gut, verstanden.", "Alright, got it."),
            ("그래, 그럼 그렇게 하자.", "Gut, dann machen wir das so.", "Alright, we will do it that way."),
        ),
    },
    ("peer", False): {
        "open": (
            ("어, 왜?", "Hey, was ist?", "Hey, what is up?"),
            ("응, 무슨 일이야?", "Ja, was gibt es?", "Yeah, what is it?"),
            ("지금 괜찮아. 말해 봐.", "Ich habe Zeit. Sag ruhig.", "I'm free. Go ahead."),
            ("왜? 무슨 일 있어?", "Warum? Ist was?", "Why? Something up?"),
        ),
        "check_do": (
            ("응, 그렇게 할게.", "Ja, mache ich.", "Yeah, I'll do that."),
            ("알았어. 지금 할게.", "Okay. Ich mache es jetzt.", "Okay. I'll do it now."),
            ("그래, 내가 해 둘게.", "Gut, ich übernehme das.", "Sure, I'll take care of it."),
        ),
        "check_ok": (
            ("응, 알았어.", "Ja, verstanden.", "Yeah, got it."),
            ("그래, 알았어.", "Gut, verstanden.", "Alright, got it."),
            ("아, 그래? 알았어.", "Ah, okay. Verstanden.", "Ah, okay. Got it."),
        ),
    },
}

FRAME_CLOSES: dict[bool, tuple[tuple[str, str, str], ...]] = {
    True: (
        ("네, 감사합니다.", "Ja, vielen Dank.", "Okay, thank you."),
        ("알겠습니다. 감사합니다.", "Gut. Danke schön.", "Sure. Thank you."),
        ("네, 그렇게 할게요. 감사합니다.", "Ja, mache ich. Danke.", "Yes, I'll do that. Thanks."),
        ("감사합니다. 그럼 그렇게 부탁드려요.", "Danke. Dann bitte so.", "Thank you. Then please do it that way."),
        ("네, 알겠어요. 고맙습니다.", "Ja, verstanden. Danke.", "Okay, got it. Thanks."),
        ("감사합니다. 수고하세요.", "Vielen Dank. Alles Gute.", "Thank you. Have a good one."),
    ),
    False: (
        ("응, 고마워.", "Ja, danke.", "Yeah, thanks."),
        ("알았어. 고마워.", "Okay. Danke.", "Okay. Thanks."),
        ("그래, 그렇게 하자. 고마워.", "Gut, machen wir so. Danke.", "Alright, we will do that. Thanks."),
        ("고마워. 그럼 그렇게 할게.", "Danke. Dann mache ich das.", "Thanks. I'll do that then."),
    ),
}


def _pool(kind: str, polite: bool, slot: str, ident: str) -> tuple[str, str, str]:
    pool = FRAME_POOLS.get((kind, polite))
    if pool is None:
        register = "polite" if polite else "casual"
        raise SystemExit(f"no {register} {kind} frame pool for {ident}")
    lines = pool[slot]
    return lines[_pattern_index(f"{ident}:{slot}", len(lines))]


def frame_lines(ident: str, seed: dict[str, Any]) -> dict[str, tuple[str, str, str]]:
    """Greeting, acknowledgement and sign-off, matched to the seed's own wording.

    Jieun keeps the register of her ``ask`` and answers in the direction the user's
    ``take`` set: she confirms when the user does the work, and commits when the
    user handed it to her. The user's sign-off keeps the register of ``need``. No
    scene title is pasted into any of these lines.
    """
    kind = seed["frame"]
    jieun_polite = _is_polite(seed["ask"][0])
    user_polite = _is_polite(seed["need"][0])
    take_ko = beat_for(ident, "take")[0]
    check_slot = "check_do" if _asks_other_to_act(take_ko) else "check_ok"
    closes = FRAME_CLOSES[user_polite]
    return {
        "open": _pool(kind, jieun_polite, "open", ident),
        "check": _pool(kind, jieun_polite, check_slot, ident),
        "close": closes[_pattern_index(f"{ident}:close", len(closes))],
    }


def render_scene(
    seed: dict[str, Any],
    *,
    ident: str,
) -> dict[str, Any]:
    frame = frame_lines(ident, seed)
    sit = seed["sit"]
    need = seed["need"]
    ask = seed["ask"]
    wait = seed["wait"]
    return {
        "intro": _t(*sit),
        "relation": seed["rel"],
        "vocab": list(seed["vocab"]),
        "particle": seed.get("particle"),
        "dialog": [
            _line("jieun", *frame["open"]),
            _line("user", *need),
            _line("jieun", *ask),
            _line("user", *beat_for(ident, "take")),
            _line("jieun", *frame["check"]),
            _line("user", *beat_for(ident, "probe")),
            _line("jieun", *wait),
            _line("user", *frame["close"]),
        ],
    }


def _seed(
    *,
    frame: str,
    rel: str,
    sit: tuple[str, str, str],
    need: tuple[str, str, str],
    ask: tuple[str, str, str],
    wait: tuple[str, str, str],
    vocab: list[str],
    particle: str | None = None,
) -> dict[str, Any]:
    if particle and particle not in ask[0]:
        raise SystemExit(f"particle {particle!r} missing from ask: {ask[0]}")
    if len(vocab) != 6:
        raise SystemExit(f"vocab must have 6 items: {vocab}")
    return {
        "frame": frame,
        "rel": rel,
        "sit": sit,
        "need": need,
        "ask": ask,
        "wait": wait,
        "vocab": vocab,
        "particle": particle,
    }


SEEDS: dict[str, dict[str, Any]] = {}


def _add(ident: str, **kwargs: Any) -> None:
    if ident in SEEDS:
        raise SystemExit(f"duplicate seed {ident}")
    SEEDS[ident] = _seed(**kwargs)


_add(
    "a1_post_queue",
    frame="service",
    rel="customer_and_service_staff",
    sit=("우체국에서 줄을 서서 택배를 보냅니다.", "An der Post steht man in der Schlange und schickt ein Paket.", "You wait in line at the post office to send a parcel."),
    need=("택배를 독일로 보내고 싶어요.", "Ich möchte ein Paket nach Deutschland schicken.", "I want to send a parcel to Germany."),
    ask=("무게를 먼저 재 볼까요?", "Soll ich zuerst das Gewicht messen?", "Should I weigh it first?"),
    wait=("앞에 두 분만 기다리시면 됩니다.", "Es sind nur noch zwei Personen vor Ihnen.", "Only two people are ahead of you."),
    vocab=["우체국", "줄", "택배", "무게", "독일", "기다리기"],
    particle="를",
)
_add(
    "a1_stamp_ask",
    frame="service",
    rel="customer_and_service_staff",
    sit=("우체국에서 우표가 몇 장인지 묻습니다.", "An der Post fragt man, wie viele Briefmarken nötig sind.", "You ask how many stamps you need at the post office."),
    need=("이 편지에는 우표가 몇 장 필요해요?", "Wie viele Marken braucht dieser Brief?", "How many stamps does this letter need?"),
    ask=("두 장을 붙이면 됩니다.", "Zwei Stück reichen.", "Two stamps will do."),
    wait=("우표는 바로 드릴 수 있습니다.", "Die Marken kann ich sofort geben.", "I can give you the stamps right away."),
    vocab=["우표", "편지", "몇 장", "붙이다", "두 장", "우체국"],
    particle="을",
)
_add(
    "a1_parcel_weight",
    frame="service",
    rel="customer_and_service_staff",
    sit=("소포 무게를 잰 다음 요금을 확인합니다.", "Man wiegt das Paket und prüft danach den Preis.", "You weigh a parcel and then check the fee."),
    need=("이 소포 무게 좀 재 주세요.", "Bitte wiegen Sie dieses Paket.", "Please weigh this parcel."),
    ask=("상자를 저울에 올려 주시겠어요?", "Legen Sie den Karton auf die Waage?", "Would you put the box on the scale?"),
    wait=("요금은 바로 나옵니다.", "Der Preis erscheint gleich.", "The fee will show up shortly."),
    vocab=["소포", "무게", "저울", "상자", "요금", "재다"],
    particle="를",
)
_add(
    "a1_pharmacy_ointment",
    frame="service",
    rel="customer_and_service_staff",
    sit=("약국에서 연고가 어디에 있는지 묻습니다.", "In der Apotheke fragt man nach der Salbe.", "You ask where the ointment is in a pharmacy."),
    need=("피부 연고가 어디에 있어요?", "Wo ist die Hautsalbe?", "Where is the skin ointment?"),
    ask=("이 선반을 보시면 됩니다.", "Schauen Sie in dieses Regal.", "Look at this shelf."),
    wait=("연고는 바로 옆에 있습니다.", "Die Salbe steht gleich daneben.", "The ointment is right next to it."),
    vocab=["약국", "연고", "피부", "선반", "어디", "옆"],
    particle="을",
)
_add(
    "a1_mask_pack",
    frame="service",
    rel="customer_and_service_staff",
    sit=("약국에서 마스크 한 통을 삽니다.", "In der Apotheke kauft man eine Packung Masken.", "You buy a pack of masks at the pharmacy."),
    need=("마스크 한 통 주세요.", "Eine Packung Masken, bitte.", "One pack of masks, please."),
    ask=("작은 통을 드릴까요, 큰 통을 드릴까요?", "Die kleine oder die große Packung?", "The small pack or the large one?"),
    wait=("계산은 바로 됩니다.", "Die Kasse ist gleich soweit.", "Checkout will be ready shortly."),
    vocab=["마스크", "한 통", "약국", "작다", "크다", "계산"],
    particle="을",
)
_add(
    "a1_weekend_rain",
    frame="home",
    rel="family",
    sit=("주말에 비가 와서 바깥 약속을 미룹니다.", "Am Wochenende regnet es, deshalb verschiebt man den Termin draußen.", "It will rain this weekend, so you put off the outdoor plan."),
    need=("토요일에 비 온대. 외출 미룰까?", "Am Samstag soll es regnen. Verschieben wir das Rausgehen?", "It is supposed to rain Saturday. Should we put off going out?"),
    ask=("우산을 가져갈까, 그냥 집에 있을까?", "Schirm mitnehmen oder zu Hause bleiben?", "Take an umbrella, or just stay home?"),
    wait=("오후에 다시 하늘 보면 돼.", "Nachmittags können wir noch einmal nach dem Himmel schauen.", "We can check the sky again in the afternoon."),
    vocab=["주말", "비", "토요일", "외출", "우산", "집"],
    particle="을",
)
_add(
    "a1_late_text",
    frame="home",
    rel="family",
    sit=("늦는다는 문자를 짧게 보냅니다.", "Man schreibt kurz, dass man sich verspätet.", "You send a short text that you will be late."),
    need=("십 분 늦을게. 먼저 먹어.", "Ich bin zehn Minuten später. Iss schon mal.", "I'll be ten minutes late. Start eating."),
    ask=("문자를 엄마에게 보냈어?", "Hast du Mama schon geschrieben?", "Did you text mom?"),
    wait=("곧 도착한다고 다시 쓸게.", "Ich schreibe gleich, dass ich bald da bin.", "I'll write again that I'm almost there."),
    vocab=["문자", "늦다", "십 분", "먼저", "도착", "보내다"],
    particle="를",
)
_add(
    "a1_neighbor_box",
    frame="home",
    rel="neighbor",
    sit=("이웃 택배가 우리 집에 와서 알려 줍니다.", "Ein Nachbarpaket ist bei uns angekommen, deshalb sagt man Bescheid.", "A neighbor's parcel arrived at your place, so you let them know."),
    need=("택배가 저희 집에 왔어요. 언제 가져가실래요?", "Ihr Paket ist bei uns. Wann holen Sie es ab?", "Your parcel is at our place. When will you pick it up?"),
    ask=("이름을 문에 적어 둘까요?", "Soll ich den Namen an die Tür schreiben?", "Should I write the name on the door?"),
    wait=("저녁에 바로 가져가시면 됩니다.", "Sie können es heute Abend gleich abholen.", "You can pick it up this evening."),
    vocab=["이웃", "택배", "집", "이름", "문", "저녁"],
    particle="을",
)
_add(
    "a1_hall_shoes",
    frame="home",
    rel="neighbor",
    sit=("복도에 둔 신발을 안으로 옮깁니다.", "Man räumt Schuhe aus dem Flur nach drinnen.", "You move shoes from the hallway inside."),
    need=("복도에 신발이 있어요. 안으로 넣을까요?", "Im Flur stehen Schuhe. Soll ich sie reinstellen?", "There are shoes in the hallway. Should I put them inside?"),
    ask=("이 신발을 안으로 옮길까요?", "Soll ich diese Schuhe nach drinnen bringen?", "Should I move these shoes inside?"),
    wait=("지금 바로 치우면 됩니다.", "Wir können sie gleich wegräumen.", "We can clear them away now."),
    vocab=["복도", "신발", "안", "옮기다", "치우다", "문"],
    particle="을",
)
_add(
    "a1_class_pencil",
    frame="class",
    rel="student_and_teacher",
    sit=("수업에서 필통을 잠시 빌립니다.", "Im Unterricht leiht man kurz ein Mäppchen.", "You borrow a pencil case for a moment in class."),
    need=("필통 잠시 빌려도 될까요?", "Darf ich kurz das Mäppchen leihen?", "May I borrow a pencil case for a moment?"),
    ask=("연필을 같이 드릴까요?", "Soll ich einen Bleistift dazu geben?", "Should I give you a pencil too?"),
    wait=("수업 끝에 바로 돌려주세요.", "Bitte nach dem Unterricht gleich zurück.", "Please return it right after class."),
    vocab=["필통", "빌리다", "연필", "수업", "돌리다", "잠시"],
    particle="을",
)
_add(
    "a1_submit_name",
    frame="class",
    rel="student_and_teacher",
    sit=("숙제 위에 이름을 씁니다.", "Man schreibt den Namen auf die Hausaufgabe.", "You write your name on the homework."),
    need=("숙제 어디에 이름을 쓸까요?", "Wohin soll ich den Namen auf die Aufgabe schreiben?", "Where should I write my name on the homework?"),
    ask=("오른쪽 위를 보시면 됩니다.", "Schauen Sie oben rechts.", "Look at the top right."),
    wait=("지금 바로 걷겠습니다.", "Ich sammle gleich ein.", "I'll collect them now."),
    vocab=["숙제", "이름", "오른쪽", "위", "쓰다", "걷다"],
    particle="를",
)
_add(
    "a1_subway_exit",
    frame="service",
    rel="stranger",
    sit=("지하철에서 사 번 출구를 찾습니다.", "In der Bahn sucht man Ausgang vier.", "You look for exit four in the subway."),
    need=("사 번 출구가 어디예요?", "Wo ist Ausgang vier?", "Where is exit four?"),
    ask=("이 화살표를 따라가시면 됩니다.", "Folgen Sie diesem Pfeil.", "Follow this arrow."),
    wait=("계단은 바로 앞에 있습니다.", "Die Treppe ist gleich vorn.", "The stairs are right ahead."),
    vocab=["지하철", "출구", "사 번", "화살표", "계단", "어디"],
    particle="를",
)
_add(
    "a1_last_train",
    frame="service",
    rel="customer_and_service_staff",
    sit=("오늘 막차가 몇 시인지 묻습니다.", "Man fragt nach der Uhrzeit des letzten Zuges.", "You ask what time the last train is."),
    need=("오늘 막차가 몇 시예요?", "Wann fährt heute der letzte Zug?", "What time is the last train today?"),
    ask=("이 화면을 보시면 됩니다.", "Schauen Sie auf diesen Bildschirm.", "Look at this screen."),
    wait=("십일 시 이십 분에 있습니다.", "Um dreiundzwanzig Uhr zwanzig.", "It is at eleven twenty."),
    vocab=["막차", "오늘", "몇 시", "화면", "십일 시", "기차"],
    particle="을",
)
_add(
    "a1_card_topup",
    frame="service",
    rel="customer_and_service_staff",
    sit=("교통카드에 돈을 넣습니다.", "Man lädt Geld auf die Fahrkarte.", "You put money on a transit card."),
    need=("카드에 만 원만 넣어 주세요.", "Bitte laden Sie zehntausend Won auf die Karte.", "Please put ten thousand won on the card."),
    ask=("현금을 여기에 넣으시겠어요?", "Möchten Sie das Bargeld hier einlegen?", "Would you put the cash in here?"),
    wait=("충전은 바로 끝납니다.", "Das Aufladen ist gleich fertig.", "The top-up will finish shortly."),
    vocab=["카드", "충전", "만 원", "현금", "넣다", "교통"],
    particle="을",
)
_add(
    "a1_weather_layer",
    frame="home",
    rel="family",
    sit=("밖이 추워서 겉옷을 챙깁니다.", "Weil es kalt ist, nimmt man eine Jacke mit.", "It is cold outside, so you take a jacket."),
    need=("오늘 춥대. 겉옷 가져갈게.", "Heute soll es kalt sein. Ich nehme eine Jacke mit.", "It is supposed to be cold today. I'll take a jacket."),
    ask=("목도리를 같이 가져갈래?", "Nimmst du auch einen Schal mit?", "Will you take a scarf too?"),
    wait=("현관에 바로 있어.", "Am Eingang liegt sie bereit.", "It is right by the door."),
    vocab=["겉옷", "춥다", "목도리", "현관", "가져가다", "오늘"],
    particle="를",
)
_add(
    "a1_dust_mask",
    frame="service",
    rel="customer_and_service_staff",
    sit=("미세먼지가 많아서 마스크를 삽니다.", "Bei Feinstaub kauft man eine Maske.", "There is a lot of fine dust, so you buy a mask."),
    need=("미세먼지용 마스크 있어요?", "Haben Sie Masken gegen Feinstaub?", "Do you have masks for fine dust?"),
    ask=("이 흰색을 드릴까요?", "Soll ich diese weiße geben?", "Should I give you this white one?"),
    wait=("계산대에서 바로 드릴게요.", "An der Kasse gebe ich sie gleich.", "I'll give it to you at the register now."),
    vocab=["미세먼지", "마스크", "흰색", "계산대", "많다", "사다"],
    particle="을",
)
_add(
    "a1_sorry_late",
    frame="peer",
    rel="peer",
    sit=("약속에 늦어서 짧게 사과합니다.", "Man kommt zu spät und entschuldigt sich kurz.", "You are late and say a short sorry."),
    need=("미안. 버스가 늦어서 지금 왔어.", "Sorry. Der Bus war spät, deshalb bin ich jetzt da.", "Sorry. The bus was late, so I just got here."),
    ask=("음료를 먼저 시켜 둘까?", "Soll ich schon ein Getränk bestellen?", "Should I order a drink first?"),
    wait=("오 분만 더 기다리면 돼.", "Fünf Minuten warten reicht.", "Five more minutes of waiting is enough."),
    vocab=["미안하다", "늦다", "버스", "음료", "기다리다", "약속"],
    particle="를",
)
_add(
    "a1_thanks_seat",
    frame="service",
    rel="stranger",
    sit=("자리를 양보받고 감사합니다.", "Man bekommt einen Platz und dankt.", "Someone gives you a seat and you say thanks."),
    need=("자리 양보해 주셔서 감사합니다.", "Danke, dass Sie den Platz überlassen.", "Thank you for giving up the seat."),
    ask=("이 옆을 쓰셔도 됩니다.", "Sie können auch daneben sitzen.", "You may sit next to it as well."),
    wait=("다음 역에서 바로 내리시면 됩니다.", "Steigen Sie am nächsten Halt gleich aus.", "Get off at the next stop."),
    vocab=["자리", "양보", "감사하다", "옆", "다음 역", "내리다"],
    particle="을",
)
_add(
    "a1_slow_speech",
    frame="class",
    rel="student_and_teacher",
    sit=("말이 빨라서 천천히 해 달라고 합니다.", "Weil es zu schnell ist, bittet man um langsameres Sprechen.", "Speech is too fast, so you ask to slow down."),
    need=("죄송해요. 조금 천천히 말해 주세요.", "Entschuldigung. Bitte sprechen Sie etwas langsamer.", "Sorry. Please speak a bit more slowly."),
    ask=("이 문장을 다시 들을까요?", "Soll ich diesen Satz noch einmal sagen?", "Should I say this sentence again?"),
    wait=("천천히 다시 말하겠습니다.", "Ich sage es gleich langsamer.", "I'll say it more slowly now."),
    vocab=["천천히", "말하다", "문장", "다시", "죄송하다", "듣다"],
    particle="을",
)
_add(
    "a1_door_bell",
    frame="home",
    rel="family",
    sit=("집 앞에서 초인종을 누릅니다.", "Vor der Wohnung klingelt man.", "You ring the doorbell at the door."),
    need=("나 왔어. 문 좀 열어 줘.", "Ich bin da. Mach bitte die Tür auf.", "I'm here. Please open the door."),
    ask=("열쇠를 가져왔어?", "Hast du den Schlüssel dabei?", "Did you bring the key?"),
    wait=("지금 내려갈게. 일 분만 기다려.", "Ich komme runter. Warte eine Minute.", "I'll come down. Wait one minute."),
    vocab=["초인종", "문", "열쇠", "열다", "일 분", "집"],
    particle="를",
)
_add(
    "a1_trash_sort",
    frame="home",
    rel="neighbor",
    sit=("쓰레기를 종류별로 나눕니다.", "Man trennt den Müll nach Art.", "You sort trash by type."),
    need=("비닐은 어디에 넣어요?", "Wohin kommt das Plastik?", "Where does the plastic go?"),
    ask=("노란 봉지를 쓰시면 됩니다.", "Bitte die gelbe Tüte nehmen.", "Please use the yellow bag."),
    wait=("내일 아침에 수거하러 와요.", "Morgen früh wird der Müll abgeholt.", "They pick up the trash tomorrow morning."),
    vocab=["쓰레기", "비닐", "봉지", "나누다", "수거", "아침"],
    particle="를",
)
_add(
    "a1_gate_code",
    frame="home",
    rel="neighbor",
    sit=("공동현관 비밀번호를 확인합니다.", "Man prüft den Code am Hauseingang.", "You check the entrance door code."),
    need=("공동현관 비밀번호가 뭐예요?", "Wie ist der Code am Hauseingang?", "What is the entrance door code?"),
    ask=("이 숫자를 누르시면 됩니다.", "Drücken Sie diese Zahlen.", "Press these numbers."),
    wait=("문은 바로 열립니다.", "Die Tür geht gleich auf.", "The door will open right away."),
    vocab=["공동현관", "비밀번호", "숫자", "누르다", "문", "열리다"],
    particle="를",
)
_add(
    "a1_whiteboard_word",
    frame="class",
    rel="student_and_teacher",
    sit=("칠판에 적힌 단어를 확인합니다.", "Man prüft das Wort an der Tafel.", "You check the word written on the board."),
    need=("저 단어가 뭐예요? 다시 읽어 주세요.", "Was ist das Wort? Bitte noch einmal lesen.", "What is that word? Please read it again."),
    ask=("이 단어를 노트에 쓰시겠어요?", "Schreiben Sie das Wort ins Heft?", "Would you write the word in your notebook?"),
    wait=("발음은 바로 다시 해 드릴게요.", "Die Aussprache mache ich gleich noch einmal.", "I'll say the pronunciation again now."),
    vocab=["단어", "칠판", "노트", "읽다", "쓰다", "발음"],
    particle="를",
)
_add(
    "a1_platform_line",
    frame="service",
    rel="stranger",
    sit=("승강장에서 노란 선 뒤에 섭니다.", "Am Bahnsteig bleibt man hinter der gelben Linie.", "You stand behind the yellow line on the platform."),
    need=("노란 선 뒤에 서면 되나요?", "Soll ich hinter der gelben Linie stehen?", "Should I stand behind the yellow line?"),
    ask=("이 선을 넘지 마세요.", "Bitte diese Linie nicht überschreiten.", "Please do not cross this line."),
    wait=("열차는 일 분 뒤에 옵니다.", "Der Zug kommt in einer Minute.", "The train comes in one minute."),
    vocab=["승강장", "노란 선", "뒤", "서다", "열차", "일 분"],
    particle="을",
)
_add(
    "a1_rain_jacket",
    frame="service",
    rel="customer_and_service_staff",
    sit=("비가 와서 우비를 찾습니다.", "Weil es regnet, sucht man eine Regenjacke.", "It is raining, so you look for a rain jacket."),
    need=("우비 있어요? 하나 사고 싶어요.", "Haben Sie Regenjacken? Ich möchte eine kaufen.", "Do you have rain jackets? I want to buy one."),
    ask=("이 노란색을 입어 보시겠어요?", "Möchten Sie dieses Gelbe anprobieren?", "Would you like to try this yellow one?"),
    wait=("계산대로 오시면 됩니다.", "Bitte zur Kasse kommen.", "Please come to the register."),
    vocab=["우비", "비", "노랗다", "입다", "사다", "계산"],
    particle="을",
)
_add(
    "a1_excuse_pass",
    frame="service",
    rel="stranger",
    sit=("좁은 길에서 실례하고 지나갑니다.", "Auf einem engen Weg bittet man um Durchlass.", "On a narrow path you ask to pass through."),
    need=("실례합니다. 지나갈게요.", "Entschuldigung. Ich gehe vorbei.", "Excuse me. I'll pass through."),
    ask=("이 옆을 지나가시면 됩니다.", "Gehen Sie hier daneben vorbei.", "Please pass on this side."),
    wait=("조금 기다리시면 길이 납니다.", "Gleich ist der Weg frei.", "The path will be clear in a moment."),
    vocab=["실례", "지나가다", "옆", "길", "좁다", "기다리다"],
    particle="을",
)
_add(
    "a1_ask_again",
    frame="class",
    rel="student_and_teacher",
    sit=("못 알아들어서 한 번 더 부탁합니다.", "Man hat es nicht verstanden und bittet um Wiederholung.", "You did not catch it and ask once more."),
    need=("한 번 더 말해 주세요.", "Bitte sagen Sie es noch einmal.", "Please say it one more time."),
    ask=("어느 부분을 다시 들을까요?", "Welchen Teil soll ich wiederholen?", "Which part should I say again?"),
    wait=("처음부터 다시 말할게요.", "Ich sage es gleich von vorn.", "I'll say it from the start."),
    vocab=["한 번 더", "알아듣다", "부분", "처음부터", "말하다", "듣다"],
    particle="을",
)
_add(
    "a1_meet_station",
    frame="peer",
    rel="peer",
    sit=("역 앞에서 친구를 기다립니다.", "Vor dem Bahnhof wartet man auf eine Freundin.", "You wait for a friend in front of the station."),
    need=("나 역 앞이야. 곧 와?", "Ich bin vor dem Bahnhof. Kommst du gleich?", "I'm in front of the station. Are you coming soon?"),
    ask=("빨간 문을 보고 있으면 돼?", "Soll ich zur roten Tür schauen?", "Should I watch the red door?"),
    wait=("오 분 안에 나갈게.", "Ich komme in fünf Minuten raus.", "I'll come out in five minutes."),
    vocab=["역", "앞", "친구", "빨간 문", "오 분", "기다리다"],
    particle="을",
)
_add(
    "a1_cancel_walk",
    frame="home",
    rel="family",
    sit=("산책을 취소하고 집에 있기로 합니다.", "Man sagt den Spaziergang ab und bleibt zu Hause.", "You cancel the walk and stay home."),
    need=("오늘 산책 취소하자. 너무 피곤해.", "Sagen wir den Spaziergang heute ab. Ich bin zu müde.", "Let's cancel the walk today. I'm too tired."),
    ask=("차를 집에 끓일까?", "Soll ich zu Hause Tee kochen?", "Should I make tea at home?"),
    wait=("조금 쉬면 다시 이야기하자.", "Nach einer Pause sprechen wir weiter.", "Let's talk again after a short rest."),
    vocab=["산책", "취소", "피곤하다", "차", "집", "쉬다"],
    particle="를",
)
_add(
    "a1_floor_number",
    frame="home",
    rel="family",
    sit=("엘리베이터가 몇 층인지 확인합니다.", "Man prüft, in welchem Stock der Aufzug ist.", "You check which floor the elevator is on."),
    need=("우리 집 몇 층이지? 버튼을 눌러 줘.", "In welchem Stock wohnen wir? Drück bitte den Knopf.", "Which floor is our place? Please press the button."),
    ask=("삼 층을 누르면 돼?", "Soll ich drei drücken?", "Should I press three?"),
    wait=("문이 바로 열릴 거야.", "Die Tür geht gleich auf.", "The door will open soon."),
    vocab=["층", "버튼", "삼 층", "누르다", "문", "집"],
    particle="을",
)
_add(
    "a1_locker_key",
    frame="service",
    rel="customer_and_service_staff",
    sit=("락커 열쇠를 어디에 두었는지 찾습니다.", "Man sucht den Spindschlüssel.", "You look for where the locker key is."),
    need=("락커 열쇠를 어디에 두면 돼요?", "Wohin soll ich den Spindschlüssel legen?", "Where should I put the locker key?"),
    ask=("이 바구니를 쓰시면 됩니다.", "Bitte diesen Korb benutzen.", "Please use this basket."),
    wait=("열쇠는 바로 옆에 있습니다.", "Der Schlüssel liegt gleich daneben.", "The key is right next to it."),
    vocab=["락커", "열쇠", "바구니", "어디", "두다", "옆"],
    particle="를",
)
_add(
    "a1_bus_late",
    frame="service",
    rel="stranger",
    sit=("버스가 늦어서 다음 차를 확인합니다.", "Der Bus ist spät, deshalb prüft man die nächste Fahrt.", "The bus is late, so you check the next one."),
    need=("이 버스가 많이 늦어요?", "Ist dieser Bus sehr spät?", "Is this bus very late?"),
    ask=("이 전광판을 보시면 됩니다.", "Schauen Sie auf diese Anzeige.", "Look at this display."),
    wait=("다음 버스는 칠 분 뒤에 옵니다.", "Der nächste Bus kommt in sieben Minuten.", "The next bus comes in seven minutes."),
    vocab=["버스", "늦다", "전광판", "다음", "칠 분", "오다"],
    particle="을",
)
_add(
    "a1_water_shop",
    frame="service",
    rel="customer_and_service_staff",
    sit=("가게에서 물을 삽니다.", "Im Laden kauft man Wasser.", "You buy water at a shop."),
    need=("물 한 병 주세요.", "Eine Flasche Wasser, bitte.", "One bottle of water, please."),
    ask=("차가운 물을 드릴까요?", "Soll ich kaltes Wasser geben?", "Would you like cold water?"),
    wait=("여기서 바로 계산하시면 됩니다.", "Sie können hier gleich zahlen.", "You can pay here now."),
    vocab=["물", "한 병", "차갑다", "가게", "사다", "계산"],
    particle="을",
)
_add(
    "a1_tea_order",
    frame="service",
    rel="customer_and_service_staff",
    sit=("카페에서 차를 주문합니다.", "Im Café bestellt man Tee.", "You order tea at a cafe."),
    need=("따뜻한 차 한 잔 주세요.", "Einen heißen Tee, bitte.", "One hot tea, please."),
    ask=("녹차를 드릴까요?", "Darf es Grüntee sein?", "Would green tea be all right?"),
    wait=("차는 바로 나옵니다.", "Der Tee kommt gleich.", "The tea will be ready shortly."),
    vocab=["차", "따뜻하다", "녹차", "한 잔", "주문", "카페"],
    particle="를",
)
_add(
    "a1_taxi_address",
    frame="service",
    rel="customer_and_service_staff",
    sit=("택시에서 주소를 말합니다.", "Im Taxi nennt man die Adresse.", "You say the address in a taxi."),
    need=("이 주소로 가 주세요.", "Bitte zu dieser Adresse.", "Please go to this address."),
    ask=("이 길을 따라갈까요?", "Soll ich dieser Straße folgen?", "Should I follow this road?"),
    wait=("십오 분 안에 도착합니다.", "In fünfzehn Minuten sind wir da.", "We will arrive in fifteen minutes."),
    vocab=["택시", "주소", "길", "따라가다", "십오 분", "도착"],
    particle="을",
)
_add(
    "a1_hotel_key",
    frame="service",
    rel="customer_and_service_staff",
    sit=("호텔에서 방 열쇠를 받습니다.", "Im Hotel holt man den Zimmerschlüssel.", "You pick up the room key at the hotel."),
    need=("삼백이 호 열쇠 주세요.", "Den Schlüssel für Zimmer dreihundertzwei, bitte.", "The key for room three oh two, please."),
    ask=("신분증을 보여 주시겠어요?", "Darf ich den Ausweis sehen?", "May I see your ID?"),
    wait=("열쇠는 바로 드리겠습니다.", "Den Schlüssel gebe ich gleich.", "I'll give you the key now."),
    vocab=["호텔", "열쇠", "방", "신분증", "삼백이 호", "받다"],
    particle="을",
)
_add(
    "a1_market_bag",
    frame="service",
    rel="customer_and_service_staff",
    sit=("시장에서 장바구니를 받습니다.", "Auf dem Markt holt man eine Einkaufstasche.", "You get a shopping bag at the market."),
    need=("장바구니 하나 주세요.", "Eine Einkaufstasche, bitte.", "One shopping bag, please."),
    ask=("종이봉투를 드릴까요?", "Soll ich eine Papiertüte geben?", "Would you like a paper bag?"),
    wait=("계산대 옆에 바로 있습니다.", "Sie liegen gleich neben der Kasse.", "They are right next to the register."),
    vocab=["시장", "장바구니", "종이봉투", "계산대", "하나", "옆"],
    particle="를",
)
_add(
    "a1_airport_cart",
    frame="service",
    rel="customer_and_service_staff",
    sit=("공항에서 짐 카트를 빌립니다.", "Am Flughafen leiht man einen Gepäckwagen.", "You borrow a luggage cart at the airport."),
    need=("카트는 어디에 있어요?", "Wo gibt es einen Wagen?", "Where can I get a cart?"),
    ask=("이 줄을 따라가시면 됩니다.", "Folgen Sie dieser Reihe.", "Follow this row."),
    wait=("카트는 바로 앞에 있습니다.", "Die Wagen stehen gleich vorn.", "The carts are right ahead."),
    vocab=["공항", "카트", "짐", "줄", "앞", "빌리다"],
    particle="을",
)
_add(
    "a1_rice_shop",
    frame="service",
    rel="customer_and_service_staff",
    sit=("김밥 가게에서 김밥을 주문합니다.", "Im Kimbap-Laden bestellt man Kimbap.", "You order kimbap at a kimbap shop."),
    need=("참치 김밥 하나 주세요.", "Ein Thunfisch-Kimbap, bitte.", "One tuna kimbap, please."),
    ask=("김밥을 반으로 잘라 드릴까요?", "Soll ich das Kimbap halbieren?", "Should I cut the kimbap in half?"),
    wait=("음식은 오 분 안에 나옵니다.", "Das Essen kommt in fünf Minuten.", "The food comes in five minutes."),
    vocab=["김밥", "참치", "가게", "자르다", "주문", "오 분"],
    particle="을",
)
_add(
    "a1_direction_left",
    frame="service",
    rel="stranger",
    sit=("왼쪽 골목으로 가는 길을 묻습니다.", "Man fragt nach dem Weg in die linke Gasse.", "You ask for the way to the left alley."),
    need=("왼쪽 골목으로 가면 시장이 나와요?", "Kommt man durch die linke Gasse zum Markt?", "Does the left alley lead to the market?"),
    ask=("이 모퉁이를 돌면 됩니다.", "Biegen Sie an dieser Ecke ab.", "Turn at this corner."),
    wait=("표지판이 바로 보입니다.", "Das Schild sehen Sie gleich.", "You will see the sign right away."),
    vocab=["왼쪽", "골목", "시장", "모퉁이", "돌다", "표지판"],
    particle="를",
)
_add(
    "a1_office_print",
    frame="coworker",
    rel="coworker",
    sit=("사무실에서 인쇄가 안 되어 도움을 청합니다.", "Im Büro druckt nichts, deshalb bittet man um Hilfe.", "The office printer is stuck, so you ask for help."),
    need=("인쇄가 안 돼요. 이 장 좀 뽑아 주세요.", "Es druckt nicht. Bitte diese Seite ausgeben.", "It will not print. Please print this page."),
    ask=("이 버튼을 눌러 볼까요?", "Soll ich diesen Knopf drücken?", "Should I press this button?"),
    wait=("한 장만 다시 나오면 됩니다.", "Eine Seite muss nur noch einmal kommen.", "Only one page needs to come out again."),
    vocab=["사무실", "인쇄", "버튼", "한 장", "뽑다", "누르다"],
    particle="을",
)
_add(
    "a1_cafe_wifi",
    frame="service",
    rel="customer_and_service_staff",
    sit=("카페에서 와이파이 비밀번호를 묻습니다.", "Im Café fragt man nach dem WLAN-Passwort.", "You ask for the wifi password at a cafe."),
    need=("와이파이 비밀번호가 뭐예요?", "Wie lautet das WLAN-Passwort?", "What is the wifi password?"),
    ask=("영수증을 뒤집으면 됩니다.", "Drehen Sie den Bon um.", "Turn the receipt over."),
    wait=("번호를 바로 불러 드릴게요.", "Ich sage Ihnen die Nummer gleich.", "I'll read the number now."),
    vocab=["카페", "와이파이", "비밀번호", "영수증", "번호", "뒤집다"],
    particle="을",
)
_add(
    "a1_station_rest",
    frame="service",
    rel="stranger",
    sit=("역에서 화장실이 어디인지 묻습니다.", "Am Bahnhof fragt man nach der Toilette.", "You ask where the restroom is at the station."),
    need=("화장실이 어디예요?", "Wo ist die Toilette?", "Where is the restroom?"),
    ask=("이 계단을 내려가시면 됩니다.", "Gehen Sie diese Treppe hinunter.", "Go down these stairs."),
    wait=("표지판이 바로 보입니다.", "Das Schild sehen Sie gleich.", "You will see the sign right away."),
    vocab=["역", "화장실", "어디", "계단", "내려가다", "표지판"],
    particle="을",
)
_add(
    "a1_home_light",
    frame="home",
    rel="family",
    sit=("현관 불이 꺼져서 켭니다.", "Das Licht im Flur ist aus, deshalb macht man es an.", "The hall light is off, so you turn it on."),
    need=("현관 불이 꺼졌어. 좀 켜 줘.", "Das Licht im Flur ist aus. Mach es bitte an.", "The hall light is off. Please turn it on."),
    ask=("스위치를 왼쪽에서 찾을까?", "Soll ich den Schalter links suchen?", "Should I look for the switch on the left?"),
    wait=("지금 바로 켜질 거야.", "Es geht gleich an.", "It will come on now."),
    vocab=["현관", "불", "스위치", "켜다", "왼쪽", "꺼지다"],
    particle="를",
)
_add(
    "a1_pharmacy_hours",
    frame="service",
    rel="customer_and_service_staff",
    sit=("약국이 몇 시에 닫는지 묻습니다.", "Man fragt, wann die Apotheke schließt.", "You ask what time the pharmacy closes."),
    need=("오늘 몇 시에 문 닫아요?", "Um wie viel Uhr schließen Sie heute?", "What time do you close today?"),
    ask=("이 안내문을 보시면 됩니다.", "Schauen Sie auf diesen Aushang.", "Look at this notice."),
    wait=("여덟 시까지 열어둡니다.", "Wir haben bis zwanzig Uhr auf.", "We stay open until eight."),
    vocab=["약국", "문", "닫다", "안내문", "여덟 시", "오늘"],
    particle="을",
)
_add(
    "a2_phone_plan",
    frame="service",
    rel="customer_and_service_staff",
    sit=("휴대폰 요금제를 더 싼 것으로 바꿉니다.", "Man wechselt den Handytarif zu einem günstigeren.", "You change the phone plan to a cheaper one."),
    need=("데이터를 줄이고 요금만 낮추고 싶어요.", "Ich möchte weniger Daten und eine niedrigere Gebühr.", "I want less data and a lower fee."),
    ask=("이 표를 같이 볼까요?", "Sollen wir diese Tabelle zusammen ansehen?", "Shall we look at this table together?"),
    wait=("변경은 오늘 저녁에 반영됩니다.", "Die Änderung gilt ab heute Abend.", "The change takes effect this evening."),
    vocab=["요금제", "데이터", "바꾸다", "표", "저녁", "낮추다"],
)
_add(
    "a2_data_roam",
    frame="service",
    rel="customer_and_service_staff",
    sit=("여행 전에 로밍을 신청합니다.", "Vor der Reise beantragt man Roaming.", "You apply for roaming before a trip."),
    need=("다음 주 독일 여행이라 로밍이 필요해요.", "Nächste Woche reise ich nach Deutschland, deshalb brauche ich Roaming.", "I travel to Germany next week, so I need roaming."),
    ask=("기간을 열흘로 넣을까요?", "Soll ich zehn Tage eintragen?", "Should I set it for ten days?"),
    wait=("신청은 바로 접수됩니다.", "Der Antrag ist gleich aufgenommen.", "The request is logged right away."),
    vocab=["로밍", "여행", "독일", "기간", "열흘", "신청"],
)
_add(
    "a2_bank_number",
    frame="service",
    rel="customer_and_service_staff",
    sit=("은행에서 대기번호를 뽑습니다.", "In der Bank zieht man eine Wartenummer.", "You take a queue number at the bank."),
    need=("이체하려면 번호를 어디서 뽑아요?", "Wo ziehe ich eine Nummer für eine Überweisung?", "Where do I take a number for a transfer?"),
    ask=("이 기계를 누르시면 됩니다.", "Drücken Sie an diesem Gerät.", "Press this machine."),
    wait=("세 번만 기다리시면 됩니다.", "Sie warten nur noch drei Nummern.", "You only wait for three more numbers."),
    vocab=["은행", "대기번호", "이체", "기계", "뽑다", "기다리다"],
)
_add(
    "a2_transfer_limit",
    frame="service",
    rel="customer_and_service_staff",
    sit=("하루 이체 한도를 올립니다.", "Man erhöht das Tageslimit für Überweisungen.", "You raise the daily transfer limit."),
    need=("오늘 집세 내려고 한도를 올리고 싶어요.", "Ich möchte das Limit erhöhen, um heute die Miete zu zahlen.", "I want to raise the limit to pay rent today."),
    ask=("신분증을 보여 주시겠어요?", "Darf ich den Ausweis sehen?", "May I see your ID?"),
    wait=("한도는 오 분 안에 바뀝니다.", "Das Limit ändert sich in fünf Minuten.", "The limit changes in five minutes."),
    vocab=["이체", "한도", "집세", "신분증", "오늘", "올리다"],
)
_add(
    "a2_gym_lock",
    frame="service",
    rel="customer_and_service_staff",
    sit=("헬스장에서 락커를 맡깁니다.", "Im Fitnessstudio gibt man einen Spind ab.", "You check a locker at the gym."),
    need=("락커 하나 맡기고 운동할게요.", "Ich gebe einen Spind ab und trainiere dann.", "I'll leave a locker and then work out."),
    ask=("자물쇠를 앞에서 빌릴까요?", "Soll ich das Schloss vorn ausleihen?", "Should I borrow a lock at the front?"),
    wait=("락커는 바로 안내하겠습니다.", "Den Spind zeige ich gleich.", "I'll show you the locker now."),
    vocab=["락커", "헬스장", "자물쇠", "맡기다", "운동", "빌리다"],
)
_add(
    "a2_stretch_start",
    frame="home",
    rel="peer",
    sit=("운동 전에 준비운동을 같이 합니다.", "Vor dem Training macht man zusammen Aufwärmen.", "You warm up together before exercise."),
    need=("바로 뛰지 말고 준비운동부터 하자.", "Nicht gleich laufen. Erst aufwärmen.", "Do not run yet. Let's warm up first."),
    ask=("어깨를 먼저 돌릴까?", "Sollen wir zuerst die Schultern kreisen?", "Shall we roll the shoulders first?"),
    wait=("삼 분만 하면 충분해.", "Drei Minuten reichen.", "Three minutes is enough."),
    vocab=["준비운동", "어깨", "돌리다", "삼 분", "운동", "먼저"],
)
_add(
    "a2_salon_cut",
    frame="service",
    rel="customer_and_service_staff",
    sit=("미용실에서 자를 길이를 정합니다.", "Beim Friseur legt man die Schnittlänge fest.", "You decide the cut length at the salon."),
    need=("귀 위로 조금만 잘라 주세요.", "Bitte nur wenig über den Ohren kürzen.", "Please cut just a little above the ears."),
    ask=("사진을 보여 주시겠어요?", "Können Sie ein Foto zeigen?", "Could you show a photo?"),
    wait=("이십 분 안에 끝납니다.", "In zwanzig Minuten sind wir fertig.", "We will finish in twenty minutes."),
    vocab=["미용실", "길이", "귀", "자르다", "사진", "이십 분"],
)
_add(
    "a2_dye_dark",
    frame="service",
    rel="customer_and_service_staff",
    sit=("염색을 얼마나 어둡게 할지 고릅니다.", "Man wählt, wie dunkel die Farbe sein soll.", "You choose how dark the dye should be."),
    need=("지금은 너무 밝아서 한 단계만 어둡게 하고 싶어요.", "Jetzt ist es zu hell. Nur eine Stufe dunkler bitte.", "It is too light now. Just one step darker, please."),
    ask=("이 갈색을 쓸까요?", "Soll ich dieses Braun nehmen?", "Should I use this brown?"),
    wait=("색은 사십 분 뒤에 나옵니다.", "Die Farbe sitzt in vierzig Minuten.", "The color will be ready in forty minutes."),
    vocab=["염색", "어둡다", "밝다", "갈색", "한 단계", "색"],
)
_add(
    "a2_apt_sticker",
    frame="service",
    rel="neighbor",
    sit=("아파트 주차 스티커를 신청합니다.", "Man beantragt den Parkaufkleber der Wohnung.", "You apply for the apartment parking sticker."),
    need=("주차 스티커를 새로 받고 싶어요.", "Ich möchte einen neuen Parkaufkleber.", "I want a new parking sticker."),
    ask=("차 번호를 불러 주시겠어요?", "Können Sie das Autokennzeichen sagen?", "Could you say the car number?"),
    wait=("스티커는 내일 오전에 나옵니다.", "Der Aufkleber ist morgen Vormittag da.", "The sticker will be ready tomorrow morning."),
    vocab=["주차", "스티커", "아파트", "차 번호", "신청", "내일"],
)
_add(
    "a2_food_bag",
    frame="home",
    rel="neighbor",
    sit=("음식물 봉투가 떨어져 하나를 받습니다.", "Die Biotüte ist leer, deshalb holt man eine neue.", "The food-waste bag is gone, so you get one."),
    need=("음식물 봉투가 떨어졌어요. 어디서 받아요?", "Die Biotüte ist alle. Wo bekomme ich eine?", "The food-waste bag is gone. Where do I get one?"),
    ask=("관리실을 오전에 가시면 됩니다.", "Gehen Sie vormittags ins Büro.", "Go to the office in the morning."),
    wait=("봉투는 바로 드립니다.", "Die Tüten gibt es gleich.", "You can get the bags right away."),
    vocab=["음식물", "봉투", "떨어지다", "관리실", "오전", "받다"],
)
_add(
    "a2_shift_table",
    frame="coworker",
    rel="coworker",
    sit=("다음 주 근무표를 확인합니다.", "Man prüft den Dienstplan für nächste Woche.", "You check next week's shift table."),
    need=("수요일 저녁 근무가 맞는지 보고 싶어요.", "Ich möchte prüfen, ob der Mittwochabend stimmt.", "I want to check if Wednesday evening is right."),
    ask=("이 칸을 같이 볼까요?", "Sollen wir dieses Feld zusammen ansehen?", "Shall we look at this cell together?"),
    wait=("표는 오늘 안에 확정됩니다.", "Der Plan steht heute noch fest.", "The table will be confirmed today."),
    vocab=["근무표", "수요일", "저녁", "칸", "확정", "다음 주"],
)
_add(
    "a2_night_pay",
    frame="coworker",
    rel="coworker",
    sit=("야간수당이 빠졌는지 묻습니다.", "Man fragt, ob der Nachtzuschlag fehlt.", "You ask whether the night bonus is missing."),
    need=("지난주 야간수당이 안 들어온 것 같아요.", "Der Nachtzuschlag von letzter Woche fehlt wohl.", "Last week's night bonus does not seem to be in."),
    ask=("근무 시간을 다시 적어 볼까요?", "Soll ich die Arbeitszeit noch einmal notieren?", "Should I write the hours again?"),
    wait=("급여는 내일 다시 확인됩니다.", "Die Zahlung wird morgen erneut geprüft.", "Pay will be checked again tomorrow."),
    vocab=["야간수당", "지난주", "근무", "시간", "급여", "확인"],
)
_add(
    "a2_lost_wallet",
    frame="service",
    rel="customer_and_service_staff",
    sit=("역에서 지갑을 잃어 습득함에 묻습니다.", "Am Bahnhof fragt man an der Fundsache nach der Geldbörse.", "You lost a wallet and ask at the station hold desk."),
    need=("검은 지갑을 이 근처에서 잃어버렸어요.", "Ich habe hier in der Nähe eine schwarze Geldbörse verloren.", "I lost a black wallet around here."),
    ask=("카드를 몇 장 넣었는지 말해주시겠어요?", "Können Sie sagen, wie viele Karten drin waren?", "Could you say how many cards were inside?"),
    wait=("보관함을 바로 찾아보겠습니다.", "Ich schaue gleich im Fundfach nach.", "I'll check the hold box now."),
    vocab=["지갑", "잃어버리다", "검은색", "카드", "보관함", "역"],
)
_add(
    "a2_found_umbrella",
    frame="service",
    rel="customer_and_service_staff",
    sit=("주운 우산을 역에 맡깁니다.", "Man gibt einen gefundenen Schirm am Bahnhof ab.", "You turn in a found umbrella at the station."),
    need=("이 우산을 의자 아래에서 주었어요.", "Ich habe diesen Schirm unter dem Sitz gefunden.", "I found this umbrella under a seat."),
    ask=("색깔을 종이에 적을까요?", "Soll ich die Farbe auf Papier schreiben?", "Should I write the color on paper?"),
    wait=("보관은 바로 됩니다.", "Die Aufbewahrung ist gleich erledigt.", "We can store it right away."),
    vocab=["우산", "줍다", "의자", "색깔", "종이", "보관"],
)
_add(
    "a2_festival_stamp",
    frame="service",
    rel="stranger",
    sit=("축제에서 스탬프를 받습니다.", "Auf dem Fest holt man einen Stempel.", "You get a stamp at a festival."),
    need=("이 부스에서 스탬프 받을 수 있어요?", "Bekomme ich an diesem Stand einen Stempel?", "Can I get a stamp at this booth?"),
    ask=("이 칸을 보여 주시겠어요?", "Können Sie dieses Feld zeigen?", "Could you show this box?"),
    wait=("스탬프는 바로 찍어 드립니다.", "Den Stempel setze ich gleich.", "I'll stamp it now."),
    vocab=["축제", "스탬프", "부스", "칸", "찍다", "받다"],
)
_add(
    "a2_booth_line",
    frame="service",
    rel="stranger",
    sit=("축제 부스 줄이 길어서 대기 시간을 묻습니다.", "Die Schlange am Stand ist lang, deshalb fragt man nach der Wartezeit.", "The booth line is long, so you ask how long the wait is."),
    need=("이 줄이 얼마나 걸려요?", "Wie lange dauert diese Schlange?", "How long is this line?"),
    ask=("이 번호를 받아 가시겠어요?", "Möchten Sie diese Nummer mitnehmen?", "Would you like to take this number?"),
    wait=("이십 분 안에 차례가 옵니다.", "In zwanzig Minuten sind Sie dran.", "Your turn comes in twenty minutes."),
    vocab=["부스", "줄", "번호", "이십 분", "차례", "기다리다"],
)
_add(
    "a2_bill_high",
    frame="home",
    rel="family",
    sit=("이번 달 청구서가 높아서 항목을 봅니다.", "Die Rechnung ist hoch, deshalb prüft man die Posten.", "This month's bill is high, so you check the items."),
    need=("이번 달 전기세가 왜 이렇게 높지?", "Warum ist der Strom diesen Monat so hoch?", "Why is electricity so high this month?"),
    ask=("사용량을 같이 볼까?", "Sollen wir den Verbrauch zusammen ansehen?", "Shall we look at the usage together?"),
    wait=("내일 아침에 다시 계산해 보자.", "Morgen früh rechnen wir noch einmal.", "Let's calculate again tomorrow morning."),
    vocab=["청구서", "전기세", "사용량", "높다", "이번 달", "계산"],
)
_add(
    "a2_auto_debit",
    frame="service",
    rel="customer_and_service_staff",
    sit=("자동이체 날짜를 바꿉니다.", "Man ändert das Datum der Lastschrift.", "You change the auto-debit date."),
    need=("월급날 이후로 자동이체를 옮기고 싶어요.", "Ich möchte die Lastschrift hinter den Zahltag legen.", "I want to move auto debit to after payday."),
    ask=("이십오 일로 바꿀까요?", "Soll ich auf den Fünfundzwanzigsten ändern?", "Should I change it to the twenty-fifth?"),
    wait=("변경은 다음 달부터 적용됩니다.", "Die Änderung gilt ab nächstem Monat.", "The change applies from next month."),
    vocab=["자동이체", "월급날", "날짜", "이십오 일", "다음 달", "옮기다"],
)
_add(
    "a2_hair_time",
    frame="service",
    rel="customer_and_service_staff",
    sit=("미용실 시간을 옮깁니다.", "Man verschiebt den Friseurtermin.", "You move a salon appointment."),
    need=("금요일 네 시 예약을 토요일로 바꾸고 싶어요.", "Ich möchte Freitag um vier auf Samstag legen.", "I want to move Friday at four to Saturday."),
    ask=("토요일 열한 시를 드릴까요?", "Darf ich Samstag um elf anbieten?", "Would Saturday at eleven work?"),
    wait=("예약은 바로 옮겨 드립니다.", "Ich verschiebe den Termin gleich.", "I'll move the booking now."),
    vocab=["미용실", "예약", "금요일", "토요일", "열한 시", "옮기다"],
)
_add(
    "a2_quiet_ten",
    frame="home",
    rel="neighbor",
    sit=("밤 열 시 이후 소음을 줄여 달라고 합니다.", "Nach zweiundzwanzig Uhr bittet man um weniger Lärm.", "After ten at night you ask for less noise."),
    need=("열 시 이후에는 발소리를 조금만 줄여 주세요.", "Bitte nach zweiundzwanzig Uhr etwas leiser gehen.", "Please walk a bit more quietly after ten."),
    ask=("매트를 깔면 될까요?", "Würde eine Matte helfen?", "Would a mat help?"),
    wait=("오늘 밤부터 조심하겠습니다.", "Ab heute Nacht passe ich auf.", "I'll be careful from tonight."),
    vocab=["소음", "열 시", "발소리", "매트", "밤", "줄이다"],
)
_add(
    "a2_handover_note",
    frame="coworker",
    rel="coworker",
    sit=("퇴근 전에 인수인계를 남깁니다.", "Vor Feierabend hinterlässt man eine Übergabe.", "You leave a handover note before leaving work."),
    need=("내일 올 사람에게 이것만은 남겨 두고 싶어요.", "Für die Person von morgen will ich wenigstens das hinterlassen.", "I want to leave at least this for the person coming tomorrow."),
    ask=("이 메모를 책상 위에 둘까요?", "Soll ich diese Notiz auf den Tisch legen?", "Should I put this note on the desk?"),
    wait=("아침에 바로 볼 수 있게 두겠습니다.", "Ich lege sie so, dass man sie morgens gleich sieht.", "I'll leave it so it is seen in the morning."),
    vocab=["인수인계", "메모", "책상", "내일", "아침", "남기다"],
)
_add(
    "a2_id_pickup",
    frame="service",
    rel="customer_and_service_staff",
    sit=("만든 신분증을 찾으러 갑니다.", "Man holt den fertigen Ausweis ab.", "You pick up a finished ID."),
    need=("지난주에 신청한 신분증을 찾으러 왔어요.", "Ich hole den Ausweis von letzter Woche ab.", "I came to pick up the ID I applied for last week."),
    ask=("접수 번호를 보여 주시겠어요?", "Können Sie die Antragsnummer zeigen?", "Could you show the request number?"),
    wait=("신분증은 바로 드리겠습니다.", "Den Ausweis gebe ich gleich.", "I'll give you the ID now."),
    vocab=["신분증", "찾다", "지난주", "접수 번호", "신청", "창구"],
)
_add(
    "a2_volunteer_vest",
    frame="service",
    rel="stranger",
    sit=("봉사 전에 안전 조끼를 받습니다.", "Vor dem Ehrenamt holt man eine Warnweste.", "You pick up a safety vest before volunteering."),
    need=("오늘 쓸 조끼를 어디서 받아요?", "Wo bekomme ich die Weste für heute?", "Where do I get today's vest?"),
    ask=("이 노란 조끼를 입으시면 됩니다.", "Bitte diese gelbe Weste anziehen.", "Please put on this yellow vest."),
    wait=("조끼는 바로 옆에 있습니다.", "Die Westen liegen gleich daneben.", "The vests are right next to us."),
    vocab=["조끼", "봉사", "노랗다", "입다", "오늘", "안전"],
)
_add(
    "a2_tea_taste",
    frame="service",
    rel="customer_and_service_staff",
    sit=("시장에서 차를 조금 맛봅니다.", "Auf dem Markt probiert man etwas Tee.", "You taste a little tea at the market."),
    need=("이 차 조금 맛봐도 될까요?", "Darf ich diesen Tee kurz probieren?", "May I taste a little of this tea?"),
    ask=("따뜻한 잔을 드릴까요?", "Soll ich eine warme Tasse geben?", "Should I give you a warm cup?"),
    wait=("시식은 바로 됩니다.", "Die Kostprobe gibt es gleich.", "The tasting is ready now."),
    vocab=["시식", "차", "맛보다", "따뜻하다", "잔", "시장"],
)
_add(
    "a2_contract_read",
    frame="coworker",
    rel="coworker",
    sit=("근로계약서에서 근무 시간만 먼저 읽습니다.", "Im Arbeitsvertrag liest man zuerst nur die Arbeitszeit.", "You first read only the work hours in the contract."),
    need=("서명 전에 근무 시간만 같이 보고 싶어요.", "Vor der Unterschrift will ich nur die Arbeitszeit sehen.", "Before signing I want to look at the hours together."),
    ask=("이 칸을 크게 볼까요?", "Sollen wir dieses Feld größer ansehen?", "Shall we look at this box more closely?"),
    wait=("오 분만 읽으면 됩니다.", "Fünf Minuten Lesen reichen.", "Five minutes of reading is enough."),
    vocab=["근로계약", "근무 시간", "서명", "칸", "읽다", "오 분"],
)
_add(
    "a2_recycle_box",
    frame="home",
    rel="neighbor",
    sit=("재활용실이 가득 차서 어디에 둘지 묻습니다.", "Der Wertstoffraum ist voll, deshalb fragt man, wohin die Sachen sollen.", "The recycling room is full, so you ask where to put things."),
    need=("재활용실이 가득 차서 상자를 둘 데가 없어요.", "Der Raum ist voll. Ich habe keinen Platz für den Karton.", "The recycling room is full. I have nowhere to put the box."),
    ask=("이 구석을 잠시 쓸까요?", "Sollen wir diese Ecke kurz nutzen?", "Shall we use this corner for a moment?"),
    wait=("오후에 바로 비우겠습니다.", "Nachmittags räume ich gleich leer.", "I'll empty it in the afternoon."),
    vocab=["재활용실", "상자", "가득", "구석", "비우다", "오후"],
)
_add(
    "a2_card_balance",
    frame="service",
    rel="customer_and_service_staff",
    sit=("교통카드 잔액이 얼마인지 확인합니다.", "Man prüft das Guthaben auf der Fahrkarte.", "You check how much is left on a transit card."),
    need=("카드에 돈이 얼마나 남았어요?", "Wie viel Geld ist noch auf der Karte?", "How much money is left on the card?"),
    ask=("이 기계에 카드를 올려 보시겠어요?", "Legen Sie die Karte auf dieses Gerät?", "Would you put the card on this machine?"),
    wait=("잔액은 바로 나옵니다.", "Das Guthaben erscheint gleich.", "The balance will show right away."),
    vocab=["카드", "잔액", "기계", "남다", "올리다", "돈"],
)
_add(
    "a2_rain_cancel",
    frame="home",
    rel="peer",
    sit=("비 때문에 바깥 모임을 취소합니다.", "Wegen Regen sagt man das Treffen draußen ab.", "Because of rain you cancel the outdoor meetup."),
    need=("비가 너무 와서 오늘 모임 취소하자.", "Es regnet zu stark. Sagen wir das Treffen heute ab.", "It is raining too hard. Let's cancel today's meetup."),
    ask=("실내를 다른 날로 옮길까?", "Sollen wir nach drinnen auf einen anderen Tag legen?", "Shall we move it indoors to another day?"),
    wait=("내일 아침에 다시 정하자.", "Morgen früh legen wir es neu fest.", "Let's set it again tomorrow morning."),
    vocab=["비", "모임", "취소", "실내", "다른 날", "옮기다"],
)
_add(
    "a2_guest_pass",
    frame="service",
    rel="customer_and_service_staff",
    sit=("방문객에게 출입 카드를 발급합니다.", "Für Gäste stellt man einen Besucherausweis aus.", "You issue a visitor pass for a guest."),
    need=("오늘 오는 손님 방문증이 필요해요.", "Für den Gast von heute brauche ich einen Ausweis.", "I need a visitor pass for today's guest."),
    ask=("이름을 여기에 적을까요?", "Soll ich den Namen hier eintragen?", "Should I write the name here?"),
    wait=("카드는 오 분 안에 나옵니다.", "Die Karte ist in fünf Minuten da.", "The card will be ready in five minutes."),
    vocab=["방문증", "손님", "이름", "카드", "오늘", "적다"],
)
_add(
    "a2_manager_leave",
    frame="coworker",
    rel="coworker",
    sit=("점장에게 하루 휴가를 요청합니다.", "Man bittet die Filialleitung um einen Urlaubstag.", "You ask the store manager for a day of leave."),
    need=("금요일에 병원이라 하루 쉬고 싶어요.", "Am Freitag habe ich Arzt, deshalb möchte ich einen Tag frei.", "I have a clinic visit on Friday, so I want one day off."),
    ask=("대체 근무를 누가 할지 적을까요?", "Soll ich eintragen, wer übernimmt?", "Should I write who will cover?"),
    wait=("오후에 바로 답 드리겠습니다.", "Nachmittags antworte ich gleich.", "I'll answer in the afternoon."),
    vocab=["휴가", "점장", "금요일", "병원", "대체", "하루"],
)
_add(
    "a2_label_phone",
    frame="service",
    rel="customer_and_service_staff",
    sit=("짐 라벨에 적힌 번호를 확인합니다.", "Man prüft die Nummer auf dem Gepäcketikett.", "You check the number on a luggage label."),
    need=("이 라벨 번호가 제 짐 맞아요?", "Ist diese Etikettnummer mein Gepäck?", "Is this label number my bag?"),
    ask=("끝 네 자리를 불러 주시겠어요?", "Können Sie die letzten vier Zahlen sagen?", "Could you say the last four digits?"),
    wait=("대조는 바로 됩니다.", "Der Abgleich ist gleich fertig.", "The check will finish now."),
    vocab=["라벨", "번호", "짐", "끝자리", "대조", "맞다"],
)
_add(
    "a2_hours_six",
    frame="service",
    rel="customer_and_service_staff",
    sit=("시장 가게가 몇 시까지 여는지 묻습니다.", "Man fragt, bis wann der Marktstand offen ist.", "You ask how late the market stall stays open."),
    need=("오늘 몇 시까지 해요?", "Bis wann haben Sie heute auf?", "Until what time are you open today?"),
    ask=("여섯 시를 목표로 보면 됩니다.", "Rechnen Sie mit achtzehn Uhr.", "Count on six o'clock."),
    wait=("재고가 끝나면 더 일찍 닫습니다.", "Wenn die Ware alle ist, schließen wir früher.", "If stock runs out, we close earlier."),
    vocab=["운영시간", "여섯 시", "오늘", "재고", "닫다", "시장"],
)
_add(
    "a2_seat_hold",
    frame="peer",
    rel="peer",
    sit=("카페에서 자리를 잠시 맡아 달라고 합니다.", "Im Café bittet man, die Plätze kurz zu halten.", "You ask someone to hold seats at a cafe."),
    need=("화장실 가는 동안 이 자리 좀 맡아 줘.", "Halt bitte den Platz, während ich zur Toilette gehe.", "Please hold this seat while I go to the restroom."),
    ask=("가방을 의자에 올려 둘까?", "Soll ich die Tasche auf den Stuhl legen?", "Should I put the bag on the chair?"),
    wait=("오 분이면 돌아올게.", "In fünf Minuten bin ich zurück.", "I'll be back in five minutes."),
    vocab=["자리", "맡다", "가방", "의자", "오 분", "화장실"],
)
_add(
    "a2_water_set",
    frame="home",
    rel="peer",
    sit=("운동 세트 사이에 물을 마십니다.", "Zwischen den Sätzen trinkt man Wasser.", "You drink water between exercise sets."),
    need=("한 세트 끝나고 물 한 모금만 하자.", "Nach einem Satz nur einen Schluck Wasser.", "After one set let's just have a sip of water."),
    ask=("병을 이쪽에 둘까?", "Soll ich die Flasche hierhin stellen?", "Should I put the bottle on this side?"),
    wait=("일 분만 쉬면 다시 하면 돼.", "Eine Minute Pause, dann weiter.", "Rest one minute, then continue."),
    vocab=["세트", "물", "한 모금", "병", "쉬다", "운동"],
)
_add(
    "a2_front_desk",
    frame="service",
    rel="customer_and_service_staff",
    sit=("호텔 안내 데스크에서 아침 식사 시간을 묻습니다.", "An der Rezeption fragt man nach der Frühstückszeit.", "You ask about breakfast hours at the hotel desk."),
    need=("아침 식사는 몇 시부터예요?", "Ab wann gibt es Frühstück?", "What time does breakfast start?"),
    ask=("이 안내문을 보시면 됩니다.", "Schauen Sie auf diesen Aushang.", "Look at this notice."),
    wait=("일곱 시부터 바로 열립니다.", "Ab sieben Uhr ist gleich offen.", "It opens from seven."),
    vocab=["안내 데스크", "아침", "식사", "일곱 시", "안내문", "호텔"],
)
_add(
    "a2_taxi_wait",
    frame="service",
    rel="customer_and_service_staff",
    sit=("택시가 언제 오는지 기사에게 확인합니다.", "Man fragt den Fahrer, wann das Taxi kommt.", "You check with the driver when the taxi will arrive."),
    need=("제가 나오는 데 오 분 걸려요. 기다려 주실 수 있어요?", "Ich brauche fünf Minuten raus. Können Sie warten?", "I need five minutes to come out. Can you wait?"),
    ask=("입구를 말씀해 주시겠어요?", "Können Sie den Eingang nennen?", "Could you tell me the entrance?"),
    wait=("오 분만 기다리겠습니다.", "Ich warte fünf Minuten.", "I'll wait five minutes."),
    vocab=["택시", "기다리다", "오 분", "입구", "나오다", "기사"],
)
_add(
    "a2_airport_sim",
    frame="service",
    rel="customer_and_service_staff",
    sit=("공항에서 유심을 삽니다.", "Am Flughafen kauft man eine Prepaid-Karte.", "You buy a local phone card at the airport."),
    need=("일주일 쓸 유심 하나 주세요.", "Eine Karte für eine Woche, bitte.", "One phone card for a week, please."),
    ask=("여권을 보여 주시겠어요?", "Darf ich den Pass sehen?", "May I see your passport?"),
    wait=("개통은 십 분 안에 됩니다.", "Die Freischaltung dauert zehn Minuten.", "Activation takes ten minutes."),
    vocab=["공항", "유심", "일주일", "여권", "개통", "십 분"],
)
_add(
    "a2_market_change",
    frame="service",
    rel="customer_and_service_staff",
    sit=("시장에서 거스름돈이 맞는지 확인합니다.", "Auf dem Markt prüft man das Wechselgeld.", "You check whether the change is right at the market."),
    need=("만 원 냈는데 거스름이 맞는지 봐 주세요.", "Ich habe zehntausend gegeben. Bitte das Wechselgeld prüfen.", "I paid ten thousand. Please check the change."),
    ask=("이 영수증을 같이 볼까요?", "Sollen wir diesen Bon zusammen ansehen?", "Shall we look at this receipt together?"),
    wait=("차액은 바로 드리겠습니다.", "Die Differenz gebe ich gleich.", "I'll give you the difference now."),
    vocab=["거스름", "만 원", "영수증", "맞다", "차액", "시장"],
)
_add(
    "a2_restaurant_split",
    frame="service",
    rel="peer",
    sit=("식당에서 각자 계산합니다.", "Im Restaurant zahlt jede Person getrennt.", "You split the bill at a restaurant."),
    need=("오늘은 각자 계산할게요.", "Heute zahlt jede Person selbst.", "Today each person will pay separately."),
    ask=("이 접시를 누구 몫으로 넣을까요?", "Auf wen soll dieser Teller gehen?", "Whose share should this plate be?"),
    wait=("계산서는 바로 나눠 드리겠습니다.", "Die Rechnung teile ich gleich auf.", "I'll split the bill now."),
    vocab=["식당", "각자", "계산", "접시", "계산서", "나누다"],
)
_add(
    "a2_direction_bus",
    frame="service",
    rel="stranger",
    sit=("버스 정류장이 어느 쪽인지 묻습니다.", "Man fragt, auf welcher Seite die Haltestelle ist.", "You ask which side the bus stop is on."),
    need=("시청 가는 정류장이 이 쪽 맞아요?", "Ist die Haltestelle zum Rathaus auf dieser Seite?", "Is the stop for city hall on this side?"),
    ask=("건너편을 보시면 됩니다.", "Schauen Sie auf die andere Seite.", "Look across the street."),
    wait=("횡단보도는 바로 앞에 있습니다.", "Der Zebrastreifen ist gleich vorn.", "The crosswalk is right ahead."),
    vocab=["정류장", "시청", "건너편", "횡단보도", "버스", "쪽"],
)
_add(
    "a2_convenience_copy",
    frame="service",
    rel="customer_and_service_staff",
    sit=("편의점에서 서류를 한 장 복사합니다.", "Im Laden kopiert man ein Blatt.", "You copy one page at a convenience store."),
    need=("이 장 한 장만 복사해 주세요.", "Bitte nur dieses eine Blatt kopieren.", "Please copy just this one page."),
    ask=("흑백으로 할까요?", "Soll es schwarz-weiß sein?", "Black and white?"),
    wait=("복사는 일 분이면 됩니다.", "Die Kopie dauert eine Minute.", "The copy takes one minute."),
    vocab=["편의점", "복사", "한 장", "흑백", "일 분", "서류"],
)
_add(
    "a2_cafe_plug",
    frame="service",
    rel="customer_and_service_staff",
    sit=("카페에서 콘센트가 있는 자리를 묻습니다.", "Im Café fragt man nach einem Platz mit Steckdose.", "You ask for a seat with an outlet at a cafe."),
    need=("콘센트 있는 자리 있어요?", "Gibt es einen Platz mit Steckdose?", "Is there a seat with an outlet?"),
    ask=("창가 자리를 쓰시겠어요?", "Möchten Sie den Platz am Fenster?", "Would you like the window seat?"),
    wait=("그 자리는 바로 비었습니다.", "Dieser Platz ist gleich frei.", "That seat is free now."),
    vocab=["카페", "콘센트", "자리", "창가", "비다", "쓰다"],
)
_add(
    "a2_hotel_late",
    frame="service",
    rel="customer_and_service_staff",
    sit=("늦게 도착해서 체크인 시간을 확인합니다.", "Weil man spät ankommt, prüft man die Ankunftszeit.", "You arrive late and check the check-in time."),
    need=("열한 시에 도착할 것 같아요. 그래도 들어가도 돼요?", "Ich komme wohl um dreiundzwanzig Uhr. Kann ich trotzdem rein?", "I'll probably arrive at eleven. Can I still go in?"),
    ask=("문을 야간 벨로 열까요?", "Soll ich die Tür über die Nachtklingel öffnen?", "Should I open the door with the night bell?"),
    wait=("도착하시면 바로 열어 드리겠습니다.", "Wenn Sie da sind, öffne ich gleich.", "When you arrive I'll open right away."),
    vocab=["호텔", "늦게", "도착", "열한 시", "문", "들어가다"],
)
_add(
    "a2_office_badge",
    frame="service",
    rel="coworker",
    sit=("출입증이 안 되어 안내 데스크에 말합니다.", "Der Ausweis geht nicht, deshalb sagt man es am Empfang.", "The office badge does not work, so you tell the desk."),
    need=("출입증이 문을 안 열어요.", "Der Ausweis öffnet die Tür nicht.", "The badge will not open the door."),
    ask=("카드를 여기에 올려 보시겠어요?", "Legen Sie die Karte hier auf?", "Would you put the card here?"),
    wait=("재발급은 십 분 안에 됩니다.", "Die Neuausgabe dauert zehn Minuten.", "A new one takes ten minutes."),
    vocab=["출입증", "문", "카드", "재발급", "십 분", "열다"],
)
_add(
    "a2_station_lost",
    frame="service",
    rel="customer_and_service_staff",
    sit=("역 보관함에 맡긴 짐을 찾습니다.", "Man holt Gepäck von der Bahnhofsaufbewahrung.", "You pick up a bag from the station holding desk."),
    need=("오전에 맡긴 가방을 찾으러 왔어요.", "Ich hole die Tasche vom Vormittag ab.", "I came to pick up the bag I left this morning."),
    ask=("보관 번호를 보여 주시겠어요?", "Können Sie die Aufbewahrungsnummer zeigen?", "Could you show the hold number?"),
    wait=("가방은 바로 드리겠습니다.", "Die Tasche gebe ich gleich.", "I'll give you the bag now."),
    vocab=["보관함", "가방", "오전", "번호", "찾다", "역"],
)
_add(
    "b1_mail_cc",
    frame="coworker",
    rel="coworker",
    sit=("메일에 참조만 넣고 결정은 맡기지 않습니다.", "Man setzt jemanden nur in Kopie und gibt keine Entscheidung ab.", "You add someone as cc only and do not hand over the decision."),
    need=("이 사람은 결정이 아니라 내용만 보면 됩니다.", "Diese Person soll nur den Inhalt sehen, nicht entscheiden.", "This person should only see the content, not decide."),
    ask=("참조 칸에만 넣을까요?", "Nur ins Kopie-Feld?", "Only in the cc field?"),
    wait=("오후에 바로 보내겠습니다.", "Nachmittags sende ich gleich.", "I'll send it in the afternoon."),
    vocab=["참조", "메일", "결정", "내용", "칸", "보내다"],
)
_add(
    "b1_missing_file",
    frame="coworker",
    rel="coworker",
    sit=("보낸 메일에 첨부가 빠졌습니다.", "Im gesendeten Mail fehlt der Anhang.", "The attachment is missing from the sent mail."),
    need=("방금 보낸 메일에 파일이 빠졌어요. 다시 보내 주세요.", "In der gerade gesendeten Mail fehlt die Datei. Bitte noch einmal senden.", "The file is missing from the mail I just sent. Please send it again."),
    ask=("이 파일만 다시 붙일까요?", "Soll ich nur diese Datei noch einmal anhängen?", "Should I attach only this file again?"),
    wait=("오 분 안에 다시 보내겠습니다.", "In fünf Minuten sende ich erneut.", "I'll send it again in five minutes."),
    vocab=["첨부", "파일", "메일", "빠지다", "다시", "보내다"],
)
_add(
    "b1_quiet_exam",
    frame="home",
    rel="neighbor",
    sit=("시험 주에는 밤 소음을 줄여 달라고 합니다.", "In der Prüfungswoche bittet man um weniger Nachtlärm.", "During exam week you ask for less night noise."),
    need=("이번 주는 시험이라 열 시 이후 소음을 줄여 주세요.", "Diese Woche sind Prüfungen. Bitte nach zweiundzwanzig Uhr leiser.", "This week is exams. Please keep it quieter after ten."),
    ask=("이 시간에만 조심하면 될까요?", "Reicht es, nur in dieser Zeit aufzupassen?", "Is it enough to be careful only at that time?"),
    wait=("오늘 밤부터 바로 줄이겠습니다.", "Ab heute Nacht mache ich es gleich leiser.", "I'll keep it down from tonight."),
    vocab=["시험", "소음", "열 시", "이번 주", "밤", "줄이다"],
)
_add(
    "b1_bill_split",
    frame="home",
    rel="peer",
    sit=("이번 달 공과금을 나눠 냅니다.", "Man teilt die Nebenkosten für diesen Monat.", "You split this month's utilities."),
    need=("전기와 인터넷을 반씩 나누고 싶어요.", "Strom und Internet möchte ich halb teilen.", "I want to split electricity and internet in half."),
    ask=("이 금액을 기준으로 할까요?", "Soll dieser Betrag die Basis sein?", "Shall we use this amount as the base?"),
    wait=("내일까지 계산해서 알려 드릴게요.", "Bis morgen rechne ich es aus.", "I'll calculate it by tomorrow."),
    vocab=["공과금", "전기", "인터넷", "반", "금액", "나누다"],
)
_add(
    "b1_claim_same_day",
    frame="service",
    rel="customer_and_service_staff",
    sit=("오늘 생긴 사고를 당일에 접수합니다.", "Man meldet den heutigen Schaden noch am selben Tag.", "You file today's accident on the same day."),
    need=("오늘 자전거가 부러졌어요. 오늘 안에 접수하고 싶어요.", "Heute ist das Fahrrad kaputt. Ich möchte es noch heute melden.", "My bike broke today. I want to file it today."),
    ask=("사진을 지금 올리시겠어요?", "Möchten Sie die Fotos jetzt hochladen?", "Would you upload the photos now?"),
    wait=("접수 번호는 삼십 분 안에 나옵니다.", "Die Meldenummer kommt in dreißig Minuten.", "The claim number comes in thirty minutes."),
    vocab=["사고", "당일", "접수", "사진", "자전거", "번호"],
)
_add(
    "b1_deductible",
    frame="service",
    rel="customer_and_service_staff",
    sit=("보험에서 내가 낼 자기부담금을 확인합니다.", "Man prüft, wie hoch die Selbstbeteiligung ist.", "You check how much of the insurance you pay yourself."),
    need=("이번 수리에서 제가 낼 금액이 얼마예요?", "Wie viel zahle ich selbst bei dieser Reparatur?", "How much do I pay myself for this repair?"),
    ask=("이 칸의 숫자를 같이 볼까요?", "Sollen wir die Zahl in diesem Feld zusammen ansehen?", "Shall we look at the number in this box together?"),
    wait=("금액은 오늘 안에 적어 드리겠습니다.", "Den Betrag schreibe ich Ihnen heute noch auf.", "I'll write the amount today."),
    vocab=["자기부담금", "수리", "금액", "칸", "보험", "숫자"],
)
_add(
    "b1_civil_ticket",
    frame="service",
    rel="customer_and_service_staff",
    sit=("민원실에서 대기번호를 받습니다.", "Im Bürgerbüro holt man eine Wartenummer.", "You take a number at the civil desk."),
    need=("전입 신고하려면 번호를 어디서 뽑아요?", "Wo ziehe ich eine Nummer für die Ummeldung?", "Where do I take a number for the move-in report?"),
    ask=("이 창구 버튼을 누르시면 됩니다.", "Drücken Sie die Taste an diesem Schalter.", "Press the button at this window."),
    wait=("일곱 번만 기다리시면 됩니다.", "Sie warten nur noch sieben Nummern.", "You only wait for seven more numbers."),
    vocab=["민원실", "번호", "전입", "창구", "버튼", "기다리다"],
)
_add(
    "b1_extra_paper",
    frame="service",
    rel="customer_and_service_staff",
    sit=("민원에 빠진 서류를 추가로 냅니다.", "Man reicht die fehlenden Unterlagen nach.", "You submit the missing extra paper for a request."),
    need=("지난번 요청한 서류를 오늘 가져왔어요.", "Die letztens angeforderten Unterlagen habe ich heute dabei.", "I brought the papers you asked for last time today."),
    ask=("이 장만 더 받으면 될까요?", "Reicht dieses eine Blatt noch?", "Is this one more page enough?"),
    wait=("검토는 내일 오전에 끝납니다.", "Die Prüfung ist morgen Vormittag fertig.", "Review finishes tomorrow morning."),
    vocab=["서류", "추가", "지난번", "한 장", "검토", "내일"],
)
_add(
    "b1_volunteer_gap",
    frame="coworker",
    rel="coworker",
    sit=("빠진 봉사 자리를 하루만 메웁니다.", "Man füllt für einen Tag die ausgefallene Ehrenamtsstelle.", "You cover a missing volunteer slot for one day."),
    need=("토요일 오전이 비어서 제가 들어가도 될까요?", "Der Samstagvormittag ist frei. Kann ich einspringen?", "Saturday morning is empty. May I step in?"),
    ask=("이 시간만 맡으면 될까요?", "Reicht es, nur diese Zeit zu übernehmen?", "Is it enough to take only this time?"),
    wait=("명단은 오늘 저녁에 올리겠습니다.", "Die Liste stelle ich heute Abend ein.", "I'll post the list this evening."),
    vocab=["결원", "봉사", "토요일", "오전", "명단", "맡다"],
)
_add(
    "b1_parent_slot",
    frame="service",
    rel="student_and_teacher",
    sit=("선생님과 짧은 면담 시간을 잡습니다.", "Man vereinbart eine kurze Sprechzeit mit der Lehrkraft.", "You book a short meeting slot with a teacher."),
    need=("아이 숙제 때문에 십 분만 이야기하고 싶어요.", "Wegen der Hausaufgaben möchte ich zehn Minuten sprechen.", "I want ten minutes to talk about the homework."),
    ask=("목요일 다섯 시를 드릴까요?", "Darf ich Donnerstag um siebzehn Uhr anbieten?", "Would Thursday at five work?"),
    wait=("시간은 바로 넣어 드리겠습니다.", "Ich trage die Zeit gleich ein.", "I'll put the time in now."),
    vocab=["면담", "숙제", "십 분", "목요일", "다섯 시", "아이"],
)
_add(
    "b1_repair_photo",
    frame="home",
    rel="neighbor",
    sit=("고장난 부분을 사진으로 남겨 수리에 보냅니다.", "Man fotografiert die defekte Stelle für die Reparatur.", "You photograph the broken part for the repair."),
    need=("천장 얼룩을 사진으로 찍어서 보낼게요.", "Ich fotografiere den Fleck an der Decke und sende ihn.", "I'll photograph the ceiling stain and send it."),
    ask=("날짜가 보이게 찍을까요?", "Soll das Datum mit drauf?", "Should I include the date in the photo?"),
    wait=("오후에 바로 전달하겠습니다.", "Nachmittags leite ich es gleich weiter.", "I'll pass it on in the afternoon."),
    vocab=["고장", "사진", "천장", "얼룩", "날짜", "보내다"],
)
_add(
    "b1_return_visit",
    frame="service",
    rel="customer_and_service_staff",
    sit=("수리가 덜 끝나 다시 방문 시간을 잡습니다.", "Die Reparatur ist nicht fertig, deshalb vereinbart man einen Zweitbesuch.", "The repair is unfinished, so you book a return visit."),
    need=("지난번에 못 고친 부분을 다시 봐 주세요.", "Bitte sehen Sie den letzten offenen Teil noch einmal an.", "Please look again at the part that was not fixed last time."),
    ask=("수요일 오전을 넣을까요?", "Soll ich Mittwochvormittag eintragen?", "Should I put in Wednesday morning?"),
    wait=("방문은 내일 확정됩니다.", "Der Besuch steht morgen fest.", "The visit will be confirmed tomorrow."),
    vocab=["재방문", "수리", "지난번", "수요일", "오전", "확정"],
)
_add(
    "b1_typhoon_change",
    frame="service",
    rel="customer_and_service_staff",
    sit=("태풍 때문에 이동 일정을 바꿉니다.", "Wegen eines Taifuns ändert man den Reisetermin.", "A typhoon forces you to change travel plans."),
    need=("태풍이 와서 금요일 기차를 토요일로 옮기고 싶어요.", "Wegen des Taifuns möchte ich den Freitagszug auf Samstag legen.", "Because of the typhoon I want to move Friday's train to Saturday."),
    ask=("토요일 오전 편을 드릴까요?", "Darf ich die Samstagmorgenfahrt anbieten?", "Would the Saturday morning train work?"),
    wait=("변경은 오늘 저녁에 끝납니다.", "Die Änderung ist heute Abend fertig.", "The change finishes this evening."),
    vocab=["태풍", "금요일", "토요일", "기차", "옮기다", "일정"],
)
_add(
    "b1_refund_rule",
    frame="service",
    rel="customer_and_service_staff",
    sit=("취소 환불이 얼마나 되는지 규정을 확인합니다.", "Man prüft, wie viel der Storno erstattet.", "You check how much of a cancellation can be refunded."),
    need=("하루 전에 취소하면 환불이 얼마나 되나요?", "Wie viel gibt es zurück, wenn ich einen Tag vorher storniere?", "How much is refunded if I cancel a day before?"),
    ask=("이 문장을 같이 읽을까요?", "Sollen wir diesen Satz zusammen lesen?", "Shall we read this sentence together?"),
    wait=("금액은 오늘 안에 계산해 드리겠습니다.", "Den Betrag rechne ich Ihnen heute noch aus.", "I'll calculate the amount today."),
    vocab=["환불", "규정", "취소", "하루 전", "문장", "금액"],
)
_add(
    "b1_followup_mail",
    frame="coworker",
    rel="coworker",
    sit=("답이 없는 건에 후속 메일을 보냅니다.", "Auf eine offene Sache sendet man eine Folgmail.", "You send a follow-up mail on an unanswered matter."),
    need=("지난주 요청에 답이 없어서 짧게 다시 묻고 싶어요.", "Auf die Bitte von letzter Woche kam nichts. Ich möchte kurz nachfragen.", "There was no answer to last week's request. I want to ask briefly again."),
    ask=("이 세 줄만 보낼까요?", "Soll ich nur diese drei Zeilen senden?", "Should I send only these three lines?"),
    wait=("오후에 바로 넣겠습니다.", "Nachmittags setze ich sie gleich ab.", "I'll send it in the afternoon."),
    vocab=["후속", "메일", "지난주", "답", "세 줄", "묻다"],
)
_add(
    "b1_guest_notice",
    frame="home",
    rel="neighbor",
    sit=("손님이 온다고 미리 이웃에게 알립니다.", "Man kündigt den Nachbarn vorher an, dass Gäste kommen.", "You tell the neighbor in advance that guests are coming."),
    need=("토요일에 손님이 두 명 와요. 미리 알려 드려요.", "Am Samstag kommen zwei Gäste. Ich sage es vorher.", "Two guests come on Saturday. Just so you know."),
    ask=("주차 자리를 하나 비워 둘까요?", "Soll ich einen Parkplatz frei halten?", "Should I keep one parking space free?"),
    wait=("저녁 전에 다시 연락할게요.", "Vor dem Abend melde ich mich noch einmal.", "I'll contact you again before evening."),
    vocab=["손님", "사전", "토요일", "주차", "두 명", "알리다"],
)
_add(
    "b1_scan_note",
    frame="service",
    rel="customer_and_service_staff",
    sit=("진단서를 스캔해서 보험에 보냅니다.", "Man scannt das Attest für die Versicherung.", "You scan a doctor's note to send to insurance."),
    need=("이 진단서를 파일로 만들어 주세요.", "Bitte machen Sie aus diesem Attest eine Datei.", "Please make this doctor's note into a file."),
    ask=("양쪽을 모두 스캔할까요?", "Soll ich beide Seiten scannen?", "Should I scan both sides?"),
    wait=("파일은 오 분 안에 보내 드리겠습니다.", "Die Datei sende ich in fünf Minuten.", "I'll send the file in five minutes."),
    vocab=["진단서", "스캔", "파일", "양쪽", "보험", "보내다"],
)
_add(
    "b1_proxy_form",
    frame="service",
    rel="customer_and_service_staff",
    sit=("본인이 못 가서 대리 신청서를 냅니다.", "Weil man selbst nicht kann, reicht man einen Vertretungsantrag ein.", "You cannot go in person, so you file a proxy form."),
    need=("제가 못 가서 동생이 대신 신청하게 하고 싶어요.", "Ich kann nicht. Mein jüngeres Geschwister soll stattdessen beantragen.", "I cannot go. I want my younger sibling to apply instead."),
    ask=("위임 칸에 이름을 넣을까요?", "Soll ich den Namen ins Vertretungsfeld setzen?", "Should I put the name in the proxy box?"),
    wait=("접수는 오늘 안에 끝납니다.", "Die Annahme ist heute noch fertig.", "Filing finishes today."),
    vocab=["대리", "신청", "위임", "이름", "동생", "접수"],
)
_add(
    "b1_safety_vest",
    frame="coworker",
    rel="coworker",
    sit=("봉사 조끼 크기가 안 맞아 바꿉니다.", "Die Ehrenamtsweste passt nicht, deshalb tauscht man sie.", "The volunteer vest does not fit, so you change it."),
    need=("이 조끼가 작아서 한 치수 큰 걸로 바꾸고 싶어요.", "Diese Weste ist zu klein. Ich möchte eine Nummer größer.", "This vest is small. I want one size larger."),
    ask=("노란 큰 옷을 드릴까요?", "Soll ich die große Gelbe geben?", "Should I give you the large yellow one?"),
    wait=("조끼는 바로 옆에 있습니다.", "Die Westen liegen gleich daneben.", "The vests are right next to us."),
    vocab=["조끼", "크기", "작다", "노랗다", "바꾸다", "봉사"],
)
_add(
    "b1_school_letter",
    frame="home",
    rel="family",
    sit=("학교에서 온 가정 통신을 같이 읽습니다.", "Man liest den Elternbrief der Schule zusammen.", "You read a school letter together."),
    need=("이 가정 통신에 회신이 필요한지 봐 줘.", "Schau bitte, ob dieser Elternbrief eine Antwort braucht.", "Please check if this school letter needs a reply."),
    ask=("날짜 칸만 먼저 볼까?", "Sollen wir zuerst nur das Datumsfeld ansehen?", "Shall we look at the date box first?"),
    wait=("저녁에 다시 읽고 보내자.", "Am Abend lesen wir noch einmal und senden.", "Let's read again in the evening and send it."),
    vocab=["가정 통신", "학교", "회신", "날짜", "저녁", "읽다"],
)
_add(
    "b1_quote_change",
    frame="service",
    rel="customer_and_service_staff",
    sit=("수리 견적에서 빠진 항목을 고칩니다.", "Man ändert den Kostenvoranschlag um einen fehlenden Posten.", "You change a repair quote to add a missing item."),
    need=("문짝 교체가 빠졌어요. 견적에 넣어 주세요.", "Der Türflügel fehlt. Bitte in den Kostenvoranschlag.", "The door panel is missing. Please add it to the quote."),
    ask=("이 금액을 추가할까요?", "Soll ich diesen Betrag ergänzen?", "Should I add this amount?"),
    wait=("새 견적은 내일 아침에 보내 드리겠습니다.", "Den neuen Voranschlag sende ich morgen früh.", "I'll send the new quote tomorrow morning."),
    vocab=["견적", "문짝", "빠지다", "금액", "추가", "수리"],
)
_add(
    "b1_waitlist",
    frame="service",
    rel="customer_and_service_staff",
    sit=("자리가 없어 대기 명단에 이름을 올립니다.", "Es gibt keinen Platz, deshalb kommt man auf die Warteliste.", "There is no seat, so you put your name on the waitlist."),
    need=("이번 회차는 자리가 없어도 대기하고 싶어요.", "Auch ohne Platz in dieser Runde möchte ich warten.", "Even without a seat this round I want to wait."),
    ask=("전화 번호를 여기에 적을까요?", "Soll ich die Telefonnummer hier eintragen?", "Should I write the phone number here?"),
    wait=("빈자리가 나면 바로 연락드리겠습니다.", "Wenn ein Platz frei wird, melde ich mich gleich.", "If a seat opens I'll contact you right away."),
    vocab=["대기", "명단", "회차", "자리", "전화", "연락"],
)
_add(
    "b1_intranet_form",
    frame="coworker",
    rel="coworker",
    sit=("내부망에서 휴가 양식을 찾습니다.", "Im Intranet sucht man das Urlaubsformular.", "You look for the leave form on the internal network."),
    need=("휴가 양식이 어느 메뉴에 있어요?", "In welchem Menü liegt das Urlaubsformular?", "Which menu has the leave form?"),
    ask=("이 경로를 따라가 볼까요?", "Sollen wir diesem Pfad folgen?", "Shall we follow this path?"),
    wait=("양식은 바로 열립니다.", "Das Formular öffnet sich gleich.", "The form will open now."),
    vocab=["내부망", "양식", "휴가", "메뉴", "경로", "열다"],
)
_add(
    "b1_laundry_turn",
    frame="home",
    rel="neighbor",
    sit=("빨래방 순서가 겹쳐 시간을 바꿉니다.", "Die Waschzeiten überschneiden sich, deshalb ändert man die Reihenfolge.", "Laundry turns overlap, so you change the time."),
    need=("수요일 저녁이 겹쳐서 목요일로 옮기고 싶어요.", "Mittwochabend überschneidet sich. Ich möchte auf Donnerstag.", "Wednesday evening overlaps. I want to move to Thursday."),
    ask=("목요일 일곱 시를 쓸까요?", "Soll ich Donnerstag um neunzehn Uhr nehmen?", "Shall we use Thursday at seven?"),
    wait=("표는 오늘 저녁에 고치겠습니다.", "Den Plan ändere ich heute Abend.", "I'll fix the table this evening."),
    vocab=["빨래", "순서", "수요일", "목요일", "겹치다", "옮기다"],
)
_add(
    "b1_warranty_week",
    frame="service",
    rel="customer_and_service_staff",
    sit=("무상 수리 기간이 얼마나 남았는지 확인합니다.", "Man prüft, wie lange die Garantie noch gilt.", "You check how much warranty time is left."),
    need=("이 선풍기 무상 기간이 이번 주까지인가요?", "Gilt die Garantie für diesen Ventilator nur bis diese Woche?", "Does this fan's free repair period last only through this week?"),
    ask=("구입 날짜를 같이 볼까요?", "Sollen wir das Kaufdatum zusammen ansehen?", "Shall we look at the purchase date together?"),
    wait=("기간은 오늘 안에 확인해 드리겠습니다.", "Die Frist prüfe ich Ihnen heute noch.", "I'll confirm the period today."),
    vocab=["무상", "기간", "선풍기", "구입", "날짜", "이번 주"],
)
_add(
    "b1_connecting",
    frame="service",
    rel="customer_and_service_staff",
    sit=("공항에서 연결편 탑승구를 다시 확인합니다.", "Am Flughafen prüft man das Gate des Anschlusses erneut.", "You check the connecting flight gate again at the airport."),
    need=("다음 편 탑승구가 바뀌었는지 봐 주세요.", "Schauen Sie bitte, ob sich das Gate des Anschlusses geändert hat.", "Please check if the next flight's gate has changed."),
    ask=("이 화면의 번호를 같이 볼까요?", "Sollen wir die Nummer auf diesem Bildschirm zusammen ansehen?", "Shall we look at the number on this screen together?"),
    wait=("이동은 십 분이면 됩니다.", "Der Weg dauert zehn Minuten.", "The walk takes ten minutes."),
    vocab=["연결편", "탑승구", "화면", "번호", "십 분", "바꾸다"],
)
_add(
    "b1_case_status",
    frame="service",
    rel="customer_and_service_staff",
    sit=("민원 번호로 처리 상태를 조회합니다.", "Mit der Vorgangsnummer prüft man den Stand.", "You look up a request's status by case number."),
    need=("이 번호로 지금 어디까지 됐는지 알고 싶어요.", "Mit dieser Nummer möchte ich wissen, wie weit es ist.", "With this number I want to know how far it has gone."),
    ask=("접수일을 한 번 더 확인할까요?", "Soll ich das Annahmedatum noch einmal prüfen?", "Should I check the filing date once more?"),
    wait=("상태는 오 분 안에 나옵니다.", "Der Stand erscheint in fünf Minuten.", "The status will appear in five minutes."),
    vocab=["민원", "번호", "상태", "접수일", "조회", "어디까지"],
)
_add(
    "b1_pickup_delay",
    frame="home",
    rel="family",
    sit=("아이를 늦게 데려가 선생님에게 알립니다.", "Man holt das Kind später ab und sagt es der Lehrkraft.", "You will pick the child up late and tell the teacher."),
    need=("오늘 육 시에 못 가서 육 시 반에 갈게요.", "Heute schaffe ich nicht um achtzehn Uhr, sondern um halb sieben.", "I cannot come at six today. I'll come at six thirty."),
    ask=("교실에서 기다리게 할까요?", "Soll das Kind im Raum warten?", "Should the child wait in the classroom?"),
    wait=("도착하면 바로 전화할게요.", "Wenn ich da bin, rufe ich gleich an.", "When I arrive I'll call right away."),
    vocab=["하원", "늦다", "육 시", "교실", "아이", "전화"],
)
_add(
    "b1_hotel_shift",
    frame="service",
    rel="customer_and_service_staff",
    sit=("숙소 하루를 다음 주로 옮깁니다.", "Man verschiebt eine Übernachtung auf nächste Woche.", "You move one hotel night to next week."),
    need=("금요일 방을 다음 주 월요일로 옮기고 싶어요.", "Ich möchte Freitag auf nächsten Montag legen.", "I want to move Friday's room to next Monday."),
    ask=("월요일 같은 방을 드릴까요?", "Soll ich montags dasselbe Zimmer geben?", "Should I give the same room on Monday?"),
    wait=("변경은 오늘 저녁에 확정됩니다.", "Die Änderung steht heute Abend fest.", "The change will be confirmed this evening."),
    vocab=["숙소", "금요일", "월요일", "방", "옮기다", "다음 주"],
)
_add(
    "b1_taxi_receipt",
    frame="service",
    rel="customer_and_service_staff",
    sit=("회사 정산용 택시 영수증을 받습니다.", "Für die Abrechnung holt man den Taxibeleg.", "You get a taxi receipt for company reimbursement."),
    need=("회사 제출용 영수증 하나 주세요.", "Einen Beleg für die Firma, bitte.", "One receipt for the company, please."),
    ask=("카드 전표를 같이 드릴까요?", "Soll ich den Kartenbeleg dazu geben?", "Should I include the card slip?"),
    wait=("영수증은 바로 출력됩니다.", "Der Beleg wird gleich gedruckt.", "The receipt will print now."),
    vocab=["택시", "영수증", "회사", "카드", "전표", "제출"],
)
_add(
    "b1_market_claim",
    frame="service",
    rel="customer_and_service_staff",
    sit=("시장에서 산 물건이 상해서 교환합니다.", "Die Marktware ist verdorben, deshalb tauscht man sie.", "Market goods went bad, so you exchange them."),
    need=("어제 산 과일이 벌써 상했어요. 바꿔 주세요.", "Das Obst von gestern ist schon verdorben. Bitte umtauschen.", "The fruit I bought yesterday is already bad. Please exchange it."),
    ask=("봉지를 보여 주시겠어요?", "Können Sie die Tüte zeigen?", "Could you show the bag?"),
    wait=("같은 무게로 바로 바꿔 드리겠습니다.", "Ich tausche gleich gegen dasselbe Gewicht.", "I'll exchange it for the same weight now."),
    vocab=["시장", "교환", "과일", "상하다", "봉지", "어제"],
)
_add(
    "b1_cafe_invoice",
    frame="service",
    rel="customer_and_service_staff",
    sit=("카페에서 회사 이름으로 영수증을 받습니다.", "Im Café holt man eine Rechnung auf den Firmennamen.", "You get a cafe receipt in the company name."),
    need=("회사 이름이 들어간 영수증으로 주세요.", "Bitte eine Rechnung mit Firmennamen.", "Please a receipt with the company name."),
    ask=("이 철자를 그대로 넣을까요?", "Soll ich diese Schreibweise so übernehmen?", "Should I put this spelling as is?"),
    wait=("영수증은 바로 다시 뽑아 드리겠습니다.", "Die Rechnung drucke ich gleich neu.", "I'll print the receipt again now."),
    vocab=["카페", "영수증", "회사", "이름", "철자", "뽑다"],
)
_add(
    "b2_review_three",
    frame="coworker",
    rel="coworker",
    sit=("성과를 세 줄로만 적습니다.", "Man schreibt die Leistung in nur drei Zeilen.", "You write the work result in only three lines."),
    need=("길게 쓰지 말고 한 일만 세 줄로 남기고 싶어요.", "Nicht lang. Nur drei Zeilen zu dem, was erledigt ist.", "Do not write long. I want only three lines of what was done."),
    ask=("이 세 문장만 남길까요?", "Soll ich nur diese drei Sätze behalten?", "Should I keep only these three sentences?"),
    wait=("오후에 바로 올려 두겠습니다.", "Nachmittags stelle ich sie gleich ein.", "I'll post them in the afternoon."),
    vocab=["성과", "세 줄", "문장", "한 일", "남기다", "올리다"],
)
_add(
    "b2_self_fail",
    frame="coworker",
    rel="coworker",
    sit=("실패한 시도를 숨기지 않고 짧게 적습니다.", "Einen gescheiterten Versuch schreibt man kurz und offen.", "You write a failed attempt briefly without hiding it."),
    need=("지난 시도가 안 된 이유를 한 줄로 남기고 싶어요.", "Ich will in einer Zeile lassen, warum der letzte Versuch scheiterte.", "I want one line on why the last attempt failed."),
    ask=("이 문장으로 충분할까요?", "Reicht dieser Satz?", "Is this sentence enough?"),
    wait=("기록은 오늘 안에 넣겠습니다.", "Den Eintrag setze ich heute noch.", "I'll put the record in today."),
    vocab=["실패", "시도", "이유", "한 줄", "기록", "남기다"],
)
_add(
    "b2_certified_mail",
    frame="service",
    rel="customer_and_service_staff",
    sit=("내용이 남는 등기로 항의 편지를 보냅니다.", "Man sendet den Widerspruch als Einschreiben mit Inhalt.", "You send a complaint letter as content-certified mail."),
    need=("내용이 기록에 남게 보내고 싶어요.", "Ich möchte senden, sodass der Inhalt dokumentiert bleibt.", "I want to send it so the content stays on record."),
    ask=("이 봉투에 사본을 넣을까요?", "Soll ich eine Kopie in diesen Umschlag legen?", "Should I put a copy in this envelope?"),
    wait=("접수증은 바로 드리겠습니다.", "Die Annahmebestätigung gebe ich gleich.", "I'll give you the receipt now."),
    vocab=["내용증명", "등기", "기록", "봉투", "사본", "접수증"],
)
_add(
    "b2_restore_scope",
    frame="coworker",
    rel="coworker",
    sit=("원상복구가 어디까지인지 범위를 정합니다.", "Man legt fest, wie weit der Rückbau geht.", "You set how far restoration should go."),
    need=("벽만 되돌리고 바닥은 건드리지 않았으면 해요.", "Nur die Wand zurück, den Boden nicht anfassen.", "I want only the wall restored, not the floor."),
    ask=("이 선을 경계로 할까요?", "Soll diese Linie die Grenze sein?", "Shall this line be the boundary?"),
    wait=("범위는 내일 문장으로 보내 드리겠습니다.", "Den Umfang sende ich morgen als Satz.", "I'll send the scope as a sentence tomorrow."),
    vocab=["원상복구", "범위", "벽", "바닥", "선", "경계"],
)
_add(
    "b2_source_check",
    frame="coworker",
    rel="coworker",
    sit=("인용한 숫자가 원문과 같은지 대조합니다.", "Man gleicht die zitierte Zahl mit der Quelle ab.", "You check a cited number against the source."),
    need=("이 숫자가 원문 표와 같은지 확인해 주세요.", "Schauen Sie bitte, ob diese Zahl zur Quelltabelle passt.", "Please check whether this number matches the source table."),
    ask=("이 쪽만 같이 볼까요?", "Sollen wir nur diese Seite zusammen ansehen?", "Shall we look at only this page together?"),
    wait=("대조는 한 시간 안에 끝납니다.", "Der Abgleich ist in einer Stunde fertig.", "The check finishes in an hour."),
    vocab=["원문", "숫자", "표", "쪽", "대조", "인용"],
)
_add(
    "b2_hold_share",
    frame="coworker",
    rel="coworker",
    sit=("확인 전에 자료를 밖에 공유하지 않습니다.", "Vor der Prüfung teilt man die Unterlage nicht nach außen.", "You do not share the material outside before it is checked."),
    need=("이 초안은 아직 밖에 보내지 말아 주세요.", "Diesen Entwurf bitte noch nicht nach außen senden.", "Please do not send this draft outside yet."),
    ask=("내부 폴더에만 둘까요?", "Nur in den internen Ordner?", "Only in the internal folder?"),
    wait=("확인이 끝나면 바로 알려 드리겠습니다.", "Wenn die Prüfung fertig ist, sage ich gleich Bescheid.", "When the check is done I'll tell you right away."),
    vocab=["공유", "보류", "초안", "내부", "폴더", "확인"],
)
_add(
    "b2_agenda_swap",
    frame="coworker",
    rel="coworker",
    sit=("회의 안건 순서를 바꿉니다.", "Man tauscht die Reihenfolge der Tagesordnung.", "You swap the order of meeting items."),
    need=("예산 안건을 맨 앞으로 옮기고 싶어요.", "Den Haushaltspunkt möchte ich ganz nach vorn.", "I want to move the budget item to the front."),
    ask=("이 두 칸만 바꿀까요?", "Soll ich nur diese zwei Felder tauschen?", "Should I swap only these two boxes?"),
    wait=("순서는 오전에 다시 올려 두겠습니다.", "Die Reihenfolge stelle ich vormittags neu ein.", "I'll post the order again in the morning."),
    vocab=["안건", "순서", "예산", "앞", "칸", "바꾸다"],
)
_add(
    "b2_quorum_wait",
    frame="coworker",
    rel="coworker",
    sit=("사람이 모자라 의결을 미룹니다.", "Es fehlen Stimmen, deshalb verschiebt man den Beschluss.", "There are not enough people, so you delay the vote."),
    need=("지금 숫자로는 의결하면 안 될 것 같아요.", "Mit dieser Zahl sollten wir nicht beschließen.", "With this number we should not vote yet."),
    ask=("십 분만 더 기다릴까요?", "Sollen wir noch zehn Minuten warten?", "Shall we wait ten more minutes?"),
    wait=("두 명이 오면 바로 시작하겠습니다.", "Wenn zwei Personen kommen, starte ich gleich.", "When two more people arrive I'll start."),
    vocab=["정족", "의결", "숫자", "십 분", "두 명", "미루다"],
)
_add(
    "b2_must_have",
    frame="coworker",
    rel="coworker",
    sit=("협상에서 빠지면 안 되는 조건만 남깁니다.", "In der Verhandlung behält man nur die Bedingung, die bleiben muss.", "In a negotiation you keep only the condition that cannot drop."),
    need=("날짜는 양보해도 가격 상한은 못 빼요.", "Das Datum kann weichen, die Preisgrenze nicht.", "The date can give, but the price cap cannot."),
    ask=("이 한 줄만 핵심으로 쓸까요?", "Soll nur diese eine Zeile der Kern sein?", "Shall only this one line be the core?"),
    wait=("문장은 오늘 저녁에 보내 드리겠습니다.", "Den Satz sende ich heute Abend.", "I'll send the sentence this evening."),
    vocab=["핵심", "조건", "가격", "상한", "날짜", "양보"],
)
_add(
    "b2_time_box",
    frame="coworker",
    rel="coworker",
    sit=("회의에서 한 안건에 쓸 시간을 미리 정합니다.", "Man setzt vorher fest, wie viel Zeit ein Punkt bekommt.", "You set in advance how much time one item gets."),
    need=("이 안건은 십오 분만 쓰고 다음으로 갔으면 해요.", "Dieser Punkt soll nur fünfzehn Minuten bekommen.", "This item should get only fifteen minutes."),
    ask=("타이머를 지금 켤까요?", "Soll ich den Timer jetzt starten?", "Should I start the timer now?"),
    wait=("시간이 되면 바로 끊겠습니다.", "Wenn die Zeit um ist, breche ich gleich ab.", "When time is up I'll stop."),
    vocab=["시간", "안건", "십오 분", "타이머", "다음", "정하다"],
)
_add(
    "b2_one_pager",
    frame="coworker",
    rel="coworker",
    sit=("긴 보고를 한 장으로 줄입니다.", "Einen langen Bericht kürzt man auf eine Seite.", "You cut a long report down to one page."),
    need=("세 쪽을 한 장으로 줄여서 보내고 싶어요.", "Drei Seiten möchte ich auf eine Seite kürzen und senden.", "I want to cut three pages to one page and send it."),
    ask=("숫자 표만 남길까요?", "Soll nur die Zahlentabelle bleiben?", "Shall only the number table stay?"),
    wait=("한 장은 내일 아침에 올리겠습니다.", "Die eine Seite stelle ich morgen früh ein.", "I'll post the one page tomorrow morning."),
    vocab=["한 장", "요약", "세 쪽", "표", "숫자", "줄이다"],
)
_add(
    "b2_assumption",
    frame="coworker",
    rel="coworker",
    sit=("계산 앞에 가정을 한 줄로 밝힙니다.", "Vor der Rechnung nennt man die Annahme in einer Zeile.", "Before the calculation you state the assumption in one line."),
    need=("인원이 그대로라는 가정을 위에 적어 주세요.", "Bitte oben schreiben, dass die Kopfzahl gleich bleibt.", "Please write at the top that headcount stays the same."),
    ask=("이 문장을 맨 위에 둘까요?", "Soll dieser Satz ganz oben stehen?", "Shall this sentence sit at the very top?"),
    wait=("가정은 오늘 안에 넣어 두겠습니다.", "Die Annahme setze ich heute noch ein.", "I'll put the assumption in today."),
    vocab=["가정", "인원", "문장", "위", "계산", "밝히다"],
)
_add(
    "b2_next_level",
    frame="coworker",
    rel="coworker",
    sit=("여기서 결정할 수 없어 윗사람에게 올립니다.", "Hier kann man nicht entscheiden, deshalb geht es eine Ebene höher.", "You cannot decide here, so you send it to the next level."),
    need=("금액이 제 권한을 넘어서 위로 올려야 해요.", "Der Betrag liegt außerhalb meiner Entscheidungsbefugnis. Ich muss ihn zur Freigabe weiterleiten.", "This amount is beyond my approval authority, so I need to send it up for approval."),
    ask=("이 요약만 첨부할까요?", "Soll ich nur diese Kurzfassung anhängen?", "Should I attach only this summary?"),
    wait=("전달은 오후에 바로 하겠습니다.", "Die Weitergabe mache ich nachmittags gleich.", "I'll pass it on in the afternoon."),
    vocab=["상위", "권한", "금액", "요약", "올리다", "전달"],
)
_add(
    "b2_case_id",
    frame="coworker",
    rel="coworker",
    sit=("사건 번호 없이는 다음으로 넘기지 않습니다.", "Ohne Fallnummer geht es nicht weiter.", "Without a case number, this does not go further."),
    need=("이 건은 번호가 생기기 전에는 공유하지 말아 주세요.", "Bitte nicht teilen, bevor es eine Nummer gibt.", "Please do not share this until there is a number."),
    ask=("임시 번호를 먼저 받을까요?", "Soll ich zuerst eine vorläufige Nummer holen?", "Should I get a temporary number first?"),
    wait=("번호는 한 시간 안에 나옵니다.", "Die Nummer kommt in einer Stunde.", "The number comes in an hour."),
    vocab=["사건", "번호", "공유", "임시", "한 시간", "진행"],
)
_add(
    "b2_limit_line",
    frame="coworker",
    rel="coworker",
    sit=("이 자료로 말할 한계를 한 문장으로 적습니다.", "Man schreibt in einem Satz, was diese Unterlage nicht tragen kann.", "You write in one sentence what this material cannot support."),
    need=("표본이 작아서 전국 수치로 말하면 안 된다고 적어 주세요.", "Bitte schreiben, dass man daraus keine landesweite Zahl machen darf.", "Please write that we must not treat this as a nationwide figure."),
    ask=("이 한계 문장을 각주에 둘까요?", "Soll dieser Grenzsatz in die Fußnote?", "Shall this limitation line go in the footnote?"),
    wait=("문장은 오늘 저녁에 넣겠습니다.", "Den Satz setze ich heute Abend ein.", "I'll put the sentence in this evening."),
    vocab=["한계", "문장", "표본", "전국", "각주", "적다"],
)
_add(
    "b2_chart_axes",
    frame="coworker",
    rel="coworker",
    sit=("도표의 가로축과 세로축이 맞는지 확인합니다.", "Man prüft, ob die Achsen des Diagramms stimmen.", "You check whether the chart axes are right."),
    need=("가로축이 날짜가 맞는지 다시 봐 주세요.", "Bitte noch einmal prüfen, ob die Querachse das Datum ist.", "Please check again whether the horizontal axis is the date."),
    ask=("이 눈금만 고칠까요?", "Soll ich nur diese Skala ändern?", "Should I change only this scale?"),
    wait=("도표는 오전에 다시 올리겠습니다.", "Das Diagramm stelle ich vormittags neu ein.", "I'll post the chart again in the morning."),
    vocab=["도표", "가로축", "세로축", "날짜", "눈금", "고치다"],
)
_add(
    "b2_minutes_draft",
    frame="coworker",
    rel="coworker",
    sit=("회의 기록문 초안에서 결정만 남깁니다.", "Im Protokollentwurf behält man nur die Beschlüsse.", "In the minutes draft you keep only the decisions."),
    need=("이야기는 빼고 결정된 문장만 남겨 주세요.", "Bitte die Gespräche streichen und nur die beschlossenen Sätze lassen.", "Please drop the talk and keep only the decided sentences."),
    ask=("이 네 줄만 남길까요?", "Soll ich nur diese vier Zeilen behalten?", "Should I keep only these four lines?"),
    wait=("초안은 내일 아침에 돌리겠습니다.", "Den Entwurf schicke ich morgen früh herum.", "I'll circulate the draft tomorrow morning."),
    vocab=["회의", "기록문", "결정", "초안", "네 줄", "남기다"],
)
_add(
    "b2_evidence_date",
    frame="coworker",
    rel="coworker",
    sit=("증거 사진에 찍힌 날짜가 맞는지 봅니다.", "Man prüft, ob das Datum auf dem Belegfoto stimmt.", "You check whether the date on the evidence photo is right."),
    need=("이 사진 날짜가 사고 당일이 맞는지 확인해 주세요.", "Schauen Sie bitte, ob das Fotodatum der Schadentag ist.", "Please check whether the photo date is the day of the incident."),
    ask=("파일 정보를 같이 열까요?", "Sollen wir die Dateiinfos zusammen öffnen?", "Shall we open the file info together?"),
    wait=("날짜는 한 시간 안에 적어 두겠습니다.", "Das Datum schreibe ich in einer Stunde auf.", "I'll write the date in an hour."),
    vocab=["증거", "사진", "날짜", "당일", "파일", "확인"],
)
_add(
    "b2_selective_edit",
    frame="coworker",
    rel="coworker",
    sit=("영상에서 일부만 잘라 쓰면 안 된다고 못 박습니다.", "Man hält fest, dass man aus dem Film nicht nur Teile schneiden darf.", "You state that you must not cut the video to show only part."),
    need=("앞부분만 보여 주면 오해가 납니다. 전체를 써야 해요.", "Nur den Anfang zu zeigen führt in die Irre. Wir brauchen das Ganze.", "Showing only the start misleads. We have to use the whole thing."),
    ask=("이 주의 문장을 위에 넣을까요?", "Soll dieser Warnsatz oben stehen?", "Shall this caution sentence go at the top?"),
    wait=("문장은 오늘 안에 넣겠습니다.", "Den Satz setze ich heute noch ein.", "I'll put the sentence in today."),
    vocab=["선택", "편집", "전체", "오해", "주의", "영상"],
)
_add(
    "b2_public_question",
    frame="coworker",
    rel="coworker",
    sit=("공개 질의에 쓸 질문을 한 문장으로 고릅니다.", "Für die öffentliche Nachfrage wählt man einen Satz.", "You pick one sentence for a public question."),
    need=("숫자 근거가 어디 있는지 한 문장으로 묻고 싶어요.", "Ich will in einem Satz fragen, wo die Zahlenherkunft liegt.", "I want one sentence asking where the number comes from."),
    ask=("이 질문으로 올릴까요?", "Soll ich diese Frage einstellen?", "Should I post this question?"),
    wait=("질의는 내일 오전에 공개됩니다.", "Die Nachfrage wird morgen Vormittag öffentlich.", "The question goes public tomorrow morning."),
    vocab=["공개", "질의", "숫자", "근거", "한 문장", "묻다"],
)
_add(
    "b2_counter_offer",
    frame="coworker",
    rel="coworker",
    sit=("거절만 하지 않고 다른 안을 제시합니다.", "Man lehnt nicht nur ab, sondern bietet eine Alternative.", "You do not only refuse; you offer another option."),
    need=("그 날짜는 안 되고, 다음 주 화요일은 됩니다.", "Dieses Datum geht nicht, nächster Dienstag schon.", "That date does not work; next Tuesday does."),
    ask=("이 대안을 첫 줄에 쓸까요?", "Soll diese Alternative in die erste Zeile?", "Shall this alternative go on the first line?"),
    wait=("제안은 오늘 저녁에 보내겠습니다.", "Den Vorschlag sende ich heute Abend.", "I'll send the offer this evening."),
    vocab=["대안", "거절", "화요일", "날짜", "첫 줄", "제안"],
)
_add(
    "b2_metric_clear",
    frame="coworker",
    rel="coworker",
    sit=("성공을 무엇으로 잴지 지표를 하나로 정합니다.", "Man legt eine Messgröße fest, woran Erfolg hängt.", "You set one metric for what counts as success."),
    need=("방문 수가 아니라 완료 건수로 보고 싶어요.", "Nicht Besuchszahlen, sondern erledigte Fälle.", "I want completed cases, not visit counts."),
    ask=("이 이름을 지표로 쓸까요?", "Soll dieser Name die Messgröße sein?", "Shall this name be the metric?"),
    wait=("정의는 내일 오전에 적어 두겠습니다.", "Die Definition schreibe ich morgen früh auf.", "I'll write the definition tomorrow morning."),
    vocab=["지표", "완료", "방문", "이름", "정의", "재다"],
)
_add(
    "b2_on_site",
    frame="coworker",
    rel="coworker",
    sit=("사진만 보지 않고 현장에서 확인합니다.", "Man prüft nicht nur Fotos, sondern vor Ort.", "You do not rely on photos only; you check on site."),
    need=("이 균열은 가서 직접 봐야 할 것 같아요.", "Diesen Riss sollten wir vor Ort selbst sehen.", "This crack we should see ourselves on site."),
    ask=("내일 오전에 갈까요?", "Sollen wir morgen Vormittag hin?", "Shall we go tomorrow morning?"),
    wait=("방문 시간은 오늘 저녁에 잡겠습니다.", "Die Besuchszeit lege ich heute Abend fest.", "I'll set the visit time this evening."),
    vocab=["현장", "균열", "직접", "사진", "방문", "보다"],
)
_add(
    "b2_cross_check",
    frame="coworker",
    rel="coworker",
    sit=("한 출처만 믿지 않고 다른 기록과 맞춰 봅니다.", "Man glaubt nicht einer Quelle, sondern gleicht mit einer zweiten.", "You do not trust one source; you match it against another record."),
    need=("이 출입 기록을 근무표와 맞춰 주세요.", "Bitte diese Zutrittsliste mit dem Dienstplan abgleichen.", "Please match this entry log with the shift table."),
    ask=("이 두 열만 먼저 볼까요?", "Sollen wir zuerst nur diese zwei Spalten ansehen?", "Shall we look at only these two columns first?"),
    wait=("교차 확인은 한 시간 안에 끝납니다.", "Die Gegenprobe ist in einer Stunde fertig.", "The cross-check finishes in an hour."),
    vocab=["교차", "기록", "근무표", "열", "맞추다", "출처"],
)
_add(
    "b2_vacate_short",
    frame="service",
    rel="neighbor",
    sit=("짧은 퇴거 통보가 너무 급하다고 이의를 답니다.", "Gegen eine zu kurze Räumungsfrist legt man Widerspruch ein.", "You object that a short vacate notice is too sudden."),
    need=("일주일은 너무 짧아요. 이주를 미룰 수 있는지 묻고 싶어요.", "Eine Woche ist zu kurz. Ich will fragen, ob der Auszug warten kann.", "One week is too short. I want to ask if the move can wait."),
    ask=("이 날짜를 기준으로 쓸까요?", "Soll ich dieses Datum als Basis nehmen?", "Should I use this date as the base?"),
    wait=("답은 내일 오전에 오겠습니다.", "Die Antwort kommt morgen Vormittag.", "The answer comes tomorrow morning."),
    vocab=["퇴거", "통보", "일주일", "이주", "날짜", "이의"],
)
_add(
    "b2_read_receipt",
    frame="coworker",
    rel="coworker",
    sit=("중요한 안내는 읽음 확인이 켜진 채로 보냅니다.", "Eine wichtige Mitteilung geht mit Lesebestätigung.", "You send an important notice with read receipt on."),
    need=("이 안내는 읽었는지 남게 보내고 싶어요.", "Diese Mitteilung soll hinterlassen, ob sie gelesen wurde.", "I want this notice to leave a record that it was read."),
    ask=("읽음 확인을 켤까요?", "Soll ich die Lesebestätigung einschalten?", "Should I turn on read receipt?"),
    wait=("발송은 오후에 바로 하겠습니다.", "Den Versand mache ich nachmittags gleich.", "I'll send it in the afternoon."),
    vocab=["읽음", "확인", "안내", "발송", "기록", "켜다"],
)
_add(
    "b2_airport_reseat",
    frame="service",
    rel="customer_and_service_staff",
    sit=("연결편 좌석이 갈려 다시 붙여 달라고 합니다.", "Getrennte Anschlussplätze sollen wieder zusammen.", "Split connecting seats should be put back together."),
    need=("아이와 떨어진 좌석을 붙여 주세요.", "Bitte den vom Kind getrennten Sitz wieder daneben.", "Please put the seat next to the child again."),
    ask=("이 두 번호를 바꿀까요?", "Soll ich diese zwei Nummern tauschen?", "Should I swap these two numbers?"),
    wait=("재배정은 삼십 분 안에 나옵니다.", "Die Neuzuweisung kommt in dreißig Minuten.", "The reseat comes in thirty minutes."),
    vocab=["좌석", "재배정", "아이", "번호", "붙이다", "연결편"],
)
_add(
    "b2_hotel_clause",
    frame="service",
    rel="customer_and_service_staff",
    sit=("숙소 계약에서 분쟁 시 어디 법을 쓰는지 확인합니다.", "Im Unterkunftsvertrag prüft man, welches Recht bei Streit gilt.", "You check which rule applies if the hotel stay is disputed."),
    need=("문제가 나면 어느 조항을 보는지 알려 주세요.", "Bitte sagen, welche Klausel bei einem Problem gilt.", "Please tell me which clause applies if there is a problem."),
    ask=("이 문단을 같이 읽을까요?", "Sollen wir diesen Absatz zusammen lesen?", "Shall we read this paragraph together?"),
    wait=("설명은 오늘 안에 적어 드리겠습니다.", "Die Erklärung schreibe ich Ihnen heute noch auf.", "I'll write the explanation today."),
    vocab=["분쟁", "조항", "숙소", "문단", "문제", "읽다"],
)
_add(
    "b2_taxi_escalate",
    frame="service",
    rel="customer_and_service_staff",
    sit=("택시 요금이 이상해서 위에 올립니다.", "Der Taxipreis wirkt falsch, deshalb eskaliert man.", "The taxi fare looks wrong, so you escalate."),
    need=("미터기가 멈춘 채로 요금이 올랐어요. 위에 전해 주세요.", "Das Taxameter zeigte nicht weiter an, aber der Fahrpreis stieg trotzdem. Bitte leiten Sie das an die zuständige Stelle weiter.", "The meter wasn't moving, but the fare kept increasing. Please pass this on to the appropriate person."),
    ask=("주행 경로를 같이 저장할까요?", "Soll ich die Fahrtroute mitspeichern?", "Should I save the route as well?"),
    wait=("접수 번호는 한 시간 안에 나옵니다.", "Die Meldenummer kommt in einer Stunde.", "The case number comes in an hour."),
    vocab=["택시", "요금", "미터기", "경로", "위", "접수"],
)
_add(
    "b2_market_source",
    frame="coworker",
    rel="coworker",
    sit=("시장에서 들은 소문을 사실과 나눕니다.", "Ein Marktgerücht trennt man von der Tatsache.", "You separate a market rumor from the fact."),
    need=("가격이 오른다는 말은 소문이고, 고시 숫자는 그대로예요.", "Dass der Preis steigt, ist Gerücht. Die amtliche Zahl bleibt.", "Talk of a price rise is rumor; the posted number is unchanged."),
    ask=("이 구분을 메모 첫 줄에 쓸까요?", "Soll diese Trennung in die erste Zeile der Notiz?", "Shall this split go on the first line of the note?"),
    wait=("메모는 오후에 돌려 두겠습니다.", "Die Notiz gebe ich nachmittags weiter.", "I'll pass the note in the afternoon."),
    vocab=["소문", "사실", "가격", "고시", "메모", "구분"],
)
_add(
    "b2_cafe_brief",
    frame="coworker",
    rel="coworker",
    sit=("카페에서 짧게 만나 핵심만 맞춥니다.", "Im Café trifft man sich kurz und klärt nur den Kern.", "You meet briefly at a cafe and align only the core."),
    need=("십 분만 만나서 내일 발표 순서만 정하고 싶어요.", "Nur zehn Minuten, nur die Reihenfolge für morgen.", "I want ten minutes only to set tomorrow's presentation order."),
    ask=("이 세 항목만 볼까요?", "Sollen wir nur diese drei Punkte ansehen?", "Shall we look at only these three items?"),
    wait=("순서는 자리에서 바로 적어 두겠습니다.", "Die Reihenfolge schreibe ich gleich am Platz auf.", "I'll write the order at the table now."),
    vocab=["카페", "발표", "순서", "십 분", "세 항목", "정하다"],
)
_add(
    "b2_station_hold",
    frame="coworker",
    rel="coworker",
    sit=("역에서 자료를 더 받기 전에 결정을 보류합니다.", "Am Bahnhof hält man die Entscheidung, bis mehr Unterlagen da sind.", "At the station you hold the decision until more papers arrive."),
    need=("파일이 오기 전에는 이 건을 확정하지 말아 주세요.", "Bitte nichts festlegen, bevor die Datei da ist.", "Please do not confirm this until the file arrives."),
    ask=("보류 표시를 지금 넣을까요?", "Soll ich die Haltemarkierung jetzt setzen?", "Should I put the hold mark now?"),
    wait=("파일이 오면 바로 다시 열겠습니다.", "Wenn die Datei da ist, öffne ich gleich wieder.", "When the file arrives I'll open it again."),
    vocab=["보류", "역", "파일", "확정", "표시", "열다"],
)
_add(
    "b2_pharmacy_claim",
    frame="service",
    rel="customer_and_service_staff",
    sit=("약국 영수증을 보험 청구에 맞게 다시 받습니다.", "Man holt den Apothekenbeleg passend zur Versicherung.", "You get the pharmacy paper again so it fits the insurance claim."),
    need=("약 이름과 날짜가 같이 있는 영수증이 필요해요.", "Ich brauche einen Beleg mit Medikamentenname und Datum.", "I need a receipt with the medicine name and the date."),
    ask=("이 항목을 다시 출력할까요?", "Soll ich diesen Posten neu drucken?", "Should I print this item again?"),
    wait=("서류는 오 분 안에 나옵니다.", "Das Papier ist in fünf Minuten da.", "The paper will be ready in five minutes."),
    vocab=["약국", "영수증", "약", "날짜", "보험", "출력"],
)
_add(
    "b2_restaurant_note",
    frame="service",
    rel="customer_and_service_staff",
    sit=("식당에 알레르기 메모를 남깁니다.", "Im Restaurant hinterlässt man eine Allergienotiz.", "You leave an allergy note at the restaurant."),
    need=("땅콩이 들어가면 안 된다고 메모에 적어 주세요.", "Bitte in die Notiz: kein Erdnuss.", "Please write on the note that peanut must not go in."),
    ask=("이 문장을 주방에 전달할까요?", "Soll ich diesen Satz in die Küche geben?", "Should I pass this sentence to the kitchen?"),
    wait=("메모는 바로 붙이겠습니다.", "Die Notiz hänge ich gleich an.", "I'll put the note up now."),
    vocab=["식당", "메모", "땅콩", "주방", "알레르기", "적다"],
)
_add(
    "b2_direction_risk",
    frame="coworker",
    rel="coworker",
    sit=("우회 길이 위험한지 현장 기준으로 말합니다.", "Man sagt anhand des Orts, ob der Umweg riskant ist.", "You say from the site whether the detour is risky."),
    need=("밤에 그 골목은 어둡고 미끄러워요. 다른 길을 쓰죠.", "Nachts ist die Gasse dunkel und glatt. Lieber einen anderen Weg.", "At night that alley is dark and slippery. Let's use another road."),
    ask=("이 위험을 안내에 넣을까요?", "Soll ich dieses Risiko in den Hinweis?", "Should I put this risk in the notice?"),
    wait=("안내는 오늘 저녁에 고치겠습니다.", "Den Hinweis ändere ich heute Abend.", "I'll fix the notice this evening."),
    vocab=["우회", "위험", "골목", "밤", "어둡다", "안내"],
)
_add(
    "b2_convenience_scan",
    frame="service",
    rel="customer_and_service_staff",
    sit=("편의점에서 서류를 스캔해 메일로 받습니다.", "Im Laden scannt man ein Papier und bekommt es per Mail.", "You scan a paper at the store and receive it by mail."),
    need=("이 장을 스캔해서 제 메일로 보내 주세요.", "Bitte dieses Blatt scannen und an meine Mail senden.", "Please scan this page and send it to my mail."),
    ask=("주소를 여기에 적을까요?", "Soll ich die Adresse hier eintragen?", "Should I write the address here?"),
    wait=("파일은 오 분 안에 갑니다.", "Die Datei geht in fünf Minuten raus.", "The file goes out in five minutes."),
    vocab=["편의점", "스캔", "메일", "한 장", "주소", "보내다"],
)
_add(
    "c1_uncertainty",
    frame="coworker",
    rel="coworker",
    sit=("회의에서 예상 숫자를 한 값이 아니라 구간으로 말합니다.", "In der Lage nennt man die Zahl als Spanne, nicht als einen Wert.", "In the meeting you give the expected number as a range, not one value."),
    need=("삼십에서 사십으로 말해 주세요. 서른다섯이라고 단정하지 말고요.", "Bitte dreißig bis vierzig sagen, nicht fünfunddreißig festlegen.", "Please say thirty to forty, not lock in thirty-five."),
    ask=("이 구간을 첫 슬라이드에 넣을까요?", "Soll diese Spanne auf die erste Folie?", "Shall this range go on the first slide?"),
    wait=("숫자는 오전에 다시 맞춰 두겠습니다.", "Die Zahl gleiche ich vormittags noch einmal ab.", "I'll match the number again in the morning."),
    vocab=["구간", "예상", "숫자", "단정", "슬라이드", "맞추다"],
)
_add(
    "c1_sample_bias",
    frame="coworker",
    rel="coworker",
    sit=("설문이 젊은 사람만 모아서 전체가 아니라고 밝힙니다.", "Die Umfrage hat vor allem Jüngere, deshalb ist sie nicht die Gesamtheit.", "The survey mostly reached younger people, so it is not the whole group."),
    need=("이 결과는 이십 대 응답이 많아서 전체를 대표하지 않아요.", "Dieses Ergebnis hat zu viele Antworten aus den Zwanzigern. Es steht nicht für alle.", "This result has too many answers from people in their twenties. It does not stand for everyone."),
    ask=("이 한계를 표 아래에 쓸까요?", "Soll diese Grenze unter die Tabelle?", "Shall this limit go under the table?"),
    wait=("문장은 오늘 저녁에 넣겠습니다.", "Den Satz setze ich heute Abend ein.", "I'll put the sentence in this evening."),
    vocab=["표본", "설문", "이십 대", "전체", "표", "한계"],
)
_add(
    "c1_briefing_number",
    frame="coworker",
    rel="coworker",
    sit=("브리핑에 넣을 숫자를 하나 고르고 나머지는 빼습니다.", "Für die Lage wählt man eine Zahl und lässt die anderen weg.", "You pick one number for the briefing and drop the rest."),
    need=("오늘은 대기 시간만 말하고 방문자 수는 빼 주세요.", "Heute nur die Wartezeit, nicht die Besucherzahl.", "Today say only wait time, not visitor count."),
    ask=("이 숫자만 크게 넣을까요?", "Soll nur diese Zahl groß stehen?", "Shall only this number sit large?"),
    wait=("슬라이드는 오전에 고치겠습니다.", "Die Folie ändere ich vormittags.", "I'll fix the slide in the morning."),
    vocab=["브리핑", "숫자", "대기 시간", "방문자", "슬라이드", "빼다"],
)
_add(
    "c1_question_window",
    frame="coworker",
    rel="coworker",
    sit=("설명 뒤에 질의 시간을 언제 열지 정합니다.", "Man legt fest, wann nach der Erklärung Fragen möglich sind.", "You set when questions open after the explanation."),
    need=("설명 십 분이 끝난 뒤에만 질문을 받고 싶어요.", "Fragen erst nach zehn Minuten Erklärung.", "I want questions only after ten minutes of explanation."),
    ask=("이 순서를 안내에 적을까요?", "Soll ich diese Reihenfolge in den Hinweis?", "Should I write this order in the notice?"),
    wait=("안내는 오늘 저녁에 올리겠습니다.", "Den Hinweis stelle ich heute Abend ein.", "I'll post the notice this evening."),
    vocab=["질의", "시간", "설명", "십 분", "순서", "안내"],
)
_add(
    "c1_leading_item",
    frame="coworker",
    rel="coworker",
    sit=("설문 문항이 답을 밀어 넣는지 고칩니다.", "Man ändert eine Frage, die die Antwort schon lenkt.", "You fix a survey item that pushes the answer."),
    need=("‘당연히 찬성하시죠’는 답을 유도해요. 중립으로 바꿔 주세요.", "„Sie sind doch dafür“ lenkt. Bitte neutral machen.", "“You agree, of course” pushes the answer. Please make it neutral."),
    ask=("이 문장으로 바꿀까요?", "Soll ich auf diesen Satz wechseln?", "Should I change it to this sentence?"),
    wait=("문항은 내일 아침에 다시 돌리겠습니다.", "Die Frage schicke ich morgen früh neu herum.", "I'll circulate the item again tomorrow morning."),
    vocab=["문항", "유도", "중립", "설문", "답", "바꾸다"],
)
_add(
    "c1_relative_risk",
    frame="coworker",
    rel="coworker",
    sit=("상대 위험만 말하지 않고 실제 숫자도 같이 적습니다.", "Man nennt nicht nur das relative Risiko, sondern auch die echte Zahl.", "You do not give relative risk alone; you add the actual number."),
    need=("두 배로 늘었다는 말 옆에 열 명에서 스무 명이라고 써 주세요.", "Neben „doppelt so viel“ bitte zehn auf zwanzig schreiben.", "Next to “it doubled,” please write ten people to twenty."),
    ask=("이 두 숫자를 같은 줄에 둘까요?", "Soll ich diese zwei Zahlen in dieselbe Zeile?", "Should I put these two numbers on the same line?"),
    wait=("표는 오전에 고치겠습니다.", "Die Tabelle ändere ich vormittags.", "I'll fix the table in the morning."),
    vocab=["상대 위험", "두 배", "열 명", "스무 명", "표", "숫자"],
)
_add(
    "c1_access_time",
    frame="coworker",
    rel="coworker",
    sit=("자료에 닿는 데 시간이 더 걸린다고 미리 말합니다.", "Man sagt vorher, dass der Zugang zur Unterlage länger dauert.", "You say in advance that reaching the material takes more time."),
    need=("이 폴더는 권한이 없어서 하루가 더 걸려요.", "Dieser Ordner braucht eine Freigabe, deshalb einen Tag mehr.", "This folder needs permission, so it takes one more day."),
    ask=("이 지연을 일정에 넣을까요?", "Soll ich diese Verzögerung in den Plan?", "Should I put this delay on the schedule?"),
    wait=("권한은 내일 오전에 요청하겠습니다.", "Die Freigabe beantrage ich morgen Vormittag.", "I'll request access tomorrow morning."),
    vocab=["접근", "권한", "폴더", "하루", "지연", "일정"],
)
_add(
    "c1_speaking_slot",
    frame="coworker",
    rel="coworker",
    sit=("발언 시간을 사람마다 나눠 한 사람이 독점하지 않게 합니다.", "Man teilt die Redezeit, damit nicht eine Person alles nimmt.", "You split speaking time so one person does not take it all."),
    need=("한 사람은 삼 분으로 맞춰 주세요. 같은 사람이 두 번 말하지 말고요.", "Bitte drei Minuten pro Person. Dieselbe Person nicht zweimal.", "Please three minutes per person. The same person should not speak twice."),
    ask=("이 순서를 칠판에 적을까요?", "Soll ich diese Reihenfolge an die Tafel?", "Should I write this order on the board?"),
    wait=("순서는 시작 전에 바로 붙이겠습니다.", "Die Reihenfolge hänge ich gleich vor Beginn an.", "I'll put the order up right before we start."),
    vocab=["발언", "삼 분", "순서", "칠판", "한 사람", "나누다"],
)
_add(
    "c2_discourse_premise",
    frame="coworker",
    rel="coworker",
    sit=("회의 전에 우리가 이미 받아들인 전제를 말로 꺼냅니다.", "Vor der Sitzung spricht man die schon übernommene Prämisse aus.", "Before the meeting you say out loud the premise already taken as given."),
    need=("비용을 줄인다는 전제가 이미 들어가 있어요. 그걸 먼저 말해야 해요.", "Die Prämisse „Kosten senken“ steckt schon drin. Die müssen wir zuerst sagen.", "The premise “cut costs” is already in. We have to say that first."),
    ask=("이 전제를 안건 위에 둘까요?", "Soll diese Prämisse über den Punkt?", "Shall this premise sit above the item?"),
    wait=("문장은 시작 전에 올려 두겠습니다.", "Den Satz stelle ich vor Beginn ein.", "I'll post the sentence before we start."),
    vocab=["전제", "비용", "안건", "회의", "먼저", "말하다"],
)
_add(
    "c2_passive_hide",
    frame="coworker",
    rel="coworker",
    sit=("수동태 문장이 누가 했는지 숨기는지 고칩니다.", "Man ändert einen Passivsatz, der verbirgt, wer handelte.", "You fix a passive sentence that hides who did it."),
    need=("‘실수가 발생했다’는 누가 했는지 안 보여요. 주어를 밝혀 주세요.", "„Ein Fehler entstand“ zeigt nicht, wer handelte. Bitte das Subjekt nennen.", "“A mistake occurred” does not show who acted. Please name the subject."),
    ask=("이 능동 문장으로 바꿀까요?", "Soll ich auf diesen Aktivsatz wechseln?", "Should I change it to this active sentence?"),
    wait=("기록은 오늘 저녁에 고치겠습니다.", "Den Eintrag ändere ich heute Abend.", "I'll fix the record this evening."),
    vocab=["수동", "주어", "실수", "능동", "기록", "밝히다"],
)
_add(
    "c2_mandate_edge",
    frame="coworker",
    rel="coworker",
    sit=("요청이 위임 밖인지 경계를 확인합니다.", "Man prüft, ob die Bitte außerhalb der Zuständigkeit liegt.", "You check whether the request sits outside the speaker's authority."),
    need=("가격을 정하는 일은 제 위임 밖이에요. 위로 가야 합니다.", "Die Entscheidung über den Preis liegt außerhalb meiner Zuständigkeit und muss auf der nächsthöheren Ebene getroffen werden.", "The pricing decision falls outside my authority and has to be made at the next decision-making level."),
    ask=("이 경계를 회신 첫 줄에 쓸까요?", "Soll diese Grenze in die erste Zeile der Antwort?", "Shall this boundary go on the first line of the reply?"),
    wait=("회신은 오후에 보내겠습니다.", "Die Antwort sende ich nachmittags.", "I'll send the reply in the afternoon."),
    vocab=["위임", "경계", "가격", "회신", "위", "밖"],
)
_add(
    "c2_archive_gap",
    frame="coworker",
    rel="coworker",
    sit=("기록에서 빠진 달을 공백으로 표시합니다.", "Einen fehlenden Monat im Archiv markiert man als Lücke.", "You mark a missing month in the archive as a gap."),
    need=("삼 월 기록이 없습니다. 있다고 채우지 말고 공백이라고 쓰세요.", "Der März fehlt. Nicht füllen, sondern als Lücke schreiben.", "March is missing. Do not fill it in; write that it is a gap."),
    ask=("이 칸을 비움으로 표시할까요?", "Soll ich dieses Feld als leer markieren?", "Should I mark this box as empty?"),
    wait=("표시는 오늘 안에 넣겠습니다.", "Die Markierung setze ich heute noch.", "I'll put the mark in today."),
    vocab=["기록", "공백", "삼 월", "칸", "채우다", "표시"],
)
_add(
    "c2_appeal_bot",
    frame="service",
    rel="customer_and_service_staff",
    sit=("챗봇이 이의를 받아 주지 않아 사람 창구를 요청합니다.", "Der Chatbot nimmt den Einspruch nicht, deshalb verlangt man einen Menschen.", "The chatbot will not take the appeal, so you ask for a human desk."),
    need=("자동 답만 오고 이의가 안 들어가요. 사람 창구로 연결해 주세요.", "Nur Automatik, der Einspruch geht nicht. Bitte zu einem Menschen.", "I only get automatic replies and the appeal will not go in. Please connect me to a person."),
    ask=("이 접수 번호를 넘길까요?", "Soll ich diese Annahmenummer weitergeben?", "Should I pass this filing number?"),
    wait=("사람 창구는 삼십 분 안에 연결됩니다.", "Der menschliche Schalter verbindet in dreißig Minuten.", "A person will be connected in thirty minutes."),
    vocab=["챗봇", "이의", "자동", "창구", "사람", "연결"],
)
_add(
    "c2_trace_log",
    frame="coworker",
    rel="coworker",
    sit=("자동 결정이 어떤 기록을 남겼는지 추적 로그를 요청합니다.", "Man verlangt das Prüfprotokoll, welche Spur die Automatik hinterließ.", "You ask for the trace log of what an automated decision left behind."),
    need=("이 거절이 어떤 규칙을 썼는지 로그를 보여 주세요.", "Bitte das Protokoll, welche Regel diese Ablehnung nutzte.", "Please show the log of which rule this refusal used."),
    ask=("이 시간대만 먼저 열까요?", "Soll ich zuerst nur dieses Zeitfenster öffnen?", "Should I open only this time window first?"),
    wait=("로그는 한 시간 안에 받겠습니다.", "Das Protokoll habe ich in einer Stunde.", "I'll have the log in an hour."),
    vocab=["추적", "로그", "거절", "규칙", "시간대", "자동"],
)
_add(
    "c2_withdraw_deep",
    frame="coworker",
    rel="coworker",
    sit=("철회 버튼이 화면 깊숙이 숨어 위치를 바꿉니다.", "Der Widerrufknopf sitzt zu tief, deshalb ändert man den Ort.", "The withdraw button is buried too deep, so you change its place."),
    need=("철회가 네 번을 눌러야 나와요. 첫 화면으로 올려 주세요.", "Der Widerruf braucht vier Klicks. Bitte auf die erste Ansicht.", "Withdraw takes four taps. Please move it to the first screen."),
    ask=("이 자리를 첫 줄로 옮길까요?", "Soll ich diesen Platz in die erste Zeile legen?", "Should I move this spot to the first line?"),
    wait=("위치는 내일 오전에 바뀝니다.", "Der Ort ändert sich morgen Vormittag.", "The place changes tomorrow morning."),
    vocab=["철회", "화면", "네 번", "첫 줄", "숨다", "올리다"],
)
_add(
    "c2_uneven_impact",
    frame="coworker",
    rel="coworker",
    sit=("같은 규칙이 집단마다 다르게 닿는지 숫자를 나눠 봅니다.", "Man teilt die Zahlen, ob dieselbe Regel Gruppen verschieden trifft.", "You split the numbers to see if the same rule hits groups differently."),
    need=("전체 평균만 보지 말고 나이대별로 나눠 주세요.", "Nicht nur den Gesamtschnitt, bitte nach Altersgruppen teilen.", "Do not look only at the overall average; please split by age group."),
    ask=("이 세 집단을 표에 넣을까요?", "Soll ich diese drei Gruppen in die Tabelle?", "Should I put these three groups in the table?"),
    wait=("표는 내일 아침에 올리겠습니다.", "Die Tabelle stelle ich morgen früh ein.", "I'll post the table tomorrow morning."),
    vocab=["차등", "평균", "나이대", "집단", "표", "나누다"],
)


_missing_beats = sorted(set(SEEDS) - set(BEATS))
_extra_beats = sorted(set(BEATS) - set(SEEDS))
if _missing_beats or _extra_beats:
    raise SystemExit(
        f"beat coverage mismatch missing={_missing_beats} extra={_extra_beats}"
    )
