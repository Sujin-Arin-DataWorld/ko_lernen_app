"""Validate authoring completeness, exact references and frozen source bytes.

Does not evaluate learner performance or claim native/device verification.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
import re
import subprocess
import sys

OUT=Path(__file__).resolve().parent
REPO=Path(subprocess.check_output(['git','-C',str(OUT),'rev-parse','--show-toplevel'],text=True).strip())
BASE='646c4658e70f594ab234a172679e29122d0f0e66'
ERRORS=[]
WARNINGS=[]
CACHE={}
ID_CACHE={}

def raw(path):
    if path not in CACHE:
        CACHE[path]=subprocess.check_output(['git','-C',str(REPO),'show',BASE+':'+path])
    return CACHE[path]

def read(p): return json.loads(p.read_text(encoding='utf-8'))
def check(ok,message):
    if not ok: ERRORS.append(message)

def language(value,label):
    check(isinstance(value,dict),label+' must be a language object')
    if isinstance(value,dict):
        for k in ['ko','en','de']:
            check(isinstance(value.get(k),str) and bool(value[k].strip()),label+' missing '+k)

def ids(value):
    result=set()
    if isinstance(value,dict):
        if isinstance(value.get('id'),str): result.add(value['id'])
        for v in value.values(): result|=ids(v)
    if isinstance(value,list):
        for v in value: result|=ids(v)
    return result

def validate():
    import csv,io
    links=read(OUT/'UNIT_CONTENT_LINKS.json')
    units=links['units']
    curriculum=[]
    for name in ['FOUNDATION.psv','UNITS.psv']:
        path='docs/learning/ildu-season1-content-20261030/reference/curriculum/'+name
        curriculum.extend(csv.DictReader(io.StringIO(raw(path).decode('utf-8-sig')),delimiter='|'))
    curriculum_by={r['id']:r for r in curriculum}
    story_path='docs/learning/ildu-season1-content-20261030/manuscripts/season1-rpg-v35/LEVEL_STORY_100.json'
    story_by={r['unit_id']:r for r in json.loads(raw(story_path))['units']}
    peer_reviewed=0
    expected={'F0.1':3,'F0.2':7,'F0.3':11,'F0.4':7,'A1.1':6,'A1.2':6,'A2.1':6,'A2.2':6}
    check(len(units)==52,'Expected 52 connected unit packets')
    check(Counter(x['band'] for x in units)==Counter(expected),'Band distribution mismatch')
    check(len({x['unit_id'] for x in units})==len(units),'Duplicate unit id')
    check(not links['missing_packets'],'Missing packets: '+str(links['missing_packets']))
    inherited=0;new=0;items=0;dialogue=0;refs=0;item_ids=set()
    for link in units:
        uid=link['unit_id'];p=OUT/link['packet'];packet=read(p)
        check(hashlib.sha256(p.read_bytes()).hexdigest()==link['packet_sha256'],uid+' packet changed after linking')
        check(packet['status']=='authored_candidate_not_runtime',uid+' missing candidate boundary')
        check(packet['prerequisites']==[x for x in curriculum_by[uid].get('prerequisites','').split(',') if x],uid+' prerequisite mismatch')
        check(link['narrative_bridge']=={k:story_by[uid][k] for k in ['scene_title','micro_conflict','npc','player_action','visible_narrative_consequence','next_hook','spoiler_gate','recall_seed']},uid+' narrative bridge differs from frozen story')
        language(packet['title'],uid+' title');language(packet['goal'],uid+' goal')
        for state in ['assisted','independent','audio_unavailable','pause','resume','save_failed','revisit']:
            language(packet['responses'].get(state),uid+' '+state)
        check(packet['review']['no_story_lock'] is True,uid+' review must not lock story')
        check(link['construction']['process_id'] is None,uid+' must not infer numeric process trigger')
        check(link['construction']['owned_stage'] is None and link['construction']['price'] is None,uid+' must not invent ownership/price')
        if 'base_manuscript' in packet:
            inherited+=1; r=packet['base_manuscript']; expected_sha=hashlib.sha256(raw(r['path'])).hexdigest()
            check(expected_sha==r['sha256'],uid+' frozen manuscript hash mismatch')
            source_path=REPO/r['path']
            check(source_path.exists() and hashlib.sha256(source_path.read_bytes()).hexdigest()==expected_sha,uid+' local source changed')
            check(bool(packet['inherited_content']),uid+' missing inherited question bindings')
        else:
            new+=1
            peer=OUT/'reviews'/f'{packet["band"]}_PEER_REVIEW.md'
            check(peer.exists(),uid+' missing independent review')
            if peer.exists():
                peer_text=peer.read_text(encoding='utf-8')
                reviewed=hashlib.sha256(p.read_bytes()).hexdigest() in peer_text
                check(reviewed,uid+' current bytes not recorded in independent review')
                peer_reviewed+=int(reviewed)
            for pathkey,hashkey in [('contract_path','contract_sha256'),('story_path','story_sha256')]:
                s=packet['source'];check(hashlib.sha256(raw(s[pathkey])).hexdigest()==s[hashkey],uid+' source hash '+pathkey)
            check(packet['source']['base_sha']==BASE,uid+' wrong source revision')
            check(len(packet['dialogue'])>=6,uid+' requires connected dialogue')
            dialogue+=len(packet['dialogue'])
            for turn in packet['dialogue']:
                language(turn,uid+' turn '+turn['id'])
                check(bool(turn['speaker']) and bool(turn['phase']),uid+' turn missing speaker/phase')
            modes=Counter(i['mode'] for i in packet['items'])
            for m,n in {'P':2,'I':2,'R':2,'T':1}.items():check(modes[m]>=n,uid+' missing '+m+' items')
            for item in packet['items']:
                label=uid+' '+item['id'];items+=1
                check(item['id'] not in item_ids,label+' duplicate item id');item_ids.add(item['id'])
                for k in ['prompt','feedback_correct','feedback_wrong','help']:language(item[k],label+' '+k)
                check(bool(item['objective']) and bool(item['material']) and bool(item['evidence_limit']),label+' missing stimulus/objective/evidence limit')
                check(item['scoring'] in ['structured','unscored'],label+' invalid scoring')
                check(item['mode'] in ['P','I','R','T'],label+' invalid mode')
                if item['kind']=='roleplay':check(item['scoring']=='unscored',label+' roleplay may not claim semantic scoring')
                if item['kind']=='roleplay':check(not item['accepted_answers'],label+' free roleplay must not have finite answer scoring')
                if packet['band']=='A1.2' and item['kind']=='short':language(item['material'].get('response_scope'),label+' bounded response scope')
                if item['kind']=='choice':
                    options=item['options']; option_ids=[x['id'] for x in options]
                    check(len(options)>=2 and len(set(option_ids))==len(option_ids),label+' invalid choices')
                    for option in options:language(option,label+' option '+option['id'])
                    check(bool(item['accepted_answers']) and set(item['accepted_answers'])<=set(option_ids),label+' answer not a choice ID')
                if item['mode']=='I' and isinstance(item['material'],dict):
                    check(not any(k in item['material'] for k in ['model','model_answer','answer']),label+' visible model in independent material')
            check(bool(packet['teach_targets']['vocab']) and bool(packet['teach_targets']['grammar']),uid+' target inventory empty')
            for v in packet['teach_targets']['vocab']:language(v,uid+' target vocabulary')
        for ref in link['references']:
            refs+=1;path=ref['source_path'];blob=raw(path)
            check(hashlib.sha256(blob).hexdigest()==ref['source_sha256'],uid+' ref source hash mismatch '+path)
            if path not in ID_CACHE:
                if path.endswith('.json'): ID_CACHE[path]=ids(json.loads(blob))
                else:
                    import csv,io
                    ID_CACHE[path]={r['id'] for r in csv.DictReader(io.StringIO(blob.decode('utf-8-sig')))}
            actual_ids=ID_CACHE[path]
            check(ref['id'] in actual_ids,uid+' missing actual ID '+ref['id'])
        for module in ['vocabulary','grammar','listening_scenario','smalltalk','games']:
            check(module in link['module_decisions'],uid+' missing module decision '+module)
        if uid=='A1.2-04':
            check(not ({'vocab_a1_0628','vocab_a1_0680'} & {r['id'] for r in link['references']}),'Counter task linked to dog/illness homograph')
        check((OUT/'review'/f'{uid}.md').is_file(),uid+' missing portable review manuscript')
    check(inherited==34 and new==18,'Expected 34 inherited + 18 newly detailed packets')
    cards=read(OUT/'GRAMMAR_CARD_LINKS.json')
    grammar_path='assets/data/grammar.csv'
    grammar_by={r['id']:r for r in csv.DictReader(io.StringIO(raw(grammar_path).decode('utf-8-sig')))}
    check(cards['base_sha']==BASE and cards['source_path']==grammar_path,'Grammar card source mismatch')
    check(cards['source_sha256']==hashlib.sha256(raw(grammar_path)).hexdigest(),'Grammar card source hash mismatch')
    check(len(cards['units'])==52 and {r['unit_id'] for r in cards['units']}=={r['unit_id'] for r in units},'Grammar card unit coverage mismatch')
    card_refs=0
    for row in cards['units']:
        if row['unit_id'].startswith('F0.'):
            check(not row['cards'],row['unit_id']+' foundation must not force grammar cards')
        for card in row['cards']:
            card_refs+=1
            check(card['id'] in grammar_by,row['unit_id']+' unknown grammar card '+card['id'])
            if card['id'] in grammar_by:check(card['pattern']==grammar_by[card['id']]['pattern'],row['unit_id']+' changed grammar card pattern')
            check(bool(card['reason_ko']) and bool(card['reuse_scope']),row['unit_id']+' missing grammar reuse scope')
    contexts=read(OUT/'HANOK_CONTEXT_LINKS.json')['contexts']
    check(len(contexts)==128 and len({x['process_id'] for x in contexts})==128,'Expected 128 unique R16 context refs')
    catalog=json.loads(raw('assets/data/ildu_r16_art_v1.json'))
    pairs={(b['id'],s['processId']) for b in catalog['buildings'] for s in b['stages']}
    art={(b['id'],s['processId']):(s['asset'],s['sha256']) for b in catalog['buildings'] for s in b['stages']}
    check(all((c['building_id'],c['process_id']) in pairs for c in contexts),'Unknown R16 context id')
    check(all(art[(c['building_id'],c['process_id'])]==(c['art_asset'],c['art_sha256']) for c in contexts),'R16 art reference differs from original catalog')
    check(all(c['owned'] is None and c['price'] is None and c['grants_currency'] is False for c in contexts),'R16 ownership/economy fabrication')
    # The original 119-file byte snapshot is unchanged.
    frozen=read(OUT.parent/'SNAPSHOT_MANIFEST.json')['files']
    for r in frozen:
        check(hashlib.sha256((REPO/r['repository_path']).read_bytes()).hexdigest()==r['copied_sha256'],'Original snapshot changed: '+r['repository_path'])
    for r in read(OUT/'SOURCE_MANIFEST.json')['sources']:
        check(hashlib.sha256(raw(r['path'])).hexdigest()==r['sha256'],'Source manifest mismatch '+r['path'])
    for name in ['README.md','EVIDENCE_AND_FLOW.md','REFERENCE_DECISIONS.md']:
        check((OUT/name).exists(),'Missing delivery contract '+name)
    changed=subprocess.check_output(['git','-C',str(REPO),'diff','--name-only',BASE],text=True).splitlines()
    check(all(x.startswith(OUT.relative_to(REPO).as_posix()+'/') for x in changed),'Tracked changes outside approved content directory')
    report={'status':'PASS' if not ERRORS else 'FAIL','base_sha':BASE,'scope':'authoring and source-reference checks, not learner/device/native approval',
      'units':len(units),'bands':dict(Counter(x['band'] for x in units)),'inherited_detailed':inherited,'newly_detailed':new,'new_items':items,'new_dialogue_turns':dialogue,'existing_source_references':refs,
      'grammar_card_references':card_refs,'hanok_contexts':len(contexts),'new_units_with_exact_hash_in_peer_review':peer_reviewed,'original_snapshot_files_unchanged':len(frozen),'errors':ERRORS,'warnings':WARNINGS}
    (OUT/'VALIDATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
    return 0 if not ERRORS else 1

if __name__=='__main__':raise SystemExit(validate())
