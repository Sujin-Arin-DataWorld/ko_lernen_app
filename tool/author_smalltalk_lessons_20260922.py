"""Rebuild the authored Small Talk catalog; no network, randomness or source writes.

Each editorial row fixes a semantic group, title and scene/communicative goal.
The first ID is the scene's answer; IDs are never assigned by array chunking.
Meaning questions reuse source translations, with explicit semantic exclusions.
Run --check to validate the checked-in catalog against its authored definition.
"""
from __future__ import annotations
import argparse
import collections
import difflib
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/data/smalltalk.json'
DEST = ROOT / 'assets/data/smalltalk_lessons.json'
CAP = dict(a1=6, a2=6, b1=5, b2=5, c1=4, c2=4)

def tri(text):
    parts = text.split('~')
    assert len(parts) == 3, text
    return dict(zip(('ko', 'de', 'en'), parts))

# level | topic | stable semantic slug | source number list | KO~DE~EN title | KO~DE~EN scene
ROWS = '''
a1|weather|outside|1,2,14|밖의 날씨~Das Wetter draußen~The weather outside|밖에 나왔어요. 날씨가 좋아서 그 느낌으로 대화를 시작해요.~Du kommst nach draußen. Das angenehme Wetter bietet einen Gesprächseinstieg.~You step outside and start a conversation by commenting on the pleasant weather.
a1|mood|today|3,15|지금 기분~Wie es gerade geht~How you feel now|오늘 기분이 좋아요. 그 기분을 말해요.~Du bist heute gut gelaunt und möchtest das sagen.~You are in a good mood today and want to say so.
a1|weekend|plans|4,16|주말 이야기~Über das Wochenende sprechen~Talking about the weekend|주말에 보통 무엇을 하는지 궁금해요.~Du möchtest wissen, was die andere Person am Wochenende macht.~You want to know what the other person does on weekends.
a1|food|meal|5,17,63,64,82|함께 먹기~Gemeinsam essen~Eating together|음식을 먹었어요. 정말 맛있다고 말해요.~Du probierst das Essen und findest es wirklich lecker.~You taste the food and want to say it is really delicious.
a1|daily|routine|6,18,81|하루의 일상~Alltag zu Hause~Everyday routines|커피 이야기를 해요. 상대가 커피를 마셨는지 물어봐요.~Ihr sprecht über Kaffee. Du fragst, ob die andere Person Kaffee getrunken hat.~You are talking about coffee and ask whether the other person has had any.
a1|daily|turn|90|내 차례~Wann bin ich dran?~Waiting your turn|순서를 기다리고 있어요. 내 차례가 언제인지 물어봐요.~Du wartest und möchtest wissen, wann du an der Reihe bist.~You are waiting and want to know when your turn is.
a1|screen|taste|7,19|영화와 드라마~Filme und Serien~Films and dramas|같은 드라마 이야기를 해요. 그 드라마가 재미있다고 말해요.~Ihr sprecht über eine Serie. Du findest sie unterhaltsam.~You are discussing a drama and want to say it is entertaining.
a1|music|song|8,20|좋아하는 노래~Ein Lied mögen~Liking a song|지금 듣는 노래가 정말 좋아요. 그 느낌을 말해요.~Das Lied, das gerade läuft, gefällt dir sehr.~You really like the song that is playing and want to say so.
a1|hobby|drawing|9,21|취미 묻기~Nach Hobbys fragen~Asking about hobbies|상대의 취미를 알고 싶어요.~Du möchtest das Hobby der anderen Person kennenlernen.~You want to find out what the other person's hobby is.
a1|travel|preferences|10,22|좋아하는 여행~Reiselust~Enjoying travel|여행 이야기가 나왔어요. 여행을 아주 좋아한다고 말해요.~Ihr sprecht über Reisen. Du reist selbst sehr gern.~Travel comes up in conversation. You want to say you really enjoy traveling.
a1|travel|outing|59,60,61,62|여행지에서 부탁하기~Unterwegs um Hilfe bitten~Asking for help on a trip|사진에 함께 나오고 싶어요. 다른 사람에게 사진을 찍어 달라고 부탁해요.~Du möchtest mit aufs Foto und bittest jemanden, es aufzunehmen.~You want to be in the photo and ask someone to take it for you.
a1|work_study|busy|11,23|바쁜 하루~Ein voller Tag~A busy day|상대에게 일이 많은지 물어봐요.~Du fragst, ob die andere Person viel Arbeit hat.~You ask whether the other person has a lot of work.
a1|family|checkin|12,24|가족 안부~Nach der Familie fragen~Asking about family|상대의 가족이 많은지 궁금해요.~Du möchtest wissen, ob die andere Person eine große Familie hat.~You want to know whether the other person has a large family.
a1|health|rest|13,25|운동과 휴식~Bewegung und Erholung~Exercise and rest|운동 이야기를 시작해요. 상대가 운동을 좋아하는지 물어봐요.~Du beginnst ein Gespräch über Sport und fragst, ob die andere Person Sport mag.~You start talking about exercise and ask whether the other person enjoys it.
a1|kpop|interest|26,27|케이팝 좋아하기~K-Pop mögen~Liking K-pop|케이팝을 정말 좋아한다고 말해요.~Du möchtest sagen, dass du K-Pop sehr magst.~You want to say that you really like K-pop.
a1|dating|relationship|28,29|만나는 사람~Über Beziehungen sprechen~Talking about relationships|이미 연애 이야기를 하고 있어요. 남자친구가 있는지 물어봐요.~Ihr sprecht bereits über Beziehungen. Du fragst nach einem festen Freund.~You are already talking about relationships and ask whether the other person has a boyfriend.
a1|interview|nerves|30,31|면접 전 긴장~Nervos vor dem Gespräch~Interview nerves|면접을 앞두고 있어요. 정말 떨린다고 말해요.~Vor dem Vorstellungsgespräch bist du sehr aufgeregt.~Before the interview, you want to say you are really nervous.
a1|job_hunting|preparation|32,33|취업 준비~Bewerbungen vorbereiten~Preparing job applications|요즘 무엇을 하는지 물어봤어요. 취업을 준비 중이라고 답해요.~Du wirst gefragt, was du gerade machst. Du bereitest dich auf Bewerbungen vor.~Someone asks what you are doing these days. You are preparing to find a job.
a1|moving|newhome|34,35|새집 소식~Neu umgezogen~News of a move|최근에 이사했어요. 그 소식을 말해요.~Du bist vor Kurzem umgezogen und erzählst davon.~You moved recently and want to share the news.
a1|hospital|visit|36,37,86|병원과 약국~Arztpraxis und Apotheke~Clinic and pharmacy|오늘 병원에 다녀올 생각이에요. 그 계획을 말해요.~Du hast vor, heute noch zum Arzt zu gehen.~You are planning to go to the clinic today and want to say so.
a1|transport|taxi|38,39,43|택시에서~Im Taxi~In a taxi|택시에 탔어요. 목적지는 경복궁이에요.~Du sitzt im Taxi und möchtest zum Gyeongbokgung-Palast.~You are in a taxi and want to go to Gyeongbokgung Palace.
a1|transport|public|40,41,42,85,87|버스와 지하철~Bus und U-Bahn~Bus and subway|버스를 타기 전에 명동에 가는 버스인지 물어봐요.~Vor dem Einsteigen fragst du, ob der Bus nach Myeongdong fährt.~Before boarding, you ask whether the bus goes to Myeongdong.
a1|shopping|choose|44,45,46,47,48|물건 고르기~Etwas aussuchen~Choosing what to buy|여러 물건을 골랐어요. 모두 합쳐 얼마인지 물어봐요.~Du hast mehrere Dinge ausgesucht und fragst nach dem Gesamtpreis.~You have picked several items and ask for the total price.
a1|shopping|service|49,83,84,88|가게와 주문 정보~Informationen zur Bestellung~Shop and order details|나중에 다시 오려고 해요. 가게가 문을 닫는 시간을 물어봐요.~Du möchtest später wiederkommen und fragst nach der Schließzeit.~You plan to return later and ask when the shop closes.
a1|phone|call|50,51,52,53|전화 받기~Ans Telefon gehen~Answering the phone|전화가 왔어요. 전화를 받으며 첫마디를 해요.~Das Telefon klingelt. Du meldest dich am Telefon.~The phone rings. You answer with the usual opening greeting.
a1|phone|card|89|전화로 충전 장소 묻기~Nach einer Aufladestelle fragen~Asking where to top up|교통카드를 충전할 곳을 물어봐요.~Du möchtest wissen, wo du deine Fahrkarte aufladen kannst.~You ask where you can top up your transport card.
a1|emergency|help|54,55,56,57,58|도움 요청과 분실~Hilfe und verlorene Sachen~Help and lost belongings|급히 다른 사람의 도움이 필요해요. 먼저 도와 달라고 말해요.~Du brauchst dringend Unterstützung und rufst nach Hilfe.~You urgently need assistance and call for help.
a1|partner_family|arrival|65,66,67,68,69,70|가족 집 첫 방문~Der erste Familienbesuch~First visit to the family home|처음 방문한 집에서 상대를 어머님이라고 불러도 되는지 확인해요.~Beim ersten Besuch fragst du, ob du die Anrede 어머님 verwenden darfst.~On a first visit, you ask whether it is all right to use the address 어머님.
a1|partner_family|holiday|71,72,73,74,75,76|식사와 명절 준비~Essen und Festvorbereitungen~Meals and holiday preparations|아버님께 진지를 드셨는지 여쭤봐요.~Du sprichst den Vater mit 아버님 an und fragst respektvoll, ob er gegessen hat.~Addressing the father as 아버님, you respectfully ask whether he has eaten.
a1|partner_family|photos|77,78,79,80|호칭과 사진~Anreden und Fotos~Names and photos|현우의 동생을 어떻게 불러야 할지 몰라서 물어봐요.~Du bist unsicher, wie du Hyunwoos jüngeres Geschwister ansprechen sollst.~You are unsure how to address Hyunwoo's younger sibling and ask.
a1|theme_park_date|rides|91,92,93,94|놀이기구 고르기~Eine Attraktion auswählen~Choosing a ride|함께 탈 놀이기구를 가리키며 타 볼지 물어봐요.~Du zeigst auf eine Attraktion und schlägst vor, gemeinsam damit zu fahren.~You point to a ride and suggest going on it together.
a1|theme_park_date|break|95,96,97,98|앉아서 간식 먹기~Sitzen und etwas essen~Sitting down for a snack|빈자리가 보여요. 그곳에 앉자고 제안해요.~Du entdeckst freie Plätze und schlägst vor, sich dort hinzusetzen.~You spot some empty seats and suggest sitting there.
a1|theme_park_date|memory|99,100|사진과 하루의 소감~Fotos und Tagesrückblick~Photos and the day's memories|사진 찍기 좋은 곳이에요. 여기서 함께 사진을 찍자고 해요.~Hier ist ein guter Fotoplatz. Du schlägst ein gemeinsames Foto vor.~This is a good spot for a photo. You suggest taking one together here.
a2|weather|weekend|1,13|주말 날씨 준비~Fürs Wochenendwetter planen~Planning for weekend weather|주말 날씨가 좋을지 궁금해서 물어봐요.~Du fragst, ob am Wochenende wohl schönes Wetter sein wird.~You ask whether the weather will be nice this weekend.
a2|mood|condition|2,14|요즘 컨디션~Wie es in letzter Zeit geht~How you have been feeling|요즘 계속 조금 피곤해요. 내 상태를 말해요.~Du bist in letzter Zeit etwas müde und erzählst davon.~You have been a bit tired lately and want to say so.
a2|weekend|arrange|3,15,74,76,77|주말 약속 잡기~Sich fürs Wochenende verabreden~Making weekend plans|이번 주말에 함께 산책하자고 제안해요.~Du schlägst einen gemeinsamen Spaziergang dieses Wochenende vor.~You suggest going for a walk together this weekend.
a2|food|preferences|4,16,56,57|함께 먹을 음식~Gemeinsam Essen auswählen~Choosing a meal together|점심을 함께 먹고 싶어서 초대해요.~Du lädst die andere Person zum gemeinsamen Mittagessen ein.~You invite the other person to have lunch together.
a2|daily|morning|5,17|아침과 시간~Der Morgen und die Zeit~Mornings and timing|오늘 아침 일찍 일어났다는 이야기를 해요.~Du erzählst, dass du heute Morgen früh aufgestanden bist.~You say that you got up early this morning.
a2|screen|watching|6,18|요즘 보는 작품~Was gerade läuft~What you are watching|상대가 요즘 어떤 드라마를 보는지 물어봐요.~Du fragst, welche Serie die andere Person gerade schaut.~You ask which drama the other person is watching these days.
a2|music|preferences|7,19|음악 취향과 공연~Musikgeschmack und Konzerte~Music tastes and concerts|좋아하는 음악이 무엇인지 물어봐요.~Du fragst nach dem Musikgeschmack.~You ask what kind of music the other person likes.
a2|hobby|freetime|8,20|여가와 새로운 취미~Freizeit und neue Hobbys~Free time and new hobbies|시간이 날 때 보통 무엇을 하는지 궁금해요.~Du möchtest wissen, was die andere Person gewöhnlich in ihrer Freizeit macht.~You want to know what the other person usually does in their free time.
a2|travel|pastfuture|9,21|가고 싶은 곳과 다녀온 곳~Reiseziele und Urlaubserinnerungen~Travel wishes and past trips|다음에 여행하고 싶은 곳이 어디인지 물어봐요.~Du fragst, wohin die andere Person gern reisen würde.~You ask where the other person would like to travel.
a2|work_study|activity|10,22|하는 일과 함께 공부하기~Arbeit und gemeinsames Lernen~Work and studying together|상대가 요즘 무슨 일을 하는지 물어봐요.~Du fragst, was die andere Person derzeit beruflich macht.~You ask what kind of work the other person does these days.
a2|family|time|11,23|가족과 보내는 시간~Zeit mit der Familie~Time with family|주말에 가족과 무엇을 하는지 물어봐요.~Du fragst nach gemeinsamen Wochenendaktivitäten mit der Familie.~You ask what the other person does with family on weekends.
a2|health|habits|12,24,75|운동과 휴식 습관~Sport und Erholung im Alltag~Exercise and rest habits|평소에 어떤 운동을 하는지 물어봐요.~Du fragst, welche Sportart die andere Person normalerweise ausübt.~You ask what kind of exercise the other person usually does.
a2|kpop|fan|25,26|좋아하는 아이돌과 공연~Idols und Konzerte~Idols and concerts|상대가 좋아하는 아이돌이 누구인지 물어봐요.~Du fragst nach dem Lieblingsidol der anderen Person.~You ask which idol the other person likes.
a2|dating|experience|27,28|취향과 만남 경험~Vorlieben und Dating-Erfahrungen~Preferences and dating experiences|어떤 사람에게 끌리는지 물어봐요.~Du fragst, welchen Typ Mensch die andere Person mag.~You ask what type of person the other person likes.
a2|interview|application|29,30|면접 일정과 지원처~Termin und Bewerbung~Interview timing and applications|면접이 잡혔다는 말을 듣고 날짜를 물어봐요.~Du hörst von einem anstehenden Vorstellungsgespräch und fragst nach dem Termin.~You hear about an upcoming interview and ask when it is.
a2|job_hunting|applications|31,32|희망 회사와 지원서~Wunschunternehmen und Bewerbung~Preferred companies and applications|어떤 회사에 취업하고 싶은지 물어봐요.~Du fragst, bei welcher Art von Unternehmen die andere Person arbeiten möchte.~You ask what kind of company the other person wants to work for.
a2|moving|logistics|33,34,82,83|집 보기와 이사 일정~Besichtigung und Umzugstermin~Viewing a home and moving dates|이사할 계획을 듣고 어디로 가는지 물어봐요.~Du hörst von einem geplanten Umzug und fragst nach dem Ziel.~You hear about plans to move and ask where the person is moving to.
a2|moving|contract|78,79,80,81|집 계약 확인~Den Mietvertrag klären~Checking rental terms|관리비가 안내되어 있어요. 인터넷 요금도 포함인지 물어봐요.~Die Nebenkosten sind angegeben. Du fragst, ob Internet enthalten ist.~The maintenance fee is listed. You ask whether internet is included.
a2|hospital|appointment|35,36|진료 전 확인~Vor dem Arzttermin~Before a medical appointment|진료 이야기를 하며 예약 여부를 물어봐요.~Im Gespräch über einen Arztbesuch fragst du, ob ein Termin vereinbart wurde.~While discussing a clinic visit, you ask whether an appointment was booked.
a2|transport|route|37,38,39,40,41,42|길과 환승 묻기~Route und Umsteigen~Routes and transfers|코엑스에 가려고 해요. 지하철 몇 호선을 타는지 물어봐요.~Du möchtest zum COEX und fragst nach der passenden U-Bahn-Linie.~You want to get to COEX and ask which subway line to take.
a2|shopping|purchase|43,44,45,46,47,48|가격과 교환~Preis und Umtausch~Prices and exchanges|가격이 조금 비싸다고 느껴요. 값을 깎아 달라고 부탁해요.~Dir ist der Preis etwas zu hoch. Du bittest um einen Preisnachlass.~You find the price a little high and ask for a discount.
a2|phone|contact|49,50,51,52|전화 연결과 메시지~Verbinden und Nachrichten~Connecting calls and messages|전화를 걸었어요. 현우 씨와 통화하고 싶어요.~Du rufst an und möchtest mit Hyunwoo sprechen.~You call and ask to speak to Hyunwoo.
a2|emergency|report|53,54,55|분실과 도난 신고~Verlust und Diebstahl melden~Reporting loss and theft|여권을 찾을 수 없어요. 여권을 잃어버렸다고 말해요.~Dein Reisepass ist weg. Du meldest den Verlust.~You cannot find your passport and say that you have lost it.
a2|partner_family|holiday|58,60,61,62,63|명절과 가족 이야기~Familie und Feiertage~Family and holidays|두 분과 고향 이야기를 시작해요. 고향이 어디인지 여쭤봐요.~Du sprichst mit zwei Personen über ihre Herkunft und fragst nach ihren Heimatorten.~You are talking to two people and respectfully ask where their hometowns are.
a2|partner_family|speech|59,64,65,72,73|분위기와 말투~Atmosphäre und Anrede~Atmosphere and speech style|방문 중 조용했던 이유를 설명해요. 아직 분위기를 파악하기 어려웠어요.~Du erklärst, warum du beim Besuch still warst: Du konntest die Stimmung noch nicht einschätzen.~You explain that you were quiet during the visit because you could not yet read the atmosphere.
a2|partner_family|stay|66,67,68,69,70,71|하룻밤 머물고 돌아가기~Übernachten und Heimfahren~Staying overnight and leaving|하룻밤 머물러요. 손님방에서 자면 되는지 물어봐요.~Du übernachtest und fragst, ob du im Gästezimmer schlafen sollst.~You are staying overnight and ask whether you should sleep in the guest room.
a2|theme_park_date|snack|84,85,86,87|서서 기다린 뒤 쉬기~Nach dem Warten ausruhen~Resting after a long wait|너무 오래 서 있었어요. 발바닥이 많이 아프다고 말해요.~Du hast lange gestanden und deine Fußsohlen tun sehr weh.~You have been standing for a long time and your feet really hurt.
a2|theme_park_date|photos|88,89|캐릭터와 사진~Maskottchen und Fotos~Mascots and photos|더운 날 인형 탈을 쓴 직원을 봤어요. 힘들겠다고 짐작해요.~Du siehst bei Hitze jemanden im Maskottchenkostüm und vermutest, wie anstrengend das ist.~You see a worker in a mascot costume on a hot day and imagine how hard that must be.
a2|theme_park_date|waterqueue|90,91,92,93|물놀이와 줄 기다리기~Wasserbahn und Warteschlangen~Water rides and queues|바지가 다 젖었어요. 그래도 곧 마를 거라고 말해요.~Deine Hose ist ganz nass, aber du rechnest damit, dass sie bald trocknet.~Your trousers are soaked, but you expect them to dry soon.
'''
ROWS += '''
b1|weather|season|1,13|날씨와 산책~Wetter und Spaziergänge~Weather and walks|산책하기 좋은 날씨라며 상대의 공감을 구해요.~Du findest das Wetter ideal zum Spazierengehen und suchst Zustimmung.~You comment that the weather is perfect for a walk and invite agreement.
b1|mood|day|2,14|하루와 피로~Der Tag und die Müdigkeit~The day and fatigue|하루가 어땠는지 상대에게 정중하게 물어봐요.~Du erkundigst dich höflich, wie der Tag der anderen Person war.~You politely ask how the other person's day was.
b1|weekend|rest|3,15|쉬는 날 보내기~Freie Tage gestalten~Spending days off|보통 쉬는 날을 어떻게 보내는지 물어봐요.~Du fragst, wie die andere Person gewöhnlich freie Tage verbringt.~You ask how the other person usually spends days off.
b1|food|recommend|4,16|먹어 본 음식과 추천~Essen und Empfehlungen~Food experiences and recommendations|최근에 맛있게 먹은 음식이 있는지 물어봐요.~Du fragst nach etwas, das der anderen Person kürzlich gut geschmeckt hat.~You ask whether the other person has eaten anything especially good recently.
b1|daily|rhythm|5,17|하루의 리듬~Der Rhythmus des Tages~The rhythm of the day|아침 커피가 맛있었어요. 덕분에 하루가 기분 좋게 시작됐다고 말해요.~Der Kaffee war gut und hat dir einen schönen Start in den Tag beschert.~The morning coffee tasted good and made for a pleasant start to your day.
b1|screen|recommend|6,18|볼 만한 작품 추천~Sehenswerte Serien und Filme~Recommending something to watch|요즘 볼 만한 드라마를 추천받고 싶어요.~Du suchst eine sehenswerte Serie.~You want a recommendation for a drama worth watching these days.
b1|music|listening|7,19|음악 취향과 기분~Musikgeschmack und Stimmung~Music tastes and mood|즐겨 듣는 음악 장르가 있는지 정중하게 물어봐요.~Du fragst höflich nach einem bevorzugten Musikgenre.~You politely ask whether the other person has a favorite music genre.
b1|hobby|afterwork|8,20|일과 후의 취미~Hobbys nach Feierabend~Hobbies after work|퇴근 후 주로 무엇을 하며 쉬는지 물어봐요.~Du fragst, wie die andere Person nach der Arbeit entspannt.~You ask how the other person usually relaxes after work.
b1|travel|experience|9,21|여행의 기억과 방식~Reiseerinnerungen und Reisestil~Travel memories and habits|가장 기억에 남는 여행지가 어디인지 물어봐요.~Du fragst nach dem Reiseziel, das am stärksten in Erinnerung geblieben ist.~You ask which travel destination was the most memorable.
b1|work_study|working|10,22,76,77,78|일의 보람과 근무 조건~Arbeit und Arbeitsbedingungen~Work and working conditions|일하면서 언제 가장 보람을 느끼는지 물어봐요.~Du fragst, wann die Arbeit besonders erfüllend ist.~You ask when work feels most rewarding.
b1|work_study|coordination|45,46,47,48,71|일정과 업무 조율~Termine und Aufgaben abstimmen~Coordinating schedules and tasks|회의 시간이 바뀌었어요. 새 시간에 참석 가능한지 확인해요.~Der Besprechungstermin hat sich geändert. Du fragst, ob die Teilnahme möglich ist.~The meeting time has changed. You check whether the other person can attend.
b1|family|contact|11,23|가족과 연락하기~Kontakt zur Familie~Keeping in touch with family|가족과 자주 연락하는 편인지 물어봐요.~Du fragst, ob die andere Person regelmäßig Kontakt zur Familie hat.~You ask whether the other person tends to keep in frequent contact with family.
b1|health|habits|12,24|건강을 위한 습관~Gewohnheiten für die Gesundheit~Health habits|건강을 위해 따로 하는 운동이 있는지 물어봐요.~Du fragst nach Sport, den die andere Person gezielt für ihre Gesundheit macht.~You ask whether the other person does any particular exercise for their health.
b1|kpop|favorites|25,26|즐겨 듣는 그룹과 최애~Lieblingsgruppen und Lieblingsmitglieder~Favorite groups and members|요즘 어느 그룹의 노래를 많이 듣는지 물어봐요.~Du fragst, welche Gruppe die andere Person gerade oft hört.~You ask which group's music the other person listens to a lot these days.
b1|dating|gettingtoknow|27,28|이상형과 연애 근황~Wunschpartner und Dating~Ideal partners and dating news|연애 이야기를 하며 이상형을 물어봐요.~Im Gespräch über Beziehungen fragst du nach dem idealen Partnertyp.~While discussing relationships, you ask what the person's ideal partner is like.
b1|interview|prepare|29,30,74|면접 준비와 일정 변경~Vorbereitung und Terminänderung~Interview preparation and rescheduling|면접을 많이 준비했는지 물어봐요.~Du fragst, ob sich die andere Person gründlich auf das Vorstellungsgespräch vorbereitet hat.~You ask whether the other person has prepared a lot for the interview.
b1|job_hunting|requirements|31,32,73,75|지원 분야와 자격~Bewerbungsfelder und Voraussetzungen~Application fields and requirements|취업 시장이 요즘 어떤지 의견을 물어봐요.~Du fragst nach der aktuellen Lage auf dem Arbeitsmarkt.~You ask what the job market is like these days.
b1|moving|settling|33,34,72|이사 준비와 새집~Umzugsplanung und neues Zuhause~Moving plans and a new home|이사한 사람에게 새집이 어떤지 물어봐요.~Nach einem Umzug fragst du, wie das neue Zuhause ist.~After someone moves, you ask what their new home is like.
b1|hospital|symptoms|35,36|증상과 처방전~Symptome und Rezept~Symptoms and prescriptions|증상이 시작된 시점을 물어봐요.~Du fragst, seit wann die Beschwerden bestehen.~You ask when the symptoms began.
b1|transport|commute|37,38|노선 확인과 출근길~Busroute und Arbeitsweg~Bus routes and commuting|이 버스가 시청역에 가는지 아는지 물어봐요.~Du fragst jemanden, ob dieser Bus zur Station City Hall fährt.~You ask whether someone knows if this bus goes to City Hall Station.
b1|shopping|purchase|39,40|구매와 환불 조건~Kaufen und Rückgabe~Purchases and refunds|물건을 사기 전에 교환이나 환불이 가능한지 확인해요.~Vor dem Kauf fragst du nach Umtausch oder Erstattung.~Before buying, you check whether exchange or refund is possible.
b1|shopping|repair|53,54|수리 일정과 비용~Reparaturtermin und Kosten~Repair scheduling and costs|수리 기사 방문 시간을 오늘 안에 확인하고 싶어요.~Du möchtest den Besuchstermin des Reparaturdienstes noch heute klären.~You want to confirm the repair technician's visit time by the end of today.
b1|phone|availability|41,42|통화 시간 배려하기~Auf die Gesprächszeit achten~Checking availability for a call|지금 통화해도 되는지 묻고, 어렵다면 나중에 연락하겠다고 해요.~Du fragst, ob ein Gespräch gerade passt, und bietest einen späteren Rückruf an.~You ask whether now is a good time to talk and offer to call later.
b1|phone|coordination|49,50,51,52|전화와 메일로 조율하기~Telefonische und schriftliche Abstimmung~Coordinating by phone and email|담당자가 없어요. 대신 확인해 줄 수 있는지 정중하게 부탁해요.~Die zuständige Person ist abwesend. Du bittest jemanden, die Sache stattdessen zu prüfen.~The person responsible is away. You politely ask someone else to check instead.
b1|emergency|preparedness|43,44|신고와 비상 연락처~Meldung und Notfallkontakte~Reporting and emergency contacts|지갑을 잃어버렸어요. 어디에 신고하는지 물어봐요.~Du hast dein Portemonnaie verloren und fragst, wo du den Verlust melden sollst.~You lost your wallet and ask where to report it.
b1|partner_family|privacy|55,56,57,58|민감한 질문에 답하기~Auf persönliche Fragen reagieren~Responding to sensitive questions|가족이 결혼 계획을 물으면 어떻게 답할지 조언을 구해요.~Du suchst Rat für den Fall, dass die Familie nach Hochzeitsplänen fragt.~You ask for advice on responding if the family asks about marriage plans.
b1|partner_family|voice|59,60,61,62|직접 말하고 예절 확인하기~Selbst sprechen und Umgangsformen klären~Speaking for yourself and checking etiquette|현우가 계속 통역해 줘요. 내가 직접 말할 기회가 줄어들까 걱정돼요.~Hyunwoo dolmetscht ständig. Du sorgst dich um deine eigenen Gelegenheiten zu sprechen.~Hyunwoo keeps interpreting. You wonder whether this will leave you fewer chances to speak for yourself.
b1|partner_family|arrange|63,64,69,70|방과 명절 일정 조율~Zimmer und Besuchstermine abstimmen~Coordinating rooms and holiday visits|함께 머물 방을 정해요. 어떤 방 배정이 편할지 여쭤봐요.~Ihr verteilt die Zimmer. Du fragst, welche Aufteilung angenehm wäre.~You are arranging rooms and ask what allocation would be comfortable.
b1|partner_family|reflection|65,66,67,68|방문 뒤 소통하기~Nach dem Besuch in Kontakt bleiben~Communicating after a visit|방문 뒤 오늘 실수한 것이 있었는지 솔직하게 알려 달라고 해요.~Nach dem Besuch bittest du um Rückmeldung zu möglichen Fehlern.~After the visit, you ask for honest feedback about any mistakes you made today.
b1|theme_park_date|arrival|79,80,81|날씨와 방문 준비~Wetter und Vorbereitung~Weather and preparation|날씨가 정말 좋아요. 놀이공원에 오기 좋은 날이라고 말해요.~Das Wetter ist herrlich. Du findest den Tag ideal für den Freizeitpark.~The weather is lovely. You say it is a perfect day to visit the theme park.
b1|theme_park_date|thrill|82,83,84,85,86|놀이기구의 스릴~Der Nervenkitzel einer Fahrt~The thrill of a ride|롤러코스터가 올라갈 때 나는 소리를 좋아한다고 말해요.~Du magst das Klackern der Achterbahn beim Hochfahren.~You say you love the clicking sound as the roller coaster climbs.
b1|theme_park_date|afterride|87,88|타고 난 뒤 소감~Nach der Fahrt~After the ride|사진을 봤어요. 내 표정이 이상해서 사진이 웃기다고 말해요.~Auf dem Foto findest du deinen eigenen Gesichtsausdruck seltsam und lustig.~You look at the photo and find it funny because your own expression looks strange.
b2|weather|precautions|1,13|날씨 변화에 대비하기~Auf Wetterwechsel reagieren~Preparing for changing weather|최근 낮과 밤의 기온 차 때문에 감기에 걸리기 쉽다고 느꼈어요.~Dir ist aufgefallen, dass die großen Temperaturunterschiede Erkältungen begünstigen.~You have noticed that large temperature swings make it easy to catch a cold.
b2|mood|feelings|2,14,71,77,79|바쁨과 감정 조절~Stress und Gefühle~Busyness and managing feelings|너무 바빠서 시간이 어떻게 지나는지 모른다고 말해요.~Du bist so beschäftigt, dass du kaum merkst, wie die Zeit vergeht.~You say you have been so busy that you hardly notice time passing.
b2|mood|reading|57,58,59,60|글을 읽고 나눈 감상~Über einen Text sprechen~Discussing a text|글을 읽은 뒤 어떤 부분이 가장 오래 마음에 남았는지 물어봐요.~Du fragst, welche Textstelle nach dem Lesen am längsten nachgewirkt hat.~You ask which part of the text stayed with the other person longest after reading.
b2|weekend|plans|3,15|계획과 실제 주말~Pläne und das wirkliche Wochenende~Plans and actual weekends|주말에 다른 계획이 없다는 조건으로 함께 바람 쐬러 가자고 해요.~Du schlägst einen gemeinsamen Ausflug vor, falls am Wochenende noch nichts geplant ist.~You suggest going out for fresh air together if there are no other weekend plans.
b2|food|eatingout|4,16|같이 또는 혼자 먹기~Gemeinsam oder allein essen~Eating together or alone|가보고 싶은 맛집이 있으면 다음에 함께 가자고 제안해요.~Du bietest an, nächstes Mal gemeinsam ein gewünschtes Restaurant auszuprobieren.~You suggest trying a restaurant together next time if there is one the other person wants to visit.
b2|daily|overload|5,17,67,80|바쁜 생활 조정하기~Den vollen Alltag abstimmen~Adjusting a busy routine|요즘 출근길이 막혀서 평소보다 일찍 출발하게 됐다고 말해요.~Wegen der Staus auf dem Arbeitsweg gehst du inzwischen früher los.~You say traffic on your commute has been making you leave earlier than usual.
b2|daily|decisions|53,54,55,56|결정과 타협~Entscheiden und Kompromisse finden~Decisions and compromise|중요한 결정을 앞두고 어떤 기준을 가장 중요하게 보는지 물어봐요.~Vor einer wichtigen Entscheidung fragst du nach dem wichtigsten Kriterium.~Before a major decision, you ask which criterion matters most.
b2|daily|sharedspace|73,74,75,76|공용 공간에서 조율하기~Gemeinsame Räume nutzen~Coordinating shared spaces|공용 세탁기를 쓰려는 시간이 겹쳤어요. 이번에 어떻게 나눠 쓸지 의논해요.~Eure Waschzeiten überschneiden sich. Du möchtest eine Aufteilung vereinbaren.~Your times for using the shared washing machine overlap. You discuss how to share it this time.
b2|daily|settling|105,106,111,114|새 이웃과 주거 정보~Neue Nachbarn und Wohninformationen~New neighbors and housing information|새 이웃들이 가장 필요하다고 했던 정보를 물어봐요.~Du fragst, welche Informationen die neu Zugezogenen selbst am nötigsten fanden.~You ask what information new neighbors themselves said they needed most.
b2|daily|access|117,118|참여와 접근 장벽~Teilhabe und Zugangshürden~Participation and access barriers|사회 통합을 언어 시험 점수 하나로 평가할 수 있는지 의문을 제기해요.~Du hinterfragst, ob Sprachtestergebnisse allein Integration messen können.~You question whether language test scores alone can measure social integration.
b2|screen|watching|6,18,69|볼거리와 화면 습관~Serien und Bildschirmgewohnheiten~Viewing choices and screen habits|요즘 볼 만한 작품을 못 찾아서 추천을 부탁해요.~Du findest gerade nichts Sehenswertes und fragst nach einer Empfehlung.~You have not found anything worth watching lately and ask for a recommendation.
b2|screen|language|61,62,63,64|온라인 표현과 어감~Online-Sprache und Tonfall~Online expressions and tone|어떤 표현이 불편하게 들릴 수 있는 이유를 함께 살펴보자고 해요.~Du schlägst vor, gemeinsam zu überlegen, warum ein Ausdruck unangenehm wirken kann.~You suggest considering together why an expression might sound uncomfortable.
b2|screen|sharing|68,108|관심을 행동으로 옮기기~Von Aufmerksamkeit zur Handlung~Turning attention into action|링크 제목은 자극적이지만 내용은 불분명해요. 공유해도 될지 고민해요.~Ein Link hat eine reißerische Überschrift, aber unklaren Inhalt. Du überlegst, ob du ihn teilen solltest.~A link has a sensational headline but unclear content. You wonder whether to share it.
b2|music|routine|7,19|일상 속 음악~Musik im Alltag~Music in daily life|일하면서 음악을 들으면 집중이 더 잘되는 편이라고 말해요.~Du konzentrierst dich bei der Arbeit meist besser mit Musik.~You say you tend to concentrate better when you listen to music while working.
b2|hobby|balance|8,20|스트레스와 취미 시간~Stress und Zeit für Hobbys~Stress and time for hobbies|스트레스를 푸는 자기만의 방법이 있는지 물어봐요.~Du fragst nach einer persönlichen Methode zum Stressabbau.~You ask whether the other person has their own way of relieving stress.
b2|travel|memories|9,21|여행의 바람과 기억~Reisewünsche und Erinnerungen~Travel wishes and memories|언젠가 시간이 되면 꼭 가보고 싶은 나라가 있다고 말해요.~Du erzählst von einem Land, das du bei Gelegenheit unbedingt besuchen möchtest.~You say there is a country you would really like to visit when you have time.
b2|work_study|balance|10,22,65,78|일과 피드백의 부담~Arbeit, Feedback und Grenzen~Work, feedback and limits|일이 많아 정신없지만 배우는 것도 많다고 말해요.~Es ist viel los bei der Arbeit, aber du lernst auch viel.~You say work is hectic, but you are also learning a lot.
b2|work_study|meeting|66,70,72|회의 흐름과 근거~Besprechungsverlauf und Belege~Meeting focus and evidence|회의가 자꾸 주제를 벗어나요. 흐름을 잡을 방법을 물어봐요.~Die Besprechung schweift ständig ab. Du suchst eine Möglichkeit, sie zu lenken.~The meeting keeps going off topic. You ask how to bring it back on track.
b2|family|distance|11,23|떨어져 사는 가족~Familie auf Distanz~Family at a distance|멀리 살면서 가족의 소중함을 더 느끼게 됐다고 말해요.~Durch die Entfernung ist dir deine Familie noch wichtiger geworden.~You say living far away has made you appreciate your family more.
b2|health|body|12,24|운동 뒤 몸의 변화~Veränderungen durch Bewegung~Changes after starting exercise|운동을 시작한 뒤 컨디션이 좋아진 것 같다고 말해요.~Seit du Sport treibst, fühlst du dich offenbar fitter.~You say you feel your condition has improved since you started exercising.
b2|kpop|participation|25,26,107,112|팬 활동과 참여~Fan-Aktivitäten und Teilhabe~Fan activities and participation|컴백 무대를 보려고 음악방송까지 챙겨 보게 됐다고 말해요.~Für die Comeback-Auftritte schaust du inzwischen sogar Musiksendungen.~You say you have started keeping up with music shows to watch the comeback performances.
b2|dating|timing|27,28|설렘과 타이밍~Kribbeln und der richtige Moment~Excitement and timing|정식으로 사귀기 전 서로 마음을 알아가는 단계가 가장 설렌다고 말해요.~Du findest die Phase des gegenseitigen Interesses vor einer festen Beziehung besonders aufregend.~You say the stage of mutual interest before an official relationship feels the most exciting.
b2|interview|presentation|29,30,99|면접에서 나를 보여 주기~Sich im Gespräch präsentieren~Presenting yourself in an interview|압박 면접 때문에 매우 긴장했던 경험을 말해요.~Du erzählst, wie nervös dich ein Stressinterview gemacht hat.~You describe feeling very nervous because it was a pressure interview.
b2|job_hunting|experience|31,32,104|취업 준비의 경험~Erfahrungen bei der Jobsuche~Job-search experiences|서류 심사는 통과하지만 면접에서는 반복해서 떨어진다고 말해요.~Deine Unterlagen überzeugen, doch nach dem Gespräch kommen wiederholt Absagen.~You say you pass document screening but keep failing at the interview stage.
b2|job_hunting|systems|103,110,116|채용 절차 확인~Einstellungsverfahren hinterfragen~Examining recruitment procedures|회사에서 AI 선별 기준을 지원자에게 공개하는지 물어봐요.~Du fragst, ob die Firma ihre KI-Auswahlkriterien Bewerbenden mitteilt.~You ask whether the company tells applicants its AI screening criteria.
b2|moving|costs|33,34,109,113,115|이사와 주거비~Umzug und Wohnkosten~Moving and housing costs|이사를 마쳤는데 정리할 것이 아주 많다고 말해요.~Nach dem Umzug gibt es noch unglaublich viel aufzuräumen.~You say there is a mountain of organizing left after the move.
b2|hospital|waiting|35,36|진료받기 어려운 때~Wenn Arzttermine knapp sind~When medical appointments are hard to get|환절기라 병원에 사람이 많았다는 경험을 말해요.~Du berichtest, wie voll die Praxis beim Jahreszeitenwechsel war.~You describe how crowded the clinic was during the change of seasons.
b2|transport|timing|37,38|이동 시간 확인~Reisezeit prüfen~Checking journey times|이 열차가 공항까지 가장 빠른 경로인지 확인해 달라고 해요.~Du bittest um Bestätigung, ob dieser Zug die schnellste Verbindung zum Flughafen ist.~You ask for confirmation that this train is the fastest route to the airport.
b2|transport|housingtradeoff|101,102|출근길과 주거비 비교~Arbeitsweg und Wohnkosten abwägen~Weighing commute and housing costs|집의 월세 외에 매달 추가로 내는 돈이 얼마인지 물어봐요.~Du fragst nach den monatlichen Kosten zusätzlich zur Miete.~You ask how much must be paid each month in addition to rent.
b2|shopping|terms|39,40,48|구매와 보상 조건~Kauf- und Entschädigungsbedingungen~Purchase and compensation terms|구매 조건을 말로만 듣지 않고 서면으로 확인하고 싶어요.~Du möchtest die Kaufbedingungen schriftlich einsehen.~You want to check the purchase terms in writing.
b2|shopping|defect|45,46,81,82|반복되는 제품 문제~Wiederkehrende Produktfehler~Recurring product faults|제품 결함에 대해 담당 부서가 검토해 주기를 요청해요.~Du bittest die zuständige Abteilung, einen Produktmangel zu prüfen.~You ask the responsible department to review a product defect.
b2|phone|calltime|41,42,100|통화 시간과 기록~Gesprächszeit und Dokumentation~Call timing and records|지금 통화가 어려우면 가능한 시간을 알려 달라고 정중하게 요청해요.~Du bittest höflich um einen passenden Zeitpunkt, falls ein Gespräch gerade nicht möglich ist.~You politely ask for an available time if the person cannot talk now.
b2|phone|complaint|47,49,50,51,52|공식 문의와 후속 조치~Formelle Anfrage und weitere Schritte~Formal enquiries and follow-up action|이미 접수된 민원이 어디까지 처리됐는지 서면으로 알려 달라고 해요.~Du bittest um schriftliche Auskunft zum Bearbeitungsstand einer eingereichten Beschwerde.~You request a written update on a complaint that has already been submitted.
b2|emergency|information|43,44|도움받을 곳과 정확한 정보~Zuständige Hilfe und genaue Angaben~Finding help and giving accurate details|긴급한 상황이라 도움을 줄 담당 부서로 연결해 달라고 해요.~In einer dringenden Situation bittest du um Verbindung mit der zuständigen Hilfestelle.~In an urgent situation, you ask to be connected to the department that can help.
b2|partner_family|schedule|83,84,85,86|양가 일정과 결정~Termine mit beiden Familien~Schedules with both families|배우자 쪽과 내 쪽 가족 방문 시간을 공평하게 나눌 방법을 물어봐요.~Du fragst, wie Besuche bei beiden Familien fair aufgeteilt werden können.~You ask how to divide visits fairly between your partner's family and your own.
b2|partner_family|etiquette|87,88,89,90|호칭과 의례 익히기~Anreden und Rituale kennenlernen~Learning forms of address and rituals|호칭을 잘못 사용하면 바로 알려 달라고 부탁해요.~Du bittest darum, bei einer falschen Anrede sofort korrigiert zu werden.~You ask to be told right away if you use the wrong form of address.
b2|partner_family|labor|91,92,93,94|돈과 명절 노동~Geld und Arbeit an Feiertagen~Money and holiday work|용돈으로 보통 얼마를 드리는지 물어봐요.~Du fragst nach der üblichen Höhe eines Geldgeschenks an die Eltern.~You ask how much people usually give the parents as spending money.
b2|partner_family|boundaries|95,96,97,98|관계를 지키며 선 긋기~Grenzen setzen und verbunden bleiben~Setting boundaries while staying close|선을 긋더라도 관계가 나빠지지 않게 말하는 방법을 물어봐요.~Du suchst eine Formulierung, mit der du Grenzen setzt, ohne die Beziehung zu belasten.~You ask how to set a boundary without damaging the relationship.
b2|theme_park_date|preferences|119,120,121,122|무서움과 서로의 취향~Angst und unterschiedliche Vorlieben~Fear and different preferences|유령의 집에 가고 싶었지만 상대가 무서운 것을 싫어해서 못 갔다고 돌아봐요.~Du wolltest ins Geisterhaus, hast aber wegen der Abneigung der anderen Person darauf verzichtet.~You look back on wanting to visit the haunted house but not going because the other person dislikes scary things.
b2|theme_park_date|belongings|123,124,125,126|분실물과 소지품~Fundsachen und persönliche Dinge~Lost property and belongings|조금 전 밖에서 커피를 마셨어요. 지금 갈색 지갑이 없어서 분실물 접수 여부를 물어봐요.~Du hast gerade draußen Kaffee getrunken. Jetzt fehlt deine braune Geldbörse, und du fragst, ob sie abgegeben wurde.~You were just having coffee outside. Your brown wallet is now missing, so you ask whether it has been handed in.
b2|theme_park_date|afterwards|127,128|스트레스 해소와 사진 선택~Stressabbau und Fotoauswahl~Stress relief and choosing photos|마음껏 소리를 질러 스트레스가 풀린 듯하지만 목은 아프다고 말해요.~Das Schreien hat wohl Stress abgebaut, aber jetzt tut dein Hals weh.~You say screaming seems to have relieved your stress, though your throat hurts.
'''
ROWS += '''
c1|weather|coverage|45,46|날씨 대책의 효과와 전달~Wirkung und Reichweite von Wetterschutz~Weather measures and warning coverage|폭염 대책 평가에서 평균 기온만 봐도 충분한지 질문해요.~Du hinterfragst, ob die Durchschnittstemperatur zur Bewertung von Hitzemaßnahmen ausreicht.~You question whether average temperature alone is enough to evaluate heatwave measures.
c1|mood|responsibility|47,48|번아웃의 원인과 책임~Ursachen und Verantwortung bei Burnout~Causes and responsibility for burnout|번아웃 설문에서 업무량과 통제감을 구별해 물었는지 확인해요.~Du prüfst, ob eine Burnout-Umfrage Arbeitsmenge und Kontrolle getrennt erfasst hat.~You check whether a burnout survey asked separately about workload and sense of control.
c1|weekend|access|49,50|주말 공간의 접근성~Zugang zu Wochenendangeboten~Access to weekend activities|행사가 무료라는 이유만으로 누구나 실제로 참여할 수 있다고 보는지 질문해요.~Du fragst, ob freier Eintritt tatsächlich Zugang für alle gewährleistet.~You question whether free admission actually guarantees access to an event.
c1|food|definition|51,52|음식 통계와 전통의 기준~Essenspreise und Tradition definieren~Defining food prices and tradition|외식 물가 통계에 배달비와 최소 주문 금액도 들어갔는지 물어봐요.~Du fragst, ob Liefergebühren und Mindestbestellwerte im Preisindex enthalten sind.~You ask whether delivery fees and minimum order amounts are included in the dining-out price index.
c1|daily|access|1,2,7,16|이용자의 접근과 부담~Zugang und Belastung der Betroffenen~Access and burdens for users|새 안내 방식을 도입했어요. 접근성이 실제로 나아졌는지 확인할 방법을 의논해요.~Eine neue Informationsform wurde eingeführt. Du suchst eine Prüfung ihrer tatsächlichen Zugänglichkeit.~A new information format has been introduced. You discuss how to check whether it really improved accessibility.
c1|daily|uncertainty|9,10,12|불확실할 때 알리기~Bei Unsicherheit informieren~Communicating under uncertainty|확인된 정보가 적어요. 첫 공지에서 무엇을 먼저 밝혀야 할지 의논해요.~Es ist wenig bestätigt. Du besprichst, was in der ersten Mitteilung Vorrang haben sollte.~Little has been confirmed. You discuss what the first announcement should make clear first.
c1|daily|continuity|13,15|좋은 시도를 지속하기~Gute Ansätze dauerhaft umsetzen~Making good initiatives last|취지가 좋은 행사가 일회성으로 끝나지 않을 조건을 물어봐요.~Du fragst, was eine sinnvolle Veranstaltung braucht, damit sie kein einmaliges Ereignis bleibt.~You ask what is needed to keep a worthwhile event from being a one-off.
c1|daily|housing|33,34|주거 통계와 지원 접근~Wohnungsdaten und Zugang zu Förderung~Housing statistics and access to support|월세 평균이 안정적이라는 설명을 듣고 신규 계약도 포함된 수치인지 물어봐요.~Die Durchschnittsmiete gilt als stabil. Du fragst, ob neue Verträge darin enthalten sind.~Average rent is said to be stable. You ask whether new contracts are included.
c1|daily|settlement|37,38,43|일자리와 정착 여건~Arbeit und Ankommen vor Ort~Jobs and conditions for settling|인력이 부족한 지역에 자격 인정 상담도 제공되는지 물어봐요.~Du fragst, ob Regionen mit Personalmangel auch Beratung zur Anerkennung von Qualifikationen anbieten.~You ask whether areas with labor shortages also offer advice on recognition of qualifications.
c1|screen|evidence|25,26|영상의 주장과 근거~Behauptungen und Belege in Videos~Claims and evidence in videos|영상에서 연구를 소개했어요. 표본 인원도 밝혔는지 물어봐요.~Ein Video berichtet über eine Untersuchung. Du fragst, ob die Stichprobengröße genannt wurde.~A video presents research. You ask whether it stated the sample size.
c1|screen|ai|72,73,74|AI 표시와 실제 감독~KI-Kennzeichnung und echte Aufsicht~AI labels and real oversight|AI로 제작했다는 표시가 있다는 설명을 듣고 그것만으로 충분한지 질문해요.~Ein Inhalt ist als KI-generiert gekennzeichnet. Du fragst, ob das allein genügt.~Content is labeled as AI-generated. You ask whether that alone is sufficient.
c1|music|metrics|53,54|음악 성과를 읽는 법~Musikerfolg einordnen~Interpreting music metrics|스트리밍 순위가 실제 취향을 얼마나 드러내는지 질문해요.~Du fragst, wie aussagekräftig Streaming-Ranglisten für den tatsächlichen Musikgeschmack sind.~You ask how much streaming rankings reveal about actual listening preferences.
c1|hobby|limits|27,28|게임 시간 제한의 효과~Wirksamkeit von Spielzeitlimits~The effectiveness of gaming limits|게임 시간 제한이 효과가 있었다는 자료를 본 적이 있는지 물어봐요.~Du fragst nach Belegen dafür, dass Spielzeitlimits tatsächlich wirken.~You ask whether the other person has seen evidence that gaming time limits actually work.
c1|travel|impact|55,56|관광의 효과와 주민 생활~Tourismuswirkung und Alltag der Anwohner~Tourism effects and residents' lives|관광객이 늘었다는 수치만으로 지역 경제 효과를 말해도 되는지 질문해요.~Du hinterfragst, ob mehr Gäste allein einen wirtschaftlichen Nutzen für die Region belegen.~You question whether increased visitor numbers alone demonstrate benefits to the local economy.
c1|work_study|evidence|3,17,18|자료에서 결론까지~Von Daten zu Schlussfolgerungen~From evidence to conclusions|연구 결과가 가설을 지지하는지, 자료가 아직 부족한지 판단을 구해요.~Du wägest ab, ob ein Ergebnis die Hypothese stützt oder die Daten noch nicht ausreichen.~You ask whether a result supports the hypothesis or the evidence is still insufficient.
c1|work_study|reporting|4,8,11,23|한계와 오류를 공개하기~Grenzen und Fehler offenlegen~Disclosing limitations and errors|연구의 한계를 발표에서 어느 정도 설명해야 흐름을 해치지 않을지 의논해요.~Du besprichst, wie ausführlich Studiengrenzen genannt werden sollten, ohne den Vortrag zu stören.~You discuss how fully to explain research limitations without disrupting the presentation.
c1|work_study|cost|14|도입비와 유지비~Anschaffung und laufende Kosten~Upfront and ongoing costs|설치비는 낮지만 유지비는 높은 장비를 선택해도 될지 물어봐요.~Du wägest ein Gerät mit niedrigen Installationskosten und hohen laufenden Kosten ab.~You ask whether to choose equipment with low installation costs but high maintenance costs.
c1|work_study|ai|35,36,75|AI의 누락과 설명~KI: Ausschlüsse und Erklärungen~AI exclusions and explanations|AI 도입 뒤 처리 속도 외에 누가 더 자주 배제되는지도 확인했는지 물어봐요.~Du fragst, ob nach der KI-Einführung neben der Geschwindigkeit auch häufigere Ausschlüsse geprüft wurden.~You ask whether the evaluation of AI checked who gets left out more often, as well as speed.
c1|family|care|57,58|돌봄과 생활 조건~Sorgearbeit und Lebensbedingungen~Care and living conditions|돌봄 지원을 적게 이용하는 이유를 신청자에게 직접 물었는지 확인해요.~Du fragst, ob Antragstellende selbst nach den Gründen für die geringe Nutzung von Betreuungsangeboten gefragt wurden.~You check whether applicants themselves were asked why use of care support is low.
c1|health|evidence|6,24|개인 경험과 위험 설명~Persönliche Erfahrung und Risikokommunikation~Personal experience and explaining risk|연구 결과와 내 경험이 다를 때 어떻게 말할지 의논해요.~Deine Erfahrung weicht von Studienergebnissen ab. Du suchst einen passenden Umgang damit im Gespräch.~Your experience differs from research findings. You discuss how to talk about that.
c1|kpop|labor|29,30,39,76|팬 번역의 지속 가능성~Fan-Übersetzungen langfristig organisieren~Sustaining fan translation|번역 계정을 몇 명이 돌아가며 운영하는지 물어봐요.~Du fragst, wie viele Personen sich mit den Übersetzungen des Accounts abwechseln.~You ask how many people take turns translating for the account.
c1|kpop|reach|40,44,77|노출과 선호, 현지화~Sichtbarkeit, Vorlieben und Lokalisierung~Exposure, preference and localization|조회수가 높아도 추천 화면에 오래 나왔을 수 있으니 선호와 구분해야 한다고 말해요.~Du weist darauf hin, dass viele Aufrufe auch durch lange Empfehlungseinblendungen entstehen können.~You point out that high views may result from prolonged recommendation exposure and should be distinguished from preference.
c1|dating|safety|31,32|안전과 선택권 확인~Sicherheit und Wahlmöglichkeiten prüfen~Checking safety and choice|앱에 신고한 뒤 처리 결과도 알려 주는지 물어봐요.~Du fragst, ob die App nach einer Meldung über das Ergebnis informiert.~You ask whether the app reports the outcome after a complaint is filed.
c1|interview|assessment|59,60|면접 평가 기준 살피기~Interviewkriterien prüfen~Examining interview criteria|평가표의 문화 적합성이 구체적으로 어떤 행동으로 측정되는지 물어봐요.~Du fragst, an welchen Verhaltensweisen kulturelle Passung im Bewertungsbogen gemessen wird.~You ask which behaviors are used to measure cultural fit on the interview assessment form.
c1|job_hunting|screening|42,61|자동 선별의 오류~Fehler automatischer Vorauswahl~Errors in automated screening|자동 선별 정확도를 말할 때 집단별 오류까지 검토했는지 물어봐요.~Du fragst, ob die behauptete Auswahlgenauigkeit auch Fehler nach Gruppen berücksichtigt.~You ask whether claims of screening accuracy also account for errors across groups.
c1|moving|data|41,62|월세 평균의 범위~Was Mietdurchschnitte erfassen~What rent averages cover|월세 평균 자료를 보고 신규 계약이 충분히 포함됐는지 확인해요.~Du prüfst, ob neue Mietverträge in den Durchschnittsdaten ausreichend vertreten sind.~You check whether new rental contracts are adequately represented in the average rent data.
c1|hospital|access|63,64|진료 대기와 예약 접근~Wartezeiten und Buchungszugang~Waiting times and booking access|예약 대기 시간을 진료과별로 나누어 공개했는지 물어봐요.~Du fragst, ob Terminwartezeiten getrennt nach Fachabteilungen veröffentlicht wurden.~You ask whether appointment waiting times were published separately by department.
c1|transport|access|5,65|이동의 접근성~Zugängliche Mobilität~Accessible travel|엘리베이터가 고장 났어요. 계단 이용이 어려운 사람에게 안내할 대안을 의논해요.~Der Aufzug steht still. Du suchst eine Alternative für Menschen, denen Treppen schwerfallen.~The elevator has stopped. You discuss alternatives for someone who has difficulty using stairs.
c1|shopping|claims|66,67|친환경과 할인 주장 확인~Umwelt- und Rabattangaben prüfen~Checking environmental and discount claims|친환경 표시의 기준과 검증 기관이 공개됐는지 물어봐요.~Du fragst nach veröffentlichten Kriterien und der Prüfstelle hinter einem Umweltlabel.~You ask whether an environmental label's criteria and verifying body are disclosed.
c1|phone|transparency|68,69|추천과 녹음의 투명성~Transparenz bei Beratung und Aufzeichnung~Transparency in recommendations and recording|요금제 추천이 실제 사용량보다 판매 수수료에 영향을 받는 건 아닌지 확인해요.~Du hinterfragst, ob Provisionen die Tarifempfehlung stärker beeinflussen als die Nutzung.~You question whether sales commissions influence the plan recommendation more than usage does.
c1|emergency|warnings|70,71|대피 안내와 경보의 위험~Evakuierung und Warnrisiken~Evacuation guidance and warning risks|대피 안내가 이동이 어려운 사람까지 고려했는지 물어봐요.~Du fragst, ob die Evakuierungsanleitung Menschen mit eingeschränkter Mobilität berücksichtigt.~You ask whether evacuation guidance considers people with limited mobility.
c1|partner_family|identity|19,20|가족 안에서의 자리~Die eigene Stellung in der Familie~Your place in the family|며느리라는 호칭이 소속감을 주는지 역할에 가두는지 확신이 서지 않는다고 말해요.~Du bist unsicher, ob die Bezeichnung Schwiegertochter Zugehörigkeit schafft oder dich auf eine Rolle festlegt.~You are unsure whether being called the daughter-in-law includes you in the family or confines you to a role.
c1|partner_family|fairness|21,22|보이지 않는 일과 공평~Unsichtbare Arbeit und Fairness~Invisible work and fairness|명절의 눈에 보이지 않는 일까지 계산하면 누가 가장 많이 하는지 물어봐요.~Du fragst, wer an Feiertagen am meisten arbeitet, wenn unsichtbare Aufgaben mitzählen.~You ask who does the most work during the holidays when invisible tasks are included.
c1|theme_park_date|return|78,79,80,81|아쉬움에서 다음 약속으로~Aus Enttäuschung wird ein neuer Plan~Turning disappointment into another plan|꼭 타고 싶던 놀이기구가 오늘 운행하지 않는 듯해요. 아쉬움을 표현해요.~Die gewünschte Attraktion scheint heute außer Betrieb zu sein. Du drückst Enttäuschung aus.~The ride you really wanted seems to be closed today. You express disappointment.
c1|theme_park_date|uncertainty|82,83,84|농담과 엇갈리는 예상~Scherze und widersprüchliche Erwartungen~Jokes and competing expectations|바닥의 동전을 모으면 직원 커피값이 되겠다고 농담하고, 농담임을 분명히 해요.~Du scherzt, die Münzen am Boden könnten für Personalkaffee reichen, und kennzeichnest es als Witz.~You joke that the coins on the ground might buy the staff coffee and explicitly mark it as a joke.
c1|theme_park_date|reflection|85,86,87|즐거움과 자기 성찰~Freude und Selbstreflexion~Enjoyment and self-reflection|놀이공원에서는 크게 웃고 소리치는 것이 자연스러워 스트레스가 풀리는 것일 수도 있다고 추측해요.~Du vermutest, dass lautes Lachen und Schreien im Freizeitpark so selbstverständlich ist und vielleicht deshalb Stress abbaut.~You speculate that laughing and screaming loudly feels natural at the park and may explain its stress-relieving effect.
c2|weather|framing|45,46|기후 위험을 정의하는 기준~Klimarisiken definieren~Defining climate risk|기후 적응을 성공이라고 부를 때 어떤 손실을 정상으로 간주하는지 물어봐요.~Du hinterfragst, welche Verluste bei erfolgreicher Klimaanpassung als normal gelten.~You ask which losses are treated as normal when climate adaptation is called successful.
c2|mood|empathy|5|동의와 공감의 차이~Zustimmung und Mitgefühl unterscheiden~Distinguishing agreement from empathy|상대의 선택에 반대하면서도 마음을 이해할 수 있는지 질문해요.~Du fragst, ob Mitgefühl möglich ist, ohne eine Entscheidung gutzuheißen.~You ask whether it is possible to empathize with someone without agreeing with their choice.
c2|mood|housing|33,34|안정과 감당 가능의 기준~Stabilität und Bezahlbarkeit definieren~Defining stability and affordability|월세가 안정됐다는 문장에서 기존 계약과 신규 계약을 따로 봤는지 물어봐요.~Du fragst, ob die Aussage über stabile Mieten alte und neue Verträge unterscheidet.~You ask whether a statement about stable rents distinguishes existing from new contracts.
c2|weekend|costs|47,48|자율성과 보이지 않는 비용~Freiwilligkeit und versteckte Kosten~Voluntariness and hidden costs|주말 노동이 자율적이라는 말에 거절할 때 치르는 비용도 드러나는지 질문해요.~Du fragst, ob die Bezeichnung freiwillige Wochenendarbeit auch den Preis einer Ablehnung sichtbar macht.~You question whether calling weekend work voluntary reveals the cost of refusing it.
c2|food|assumptions|49,50|가격과 표준화의 전제~Annahmen über Preise und Standards~Assumptions about prices and standards|합리적인 가격이라는 평가가 누구의 소득과 시간 비용을 기준으로 하는지 물어봐요.~Du fragst, wessen Einkommen und Zeitkosten einem als angemessen geltenden Preis zugrunde liegen.~You ask whose income and time costs underpin a price described as reasonable.
c2|daily|fairness|2,7,9|결과와 절차의 공정성~Faire Ergebnisse und faire Verfahren~Fair outcomes and fair procedures|좋은 결과가 나왔더라도 절차가 불공정했다면 결정을 받아들여야 하는지 질문해요.~Du fragst, ob ein gutes Ergebnis eine unfair zustande gekommene Entscheidung akzeptabel macht.~You question whether a decision should be accepted if its outcome is good but its procedure was unfair.
c2|daily|appeal|14,17,18|자동 심사에 이의 제기하기~Automatische Entscheidungen anfechten~Challenging automated decisions|자동 심사에 이의를 제기하려는 사람에게 어떤 절차가 보여야 할지 물어봐요.~Du fragst, welches Verfahren für Menschen sichtbar sein muss, die eine automatische Entscheidung anfechten wollen.~You ask what procedure must be visible to someone seeking to challenge an automated decision.
c2|daily|autonomy|16,24|감시와 철회의 경계~Grenzen von Überwachung und Widerruf~Limits to surveillance and withdrawal|안전을 이유로 한 감시를 어느 범위까지 허용할 수 있는지 물어봐요.~Du fragst nach den zulässigen Grenzen einer mit Sicherheit begründeten Überwachung.~You ask how far surveillance justified by safety should be permitted.
c2|daily|accountability|35,36|AI 오류와 구제 책임~KI-Fehler und Abhilfe~AI errors and remedies|AI가 틀렸을 때 이용 회사와 공급업체 중 누가 답해야 하는지 물어봐요.~Du fragst, ob bei einem KI-Fehler das nutzende Unternehmen oder der Anbieter Rede und Antwort stehen muss.~You ask whether the company using AI or its supplier should answer for an error.
c2|daily|framing|43,71,72,75|사회 문제의 책임 프레임~Gesellschaftliche Verantwortung rahmen~Framing responsibility for social issues|취업률이 높다는 사실을 통합 성공의 근거로 보는 전제가 왜 문제인지 질문해요.~Du hinterfragst die Annahme, eine hohe Beschäftigungsquote bedeute gelungene Integration.~You question the assumption that a high employment rate means integration has succeeded.
c2|screen|context|4,10,12,74|맥락과 발언권~Kontext und Mitsprache~Context and voice|같은 사건을 다룬 두 기사가 전혀 다른 인상을 주는 이유를 물어봐요.~Du fragst, warum zwei Artikel über dasselbe Ereignis so unterschiedlich wirken.~You ask why two reports about the same event give such different impressions.
c2|music|power|51,52|추천 권력과 팬덤의 경계~Empfehlungsmacht und Fandom-Grenzen~Recommendation power and fandom boundaries|플랫폼이 발견 기회를 준다는 말이 추천에 대한 권력을 가리고 있지는 않은지 질문해요.~Du hinterfragst, ob das Versprechen von Entdeckbarkeit die Empfehlungsmacht der Plattform verdeckt.~You ask whether the platform's promise of discoverability obscures its power over recommendations.
c2|hobby|sanctions|27,28|자동 계정 정지의 근거~Gründe automatischer Kontosperren~Grounds for automated account suspension|계정이 자동 정지될 때 그 사유가 얼마나 공개되는지 물어봐요.~Du fragst, wie ausführlich eine automatische Kontosperre begründet wird.~You ask how much of the reason is disclosed when an account is automatically suspended.
c2|travel|limits|53,54|관광의 한계와 책임~Grenzen und Verantwortung des Tourismus~Tourism limits and responsibility|관광지 수용력을 정의할 때 주민 생활권까지 포함했는지 확인해요.~Du fragst, ob bei touristischer Tragfähigkeit auch der Lebensraum der Anwohner berücksichtigt wurde.~You check whether tourism capacity was defined to include residents' living space and rights.
c2|work_study|dissent|1,3,8,11|합의 속 소수 의견~Minderheitspositionen im Konsens~Minority views in consensus|다수의 안이 채택됐어도 소수 의견을 회의록에 남겨야 할지 물어봐요.~Du fragst, ob Minderheitspositionen nach Annahme des Mehrheitsvorschlags im Protokoll bleiben sollten.~You ask whether minority views should stay in the minutes even after the majority proposal is adopted.
c2|work_study|interpretation|6,23|해석의 여지와 권한~Interpretationsspielraum und Befugnisse~Room for interpretation and authority|결말을 열어 둔 작품을 어느 범위까지 해석할 수 있는지 질문해요.~Du fragst nach den Grenzen der Interpretation bei einem Werk mit offenem Ende.~You ask how far interpretation can go with a work that leaves its ending open.
c2|work_study|automation|13,15|자동 결정의 추적과 신뢰~Automatische Entscheidungen nachvollziehen~Tracing and trusting automated decisions|나중에 자동 결정의 이유를 추적할 수 있도록 지금 무엇을 기록할지 물어봐요.~Du fragst, was jetzt dokumentiert werden muss, damit eine automatische Entscheidung später nachvollziehbar bleibt.~You ask what must be recorded now so the reasons for an automated decision can be traced later.
c2|work_study|policy|37,38,73,76|정책의 성과와 선택권~Politikwirkung und Wahlfreiheit~Policy outcomes and freedom of choice|기사에서 통합 성공을 어떤 지표로 측정했는지 확인해요.~Du fragst, woran ein Artikel erfolgreiche Integration gemessen hat.~You ask how an article measured successful integration.
c2|family|responsibility|55,56|가족 담론과 공공 책임~Familiendiskurs und öffentliche Verantwortung~Family discourse and public responsibility|저출생을 국가 경쟁력의 위기로만 말할 때 누구의 삶이 수단이 되는지 질문해요.~Du fragst, wessen Leben instrumentalisiert wird, wenn niedrige Geburtenzahlen nur als nationale Wettbewerbskrise gelten.~You ask whose lives are treated as instruments when low birth rates are framed solely as a crisis of national competitiveness.
c2|health|classification|57,58|위험 분류와 정책 비용~Risikokategorien und politische Kosten~Risk classifications and policy costs|건강 앱에서 위험군으로 분류되었을 때 누가 이의를 제기할 수 있는지 물어봐요.~Du fragst, wer die Risikogruppen-Einstufung einer Gesundheits-App anfechten kann.~You ask who can challenge a health app's classification of someone as high-risk.
c2|kpop|norms|31,32|팬 공동체의 말과 기준~Sprache und Normen in Fangruppen~Language and norms in fan communities|문제가 된 표현에 대해 공동체 내부에서 왜 문제인지 설명한 적이 있는지 물어봐요.~Du fragst, ob innerhalb der Gruppe erklärt wurde, warum ein Ausdruck problematisch ist.~You ask whether anyone within the community has explained why an expression is problematic.
c2|kpop|boundaries|39,40,44|진짜 팬의 경계와 재해석~Fan-Grenzen und lokale Neuinterpretationen~Fan boundaries and local reinterpretation|발표에서 사용한 진짜 팬이라는 기준을 누가 정했는지 물어봐요.~Du fragst, wer im Vortrag den Maßstab für echte Fans festgelegt hat.~You ask who set the standard for a real fan in the presentation.
c2|dating|perspective|29,30|관계 기억의 관점~Perspektiven auf Beziehungserinnerungen~Perspectives on relationship memories|지금 정리된 이야기가 누구의 관점을 따르는지 물어봐요.~Du fragst, aus wessen Perspektive die Geschichte gerade erzählt wird.~You ask whose perspective shapes the way the story is currently being told.
c2|interview|bias|59,60|평가의 편향과 책임~Bewertungsverzerrung und Verantwortung~Assessment bias and responsibility|잠재력이라는 기준에 평가자와 닮은 사람을 선호하는 편향이 숨어 있을 수 있다고 질문해요.~Du hinterfragst, ob das Kriterium Potenzial eine Vorliebe für den Bewertenden ähnliche Personen verdeckt.~You question whether the criterion of potential hides a preference for people similar to the evaluator.
c2|job_hunting|accountability|42,61|채용 도구와 독립적 이의 절차~Auswahltools und unabhängiger Widerspruch~Recruitment tools and independent appeals|자동 결정을 보조 도구라고 부르면 책임을 지는 주체도 달라지는지 질문해요.~Du fragst, ob die Bezeichnung Hilfswerkzeug statt automatischer Entscheidung die Verantwortungszuordnung verändert.~You ask whether calling something an assistance tool rather than an automated decision changes who is responsible.
c2|moving|affordability|41,62|감당 가능한 주거비의 기준~Bezahlbarkeit von Wohnraum definieren~Defining affordable housing|감당 가능한 집이라는 정의가 어떤 사람의 지출 구조를 전제로 하는지 물어봐요.~Du fragst, wessen Ausgabenstruktur der Definition bezahlbaren Wohnraums zugrunde liegt.~You ask whose spending pattern underlies the definition of affordable housing.
c2|hospital|consent|63,64|진료 알고리즘과 동의~Behandlungsalgorithmen und Einwilligung~Clinical algorithms and consent|진료 우선순위 알고리즘의 오류에 대해 병원과 공급자 중 누가 책임지는지 물어봐요.~Du fragst, ob das Krankenhaus oder der Anbieter für Fehler im Triage-Algorithmus verantwortlich ist.~You ask whether the hospital or supplier is accountable for errors in an algorithm that prioritizes care.
c2|transport|distribution|65,66|이동 정책의 비교 기준~Verkehrspolitik und Vergleichsmaßstäbe~Transport policies and comparison standards|혼잡 요금이 이동 대안이 적은 사람에게 어떤 부담을 넘기는지 질문해요.~Du fragst, welche Belastung eine Staugebühr auf Menschen mit wenigen Verkehrsalternativen verlagert.~You ask what burden congestion pricing shifts onto people with few travel alternatives.
c2|shopping|choice|67,68|혜택이라는 말과 선택권~Vorteilsversprechen und Wahlfreiheit~Claims of benefits and consumer choice|개인화 가격을 맞춤 혜택이라고 이름 붙이면 차별의 가능성까지 없어지는지 질문해요.~Du fragst, ob die Bezeichnung maßgeschneiderter Vorteil das Diskriminierungsrisiko personalisierter Preise beseitigt.~You question whether calling personalized pricing a tailored benefit removes its potential for discrimination.
c2|phone|remedy|25,26|요금 이의와 실제 구제~Rechnungseinspruch und wirksame Abhilfe~Billing appeals and effective remedies|자동 계산된 요금에 이의를 제기하면 사람이 재검토하는지 물어봐요.~Du fragst, ob ein Mensch eine automatisch berechnete Gebühr nach einem Einspruch erneut prüft.~You ask whether a person reviews an automatically calculated charge after an appeal.
c2|emergency|power|69,70|비상 권한의 종료와 책임~Ende von Notstandsbefugnissen und Verantwortung~Ending emergency powers and assigning responsibility|비상 권한에 종료 조건이 없으면 예외가 어떻게 상시 제도로 굳어지는지 질문해요.~Du fragst, wie fehlende Endbedingungen Notstandsbefugnisse zur Dauereinrichtung machen.~You ask how emergency powers without an end condition can turn an exception into a permanent system.
c2|partner_family|decisions|19,20|결정과 전달의 권한~Entscheiden und Entscheidungen mitteilen~Making and communicating decisions|결정하는 사람과 그 결정을 말로 전하는 사람이 다른 것 같다고 의견을 구해요.~Du vermutest, dass Entscheidung und Verkündung bei verschiedenen Personen liegen, und fragst nach einer Einschätzung.~You ask for a view on your impression that the person making decisions differs from the person voicing them.
c2|partner_family|authorship|21,22|역할을 넘어 내 이름으로~Mehr als eine Familienrolle~Being more than a family role|계속 이름 대신 가족 내 역할로 불리면 훗날 어떻게 기억될지 질문해요.~Du fragst, wie du später in Erinnerung bleibst, wenn man dich nur mit einer Rolle statt deinem Namen bezeichnet.~You ask how you will be remembered if you are addressed only by your role rather than your name.
c2|theme_park_date|sharedjoy|77,78,79|일상 밖에서 함께 느끼기~Gemeinsam außerhalb des Alltags~Shared feelings outside daily life|사람들의 웃음과 설레는 모습을 보고 놀이공원의 매력을 알 것 같다고 성찰해요.~Angesichts des Lachens und der Vorfreude glaubst du zu verstehen, was Menschen am Freizeitpark mögen.~Seeing people's laughter and excitement, you reflect that you may understand why people enjoy the park.
c2|theme_park_date|anticipation|80,81,82|공포 뒤 해방감과 기대~Erleichterung nach Angst und Vorfreude~Release after fear and anticipation|무서운데 또 타고 싶은 마음을 공포가 끝난 뒤의 해방감으로 설명할 수 있을지 생각해요.~Du vermutest, dass der Wunsch nach einer weiteren Fahrt mit der Erleichterung nach der Angst zusammenhängt.~You consider whether wanting another ride despite the fear is about enjoying the release afterward.
c2|theme_park_date|sharedmemory|83,84,85,86|완벽하지 않아도 함께한 하루~Ein gemeinsamer Tag trotz kleiner Pannen~A shared day despite imperfections|유령의 집을 포기한 아쉬움은 있지만 서로 즐길 수 있는 것을 고르는 게 더 중요하다고 말해요.~Du bedauerst den Verzicht aufs Geisterhaus, hältst aber gemeinsames Vergnügen für wichtiger.~You are disappointed about skipping the haunted house but say choosing something both can enjoy matters more.
'''

# Situation contrasts are authored against each scene's exact communicative goal.
# They are Korean choices intentionally shared across UI locales, not translations.
SCENE_OPTIONS = '''
a1.weather.outside|오늘은 비가 많이 오네요.|내일 날씨도 좋을까요?
a1.mood.today|오늘 기분이 별로예요.|어제는 기분이 좋았어요.
a1.weekend.plans|주말에 어디 갔어요?|평일에는 뭐 해요?
a1.food.meal|이거 맛이 좀 이상해요.|이 음식 만드는 게 어려워요.
a1.daily.routine|커피 마실래요?|커피 좋아해요?
a1.daily.turn|제 차례가 끝났어요?|다음에는 어디로 가요?
a1.screen.taste|그 드라마 너무 지루해요.|그 드라마 언제 시작해요?
a1.music.song|이 노래 제목이 뭐예요?|이 노래는 별로예요.
a1.hobby.drawing|취미 생활 자주 해요?|그림은 어디에서 배워요?
a1.travel.preferences|저 여행 별로 안 좋아해요.|저 여행이 끝났어요.
a1.travel.outing|여기서 사진 찍어도 돼요?|사진을 같이 볼까요?
a1.work_study.busy|일이 언제 끝나요?|일이 재미있어요?
a1.family.checkin|가족이 어디 살아요?|가족을 자주 만나요?
a1.health.rest|운동 끝났어요?|운동하러 어디 가요?
a1.kpop.interest|저 케이팝 잘 몰라요.|이 케이팝 노래 누가 불러요?
a1.dating.relationship|남자친구 어디에 있어요?|남자친구랑 언제 만나요?
a1.interview.nerves|아, 진짜 편안하네요.|면접이 벌써 끝났네요.
a1.job_hunting.preparation|요즘 회사에서 일하고 있어요.|취업 준비는 다 끝났어요.
a1.moving.newhome|저 다음 달에 이사해요.|저 이 집에 오래 살았어요.
a1.hospital.visit|오늘 병원에서 왔어요.|오늘 병원 문 열어요?
a1.transport.taxi|경복궁에서 기다려 주세요.|경복궁에서 왔어요.
a1.transport.public|이 버스가 명동에서 출발해요?|명동에 가는 지하철이 어디예요?
a1.shopping.choose|이거 하나 얼마예요?|이거 전부 있어요?
a1.shopping.service|몇 시에 문을 열어요?|오늘 가게가 쉬어요?
a1.phone.call|전화번호가 뭐예요?|나중에 전화할게요.
a1.phone.card|교통카드 얼마예요?|교통카드 어디에서 써요?
a1.emergency.help|이제 괜찮아요!|도움이 필요하세요?
a1.partner_family.arrival|어머님은 지금 어디 계세요?|어머님께 언제 전화하면 될까요?
a1.partner_family.holiday|아버님, 진지 준비해 드릴까요?|아버님, 내일 진지 같이 드실래요?
a1.partner_family.photos|현우 동생은 어디에 있어요?|현우 동생은 몇 살이에요?
a1.theme_park_date.rides|우리 저거 이미 탔지?|저거 타고 싶지 않아.
a1.theme_park_date.break|자리 없네. 조금만 더 서 있자.|저 자리는 누가 예약했어?
a1.theme_park_date.memory|우리 찍은 사진부터 볼까?|우리 저쪽에서 기다릴까?
a2.weather.weekend|지난 주말에 날씨 좋았어요?|이번 주말에 어디 갈까요?
a2.mood.condition|요즘은 전혀 피곤하지 않아요.|오늘만 조금 긴장돼요.
a2.weekend.arrange|지난 주말에 같이 산책했죠?|이번 주말에 혼자 산책하려고요.
a2.food.preferences|점심은 벌써 먹었어요?|점심에는 뭐 먹었어요?
a2.daily.morning|오늘 아침에 늦게 일어났어요.|내일 아침에 일찍 일어날 거예요.
a2.screen.watching|그 드라마 어제 끝났어요?|요즘 어떤 영화를 만들어요?
a2.music.preferences|음악 언제 들어요?|음악 소리 너무 커요?
a2.hobby.freetime|오늘 몇 시에 시간 있어요?|시간이 없을 때 어떻게 해요?
a2.travel.pastfuture|어디로 여행 다녀왔어요?|여행 언제 끝나요?
a2.work_study.activity|요즘 일을 어디에서 배워요?|지금 하는 일을 좋아해요?
a2.family.time|주말에 가족이랑 어디 살아요?|주중에 혼자 뭐 해요?
a2.health.habits|보통 운동은 몇 시에 해요?|운동 좋아하게 됐어요?
a2.kpop.fan|그 아이돌은 언제 데뷔했어요?|아이돌 콘서트 언제 가요?
a2.dating.experience|그 사람을 어디서 만났어요?|그 사람은 무슨 일 해요?
a2.interview.application|면접은 어디에서 봐요?|면접 결과 언제 나와요?
a2.job_hunting.applications|어떤 회사에 다녔어요?|그 회사는 어디에 있어요?
a2.moving.logistics|언제 이사 가요?|누구랑 이사 가요?
a2.moving.contract|인터넷 요금은 언제 내요?|관리비는 매달 달라져요?
a2.hospital.appointment|진료 다 받았어요?|예약을 취소할 거예요?
a2.transport.route|코엑스역은 몇 번 출구로 나가요?|코엑스에서 지하철은 몇 시에 끊겨요?
a2.shopping.purchase|비싸도 괜찮아요. 그냥 살게요.|조금 비싸니까 포장만 해 주세요.
a2.phone.contact|현우 씨가 전화하셨나요?|현우 씨에게 제 번호를 알려 주세요.
a2.emergency.report|여권을 다시 찾았어요.|여권을 새로 신청했어요.
a2.partner_family.holiday|두 분은 지금 어디 사세요?|두 분은 언제 처음 만나셨어요?
a2.partner_family.speech|분위기를 잘 알아서 먼저 농담했어요.|조용히 있었지만 모든 말은 잘 이해했어요.
a2.partner_family.stay|손님방은 누가 청소했어요?|손님방에 짐만 두고 가도 돼요?
a2.theme_park_date.snack|오래 앉아 있어서 허리가 아파.|금방 일어나서 발은 하나도 안 아파.
a2.theme_park_date.photos|인형 탈 안은 시원해서 일하기 편하겠다.|저 직원은 오늘 일을 쉬는 게 분명해.
a2.theme_park_date.waterqueue|바지가 하나도 안 젖었어. 다행이다.|바지가 젖었어. 오늘 안에는 안 마를 거야.
b1.weather.season|이런 날씨엔 산책하기 어렵겠죠.|산책하면 내일 날씨가 좋아지겠죠.
b1.mood.day|내일은 하루를 어떻게 보내실 거예요?|오늘 하루 종일 어디 계셨어요?
b1.weekend.rest|이번 한 번만 쉬는 날을 바꿀까요?|보통 일하는 날에는 몇 시에 출근하세요?
b1.food.recommend|요즘 피하고 싶은 음식 있어요?|다음 주에 먹어 보고 싶은 음식 있어요?
b1.daily.rhythm|아침 커피가 맛없어서 하루 시작부터 아쉽네요.|아침에 커피를 못 마셔서 이제 마시려고요.
b1.screen.recommend|요즘 드라마를 어디서 촬영하나요?|요즘 드라마 보는 시간을 줄이셨어요?
b1.music.listening|음악을 주로 언제 들으세요?|음악 장르는 모두 똑같이 좋아하세요?
b1.hobby.afterwork|퇴근할 때는 주로 어떤 교통편을 쓰세요?|출근 전에는 주로 어떤 일을 준비하세요?
b1.travel.experience|가장 저렴했던 여행지는 어디예요?|다음에 꼭 가야 하는 여행지는 어디예요?
b1.work_study.working|일하면서 가장 피곤할 때가 언제예요?|일하면서 보통 몇 시에 쉬세요?
b1.work_study.coordination|회의 시간이 그대로인데 장소를 바꿔도 될까요?|회의가 취소됐는데 다음 주에 새로 잡을까요?
b1.family.contact|가족과 한집에서 사는 편이세요?|가족에게 먼저 선물을 보내는 편이세요?
b1.health.habits|건강 때문에 운동을 모두 그만두셨어요?|운동할 때 주로 어떤 옷을 입으세요?
b1.kpop.favorites|요즘 어떤 그룹이 새로 데뷔했어요?|요즘 어떤 그룹의 춤을 연습해요?
b1.dating.gettingtoknow|지금 만나는 사람과 어디서 만났어요?|이상형을 만나면 언제 결혼할 거예요?
b1.interview.prepare|면접 결과를 많이 기다렸어요?|면접은 이미 다 끝났어요?
b1.job_hunting.requirements|다음 주 면접 장소가 어디예요?|취업하면 첫 월급은 어디에 쓸 거예요?
b1.moving.settling|새 집에는 언제 이사할 거예요?|예전에 살던 집은 얼마나 컸어요?
b1.hospital.symptoms|증상은 지금 얼마나 심해요?|증상이 어느 부위에 있어요?
b1.transport.commute|이 버스가 시청역에서 출발하는지 아세요?|시청역에서 버스가 몇 시에 끊기는지 아세요?
b1.shopping.purchase|이 상품은 포장이나 배송이 가능한가요?|이 상품은 할인이나 적립이 가능한가요?
b1.shopping.repair|수리가 오늘 안에 반드시 끝나는지 확인할 수 있을까요?|수리 기사님이 지난번에 언제 왔는지 알 수 있을까요?
b1.phone.availability|지금 꼭 통화해야 하니 나중으로 미루지 말아 주세요.|지금 통화가 끝났으니 앞으로는 연락하지 않을게요.
b1.phone.coordination|담당자분이 오실 때까지 확인하지 말아 주세요.|담당자분 대신 제가 확인했으니 다시 보지 않으셔도 돼요.
b1.emergency.preparedness|지갑을 찾았는데 신고를 취소해야 하나요?|지갑을 새로 사려면 어디에 가야 하나요?
b1.partner_family.privacy|결혼 날짜가 정해졌는데 언제 알려 드릴까요?|결혼 계획을 물어보시면 왜 화를 내시는 걸까요?
b1.partner_family.voice|현우가 계속 통역하면 제가 직접 말할 필요는 없어지겠죠?|현우가 통역을 안 해서 제가 이미 모든 말을 잘 전달했어요.
b1.partner_family.arrange|방 배정은 이미 끝났으니 그대로 따라 주세요.|같은 방을 쓰실 분은 몇 시에 도착하시나요?
b1.partner_family.reflection|오늘 제가 한 실수는 다시는 이야기하지 말아 줄래요?|다음 명절에 무슨 음식을 할지 지금 정해 줄래요?
b1.theme_park_date.arrival|날씨가 너무 나빠서 놀이공원에 오기 힘든 날이야.|날씨가 좋아질 때까지 놀이공원에 가지 말자.
b1.theme_park_date.thrill|난 롤러코스터가 내려갈 때 나는 비명 소리가 싫어.|롤러코스터가 올라갈 때는 아무 소리도 안 나서 좋아.
b1.theme_park_date.afterride|우리 사진은 너무 평범해서 하나도 안 웃겨.|내 표정은 잘 나왔는데 사진이 너무 어둡게 찍혔다.
'''

SCENE_OPTIONS += '''
b2.weather.precautions|요즘 일교차가 작아서 감기 걱정은 전혀 없더라고요.|감기에 걸린 뒤로 일교차가 더 커졌다고 하더라고요.
b2.mood.feelings|요즘 너무 한가해서 시간이 안 가는 것 같아요.|요즘 바쁘기는 해도 시간이 늘 남아서 지루해요.
b2.mood.reading|이 글을 읽는 데 시간이 얼마나 걸렸어요?|이 글에서 가장 먼저 고쳐야 할 문장은 무엇이었어요?
b2.weekend.plans|주말 약속을 모두 취소하고 꼭 같이 나가야 해요.|주말에 이미 같이 나갔으니 다음에는 혼자 갈게요.
b2.food.eatingout|제가 정한 맛집으로 다음에 꼭 같이 오셔야 해요.|가보고 싶은 맛집이 있어도 이번에는 따로 가요.
b2.daily.overload|출근길이 한산해져서 예전보다 늦게 나서게 돼요.|출근 시간이 바뀌어서 길이 더 막히게 된 것 같아요.
b2.daily.decisions|중요한 결정은 이미 끝났는데 결과에 만족하세요?|중요한 결정을 남에게 맡기면 책임도 없어질까요?
b2.daily.sharedspace|세탁기 시간이 겹쳤으니 이번에는 제가 먼저 쓰겠습니다.|공용 세탁기를 언제 샀는지 확인해 주실 수 있을까요?
b2.daily.settling|새로 이사 온 분들에게 가장 필요할 거라고 우리가 예상한 정보는 뭐였어요?|새로 이사 온 분들이 가장 늦게 제출한 서류가 뭐였어요?
b2.daily.access|언어 시험 점수만 높으면 사회 통합은 모두 성공한 거겠죠?|사회 통합과 관계없이 시험 문항 수만 줄여 볼까요?
b2.screen.watching|요즘 볼 만한 게 너무 많아서 추천은 필요 없어요.|추천해 주신 작품은 다 봤는데 결말을 바꿀 수 있을까요?
b2.screen.language|이 표현은 누구에게나 편하니 이유를 따져 볼 필요가 없어요.|이 표현이 불편하다는 사람의 배경을 우리가 정해 볼까요?
b2.screen.sharing|제목이 자극적이니 내용은 확인하지 말고 바로 공유할까요?|내용이 충분히 확인됐으니 제목만 더 자극적으로 바꿀까요?
b2.music.routine|일할 때 음악을 들으면 오히려 집중이 흐트러지는 편이에요.|집중이 잘될 때만 음악 듣는 일을 시작할 수 있어요.
b2.hobby.balance|스트레스를 받으면 취미는 반드시 그만두시나요?|스트레스를 주는 방법 중 가장 효과적인 게 뭔가요?
b2.travel.memories|시간이 생겨도 다시는 가고 싶지 않은 나라가 있어요.|가보고 싶은 나라는 이미 이번 여행에서 모두 다녀왔어요.
b2.work_study.balance|요즘 일이 줄어서 여유롭지만 배울 게 하나도 없어요.|요즘 일이 몰리니 배우는 건 전혀 불가능하다고 생각해요.
b2.work_study.meeting|회의가 주제를 벗어나도 끝날 때까지 그대로 두는 게 낫겠죠?|회의가 예정대로 끝났는데 참석자 수를 어떻게 늘릴까요?
b2.family.distance|멀리 떨어져 사니 가족의 소중함을 오히려 덜 느끼게 됐어요.|가족이 소중해서 이제부터는 반드시 같이 살아야 해요.
b2.health.body|운동을 시작했지만 컨디션은 더 나빠진 게 확실해요.|컨디션이 좋아졌으니 운동을 시작할 필요가 없어졌어요.
b2.kpop.participation|컴백 무대는 관심 없어서 음악방송도 안 보게 돼요.|음악방송을 보지 않으려고 컴백 무대만 기다리고 있어요.
b2.dating.timing|사귀기 전에는 아무 설렘도 없고 연애가 끝난 뒤에만 설레요.|썸을 타기만 하면 누구나 바로 결혼을 결정해야 해요.
b2.interview.presentation|편안한 면접이라 긴장이 전혀 되지 않았어요.|면접이 끝나고 합격한 뒤에야 처음 긴장됐어요.
b2.job_hunting.experience|서류는 계속 떨어지는데 면접만 보면 꼭 합격해요.|서류와 면접에 모두 합격해서 입사 날짜만 기다려요.
b2.job_hunting.systems|그 회사는 AI 선별 결과가 나온 뒤 면접 날짜만 알려 줘요?|그 회사는 지원자가 AI를 썼는지만 확인해요?
b2.moving.costs|이사 전에 다 정리해서 이제 남은 일이 하나도 없어요.|정리할 게 너무 적어서 이사를 취소하려고 해요.
b2.hospital.waiting|환절기인데도 병원에 사람이 거의 없더라고요.|병원에 사람이 많아서 계절이 바뀐 것이 확실해요.
b2.transport.timing|이 열차가 공항까지 가장 싼 경로인지 확인해 주시겠습니까?|이 열차가 공항에서 출발하는 마지막 열차인지 확인해 주시겠습니까?
b2.transport.housingtradeoff|그 집은 월세를 어느 날짜에 내야 해요?|그 집은 월세에 모든 비용이 포함된 게 확실하죠?
b2.shopping.terms|구매 조건은 기록 없이 전화로만 설명해 주실 수 있을까요?|구매 조건과 관계없이 영수증만 다시 보내 주실 수 있을까요?
b2.shopping.defect|제품의 결함은 검토하지 말고 같은 상품을 바로 더 보내 주시겠습니까?|담당 부서의 검토가 끝났으니 더 이상 결함을 기록하지 않겠습니다.
b2.phone.calltime|지금 통화가 어려워도 이 시간에 반드시 답해 주셔야 합니다.|가능한 시간은 알려 주지 마시고 다음 연락을 기다려 주세요.
b2.phone.complaint|아직 접수하지 않은 민원을 전화로 처음 설명드리겠습니다.|접수된 민원의 처리 현황은 서면으로 남기지 말아 주십시오.
b2.emergency.information|긴급한 상황은 아니니 도움을 받을 부서로 연결하지 않으셔도 됩니다.|담당 부서와 이미 연결됐으니 이제 도움 요청을 취소하겠습니다.
b2.partner_family.schedule|올해는 한쪽 집에만 가기로 했으니 일정은 더 나누지 맙시다.|시댁과 친정이 같은 지역에 사는지 먼저 주소만 확인할까요?
b2.partner_family.etiquette|호칭을 잘못 써도 그냥 넘어가 주시겠어요?|어떤 호칭을 쓰실지는 제가 대신 정해 드려도 될까요?
b2.partner_family.labor|용돈은 보통 어느 은행으로 보내 드려요?|용돈을 드린 뒤에는 반드시 돌려받아야 하나요?
b2.partner_family.boundaries|관계가 나빠지더라도 상대가 불편하도록 거절하려면 어떻게 말할까요?|거절하지 않고 언제나 모두 받아들이겠다고 어떻게 약속할까요?
b2.theme_park_date.preferences|너도 유령의 집을 좋아해서 결국 둘이 즐겁게 다녀왔지.|나는 유령의 집이 싫었는데 네가 억지로 데려가서 결국 들어갔지.
b2.theme_park_date.belongings|안녕하세요. 갈색 지갑을 주웠는데 분실물로 맡길 수 있을까요?|안녕하세요. 갈색 지갑을 새로 사고 싶은데 기념품점에 있나요?
b2.theme_park_date.afterwards|소리를 전혀 지르지 않아서 목은 편한데 스트레스가 더 쌓였어.|소리를 크게 질렀더니 목도 전혀 안 아프고 앞으로 스트레스는 절대 없을 거야.
c1.weather.coverage|폭염 대책의 효과는 평균 기온만 낮아지면 충분히 확인된 거겠죠?|폭염 대책을 평가할 때 평균 기온 자료는 전혀 볼 필요가 없겠죠?
c1.mood.responsibility|업무량과 통제감은 같은 개념이므로 설문에서 구별할 필요가 없어요.|번아웃 설문 결과만으로 업무량을 모두 줄이기로 이미 결정했나요?
c1.weekend.access|주말 행사는 입장료가 없으니 다른 접근 장벽도 모두 사라졌어요.|주말 행사에 무료로 온 사람은 참여 이유를 따로 물을 수 없죠?
c1.food.definition|외식 물가 지수에서 음식값을 빼고 배달비만 비교했나요?|배달비가 올랐다는 이유로 최소 주문 금액도 이미 올렸나요?
c1.daily.access|새 안내 방식을 도입했으니 접근성 향상은 확인할 필요가 없겠죠?|새 안내 방식이 더 저렴한지만 확인하면 이용자 반응은 생략해도 되겠죠?
c1.daily.uncertainty|확정된 내용이 적어도 첫 공지에서는 모든 결과를 확실한 사실로 발표할까요?|확인된 내용과 미확인 내용을 구분하지 않고 첫 공지를 만들까요?
c1.daily.continuity|좋은 취지의 행사라도 한 번으로 끝내려면 무엇을 없애야 할까요?|행사가 지속됐는지는 따지지 말고 첫날 참석자만 세면 되겠죠?
c1.daily.housing|평균 월세가 안정적이면 신규 계약의 월세도 모두 같아졌다는 뜻인가요?|신규 계약만 조사해서 기존 계약의 월세는 모두 제외했다는 뜻인가요?
c1.daily.settlement|인력이 부족한 지역에서는 자격 인정 상담을 받지 못하도록 정했나요?|자격 인정 상담을 받은 사람은 모두 그 지역에 정착했다고 볼 수 있나요?
c1.screen.evidence|그 영상의 조회수가 연구 표본 수와 같다고 나와 있었어요?|그 영상에 나온 연구는 표본 없이 진행됐다고 확인됐어요?
c1.screen.ai|AI로 만든 콘텐츠는 표시가 있으면 정확성도 자동으로 보장되겠죠?|AI 제작 여부는 표시하지 않는 편이 이용자에게 더 투명하겠죠?
c1.music.metrics|스트리밍 순위가 높으면 모든 청취자의 취향이 같다는 뜻이죠?|실제 청취 취향과 상관없이 순위 발표 날짜만 확인하면 될까요?
c1.hobby.limits|게임 시간 제한을 도입했다는 사실만으로 효과가 입증된 거겠죠?|게임 시간 제한이 효과 없다고 정해 놓고 자료를 골라도 될까요?
c1.travel.impact|관광객 수가 늘었으니 주민 모두의 소득도 늘었다고 단정해도 되겠죠?|지역 경제 효과는 관광객 수와 관련된 자료를 전부 빼야 알 수 있을까요?
c1.work_study.evidence|자료가 부족해도 이 결과만으로 가설이 완전히 입증됐다고 발표할까요?|가설과 맞는 결과가 나왔으니 추가 자료는 모두 무의미하겠죠?
c1.work_study.reporting|발표 흐름을 위해 연구의 한계는 전부 숨겨도 괜찮을까요?|연구의 한계만 설명하고 연구 결과는 발표하지 않는 게 목적이죠?
c1.work_study.cost|설치비가 싸니 유지비가 아무리 높아도 이 장비가 가장 저렴하겠죠?|유지비가 높다는 이유만으로 설치비도 비쌌다고 기록해도 될까요?
c1.work_study.ai|AI 도입 뒤 속도만 빨라졌으면 누락되는 사람은 더 볼 필요가 없겠죠?|누가 빠지는지는 이미 확인됐으니 처리 속도만 처음 조사한 건가요?
c1.family.care|돌봄 지원 이용률이 낮으니 신청자에게 묻지 않고 수요가 없다고 결론 냈나요?|신청자에게 이용률을 높이라고 부탁했으니 낮은 이유는 해결된 건가요?
c1.health.evidence|제 경험과 다르니 연구 결과는 모두 틀렸다고 말하면 될까요?|연구 결과와 다르면 제 개인 경험은 없었던 일로 설명해야 할까요?
c1.kpop.labor|그 계정의 번역은 돌아가며 하지 않고 한 분이 모두 맡으세요?|그 계정은 몇 분마다 번역문을 자동으로 올리나요?
c1.kpop.reach|추천 화면에 오래 나와 조회수가 높다면 실제 선호도도 반드시 높아요.|조회수가 높다는 것은 추천 화면 노출과 아무 관계가 없다는 증거예요.
c1.dating.safety|그 앱은 신고를 받으면 결과를 알리지 않기로 이미 정했나요?|그 앱에서 신고 결과를 받으면 처음 신고를 다시 취소해야 하나요?
c1.interview.assessment|문화 적합성은 행동과 관계없이 평가자의 느낌으로 정하면 되나요?|평가표에 문화 적합성이 있으면 집단별 오류는 이미 없는 거겠죠?
c1.job_hunting.screening|전체 선별 정확도가 높으면 집단별 오류는 따로 볼 필요 없겠죠?|집단별 지원자 수만 공개하면 집단별 오류까지 공개한 셈이죠?
c1.moving.data|평균 월세가 안정적이니 신규 계약 월세도 반드시 내려갔겠죠?|신규 계약은 모두 빼야 평균 월세를 정확하게 구할 수 있나요?
c1.hospital.access|진료과별 차이는 중요하지 않으니 대기 시간은 전체 평균만 공개하면 돼요.|대기 시간이 짧아졌다는 이유로 진료과별 예약을 모두 없앴나요?
c1.transport.access|엘리베이터가 멈췄어도 계단이 있으니 대안 안내는 생략해도 되겠죠?|계단을 이용하기 어려운 분께는 기다리지 말고 반드시 계단으로 가시라고 할까요?
c1.shopping.claims|친환경 표시가 붙어 있으면 기준과 검증 기관은 확인하지 않아도 되나요?|검증 기관의 이름만 있으면 친환경 기준은 공개할 필요가 없나요?
c1.phone.transparency|판매 수수료가 높은 요금제가 사용량에도 반드시 가장 잘 맞겠죠?|사용량에 맞는 요금제인지와 관계없이 판매 수수료만 비교해 볼까요?
c1.emergency.warnings|대피 안내가 있으면 이동이 어려운 사람도 같은 경로를 반드시 이용할 수 있죠?|이동이 어려운 사람은 대피 대상에서 제외했다고 안내하면 되나요?
c1.partner_family.identity|우리 며느리라는 말은 언제나 소속만 뜻하니 역할의 부담은 전혀 없어요.|우리 며느리라는 말을 들었으니 가족들이 저를 배제한다는 게 확실해요.
c1.partner_family.fairness|명절에 눈에 보이는 일만 세면 보이지 않는 일의 분담도 알 수 있겠죠?|명절에는 보이지 않는 일을 누가 했는지와 관계없이 모두 같은 양을 했다고 볼까요?
c1.theme_park_date.return|어, 오늘은 이 놀이기구가 운행하네. 타고 싶지 않았는데 다행이야.|오늘은 운행하지 않는다고 내가 직접 정했어. 처음부터 탈 생각은 없었어.
c1.theme_park_date.uncertainty|저 동전을 모두 모아서 직원들 커피를 사 주기로 공식적으로 약속했어.|저 동전이 모두 직원들 돈이라는 걸 확인했으니 바로 가져다주면 돼.
c1.theme_park_date.reflection|놀이공원에서 크게 웃고 소리치면 누구나 반드시 스트레스가 완전히 없어져.|놀이공원에서는 조용히 있어야만 스트레스가 풀린다는 사실이 증명됐어.
'''

SCENE_OPTIONS += '''
c2.weather.framing|기후 적응 성공이라는 표현을 쓰면 앞으로 어떤 손실도 없다는 뜻인가요?|기후 적응에 실패한 지역만 조사하면 성공 기준은 따로 정하지 않아도 될까요?
c2.mood.empathy|상대의 선택을 바꾸려면 어떤 근거를 제시해야 할까요?|제 선택에 찬성하는 사람만 만나도 괜찮을까요?
c2.mood.housing|기존 계약과 신규 계약은 조건이 같으니 월세 자료에서 구분하지 않아도 돼요.|기존 계약과 신규 계약의 차이는 월세가 오를 때만 생긴다는 뜻인가요?
c2.weekend.costs|주말 노동에 자율적이라는 이름을 붙이면 거절의 불이익도 사라지나요?|주말 노동의 거절 비용 대신 주말 교통비만 계산하면 충분할까요?
c2.food.assumptions|합리적 가격이라는 말은 소득과 시간 비용이 누구에게나 같다는 사실을 보여 주나요?|소득과 시간 비용을 빼고 가격 숫자만 비교하면 누구에게나 합리적인가요?
c2.daily.fairness|결과가 좋으므로 절차가 불공정해도 그 결정을 그대로 받아들여야 해요.|절차가 공정하면 어떤 결과가 나와도 평가할 필요가 없을까요?
c2.daily.appeal|자동 심사에 이의를 제기하려는 사람에게 결과를 다시 읽어 주기만 하면 될까요?|자동 심사 결과를 바꾸지 않으려면 이의 절차를 어디에 숨겨야 할까요?
c2.daily.autonomy|안전을 위한 감시라면 범위를 제한하는 기준은 필요 없겠죠?|감시를 시작했다는 이유만으로 안전이 확보됐다고 발표해도 될까요?
c2.daily.accountability|AI가 틀렸을 때 회사와 공급업체 중 누가 더 빠르게 계산했는지 비교할까요?|AI가 자동으로 판단했으니 회사와 공급업체 모두 설명할 필요는 없겠죠?
c2.daily.framing|취업률만 높으면 통합의 다른 조건도 모두 충족됐다고 봐야 할까요?|통합의 성공 여부와 관계없이 취업률 발표 시기만 앞당길까요?
c2.screen.context|두 기사가 같은 사건을 다뤘으니 관점과 인상도 같아야 하는 거죠?|두 기사의 제목을 같게 바꾸면 보도 내용의 차이도 없어질까요?
c2.music.power|플랫폼이 발견 기회를 제공하면 추천에 대한 권력은 더 이상 없는 걸까요?|추천 권력을 설명하려면 발견 가능성이라는 말만 반복하면 충분할까요?
c2.hobby.sanctions|계정이 자동으로 정지되면 다시 가입하는 데 돈이 얼마나 드나요?|자동 계정 정지의 사유를 공개하지 않기로 이미 결정한 건가요?
c2.travel.limits|관광지 수용력은 방문객 숫자만으로 정하면 되고 주민 생활권은 고려할 필요가 없어요.|주민 생활권을 고려했다면 관광객 수에는 제한을 둘 수 없는 건가요?
c2.work_study.dissent|다수안이 채택됐으니 회의록에서 소수 의견은 삭제하는 게 좋겠죠?|소수 의견을 남기려면 다수안 채택부터 무효로 해야 할까요?
c2.work_study.interpretation|결말이 열려 있으면 어떤 해석이든 작품의 근거와 관계없이 옳을까요?|결말이 열려 있는 작품은 해석을 전혀 해서는 안 되는 걸까요?
c2.work_study.automation|자동 결정의 근거는 지금 지워 두고 나중에 결과만 기록하면 될까요?|자동 결정이 빨랐다는 사실만 남기면 그 판단 이유도 추적할 수 있을까요?
c2.work_study.policy|그 기사에서 통합 성공을 측정했다는 이유만으로 지표는 더 볼 필요 없겠죠?|통합에 성공했다는 기사의 제목을 누가 먼저 공유했어요?
c2.family.responsibility|저출생을 경쟁력 위기로만 부르면 개인의 삶은 어떤 목적에서도 자유로워지나요?|경쟁력 수치가 높아지면 저출생 논의에 개인의 삶을 포함할 필요가 없을까요?
c2.health.classification|건강 앱이 위험군으로 분류했으니 누구도 그 판단을 검토할 수 없나요?|위험군 분류를 받은 사람은 언제 앱을 설치했는지만 확인하면 되나요?
c2.kpop.norms|그 표현을 많이 쓰니까 공동체 안에서도 문제가 없다고 확정된 건가요?|그 표현이 문제라는 설명 없이도 사람들이 같은 이유로 반대한다고 보면 될까요?
c2.kpop.boundaries|그 발표에서 진짜 팬이라는 기준에 맞는 사람은 모두 같은 나이였어요?|진짜 팬이라는 말을 쓴 이상 누가 정했는지는 따질 필요 없겠죠?
c2.dating.perspective|그 이야기를 가장 먼저 들은 사람은 누구였다고 하세요?|그 이야기는 누구의 관점과도 관계없는 완전히 중립적인 기록이라고 확정됐나요?
c2.interview.bias|잠재력이라는 기준이 있으면 평가자와 닮은 사람을 선호할 가능성은 없어지나요?|평가자와 지원자가 닮았는지는 묻지 말고 잠재력 점수만 높일까요?
c2.job_hunting.accountability|보조 도구라고 부르기만 하면 책임을 지는 주체도 없어지는 건가요?|자동 결정이 보조 도구로 바뀌면 처리 속도만 달라지는지 측정할까요?
c2.moving.affordability|감당 가능한 집은 모든 가구의 지출 구조가 같다는 뜻으로 정의됐나요?|감당 가능한 집이라는 이름이 있으면 실제 지출은 확인하지 않아도 될까요?
c2.hospital.consent|진료 우선순위 알고리즘의 오류가 났을 때 병원과 공급자는 누가 더 빨랐는지만 비교하나요?|알고리즘이 자동으로 판단했으니 병원과 공급자 모두 오류를 설명하지 않아도 되나요?
c2.transport.distribution|혼잡 요금은 이동 대안이 적은 사람에게도 언제나 같은 선택권을 보장하나요?|혼잡 요금이 걷혔다는 사실만으로 교통 부담은 모두 해소됐다고 볼까요?
c2.shopping.choice|개인화 가격을 맞춤 혜택이라고 부르는 대신 모든 고객에게 같은 가격을 적용할까요?|맞춤 혜택이라는 이름을 유지하려면 개인화 가격의 비교 기준은 숨겨도 될까요?
c2.phone.remedy|자동으로 계산된 요금에 이의를 넣으면 결과를 자동으로 한 번 더 보내나요?|자동 계산된 요금은 사람이 검토하지 않기로 이미 합의한 건가요?
c2.emergency.power|비상 권한에 종료 조건이 없으면 예외는 어떻게 저절로 사라지나요?|비상 권한이 오래 유지돼도 상시 제도가 될 가능성은 없는 건가요?
c2.partner_family.decisions|결정을 내리는 사람과 발표하는 사람이 같다는 게 확실한데, 그대로 기록할까요?|결정을 전달한 사람이 언제나 혼자 결정했다고 보는 데 동의하시나요?
c2.partner_family.authorship|제 이름 대신 역할로만 불려도 제 경험이 모두 똑같이 기억될까요?|몇 년 뒤에 역할을 바꾸면 지금까지 쓴 제 이름도 반드시 사라질까요?
c2.theme_park_date.sharedjoy|곰곰이 생각해 보니 사람들은 웃음과 설렘보다 놀이기구의 수만 보고 오는 게 확실해.|사람들이 설레 보이기는 해도 웃음이 없으니 놀이공원을 좋아할 이유가 전혀 없는 것 같아.
c2.theme_park_date.anticipation|무서운 줄 알면서 다시 타고 싶은 걸 보면, 공포가 끝난 뒤보다 공포 자체만 즐기는 게 확실해.|다시 타고 싶은 마음은 있지만, 공포가 끝난 뒤의 해방감과는 전혀 관계없다는 걸 이미 확인했어.
c2.theme_park_date.sharedmemory|유령의 집을 포기한 게 아쉬우니까, 네가 싫어해도 억지로 같이 가야 데이트가 의미 있을 것 같아.|서로 즐길 것을 고르는 건 중요하지 않고, 내가 가고 싶은 곳을 다 가야 좋은 데이트라고 생각해.
'''

# These are semantic neighbors, not alternatives judged wrong merely because of
# wording. Do not put members of one cluster into the same choice question.
EQUIVALENT = [
    {'smalltalk_a1_0042', 'smalltalk_a1_0089'},
    {'smalltalk_c1_0033', 'smalltalk_c1_0041', 'smalltalk_c1_0062'},
    {'smalltalk_c2_0041', 'smalltalk_c2_0062'},
    {'smalltalk_b1_0006', 'smalltalk_b1_0018', 'smalltalk_b2_0006'},
    {'smalltalk_b1_0041', 'smalltalk_b2_0041', 'smalltalk_b2_0100'},
    {'smalltalk_c1_0040', 'smalltalk_c1_0044'},
    {'smalltalk_c2_0039', 'smalltalk_c2_0044'},
    {'smalltalk_a1_0009', 'smalltalk_a2_0008', 'smalltalk_b1_0008'},
    {'smalltalk_a1_0004', 'smalltalk_b1_0003'},
    {'smalltalk_a2_0007', 'smalltalk_b1_0007'},
    {'smalltalk_a2_0027', 'smalltalk_b1_0027'},
    {'smalltalk_a1_0054', 'smalltalk_b2_0043'},
]

NEIGHBORS = [
    {'weather', 'travel', 'weekend', 'transport'},
    {'mood', 'health', 'hospital', 'daily'},
    {'food', 'shopping'},
    {'screen', 'music', 'kpop', 'hobby'},
    {'family', 'partner_family', 'dating'},
    {'work_study', 'job_hunting', 'interview', 'phone'},
    {'moving', 'daily', 'shopping', 'transport'},
    {'emergency', 'hospital', 'transport', 'phone'},
    {'theme_park_date', 'travel', 'weekend'},
]

# Approved source corrections, also asserted below to prevent source/catalog drift.
# These retain uncertainty/force where the former translation weakened it.
SOURCE_TRANSLATION_CORRECTIONS = {
    'smalltalk_a1_0003': {'de': 'Ich bin heute gut gelaunt.'},
    'smalltalk_c1_0005': {
        'de': 'Der Aufzug ist außer Betrieb. Welche Alternative sollten wir jemandem nennen, dem Treppensteigen schwerfällt?',
        'en': 'The elevator has stopped. What alternative should we suggest to someone who has difficulty using the stairs?',
    },
    'smalltalk_c2_0049': {
        'de': 'Wessen Einkommen und Zeitkosten setzt ein als angemessen bezeichneter Preis voraus?',
        'en': 'Whose income and time costs does a price described as reasonable assume?',
    },
    'smalltalk_c2_0067': {
        'de': 'Verschwindet die Möglichkeit von Diskriminierung, wenn personalisierte Preise als maßgeschneiderte Vorteile bezeichnet werden?',
        'en': 'Does the possibility of discrimination disappear when personalized pricing is called a tailored benefit?',
    },
    'smalltalk_c2_0077': {
        'en': 'Thinking it over, I feel I can understand why people like coming to amusement parks. There is laughter everywhere, and everyone looks excited and happy.',
    },
}

def meaning(p):
    for lang, expected in SOURCE_TRANSLATION_CORRECTIONS.get(p['id'], {}).items():
        assert p[lang] == expected, f'Source correction was lost: {p["id"]}.{lang}'
    return {lang: p[lang] for lang in ('ko', 'de', 'en')}

def same_meaning(a, b):
    if a['ko'] == b['ko'] or any({a['id'], b['id']} <= group for group in EQUIVALENT):
        return True
    # A conservative lexical guard supplements the editorial equivalence list.
    return any(difflib.SequenceMatcher(None, a[k], b[k]).ratio() > .73 for k in ('ko', 'de', 'en'))

def near_topic(a, b):
    return a == b or any({a, b} <= group for group in NEIGHBORS)

def alternatives(p, phrases, excluded=()):
    """Rank reviewed source contrasts; never turn free paraphrases into errors.

    The question asks for the meaning of the whole quoted utterance, not for any
    conversationally possible reply. Thus other true statements remain distinct
    meanings; source relationshipContext has no role in answer selection.
    """
    levels = list(CAP)
    candidates = []
    for candidate in phrases:
        if candidate['id'] == p['id'] or candidate['id'] in excluded:
            continue
        if not near_topic(p['category'], candidate['category']):
            continue
        distance = abs(levels.index(p['level']) - levels.index(candidate['level']))
        if distance > 1:
            continue
        if not .35 <= len(candidate['ko']) / len(p['ko']) <= 2.8:
            continue
        if same_meaning(p, candidate):
            continue
        lexical = difflib.SequenceMatcher(None, p['ko'], candidate['ko']).ratio()
        score = (5 * (p['category'] == candidate['category']) + 5 * (distance == 0)
                 + 3 * (p['ko'].endswith('?') == candidate['ko'].endswith('?')) + lexical)
        candidates.append((-score, candidate['id'], candidate))
    selected = []
    for _, _, candidate in sorted(candidates):
        if all(not same_meaning(candidate, other) for other in selected):
            selected.append(candidate)
        if len(selected) == 2:
            return selected
    raise ValueError(f'Need two distinct topical contrasts for {p["id"]}')

# At higher levels, selected questions test an inference or pragmatic distinction
# directly instead of merely matching a translation. Each contrast is authored.
# source ID | prompt | answer | distractor | distractor | explanation (KO~DE~EN)
NUANCE = '''
smalltalk_c1_0078|운행 여부에 대한 화자의 근거는 어떻게 표현되나요?~Wie stellt die Person ihr Wissen über den Betrieb dar?~How does the speaker present their knowledge about the ride's operation?|상황을 보고 운행하지 않는 듯하다고 추측해요.~Sie schließt aus der Situation, dass die Attraktion wohl nicht fährt.~They infer from the situation that the ride seems not to be running.|직원에게 들은 공식 발표를 인용해요.~Sie zitiert eine offizielle Mitteilung des Personals.~They quote an official announcement from staff.|직접 운행 중단을 결정했다고 말해요.~Sie sagt, sie habe die Stilllegung selbst beschlossen.~They say they personally decided to stop the ride.|‘-나 봐’는 여기서 추측을 나타내요. 직원에게 들었다거나 운행을 결정했다는 내용은 없어요.~Mit -나 봐 wird hier eine Vermutung ausgedrückt. Eine Auskunft des Personals oder eine eigene Entscheidung wird nicht genannt.~Here, -나 봐 marks an inference. The speaker does not mention being told by staff or deciding to close the ride.
smalltalk_c1_0080|크리스마스 마켓이 예쁘다는 정보는 어디서 왔나요?~Woher stammt die Aussage über den schönen Weihnachtsmarkt?~Where does the information about the Christmas market being beautiful come from?|다른 데서 들은 말을 전해요.~Die Person gibt etwas Gehörtes weiter.~The speaker passes on something they have heard.|화자가 직접 본 경험을 말해요.~Die Person berichtet von einem eigenen Besuch.~The speaker describes seeing it personally.|겨울에 예뻐질 거라는 예측만 해요.~Die Person sagt nur voraus, dass er im Winter schön werden wird.~The speaker only predicts that it will become beautiful in winter.|‘예쁘대’는 전언이고, 뒤의 말은 겨울에 다시 오자는 제안이에요. 직접 봤다고 단정하지 않아요.~예쁘대 kennzeichnet eine fremde Aussage. Danach folgt der Vorschlag, im Winter wiederzukommen; ein eigener Besuch wird nicht behauptet.~예쁘대 marks reported information, followed by an invitation to return in winter. It does not claim firsthand observation.
smalltalk_c1_0082|직원들 커피값 이야기는 어떤 기능을 하나요?~Welche Funktion hat die Bemerkung über Kaffee fürs Personal?~What is the function of the remark about coffee for the staff?|가정으로 웃음을 유도하고 농담이라고 밝혀요.~Eine hypothetische Bemerkung soll amüsieren und wird als Witz markiert.~It uses a hypothetical idea for humor and explicitly marks it as a joke.|동전을 모으겠다는 약속을 해요.~Die Person verspricht, die Münzen einzusammeln.~It promises to collect the coins.|동전이 직원들 소유라고 확인해요.~Die Person bestätigt, dass die Münzen dem Personal gehören.~It confirms that the coins belong to the staff.|‘모으면’이라는 가정과 ‘농담이야’가 있어요. 수집 계획이나 소유권 확인으로 읽으면 의미가 달라져요.~Die Bedingung 모으면 und die Kennzeichnung als Witz schließen eine feste Zusage oder Eigentumsfeststellung aus.~The conditional 모으면 and explicit joke marker make this neither a firm undertaking nor a statement of ownership.
smalltalk_c1_0083|앞자리에 대한 판단은 어떻게 열려 있나요?~Wie bleibt die Einschätzung der ersten Reihe offen?~How does the assessment of the front row remain open?|잘 보이는 점이 더 무섭게도, 덜 무섭게도 느껴질 수 있어요.~Die freie Sicht könnte mehr oder weniger Angst auslösen.~The clear view could make it feel either more or less frightening.|앞자리는 반드시 더 무섭다고 결론 내려요.~Die erste Reihe wird eindeutig als beängstigender bewertet.~The speaker concludes that the front is definitely scarier.|잘 보이므로 두려움이 완전히 사라진다고 말해요.~Die freie Sicht beseitigt nach dieser Aussage jede Angst.~The speaker says the view removes fear completely.|두 개의 ‘-것 같기도’가 상반된 가능성을 함께 남겨요. 어느 쪽도 확정하지 않아요.~Die beiden Formulierungen mit -것 같기도 lassen gegensätzliche Möglichkeiten nebeneinander stehen.~The two -것 같기도 clauses keep contrasting possibilities open rather than settling on either.
smalltalk_c1_0085|스트레스가 풀리는 이유를 얼마나 확신하나요?~Wie sicher wird die Erklärung für den Stressabbau dargestellt?~How certain is the explanation for stress relief?|크게 웃고 소리칠 수 있어서일지도 모른다고 추측해요.~Lautes Lachen und Schreien werden als mögliche Erklärung vermutet.~Laughing and screaming freely are proposed as a possible explanation.|큰 소리가 스트레스를 없앤다는 연구를 인용해요.~Eine Studie wird als Nachweis für die Wirkung lauter Geräusche zitiert.~A study is cited as proof that loud sounds remove stress.|모든 방문객에게 같은 효과가 있다고 단정해요.~Die Wirkung wird für alle Besucher als gleich dargestellt.~The speaker asserts the same effect for every visitor.|‘-는지도 모르겠어’는 이유에 대한 추측이에요. 연구 근거나 모든 사람에 대한 보장은 말하지 않아요.~Die Wendung -는지도 모르겠어 markiert eine Vermutung über den Grund, keinen Forschungsbeleg und keine Garantie für alle.~-는지도 모르겠어 makes the causal explanation tentative; it does not cite research or guarantee the effect for everyone.
smalltalk_c1_0087|나이 탓을 하는 자신을 어떻게 해석하나요?~Wie deutet die Person ihre eigene Erklärung mit dem Alter?~How does the speaker interpret their own tendency to blame age?|놀랐다는 사실을 인정하기 싫어서일 수 있다고 봐요.~Vielleicht möchte sie nicht zugeben, wie erschrocken sie war.~They think they may be reluctant to admit being scared.|나이 때문에 어지럽다는 의학적 진단을 확인해요.~Sie bestätigt eine medizinische Diagnose für altersbedingten Schwindel.~They confirm a medical diagnosis of age-related dizziness.|상대가 나이를 비난해서 화났다고 말해요.~Sie sagt, sie sei wegen einer Altersbemerkung der anderen Person wütend.~They say they are angry because the other person criticized their age.|‘인정하기 싫은가 봐’는 자기 태도에 대한 추측이에요. 어지럼증의 원인을 의학적으로 확정하지 않아요.~인정하기 싫은가 봐 deutet die eigene Haltung vorsichtig; eine medizinische Ursache wird nicht festgestellt.~인정하기 싫은가 봐 is a tentative interpretation of the speaker's attitude, not a medical explanation of dizziness.
smalltalk_c2_0078|놀이공원에 오는 이유를 어떻게 제시하나요?~Wie wird der mögliche Grund für einen Parkbesuch formuliert?~How is the possible reason for visiting the park presented?|놀이기구 외에 일상과 다른 모습을 경험하려는 이유도 있을 수 있다고 봐요.~Neben den Fahrgeschäften könnte auch das Erleben einer anderen Seite des eigenen Ichs eine Rolle spielen.~Besides rides, experiencing a different side of oneself might also be a reason.|모든 사람이 자기 삶을 싫어해서 온다고 단정해요.~Alle kämen eindeutig deshalb, weil sie ihr Leben ablehnten.~Everyone is said to come because they dislike their life.|놀이기구는 방문 이유가 전혀 아니라고 확정해요.~Fahrgeschäfte werden als Besuchsgrund vollständig ausgeschlossen.~Rides are completely ruled out as a reason to visit.|‘만’과 ‘아닐까’가 중요해요. 기존 이유에 다른 가능성을 더하며, 모든 사람의 동기를 단정하지 않아요.~만 und 아닐까 erweitern eine Erklärung um eine Möglichkeit. Sie legen nicht die Motive aller Besucher fest.~만 and 아닐까 add a possible explanation without claiming to know every visitor's motives.
smalltalk_c2_0080|다시 타고 싶은 이유에 대한 해석은 무엇인가요?~Wie wird der Wunsch nach einer weiteren Fahrt gedeutet?~How is the desire for another ride interpreted?|공포 자체보다 공포 뒤의 해방감을 즐기는 것일 수 있어요.~Vielleicht reizt eher die Erleichterung danach als die Angst selbst.~Perhaps the release afterward is enjoyed more than the fear itself.|다시 타고 싶다는 것은 처음부터 무섭지 않았다는 증거예요.~Der Wunsch beweist, dass von Anfang an keine Angst bestand.~Wanting another ride proves there was no fear in the first place.|공포 자체를 더 좋아한다는 결론이 확정됐어요.~Es steht fest, dass die Angst selbst stärker geschätzt wird.~It is certain that fear itself is what is enjoyed more.|‘-지도 모르겠어’는 가설을 남겨요. 무서웠다는 전제를 지우지 않고, 즐거움의 시점을 다시 해석해요.~Die Aussage bleibt eine Vermutung. Sie bestreitet die Angst nicht, sondern verortet den Genuss möglicherweise in der Zeit danach.~The statement remains tentative. It does not deny the fear; it suggests that enjoyment may lie in what follows it.
smalltalk_c2_0082|일상의 불확실성에 관한 마지막 말은 무엇을 나타내나요?~Was drückt der letzte Gedanke über Unsicherheit im Alltag aus?~What does the final thought about uncertainty in everyday life express?|일상에서도 그렇게 받아들일 수 있으면 좋겠다는 바람이에요.~Es ist der Wunsch, Unsicherheit auch im Alltag so annehmen zu können.~It expresses a wish to welcome uncertainty that way in everyday life too.|모든 불확실성을 이미 즐겁게 받아들인다는 보고예요.~Es ist ein Bericht darüber, dass jede Unsicherheit bereits Freude macht.~It reports that every uncertainty is already welcomed happily.|상대에게 불안을 느끼지 말라는 명령이에요.~Es ist eine Aufforderung, keine Unsicherheit mehr zu empfinden.~It orders the other person not to feel anxious.|‘-수 있다면 좋을 텐데’는 조건을 둔 바람이에요. 일상에서 이미 실현됐다는 주장이나 상대를 향한 명령이 아니에요.~Die Bedingung mit dem Wunsch sagt weder, dass es im Alltag schon gelingt, noch fordert sie es von der anderen Person.~The conditional wish neither claims this already happens in daily life nor demands it of the listener.
smalltalk_c2_0083|화자는 아쉬움과 상대의 취향을 어떻게 함께 다루나요?~Wie verbindet die Person Enttäuschung mit den Vorlieben des Gegenübers?~How does the speaker balance disappointment and the other person's preferences?|아쉬움은 인정하면서 함께 즐길 선택을 더 중요하게 봐요.~Sie erkennt ihre Enttäuschung an, gewichtet gemeinsames Vergnügen aber höher.~They acknowledge disappointment while valuing a choice both can enjoy more highly.|아쉬움이 없었으므로 포기한 선택에는 의미가 없다고 봐요.~Ohne Enttäuschung habe der Verzicht keine Bedeutung.~They say there was no disappointment, so giving it up had no significance.|상대가 싫어해도 함께 해야 좋은 데이트라고 봐요.~Ein gutes Date verlange gemeinsames Mitmachen trotz Abneigung.~They say a good date requires doing it together despite the other's dislike.|‘아쉽기는 하지만’은 감정을 없애지 않아요. 뒤에서 강요보다 함께 즐기는 것을 우선하는 판단이 이어져요.~아쉽기는 하지만 lässt die Enttäuschung bestehen. Danach wird gemeinsames Vergnügen gegenüber Druck bevorzugt.~아쉽기는 하지만 preserves the disappointment, then prioritizes shared enjoyment over pressure.
smalltalk_c2_0084|운행 중단을 바라보는 관점은 어떻게 바뀌나요?~Wie verändert sich der Blick auf die geschlossene Attraktion?~How does the view of the closed ride change?|처음의 큰 아쉬움을 나중에는 다음 만남의 이유로 다시 봐요.~Die anfängliche Enttäuschung wird später als Anlass für ein Wiedersehen gedeutet.~Initial disappointment is later reframed as a reason for another meeting.|처음부터 다음 약속을 만들려고 운행 중단을 계획했어요.~Die Schließung wurde von Anfang an geplant, um ein Wiedersehen zu erreichen.~The closure was planned from the start to create another date.|하루를 망쳤다는 판단을 끝까지 그대로 유지해요.~Die Bewertung als verdorbener Tag bleibt unverändert.~The judgment that the day was ruined remains unchanged.|‘보는 순간’과 ‘지금 생각하면’이 관점의 시간을 나눠요. 나중에 의미를 다시 붙인 것이지 처음부터 세운 계획은 아니에요.~Der erste Moment und der jetzige Rückblick werden getrennt. Die neue Bedeutung entsteht nachträglich, nicht durch einen ursprünglichen Plan.~The initial moment and the later reflection are distinct. The new meaning is retrospective, not evidence of an original plan.
smalltalk_c2_0085|사진에 대한 평가에서 무엇이 바뀌나요?~Was verändert sich in der Bewertung des Fotos?~What changes in the evaluation of the photo?|잘 나온 모습만 남기려던 생각에서 솔직한 감정의 기록도 가치 있을 수 있다고 봐요.~Neben schmeichelhaften Bildern könnte auch ein ehrlicher Gefühlsausdruck wertvoll sein.~Beyond flattering images, an honest record of emotion might also be valuable.|잘못 나온 사진은 모두 좋은 사진보다 낫다고 단정해요.~Jedes misslungene Foto sei grundsätzlich besser als ein gelungenes.~Every bad photo is declared better than every good one.|예쁘게 나온 사진을 원했던 마음은 처음부터 없었다고 해요.~Der Wunsch nach schmeichelhaften Fotos habe nie bestanden.~The speaker says they never wanted flattering photos in the first place.|‘싶어 했는데’는 이전 선호를 인정하고 ‘-일 수도’는 새로운 가능성을 열어요. 모든 사진에 대한 법칙을 만들지 않아요.~Die frühere Vorliebe bleibt erhalten; -일 수도 öffnet eine neue Möglichkeit, keine allgemeine Fotoregel.~The earlier preference is acknowledged, while -일 수도 opens a new possibility rather than a universal rule about photos.
smalltalk_c2_0086|즐거웠던 하루의 이유를 어떻게 정리하나요?~Wie wird erklärt, warum der Tag schön war?~How does the speaker explain why the day was enjoyable?|불편한 일도 있었지만 함께 겪은 점이 좋았던 이유인 듯해요.~Trotz Unannehmlichkeiten scheint das gemeinsame Erleben den Tag schön gemacht zu haben.~Despite inconveniences, sharing the experience seems to have made the day good.|불편한 일이 하나도 없었기 때문에 완벽한 하루였어요.~Der Tag war perfekt, weil es keinerlei Unannehmlichkeiten gab.~The day was perfect because there were no inconveniences.|기다리고 젖은 일이 모든 사람에게 언제나 즐겁다는 뜻이에요.~Warten und Nasswerden seien für alle immer angenehm.~Waiting and getting wet are said to be enjoyable for everyone at all times.|‘-는데도’가 불편함과 즐거움의 공존을 남기고 ‘-였나 봐’는 함께한 경험에 대한 해석을 제시해요.~Trotz -는데도 bleiben Mühen und Freude nebeneinander bestehen. -였나 봐 deutet das gemeinsame Erlebnis als Grund.~-는데도 preserves both inconvenience and enjoyment; -였나 봐 offers shared experience as the inferred reason.
smalltalk_c1_0017|높은 찬성 비율만으로 결론을 내리기 어려운 이유는 무엇인가요?~Warum reicht die hohe Zustimmungsquote hier nicht für eine Schlussfolgerung?~Why is the high approval rate not sufficient for a conclusion here?|표본이 치우쳤다면 결과를 일반화할 범위가 제한될 수 있어요.~Eine verzerrte Stichprobe kann die Verallgemeinerbarkeit begrenzen.~A biased sample may limit how broadly the result can be generalized.|찬성한 사람들은 실제 의견이 없다는 뜻이에요.~Die Zustimmenden hätten keine wirkliche Meinung.~It means those who agreed have no real opinion.|찬성 비율이 높을수록 조사 결과가 반드시 틀려요.~Je höher die Zustimmung, desto sicherer ist das Ergebnis falsch.~The higher the approval, the more certain the result is false.|문장은 표본의 치우침을 조건으로 결론의 범위를 묻고 있어요. 찬성 의견 자체를 거짓이라고 말하지 않아요.~Die Frage betrifft die Reichweite einer Schlussfolgerung bei verzerrter Auswahl, nicht die Echtheit einzelner Meinungen.~The question concerns the scope of inference under sampling bias, not whether individual opinions are genuine.
smalltalk_c1_0018|상관관계가 보인 뒤 제안하는 다음 단계는 무엇인가요?~Welcher Schritt wird nach dem Erkennen einer Korrelation vorgeschlagen?~What next step is proposed after observing a correlation?|다른 설명이 가능한지 먼저 살펴봐요.~Zunächst werden alternative Erklärungen geprüft.~First examine whether other explanations are possible.|상관관계를 확인했으니 인과관계도 확정해요.~Mit der Korrelation wird auch die Ursache als erwiesen angesehen.~Treat causation as confirmed because correlation has been observed.|다른 설명이 있을 수 있으니 모든 자료를 버려요.~Wegen möglicher Alternativen werden sämtliche Daten verworfen.~Discard all the data because alternatives may exist.|‘-아도’는 상관관계를 인정하면서도 추가 검토가 필요하다는 뜻이에요. 자료를 버리거나 인과를 확정하라는 말이 아니에요.~Die Korrelation wird anerkannt, reicht aber nicht ohne Prüfung weiterer Erklärungen. Weder Datenverwerfung noch ein Kausalbeweis wird verlangt.~The correlation is acknowledged, but further explanations must be considered; neither discarding the data nor declaring causation follows.
smalltalk_c2_0018|이 문장에서 처리 속도는 어떤 근거로 취급되나요?~Wie wird Verarbeitungsgeschwindigkeit als Begründung eingeordnet?~How is processing speed treated as a justification?|인간의 재검토를 생략하기에는 충분하지 않은 근거예요.~Sie reicht allein nicht aus, um auf menschliche Nachprüfung zu verzichten.~It is insufficient on its own to justify omitting human review.|빠르면 어떤 인간의 검토도 필요 없다는 충분한 근거예요.~Hohe Geschwindigkeit macht jede menschliche Prüfung überflüssig.~Speed is sufficient to make all human review unnecessary.|빠른 처리 자체를 금지해야 한다는 근거예요.~Sie ist ein Grund, schnelle Verarbeitung an sich zu verbieten.~It is a reason to prohibit fast processing itself.|‘이유만으로’는 속도의 충분성을 제한해요. 자동 처리나 빠른 속도 자체를 금지하는 문장은 아니에요.~이유만으로 begrenzt die Begründungskraft der Geschwindigkeit. Schnelle oder automatische Bearbeitung wird nicht grundsätzlich verboten.~이유만으로 limits the sufficiency of speed as a reason; it does not prohibit fast or automated processing itself.
smalltalk_c2_0076|동의와 관련해 어떤 문제를 살피고 있나요?~Welches Problem wird trotz Einwilligung untersucht?~What concern is examined even where consent exists?|권력 차이 때문에 거절이 실질적으로 어려울 수 있어요.~Ein Machtgefälle kann eine tatsächliche Ablehnung erschweren.~A power imbalance can make refusal difficult in practice.|동의 표시가 있으면 거절의 자유도 언제나 보장돼요.~Eine Zustimmung garantiert stets die Freiheit zur Ablehnung.~An indication of consent always guarantees freedom to refuse.|권력 차이가 있으면 모든 동의는 법적으로 무효라고 확정해요.~Jede Zustimmung bei Machtgefälle wird rechtlich für unwirksam erklärt.~All consent under unequal power is declared legally invalid.|‘동의가 있어도’는 형식적 동의와 실제 거절 가능성을 구별해요. 특정한 법적 무효 판단을 내리지는 않아요.~Die Frage trennt formale Zustimmung von praktisch möglicher Ablehnung, ohne ein konkretes Rechtsurteil zu fällen.~The question distinguishes formal consent from practical freedom to refuse without making a specific legal ruling.
smalltalk_b2_0125|소지품 보관 지시의 근거는 어디에 있나요?~Worauf stützt sich die Aufforderung zum Verstauen der Gegenstände?~What is the source of the instruction to store belongings?|안내문에 쓰인 내용을 근거로 확인해요.~Die Person bezieht sich auf einen schriftlichen Hinweis.~The speaker refers to a written notice.|화자가 직접 새 규칙을 만들어요.~Die Person erlässt selbst eine neue Regel.~The speaker creates a new rule themselves.|앞서 물건을 잃어버렸다고 고백해요.~Die Person berichtet vom eigenen Verlust eines Gegenstands.~The speaker admits having lost an item earlier.|‘안내문에 … 쓰여 있어’가 출처예요. 주머니 확인 질문이 상대의 과거 분실을 증명하지는 않아요.~Die Quelle ist der schriftliche Hinweis. Die Taschenkontrolle beweist keinen früheren Verlust.~The source is the written notice. Asking about pockets does not establish that the other person lost anything earlier.
smalltalk_b2_0128|사진에 대한 태도는 무엇인가요?~Welche Haltung zeigt die Person zum Foto?~What is the speaker's attitude toward the photo?|웃긴 사진임은 인정하지만 자신의 모습 때문에 인화는 원하지 않아요.~Sie findet das Foto lustig, möchte es wegen des eigenen Aussehens aber nicht ausdrucken lassen.~They acknowledge it is funny but do not want a print because of how they look.|사진이 웃겨서 꼭 인화하고 싶어 해요.~Weil das Foto lustig ist, will sie es unbedingt ausdrucken lassen.~They definitely want a print because it is funny.|다른 사람이 못생기게 나와서 사진을 삭제하라고 명령해요.~Sie verlangt die Löschung, weil die andere Person unvorteilhaft aussieht.~They order it deleted because the other person looks bad.|‘사진은 … 웃기지만’과 ‘나는 … 뽑고 싶지는 않아’를 함께 읽어요. 내 모습에 대한 평가와 인화 거절이지 상대 외모의 평가가 아니에요.~Der Kontrast betrifft das eigene Bild und den Wunsch nach einem Ausdruck, nicht das Aussehen des Gegenübers.~The contrast concerns the speaker's own appearance and choice about printing, not a judgment of the other person's appearance.
'''

def nuance_rows():
    result = {}
    for line in NUANCE.strip().splitlines():
        sid, prompt, answer, wrong1, wrong2, explanation = line.split('|')
        assert sid not in result, sid
        result[sid] = dict(prompt=tri(prompt), options=[tri(answer), tri(wrong1), tri(wrong2)], explanation=tri(explanation))
    return result

def scene_options():
    result = {}
    for line in SCENE_OPTIONS.strip().splitlines():
        if line.strip():
            key, a, b = line.split('|')
            assert key not in result, key
            result[key] = [a, b]
    assert len(result) == 207
    return result

def build():
    data = json.loads(SOURCE.read_text(encoding='utf-8'))
    phrases = data['phrases']
    by_id = {p['id']: p for p in phrases}
    nuance = nuance_rows()
    lessons = []
    for row in ROWS.strip().splitlines():
        if not row.strip():
            continue
        level, topic, slug, nums, title, scene = row.split('|')
        ids = [f'smalltalk_{level}_{int(num):04d}' for num in nums.split(',')]
        ps = [by_id[i] for i in ids]
        lesson_id = f'smalltalk.{level}.{topic}.{slug}'
        scene_tri = tri(scene)
        questions = []
        for p in ps:
            options = [p, *alternatives(p, phrases)]
            # Stable rotation avoids an answer-position cue in static exports.
            offset = int(p['id'].split('_')[-1]) % 3
            options = options[offset:] + options[:offset]
            pm = meaning(p)
            questions.append({
                'id': f'{lesson_id}.{p["id"]}.meaning',
                'type': 'choice', 'skill': 'meaning',
                'prompt': {
                    'ko': f'“{p["ko"]}”\n이 말의 전체 뜻과 맞는 것을 고르세요.',
                    'de': f'„{p["ko"]}“\nWelche Bedeutung gibt die ganze Äußerung wieder?',
                    'en': f'“{p["ko"]}”\nWhich meaning matches the whole utterance?',
                },
                'options': [meaning(o) for o in options],
                'correctIndex': options.index(p),
                'explanation': {
                    'ko': f'이 표현의 내용은 “{p["ko"]}”입니다. 시간, 대상, 질문인지 진술인지까지 함께 확인하세요.',
                    'de': f'Gemeint ist: {pm["de"]} Achte auch auf Zeit, Bezug und darauf, ob gefragt oder etwas ausgesagt wird.',
                    'en': f'The meaning is: {pm["en"]} Keep the time, referents and whether this is a question or a statement.',
                },
                'sourceIds': [p['id']], 'audioKo': p['ko'], 'evidenceKo': p['ko'],
            })
            if p['id'] in nuance:
                authored = nuance[p['id']]
                q = questions[-1]
                q['prompt'] = {lang: f'“{p["ko"]}”\n{authored["prompt"][lang]}' for lang in ('ko','de','en')}
                opts = authored['options']
                q['options'] = opts[offset:] + opts[:offset]
                q['correctIndex'] = q['options'].index(opts[0])
                q['explanation'] = authored['explanation']
        anchor = ps[0]
        # Contrast the same scene's intention, time, referent or strength; do not
        # ask learners to eliminate unrelated categories or infer an audience.
        scene_key = f'{level}.{topic}.{slug}'
        scene_distractors = scene_options()[scene_key]
        options = [anchor['ko'], *scene_distractors]
        offset = len(ids) % 3
        options = options[offset:] + options[:offset]
        questions.append({
            'id': f'{lesson_id}.situation', 'type': 'choice', 'skill': 'situation',
            'prompt': {
                'ko': scene_tri['ko'] + '\n이 뜻을 가장 정확히 전하는 표현은 무엇인가요?',
                'de': scene_tri['de'] + '\nWelche Äußerung drückt genau diese Absicht aus?',
                'en': scene_tri['en'] + '\nWhich expression conveys this precise intention?',
            },
            'options': [{lang: o for lang in ('ko', 'de', 'en')} for o in options],
            'correctIndex': options.index(anchor['ko']),
            'explanation': {
                'ko': f'“{anchor["ko"]}” — {scene_tri["ko"]}',
                'de': f'„{anchor["ko"]}“ bedeutet: {meaning(anchor)["de"]}',
                'en': f'“{anchor["ko"]}” means: {meaning(anchor)["en"]}',
            },
            'sourceIds': ids, 'audioKo': anchor['ko'], 'evidenceKo': anchor['ko'],
        })
        lessons.append({
            'id': lesson_id, 'kind': 'smalltalk', 'level': level, 'topicId': topic,
            'title': tri(title),
            'intro': {
                'ko': scene_tri['ko'] + ' 이어지는 표현도 함께 익혀 보세요.',
                'de': scene_tri['de'] + ' Lerne auch die weiteren Ausdrücke dieser Lektion kennen.',
                'en': scene_tri['en'] + ' Explore the other expressions in this lesson too.',
            },
            'contentIds': ids, 'questions': questions,
        })
    return {'version': 1, 'lessons': lessons}

def validate(catalog):
    source = json.loads(SOURCE.read_text(encoding='utf-8'))
    phrases = {p['id']: p for p in source['phrases']}
    counts = collections.Counter()
    lessons = set()
    questions = set()
    topic_levels = set()
    for lesson in catalog['lessons']:
        assert set(lesson) == {'id','kind','level','topicId','title','intro','contentIds','questions'}
        lid = lesson['id']
        assert lid not in lessons, lid
        lessons.add(lid)
        assert lesson['kind'] == 'smalltalk'
        topic_levels.add((lesson['level'], lesson['topicId']))
        ids = lesson['contentIds']
        assert 0 < len(ids) <= CAP[lesson['level']], lid
        for sid in ids:
            assert sid in phrases, sid
            assert phrases[sid]['category'] == lesson['topicId'], sid
            assert phrases[sid]['level'] == lesson['level'], sid
            counts[sid] += 1
        covered = set()
        for item in (lesson['title'], lesson['intro']):
            validate_tri(item)
        for q in lesson['questions']:
            assert set(q) == {'id','type','skill','prompt','options','correctIndex','explanation','sourceIds','audioKo','evidenceKo'}, q['id']
            assert q['id'] not in questions, q['id']
            questions.add(q['id'])
            assert q['type'] == 'choice'
            assert q['skill'] in {'meaning','situation'}
            assert q['sourceIds'] and set(q['sourceIds']) <= set(ids)
            if q['skill'] != 'situation':
                covered.update(q['sourceIds'])
            validate_tri(q['prompt'])
            validate_tri(q['explanation'])
            assert len(q['options']) == 3
            assert 0 <= q['correctIndex'] < len(q['options'])
            for option in q['options']:
                validate_tri(option)
            for lang in ('ko','de','en'):
                assert len({o[lang] for o in q['options']}) == len(q['options']), q['id']
            assert q['audioKo'] == q['evidenceKo']
            assert q['evidenceKo'] in [phrases[s]['ko'] for s in q['sourceIds']]
            correct = q['options'][q['correctIndex']]
            if q['skill'] == 'meaning':
                sid = q['sourceIds'][0]
                expected = nuance_rows().get(sid, {}).get('options', [meaning(phrases[sid])])[0]
                assert correct == expected
            else:
                assert all(value == q['evidenceKo'] for value in correct.values())
        assert covered == set(ids), lid
        assert sum(q['skill'] == 'situation' for q in lesson['questions']) == 1
        assert len(lesson['questions']) == len(ids) + 1
    assert counts == collections.Counter({sid: 1 for sid in phrases}), counts - collections.Counter(phrases)
    expected = {(level, c['id']) for level in CAP for c in source['categories']}
    assert topic_levels == expected, expected - topic_levels
    park = [l['contentIds'] for l in catalog['lessons'] if l['level'] == 'a1' and l['topicId'] == 'theme_park_date']
    assert park == [[f'smalltalk_a1_{i:04d}' for i in group] for group in (range(91,95),range(95,99),range(99,101))]
    return {'expressions': len(counts), 'lessons': len(lessons), 'questions': len(questions),
            'authoredSituationContrasts': len(scene_options()) * 2, 'authoredNuanceQuestions': len(nuance_rows()),
            'topicLevelPairs': len(topic_levels), 'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
            'lessonsByLevel': dict(collections.Counter(l['level'] for l in catalog['lessons']))}

def validate_tri(value):
    assert set(value) == {'ko','de','en'}, value
    for s in value.values():
        assert isinstance(s, str) and s.strip() == s and s and '\ufffd' not in s, value
        assert not any(x in s.lower() for x in ('todo', 'placeholder', 'lorem ipsum')), value

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--review', type=Path, help='Write TSV with every option for semantic audit')
    args = parser.parse_args()
    catalog = build()
    receipt = validate(catalog)
    rendered = json.dumps(catalog, ensure_ascii=False, indent=2) + '\n'
    if args.check:
        assert DEST.read_text(encoding='utf-8') == rendered, 'Catalog differs from authored source'
    else:
        DEST.write_text(rendered, encoding='utf-8')
    if args.review:
        lines = ['question_id\tskill\tcorrect\twrong_1\twrong_2']
        for lesson in catalog['lessons']:
            for q in lesson['questions']:
                correct = q['options'][q['correctIndex']]['ko']
                wrong = [o['ko'] for i,o in enumerate(q['options']) if i != q['correctIndex']]
                lines.append('\t'.join([q['id'],q['skill'],correct,*wrong]))
        args.review.write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print(json.dumps(receipt, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
