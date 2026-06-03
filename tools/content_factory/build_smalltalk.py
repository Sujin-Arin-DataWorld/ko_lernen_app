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
    ("kpop", "🎤", "K-pop·아이돌", "K-Pop & Idols", "K-pop & idols"),
    ("dating", "💕", "연애·썸", "Dating & Beziehung", "Dating & relationships"),
    ("interview", "🧑‍💼", "면접", "Vorstellungsgespräch", "Job interviews"),
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

    # ── Erweiterung (batch 1): +4 pro Kategorie ──
    ("weather", "a1", "opener", "비가 와요.", "Es regnet.", "It's raining."),
    ("weather", "a2", "question", "우산 가져왔어요?", "Hast du einen Schirm dabei?", "Did you bring an umbrella?"),
    ("weather", "b1", "opener", "날씨가 점점 추워지네요.", "Es wird allmählich kälter.", "It's gradually getting colder."),
    ("weather", "b2", "opener", "미세먼지가 심한 날엔 마스크를 챙기게 되더라고요.", "An Tagen mit viel Feinstaub nehme ich am Ende immer eine Maske mit.", "On heavy fine-dust days I always end up grabbing a mask."),
    ("mood", "a1", "opener", "좀 졸려요.", "Ich bin etwas schläfrig.", "I'm a bit sleepy."),
    ("mood", "a2", "question", "오늘 컨디션 어때요?", "Wie fühlst du dich heute?", "How are you feeling today?"),
    ("mood", "b1", "opener", "요즘 일이 많아서 좀 지쳤어요.", "Wegen viel Arbeit bin ich in letzter Zeit etwas erschöpft.", "I'm a bit worn out from all the work lately."),
    ("mood", "b2", "opener", "별일 없는데도 괜히 마음이 싱숭생숭하네요.", "Obwohl nichts los ist, bin ich grundlos unruhig.", "Nothing's really wrong, yet I feel oddly restless."),
    ("weekend", "a1", "reaction", "주말 잘 보내세요.", "Schönes Wochenende.", "Have a nice weekend."),
    ("weekend", "a2", "opener", "주말에 친구를 만났어요.", "Am Wochenende hab ich einen Freund getroffen.", "I met a friend over the weekend."),
    ("weekend", "b1", "opener", "이번 주말엔 집에서 좀 쉬려고요.", "Dieses Wochenende will ich mich zu Hause ausruhen.", "I plan to just rest at home this weekend."),
    ("weekend", "b2", "opener", "주말마다 뭔가 하려고 계획은 하는데 결국 늦잠만 자게 돼요.", "Jedes Wochenende plane ich etwas, aber am Ende schlafe ich nur aus.", "Every weekend I plan something but end up just sleeping in."),
    ("food", "a1", "opener", "배고파요.", "Ich hab Hunger.", "I'm hungry."),
    ("food", "a2", "question", "매운 거 잘 먹어요?", "Verträgst du Scharfes gut?", "Can you handle spicy food?"),
    ("food", "b1", "question", "이 근처에 맛집 좀 아세요?", "Kennen Sie hier in der Nähe ein gutes Lokal?", "Do you know any good restaurants nearby?"),
    ("food", "b2", "opener", "혼자 밥 먹는 것도 익숙해지니까 나름 편하더라고요.", "Allein zu essen wird mit der Zeit ganz angenehm.", "Eating alone becomes quite comfortable once you get used to it."),
    ("daily", "a1", "question", "잘 잤어요?", "Gut geschlafen?", "Did you sleep well?"),
    ("daily", "a2", "opener", "오늘 좀 늦었어요.", "Ich bin heute etwas spät dran.", "I'm running a bit late today."),
    ("daily", "b1", "opener", "요즘 하루가 너무 빨리 가는 것 같아요.", "Die Tage vergehen gerade so schnell.", "The days feel like they're flying by lately."),
    ("daily", "b2", "opener", "퇴근하고 나면 아무것도 하기 싫어지더라고요.", "Nach Feierabend hab ich zu gar nichts mehr Lust.", "After work I just don't feel like doing anything."),
    ("screen", "a1", "opener", "영화 좋아해요.", "Ich mag Filme.", "I like movies."),
    ("screen", "a2", "question", "주말에 영화 봤어요?", "Hast du am Wochenende einen Film gesehen?", "Did you watch a movie over the weekend?"),
    ("screen", "b1", "question", "최근에 본 것 중에 추천할 만한 거 있어요?", "Gibt's unter deinen letzten etwas zu empfehlen?", "Anything worth recommending from what you've seen recently?"),
    ("screen", "b2", "opener", "요즘은 드라마 정주행하느라 밤을 새우기 일쑤예요.", "In letzter Zeit binge ich Serien und mache oft die Nacht durch.", "Lately I binge dramas and often end up pulling all-nighters."),
    ("music", "a1", "opener", "노래 들어요.", "Ich höre Musik.", "I'm listening to music."),
    ("music", "a2", "question", "콘서트 가 본 적 있어요?", "Warst du schon mal auf einem Konzert?", "Have you ever been to a concert?"),
    ("music", "b1", "question", "기분 안 좋을 때 듣는 노래 있어요?", "Hast du ein Lied für schlechte Tage?", "Do you have a song for when you're feeling down?"),
    ("music", "b2", "opener", "출퇴근할 때 음악이 없으면 하루가 허전하더라고요.", "Ohne Musik auf dem Arbeitsweg fühlt sich der Tag leer an.", "Without music on my commute the day feels empty."),
    ("hobby", "a1", "opener", "저는 그림을 그려요.", "Ich male.", "I draw."),
    ("hobby", "a2", "question", "요즘 새로 배우는 거 있어요?", "Lernst du gerade etwas Neues?", "Are you learning anything new lately?"),
    ("hobby", "b1", "opener", "취미로 시작했는데 점점 진심이 됐어요.", "Hab's als Hobby angefangen, aber es wird immer ernster.", "I started it as a hobby but I'm getting more serious about it."),
    ("hobby", "b2", "opener", "바쁘다는 핑계로 취미를 자꾸 미루게 되네요.", "Mit der Ausrede 'keine Zeit' schiebe ich meine Hobbys ständig auf.", "I keep putting off my hobbies with the excuse of being busy."),
    ("travel", "a1", "opener", "바다 좋아해요.", "Ich mag das Meer.", "I like the sea."),
    ("travel", "a2", "question", "휴가 때 어디 갔어요?", "Wohin bist du im Urlaub gefahren?", "Where did you go on your vacation?"),
    ("travel", "b1", "question", "여행은 혼자 가는 편이에요, 같이 가는 편이에요?", "Reist du eher allein oder mit anderen?", "Do you tend to travel alone or with others?"),
    ("travel", "b2", "opener", "계획 없이 떠나는 여행이 의외로 더 기억에 남더라고요.", "Reisen ohne Plan bleiben einem überraschend besser in Erinnerung.", "Trips taken without a plan turn out surprisingly more memorable."),
    ("work_study", "a1", "opener", "오늘 바빠요.", "Heute ist viel los.", "I'm busy today."),
    ("work_study", "a2", "question", "일 끝나고 뭐 해요?", "Was machst du nach der Arbeit?", "What do you do after work?"),
    ("work_study", "b1", "opener", "새 프로젝트 때문에 요즘 좀 바빠요.", "Wegen eines neuen Projekts hab ich gerade viel zu tun.", "I'm pretty busy lately because of a new project."),
    ("work_study", "b2", "opener", "일과 삶의 균형을 맞추는 게 생각보다 어렵더라고요.", "Die Work-Life-Balance hinzubekommen ist schwerer als gedacht.", "Balancing work and life is harder than I expected."),
    ("family", "a1", "question", "부모님 잘 계세요?", "Geht's deinen Eltern gut?", "Are your parents doing well?"),
    ("family", "a2", "question", "형제 있어요?", "Hast du Geschwister?", "Do you have any siblings?"),
    ("family", "b1", "question", "명절엔 보통 가족이랑 보내세요?", "Verbringen Sie die Feiertage meist mit der Familie?", "Do you usually spend the holidays with family?"),
    ("family", "b2", "opener", "부모님이랑 떨어져 살면서 전화를 더 자주 하게 됐어요.", "Seit ich getrennt von meinen Eltern lebe, rufe ich öfter an.", "Since living apart from my parents, I've started calling them more often."),
    ("health", "a1", "reaction", "잘 자요.", "Schlaf gut.", "Sleep well."),
    ("health", "a2", "question", "요즘 잘 자요?", "Schläfst du in letzter Zeit gut?", "Are you sleeping well these days?"),
    ("health", "b1", "opener", "건강 챙기려고 물을 많이 마시려고 해요.", "Um gesund zu bleiben, versuche ich viel Wasser zu trinken.", "I try to drink lots of water to stay healthy."),
    ("health", "b2", "opener", "나이 드니까 조금만 무리해도 몸이 바로 티가 나더라고요.", "Mit dem Alter merkt der Körper jede kleine Überanstrengung sofort.", "As I get older, my body shows it right away if I overdo it even a little."),

    # ── neue Kategorien: K-pop / Dating / Interview ──
    ("kpop", "a1", "opener", "케이팝 좋아해요.", "Ich mag K-Pop.", "I like K-pop."),
    ("kpop", "a1", "reaction", "이 노래 인기 많아요.", "Das Lied ist sehr beliebt.", "This song is really popular."),
    ("kpop", "a2", "question", "어떤 아이돌 좋아해요?", "Welche Idols magst du?", "Which idols do you like?"),
    ("kpop", "a2", "question", "콘서트 표 구했어요?", "Hast du Konzertkarten bekommen?", "Did you get concert tickets?"),
    ("kpop", "b1", "question", "요즘 어떤 그룹 노래 많이 들어요?", "Welche Gruppe hörst du gerade viel?", "Which group are you listening to a lot lately?"),
    ("kpop", "b1", "question", "최애가 누구예요?", "Wer ist dein Bias (Lieblingsmitglied)?", "Who's your bias (favorite member)?"),
    ("kpop", "b2", "opener", "컴백 무대 보려고 음악방송까지 챙겨 보게 되더라고요.", "Für die Comeback-Bühne schaue ich sogar die Musikshows.", "I even keep up with the music shows just to catch the comeback stage."),
    ("kpop", "b2", "opener", "덕질하다 보면 시간 가는 줄 모르겠어요.", "Wenn man im Fandom versinkt, vergisst man die Zeit.", "When you're deep into fandom, you lose all track of time."),
    ("dating", "a1", "question", "남자친구 있어요?", "Hast du einen Freund?", "Do you have a boyfriend?"),
    ("dating", "a1", "question", "여자친구 있어요?", "Hast du eine Freundin?", "Do you have a girlfriend?"),
    ("dating", "a2", "question", "어떤 사람 좋아해요?", "Was für Menschen magst du?", "What kind of person do you like?"),
    ("dating", "a2", "question", "소개팅 해 봤어요?", "Warst du schon mal bei einem Blind Date?", "Have you ever been on a blind date?"),
    ("dating", "b1", "question", "이상형이 어떻게 돼요?", "Was ist dein Typ?", "What's your ideal type?"),
    ("dating", "b1", "question", "요즘 만나는 사람 있어요?", "Triffst du dich gerade mit jemandem?", "Are you seeing anyone these days?"),
    ("dating", "b2", "opener", "썸 타는 단계가 제일 설레는 것 같아요.", "Die 'Kennenlern-Phase' ist wohl am aufregendsten.", "The 'talking' stage is probably the most exciting."),
    ("dating", "b2", "opener", "연애는 타이밍이 정말 중요한 것 같더라고요.", "Beim Dating ist Timing wirklich entscheidend.", "In dating, timing really does seem to matter."),
    ("interview", "a1", "reaction", "떨려요.", "Ich bin nervös.", "I'm nervous."),
    ("interview", "a1", "reaction", "면접 잘 보세요.", "Viel Erfolg beim Vorstellungsgespräch.", "Good luck with your interview."),
    ("interview", "a2", "question", "면접 언제예요?", "Wann ist dein Vorstellungsgespräch?", "When is your interview?"),
    ("interview", "a2", "question", "어디 지원했어요?", "Wo hast du dich beworben?", "Where did you apply?"),
    ("interview", "b1", "question", "면접 준비 많이 했어요?", "Hast du dich gut auf das Interview vorbereitet?", "Did you prepare a lot for the interview?"),
    ("interview", "b1", "question", "자기소개는 어떻게 준비했어요?", "Wie hast du deine Selbstvorstellung vorbereitet?", "How did you prepare your self-introduction?"),
    ("interview", "b2", "opener", "압박 면접이라 너무 긴장됐어요.", "Es war ein Stressinterview, ich war total angespannt.", "It was a pressure interview, so I was really tense."),
    ("interview", "b2", "opener", "면접에선 솔직하면서도 자신감 있는 태도가 중요한 것 같아요.", "Im Interview ist eine ehrliche und zugleich selbstbewusste Haltung wichtig.", "In interviews, an honest yet confident attitude seems to matter."),
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
