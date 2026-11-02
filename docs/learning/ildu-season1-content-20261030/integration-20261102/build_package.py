"""Build portable authoring packets and source-resolved integration references.

This tool never edits runtime assets. Run from any directory inside the checkout.
"""
from pathlib import Path
from collections import Counter, defaultdict
import csv
import hashlib
import io
import json
import subprocess
import sys

OUT = Path(__file__).resolve().parent
REPO = Path(subprocess.check_output(['git','-C',str(OUT),'rev-parse','--show-toplevel'],text=True).strip())
PACKAGE = OUT.parent
PREFIX = PACKAGE.relative_to(REPO).as_posix()
BASE = '646c4658e70f594ab234a172679e29122d0f0e66'
SNAPSHOTS = {}

def digest(data):
    return hashlib.sha256(data).hexdigest()

def source(path):
    data = subprocess.check_output(['git','-C',str(REPO),'show',BASE+':'+path])
    SNAPSHOTS[path] = {'path':path,'sha256':digest(data),'bytes':len(data),'git_revision':BASE}
    return data

def data(path):
    return json.loads(source(path))

def table(name, delimiter='|'):
    return list(csv.DictReader(io.StringIO(source(PREFIX+'/reference/curriculum/'+name).decode('utf-8-sig')),delimiter=delimiter))

def dump(path, obj):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def tri(ko,en,de):
    return {'ko':ko,'en':en,'de':de}

GOALS = [
('Understand the roles of initial ㅇ and the vowel, and distinguish 아 from 어.','Verstehe die Funktion von ㅇ am Silbenanfang und die des Vokals und unterscheide 아 von 어.'),
('Build syllables with a horizontal vowel below the initial.','Bilde Silben, bei denen der waagerechte Vokal unter dem Anfangszeichen steht.'),
('Distinguish ㅡ and ㅣ and rebuild the six vowels you have learned.','Unterscheide ㅡ und ㅣ und setze die sechs gelernten Vokale erneut zusammen.'),
('Combine ㄴ and ㅁ with the vowels you know.','Verbinde ㄴ und ㅁ mit den Vokalen, die du kennst.'),
('Combine ㄱ and ㄷ with familiar vowels.','Verbinde ㄱ und ㄷ mit vertrauten Vokalen.'),
('Combine ㄹ and ㅂ with familiar vowels.','Verbinde ㄹ und ㅂ mit vertrauten Vokalen.'),
('Build syllables with ㅅ and ㅈ.','Bilde Silben mit ㅅ und ㅈ.'),
('Read syllables with ㅎ and reuse familiar consonant combinations.','Lies Silben mit ㅎ und verwende vertraute Konsonantenverbindungen erneut.'),
('Read 나무 and 모자 and connect their forms, sounds and meanings.','Lies 나무 und 모자 und verbinde Schriftbild, Laut und Bedeutung.'),
('Connect the sounds and spellings of 바다 and 다리 with their meanings.','Verbinde die Laute und Schreibweisen von 바다 und 다리 mit ihren Bedeutungen.'),
('Listen to ㅑ and ㅕ and distinguish their strokes within a block.','Hör dir ㅑ und ㅕ an und unterscheide ihre Striche im Silbenblock.'),
('Distinguish ㅛ and ㅠ in sound and horizontal layout.','Unterscheide ㅛ und ㅠ nach Laut und waagerechter Anordnung.'),
('Compare ㅋ with ㄱ, then ㅌ with ㄷ.','Vergleiche zuerst ㅋ mit ㄱ, dann ㅌ mit ㄷ.'),
('Compare ㅍ with ㅂ, then ㅊ with ㅈ.','Vergleiche zuerst ㅍ mit ㅂ, dann ㅊ mit ㅈ.'),
('Compare ㄲ and ㄸ with their familiar counterparts.','Vergleiche ㄲ und ㄸ mit den entsprechenden vertrauten Konsonanten.'),
('Learn ㅃ, ㅆ and ㅉ separately and compare their sounds.','Lerne ㅃ, ㅆ und ㅉ einzeln kennen und vergleiche ihre Laute.'),
('Distinguish the spellings ㅐ and ㅔ in familiar words.','Unterscheide die Schreibweisen ㅐ und ㅔ in vertrauten Wörtern.'),
('Understand how ㅘ and ㅝ fit into syllable blocks.','Verstehe, wie ㅘ und ㅝ in den Silbenblock passen.'),
('Learn the spellings ㅟ and ㅚ and listen to their sounds.','Lerne die Schreibweisen ㅟ und ㅚ kennen und höre ihre Laute.'),
('Place and read final ㅁ, ㄴ and ㄹ below the syllable.','Setze ㅁ, ㄴ und ㄹ unten als Endkonsonanten ein und lies die Silben.'),
('Distinguish the role of ㅇ at the start and end of a syllable.','Unterscheide die Funktion von ㅇ am Silbenanfang und am Silbenende.'),
('Explore closure in simple final consonants from the ㄱ, ㄷ and ㅂ groups.','Lerne den Verschluss bei einfachen Endkonsonanten aus der ㄱ-, ㄷ- und ㅂ-Gruppe kennen.'),
('Learn the spellings ㅙ and ㅞ and listen to their sounds.','Lerne die Schreibweisen ㅙ und ㅞ kennen und höre ihre Laute.'),
('Compare ㅒ and ㅖ with familiar vowels.','Vergleiche ㅒ und ㅖ mit vertrauten Vokalen.'),
('Explore ㅢ and the pronunciation of 의 in context.','Lerne ㅢ und die Aussprache von 의 im jeweiligen Zusammenhang kennen.'),
('Explore how a familiar final consonant links to a vowel-initial syllable.','Erkunde, wie ein vertrauter Endkonsonant mit einer vokalisch beginnenden Silbe verbunden wird.'),
('Type familiar syllables and words and correct a typo.','Tippe vertraute Silben und Wörter und verbessere einen Tippfehler.'),
('Notice word boundaries in familiar short phrases and respond.','Erkenne Wortgrenzen in vertrauten kurzen Wendungen und reagiere darauf.'),
('Greet someone, give a name, and ask someone to repeat what you did not hear.','Begrüße jemanden, nenne einen Namen und bitte um Wiederholung, wenn du etwas nicht gehört hast.'),
('Choose which details about your name, origin and languages to share, and ask others about theirs.','Entscheide, was du über deinen Namen, deine Herkunft und deine Sprachen mitteilen möchtest, und frage andere danach.'),
('Ask whether familiar objects are present and check their location.','Frage nach vertrauten Gegenständen und kläre, wo sie sind.'),
('Ask for an object you need and say thank you.','Bitte um einen Gegenstand, den du brauchst, und bedanke dich.'),
('Check who owns an object and say who is with you.','Kläre, wem ein Gegenstand gehört, und sage, wer bei dir ist.'),
('Correct a mix-up over a name or object, and ask for only what you need.','Korrigiere falsche Angaben zu Namen oder Gegenständen und grenze ein, was du brauchst.'),
]

COMMON = {
 'assisted':tri('도움을 받아 이 활동을 함께 마쳤어요. 다른 예는 준비되면 해 봐요.','You completed this activity with support. Try another example when you are ready.','Du hast diese Aufgabe mit Hilfe abgeschlossen. Probiere ein weiteres Beispiel, wenn du bereit bist.'),
 'independent':tri('이 예는 시범 없이 확인했어요. 다른 날 새로운 상황에서도 다시 해 봐요.','You checked this example without a model. Try it in a new setting another day.','Du hast dieses Beispiel ohne Vorlage bearbeitet. Probiere es an einem anderen Tag in einer neuen Situation.'),
 'audio_unavailable':tri('지금은 소리를 재생할 수 없어요. 글과 그림으로 계속하거나 나중에 다시 들어요.','Audio is unavailable right now. Continue with text and pictures, or listen later.','Der Ton ist gerade nicht verfügbar. Mach mit Text und Bildern weiter oder höre später noch einmal zu.'),
 'pause':tri('여기서 잠시 쉬어도 괜찮아요. 돌아오면 같은 차례에서 이어가요.','You can take a break here. When you return, continue from the same turn.','Du kannst hier eine Pause machen. Wenn du zurückkommst, geht es an derselben Stelle weiter.'),
 'resume':tri('돌아왔네요. 놓아 둔 답과 도움 상태를 확인하고 이어가요.','Welcome back. Check your previous response and any help you used, then continue.','Willkommen zurück. Sieh dir deine bisherige Antwort und die verwendete Hilfe an und mach dann weiter.'),
 'save_failed':tri('아직 저장을 확인하지 못했어요. 지금 답은 유지한 채 다시 시도해요.','Saving has not been confirmed yet. Keep your response and try again.','Das Speichern ist noch nicht bestätigt. Deine Antwort bleibt stehen; versuche es erneut.'),
 'revisit':tri('이미 본 장면이에요. 다시 보아도 보상이나 공정이 중복 생성되지 않아요.','You have seen this scene before. Replaying it does not grant another reward or construction step.','Du kennst diese Szene bereits. Beim erneuten Ansehen erhältst du keine weitere Belohnung und keinen zusätzlichen Bauabschnitt.'),
}

# Read original dialogues, not only course labels. These are partial-skill
# modern reprises; the authored unit still owns its full functional teaching.
SCENE_SELECTION = {
 'A1.1-01':['introduce_yourself','clarify_repeat'],
 'A1.1-02':['introduce_yourself','first_class_meeting'],
 'A1.1-03':['home_morning_routine'],
 'A1.1-04':['bakery_payment_bag'],
 'A1.1-05':['umbrella_weather'],
 'A1.1-06':[],
 'A1.2-01':['meeting_time'],
 'A1.2-02':['a1_w10_wayfinding'],
 'A1.2-03':[],
 'A1.2-04':['bunshik_tteokbokki'],
 'A1.2-05':['a1_theme_park_date_choices'],
 'A1.2-06':['meeting_time'],
 'A2.1-01':['a2_w10_booking'],
 'A2.1-02':['clothing_refund_size'],
 'A2.1-03':['jeju_bus_missed'],
 'A2.1-04':['group_chat_photo_permission'],
 'A2.1-05':[],
 'A2.1-06':['a2_w10_partner'],
 'A2.2-01':['favorite_drama_chat'],
 'A2.2-02':[],
 'A2.2-03':['friend_cancelled_plan'],
 'A2.2-04':['friend_cancelled_plan','a2_message_change_of_plan_2026'],
 'A2.2-05':['package_wrong_door'],
 'A2.2-06':['package_wrong_door','train_seat_swap'],
}

SENSE_EXCLUSIONS = {
 ('A1.2-04','vocab_a1_0628'):'개=dog/Hund is not the item counter 개.',
 ('A1.2-04','vocab_a1_0680'):'병=illness/Krankheit is not bottle/counter 병.',
}
TRANSLATION_PATCHES = [
 {'id':'integration-vocab-a1-0759-sense','source_path':'assets/data/korean_vocab.csv','content_id':'vocab_a1_0759','field':'german','source_value':'nicht Student/in sein','proposed_value':'nicht … sein (bei Nomen)','reason_ko':'아니다의 일반 명사 부정을 학생이 아님으로 좁힌 번역을 보완한다. 런타임 CSV는 수정하지 않는다.','status':'proposed_authoring_override_not_runtime'},
 {'id':'integration-vocab-a2-0264-sense','source_path':'assets/data/korean_vocab.csv','content_id':'vocab_a2_0264','field':'german','source_value':'hängen (dauern)','proposed_value':'hängen (hier: angebracht sein)','reason_ko':'이번 걸리다는 걸려 있는 상태이다. 시간을 뜻하는 dauern을 같은 뜻의 괄호로 제시하지 않는다. 런타임 CSV는 수정하지 않는다.','status':'proposed_authoring_override_not_runtime'},
]

def prepare():
    foundation=table('FOUNDATION.psv')
    conversation=[r for r in table('UNITS.psv') if r['id'].startswith(('A1.1-','A1.2-','A2.1-','A2.2-'))]
    intro=data(PREFIX+'/final/sources/season1-rpg-image-production-20261031/INTRO_UNITS.json')
    a11=data(PREFIX+'/manuscripts/a1-1-v35/AUTHORING_ITEMS.json')
    story=data(PREFIX+'/manuscripts/season1-rpg-v35/LEVEL_STORY_100.json')
    story_by={r['unit_id']:r for r in story['units']}
    intro_by={r['id']:r for r in intro}
    frozen_rows=foundation+[r for r in conversation if r['id'].startswith('A1.1-')]
    assert len(frozen_rows)==len(GOALS)==34
    for index,row in enumerate(frozen_rows):
        uid=row['id']; band=uid[:4]; anchor=story_by[uid]['story_anchor']
        if uid.startswith('F0.'):
            original=intro_by[uid]
            path=PREFIX+'/manuscripts/'+Path(original['source']).parent.name+'/'+Path(original['source']).name
            # Windows paths are normalized separately on non-Windows hosts too.
            path=PREFIX+'/manuscripts/'+'/'.join(original['source'].replace('\\','/').split('/')[-2:])
            inherited=original['pattern_links']
            title={'ko':row['goal'],**original['title']}
        else:
            path=PREFIX+'/manuscripts/a1-1-v35/'+uid[-2:]+'_'+uid+'.md'
            inherited={'items':[x for x in a11 if x['unit_id']==uid]}
            title=tri(row['title'],['Meeting someone and asking again','Introducing yourself','Finding familiar objects','Asking for what you need','Whose is it?','Correcting a misunderstanding'][int(uid[-2:])-1],['Begrüßen und nachfragen','Sich vorstellen','Vertraute Gegenstände finden','Um etwas bitten','Wem gehört das?','Ein Missverständnis klären'][int(uid[-2:])-1])
        src=source(path)
        goal=tri(row.get('goal',row.get('can_do')),GOALS[index][0],GOALS[index][1])
        packet={'schemaVersion':1,'status':'authored_candidate_not_runtime','record_type':'inherited_detailed_with_integration_overlay','unit_id':uid,'band':band,'title':title,'goal':goal,
          'prerequisites':row.get('prerequisites','').split(',') if row.get('prerequisites') else [],
          'base_manuscript':{'path':path,'sha256':digest(src),'inheritance':'full dialogue, teaching, P/I/R items, answer criteria, help and feedback retained verbatim; overlay is additive'},
          'source_contract':row,'inherited_content':inherited,'responses':COMMON,'response_conditions':{'assisted':'only after supported task is resolved','independent':'only if the eligible item met its criteria without model/hint; not all modalities','resume':'only after original state is actually restored','revisit':'existing reward owner remains authoritative'},
          'story':{'lq_id':anchor['lq_id'],'anchor':anchor['anchor'],'spoiler_guard':'Use only revealed facts. First book has no completed Sarangchae; first 집 remains practice draft until original readiness is confirmed.'},
          'review':{'delay':'next_day','no_story_lock':True,'original_review_scope':'existing manuscript reviews and same-byte source; not human/native/device approval'}}
        dump(OUT/'units'/f'{uid}.json',packet)
    dump(OUT/'COMMON_COPY.json',{'status':'authoring_copy_not_runtime','copy':COMMON})
    return foundation+conversation,story_by

def build():
    rows,story_by=prepare()
    manifest=data('assets/data/curriculum_manifest.json')
    bindings=table('COURSE_BINDINGS.psv')
    alloc=table('GRAMMAR_ALLOCATION.csv',',')
    phase=data('assets/data/phase_tasks.json')['tasks']; task_by={x['id']:x for x in phase}
    vocab=list(csv.DictReader(io.StringIO(source('assets/data/korean_vocab.csv').decode('utf-8-sig'))))
    grammar=list(csv.DictReader(io.StringIO(source('assets/data/grammar.csv').decode('utf-8-sig'))))
    scenarios=[x for level in ['a1','a2','b1','b2','c1','c2'] for x in data(f'assets/data/scenarios_{level}.json')['scenarios']]
    listening=data('assets/data/listening_lessons.json')['lessons']
    smalltalk=data('assets/data/smalltalk.json')['phrases']
    cloze=data('assets/data/cloze.json'); cloze=cloze.get('items',cloze.get('sentences',[])) if isinstance(cloze,dict) else cloze
    satz=data('assets/data/satz_sentences.json'); satz=satz.get('sentences',satz.get('items',[])) if isinstance(satz,dict) else satz
    r16=data('assets/data/ildu_r16_art_v1.json')
    stage_story=data(PREFIX+'/manuscripts/season1-rpg-v35/STAGE_STORY_128.json')
    course_by={r['id']:r for r in manifest['courseUnits']}
    small_by={r['id']:r for r in smalltalk}
    links=[]; missing=[]; audit=[]
    for row in rows:
        uid=row['id']; file=OUT/'units'/f'{uid}.json'
        if not file.exists(): missing.append(uid); continue
        packet=json.loads(file.read_text(encoding='utf-8'))
        courses=[r['course_id'] for r in bindings if uid in r['unit_ids'].split(',')]
        allocation=[r for r in alloc if r['design_unit_id']==uid]
        pids=list(dict.fromkeys(x for r in allocation for x in r['legacy_task_ids'].split('|') if x in task_by))
        target_lexis=[s.strip() for s in row.get('lexis','').split(',') if s.strip()]
        target_level='a1' if uid.startswith(('F0.','A1.')) else 'a2'
        # Exact surface matches only. Do not lemmatize inflected forms or confuse
        # sound signs with lexical meanings; F0 practice remains in its packet.
        surface=[] if uid.startswith('F0.') else [v for v in vocab if v['korean'] in target_lexis and v['level'].lower() in ({'a1'} if target_level=='a1' else {'a1','a2'})]
        vs=[v for v in surface if (uid,v['id']) not in SENSE_EXCLUSIONS]
        vocab_ids={v['id'] for v in vs}
        broad_scenes=[s for s in scenarios if s.get('courseUnitId') in courses]
        selected=SCENE_SELECTION.get(uid,[])
        ss=[s for s in scenarios if s['id'] in selected]
        ls=[l for l in listening if any(c in {s['id'] for s in ss} for c in l.get('contentIds',[]))]
        sts=[small_by[x['contentId']] for x in manifest['contentLinks'] if x.get('contentKind')=='smalltalk' and x.get('courseUnitId') in courses and x['contentId'] in small_by and any(len(w)>=2 and w in small_by[x['contentId']]['ko'] for w in target_lexis)]
        gs=[('cloze',g) for g in cloze if g.get('sourceVocabId') in vocab_ids]+[('satz',g) for g in satz if g.get('sourceVocabId') in vocab_ids]
        aid=story_by[uid]['story_anchor']['lq_id']; bmap={'LQ-01':'sarangchae','LQ-02':'changgo','LQ-03':'jungmunganchae','LQ-04':'sarangchae','LQ-05':'jungmunganchae','LQ-06':'araechae','LQ-07':'toilet-south','LQ-08':'anchae'}
        def ref(kind,item,path,scope): return {'kind':kind,'id':item['id'],'source_path':path,'source_sha256':SNAPSHOTS[path]['sha256'],'reuse_scope':scope,'runtime_content_unchanged':True}
        refs=[]
        refs += [ref('course_unit',course_by[c],'assets/data/curriculum_manifest.json','candidate course correspondence; check exact sub-goal and prerequisites, not one-to-one equivalence') for c in courses]
        refs += [ref('phase_task',task_by[t],'assets/data/phase_tasks.json','allocated grammar form reference; original task material may require more vocabulary; not an automatic assess gate') for t in pids]
        refs += [ref('vocab',v,'assets/data/korean_vocab.csv','exact lexical form; compare the supplied English/German sense before launch') for v in vs]
        for s in ss: refs.append(ref('scenario',s,f'assets/data/scenarios_{s["level"]}.json','optional modern transfer; keep original cast/place/text and separate story return'))
        refs += [ref('listening_lesson',l,'assets/data/listening_lessons.json','same scenario source as above; a listening activity, not a second dialogue corpus') for l in ls]
        refs += [ref('smalltalk',s,'assets/data/smalltalk.json','optional modern practice from existing explicit course link; source relationship preserved') for s in sts]
        refs += [ref(k,g,'assets/data/cloze.json' if k=='cloze' else 'assets/data/satz_sentences.json','optional vocabulary reprise after full sentence prerequisites; never independent mastery inferred from completion') for k,g in gs]
        modules={kind:{'state':'references_present' if any(x['kind'] in kinds for x in refs) else 'authored_packet_or_not_applicable','reason':reason} for kind,kinds,reason in [
          ('vocabulary',['vocab'],'Sound-sign work is not dictionary word knowledge; missing forms/senses stay explicitly in the authored packet.'),
          ('grammar',['phase_task'],'Use allocated forms as reference; new functional teaching stays in this packet, without legacy gate inheritance.'),
          ('listening_scenario',['scenario','listening_lesson'],'No matching existing scene is silently renamed; authored dialogue/audio script is a new candidate, not an existing playable clip.'),
          ('smalltalk',['smalltalk'],'Use only a matching relationship/function. No mandatory smalltalk quota.'),
          ('games',['cloze','satz'],'No game forced into a unit. F0 uses the manuscript assembly/recognition tasks; six-level pools are not automatically beginner-safe.') ]}
        record={'unit_id':uid,'band':packet['band'],'goal':packet['goal'],'packet':file.relative_to(OUT).as_posix(),'packet_sha256':digest(file.read_bytes()),'story_anchor':story_by[uid]['story_anchor'],
          'reference_status':'authoring_connections_not_runtime_registration','module_decisions':modules,'references':refs,
          'narrative_bridge':{k:story_by[uid][k] for k in ['scene_title','micro_conflict','npc','player_action','visible_narrative_consequence','next_hook','spoiler_gate','recall_seed']},
          'narrative_bridge_status':'verbatim existing story manuscript; original translation QA status retained; use its spoiler gate before display',
          'excluded_lexical_matches':[{'id':v['id'],'form':v['korean'],'reason':SENSE_EXCLUSIONS[(uid,v['id'])]} for v in surface if (uid,v['id']) in SENSE_EXCLUSIONS],
          'copy_overrides_required':[x for x in TRANSLATION_PATCHES if x['content_id'] in vocab_ids],
          'construction':{'building_id':bmap[aid],'process_id':None,'relation':'context_only','reason':'Narrative start/middle/end is not a confirmed numeric process trigger; no one-unit/one-process mapping.','owned_stage':None,'price':None,'grants_currency':False},
          'existing_course_mapping_notes':[r['review_focus'] for r in bindings if r['course_id'] in courses],
          'scenario_selection':{'selected_ids':selected,'excluded_broad_course_ids':[s['id'] for s in broad_scenes if s['id'] not in selected],'reason':'Course association alone is insufficient. Selected scenes reuse a functional subset with original modern cast and text; the full unit remains in the authored packet.'},
          'evidence_policy':'Read practice/help, independent assessment, next-day review, story facts, ownership and currency from their distinct original owners; no promotion from lessonDone.'}
        links.append(record)
        audit += [{'unit_id':uid,'vocab_id':v['id'],'form':v['korean'],'en':v['english'],'de':v['german']} for v in vs]
    dump(OUT/'UNIT_CONTENT_LINKS.json',{'base_sha':BASE,'status':'authoring_connections_not_runtime','units':links,'missing_packets':missing})
    dump(OUT/'LEXICAL_SENSE_REVIEW.json',{'scope':'exact lexical matches for human/model semantic comparison, not automatic homograph approval','rows':audit})
    dump(OUT/'TRANSLATION_PATCHES.json',{'base_sha':BASE,'runtime_modified':False,'patches':TRANSLATION_PATCHES,'new_and_inherited_copy_review':'reviews/ROOT_COPY_REVIEW.md; peer-review files and corrections apply to authoring packets only'})
    by_proc={s['processId']:s for s in stage_story['stages']}
    contexts=[]
    for b in r16['buildings']:
        for stage in b['stages']:
            authored=by_proc[stage['processId']]
            contexts.append({'building_id':b['id'],'process_id':stage['processId'],'sequence':stage['sequence'],'label_ko':stage['labelKo'],'art_asset':stage['asset'],'art_sha256':stage['sha256'],
             'story_anchor':authored['study']['questAnchorId'],'suggested_band':authored['study']['suggestedStudyBand'],'relation':'context_only_not_ownership_or_eligibility','legacy_requirements_status':authored['requiredCourseUnitIdsStatus'],
             'in_this_delivery':authored['study']['suggestedStudyBand'] in {r['band'] for r in links},'price':None,'owned':None,'grants_currency':False})
    dump(OUT/'HANOK_CONTEXT_LINKS.json',{'base_sha':BASE,'presentationOnly':True,'processPolicyIncluded':False,'progressOrOwnershipMigrationIncluded':False,'contexts':contexts})
    dump(OUT/'SOURCE_MANIFEST.json',{'base_sha':BASE,'sources':list(SNAPSHOTS.values())})
    render(links)
    print(json.dumps({'packets':len(links),'missing':missing,'references':sum(len(r['references']) for r in links),'hanok_contexts':len(contexts),'lexical_matches':len(audit)},ensure_ascii=False))

def render(links):
    index=['# 입문~A2.2 · 52단원 통합 검토본','','상세 원문은 보존하고, 다음 링크에서 구간별 원고·추가 집필·실제 참조를 함께 읽는다. 앱 실행/평가/소유권 변경이 아니다.','','| 구간 | 단원 | 목표 |','|---|---|---|']
    for link in links:
        uid=link['unit_id']; packet=json.loads((OUT/link['packet']).read_text(encoding='utf-8'))
        index.append(f'| {link["band"]} | [{uid}](review/{uid}.md) | {packet["goal"]["ko"]} |')
        lines=[f'# {uid} · {packet["title"]["ko"]}','','지위: 집필 후보·연결자료, 런타임 등록/사람 원어민 승인/음성/기기 검증 아님.','','## 목표',f'- KO: {packet["goal"]["ko"]}',f'- EN: {packet["goal"]["en"]}',f'- DE: {packet["goal"]["de"]}','','## 이야기·건축 접점',f'- 앵커: {link["story_anchor"]["lq_id"]} / {link["construction"]["building_id"]}. 공정 번호·소유·가격은 부여하지 않는다.','- 기존 콘텐츠의 현대 인물·관계·장소는 유지하고 활동 뒤 기억 고택의 장면으로 돌아온다.','']
        bridge=link['narrative_bridge']
        lines += ['### 보존한 본편 사건과 복귀','기존 LEVEL_STORY_100 원고의 같은 단원 연결이다. 아래 서사 문구의 기존 번역 QA 상태는 승격하지 않는다. 공개 조건이 충족되지 않으면 고택 사건·이름·소품을 표시하지 않고 현대 역할 카드만 사용한다.','',f'사건: {bridge["micro_conflict"]}',f'행동: {bridge["player_action"]}',f'보이는 결과: {bridge["visible_narrative_consequence"]}',f'다음 사건: {bridge["next_hook"]}',f'공개 조건: {json.dumps(bridge["spoiler_gate"],ensure_ascii=False)}',f'기존 NPC 대사: {json.dumps(bridge["npc"],ensure_ascii=False)}','']
        if link['excluded_lexical_matches'] or link['copy_overrides_required']:
            lines += ['### 단어 뜻·번역 검수',f'제외한 동형어: {json.dumps(link["excluded_lexical_matches"],ensure_ascii=False)}',f'실행 전 별도 적용이 필요한 번역 제안: {json.dumps(link["copy_overrides_required"],ensure_ascii=False)}','']
        if 'base_manuscript' in packet:
            base=packet['base_manuscript']; rel=Path(base['path']).relative_to(PACKAGE.relative_to(REPO)).as_posix()
            lines += ['## 상속한 상세 원고',f'[동일 바이트 원문](../../{rel}) · SHA-256 `{base["sha256"]}`','','아래 원문은 대사·시범·문항·도움·오답·복습 전문이다. 이 검토본 뒤의 연결 표는 추가 자료이며 원래 평가 조건을 바꾸지 않는다.','',source(base['path']).decode('utf-8'),'']
        else:
            lines += ['## 목표 어휘·형태',json.dumps(packet['teach_targets'],ensure_ascii=False),'','## 이어지는 대화','| 차례 | 화자 | KO | EN | DE |','|---|---|---|---|---|']
            for t in packet['dialogue']: lines.append('| '+ ' | '.join(str(t[k]).replace('|','／').replace('\n','<br>') for k in ['phase','speaker','ko','en','de'])+' |')
            lines += ['','## 문항·도움·오답·회상']
            for item in packet['items']:
                lines += ['',f'### {item["id"]} · {item["mode"]} / {item["scoring"]}',f'목표: {item["objective"]}','',f'자료: {json.dumps(item["material"],ensure_ascii=False)}','',f'KO: {item["prompt"]["ko"]}',f'EN: {item["prompt"]["en"]}',f'DE: {item["prompt"]["de"]}','',f'보기: {json.dumps(item["options"],ensure_ascii=False)}',f'허용 답: {json.dumps(item["accepted_answers"],ensure_ascii=False)}',f'정답 반응: {json.dumps(item["feedback_correct"],ensure_ascii=False)}',f'오답 반응: {json.dumps(item["feedback_wrong"],ensure_ascii=False)}',f'도움: {json.dumps(item["help"],ensure_ascii=False)}',f'증거 한계: {item["evidence_limit"]}']
        lines += ['','## 보조 상태 카피','| 상태 | KO | EN | DE |','|---|---|---|---|']
        for state,text in packet['responses'].items(): lines.append('| '+state+' | '+' | '.join(text[k].replace('|','／') for k in ['ko','en','de'])+' |')
        lines += ['','## 기존 콘텐츠 연결','해당 자료는 명시된 재사용 범위로만 쓴다. 참고 자료 존재가 단원의 독립 수행 증거가 되는 것은 아니다.','','| 종류 | 실제 ID | 재사용 범위 |','|---|---|---|']
        for r in link['references']: lines.append(f'| {r["kind"]} | {r["id"]} | {r["reuse_scope"]} |')
        if not link['references']: lines.append('| 집필 원고 | 이 단원 원문의 문항 ID | 준비된 글자·목표의 활동. 맞지 않는 기존 풀은 강제 연결하지 않음 |')
        (OUT/'review').mkdir(exist_ok=True)
        (OUT/'review'/f'{uid}.md').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    (OUT/'INDEX.md').write_text('\n'.join(index)+'\n',encoding='utf-8',newline='\n')

if __name__=='__main__':
    if '--prepare' in sys.argv:
        rows,_=prepare(); print('Prepared 34 inherited packets; planned units:',len(rows))
    else:
        build()
