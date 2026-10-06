from __future__ import annotations

import csv
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
LOCALIZATION = ROOT / "tools/content_factory/review/living_korea_localization_20261006.json"
FIRST = ROOT / "tools/content_factory/drafts/living_korea_scene_first_drafts_20261005.json"
SECOND = ROOT / "tools/content_factory/drafts/living_korea_second_wave_scene_first_drafts_20261005.json"
MINING = ROOT / "tools/content_factory/review/living_korea_language_mining_20261005.json"
MINING2 = ROOT / "tools/content_factory/review/living_korea_second_wave_language_mining_20261005.json"
GRAMMAR = ROOT / "assets/data/grammar.csv"
DRAFT = ROOT / "tools/content_factory/drafts/living_korea_scenarios_20261006.json"
REVIEW = ROOT / "tools/content_factory/review/living_korea_scenarios_20261006.csv"
MANIFEST = ROOT / "tools/content_factory/drafts/batch_39_living_korea_manifest.json"

META = {
"b1_maya_daniel_ai_campaign_cut":("b1_03_work_softening","concept_b1_softening","b1_team","office","business","🎬"),
"b2_daniel_sujin_ai_asset_handoff":("b2_03_precise_requests","concept_b2_precise_requests","b2_meeting","office","business","🗂️"),
"b1_sujin_christian_asset_provenance_check":("b1_06_life_capstone","concept_b1_life","b1_partner","home","intimate","📁"),
"a2_jun_minho_class_phone_rule":("a2_06_study_work","concept_a2_work_study","a2_work","home","intimate","📵"),
"b1_jun_andrea_phone_house_rules":("b1_04_relationships","concept_b1_relationships","b1_partner","home","intimate","📱"),
"b1_jun_christian_phone_study_habit":("b1_04_relationships","concept_b1_relationships","b1_friends","cafe","polite","📚"),
"a2_dongsun_christian_suspicious_delivery_text":("a2_05_delivery_services","concept_a2_services","a2_delivery","home","polite","📦"),
"b1_christian_sujin_suspicious_text_followup":("b1_06_life_capstone","concept_b1_life","b1_partner","home","intimate","🔐"),
"b1_sujin_byeongcheol_family_verification_rule":("b1_06_life_capstone","concept_b1_life","b1_partner","home","intimate","☎️"),
"b1_andrea_minho_friday_schedule":("b1_04_relationships","concept_b1_relationships","b1_partner","home","intimate","🗓️"),
"b2_sujin_minho_shorter_hours_tradeoff":("b2_02_professional_opinion","concept_b2_opinion","b2_meeting","office","polite","⏱️"),
"b2_hyuna_andrea_work_family_choices":("b2_02_professional_opinion","concept_b2_opinion","b2_public","cafe","polite","⚖️"),
"b1_andrea_minho_family_calendar":("b1_04_relationships","concept_b1_relationships","b1_partner","home","intimate","📅"),
"b1_dongsun_sujin_repair_price":("b1_03_work_softening","concept_b1_softening","b1_repair","market","casual","🛠️"),
"b1_dongsun_maya_price_notice":("b1_03_work_softening","concept_b1_softening","b1_team","market","polite","🏷️"),
"b1_lena_hyuna_crowded_weekend":("b1_01_experience_reasons","concept_b1_reasons_experience","b1_friends","cafe","casual","🚶"),
"b2_hyuna_daniel_resident_flow_filming":("b2_03_precise_requests","concept_b2_precise_requests","b2_travel","directions","business","🎥"),
"b1_lena_maya_beyond_music":("b1_01_experience_reasons","concept_b1_reasons_experience","b1_fandom","cafe","casual","🎧"),
"b2_maya_daniel_tradition_reinterpretation":("b2_02_professional_opinion","concept_b2_opinion","b2_evidence","office","business","💍"),
"b2_hyuna_daniel_gyeongju_after_apec":("b2_02_professional_opinion","concept_b2_opinion","b2_evidence","directions","business","🏯"),
"b2_hyuna_sujin_gyeongju_fieldnotes":("b2_02_professional_opinion","concept_b2_opinion","b2_evidence","cafe","casual","📝"),
"a2_lena_hyuna_heatwave_plan":("a2_02_plans_proposals","concept_proposal_casual","a2_plan","cafe","casual","☀️"),
"b2_byeongcheol_sujin_heat_electricity":("b2_06_advanced_capstone","concept_b2_advanced","b2_partner","home","intimate","⚡"),
}

TITLE = {
"b1_maya_daniel_ai_campaign_cut":("AI 장면 표시 정하기","KI-Szenen kennzeichnen","Labeling AI scenes"),
"b2_daniel_sujin_ai_asset_handoff":("이미지 출처를 정리해 넘기기","Bildherkunft für die Übergabe ordnen","Organizing image provenance for handoff"),
"b1_sujin_christian_asset_provenance_check":("예전 파일 기록 확인하기","Alte Dateiverläufe prüfen","Checking old file records"),
"a2_jun_minho_class_phone_rule":("수업 중 휴대폰 예외 설명하기","Ausnahmen bei der Handynutzung im Unterricht erklären","Explaining classroom phone exceptions"),
"b1_jun_andrea_phone_house_rules":("집에서 지킬 휴대폰 규칙 정하기","Handyregeln für zu Hause vereinbaren","Agreeing on phone rules at home"),
"b1_jun_christian_phone_study_habit":("휴대폰 공부 습관 비교하기","Handygewohnheiten beim Lernen vergleichen","Comparing phone habits while studying"),
"a2_dongsun_christian_suspicious_delivery_text":("수상한 택배 문자 확인하기","Eine verdächtige Paket-SMS prüfen","Checking a suspicious delivery text"),
"b1_christian_sujin_suspicious_text_followup":("피싱 문자 확인 결과 나누기","Das Ergebnis einer Phishing-Prüfung besprechen","Sharing the result of a phishing check"),
"b1_sujin_byeongcheol_family_verification_rule":("가족 링크 확인 규칙 정하기","Eine Familienregel zum Prüfen von Links festlegen","Setting a family rule for checking links"),
"b1_andrea_minho_friday_schedule":("금요일 오후 일정 맞추기","Den Freitagnachmittag abstimmen","Coordinating Friday afternoon"),
"b2_sujin_minho_shorter_hours_tradeoff":("근무시간 단축의 조건 따져 보기","Bedingungen kürzerer Arbeitszeiten abwägen","Weighing the conditions for shorter hours"),
"b2_hyuna_andrea_work_family_choices":("통계와 개인 선택 구분하기","Statistik und persönliche Entscheidungen auseinanderhalten","Separating statistics from personal choices"),
"b1_andrea_minho_family_calendar":("가족 일정을 셋이 맞추기","Den Familienkalender zu dritt abstimmen","Coordinating the family calendar together"),
"b1_dongsun_sujin_repair_price":("수리 가격 다시 계산하기","Reparaturpreise neu durchrechnen","Reworking repair prices"),
"b1_dongsun_maya_price_notice":("가격 변경 안내문 다듬기","Eine Preisänderung klar ankündigen","Writing a clear price-change notice"),
"b1_lena_hyuna_crowded_weekend":("붐비는 동네 방문 시간 바꾸기","Die Besuchszeit für ein volles Viertel ändern","Changing the time for a crowded neighborhood visit"),
"b2_hyuna_daniel_resident_flow_filming":("주민 동선을 막지 않고 촬영하기","Filmen, ohne Anwohnerwege zu blockieren","Filming without blocking residents"),
"b1_lena_maya_beyond_music":("음악 밖으로 넓어진 한류 이야기","Hallyu über Musik hinaus","Talking about Hallyu beyond music"),
"b2_maya_daniel_tradition_reinterpretation":("전통과 재해석 구분하기","Tradition und Neuinterpretation unterscheiden","Separating tradition from reinterpretation"),
"b2_hyuna_daniel_gyeongju_after_apec":("APEC 이후 경주 기록하기","Gyeongju nach der APEC dokumentieren","Documenting Gyeongju after APEC"),
"b2_hyuna_sujin_gyeongju_fieldnotes":("경주 답사 메모와 사실 나누기","Feldnotizen und Fakten in Gyeongju trennen","Separating field notes from facts in Gyeongju"),
"a2_lena_hyuna_heatwave_plan":("폭염에 맞춰 약속 시간 바꾸기","Pläne an die Hitze anpassen","Changing plans for a heatwave"),
"b2_byeongcheol_sujin_heat_electricity":("더운 날 전기 이상에 대응하기","Bei Hitze sicher auf elektrische Probleme reagieren","Responding safely to electrical problems in hot weather"),
}

INTRO = {
"b1_maya_daniel_ai_campaign_cut":("마야와 다니엘이 캠페인 영상에서 실제 촬영본과 AI 생성 장면을 구분하고 게시 방식을 정해요.","Maya und Daniel unterscheiden im Kampagnenvideo echtes Filmmaterial von KI-generierten Szenen und legen die Kennzeichnung fest.","Maya and Daniel separate real footage from AI-generated scenes in a campaign video and decide how to label them."),
"b2_daniel_sujin_ai_asset_handoff":("다니엘과 수진이 실제 사진과 생성 이미지를 구분해 앱 자산을 넘기는 기준을 맞춰요.","Daniel und Sujin legen fest, wie echte Fotos und generierte Bilder bei der Übergabe von App-Material getrennt werden.","Daniel and Sujin agree on how to separate real photos from generated images when handing off app assets."),
"b1_sujin_christian_asset_provenance_check":("수진과 크리스티안이 오래된 파일의 제작 기록을 확인하되 모르는 보안 정보는 추측하지 않아요.","Sujin und Christian prüfen die Herkunft älterer Dateien, ohne unbekannte Sicherheitsdetails zu erraten.","Sujin and Christian check the provenance of older files without guessing about security details they cannot verify."),
"a2_jun_minho_class_phone_rule":("준이 민호에게 학교의 휴대폰 규칙과 수업별 예외를 설명해요.","Jun erklärt Minho die Handyregeln der Schule und die Ausnahmen im Unterricht.","Jun explains the school phone rules and the exceptions that apply in class."),
"b1_jun_andrea_phone_house_rules":("준과 안드레아가 학교 규칙과 집에서 지킬 휴대폰 규칙을 따로 정해요.","Jun und Andrea unterscheiden Schulregeln von ihren Handyregeln zu Hause.","Jun and Andrea separate school rules from the phone rules they want at home."),
"b1_jun_christian_phone_study_habit":("준과 크리스티안이 수업 중 휴대폰 사용과 공부 습관을 비교해요.","Jun und Christian vergleichen Handynutzung im Unterricht und ihre Lerngewohnheiten.","Jun and Christian compare phone use in class and their study habits."),
"a2_dongsun_christian_suspicious_delivery_text":("동선과 크리스티안이 수상한 택배 문자를 링크 대신 공식 앱에서 확인해요.","Dongsun und Christian prüfen eine verdächtige Paket-SMS direkt in der offiziellen App statt über den Link.","Dongsun and Christian verify a suspicious delivery text in the official app instead of using the link."),
"b1_christian_sujin_suspicious_text_followup":("크리스티안이 수진에게 피싱으로 보인 택배 문자와 공식 앱에서 확인한 결과를 알려 줘요.","Christian erzählt Sujin von der verdächtigen Paket-SMS und dem Ergebnis der Prüfung in der offiziellen App.","Christian tells Sujin about the suspicious delivery text and what he confirmed in the official app."),
"b1_sujin_byeongcheol_family_verification_rule":("수진과 병철이 가족에게 온 링크와 송금 요청을 먼저 확인하는 간단한 규칙을 정해요.","Sujin und Byeongcheol vereinbaren eine einfache Familienregel: Links und Geldforderungen werden zuerst geprüft.","Sujin and Byeongcheol agree on a simple family rule for checking links and money requests first."),
"b1_andrea_minho_friday_schedule":("안드레아와 민호가 금요일 근무시간 변화 가능성을 가족 일정과 함께 조율해요.","Andrea und Minho stimmen eine mögliche Änderung der Freitagsarbeitszeit mit ihrem Familienplan ab.","Andrea and Minho coordinate a possible change in Friday work hours with their family schedule."),
"b2_sujin_minho_shorter_hours_tradeoff":("수진과 민호가 근무시간을 줄일 때 업무량과 회의를 함께 줄여야 하는지 이야기해요.","Sujin und Minho sprechen darüber, ob bei kürzeren Arbeitszeiten auch Arbeitsmenge und Meetings sinken müssen.","Sujin and Minho discuss whether shorter working hours also require cutting workload and meetings."),
"b2_hyuna_andrea_work_family_choices":("현아와 안드레아가 통계가 보여 주는 흐름과 개인의 서로 다른 선택 조건을 구분해요.","Hyuna und Andrea unterscheiden statistische Trends von den unterschiedlichen Bedingungen persönlicher Entscheidungen.","Hyuna and Andrea distinguish statistical trends from the different conditions behind personal choices."),
"b1_andrea_minho_family_calendar":("안드레아와 민호가 준의 의견도 포함해 가족 일정을 함께 맞추기로 해요.","Andrea und Minho beschließen, den Familienkalender gemeinsam mit Jun abzustimmen.","Andrea and Minho decide to coordinate the family schedule together with Jun."),
"b1_dongsun_sujin_repair_price":("동선과 수진이 재료비와 작업시간을 보며 어떤 수리 가격부터 조정할지 정해요.","Dongsun und Sujin überlegen anhand von Materialkosten und Arbeitszeit, welche Reparaturpreise zuerst angepasst werden sollten.","Dongsun and Sujin use material costs and work time to decide which repair prices should change first."),
"b1_dongsun_maya_price_notice":("동선과 마야가 손님이 이해하기 쉬운 가격 변경 안내 문구를 만들어요.","Dongsun und Maya formulieren eine klare Preisänderungsankündigung für die Kundschaft.","Dongsun and Maya write a clear price-change notice for customers."),
"b1_lena_hyuna_crowded_weekend":("레나와 현아가 붐비는 동네를 방문할 시간을 바꾸며 주민 생활도 고려해요.","Lena und Hyuna verschieben ihren Besuch in einem vollen Viertel und berücksichtigen dabei den Alltag der Anwohner.","Lena and Hyuna change the time of a visit to a crowded neighborhood while considering local residents."),
"b2_hyuna_daniel_resident_flow_filming":("현아와 다니엘이 주민 통행을 막지 않으면서 골목을 촬영할 방법을 정해요.","Hyuna und Daniel planen einen Dreh in einer Gasse, ohne die Wege der Anwohner zu blockieren.","Hyuna and Daniel plan how to film an alley without blocking residents' access."),
"b1_lena_maya_beyond_music":("레나와 마야가 음악에서 시작해 음식·책·여행으로 넓어진 한국 문화 관심을 이야기해요.","Lena und Maya sprechen darüber, wie ihr Interesse an koreanischer Kultur von Musik auf Essen, Bücher und Reisen übergegangen ist.","Lena and Maya talk about how an interest that began with music expanded to food, books, and travel."),
"b2_maya_daniel_tradition_reinterpretation":("마야와 다니엘이 전통 장신구의 원래 맥락과 현대적 재해석을 분명히 구분해요.","Maya und Daniel trennen den ursprünglichen Kontext traditionellen Schmucks klar von ihrer modernen Neuinterpretation.","Maya and Daniel clearly separate the original context of traditional jewelry from their modern reinterpretation."),
"b2_hyuna_daniel_gyeongju_after_apec":("현아와 다니엘이 APEC 행사 기록과 경주의 기존 문화유산을 섞지 않고 도시의 현재 모습을 기록해요.","Hyuna und Daniel dokumentieren Gyeongju nach der APEC, ohne Veranstaltungsbilder und das bestehende Kulturerbe der Stadt zu vermischen.","Hyuna and Daniel document Gyeongju after APEC without blending event imagery into the city's existing heritage."),
"b2_hyuna_sujin_gyeongju_fieldnotes":("현아와 수진이 경주 답사에서 현장 인상과 확인해야 할 역사 사실을 따로 다뤄요.","Hyuna und Sujin trennen bei der Gyeongju-Feldrecherche persönliche Eindrücke von historischen Fakten, die noch geprüft werden müssen.","Hyuna and Sujin keep field impressions separate from historical facts that still need verification during a Gyeongju research trip."),
"a2_lena_hyuna_heatwave_plan":("레나와 현아가 폭염을 피해 산책 시간과 실내 대안을 함께 정해요.","Lena und Hyuna verlegen ihren Spaziergang wegen der Hitze und planen eine Alternative drinnen.","Lena and Hyuna change their walking time for the heatwave and plan an indoor alternative."),
"b2_byeongcheol_sujin_heat_electricity":("병철과 수진이 더운 날 전기기기를 많이 쓸 때 이상 신호가 보이면 먼저 전원을 끄기로 해요.","Byeongcheol und Sujin sprechen darüber, bei ungewöhnlichen Anzeichen zuerst den Strom auszuschalten, wenn bei Hitze viele Geräte laufen.","Byeongcheol and Sujin agree to switch off the power first if something seems wrong while many electrical devices are running in hot weather."),
}

GRAMMAR_FALLBACK = {
"b1_sujin_christian_asset_provenance_check":"grammar_a2_conditional",
"b1_andrea_minho_family_calendar":"grammar_a2_promise",
}

def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))

def normalize_pattern(value: str) -> str:
    return re.sub(r"\s+", "", value or "").replace("A/V", "V/A")

def source_scenes() -> dict[str, dict[str, Any]]:
    result={}
    for path in (FIRST,SECOND):
        p=load(path)
        for arc in p["arcs"]:
            for s in arc["scenes"]:
                result[s["id"]]=s
    return result

def mining_index() -> dict[str, dict[str, Any]]:
    result={}
    for path in (MINING,MINING2):
        p=load(path)
        result.update({s["sceneId"]:s for s in p["scenes"]})
    return result

def grammar_rows() -> tuple[list[dict[str,str]],dict[str,dict[str,str]]]:
    with GRAMMAR.open(encoding="utf-8-sig",newline="") as f:
        rows=list(csv.DictReader(f))
    return rows,{r["id"]:r for r in rows}

def choose_grammar(scene_id: str, mined: dict[str,Any], rows: list[dict[str,str]]) -> dict[str,str]:
    if scene_id in GRAMMAR_FALLBACK:
        ident=GRAMMAR_FALLBACK[scene_id]
        return next(r for r in rows if r["id"]==ident)
    for m in mined.get("grammar",[]):
        for row in rows:
            if normalize_pattern(m["pattern"])==normalize_pattern(row["pattern"]):
                return row
    raise ValueError(f"{scene_id}: no grammar mapping")

def vocab_for(scene: dict[str,Any], mined: dict[str,Any]) -> list[dict[str,str]]:
    out=[]
    seen=set()
    for item in mined.get("vocabulary",[]):
        lemma=str(item.get("lemma","")).strip()
        if lemma and lemma not in seen:
            seen.add(lemma); out.append({"korean":lemma})
    # Supplement only if a scene's deliberately narrow mining has <6 lexical items.
    source=" ".join([scene.get("realTaskKo",""), *[t["ko"] for t in scene["dialog"]]])
    for token in re.findall(r"[가-힣A-Za-z0-9·.]+",source):
        clean=token.strip(".,")
        if len(clean)<2 or clean in seen:
            continue
        if clean in {"그래서","그런데","그리고","그러면","맞아요","좋아요","그렇지","그럼","진짜"}:
            continue
        seen.add(clean); out.append({"korean":clean})
        if len(out)>=6: break
    if len(out)<6: raise ValueError(f"{scene['id']}: needs six vocab refs")
    return out[:8]

def quests(scene_id: str, turns: list[dict[str,str]], concept: str) -> list[dict[str,Any]]:
    # Three comprehension/production checks anchored only in approved scene lines.
    hearing=turns[1]
    hearing_opts=[turns[i] for i in (1,0,2,3)]
    translate=turns[4]
    ko_opts=[turns[i] for i in (4,0,2,5)]
    build=turns[5]
    return [
      {"id":f"quest_{scene_id}_01","type":"hoerverstehen","conceptIds":[concept],
       "data":{"audioKo":hearing["ko"],"options":[{"de":x["de"],"en":x["en"]} for x in hearing_opts],"correctIndex":0}},
      {"id":f"quest_{scene_id}_02","type":"uebersetzen","conceptIds":[concept],
       "data":{"promptDe":translate["de"],"promptEn":translate["en"],"options":[{"ko":x["ko"]} for x in ko_opts],"correctIndex":0}},
      {"id":f"quest_{scene_id}_03","type":"satzBauen","conceptIds":[concept],
       "data":{"targetKo":build["ko"],"audioKo":build["ko"],"promptDe":build["de"],"promptEn":build["en"],
               "distractors":["아마 다음에","그냥 아무거나","확인 없이"]}},
    ]

def main() -> None:
    localization=load(LOCALIZATION)
    loc={s["sceneId"]:s for s in localization["scenes"]}
    sources=source_scenes()
    mined=mining_index()
    grammar,grammar_by_id=grammar_rows()
    scenarios=[]
    content_links=[]
    topics=set()
    levels={}
    for sid,scene in sources.items():
        if sid not in META or sid not in TITLE or sid not in INTRO or sid not in loc:
            raise ValueError(f"{sid}: missing promotion metadata")
        unit,concept,shelf,backdrop,style,emoji=META[sid]
        g=choose_grammar(sid,mined[sid],grammar)
        localized=loc[sid]
        turns=[
          {"speaker":turn["speaker"],"ko":turn["ko"],"de":turn["deDisplay"],"en":turn["enDisplay"]}
          for turn in localized["turns"]
        ]
        title_ko,title_de,title_en=TITLE[sid]
        intro_ko,intro_de,intro_en=INTRO[sid]
        scenario={
          "id":sid,"level":scene["level"],"emoji":emoji,
          "register":style,"speechStyle":style,
          "title":{"ko":title_ko,"de":title_de,"en":title_en},
          "intro":{"ko":intro_ko,"de":intro_de,"en":intro_en},
          "courseUnitId":unit,
          "playerCharacterId":scene["playerCharacterId"],
          "participantIds":scene["participantIds"],
          "relationshipContext":scene["relationshipContextKo"],
          "intent":scene["realTaskKo"],
          "shelf":shelf,"backdrop":backdrop,
          "vocab":vocab_for(scene,mined[sid]),
          "conceptIds":[concept],"surfaceFormIds":[],
          "grammarIds":[g["id"]],
          "grammarBlock":{
             "title":{"ko":g["pattern"],"de":f"Grammatik im Kontext: {g['pattern']}","en":f"Grammar in context: {g['pattern']}"},
             "explanation":{
                "ko":f"이 장면에서 {g['pattern']} 표현이 실제 대화에서 어떤 기능을 하는지 확인해요.",
                "de":g.get("explanation_de") or f"Achte darauf, wie {g['pattern']} in dieser Szene im Kontext verwendet wird.",
                "en":g.get("explanation_en") or f"Notice how {g['pattern']} is used in context in this scene.",
             },
          },
          "dialog":turns,
          "quests":quests(sid,turns,concept),
          "xpReward":120,
        }
        scenarios.append(scenario)
        content_links.append({"contentKind":"scenario","contentId":sid,"courseUnitId":unit,"conceptIds":[concept],"role":"assess"})
        levels[scene["level"]]=levels.get(scene["level"],0)+1
        topics.add(localized["canonicalNativeUsageTopicId"])
    if len(scenarios)!=23:
        raise ValueError(f"expected 23 scenes, got {len(scenarios)}")
    DRAFT.write_text(json.dumps({"version":1,"scenarios":scenarios},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    with REVIEW.open("w",encoding="utf-8-sig",newline="") as handle:
        fieldnames=["id","level","ko","de","en","field_notes","상태","jin_memo"]
        writer=csv.DictWriter(handle,fieldnames=fieldnames)
        writer.writeheader()
        for s in scenarios:
            writer.writerow({
               "id":s["id"],"level":s["level"].upper(),
               "ko":s["title"]["ko"],"de":s["title"]["de"],"en":s["title"]["en"],
               "field_notes":"rights: original; KO checkpoint + EN/DE direct-from-KO corpus QA; no human-native QA claim; review full live Scenario adapter before release",
               "상태":"approved",
               "jin_memo":"User explicitly authorized Living Korea EN/DE localization, native QA and live-promotion work in chat on 2026-10-06. TTS remains excluded.",
            })
    manifest={
      "version":1,"batch":"39","status":"approved",
      "localizationContract":"tools/content_factory/canonical_scenarios/dialogue_localization_contract_20261006.json",
      "nativeUsageTopicIds":sorted(topics),
      "provenance":{
        "date":"2026-10-06","rights":"original",
        "scope":"Living Korea 23 user-reviewed Korean scenes promoted through the canonical Scenario runtime after EN/DE direct-from-KO localization and corpus/native-usage QA.",
        "approval":{"authority":"jin","approvedAt":"2026-10-06","method":"explicit_user_approval_in_chat","scope":"Living Korea 23 localization, native QA and live promotion"},
        "modelLanguageQa":"CORPUS_QA_PASS","humanLanguageQaClaim":False,
        "ttsGenerated":False,
      },
      "artifacts":[{"kind":"scenario","draft":DRAFT.relative_to(ROOT).as_posix(),"review":REVIEW.relative_to(ROOT).as_posix(),"count":23,"levels":dict(sorted(levels.items()))}],
      "recordCount":23,"questCount":69,
      "contentLinks":content_links,
      "backdrops":{s["id"]:s["backdrop"] for s in scenarios},
      "mergeOrder":["scenario + curriculum contentLinks + audit via integrate_scenario_batch.py","TTS only after Jin-owned spoken-surface review"],
      "nonMergeGuards":["Do not synthesize or overwrite TTS audio.","Do not claim human-native sign-off from corpus/model QA.","Preserve Korean checkpoint copy and persona relationship canon."],
    }
    MANIFEST.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"scenarioCount":len(scenarios),"questCount":69,"levels":levels,"nativeUsageTopicIds":sorted(topics)},ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
