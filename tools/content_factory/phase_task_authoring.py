"""Small authoring helpers. Writing source never grants publication approval."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / 'tools/content_factory/cefr_matrix/phase_content'
PHASES = {p['id']: p for p in json.loads((FOLDER.parent / 'phases.json').read_text(encoding='utf-8'))['phases']}


def loc(ko, en, de):
    return dict(ko=ko, en=en, de=de)


def choice(qid, prompt, options, explanation, *, required=True):
    return dict(id=qid, kind='choice', prompt=prompt, required=required,
                options=[dict(id=str(i), text=text) for i, text in enumerate(options)],
                acceptedAnswers=['0'], explanation=explanation)


def sentence(qid, prompt, accepted, rejected, explanation):
    return dict(id=qid, kind='boundedSentence', prompt=prompt, required=True,
                options=[], acceptedAnswers=accepted, rejectedAnswers=rejected,
                explanation=explanation)


def packet(text, questions, kind='text'):
    return dict(sourceKind=kind, sourceKo=text, questions=questions)


def free_text(qid, prompt, rubric):
    """A required writing response with review guidance, never an answer key."""
    return dict(id=qid, kind='freeText', prompt=prompt, required=True,
                options=[], acceptedAnswers=[], explanation=rubric)


def task(phase_id, suffix, skill, title, teaching, practice, assessment,
         *, keys=(), examples=(), minimum=1, prerequisites=()):
    tid = f'{phase_id}:{suffix}'
    result = dict(id=tid, phaseId=phase_id, level=PHASES[phase_id]['level'],
                  objectiveId=tid, requirementKeys=list(keys), skill=skill,
                  mode='P' if skill in ('writing', 'speaking') else 'R',
                  contentRevision=1, rubricVersion=1, title=title, teaching=teaching,
                  examplesKo=list(examples), minimumScore=minimum,
                  prerequisiteTaskIds=list(prerequisites),
                  practice=practice, assessment=assessment)
    # Stable, varied positions prevent a catalogue-wide first-answer shortcut.
    for mode in ('practice', 'assessment'):
        for question in result[mode]['questions']:
            if question['kind'] == 'choice':
                seed = f'{tid}/{mode}/{question["id"]}'
                question['options'].sort(key=lambda option: hashlib.sha256(
                    (seed + '/' + option['id']).encode()).hexdigest())
    return result


def grammar_task(phase_id, index, key, teaching, practice, assessment):
    grammar = next(g for g in PHASES[phase_id]['koreanGrammar'] if g['grammarKey'] == key)
    prompt = loc('문장에 맞는 뜻을 고르세요.', 'Choose the meaning that matches the text.',
                 'Wähle die Bedeutung, die zum Text passt.')
    def make(row):
        text, right, wrong = row
        return packet(text, [choice('meaning', prompt, [right, wrong], teaching)])
    return task(phase_id, f'grammar:{index:02}', 'reading',
                loc(grammar['form'], grammar['form'], grammar['form']), teaching,
                make(practice), make(assessment), keys=[key],
                examples=[grammar['example']['ko'], assessment[0]])


def write_source(phase_id, tasks):
    """Leave an unsigned source for a separate KO/EN/DE/rubric review."""
    FOLDER.mkdir(parents=True, exist_ok=True)
    path = FOLDER / f'{phase_id.lower()}.json'
    path.write_text(json.dumps(dict(schemaVersion=1, phaseId=phase_id,
                                   status='partial', tasks=tasks),
                               ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return path
