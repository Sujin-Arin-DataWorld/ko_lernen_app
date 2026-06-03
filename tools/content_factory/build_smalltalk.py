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
    ("job_hunting", "🧑‍💻", "취업 준비", "Jobsuche", "Job hunting"),
    ("moving", "📦", "이사", "Umzug", "Moving house"),
    ("hospital", "🏥", "병원", "Arztbesuch", "At the clinic"),
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

    # ── neue Kategorien (batch 2): Jobsuche / Umzug / Arztbesuch ──
    ("job_hunting", "a1", "opener", "취업 준비해요.", "Ich suche gerade einen Job.", "I'm job hunting."),
    ("job_hunting", "a1", "question", "이력서 썼어요?", "Hast du deinen Lebenslauf geschrieben?", "Did you write your resume?"),
    ("job_hunting", "a2", "question", "어떤 회사 가고 싶어요?", "Bei welcher Firma möchtest du arbeiten?", "What company do you want to work for?"),
    ("job_hunting", "a2", "question", "자소서 다 썼어요?", "Bist du mit dem Anschreiben fertig?", "Did you finish your cover letter?"),
    ("job_hunting", "b1", "question", "요즘 취업 시장 어때요?", "Wie ist gerade der Arbeitsmarkt?", "How's the job market these days?"),
    ("job_hunting", "b1", "question", "어느 분야로 지원하고 있어요?", "In welchem Bereich bewirbst du dich?", "What field are you applying in?"),
    ("job_hunting", "b2", "opener", "서류는 붙었는데 면접에서 자꾸 떨어지네요.", "Die Unterlagen kommen durch, aber im Interview falle ich immer wieder durch.", "I pass the document round but keep failing the interviews."),
    ("job_hunting", "b2", "opener", "취준 기간이 길어지니까 좀 지치더라고요.", "Die lange Jobsuche zehrt langsam an mir.", "The long job search is starting to wear me down."),
    ("moving", "a1", "opener", "이사했어요.", "Ich bin umgezogen.", "I moved."),
    ("moving", "a1", "question", "집 구했어요?", "Hast du eine Wohnung gefunden?", "Did you find a place?"),
    ("moving", "a2", "question", "어디로 이사 가요?", "Wohin ziehst du um?", "Where are you moving to?"),
    ("moving", "a2", "question", "이삿짐 많아요?", "Hast du viel Umzugsgut?", "Do you have a lot of stuff to move?"),
    ("moving", "b1", "question", "새 집은 어때요?", "Wie ist die neue Wohnung?", "How's the new place?"),
    ("moving", "b1", "question", "이사 비용 많이 들었어요?", "War der Umzug teuer?", "Did the move cost a lot?"),
    ("moving", "b2", "opener", "이사하고 나니까 정리할 게 산더미예요.", "Nach dem Umzug gibt's einen Berg zum Aufräumen.", "After moving there's a mountain of stuff to organize."),
    ("moving", "b2", "opener", "전세 구하기가 요즘 정말 어렵더라고요.", "Eine Jeonse-Wohnung zu finden ist gerade echt schwer.", "Finding a jeonse place is really tough these days."),
    ("hospital", "a1", "opener", "병원 가요.", "Ich gehe zum Arzt.", "I'm going to the doctor."),
    ("hospital", "a1", "question", "어디 아파요?", "Wo tut's weh?", "Where does it hurt?"),
    ("hospital", "a2", "question", "예약했어요?", "Hast du einen Termin?", "Do you have an appointment?"),
    ("hospital", "a2", "question", "보험 있어요?", "Hast du eine Versicherung?", "Do you have insurance?"),
    ("hospital", "b1", "question", "증상이 언제부터 그랬어요?", "Seit wann hast du die Symptome?", "Since when have you had the symptoms?"),
    ("hospital", "b1", "question", "처방전 받았어요?", "Hast du ein Rezept bekommen?", "Did you get a prescription?"),
    ("hospital", "b2", "opener", "요즘 환절기라 병원에 사람이 너무 많더라고요.", "Wegen des Jahreszeitenwechsels ist beim Arzt gerade viel los.", "With the season changing, the clinic's been packed lately."),
    ("hospital", "b2", "opener", "큰 병원은 예약 잡기가 하늘의 별 따기예요.", "Bei großen Krankenhäusern einen Termin zu bekommen ist fast unmöglich.", "Getting an appointment at a big hospital is nearly impossible."),
]

LEVELS = {"a1", "a2", "b1", "b2"}
KINDS = {"opener", "question", "reaction"}

# 모범 답변 (캐치볼 연습) — 질문 ko → (ko, de, en). 자연스러운 한 줄 응답.
REPLIES = {
    "주말에 날씨 좋을까요?": ("네, 맑을 것 같아요.", "Ja, es wird wohl sonnig.", "Yeah, looks like it'll be sunny."),
    "오늘 하루 어떠셨어요?": ("바빴지만 괜찮았어요.", "Anstrengend, aber okay.", "Busy, but it was okay."),
    "주말에 뭐 해요?": ("보통 집에서 쉬어요.", "Meist ruh ich mich zu Hause aus.", "I usually rest at home."),
    "이번 주말에 뭐 할 거예요?": ("친구를 만날 거예요.", "Ich treffe einen Freund.", "I'm going to meet a friend."),
    "보통 쉬는 날엔 어떻게 시간 보내세요?": ("산책하거나 책을 읽어요.", "Ich gehe spazieren oder lese.", "I go for a walk or read."),
    "주말에 별 계획 없으면 같이 바람이나 쐬러 갈까요?": ("좋아요, 그래요!", "Gerne, machen wir!", "Sure, let's do it!"),
    "점심 뭐 먹었어요?": ("김치찌개 먹었어요.", "Kimchi-Eintopf.", "I had kimchi stew."),
    "요즘 맛있게 먹은 음식 있어요?": ("어제 먹은 파스타가 맛있었어요.", "Die Pasta gestern war lecker.", "The pasta I had yesterday was great."),
    "커피 마셨어요?": ("네, 아침에 한 잔 마셨어요.", "Ja, morgens eine Tasse.", "Yes, I had a cup this morning."),
    "요즘 무슨 드라마 봐요?": ("요즘 한국 드라마 보고 있어요.", "Gerade eine koreanische Serie.", "I'm watching a Korean drama these days."),
    "넷플릭스에 볼 만한 거 있어요?": ("요즘 이거 인기 많아요.", "Das hier ist gerade beliebt.", "This one's popular right now."),
    "요즘 통 볼 만한 게 없던데, 혹시 추천해 줄 거 있어요?": ("이 드라마 한번 봐 보세요.", "Probier mal diese Serie.", "Try this drama."),
    "무슨 음악 좋아해요?": ("케이팝이랑 발라드 좋아해요.", "K-Pop und Balladen.", "I like K-pop and ballads."),
    "즐겨 듣는 음악 장르가 있으세요?": ("주로 재즈를 들어요.", "Hauptsächlich Jazz.", "Mostly jazz."),
    "취미가 뭐예요?": ("사진 찍는 거 좋아해요.", "Ich fotografiere gern.", "I like taking photos."),
    "시간 있을 때 보통 뭐 해요?": ("보통 영화를 봐요.", "Meist schaue ich Filme.", "I usually watch movies."),
    "퇴근 후엔 주로 뭐 하면서 쉬세요?": ("음악 들으면서 쉬어요.", "Ich entspanne mit Musik.", "I relax by listening to music."),
    "스트레스 받을 때 푸는 본인만의 방법이 있으세요?": ("운동을 하면 좀 풀려요.", "Sport hilft mir dabei.", "Exercising helps me."),
    "어디로 여행 가고 싶어요?": ("제주도에 가고 싶어요.", "Nach Jeju.", "I want to go to Jeju."),
    "가장 기억에 남는 여행지가 어디예요?": ("부산이 제일 기억에 남아요.", "Busan.", "Busan is the most memorable."),
    "일 많아요?": ("네, 요즘 좀 바빠요.", "Ja, gerade ziemlich viel.", "Yeah, pretty busy lately."),
    "요즘 무슨 일 해요?": ("회사에서 마케팅 일 해요.", "Ich arbeite im Marketing.", "I work in marketing."),
    "일하면서 가장 보람 있을 때가 언제예요?": ("결과가 좋을 때 보람 있어요.", "Wenn die Ergebnisse gut sind.", "When the results turn out well."),
    "가족이 많아요?": ("네 명이에요.", "Wir sind vier.", "There are four of us."),
    "주말에 가족이랑 뭐 해요?": ("같이 밥 먹고 산책해요.", "Wir essen und spazieren zusammen.", "We eat and take walks together."),
    "가족이랑 자주 연락하는 편이세요?": ("네, 거의 매일 연락해요.", "Ja, fast täglich.", "Yes, almost every day."),
    "운동 좋아해요?": ("네, 좋아해요.", "Ja, sehr.", "Yes, I do."),
    "보통 무슨 운동 해요?": ("주로 달리기를 해요.", "Ich laufe meistens.", "I mostly run."),
    "건강을 위해 따로 하는 운동 있으세요?": ("요가를 하고 있어요.", "Ich mache Yoga.", "I do yoga."),
    "우산 가져왔어요?": ("네, 챙겨 왔어요.", "Ja, hab ich dabei.", "Yes, I brought one."),
    "오늘 컨디션 어때요?": ("좀 피곤하지만 괜찮아요.", "Etwas müde, aber okay.", "A bit tired, but okay."),
    "매운 거 잘 먹어요?": ("네, 매운 거 좋아해요.", "Ja, ich mag scharf.", "Yes, I love spicy food."),
    "이 근처에 맛집 좀 아세요?": ("저기 분식집이 맛있어요.", "Der Imbiss da drüben ist gut.", "That snack place over there is good."),
    "잘 잤어요?": ("네, 푹 잤어요.", "Ja, gut geschlafen.", "Yes, I slept well."),
    "주말에 영화 봤어요?": ("네, 한 편 봤어요.", "Ja, einen Film.", "Yes, I watched one."),
    "최근에 본 것 중에 추천할 만한 거 있어요?": ("이거 진짜 재밌었어요.", "Das war echt gut.", "This one was really good."),
    "콘서트 가 본 적 있어요?": ("네, 작년에 가 봤어요.", "Ja, letztes Jahr.", "Yes, last year."),
    "기분 안 좋을 때 듣는 노래 있어요?": ("네, 잔잔한 노래 들어요.", "Ja, ruhige Lieder.", "Yes, I listen to calm songs."),
    "요즘 새로 배우는 거 있어요?": ("요즘 기타 배워요.", "Ich lerne gerade Gitarre.", "I'm learning guitar these days."),
    "휴가 때 어디 갔어요?": ("바다에 다녀왔어요.", "Ans Meer.", "I went to the beach."),
    "여행은 혼자 가는 편이에요, 같이 가는 편이에요?": ("보통 친구랑 같이 가요.", "Meist mit Freunden.", "Usually with friends."),
    "일 끝나고 뭐 해요?": ("집에 가서 쉬어요.", "Ich geh heim und ruh mich aus.", "I go home and rest."),
    "부모님 잘 계세요?": ("네, 잘 지내세요.", "Ja, es geht ihnen gut.", "Yes, they're doing well."),
    "형제 있어요?": ("네, 동생 한 명 있어요.", "Ja, ein jüngeres Geschwister.", "Yes, one younger sibling."),
    "명절엔 보통 가족이랑 보내세요?": ("네, 가족이랑 모여요.", "Ja, wir kommen zusammen.", "Yes, we gather as a family."),
    "요즘 잘 자요?": ("네, 잘 자요.", "Ja, ganz gut.", "Yes, pretty well."),
    "어떤 아이돌 좋아해요?": ("저는 이 그룹 좋아해요.", "Ich mag diese Gruppe.", "I like this group."),
    "콘서트 표 구했어요?": ("네, 겨우 구했어요!", "Ja, gerade so!", "Yes, barely got one!"),
    "요즘 어떤 그룹 노래 많이 들어요?": ("요즘 이 그룹 많이 들어요.", "Gerade viel diese Gruppe.", "I'm listening to this group a lot."),
    "최애가 누구예요?": ("저는 메인보컬이 최애예요.", "Mein Bias ist der Hauptsänger.", "My bias is the main vocalist."),
    "남자친구 있어요?": ("아니요, 없어요.", "Nein, hab ich nicht.", "No, I don't."),
    "여자친구 있어요?": ("네, 있어요.", "Ja, hab ich.", "Yes, I do."),
    "어떤 사람 좋아해요?": ("유머 있는 사람이 좋아요.", "Ich mag humorvolle Menschen.", "I like people with a sense of humor."),
    "소개팅 해 봤어요?": ("네, 몇 번 해 봤어요.", "Ja, ein paar Mal.", "Yes, a few times."),
    "이상형이 어떻게 돼요?": ("착하고 잘 웃는 사람이요.", "Nett und fröhlich.", "Someone kind who smiles a lot."),
    "요즘 만나는 사람 있어요?": ("아니요, 요즘은 없어요.", "Nein, gerade nicht.", "No, not at the moment."),
    "면접 언제예요?": ("다음 주 월요일이에요.", "Nächsten Montag.", "Next Monday."),
    "어디 지원했어요?": ("IT 회사에 지원했어요.", "Bei einer IT-Firma.", "I applied to an IT company."),
    "면접 준비 많이 했어요?": ("네, 열심히 준비했어요.", "Ja, ich hab fleißig geübt.", "Yes, I prepared hard."),
    "자기소개는 어떻게 준비했어요?": ("경험 위주로 준비했어요.", "Hauptsächlich über meine Erfahrung.", "I focused on my experience."),
    "이력서 썼어요?": ("네, 어제 다 썼어요.", "Ja, gestern fertig geschrieben.", "Yes, I finished it yesterday."),
    "어떤 회사 가고 싶어요?": ("IT 회사에 가고 싶어요.", "Zu einer IT-Firma.", "I'd like to join an IT company."),
    "자소서 다 썼어요?": ("아직 반밖에 못 썼어요.", "Erst die Hälfte.", "Only halfway done so far."),
    "요즘 취업 시장 어때요?": ("경쟁이 좀 치열해요.", "Der Wettbewerb ist ziemlich hart.", "The competition is pretty fierce."),
    "어느 분야로 지원하고 있어요?": ("마케팅 쪽으로 지원해요.", "Im Bereich Marketing.", "I'm applying in marketing."),
    "집 구했어요?": ("네, 지난주에 구했어요.", "Ja, letzte Woche.", "Yes, last week."),
    "어디로 이사 가요?": ("회사 근처로 가요.", "In die Nähe der Firma.", "Near my office."),
    "이삿짐 많아요?": ("생각보다 많아요.", "Mehr als gedacht.", "More than I thought."),
    "새 집은 어때요?": ("깨끗하고 좋아요.", "Sauber und schön.", "Clean and nice."),
    "이사 비용 많이 들었어요?": ("네, 좀 비쌌어요.", "Ja, ziemlich teuer.", "Yeah, it was pretty pricey."),
    "어디 아파요?": ("목이 좀 아파요.", "Mein Hals tut weh.", "My throat hurts a bit."),
    "예약했어요?": ("네, 두 시로 했어요.", "Ja, um zwei Uhr.", "Yes, at two o'clock."),
    "보험 있어요?": ("네, 있어요.", "Ja, hab ich.", "Yes, I do."),
    "증상이 언제부터 그랬어요?": ("며칠 됐어요.", "Seit ein paar Tagen.", "For a few days now."),
    "처방전 받았어요?": ("네, 약 타러 가요.", "Ja, ich hol gleich die Medizin.", "Yes, I'm off to get the medicine."),
}


def _phrase(cat, lvl, kind, ko, de, en):
    p = {"category": cat, "level": lvl, "kind": kind, "ko": ko, "de": de, "en": en}
    if ko in REPLIES:
        r = REPLIES[ko]
        p["reply"] = {"ko": r[0], "de": r[1], "en": r[2]}
    return p


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
            _phrase(cat, lvl, kind, ko, de, en)
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
