"""Build display bands and traceable links. Never modifies KP or mastery data.

Assignments are pedagogical proposals; runtime coverage remains partial until
teaching, transfer and human validation gates are satisfied.
"""
import argparse
import csv
import hashlib
import io
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs/learning/lernpfad-v2'
DATA = ROOT / 'assets/data'


def text(ko, en, de):
    return dict(ko=ko, en=en, de=de)


# Deliberate function-based groups. These are new display IDs, not replacements
# for the old A1.1..A1.4 etc. phase labels.
BANDS = [
    ('F0.1', [], text('소리와 첫 음절', 'Sounds and first syllables', 'Laute und erste Silben'), text('배운 소리와 글자를 연결하고 음절을 조립해요.', 'Connect the sounds and letters you have learned and build syllable blocks.', 'Verbinde gelernte Laute mit Zeichen und setze Silbenblöcke zusammen.')),
    ('F0.2', [], text('자음과 짧은 단어', 'Consonants and short words', 'Konsonanten und kurze Wörter'), text('받침 없는 짧은 단어를 읽고 뜻과 연결해요.', 'Read short words without final consonants and connect them to their meaning.', 'Lies kurze Wörter ohne Endkonsonanten und ordne ihre Bedeutung zu.')),
    ('F0.3', [], text('더 많은 소리와 첫 받침', 'More sounds and first final consonants', 'Weitere Laute und erste Endkonsonanten'), text('익힌 자모의 새 조합을 읽고 짧은 표지를 알아봐요.', 'Read new combinations of familiar letters and recognise short signs.', 'Lies neue Kombinationen bekannter Zeichen und erkenne kurze Schilder.')),
    ('F0.4', [], text('읽고 입력하고 응답하기', 'Read, type and respond', 'Lesen, tippen und antworten'), text('익힌 짧은 문구를 읽고 간단히 입력하고 응답해요.', 'Read familiar short phrases, type simple text and respond.', 'Lies vertraute kurze Ausdrücke, tippe einfachen Text und antworte.')),
    ('A1.1', [1], text('만나고 소개하고 부탁하기', 'Meet, introduce and ask', 'Begegnen, vorstellen und bitten'), text('나를 소개하고 원하는 것을 요청하며 다시 물어봐요.', 'Introduce yourself, ask for what you need and ask again when unclear.', 'Stelle dich vor, bitte um etwas und frage bei Unklarheiten nach.')),
    ('A1.2', [2, 3, 4], text('하루와 약속', 'Your day and plans', 'Dein Alltag und Verabredungen'), text('하루를 설명하고 시간·수량·위치·약속을 확인해요.', 'Describe your day and confirm times, quantities, locations and plans.', 'Beschreibe deinen Tag und kläre Zeiten, Mengen, Orte und Verabredungen.')),
    ('A2.1', [5], text('생활 속 문제 해결', 'Solve everyday problems', 'Alltagsprobleme lösen'), text('조건을 확인하고 대안을 선택하며 해결을 요청해요.', 'Check conditions, choose alternatives and ask for help with a problem.', 'Kläre Bedingungen, wähle Alternativen und bitte um eine Lösung.')),
    ('A2.2', [6, 7, 8], text('경험과 관계', 'Experiences and relationships', 'Erfahrungen und Beziehungen'), text('경험을 이어 말하고 공감·거절·사과·정정을 해요.', 'Connect experiences in a story, show empathy, decline, apologise and correct yourself.', 'Erzähle zusammenhängend von Erfahrungen, zeige Verständnis, lehne ab und entschuldige oder korrigiere dich.')),
    ('B1.1', [9, 10], text('사건의 흐름', 'How events unfolded', 'Wie Ereignisse zusammenhängen'), text('사건의 배경과 경위를 설명하고 질문에 답하며 해결책을 만들어요.', 'Explain the background and sequence of an event, answer questions and suggest solutions.', 'Erkläre Hintergrund und Ablauf eines Ereignisses, beantworte Fragen und schlage Lösungen vor.')),
    ('B1.2', [11, 12, 13], text('출처와 근거', 'Sources and reasons', 'Quellen und Begründungen'), text('사실·추측·출처를 구분하고 근거를 붙여 의견을 조정해요.', 'Separate facts, guesses and sources, and adjust an opinion using reasons.', 'Unterscheide Fakten, Vermutungen und Quellen und passe deine Meinung mit Begründungen an.')),
    ('B2.1', [14, 15], text('자료를 비교해 설명하기', 'Compare and explain information', 'Informationen vergleichen und erklären'), text('자료를 비교하고 사실과 해석을 구분해 설명해요.', 'Compare sources and explain the difference between facts and interpretations.', 'Vergleiche Materialien und erkläre den Unterschied zwischen Fakten und Deutungen.')),
    ('B2.2', [16, 17, 18], text('반론과 합의', 'Counterarguments and agreement', 'Gegenargumente und Einigung'), text('반론에 대응하고 오해를 풀며 합의안을 만들어요.', 'Respond to counterarguments, resolve misunderstandings and negotiate agreement.', 'Gehe auf Gegenargumente ein, kläre Missverständnisse und handle eine Einigung aus.')),
    ('C1.1', [19, 20], text('복잡한 정보를 쉽게', 'Make complex information clear', 'Komplexes verständlich machen'), text('여러 자료를 통합하고 전문 내용을 쉽게 설명해요.', 'Synthesize several sources and explain specialist information clearly.', 'Führe mehrere Quellen zusammen und erkläre Fachinhalte verständlich.')),
    ('C1.2', [21, 22, 23, 24], text('관점과 관계 중개', 'Mediate perspectives and relationships', 'Perspektiven und Beziehungen vermitteln'), text('상대와 목적에 맞춰 표현을 바꾸고 관점을 중개해요.', 'Adapt expression to the audience and purpose and mediate between viewpoints.', 'Passe deine Ausdrucksweise an Gegenüber und Zweck an und vermittle zwischen Sichtweisen.')),
    ('C2.1', [25, 26, 27, 28], text('의미와 해석의 차이', 'Subtle meanings and interpretations', 'Feine Bedeutungs- und Deutungsunterschiede'), text('여러 해석을 근거로 비교하고 불확실성을 정교하게 표현해요.', 'Compare plausible interpretations using evidence and express uncertainty precisely.', 'Vergleiche begründete Deutungen und drücke Unsicherheit differenziert aus.')),
    ('C2.2', [29, 30], text('종합하고 재구성하기', 'Synthesize and reshape', 'Zusammenführen und neu gestalten'), text('복합 자료로 정교하게 표현하고 다른 청자를 위해 재구성해요.', 'Create nuanced responses to complex material and reshape them for another audience.', 'Formuliere differenziert zu komplexem Material und gestalte es für andere Zielgruppen neu.')),
]


def foundation():
    # The first playable lesson intentionally makes only a narrow claim.
    # Larger F0 goals remain explicitly pending in the catalog and work queue.
    return {'schemaVersion': 1, 'lessons': [{
        'id': 'F0.1.sound-signs', 'bandId': 'F0.1', 'revision': 1,
        'introduced': ['ㅇ', 'ㅏ', 'ㅓ'], 'evidenceScope': 'taught_symbol_recognition',
        'title': text('소리표의 자리를 되찾기', 'Put the sound signs back', 'Die Lautschilder zurückbringen'),
        'story': text('일두고택 마당의 현대 학습용 소리표가 섞였어요. Joy와 함께 아와 어의 자리를 찾아주세요.', 'The modern practice signs in Ildu’s courtyard have been mixed up. Help Joy find the places for 아 and 어.', 'Die heutigen Übungsschilder im Hof von Ildu sind durcheinandergeraten. Hilf Joy, die Plätze für 아 und 어 zu finden.'),
        'teaching': [
            {'target': '아', 'parts': ['ㅇ', 'ㅏ'], 'explanation': text('ㅏ는 모음이에요. 음절 첫자리의 ㅇ은 소리가 없어요. ㅇ을 왼쪽에, ㅏ를 오른쪽에 놓으면 아가 돼요.', 'ㅏ is a vowel. At the start of a syllable, ㅇ is silent. Put ㅇ on the left and ㅏ on the right to make 아.', 'ㅏ ist ein Vokal. Am Silbenanfang ist ㅇ stumm. Mit ㅇ links und ㅏ rechts entsteht 아.')},
            {'target': '어', 'parts': ['ㅇ', 'ㅓ'], 'explanation': text('이번에는 ㅓ예요. 짧은 획이 왼쪽을 향해요. 첫자리 ㅇ과 합치면 어가 돼요. 소리를 듣고 아와 비교해 보세요.', 'Now try ㅓ. Its short stroke points left. Together with initial ㅇ it makes 어. Listen and compare it with 아.', 'Jetzt kommt ㅓ. Der kurze Strich zeigt nach links. Mit ㅇ am Anfang entsteht 어. Hör zu und vergleiche den Laut mit 아.')},
        ],
        'practice': [
            {'id': 'p-a', 'parts': ['ㅇ', 'ㅏ'], 'answer': '아', 'options': ['어', '아']},
            {'id': 'p-eo', 'parts': ['ㅇ', 'ㅓ'], 'answer': '어', 'options': ['아', '어']},
        ],
        'assessment': [
            {'id': 'a-eo', 'parts': ['ㅇ', 'ㅓ'], 'answer': '어', 'options': ['어', '아']},
            {'id': 'a-a', 'parts': ['ㅇ', 'ㅏ'], 'answer': '아', 'options': ['아', '어']},
        ],
        'followup': text('다른 날에도 두 소리표를 찾아보세요. 아직 새 단어를 읽을 수 있다는 뜻은 아니에요.', 'Try the two signs again another day. This does not yet confirm that you can read unfamiliar words.', 'Probiere die beiden Schilder an einem anderen Tag erneut. Damit ist noch nicht bestätigt, dass du unbekannte Wörter lesen kannst.'),
        'reviewStatus': 'authored_candidate_requires_learner_and_audio_review',
    }]}


def build():
    phases = json.loads((ROOT / 'tools/content_factory/cefr_matrix/phases.json').read_text(encoding='utf-8'))
    task_data = json.loads((DATA / 'phase_tasks.json').read_text(encoding='utf-8'))
    f0 = foundation()
    phase_band = {f'KP{n:02}': b for b, nums, _, _ in BANDS for n in nums}
    assert len(phase_band) == 30
    activities = []
    bands = []
    for band_id, numbers, title, outcome in BANDS:
        own = []
        for lesson in f0['lessons']:
            if lesson['bandId'] == band_id:
                own.append(dict(id=lesson['id'], kind='foundation', bandId=band_id,
                                title=lesson['title'], prerequisiteIds=[], required=True))
        for task in task_data['tasks']:
            if phase_band[task['phaseId']] == band_id:
                own.append(dict(id=task['id'], taskId=task['id'], kind='phaseTask', bandId=band_id,
                                phaseId=task['phaseId'], title=task['title'], skill=task['skill'],
                                contentHash=task['contentHash'], prerequisiteIds=task['prerequisiteTaskIds'], required=True))
        # Explicitly represents the unmet band completion gate. It cannot be
        # completed by selecting a card, replaying a task or using a substitute.
        pending_id = band_id + '.transfer-review'
        own.append(dict(id=pending_id, kind='pending', bandId=band_id, title=outcome,
                        prerequisiteIds=[], required=True))
        activities.extend(own)
        bands.append(dict(id=band_id, level=band_id.split('.')[0], title=title, outcome=outcome,
                          phaseIds=[f'KP{n:02}' for n in numbers],
                          activityIds=[a['id'] for a in own],
                          coverage='partial', reviewStatus='pedagogical_assignment_human_review_pending',
                          dimensions=['listening', 'speaking', 'reading', 'writing', 'pronunciation', 'vocabulary', 'grammar', 'register', 'culture', 'delayed_transfer']))
    source = list(csv.DictReader(io.StringIO((DOCS / 'reference/EXISTING_GRAMMAR_INVENTORY.csv').read_text(encoding='utf-8-sig'))))
    by_key = defaultdict(list)
    for t in task_data['tasks']:
        for key in t['requirementKeys']:
            by_key[(t['phaseId'], key)].append(t['id'])
    dependencies = defaultdict(set)
    for edge in phases['dependencyMap']:
        dependencies[edge['targetKey']].add(edge['prerequisiteKey'])
        if edge.get('advancedReuseKey'):
            dependencies[edge['advancedReuseKey']].add(edge['targetKey'])
    new_rows = {r['grammar_key']: r for r in source if r['role'] == 'new'}
    assert len(new_rows) == 336, 'Each grammar item has exactly one new introduction'
    def check_graph(graph, known):
        visiting, visited = set(), set()
        def visit(node):
            assert node in known, 'Unknown prerequisite: ' + node
            assert node not in visiting, 'Cyclic prerequisite: ' + node
            if node in visited:
                return
            visiting.add(node)
            for parent in graph.get(node, []):
                visit(parent)
            visiting.remove(node)
            visited.add(node)
        for node in known:
            visit(node)
        return len(visited)
    grammar_checked = check_graph(dependencies, set(new_rows))
    task_graph = {t['id']: t['prerequisiteTaskIds'] for t in task_data['tasks']}
    check_graph(task_graph, set(task_graph))
    tasks_by_id = {t['id']: t for t in task_data['tasks']}
    for a in activities:
        if a['kind'] != 'phaseTask':
            continue
        task = tasks_by_id[a['id']]
        candidates = []
        for key in task['requirementKeys']:
            for parent in sorted(dependencies.get(key, [])):
                parent_phase = new_rows[parent]['existing_phase_id']
                candidates.extend(by_key[(parent_phase, parent)])
        a['preparationTaskIds'] = sorted(set(candidates) - {a['id']})
    # These are teaching suggestions, never a new mastery gate. The source
    # Phase catalog currently has no task prerequisite edges.
    check_graph({a['id']: a.get('preparationTaskIds', []) for a in activities
                 if a['kind'] == 'phaseTask'}, set(task_graph))
    mapped = []
    for row in source:
        b = phase_band[row['existing_phase_id']]
        mapped.append(dict(**row, band_id=b, decision='retain_source_and_group_display',
                           decision_reason='원 급과 도입 순서를 보존하고 승인된 기능 중심 표시 구간으로 묶음; 개별 이동은 교사 검토 후 별도 개정',
                           prerequisite_grammar_keys='|'.join(sorted(dependencies[row['grammar_key']])),
                           linked_task_ids='|'.join(by_key[(row['existing_phase_id'], row['grammar_key'])]),
                           disposition='receptive_and_productive_review_required',
                           mapping_review_status='candidate_not_teacher_approved'))
    assert Counter(r['role'] for r in mapped) == {'new': 336, 'spiral': 20}
    out = io.StringIO(newline='')
    writer = csv.DictWriter(out, fieldnames=list(mapped[0]), lineterminator='\n')
    writer.writeheader()
    writer.writerows(mapped)
    report = {
        'schemaVersion': 1, 'sourcePhaseCount': len(phases['phases']), 'sourceTaskCount': len(task_data['tasks']),
        'grammarRows': len(mapped), 'grammarRoles': dict(Counter(r['role'] for r in mapped)),
        'linkedGrammarRows': sum(bool(r['linked_task_ids']) for r in mapped),
        'taskSkills': dict(Counter(t['skill'] for t in task_data['tasks'])),
        'dependencyAudit': {'grammarNodesChecked': grammar_checked, 'cycles': 0,
                            'originalTaskEdges': sum(len(v) for v in task_graph.values()),
                            'derivedPreparationEdges': sum(len(a.get('preparationTaskIds', [])) for a in activities),
                            'meaning': 'declared graph consistency only; not proof that every teaching prerequisite has been authored'},
        'routes': {'phaseTask': '/learning-phase/task', 'foundation': '/path/foundation', 'path': '/path/v2'},
        'coverage': 'partial_not_full_curriculum_completion',
        'sources': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in [
            'assets/data/phase_tasks.json', 'assets/data/learning_phases.json', 'assets/data/curriculum_manifest.json',
            'tools/content_factory/cefr_matrix/phases.json']},
        'unverified': ['teacher_item_review', 'beginner_observation', 'audio_listening_review', 'full_band_transfer',
                       'physical_device_qa', 'cross_device_extension_sync', 'historical_episode_expansion'],
    }
    def js(value):
        return json.dumps(value, ensure_ascii=False, indent=2) + '\n'
    dimensions = []
    for p in phases['phases']:
        for dimension in ['functions', 'vocabDomains', 'phonology', 'pragmaticsRegister',
                          'listening', 'speaking', 'reading', 'writing', 'prerequisites',
                          'masteryCheck', 'enBridge', 'deBridge', 'transferWarnings']:
            dimensions.append({'phaseId': p['id'], 'bandId': phase_band[p['id']],
                               'dimension': dimension, 'sourceValue': p[dimension],
                               'taskIds': [t['id'] for t in task_data['tasks'] if t['phaseId'] == p['id']
                                           and (t['skill'] == dimension or dimension not in ['listening','speaking','reading','writing'])],
                               'linkScope': 'phase-level candidates, requires item-level educational review'})
    return {
        DATA / 'lernpfad_v2.json': js(dict(schemaVersion=1, curriculumVersion='lernpfad-v2-20261023.1', bands=bands, activities=activities)),
        DATA / 'lernpfad_foundation.json': js(f0),
        DOCS / 'GRAMMAR_CROSSWALK.csv': out.getvalue(),
        DOCS / 'COVERAGE_AUDIT.json': js(report),
        DOCS / 'DIMENSION_CROSSWALK.json': js({'source': 'tools/content_factory/cefr_matrix/phases.json',
                                             'reviewStatus': 'source-preserving candidate', 'rows': dimensions}),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    stale = []
    for path, content in build().items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8') != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding='utf-8', newline='\n')
    if stale:
        raise SystemExit('Stale derived files: ' + ', '.join(stale))
    print('Lernpfad: 16 bands, 30 preserved phases, 902 task links, 356 grammar rows; coverage partial.')


if __name__ == '__main__':
    main()
