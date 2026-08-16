#!/usr/bin/env python3
"""Build the executable productive-assessment catalog from canonical segments.

The segment catalog owns stable identity and provenance. This generator owns
only deterministic rubrics and first-party project material; it never reads or
copies third-party reference pages.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SEGMENTS_PATH = ROOT / "assets" / "data" / "can_do_segments.json"
OUTPUT_PATH = (
    ROOT / "tools" / "content_factory" / "drafts" / "productive_assessments.json"
)

MODE_SNAKE = {
    "guidedProduction": "guided_production",
    "dictation": "dictation",
    "connectedProduction": "connected_production",
    "openWriting": "open_writing",
    "oralProduction": "oral_production",
    "connectedEvidence": "connected_evidence",
}

# Every A1-B2 permanent authority has a first-party authored task,
# deterministic passing fixture, and required meaning slots. There is
# intentionally no title-keyword fallback: a newly published segment must add
# an explicit rubric here or generation fails closed. Per-ID human approval is
# tracked separately and is not implied by this executable contract.
BASIC_SPECS: dict[str, dict[str, Any]] = {
    "segment_a1_01_greetings_hangul": {
        "task": (
            "처음 만난 사람에게 한글로 인사하고 반가움을 정중하게 표현하세요.",
            "Begrüße eine neue Person auf Koreanisch und drücke höflich Freude über das Kennenlernen aus.",
            "Greet a new person in Korean and politely say that you are glad to meet them.",
        ),
        "sample": "안녕하세요. 반갑습니다.",
        "slots": [
            ("greeting", ["안녕하세요", "안녕하십니까"]),
            ("polite_response", ["반갑습니다", "반가워요"]),
        ],
    },
    "segment_a1_02_self_intro_identity": {
        "task": (
            "같은 자기소개를 합니다체, 해요체, 반말의 세 문장으로 바꾸어 쓰세요.",
            "Schreibe dieselbe Selbstvorstellung in drei Sätzen: formell, höflich und vertraut.",
            "Write the same self-introduction in three sentences: formal, polite, and casual.",
        ),
        "sample": "저는 수진입니다. 저는 수진이에요. 나 수진이야.",
        "identityEquality": True,
        "endings": ["야", "이야"],
    },
    "segment_a1_03_topic_subject_particles": {
        "task": (
            "이미 아는 사람은 은/는으로, 새로 밝히는 사람은 이/가로 한 문장에 말하세요.",
            "Markiere die bekannte Person mit 은/는 und die neue Information mit 이/가 in einem Satz.",
            "Use 은/는 for the known person and 이/가 for the newly identified person in one sentence.",
        ),
        "sample": "수진은 학생이고 제가 선생님이에요.",
        "slots": [
            ("topic_particle", ["수진은", "민수는", "저는"]),
            ("subject_particle", ["제가", "친구가", "수진이가"]),
        ],
    },
    "segment_a1_04_order_request_object": {
        "task": (
            "서비스 직원에게 목적어 을/를을 넣어 데우거나 준비해 달라고 정중하게 요청하세요.",
            "Bitte eine Servicekraft höflich, etwas zu erwärmen oder vorzubereiten, und verwende 을/를 am Objekt.",
            "Politely ask service staff to heat or prepare an item, marking the object with 을/를.",
        ),
        "sample": "커피를 데워 주세요.",
        "slots": [
            ("object_particle", ["커피를", "차를", "밥을"]),
            ("polite_request", ["데워 주세요", "준비해 주세요", "가져다주세요"]),
        ],
    },
    "segment_a1_05_numbers_time": {
        "task": (
            "들은 시간 문장을 그대로 받아쓰세요.",
            "Schreibe den gehörten Zeitsatz exakt auf.",
            "Write the time sentence exactly as you hear it.",
        ),
        "sample": "지금 세 시예요.",
        "exact": True,
    },
    "segment_a1_06_transport_directions": {
        "task": (
            "기사에게 목적지를 말하고 그곳으로 가 달라고 정중하게 요청하세요.",
            "Nenne dem Fahrer das Ziel und bitte höflich darum, dorthin zu fahren.",
            "Tell the driver your destination and politely ask to go there.",
        ),
        "sample": "서울역으로 가 주세요.",
        "slots": [
            ("destination", ["서울역으로", "시청으로", "공항으로"]),
            ("direction_request", ["가 주세요", "가 주시겠어요"]),
        ],
    },
    "segment_a1_07_contact_address": {
        "task": (
            "들은 연락처 확인 문장을 그대로 받아쓰세요.",
            "Schreibe den gehörten Satz zur Kontaktbestätigung exakt auf.",
            "Write the contact-confirmation sentence exactly as you hear it.",
        ),
        "sample": "전화번호를 다시 확인해 주세요.",
        "exact": True,
    },
    "segment_a1_08_clarify_repair": {
        "task": (
            "상대의 말을 못 알아들었을 때 다시 천천히 말해 달라고 요청하세요.",
            "Bitte darum, etwas noch einmal langsam zu sagen, wenn du es nicht verstanden hast.",
            "Ask the other person to say it again slowly when you do not understand.",
        ),
        "sample": "죄송하지만 다시 천천히 말해 주세요.",
        "slots": [
            ("repair_signal", ["죄송하지만", "잘 못 들었어요", "못 알아들었어요"]),
            ("repeat_slowly", ["다시 천천히 말해 주세요", "한 번 더 말해 주세요"]),
        ],
    },
    "segment_a1_09_home_daily_life": {
        "task": (
            "집에서 언제 무엇을 하는지 장소와 일상 행동을 한 문장으로 말하세요.",
            "Sage in einem Satz, wann und was du zu Hause machst.",
            "Say in one sentence when and what you do at home.",
        ),
        "sample": "저는 집에서 아침마다 밥을 먹어요.",
        "slots": [
            ("home_place", ["집에서", "방에서"]),
            ("daily_action", ["밥을 먹어요", "공부해요", "운동해요"]),
        ],
    },
    "segment_a1_10_health_safety": {
        "task": (
            "아픈 곳이나 상태를 말하고 필요한 도움을 분명히 요청하세요.",
            "Nenne deine Beschwerden und bitte klar um die nötige Hilfe.",
            "State where or how you feel sick and clearly ask for the help you need.",
        ),
        "sample": "배가 많이 아파서 도움이 필요해요.",
        "slots": [
            ("symptom", ["배가 많이 아파서", "배가 많이 아파요", "머리가 아파요", "숨쉬기가 힘들어요"]),
            ("help_request", ["도움이 필요해요", "병원에 가야 해요", "도와주세요"]),
        ],
    },
    "segment_a1_11_titles_relationships": {
        "task": (
            "처음 만난 사람에게 너라고 하지 말고 안전한 호칭으로 인사하세요.",
            "Begrüße eine neue Person mit einer sicheren Anrede statt mit 너.",
            "Greet a new person using a safe title instead of 너.",
        ),
        "sample": "선생님, 안녕하세요.",
        "slots": [
            ("safe_title", ["선생님", "기사님", "사장님"]),
            ("greeting", ["안녕하세요", "안녕하십니까"]),
        ],
    },
    "segment_a1_12_daily_negation": {
        "task": (
            "오늘 하지 않는 일이나 사실이 아닌 것을 정중하게 말하세요.",
            "Sage höflich, was du heute nicht tust oder was nicht der Fall ist.",
            "Politely say what you are not doing today or what is not true.",
        ),
        "sample": "오늘은 운동을 안 해요.",
        "slots": [
            ("daily_context", ["오늘은", "평일에는", "아침에는"]),
            ("negation", ["안 해요", "아니에요", "못 가요"]),
        ],
    },
    "segment_a1_13_register_switching": {
        "task": (
            "처음 만난 사람에게 쓸 합니다체와 친해진 뒤 쓸 해요체를 각각 한 문장으로 보여 주세요.",
            "Zeige je einen Satz im formellen Stil für ein erstes Treffen und im höflichen Stil für eine vertrautere Beziehung.",
            "Give one formal sentence for a first meeting and one polite sentence for a more familiar relationship.",
        ),
        "sample": "처음 뵙겠습니다. 만나서 반가워요.",
        "slots": [
            ("formal_register", ["처음 뵙겠습니다", "반갑습니다"]),
            ("polite_register", ["반가워요", "잘 지내요", "고마워요"]),
        ],
    },
    "segment_a1_14_payment_delivery": {
        "task": (
            "들은 결제 안내 문장을 그대로 받아쓰세요.",
            "Schreibe den gehörten Zahlungshinweis exakt auf.",
            "Write the payment notice exactly as you hear it.",
        ),
        "sample": "이 주문은 자동 결제예요.",
        "exact": True,
    },
    "segment_a1_15_first_class_work": {
        "task": (
            "첫 수업이나 출근에서 자신을 소개하고 상대의 이름을 정중하게 물으세요.",
            "Stelle dich am ersten Kurs- oder Arbeitstag vor und frage höflich nach dem Namen der anderen Person.",
            "Introduce yourself on your first day in class or at work and politely ask the other person's name.",
        ),
        "sample": "처음 뵙겠습니다. 저는 수진입니다. 성함이 어떻게 되세요?",
        "slots": [
            ("first_meeting", ["처음 뵙겠습니다", "만나서 반갑습니다"]),
            ("self_intro", ["저는 수진입니다", "저는 민수입니다"]),
            ("name_question", ["성함이 어떻게 되세요", "이름이 뭐예요"]),
        ],
    },
    "segment_a1_16_survival_capstone": {
        "task": (
            "낯선 직원에게 인사하고 서울역 가는 길을 물은 뒤 못 들었음을 알리고 반복을 요청하세요.",
            "Begrüße eine fremde Servicekraft, frage nach dem Weg zum Bahnhof Seoul und bitte nach Wiederholung.",
            "Greet an unfamiliar staff member, ask the way to Seoul Station, and request repetition after not hearing clearly.",
        ),
        "sample": "안녕하세요. 서울역으로 가려면 어디로 가야 해요? 잘 못 들었어요. 다시 말해 주세요.",
        "slots": [
            ("greeting", ["안녕하세요", "안녕하십니까"]),
            ("direction_problem", ["서울역으로 가려면", "서울역은 어디예요"]),
            ("repair", ["잘 못 들었어요", "다시 말해 주세요", "천천히 말해 주세요"]),
        ],
    },
    "segment_a2_haeyo_register_transition": {
        "task": (
            "같은 출발 안내를 합니다체와 해요체로 한 번씩 바꾸어 쓰세요.",
            "Formuliere dieselbe Abfahrtsmitteilung einmal formell und einmal höflich.",
            "Write the same departure notice once in formal style and once in polite style.",
        ),
        "sample": "지금 출발합니다. 지금 출발해요.",
        "slots": [
            ("formal_action", ["출발합니다", "시작합니다"]),
            ("polite_action", ["출발해요", "시작해요"]),
        ],
    },
    "segment_a2_plans_with_friend": {
        "task": (
            "토요일 약속 제안을 격식체, 해요체, 반말의 세 가지 관계 말투로 쓰세요.",
            "Schlage ein Treffen am Samstag in drei Registern vor: formell, höflich und vertraut.",
            "Suggest meeting on Saturday in formal, polite, and casual speech.",
        ),
        "sample": "토요일에 만나는 게 어떻습니까? 토요일에 만나는 게 어때요? 토요일에 만나는 게 어때?",
        "slots": [
            ("formal_proposal", ["어떻습니까", "만나시겠습니까"]),
            ("polite_proposal", ["어때요", "만날까요"]),
            ("casual_proposal", ["어때", "만날래"]),
        ],
        "endings": ["어때", "만날래"],
    },
    "segment_a2_friend_birthday": {
        "task": (
            "생일을 함께 축하하자는 제안을 격식체, 해요체, 반말로 각각 쓰세요.",
            "Schlage in formellem, höflichem und vertrautem Stil vor, den Geburtstag gemeinsam zu feiern.",
            "Suggest celebrating the birthday together in formal, polite, and casual speech.",
        ),
        "sample": "함께 축하하러 갑시다. 같이 축하하러 가요. 우리 같이 축하하러 가자.",
        "slots": [
            ("formal_proposal", ["갑시다", "축하합시다"]),
            ("polite_proposal", ["가요", "축하해요"]),
            ("casual_proposal", ["가자", "축하하자"]),
        ],
        "endings": ["가자", "하자"],
    },
    "segment_a2_running_late": {
        "task": (
            "약속에 늦는 이유와 예상 지연 시간을 말하고 사과하세요.",
            "Nenne den Grund und die erwartete Verspätung und entschuldige dich.",
            "Explain why you are late, give the expected delay, and apologize.",
        ),
        "sample": "버스가 늦어서 약속에 십 분 늦을 것 같아요. 미안해요.",
        "slots": [
            ("reason", ["버스가 늦어서", "길이 막혀서", "일이 늦게 끝나서"]),
            ("delay", ["십 분 늦을 것 같아요", "곧 도착할 것 같아요"]),
            ("apology", ["미안해요", "죄송해요"]),
        ],
    },
    "segment_a2_pharmacy_headache": {
        "task": (
            "약사에게 증상과 지속 시간을 말하고 알맞은 약을 요청하세요.",
            "Nenne in der Apotheke Beschwerden und Dauer und bitte um ein passendes Medikament.",
            "Tell the pharmacist your symptom and how long it has lasted, then ask for suitable medicine.",
        ),
        "sample": "어제부터 머리가 아파요. 두통약을 추천해 주세요.",
        "slots": [
            ("duration_symptom", ["어제부터 머리가 아파요", "아침부터 머리가 아파요"]),
            ("medicine_request", ["두통약을 추천해 주세요", "먹을 약이 있을까요"]),
        ],
    },
    "segment_a2_gym_signup": {
        "task": (
            "헬스장 직원에게 원하는 이용 기간을 말하고 가격과 시작일을 물으세요.",
            "Nenne im Fitnessstudio die gewünschte Laufzeit und frage nach Preis und Startdatum.",
            "Tell gym staff the membership period you want and ask about price and start date.",
        ),
        "sample": "한 달 등록하고 싶어요. 가격이 얼마이고 언제부터 시작할 수 있어요?",
        "slots": [
            ("membership_period", ["한 달 등록하고 싶어요", "세 달 이용하고 싶어요"]),
            ("price_question", ["가격이 얼마이고", "가격이 얼마예요", "비용이 얼마예요"]),
            ("start_question", ["언제부터 시작할 수 있어요", "오늘부터 이용할 수 있어요"]),
        ],
    },
    "segment_a2_feeling_sick": {
        "task": (
            "친구에게 아픈 상태를 설명하고 오늘 약속을 바꿔도 되는지 물으세요.",
            "Erkläre einem Freund, dass du krank bist, und frage, ob ihr den heutigen Termin verschieben könnt.",
            "Tell a friend that you are sick and ask whether today's plan can be changed.",
        ),
        "sample": "열이 나고 몸이 아파요. 오늘 약속을 다음으로 미뤄도 될까요?",
        "slots": [
            ("illness", ["열이 나요", "몸이 아파요", "감기에 걸린 것 같아요"]),
            ("change_request", ["약속을 다음으로 미뤄도 될까요", "다음에 만나도 될까요"]),
        ],
    },
    "segment_a2_cafe_starbucks_basic": {
        "task": (
            "카페에서 음료와 크기를 고르고 매장 이용인지 포장인지 말하세요.",
            "Bestelle im Café ein Getränk mit Größe und sage, ob es für hier oder zum Mitnehmen ist.",
            "Order a drink and size at a café and say whether it is for here or to go.",
        ),
        "sample": "아이스 아메리카노 톨 사이즈로 주세요. 매장에서 마실게요.",
        "slots": [
            ("drink_size", ["아이스 아메리카노 톨 사이즈로", "따뜻한 라테 큰 사이즈로"]),
            ("order_request", ["주세요", "주문할게요"]),
            ("service_mode", ["매장에서 마실게요", "포장해 주세요"]),
        ],
    },
    "segment_a2_myeongdong_shopping": {
        "task": (
            "옷가게에서 원하는 색과 크기를 말하고 입어 봐도 되는지 물으세요.",
            "Nenne im Kleidungsgeschäft Farbe und Größe und frage, ob du das Stück anprobieren darfst.",
            "State the color and size you want in a clothing store and ask to try it on.",
        ),
        "sample": "이 셔츠 검은색 큰 사이즈 있어요? 입어 봐도 돼요?",
        "slots": [
            ("item_option", ["셔츠 검은색 큰 사이즈", "바지 파란색 작은 사이즈"]),
            ("availability", ["있어요", "있나요"]),
            ("try_on", ["입어 봐도 돼요", "신어 봐도 돼요"]),
        ],
    },
    "segment_a2_cafe_study": {
        "task": (
            "카페에서 공부할 자리를 찾고 콘센트를 사용해도 되는지 물으세요.",
            "Bitte im Café um einen Lernplatz und frage, ob du die Steckdose benutzen darfst.",
            "Ask for a place to study at a café and whether you may use the outlet.",
        ),
        "sample": "여기에서 공부해도 돼요? 콘센트를 사용해도 될까요?",
        "slots": [
            ("study_permission", ["공부해도 돼요", "공부해도 될까요"]),
            ("facility_permission", ["콘센트를 사용해도 될까요", "와이파이를 써도 돼요"]),
        ],
    },
    "segment_a2_subway_transfer": {
        "task": (
            "지하철에서 갈아탈 노선과 환승역을 확인하세요.",
            "Frage in der U-Bahn nach der Umsteigelinie und der Umsteigestation.",
            "Ask which subway line to transfer to and at which station.",
        ),
        "sample": "2호선으로 갈아타려면 어느 역에서 내려야 해요?",
        "slots": [
            ("transfer_line", ["2호선으로 갈아타려면", "3호선으로 환승하려면"]),
            ("station_question", ["어느 역에서 내려야 해요", "어디에서 갈아타요"]),
        ],
    },
    "segment_a2_taxi_street": {
        "task": (
            "택시 기사에게 목적지와 내려 줄 정확한 장소를 말하세요.",
            "Nenne dem Taxifahrer Ziel und genauen Ausstiegsort.",
            "Tell the taxi driver your destination and exact drop-off point.",
        ),
        "sample": "시청으로 가 주세요. 정문 앞에서 내려 주세요.",
        "slots": [
            ("taxi_destination", ["시청으로 가 주세요", "서울역으로 가 주세요"]),
            ("drop_off", ["정문 앞에서 내려 주세요", "큰길에서 내려 주세요"]),
        ],
    },
    "segment_a2_subway_directions": {
        "task": (
            "지하철로 목적지에 가는 방법과 출구 번호를 물으세요.",
            "Frage nach dem U-Bahn-Weg zum Ziel und nach der Ausgangsnummer.",
            "Ask how to reach your destination by subway and which exit to use.",
        ),
        "sample": "광화문에 지하철로 어떻게 가요? 몇 번 출구로 나가야 해요?",
        "slots": [
            ("route_question", ["지하철로 어떻게 가요", "어느 노선을 타야 해요"]),
            ("exit_question", ["몇 번 출구로 나가야 해요", "어느 출구예요"]),
        ],
    },
    "segment_a2_lost_phone": {
        "task": (
            "휴대전화를 잃어버린 장소와 시간을 말하고 연락 도움을 요청하세요.",
            "Nenne Ort und Zeit des verlorenen Handys und bitte um Hilfe beim Anrufen.",
            "Say where and when you lost your phone and ask for help calling it.",
        ),
        "sample": "방금 카페에서 휴대전화를 잃어버렸어요. 제 번호로 전화해 주실 수 있어요?",
        "slots": [
            ("loss_detail", ["카페에서 휴대전화를 잃어버렸어요", "지하철에서 휴대전화를 놓고 내렸어요"]),
            ("contact_help", ["제 번호로 전화해 주실 수 있어요", "찾는 것을 도와주실 수 있어요"]),
        ],
    },
    "segment_a2_ktx_ticket": {
        "task": (
            "KTX 목적지와 출발 시간을 말하고 표를 요청하세요.",
            "Nenne KTX-Ziel und Abfahrtszeit und bitte um eine Fahrkarte.",
            "State your KTX destination and departure time and ask for a ticket.",
        ),
        "sample": "내일 오전 열 시 부산행 KTX 표 한 장 주세요.",
        "slots": [
            ("train_detail", ["내일 오전 열 시 부산행", "오늘 오후 세 시 대전행"]),
            ("ticket_request", ["KTX 표 한 장 주세요", "기차표 두 장 주세요"]),
        ],
    },
    "segment_a2_rent_bank_transfer": {
        "task": (
            "월세 자동이체 날짜와 계좌를 확인하는 질문을 하세요.",
            "Frage nach Datum und Konto für die automatische Mietüberweisung.",
            "Ask to confirm the date and account for an automatic rent transfer.",
        ),
        "sample": "월세는 매달 5일에 자동이체하면 돼요? 이 계좌로 보내면 돼요?",
        "slots": [
            ("transfer_date", ["매달 5일에 자동이체하면 돼요", "언제 자동이체하면 돼요"]),
            ("account_confirmation", ["이 계좌로 보내면 돼요", "계좌번호가 맞아요"]),
        ],
    },
    "segment_b1_plans_with_reasons": {
        "task": (
            "약속을 미뤄야 하는 이유를 설명하고 구체적인 새 시간을 제안하세요.",
            "Erkläre, warum der Termin verschoben werden muss, und schlage einen konkreten neuen Zeitpunkt vor.",
            "Explain why the plan must be postponed and suggest a specific new time.",
        ),
        "sample": "갑자기 회의가 생겨서 오늘은 어렵습니다. 금요일 저녁으로 미루는 게 어떨까요?",
        "slots": [
            ("postpone_reason", ["회의가 생겨서", "일이 늦게 끝나서", "몸이 좋지 않아서"]),
            ("new_plan", ["금요일 저녁으로 미루는 게 어떨까요", "내일 다시 만날 수 있을까요"]),
        ],
    },
    "segment_b1_travel_experience": {
        "task": (
            "기억에 남는 여행 경험과 그렇게 느낀 이유를 연결해 말하세요.",
            "Erzähle von einem Reiseerlebnis und begründe, warum es dir in Erinnerung geblieben ist.",
            "Describe a memorable travel experience and explain why it stayed with you.",
        ),
        "sample": "지난해 제주도에 가 본 적이 있는데 바다 풍경이 아름다워서 오래 기억에 남았습니다.",
        "slots": [
            ("travel_experience", ["제주도에 가 본 적이 있는데", "부산을 여행한 적이 있는데"]),
            ("experience_reason", ["아름다워서 오래 기억에 남았습니다", "사람들이 친절해서 인상적이었습니다"]),
        ],
    },
    "segment_b1_relay_social_speech": {
        "task": (
            "회식에서 동료가 한 말과 그 말에 대한 자신의 대응을 간접화법으로 전하세요.",
            "Gib indirekt wieder, was ein Kollege beim Firmenessen sagte, und wie du darauf reagiert hast.",
            "Use reported speech to relay what a colleague said at a company dinner and how you responded.",
        ),
        "sample": "동료가 오늘은 먼저 가겠다고 해서 조심히 들어가라고 말했습니다.",
        "slots": [
            ("reported_speech", ["가겠다고 해서", "늦는다고 해서", "참석한다고 해서"]),
            ("relay_response", ["들어가라고 말했습니다", "연락해 달라고 했습니다", "알겠다고 답했습니다"]),
        ],
    },
    "segment_b1_relay_media_claim": {
        "task": (
            "매체가 보도한 주장을 간접화법으로 전하고 출처를 확인해야 한다고 덧붙이세요.",
            "Gib eine Medienbehauptung indirekt wieder und füge hinzu, dass die Quelle geprüft werden muss.",
            "Report a media claim indirectly and add that its source must be checked.",
        ),
        "sample": "기사에서는 이용자가 늘었다고 했지만 조사 출처를 먼저 확인해야 합니다.",
        "slots": [
            ("media_claim", ["늘었다고 했지만", "줄었다고 보도했지만", "효과가 있다고 주장했지만"]),
            ("source_check", ["출처를 먼저 확인해야 합니다", "근거가 무엇인지 살펴봐야 합니다"]),
        ],
    },
    "segment_b1_bank_soft_request": {
        "task": (
            "은행에서 계좌 개설 목적을 말하고 필요한 서류를 완곡하게 물으세요.",
            "Nenne bei der Bank den Zweck der Kontoeröffnung und frage höflich-indirekt nach den Unterlagen.",
            "State why you want to open an account and softly ask which documents are required.",
        ),
        "sample": "급여 계좌를 만들려고 하는데 필요한 서류를 알려 주실 수 있을까요?",
        "slots": [
            ("bank_purpose", ["계좌를 만들려고 하는데", "통장을 개설하려고 하는데"]),
            ("soft_request", ["알려 주실 수 있을까요", "확인해 주실 수 있을까요"]),
        ],
    },
    "segment_b1_team_role_coordination": {
        "task": (
            "팀 과업의 담당자와 기한을 제안하고 상대가 가능한지 부드럽게 확인하세요.",
            "Schlage Zuständigkeit und Frist für eine Teamaufgabe vor und frage behutsam, ob das möglich ist.",
            "Propose an owner and deadline for a team task and softly check whether it is feasible.",
        ),
        "sample": "자료 정리는 제가 금요일까지 맡겠습니다. 발표 준비는 민지 씨가 맡아 주실 수 있을까요?",
        "slots": [
            ("role_deadline", ["제가 금요일까지 맡겠습니다", "제가 내일까지 준비하겠습니다"]),
            ("coordination_request", ["맡아 주실 수 있을까요", "확인해 주실 수 있을까요"]),
        ],
    },
    "segment_b1_attendance_and_coverage": {
        "task": (
            "불참 이유를 알리고 자신의 업무를 대신 맡아 줄 수 있는지 요청하세요.",
            "Teile den Grund deiner Abwesenheit mit und bitte darum, deine Aufgabe zu übernehmen.",
            "Explain why you will be absent and ask someone to cover your task.",
        ),
        "sample": "병원 예약 때문에 회의에 참석하기 어렵습니다. 제 발표를 대신 맡아 주실 수 있을까요?",
        "slots": [
            ("absence_reason", ["병원 예약 때문에", "출장 일정 때문에", "가족 일 때문에"]),
            ("coverage_request", ["대신 맡아 주실 수 있을까요", "대신 진행해 주실 수 있을까요"]),
        ],
    },
    "segment_b1_schedule_softening": {
        "task": (
            "현재 일정의 어려움을 설명하고 대체 시간을 완곡하게 제안하세요.",
            "Erkläre das Terminproblem und schlage behutsam eine Alternative vor.",
            "Explain the scheduling difficulty and softly propose an alternative time.",
        ),
        "sample": "수요일 오전은 조금 어려울 것 같습니다. 가능하시다면 오후 세 시로 바꿀 수 있을까요?",
        "slots": [
            ("soft_constraint", ["조금 어려울 것 같습니다", "시간이 빠듯할 것 같습니다"]),
            ("alternative", ["오후 세 시로 바꿀 수 있을까요", "목요일로 조정할 수 있을까요"]),
        ],
    },
    "segment_b1_encouragement": {
        "task": (
            "상대의 어려움을 인정하고 구체적으로 도울 수 있다는 따뜻한 말을 전하세요.",
            "Erkenne die Schwierigkeit an und biete warm und konkret Hilfe an.",
            "Acknowledge the difficulty and warmly offer specific help.",
        ),
        "sample": "요즘 많이 힘들었겠어요. 혼자 하지 말고 필요하면 제가 같이 준비할게요.",
        "slots": [
            ("empathy", ["많이 힘들었겠어요", "정말 걱정됐겠어요", "마음이 무거웠겠어요"]),
            ("concrete_support", ["제가 같이 준비할게요", "제가 옆에서 도울게요", "언제든 이야기해 주세요"]),
        ],
    },
    "segment_b1_intimate_feelings": {
        "task": (
            "좋아하는 마음을 조심스럽게 전하고 상대가 바로 답하지 않아도 된다고 말하세요.",
            "Teile deine Gefühle behutsam mit und sage, dass die andere Person nicht sofort antworten muss.",
            "Share your feelings carefully and say the other person does not need to answer immediately.",
        ),
        "sample": "오랫동안 좋아해 왔어요. 부담을 주고 싶지는 않으니 지금 바로 대답하지 않아도 돼요.",
        "slots": [
            ("feeling", ["좋아해 왔어요", "마음이 있어요", "소중하게 생각해요"]),
            ("no_pressure", ["바로 대답하지 않아도 돼요", "부담을 느끼지 않았으면 해요"]),
        ],
    },
    "segment_b1_social_invitation": {
        "task": (
            "모임의 시간과 목적을 알려 초대하고, 어려우면 거절해도 된다고 덧붙이세요.",
            "Lade mit Zeit und Anlass ein und sage dazu, dass eine Absage in Ordnung ist.",
            "Invite someone with the time and purpose, and add that it is okay to decline.",
        ),
        "sample": "토요일 저녁에 동료들과 식사하려고 해요. 시간 되시면 함께 가실래요? 어려우시면 괜찮아요.",
        "slots": [
            ("event_detail", ["토요일 저녁에 동료들과 식사하려고 해요", "금요일에 작은 모임이 있어요"]),
            ("invitation", ["함께 가실래요", "같이 오실 수 있을까요"]),
            ("decline_option", ["어려우시면 괜찮아요", "부담 없이 말씀해 주세요"]),
        ],
    },
    "segment_b1_delivery_resolution": {
        "task": (
            "배달 문제를 구체적으로 설명하고 원하는 해결 방법을 요청하세요.",
            "Beschreibe das Lieferproblem konkret und bitte um die gewünschte Lösung.",
            "Describe the delivery problem specifically and request the resolution you want.",
        ),
        "sample": "주문한 음식과 다른 메뉴가 왔습니다. 확인 후 다시 보내 주실 수 있을까요?",
        "slots": [
            ("delivery_problem", ["다른 메뉴가 왔습니다", "음식이 빠져 있습니다", "배달이 한 시간 늦었습니다"]),
            ("remedy_request", ["다시 보내 주실 수 있을까요", "환불해 주실 수 있을까요"]),
        ],
    },
    "segment_b1_property_damage_report": {
        "task": (
            "집의 파손 위치와 발생 시점을 알리고 점검을 요청하세요.",
            "Melde Ort und Zeitpunkt eines Schadens in der Wohnung und bitte um Prüfung.",
            "Report where and when property damage occurred and ask for an inspection.",
        ),
        "sample": "오늘 아침부터 주방 천장에서 물이 새고 있습니다. 가능한 한 빨리 점검해 주세요.",
        "slots": [
            ("damage_detail", ["주방 천장에서 물이 새고 있습니다", "창문이 깨져 있습니다"]),
            ("occurrence_time", ["오늘 아침부터", "어젯밤부터", "방금"]),
            ("inspection_request", ["빨리 점검해 주세요", "수리 일정을 알려 주세요"]),
        ],
    },
    "segment_b1_housing_contract": {
        "task": (
            "주택 계약의 보증금과 입주 날짜를 확인하는 질문을 하세요.",
            "Frage nach Kaution und Einzugsdatum im Mietvertrag.",
            "Ask to confirm the deposit and move-in date in a housing contract.",
        ),
        "sample": "계약서의 보증금이 천만 원이 맞나요? 입주 날짜는 3월 1일로 정해진 건가요?",
        "slots": [
            ("deposit_confirmation", ["보증금이 천만 원이 맞나요", "보증금에 관리비가 포함되나요"]),
            ("move_in_confirmation", ["입주 날짜는 3월 1일로 정해진 건가요", "언제부터 입주할 수 있나요"]),
        ],
    },
    "segment_b1_safety_health_concern": {
        "task": (
            "난방이나 건강 상태의 위험을 설명하고 즉시 할 조치를 제안하세요.",
            "Beschreibe ein Heizungs- oder Gesundheitsrisiko und schlage eine sofortige Maßnahme vor.",
            "Describe a heating or health risk and propose an immediate action.",
        ),
        "sample": "난방이 계속 켜져 있어서 과열될까 걱정됩니다. 지금 전원을 끄고 관리실에 연락하겠습니다.",
        "slots": [
            ("safety_concern", ["과열될까 걱정됩니다", "가스 냄새가 나서 위험합니다", "상태가 더 나빠질까 걱정됩니다"]),
            ("immediate_action", ["전원을 끄고 관리실에 연락하겠습니다", "창문을 열고 밖으로 나가겠습니다"]),
        ],
    },
    "segment_b1_relationship_conflict_repair": {
        "task": (
            "다툼에서 자신의 감정을 비난 없이 말하고 사과와 대화 제안을 하세요.",
            "Sprich im Streit ohne Vorwurf über dein Gefühl und biete Entschuldigung und Gespräch an.",
            "State your feelings without blame and offer an apology and a conversation.",
        ),
        "sample": "연락이 없어서 서운했어요. 화를 내서 미안해요. 서로 괜찮을 때 다시 이야기하고 싶어요.",
        "slots": [
            ("i_feeling", ["서운했어요", "걱정됐어요", "속상했어요"]),
            ("apology", ["화를 내서 미안해요", "말을 세게 해서 미안해요"]),
            ("repair_proposal", ["다시 이야기하고 싶어요", "차분히 이야기해 볼까요"]),
        ],
    },
    "segment_b1_move_in_handover": {
        "task": (
            "입주 전 열쇠 인수 시간과 함께 확인할 항목을 요청하세요.",
            "Bestätige Zeit der Schlüsselübergabe und bitte darum, die Prüfpunkte gemeinsam durchzugehen.",
            "Confirm the key handover time and ask to review the move-in checklist together.",
        ),
        "sample": "금요일 오후 두 시에 열쇠를 받으러 가겠습니다. 계량기와 벽 상태를 함께 확인할 수 있을까요?",
        "slots": [
            ("handover_time", ["금요일 오후 두 시에 열쇠를 받으러 가겠습니다", "내일 열쇠를 받을 수 있을까요"]),
            ("condition_check", ["계량기와 벽 상태를 함께 확인할 수 있을까요", "시설 상태를 같이 살펴볼 수 있을까요"]),
        ],
    },
    "segment_b1_life_course_narrative": {
        "task": (
            "과거 경험, 삶의 전환점, 현재 모습을 시간 순서로 연결해 서술하세요.",
            "Erzähle eine frühere Erfahrung, einen Wendepunkt und die Gegenwart in zeitlicher Reihenfolge.",
            "Narrate a past experience, a turning point, and your present situation in chronological order.",
        ),
        "sample": "대학을 졸업한 뒤 서울로 왔습니다. 새로운 일을 시작하면서 생각이 많이 바뀌었고 지금은 교육 분야에서 일합니다.",
        "slots": [
            ("past_stage", ["졸업한 뒤", "어릴 때", "처음 일을 시작했을 때"]),
            ("turning_point", ["시작하면서 생각이 많이 바뀌었고", "경험한 뒤 진로를 바꾸었고"]),
            ("present_stage", ["지금은 교육 분야에서 일합니다", "현재는 새로운 목표를 준비합니다"]),
        ],
    },
    "segment_b2_formal_meeting_opening": {
        "task": (
            "비즈니스 미팅을 격식 있게 열며 이름, 역할, 오늘의 안건을 소개하세요.",
            "Eröffne ein Geschäftsmeeting formell und nenne Name, Rolle und heutige Agenda.",
            "Open a business meeting formally and introduce your name, role, and today's agenda.",
        ),
        "sample": "처음 뵙겠습니다. 저는 한글소리의 기획을 맡은 수진입니다. 오늘은 협업 일정과 역할을 논의하겠습니다.",
        "slots": [
            ("formal_opening", ["처음 뵙겠습니다", "참석해 주셔서 감사합니다"]),
            ("role_intro", ["기획을 맡은 수진입니다", "개발을 담당하는 민수입니다"]),
            ("agenda", ["협업 일정과 역할을 논의하겠습니다", "다음 단계와 예산을 검토하겠습니다"]),
        ],
    },
    "segment_b2_honorific_register_transform": {
        "task": (
            "상사의 도착과 회의 시작을 주체 높임과 격식체를 사용해 보고하세요.",
            "Berichte mit Subjekthonorifik und formellem Stil über die Ankunft einer Führungskraft und den Sitzungsbeginn.",
            "Use subject honorifics and formal style to report a manager's arrival and the meeting start.",
        ),
        "sample": "김 부장님께서 곧 오십니다. 먼저 회의를 시작하겠습니다.",
        "slots": [
            ("honorific_subject", ["부장님께서", "선생님께서", "교수님께서"]),
            ("honorific_action", ["오십니다", "말씀하십니다", "확인하셨습니다"]),
            ("formal_action", ["시작하겠습니다", "보고드리겠습니다"]),
        ],
    },
    "segment_b2_decision_criteria": {
        "task": (
            "두 선택안의 기준과 상충점을 설명하고 조건이 있는 절충안을 제안하세요.",
            "Erkläre Kriterien und Zielkonflikt zweier Optionen und schlage einen bedingten Kompromiss vor.",
            "Explain the criteria and trade-off between two options and propose a conditional compromise.",
        ),
        "sample": "비용에 비추어 보면 A안이 유리하지만 접근성은 B안이 낫습니다. 예산을 지키는 한 핵심 기능은 B안으로 절충하겠습니다.",
        "slots": [
            ("criteria_comparison", ["비용에 비추어 보면", "안정성을 기준으로 보면", "접근성은"]),
            ("tradeoff", ["유리하지만", "낫지만", "장점이 있는 반면"]),
            ("conditional_compromise", ["지키는 한", "조건으로 절충하겠습니다", "우선 적용하겠습니다"]),
        ],
    },
    "segment_b2_public_wording_revision": {
        "task": (
            "배제적으로 들릴 수 있는 안내문 표현을 지적하고 더 포용적인 문장과 수정 이유를 쓰세요.",
            "Benenne eine ausschließend wirkende Formulierung, schreibe eine inklusivere Fassung und begründe die Änderung.",
            "Identify exclusionary wording in a public notice, write a more inclusive version, and explain the change.",
        ),
        "sample": "기존 안내의 ‘정상 이용자’라는 표현은 일부 사람을 배제할 수 있습니다. 따라서 ‘모든 이용자’로 바꾸면 대상이 더 분명하고 포용적입니다.",
        "slots": [
            ("wording_problem", ["일부 사람을 배제할 수 있습니다", "오해를 낳을 수 있습니다"]),
            ("inclusive_revision", ["모든 이용자", "도움이 필요한 이용자", "누구나"]),
            ("revision_reason", ["더 분명하고 포용적입니다", "책임 주체가 명확해집니다"]),
        ],
    },
    "segment_b2_collaborative_feedback": {
        "task": (
            "동료 작업의 장점을 인정하고 구체적인 우려와 실행 가능한 개선안을 말하세요.",
            "Würdige eine Stärke der Arbeit, nenne eine konkrete Sorge und schlage eine umsetzbare Verbesserung vor.",
            "Acknowledge a strength in a colleague's work, state a specific concern, and propose an actionable improvement.",
        ),
        "sample": "구조가 명확해서 핵심을 이해하기 쉽습니다. 다만 첫 화면의 정보가 많으니 예시를 한 개로 줄여 보는 게 어떨까요?",
        "slots": [
            ("feedback_strength", ["구조가 명확해서", "근거가 구체적이라", "흐름이 자연스러워서"]),
            ("specific_concern", ["다만 첫 화면의 정보가 많으니", "다만 결론의 근거가 부족하니"]),
            ("actionable_suggestion", ["한 개로 줄여 보는 게 어떨까요", "자료를 하나 추가하면 좋겠습니다"]),
        ],
    },
    "segment_b2_digital_source_judgment": {
        "task": (
            "디지털 자료의 작성자, 날짜, 근거를 검토하고 한계를 포함한 신뢰 판단을 쓰세요.",
            "Prüfe Autor, Datum und Belege einer digitalen Quelle und beurteile ihre Verlässlichkeit mit Einschränkung.",
            "Review a digital source's author, date, and evidence, then judge its reliability with a limitation.",
        ),
        "sample": "작성 기관과 게시 날짜는 확인되지만 원자료 링크가 없습니다. 따라서 참고는 할 수 있으나 사실로 단정하기 전에 다른 출처와 비교해야 합니다.",
        "slots": [
            ("source_metadata", ["작성 기관과 게시 날짜는", "작성자와 수정 날짜는"]),
            ("evidence_limit", ["원자료 링크가 없습니다", "표본 설명이 부족합니다"]),
            ("qualified_judgment", ["다른 출처와 비교해야 합니다", "그대로 신뢰하기는 어렵습니다"]),
        ],
    },
    "segment_b2_societal_evidence_argument": {
        "task": (
            "사회 문제에 대한 주장, 구체적 근거, 근거의 한계, 결론을 연결해 쓰세요.",
            "Verbinde zu einem gesellschaftlichen Thema Behauptung, konkreten Beleg, dessen Grenze und Schlussfolgerung.",
            "Connect a claim, concrete evidence, the evidence's limitation, and a conclusion about a social issue.",
        ),
        "sample": "대중교통 확대는 이동 격차를 줄일 수 있습니다. 설문에서 이용 시간이 감소했지만 한 지역 자료에 불과합니다. 따라서 여러 지역의 결과를 확인한 뒤 확대해야 합니다.",
        "slots": [
            ("social_claim", ["이동 격차를 줄일 수 있습니다", "참여 기회를 넓힐 수 있습니다"]),
            ("specific_evidence", ["설문에서", "통계에서", "조사 결과"]),
            ("evidence_limit", ["한 지역 자료에 불과합니다", "표본이 작다는 한계가 있습니다"]),
            ("reasoned_conclusion", ["결과를 확인한 뒤 확대해야 합니다", "추가 검토가 필요합니다"]),
        ],
    },
    "segment_b2_language_social_change": {
        "task": (
            "언어 사용 변화의 사례와 사회적 원인을 들고 단순한 결론을 경계하세요.",
            "Nenne ein Beispiel sprachlichen Wandels und eine soziale Ursache und warne vor einer vorschnellen Schlussfolgerung.",
            "Give an example of language change and a social cause, and caution against a simplistic conclusion.",
        ),
        "sample": "온라인에서는 줄임말 사용이 늘었습니다. 소통 속도와 집단 정체성이 영향을 줍니다. 하지만 새로운 표현이라고 해서 모두 오래 남는 것은 아닙니다.",
        "slots": [
            ("language_example", ["줄임말 사용이 늘었습니다", "호칭 사용이 달라졌습니다"]),
            ("social_cause", ["집단 정체성이 영향을 줍니다", "관계 변화와 매체가 영향을 줍니다"]),
            ("qualified_change", ["모두 오래 남는 것은 아닙니다", "같은 의미로 받아들여지는 것은 아닙니다"]),
        ],
    },
    "segment_b2_medical_precision": {
        "task": (
            "의사에게 증상의 시작 시점, 위치, 정도, 악화 조건을 정확히 설명하세요.",
            "Beschreibe dem Arzt Beginn, Ort, Stärke und Auslöser der Beschwerden präzise.",
            "Precisely tell a doctor when the symptom began, where it is, how severe it is, and what worsens it.",
        ),
        "sample": "사흘 전부터 오른쪽 무릎이 아프고 통증은 10점 중 7점입니다. 계단을 오를 때 더 심해집니다.",
        "slots": [
            ("onset_location", ["사흘 전부터 오른쪽 무릎이 아프고", "어젯밤부터 왼쪽 배가 아프고"]),
            ("severity", ["10점 중 7점입니다", "통증이 매우 심합니다"]),
            ("trigger", ["계단을 오를 때 더 심해집니다", "식사 후에 더 아픕니다"]),
        ],
    },
    "segment_b2_contract_scope": {
        "task": (
            "계약서에 서명할 사람의 범위, 예외, 서면 확인 요청을 명확히 쓰세요.",
            "Kläre schriftlich, wer unterschreiben muss, welche Ausnahme gilt, und bitte um Bestätigung.",
            "Clearly write who must sign the contract, what exception applies, and ask for written confirmation.",
        ),
        "sample": "원칙적으로 모든 공동 임차인이 서명해야 하는 것으로 이해했습니다. 다만 해외 체류자는 위임장이 가능한지, 가능하다면 서면으로 확인해 주시기 바랍니다.",
        "slots": [
            ("signature_scope", ["모든 공동 임차인이 서명해야", "계약 당사자 전원이 서명해야"]),
            ("exception_inquiry", ["위임장이 가능한지", "대리 서명이 인정되는지"]),
            ("written_confirmation", ["서면으로 확인해 주시기 바랍니다", "문서로 답변해 주시기 바랍니다"]),
        ],
    },
    "segment_b2_terms_deferral": {
        "task": (
            "현재 기한, 불가피한 이유, 새 제출일, 그때까지의 계획을 포함해 유예를 요청하세요.",
            "Beantrage Aufschub mit aktueller Frist, zwingendem Grund, neuem Termin und Arbeitsplan.",
            "Request a deferral including the current deadline, unavoidable reason, new date, and completion plan.",
        ),
        "sample": "현재 제출 기한은 5월 10일입니다. 하지만 자료 제공이 늦어졌습니다. 5월 17일까지 유예해 주시면 중간 보고서를 먼저 제출하겠습니다.",
        "slots": [
            ("current_deadline", ["제출 기한은 5월 10일입니다", "마감일은 이번 금요일입니다"]),
            ("deferral_reason", ["자료 제공이 늦어졌습니다", "검토 일정이 지연되었습니다"]),
            ("new_date_plan", ["5월 17일까지 유예해 주시면", "다음 주까지 연장해 주시면"]),
            ("interim_commitment", ["중간 보고서를 먼저 제출하겠습니다", "진행 상황을 매일 공유하겠습니다"]),
        ],
    },
    "segment_b2_environmental_tradeoff": {
        "task": (
            "환경 효과와 비용 또는 접근성의 상충관계를 설명하고 조건부 대안을 제시하세요.",
            "Erkläre den Zielkonflikt zwischen Umweltwirkung und Kosten oder Zugang und schlage eine bedingte Alternative vor.",
            "Explain a trade-off between environmental impact and cost or access, then propose a conditional alternative.",
        ),
        "sample": "일회용품을 줄이면 폐기물은 감소합니다. 하지만 초기 비용이 늘어납니다. 예산을 초과하지 않는 한 재사용품을 단계적으로 도입하겠습니다.",
        "slots": [
            ("environment_benefit", ["폐기물은 감소합니다", "에너지 사용은 줄어듭니다"]),
            ("tradeoff_cost", ["초기 비용이 늘어납니다", "이용자의 접근이 어려워질 수 있습니다"]),
            ("conditional_option", ["초과하지 않는 한", "단계적으로 도입하겠습니다", "시범 운영하겠습니다"]),
        ],
    },
    "segment_b2_formal_complaint": {
        "task": (
            "주문 번호, 배송 오류, 확인 가능한 근거, 원하는 조치와 답변 기한을 포함해 항의문을 쓰세요.",
            "Schreibe eine Reklamation mit Bestellnummer, Lieferfehler, Nachweis, gewünschter Abhilfe und Antwortfrist.",
            "Write a complaint including order number, delivery error, evidence, requested remedy, and response deadline.",
        ),
        "sample": "주문 204번은 검은색 제품이지만 흰색 제품이 배송되었습니다. 따라서 첨부 사진을 확인하시고 교환 일정과 처리 결과를 3일 안에 알려 주시기 바랍니다.",
        "slots": [
            ("order_error", ["주문 204번은", "다른 제품이 배송되었습니다", "수량이 다릅니다"]),
            ("complaint_evidence", ["첨부 사진을 확인하시고", "영수증을 첨부하오니"]),
            ("formal_remedy", ["교환 일정과 처리 결과를 3일 안에 알려 주시기 바랍니다", "환불해 주시기 바랍니다"]),
            ("response_deadline", ["3일 안에", "이번 주까지"]),
        ],
    },
    "segment_b2_remedy_and_appeal": {
        "task": (
            "이전 민원, 현재 상태, 구체적인 시정 단계와 기한, 이의제기 절차를 서면으로 요청하세요.",
            "Bitte schriftlich um Status, konkrete Abhilfeschritte mit Frist und Beschwerdeweg zu einer früheren Reklamation.",
            "Request in writing the status, concrete remedy steps and deadline, and appeal route for an earlier complaint.",
        ),
        "sample": "지난주 접수한 민원의 처리 상태를 확인하고자 합니다. 따라서 시정 단계와 완료 기한을 서면으로 알려 주시고, 불복 시 이의제기 절차도 안내해 주시기 바랍니다.",
        "slots": [
            ("prior_case_status", ["민원의 처리 상태를 확인하고자 합니다", "접수 번호의 진행 상황을 요청합니다"]),
            ("remedy_plan", ["시정 단계와 완료 기한을 서면으로", "조치 계획과 담당자를 문서로"]),
            ("appeal_route", ["이의제기 절차도 안내해 주시기 바랍니다", "재심 신청 방법을 알려 주시기 바랍니다"]),
        ],
    },
    "segment_b2_shared_space_coordination": {
        "task": (
            "공용 공간 사용 충돌을 설명하고 서로의 필요를 반영한 시간 규칙을 제안하세요.",
            "Beschreibe einen Nutzungskonflikt im Gemeinschaftsraum und schlage eine Zeitregel vor, die beide Bedürfnisse berücksichtigt.",
            "Describe a shared-space conflict and propose a time rule that addresses both sides' needs.",
        ),
        "sample": "저녁에는 주방 사용 시간이 겹쳐 기다리는 경우가 많습니다. 조리가 긴 사람은 미리 시간대를 적고, 30분씩 번갈아 쓰는 게 어떨까요?",
        "slots": [
            ("shared_conflict", ["사용 시간이 겹쳐", "소음 때문에 쉬기 어려워"]),
            ("mutual_need", ["조리가 긴 사람은", "일찍 자는 사람을 위해"]),
            ("coordination_rule", ["30분씩 번갈아 쓰는 게 어떨까요", "사용 시간을 미리 적는 게 어떨까요"]),
        ],
    },
    "segment_b2_personal_boundaries": {
        "task": (
            "불편한 행동과 이유를 비난 없이 설명하고 지켜 주길 바라는 경계를 협의하세요.",
            "Erkläre ohne Vorwurf ein unangenehmes Verhalten und den Grund und verhandle eine gewünschte Grenze.",
            "Explain an uncomfortable behavior and why it matters without blame, then negotiate the boundary you want respected.",
        ),
        "sample": "제 물건을 묻지 않고 사용하면 당황스럽습니다. 앞으로는 먼저 물어봐 주시고, 급한 경우에는 메시지를 남기는 것으로 합의하면 좋겠습니다.",
        "slots": [
            ("boundary_behavior", ["묻지 않고 사용하면", "늦은 시간에 연락하면", "개인 이야기를 다른 사람에게 말하면"]),
            ("boundary_feeling", ["당황스럽습니다", "부담스럽습니다", "불편합니다"]),
            ("negotiated_request", ["먼저 물어봐 주시고", "메시지를 남기는 것으로 합의하면 좋겠습니다"]),
        ],
    },
    "segment_b2_household_safety_rule": {
        "task": (
            "생활 위험, 예방 규칙, 담당 행동, 예외 상황의 연락 방법을 포함한 안전 규칙을 쓰세요.",
            "Formuliere eine Sicherheitsregel mit Risiko, Prävention, Zuständigkeit und Kontaktweg für Ausnahmen.",
            "Write a household safety rule including the risk, preventive rule, responsible action, and emergency contact route.",
        ),
        "sample": "가스레인지를 켠 채 자리를 비우면 화재 위험이 있습니다. 따라서 사용한 사람이 즉시 끄고 확인해야 하며, 냄새가 나면 밸브를 잠근 뒤 관리실에 연락합니다.",
        "slots": [
            ("household_risk", ["화재 위험이 있습니다", "미끄러질 위험이 있습니다"]),
            ("preventive_rule", ["즉시 끄고 확인해야", "통로를 비워 두어야"]),
            ("exception_action", ["밸브를 잠근 뒤 관리실에 연락합니다", "전원을 차단하고 119에 연락합니다"]),
        ],
    },
    "segment_b2_interview_experience": {
        "task": (
            "면접에서 문제 상황, 자신의 행동, 측정 가능한 결과, 지원 직무와의 연결을 말하세요.",
            "Beschreibe im Interview Problemsituation, eigenes Handeln, messbares Ergebnis und Bezug zur Stelle.",
            "In an interview, describe a problem, your action, a measurable result, and how it relates to the role.",
        ),
        "sample": "프로젝트 일정이 지연됐을 때 업무를 다시 나누고 매일 진행 상황을 공유했습니다. 그 결과 일주일 안에 납기를 맞췄고 이 경험을 협업 업무에 활용할 수 있습니다.",
        "slots": [
            ("interview_situation", ["일정이 지연됐을 때", "고객 불만이 늘었을 때"]),
            ("candidate_action", ["업무를 다시 나누고", "원인을 분석하고"]),
            ("measurable_result", ["일주일 안에 납기를 맞췄고", "오류를 절반으로 줄였고"]),
            ("role_connection", ["협업 업무에 활용할 수 있습니다", "이 직무에 적용할 수 있습니다"]),
        ],
    },
    "segment_b2_literary_cultural_response": {
        "task": (
            "읽은 글의 여운, 자신의 해석, 글 속 근거, 가능한 다른 해석을 함께 쓰세요.",
            "Schreibe über Nachklang, eigene Deutung, Textbeleg und eine mögliche andere Lesart.",
            "Write about the text's impact, your interpretation, textual evidence, and a possible alternative reading.",
        ),
        "sample": "마지막 장면의 침묵이 오래 남았습니다. 저는 화해의 가능성을 뜻한다고 보지만, 반복되는 닫힌 문은 단절의 근거가 됩니다. 그러나 두려움의 표현으로도 해석할 수 있습니다.",
        "slots": [
            ("reader_response", ["오래 남았습니다", "깊은 여운을 주었습니다"]),
            ("interpretation", ["가능성을 뜻한다고 보지만", "상실을 보여 준다고 생각하지만"]),
            ("textual_evidence", ["닫힌 문은", "반복되는 빛의 이미지는", "화자의 침묵은"]),
            ("alternative_reading", ["다르게도 해석할 수 있습니다", "표현으로도 해석할 수 있습니다"]),
        ],
    },
    "segment_b2_formal_soft_reformulation": {
        "task": (
            "직접적인 비판을 문제점, 개선 가능성, 정중한 요청이 담긴 격식 표현으로 바꾸세요.",
            "Formuliere direkte Kritik als formelle Aussage mit Problem, Verbesserungsmöglichkeit und höflicher Bitte.",
            "Reformulate direct criticism formally with the issue, room for improvement, and a polite request.",
        ),
        "sample": "현재 안은 근거 설명이 부족해 보완이 필요해 보입니다. 관련 자료를 덧붙여 다시 검토해 주시면 감사하겠습니다.",
        "slots": [
            ("soft_problem", ["보완이 필요해 보입니다", "조정할 여지가 있어 보입니다"]),
            ("improvement_detail", ["관련 자료를 덧붙여", "대안을 함께 제시해"]),
            ("formal_request", ["검토해 주시면 감사하겠습니다", "확인해 주시기 바랍니다"]),
        ],
    },
}

PROJECT_SOURCES: dict[str, list[dict[str, Any]]] = {
    "project_c1_evidence_v1": [
        {"ko": "참여자 24명을 대상으로 한 설문에서 18명이 개선을 체감했다고 답했다.", "de": "In einer Befragung von 24 Teilnehmenden berichteten 18 von einer Verbesserung.", "en": "In a survey of 24 participants, 18 reported an improvement."},
        {"ko": "비교 집단이 없고 참여자가 자발적으로 지원해 인과관계는 확인할 수 없다.", "de": "Es gab keine Vergleichsgruppe, und die Teilnahme war freiwillig; Kausalität ist daher nicht belegt.", "en": "There was no comparison group and participation was voluntary, so causality is not established."},
        {"ko": "다른 지역의 반복 조사에서는 효과가 작았고 연령별 차이가 컸다.", "de": "Eine Wiederholungsstudie in einer anderen Region fand einen kleineren Effekt und große Altersunterschiede.", "en": "A replication in another region found a smaller effect and large differences by age."},
        {"ko": "연구팀은 표본 확대와 사전 등록 뒤 결론을 다시 검토하겠다고 밝혔다.", "de": "Das Forschungsteam will die Schlussfolgerung nach größerer Stichprobe und Präregistrierung erneut prüfen.", "en": "The team will revisit the conclusion after a larger sample and preregistration."},
    ],
    "project_c1_risk_v1": [
        {"ko": "현재 확인된 측정값은 기준 범위 안에 있으며 즉각적인 위험 신호는 없다.", "de": "Die bestätigten Messwerte liegen im Referenzbereich; ein unmittelbares Warnsignal besteht nicht.", "en": "Confirmed measurements are within the reference range and show no immediate warning signal."},
        {"ko": "장기 자료와 취약 집단 자료가 부족해 낮은 확률의 위험은 아직 배제할 수 없다.", "de": "Langzeitdaten und Daten zu vulnerablen Gruppen fehlen; ein seltenes Risiko ist noch nicht auszuschließen.", "en": "Long-term and vulnerable-group data are limited, so a low-probability risk cannot yet be ruled out."},
        {"ko": "새 검사에서 특정 조건에서만 수치가 상승하는 양상이 발견되었다.", "de": "Eine neue Prüfung zeigte erhöhte Werte nur unter bestimmten Bedingungen.", "en": "A new test found elevated values only under specific conditions."},
        {"ko": "기관은 이전 안내의 범위를 정정하고 다음 측정 시점과 문의 창구를 공개했다.", "de": "Die Behörde korrigierte den Umfang der früheren Mitteilung und veröffentlichte Messplan und Kontaktstelle.", "en": "The agency corrected the scope of its earlier notice and published the next measurement date and contact point."},
    ],
    "project_c1_accessibility_v1": [
        {"ko": "접수 기록에서 화면 읽기 사용자와 저속 인터넷 사용자의 중도 이탈률이 높았다.", "de": "Anmeldedaten zeigen höhere Abbruchquoten bei Screenreader-Nutzenden und langsamen Verbindungen.", "en": "Registration records show higher drop-off for screen-reader users and people on slow connections."},
        {"ko": "당사자 인터뷰에서는 시간 제한과 이미지로만 제시된 안내가 핵심 장벽으로 꼽혔다.", "de": "Betroffene nannten Zeitlimits und rein bildbasierte Hinweise als zentrale Barrieren.", "en": "Participants identified time limits and image-only instructions as key barriers."},
        {"ko": "운영팀은 예산과 보안 검토 때문에 모든 기능을 한 번에 바꾸기 어렵다고 설명했다.", "de": "Das Betriebsteam erklärte, Budget und Sicherheitsprüfung verhinderten eine sofortige Komplettumstellung.", "en": "The operations team said budget and security review prevent changing everything at once."},
        {"ko": "작은 시험에서는 시간 연장과 텍스트 대체 설명을 선택하게 하자 완료율이 높아졌다.", "de": "In einem Pilotversuch stieg die Abschlussquote durch wählbare Zeitverlängerung und Textalternativen.", "en": "A pilot improved completion by offering optional extra time and text alternatives."},
    ],
    "project_c1_sustainability_v1": [
        {"ko": "선택안 가는 구입비가 낮지만 매년 부품 교체가 필요하다.", "de": "Option A kostet zunächst weniger, benötigt aber jährlich Ersatzteile.", "en": "Option A costs less upfront but requires replacement parts every year."},
        {"ko": "선택안 나는 구입비가 높고 수리 교육이 필요하지만 예상 수명이 두 배다.", "de": "Option B kostet mehr und erfordert Reparaturschulung, hat aber die doppelte erwartete Lebensdauer.", "en": "Option B costs more and requires repair training, but its expected lifespan is twice as long."},
        {"ko": "실제 이용 기록에서는 겨울철 에너지 사용과 운송 거리가 총비용에 큰 영향을 주었다.", "de": "Nutzungsdaten zeigen, dass Winterenergie und Transportwege die Gesamtkosten stark beeinflussen.", "en": "Usage records show winter energy demand and transport distance strongly affect total cost."},
        {"ko": "지역 수리점은 표준 부품을 쓰면 유지비와 폐기물을 함께 줄일 수 있다고 제안했다.", "de": "Eine lokale Werkstatt schlug Standardteile vor, um Wartungskosten und Abfall zugleich zu senken.", "en": "A local repair shop proposed standard parts to reduce both maintenance cost and waste."},
    ],
    "project_c2_institution_v1": [
        {"ko": "규정은 모든 신청자에게 같은 서류 목록과 심사 기한을 적용한다고 명시한다.", "de": "Die Regel schreibt für alle Antragstellenden dieselben Unterlagen und Prüffristen vor.", "en": "The rule specifies the same document list and review deadline for every applicant."},
        {"ko": "공청회 기록에서는 돌봄 책임이 있는 사람에게 동일한 기한이 불리하다는 의견이 제기되었다.", "de": "Im Anhörungsprotokoll wurde eingewandt, dass dieselbe Frist Menschen mit Sorgepflichten benachteiligt.", "en": "The hearing record notes that the same deadline disadvantages people with care responsibilities."},
        {"ko": "이의신청 감사에서는 예외 기준이 공개되지 않아 비슷한 사건의 결과가 달랐음이 확인되었다.", "de": "Eine Beschwerdeprüfung stellte fest, dass unveröffentlichte Ausnahmen zu unterschiedlichen Ergebnissen ähnlicher Fälle führten.", "en": "An appeal audit found that unpublished exception criteria produced different outcomes in similar cases."},
        {"ko": "조정안은 기준 공개, 이유 통지, 독립 재심과 정기 감사를 함께 제안한다.", "de": "Der Vermittlungsvorschlag kombiniert veröffentlichte Kriterien, Begründung, unabhängige Prüfung und regelmäßige Audits.", "en": "The mediation proposal combines published criteria, reasoned notice, independent review, and regular audits."},
    ],
    "project_c2_narrative_v1": [
        {"ko": "당시 참가자의 일기는 결정이 현장 토론 뒤 바뀌었다고 기록한다.", "de": "Das Tagebuch eines Beteiligten hält fest, dass die Entscheidung nach einer Debatte vor Ort geändert wurde.", "en": "A participant's diary records that the decision changed after an on-site debate."},
        {"ko": "공식 보고서는 결정을 예정된 절차의 연속으로 서술하고 토론은 언급하지 않는다.", "de": "Der offizielle Bericht beschreibt die Entscheidung als planmäßigen Ablauf und erwähnt die Debatte nicht.", "en": "The official report presents the decision as a planned sequence and does not mention the debate."},
        {"ko": "반대 측 구술 기록은 발언 기회가 제한되어 합의라는 표현이 과장되었다고 주장한다.", "de": "Eine mündliche Gegenquelle behauptet, begrenzte Redezeit mache die Bezeichnung Konsens übertrieben.", "en": "An opposing oral history says limited speaking time makes the label consensus misleading."},
        {"ko": "보관소 메모는 세 자료의 작성 목적과 공개 시점이 달라 침묵 자체도 해석해야 한다고 적는다.", "de": "Eine Archivnotiz betont unterschiedliche Zwecke und Veröffentlichungszeiten; auch Auslassungen seien zu deuten.", "en": "An archive memo notes differing purposes and publication dates, so omissions also require interpretation."},
    ],
    "project_c2_framing_v1": [
        {"ko": "제목은 주민이 변화를 거부했다고 쓰지만 본문에는 조건부 찬성 의견도 포함되어 있다.", "de": "Die Überschrift sagt, Anwohnende lehnten die Änderung ab; der Text enthält jedoch bedingte Zustimmung.", "en": "The headline says residents rejected the change, while the article includes conditional support."},
        {"ko": "안내문은 정상 이용자라는 표현을 써 특정 이용 방식을 기준으로 삼는다.", "de": "Die Mitteilung verwendet normale Nutzende und setzt damit eine bestimmte Nutzungsweise als Maßstab.", "en": "The notice uses normal users, treating one way of using the service as the standard."},
        {"ko": "영향을 받은 집단은 문제가 개인 능력이 아니라 설계 선택에서 생겼다고 설명한다.", "de": "Die betroffene Gruppe erklärt, das Problem entstehe durch Designentscheidungen, nicht durch individuelle Fähigkeiten.", "en": "The affected group explains that the problem comes from design choices, not individual ability."},
        {"ko": "수정안은 행위 주체와 제약을 명시하고 가치 판단과 확인된 사실을 구분한다.", "de": "Die Neufassung nennt Handelnde und Einschränkungen und trennt Wertung von bestätigten Tatsachen.", "en": "The revision names actors and constraints and separates value judgments from confirmed facts."},
    ],
    "project_c2_technology_v1": [
        {"ko": "시스템 기록에는 입력 자료 버전, 모델 버전, 결정 시각과 담당 부서가 남아 있다.", "de": "Das Systemprotokoll enthält Datenversion, Modellversion, Entscheidungszeit und zuständige Stelle.", "en": "The system log records data version, model version, decision time, and responsible office."},
        {"ko": "영향 보고서는 전체 정확도는 높지만 한 집단의 오류율이 두 배라고 밝힌다.", "de": "Der Wirkungsbericht nennt hohe Gesamtgenauigkeit, aber eine doppelte Fehlerquote für eine Gruppe.", "en": "The impact report shows high overall accuracy but twice the error rate for one group."},
        {"ko": "이의신청 사례에서는 자동 결정의 이유가 제공되지 않아 잘못된 자료를 정정하지 못했다.", "de": "In einem Beschwerdefall fehlte eine Begründung, sodass falsche Daten nicht berichtigt werden konnten.", "en": "In one appeal, no reason was provided, preventing correction of inaccurate data."},
        {"ko": "책임 헌장 초안은 사람의 재검토, 기록 보존, 독립 감사와 중단 권한을 지정한다.", "de": "Der Chartaentwurf legt menschliche Prüfung, Protokollaufbewahrung, unabhängige Audits und Abschaltbefugnis fest.", "en": "The draft charter assigns human review, record retention, independent audit, and suspension authority."},
    ],
}

SOURCE_ROLES = [
    ["support", "context"],
    ["limitation", "contrast", "context"],
    ["complement", "support", "stakeholderPerspective", "context"],
    ["limitation", "counterexample", "contrast", "context"],
]


def localized(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


def project_key(project_id: str) -> str:
    return project_id.removeprefix("project_").removesuffix("_v1")


def basic_definition(segment: dict[str, Any]) -> dict[str, Any]:
    requirement = segment["assessmentRequirements"][0]
    mode = requirement["evidenceMode"]
    spec = BASIC_SPECS.get(segment["id"])
    if spec is None:
        raise ValueError(f"{segment['id']} requires a reviewed productive spec")
    example: str = spec["sample"]
    prompt = localized(*spec["task"])
    role = localized(
        "필수 의미를 빠뜨리지 말고 관계에 맞는 말투와 문장 끝맺음을 사용하세요.",
        "Drücke alle geforderten Bedeutungen aus und verwende die passende Anrede und Satzendung.",
        "Express every required meaning and use the appropriate register and sentence ending.",
    )
    if mode == "dictation":
        if spec.get("exact") is not True or spec.get("slots"):
            raise ValueError(f"{segment['id']} dictation must be an exact reviewed answer")
        criteria = [{
            "id": "dictated_utterance",
            "kind": "exactAnswer",
            "acceptedVariants": [example],
            "weight": 1,
            "requiredForPass": True,
        }]
        min_points = max(4, len(example.rstrip(".?")))
    else:
        slots = spec.get("slots")
        identity_equality = spec.get("identityEquality") is True
        if spec.get("exact") or (
            not identity_equality and (not isinstance(slots, list) or not slots)
        ):
            raise ValueError(f"{segment['id']} production requires reviewed meaning slots")
        criteria = ([{
            "id": "same_identity_across_registers",
            "kind": "sameIdentityAcrossRegisters",
            "acceptedVariants": ["typed_identity_capture_v1"],
            "weight": 3,
            "requiredForPass": True,
        }] if identity_equality else [{
            "id": slot_id,
            "kind": "tokenSequence",
            "acceptedVariants": variants,
            "weight": 1,
            "requiredForPass": True,
        } for slot_id, variants in slots])
        endings = spec.get("endings")
        if endings is None:
            endings = (
                ["습니다", "합니다", "입니다", "아닙니다", "겠습니다", "집니다", "바랍니다", "까요"]
                if segment["level"] == "b2"
                else ["요", "니다", "세요", "습니다", "합니다"]
            )
        criteria.append({
            "id": "complete_ending",
            "kind": "sentenceEnding",
            "acceptedVariants": endings,
            "weight": 1,
            "requiredForPass": True,
        })
        minimums = {
            "a1": {"guidedProduction": 6, "connectedProduction": 12, "openWriting": 20},
            "a2": {"guidedProduction": 12, "connectedProduction": 18, "openWriting": 30},
            "b1": {"guidedProduction": 20, "connectedProduction": 28, "openWriting": 40},
            "b2": {"guidedProduction": 28, "connectedProduction": 40, "openWriting": 60},
        }
        min_points = minimums[segment["level"]][mode]
        if mode == "openWriting":
            criteria.append({
                "id": "reasoning_link",
                "kind": "tokenSequence",
                "acceptedVariants": ["하지만", "그래서", "따라서", "때문에", "반면에", "다만", "그러나"],
                "weight": 1,
                "requiredForPass": True,
            })
    return {
        "canDoSegmentId": segment["id"],
        "assessmentItemId": requirement["assessmentItemId"],
        "missionContentLinkId": requirement["missionContentLinkId"],
        "level": segment["level"],
        "courseUnitId": segment["parentCourseUnitId"],
        "conceptIds": segment["requiredConceptIds"],
        "evidenceMode": mode,
        "rubricVersion": requirement["rubricVersion"],
        "minimumScore": requirement["minimumScore"],
        "prompt": prompt,
        "roleInstruction": role,
        "prerequisiteAssessmentItemIds": [],
        "grammarReferenceIds": [],
        "authoredContextExamples": [example],
        "textRubric": {
            "minInputCodePoints": min_points,
            "maxInputCodePoints": 720 if mode == "openWriting" else 480,
            "requiredStructuredSlotIds": [],
            "minimumDistinctSourceSpanIds": 0,
            "requiredSourceSnippetIds": [],
            "oneOfSourceGroups": [],
            "discourseMarkerGroups": [],
            "criteria": criteria,
        },
    }


def c_definitions(
    segment: dict[str, Any],
    project_id: str,
    step_order: int,
    earlier_assessment_ids: list[str],
) -> list[dict[str, Any]]:
    requirements = {item["evidenceMode"]: item for item in segment["assessmentRequirements"]}
    key = project_key(project_id)
    snippets = [f"snippet_{key}_{index:02d}_v1" for index in range(1, 5)]
    if step_order == 2:
        required_sources = snippets[:2]
        one_of_sources: list[list[str]] = []
    else:
        required_sources = snippets[2:]
        one_of_sources = [snippets[:2]]
    title = segment["title"]
    common = {
        "canDoSegmentId": segment["id"],
        "level": segment["level"],
        "courseUnitId": segment["parentCourseUnitId"],
        "conceptIds": segment["requiredConceptIds"],
        "rubricVersion": 1,
        "minimumScore": 0.7,
        "grammarReferenceIds": [],
        "authoredContextExamples": [],
    }
    if segment["id"] == "segment_c2_procedural_legitimacy":
        common["grammarReferenceIds"] = ["grammar_c2_even_if_concession"]
        common["authoredContextExamples"] = ["절차가 오래 걸린다고 치더라도 이유 통지와 이의제기 권리는 보장해야 합니다."]
    if segment["id"] == "segment_c2_interpretation_justification":
        common["grammarReferenceIds"] = ["grammar_c2_fortunate_counterfactual"]
        common["authoredContextExamples"] = ["반대 기록이 남아 있었기에 망정이지 공식 서술만으로는 침묵의 의미를 알기 어려웠습니다."]
    write_req = requirements["openWriting"]
    writing = {
        **common,
        "assessmentItemId": write_req["assessmentItemId"],
        "missionContentLinkId": write_req["missionContentLinkId"],
        "evidenceMode": "openWriting",
        "prompt": localized(
            f"프로젝트 자료를 연결해 ‘{title['ko']}’에 관한 120자 이상의 판단문을 작성하세요.",
            f"Verknüpfe die Projektquellen zu einer koreanischen Beurteilung von mindestens 120 Zeichen zum Thema „{title['de']}“.",
            f"Connect the project sources in a Korean judgment of at least 120 characters about “{title['en']}.”",
        ),
        "roleInstruction": localized(
            "주장·근거·한계·결론 네 칸을 모두 본문에 쓰고, 각 칸을 자료 구간과 연결하세요.",
            "Fülle Behauptung, Evidenz, Grenze und Schluss aus, verwende alles im Text und verknüpfe jeden Teil mit Quellen.",
            "Complete claim, evidence, limitation, and conclusion; include each in the text and link each to sources.",
        ),
        "prerequisiteAssessmentItemIds": earlier_assessment_ids,
        "textRubric": {
            "minInputCodePoints": 120,
            "maxInputCodePoints": 1200,
            "requiredStructuredSlotIds": ["claim", "evidence", "limitation", "conclusion"],
            "minimumDistinctSourceSpanIds": 2 if step_order == 2 else 3,
            "requiredSourceSnippetIds": required_sources,
            "oneOfSourceGroups": one_of_sources,
            "discourseMarkerGroups": [["우선", "첫째"], ["그러나", "반면에"], ["따라서", "그러므로"]],
            "criteria": [
                {"id": "formal_conclusion", "kind": "sentenceEnding", "acceptedVariants": ["습니다", "합니다", "입니다"], "weight": 1, "requiredForPass": True},
                {"id": "specificity", "kind": "tokenSequence", "acceptedVariants": ["구체적으로", "예를 들어"], "weight": 1, "requiredForPass": False},
            ],
        },
    }
    oral_req = requirements["oralProduction"]
    oral_prerequisites = list(dict.fromkeys([*earlier_assessment_ids, write_req["assessmentItemId"]]))
    oral = {
        **common,
        "assessmentItemId": oral_req["assessmentItemId"],
        "missionContentLinkId": oral_req["missionContentLinkId"],
        "evidenceMode": "oralProduction",
        "prompt": localized(
            "통과한 판단문의 메모만 바탕으로 원문을 읽지 말고 45초에서 120초 동안 근거와 한계를 설명하세요.",
            "Sprich 45 bis 120 Sekunden frei anhand der Notizen deines bestandenen Textes; lies den Ausgangstext nicht vor und erkläre Belege und Grenzen.",
            "Speak unscripted for 45 to 120 seconds from notes based on your passed writing; do not read the original text, and explain evidence and limitations.",
        ),
        "roleInstruction": localized(
            "주장·근거·한계·결론을 말하고 자료 번호와 우선·그러나·따라서 같은 연결 표현을 사용하세요. 음성과 인식 원문은 저장되지 않습니다.",
            "Nenne Behauptung, Beleg, Grenze und Schluss, verweise auf die Quellenzahlen und nutze Verknüpfungen wie zuerst, jedoch und daher. Audio und Transkript werden nicht gespeichert.",
            "State the claim, evidence, limitation, and conclusion; mention source numbers and use links such as first, however, and therefore. Audio and transcript are not stored.",
        ),
        "prerequisiteAssessmentItemIds": oral_prerequisites,
        "oralRubric": {
            "minimumPronunciation": 0.7,
            "minimumAccuracy": 0.7,
            "minimumFluency": 0.7,
            "minimumDurationMilliseconds": 45000,
            "maximumDurationMilliseconds": 120000,
            "minimumTranscriptCodePoints": 120,
            "requiredSemanticSlotIds": ["claim", "evidence", "limitation", "conclusion"],
            "semanticSlotMentionVariants": {
                "claim": ["제 판단부터 말하면", "핵심부터 말씀드리면", "제가 내린 판단은"],
                "evidence": ["그 판단의 근거로", "이를 뒷받침하는 자료로", "근거를 말씀드리면"],
                "limitation": ["다만 주의할 한계는", "그렇지만 이 판단의 한계는", "여기서 확정하기 어려운 점은"],
                "conclusion": ["종합해서 말씀드리면", "이 자료들을 함께 보면", "마지막으로 제안하면"],
            },
            "requiredSourceSnippetIds": required_sources,
            "oneOfSourceGroups": one_of_sources,
            "sourceMentionVariants": {
                source_id: [
                    ["첫 번째 자료", "자료 1"],
                    ["두 번째 자료", "자료 2"],
                    ["세 번째 자료", "자료 3"],
                    ["네 번째 자료", "자료 4"],
                ][index]
                for index, source_id in enumerate(snippets[:2] if step_order == 2 else snippets)
            },
            "discourseMarkerGroups": [["우선", "첫째"], ["그러나", "반면에"], ["따라서", "그러므로"]],
        },
    }
    evidence_req = requirements["connectedEvidence"]
    if step_order == 2:
        required_roles = ["support", "limitation"]
        relationships = [
            {"id": "support_source", "role": "support", "oneOfSourceSnippetIds": [snippets[0]]},
            {"id": "limitation_source", "role": "limitation", "oneOfSourceSnippetIds": [snippets[1]]},
        ]
    else:
        required_roles = ["complement", "counterexample", "context"]
        relationships = [
            {"id": "new_support", "role": "complement", "oneOfSourceSnippetIds": [snippets[2]]},
            {"id": "counter_source", "role": "counterexample", "oneOfSourceSnippetIds": [snippets[3]]},
            {"id": "earlier_context", "role": "context", "oneOfSourceSnippetIds": snippets[:2]},
        ]
    connected = {
        **common,
        "assessmentItemId": evidence_req["assessmentItemId"],
        "missionContentLinkId": evidence_req["missionContentLinkId"],
        "evidenceMode": "connectedEvidence",
        "prompt": localized(
            "현재 프로젝트 단계의 자료를 역할에 맞게 연결하고 출처 관계를 확인하세요.",
            "Verknüpfe die Quellen dieses Projektschritts mit den vorgegebenen Rollen und prüfe ihre Herkunft.",
            "Connect the current project-step sources to the authored roles and verify provenance.",
        ),
        "roleInstruction": localized(
            "자료마다 지지·한계·맥락 중 정해진 관계만 지정하세요.",
            "Ordne jeder Quelle nur die vorgegebene Beziehung wie Stütze, Grenze oder Kontext zu.",
            "Assign only the authored relationship, such as support, limitation, or context, to each source.",
        ),
        "prerequisiteAssessmentItemIds": earlier_assessment_ids,
        "connectedEvidenceRubric": {
            "minimumSourceNodes": 2 if step_order == 2 else 3,
            "requiredRoles": required_roles,
            "requiredSourceSnippetIds": required_sources,
            "oneOfSourceGroups": one_of_sources,
            "relationshipRequirements": relationships,
            "requireProvenance": True,
        },
    }
    return [writing, oral, connected]


def build() -> dict[str, Any]:
    source = json.loads(SEGMENTS_PATH.read_text(encoding="utf-8"))
    segments: list[dict[str, Any]] = source["segments"]
    basic_segment_ids = {
        segment["id"]
        for segment in segments
        if segment["level"] not in {"c1", "c2"}
    }
    if basic_segment_ids != set(BASIC_SPECS):
        missing = sorted(basic_segment_ids.difference(BASIC_SPECS))
        extra = sorted(set(BASIC_SPECS).difference(basic_segment_ids))
        raise ValueError(
            f"reviewed productive spec mismatch; missing={missing}, extra={extra}"
        )
    clusters = {cluster["id"]: cluster for cluster in source["contentClusters"]}
    definitions = [basic_definition(segment) for segment in segments if segment["level"] not in {"c1", "c2"}]
    project_segments: dict[str, list[dict[str, Any]]] = {}
    for segment in segments:
        if segment["level"] not in {"c1", "c2"}:
            continue
        cluster = clusters[segment["contentClusterIds"][0]]
        project_refs = [ref["id"] for ref in cluster["contentReferences"] if ref["kind"] == "project"]
        if len(project_refs) != 1:
            raise ValueError(f"{segment['id']} must have one project reference")
        project_segments.setdefault(project_refs[0], []).append(segment)

    projects: list[dict[str, Any]] = []
    snippets: list[dict[str, Any]] = []
    bundles: list[dict[str, Any]] = []
    for project_id, paired in sorted(project_segments.items()):
        if project_id not in PROJECT_SOURCES or len(paired) != 2:
            raise ValueError(f"{project_id} must own exactly two advanced segments")
        paired.sort(key=lambda segment: segment["order"])
        key = project_key(project_id)
        step_ids = [f"step_{key}_{index:02d}_v1" for index in range(1, 5)]
        snippet_ids = [f"snippet_{key}_{index:02d}_v1" for index in range(1, 5)]
        assessment_ids = [
            [item["assessmentItemId"] for item in paired[0]["assessmentRequirements"]],
            [item["assessmentItemId"] for item in paired[1]["assessmentRequirements"]],
        ]
        actions = [
            localized("첫 자료의 주장과 출처를 확인하세요.", "Prüfe Aussage und Herkunft der ersten Quelle.", "Check the first source's claim and provenance."),
            localized("첫 두 자료를 비교해 중간 판단을 완성하세요.", "Vergleiche die ersten beiden Quellen und formuliere ein Zwischenurteil.", "Compare the first two sources and complete an interim judgment."),
            localized("반례나 새로운 관점이 담긴 세 번째 자료를 검토하세요.", "Prüfe die dritte Quelle mit Gegenbeispiel oder neuer Perspektive.", "Review the third source containing a counterpoint or new perspective."),
            localized("네 자료를 종합해 한계와 책임을 포함한 최종 설명을 완성하세요.", "Führe alle vier Quellen zu einer Erklärung mit Grenzen und Verantwortung zusammen.", "Synthesize all four sources into a final explanation including limits and responsibility."),
        ]
        steps = []
        for index in range(4):
            steps.append({
                "id": step_ids[index],
                "order": index + 1,
                "snippetIds": snippet_ids[: index + 1],
                "prerequisiteStepIds": [] if index == 0 else [step_ids[index - 1]],
                "action": actions[index],
                "assessmentItemIds": assessment_ids[0] if index == 1 else (assessment_ids[1] if index == 3 else []),
            })
        projects.append({"id": project_id, "steps": steps})
        for index, body in enumerate(PROJECT_SOURCES[project_id]):
            snippets.append({
                "id": snippet_ids[index],
                "projectId": project_id,
                "stepId": step_ids[index],
                "provenance": localized(
                    f"한글소리 독자 제작 프로젝트 자료 {index + 1}",
                    f"Hangul Sori, eigenständig erstellte Projektquelle {index + 1}",
                    f"Hangul Sori first-party project source {index + 1}",
                ),
                "text": body,
                "supportedRoles": SOURCE_ROLES[index],
            })
        earlier_ids: list[str] = []
        for pair_index, segment in enumerate(paired):
            step_order = 2 if pair_index == 0 else 4
            built = c_definitions(segment, project_id, step_order, earlier_ids)
            definitions.extend(built)
            ids = [definition["assessmentItemId"] for definition in built]
            bundles.append({
                "canDoSegmentId": segment["id"],
                "projectId": project_id,
                "stepId": step_ids[1] if pair_index == 0 else step_ids[3],
                "assessmentItemIds": ids,
            })
            earlier_ids = ids

    result = {
        "schemaVersion": 1,
        "definitions": definitions,
        "projects": projects,
        "sourceSnippets": snippets,
        "bundles": bundles,
    }
    if (
        len(definitions) != 118
        or len(projects) != 8
        or len(snippets) != 32
        or len(bundles) != 16
    ):
        raise ValueError("productive catalog count contract failed")
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = json.dumps(build(), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not OUTPUT_PATH.exists() or OUTPUT_PATH.read_text(encoding="utf-8") != rendered:
            raise SystemExit(
                "draft productive_assessments.json is stale; regenerate it"
            )
        return
    OUTPUT_PATH.write_text(rendered, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
