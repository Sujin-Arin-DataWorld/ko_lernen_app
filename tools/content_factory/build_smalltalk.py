#!/usr/bin/env python3
"""Content factory (c) — 스몰토크/회화 주제 코퍼스 (카테고리 × 레벨).

독일어권 학습자용 한국어 스몰토크. 직접 작성한 정확 한/독/영.
레벨 기준:
  A1 한 문장·현재형·기본어휘 · A2 미래/과거+간단질문 ·
  B1 복문+완곡어법(혹시/-는데) · B2 뉘앙스·관용·의견(-더라고요).
출력: assets/data/smalltalk.json (assets/data/ 는 pubspec에서 이미 번들됨).
실행:  python3 tools/content_factory/build_smalltalk.py --write
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets/data/smalltalk.json")

# (id, emoji, ko-label, de-label, en-label)
CATS = [
    ("weather", "☀️", "날씨·계절", "Wetter & Jahreszeit", "Weather & season"),
    ("mood", "🙂", "기분·컨디션", "Stimmung & Befinden", "Mood & how you feel"),
    ("weekend", "📅", "주말·계획", "Wochenende & Pläne", "Weekend & plans"),
    ("food", "🍽️", "음식·맛집", "Essen & Restaurants", "Food & eating out"),
    ("daily", "☕", "일상·근황", "Alltag & Neues", "Daily life & catching up"),
    ("screen", "🎬", "영화·드라마·OTT", "Filme, Serien & Streaming", "Movies, series & streaming"),
    ("music", "🎵", "음악", "Musik", "Music"),
    ("hobby", "🎨", "취미·여가", "Hobbys & Freizeit", "Hobbies & free time"),
    ("travel", "✈️", "여행", "Reisen", "Travel"),
    ("work_study", "💼", "일·공부", "Arbeit & Lernen", "Work & study"),
    ("family", "👨‍👩‍👧", "가족·사람", "Familie & Menschen", "Family & people"),
    ("health", "💪", "운동·건강", "Sport & Gesundheit", "Exercise & health"),
]

# (category, level, kind, ko, de, en)   kind: opener | question | reaction
P = [
    # ── weather ──
    ("weather", "a1", "opener", "날씨 좋네요.", "Schönes Wetter, oder?", "Nice weather, huh?"),
    ("weather", "a1", "opener", "오늘 좀 덥네요.", "Heute ist es etwas heiß.", "It's a bit hot today."),
    ("weather", "a2", "question", "주말에 날씨 좋을까요?", "Ob das Wetter am Wochenende gut wird?", "Will the weather be nice this weekend?"),
    ("weather", "b1", "opener", "이런 날씨엔 산책하기 딱 좋죠.", "Bei so einem Wetter geht man perfekt spazieren.", "This kind of weather is perfect for a walk."),
    ("weather", "b2", "opener", "요즘 일교차가 커서 감기 걸리기 쉽더라고요.", "Die Temperaturunterschiede sind gerade groß — da erkältet man sich leicht.", "The temperature swings lately make it easy to catch a cold."),
    # ── mood ──
    ("mood", "a1", "opener", "오늘 기분 좋아요.", "Mir geht's heute gut.", "I'm in a good mood today."),
    ("mood", "a2", "opener", "요즘 좀 피곤해요.", "In letzter Zeit bin ich etwas müde.", "I've been a bit tired lately."),
    ("mood", "b1", "question", "오늘 하루 어떠셨어요?", "Wie war Ihr Tag heute?", "How was your day today?"),
    ("mood", "b2", "opener", "요즘 정신없이 바빠서 시간이 어떻게 가는지 모르겠어요.", "Ich bin gerade so im Stress, dass ich gar nicht merke, wie die Zeit vergeht.", "I'm so busy lately I don't even notice time passing."),
    # ── weekend ──
    ("weekend", "a1", "question", "주말에 뭐 해요?", "Was machst du am Wochenende?", "What do you do on weekends?"),
    ("weekend", "a2", "question", "이번 주말에 뭐 할 거예요?", "Was machst du dieses Wochenende?", "What are you doing this weekend?"),
    ("weekend", "b1", "question", "보통 쉬는 날엔 어떻게 시간 보내세요?", "Wie verbringen Sie normalerweise Ihre freien Tage?", "How do you usually spend your days off?"),
    ("weekend", "b2", "question", "주말에 별 계획 없으면 같이 바람이나 쐬러 갈까요?", "Wenn Sie am Wochenende nichts vorhaben, sollen wir mal zusammen rauskommen?", "If you have no plans this weekend, shall we go out for some fresh air?"),
    # ── food ──
    ("food", "a1", "reaction", "이거 진짜 맛있어요.", "Das ist echt lecker.", "This is really delicious."),
    ("food", "a2", "question", "점심 뭐 먹었어요?", "Was hast du zu Mittag gegessen?", "What did you have for lunch?"),
    ("food", "b1", "question", "요즘 맛있게 먹은 음식 있어요?", "Gab's in letzter Zeit etwas richtig Leckeres?", "Have you had anything really good to eat lately?"),
    ("food", "b2", "opener", "가보고 싶은 맛집 있으면 다음에 같이 가요.", "Wenn Sie ein Lokal ausprobieren möchten, gehen wir mal zusammen.", "If there's a place you want to try, let's go together sometime."),
    # ── daily ──
    ("daily", "a1", "question", "커피 마셨어요?", "Hast du schon Kaffee getrunken?", "Have you had coffee?"),
    ("daily", "a2", "opener", "오늘 아침에 일찍 일어났어요.", "Ich bin heute früh aufgestanden.", "I got up early this morning."),
    ("daily", "b1", "opener", "아침에 마신 커피가 맛있어서 하루 시작이 좋네요.", "Der Kaffee heute Morgen war so gut — ein schöner Start in den Tag.", "The coffee this morning was great, so it's a nice start to the day."),
    ("daily", "b2", "opener", "요즘 출근길이 너무 막혀서 평소보다 일찍 나서게 되더라고요.", "Der Weg zur Arbeit ist gerade so verstopft, dass ich früher losgehe als sonst.", "The commute's so jammed lately that I end up leaving earlier than usual."),
    # ── screen ──
    ("screen", "a1", "reaction", "그 드라마 재미있어요.", "Die Serie ist gut.", "That drama is fun."),
    ("screen", "a2", "question", "요즘 무슨 드라마 봐요?", "Welche Serie schaust du gerade?", "What drama are you watching these days?"),
    ("screen", "b1", "question", "넷플릭스에 볼 만한 거 있어요?", "Gibt's auf Netflix etwas Sehenswertes?", "Is there anything worth watching on Netflix?"),
    ("screen", "b2", "question", "요즘 통 볼 만한 게 없던데, 혹시 추천해 줄 거 있어요?", "In letzter Zeit gibt's kaum etwas Gutes — hast du vielleicht eine Empfehlung?", "There's been nothing good to watch lately — got any recommendations?"),
    # ── music ──
    ("music", "a1", "reaction", "이 노래 좋아요.", "Das Lied ist schön.", "I like this song."),
    ("music", "a2", "question", "무슨 음악 좋아해요?", "Welche Musik magst du?", "What music do you like?"),
    ("music", "b1", "question", "즐겨 듣는 음악 장르가 있으세요?", "Haben Sie ein Lieblingsgenre bei Musik?", "Do you have a favorite music genre?"),
    ("music", "b2", "opener", "일할 때 음악을 들으면 집중이 더 잘 되는 편이에요.", "Mit Musik beim Arbeiten kann ich mich eher besser konzentrieren.", "I tend to focus better when I listen to music while working."),
    # ── hobby ──
    ("hobby", "a1", "question", "취미가 뭐예요?", "Was ist dein Hobby?", "What's your hobby?"),
    ("hobby", "a2", "question", "시간 있을 때 보통 뭐 해요?", "Was machst du normalerweise in deiner Freizeit?", "What do you usually do in your free time?"),
    ("hobby", "b1", "question", "퇴근 후엔 주로 뭐 하면서 쉬세요?", "Womit entspannen Sie sich meist nach der Arbeit?", "What do you usually do to relax after work?"),
    ("hobby", "b2", "question", "스트레스 받을 때 푸는 본인만의 방법이 있으세요?", "Haben Sie eine eigene Methode, um Stress abzubauen?", "Do you have your own way of relieving stress?"),
    # ── travel ──
    ("travel", "a1", "opener", "저는 여행을 좋아해요.", "Ich reise gern.", "I like traveling."),
    ("travel", "a2", "question", "어디로 여행 가고 싶어요?", "Wohin möchtest du reisen?", "Where do you want to travel?"),
    ("travel", "b1", "question", "가장 기억에 남는 여행지가 어디예요?", "Welches Reiseziel ist Ihnen am meisten in Erinnerung geblieben?", "What's your most memorable travel destination?"),
    ("travel", "b2", "opener", "나중에 시간 되면 꼭 한번 가보고 싶은 나라가 있어요.", "Es gibt ein Land, das ich später unbedingt einmal besuchen möchte.", "There's a country I really want to visit someday."),
    # ── work_study ──
    ("work_study", "a1", "question", "일 많아요?", "Hast du viel zu tun?", "Are you busy with work?"),
    ("work_study", "a2", "question", "요즘 무슨 일 해요?", "Was machst du gerade beruflich?", "What kind of work do you do these days?"),
    ("work_study", "b1", "question", "일하면서 가장 보람 있을 때가 언제예요?", "Wann ist Ihre Arbeit am erfüllendsten?", "When do you find your work most rewarding?"),
    ("work_study", "b2", "opener", "요즘 일이 몰려서 좀 정신없는데, 그래도 배우는 게 많아요.", "Gerade häuft sich die Arbeit und es ist hektisch, aber ich lerne viel dabei.", "Work's been piling up and it's hectic, but I'm learning a lot."),
    # ── family ──
    ("family", "a1", "question", "가족이 많아요?", "Hast du eine große Familie?", "Do you have a big family?"),
    ("family", "a2", "question", "주말에 가족이랑 뭐 해요?", "Was machst du am Wochenende mit der Familie?", "What do you do with your family on weekends?"),
    ("family", "b1", "question", "가족이랑 자주 연락하는 편이세요?", "Haben Sie oft Kontakt zu Ihrer Familie?", "Do you keep in touch with your family often?"),
    ("family", "b2", "opener", "멀리 떨어져 살다 보니 가족이 더 소중하게 느껴지더라고요.", "Seit ich weit weg wohne, ist mir die Familie noch wichtiger geworden.", "Living far away has made me appreciate family even more."),
    # ── health ──
    ("health", "a1", "question", "운동 좋아해요?", "Treibst du gern Sport?", "Do you like exercising?"),
    ("health", "a2", "question", "보통 무슨 운동 해요?", "Welchen Sport machst du normalerweise?", "What sport do you usually do?"),
    ("health", "b1", "question", "건강을 위해 따로 하는 운동 있으세요?", "Machen Sie etwas Bestimmtes für Ihre Gesundheit?", "Do you do anything specific for your health?"),
    ("health", "b2", "opener", "요즘 운동을 시작했는데, 확실히 컨디션이 좋아진 것 같아요.", "Ich hab neulich mit Sport angefangen — ich fühle mich deutlich fitter.", "I started working out recently and I definitely feel in better shape."),
]

LEVELS = {"a1", "a2", "b1", "b2"}
KINDS = {"opener", "question", "reaction"}


def main():
    write = "--write" in sys.argv
    cat_ids = {c[0] for c in CATS}
    errs = []
    seen = set()
    for (cat, lvl, kind, ko, de, en) in P:
        if cat not in cat_ids:
            errs.append(f"unknown category {cat}")
        if lvl not in LEVELS:
            errs.append(f"bad level {lvl} ({ko})")
        if kind not in KINDS:
            errs.append(f"bad kind {kind} ({ko})")
        if not (ko and de and en):
            errs.append(f"empty field ({ko})")
        if ko in seen:
            errs.append(f"duplicate ko ({ko})")
        seen.add(ko)
    if errs:
        for e in errs:
            print("✗", e)
        sys.exit(1)

    data = {
        "version": 1,
        "_comment": "Small-talk corpus by category x level. Built by tools/content_factory/build_smalltalk.py. Native review recommended before launch.",
        "categories": [
            {"id": c[0], "emoji": c[1],
             "label": {"ko": c[2], "de": c[3], "en": c[4]}}
            for c in CATS
        ],
        "phrases": [
            {"category": cat, "level": lvl, "kind": kind,
             "ko": ko, "de": de, "en": en}
            for (cat, lvl, kind, ko, de, en) in P
        ],
    }

    # 요약
    from collections import Counter
    bylvl = Counter(p["level"] for p in data["phrases"])
    print(f"카테고리 {len(CATS)} · 문장 {len(P)} · 레벨별 {dict(sorted(bylvl.items()))}")

    if write:
        with open(OUT, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        print("✓ 저장:", OUT)
    else:
        print("(dry-run — --write 로 저장)")


if __name__ == "__main__":
    main()
