"""Promote Jin's exact approved PNG bytes; does not publish or change runtime."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / 'assets_unused/pending_review/personal_hanok_v3/ansarang_shrine_maintained_v1'
BASE = ROOT / 'assets_unused/pending_review/personal_hanok_v3'
APPROVED = {
    'ansarangchae': ('b5f58783f01005b6babac4ac5a85a7b8a86e3f06c90154e4cbc670fee1f47497', 14, 'ansarang'),
    'sadangmun': ('336dcc5251b2f3edfaaa57d0dbd2902b0034491f36c4eda8fdc01a5c0d52be4e', 8, 'sadang-gate'),
    'sadang': ('8cfc8bb5ca7ce6ae652c9defd1eb0bb3b523ac29eef1cf3afc6e370223869069', 12, 'sadang'),
}
EVIDENCE = '너무 좋아ㅎㅎ 그걸로 최종 완성된 정본으로 올리고, 완성정본을 고정한채 서까래와 기둥 그리고 지붕등이 설계되면서 어긋나지않고 평면이 아닌 사람이 이용하던 건물을 기억하며 2.5D로 건물 완성 설계해줘'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def main():
    # Validate all inputs and existing destinations before copying any master.
    for building, (digest, _, _) in APPROVED.items():
        source = REVIEW / 'masters' / f'{building}_maintained_front_right.png'
        assert sha(source) == digest, f'Approved source changed: {source}'
        target = BASE / 'canonical' / building / f'{building}-v3-canonical.png'
        assert not target.exists() or sha(target) == digest, f'Different canonical file already exists: {target}'
    style_path = ROOT / 'docs/assets/STYLE_LOCK.json'
    style = json.loads(style_path.read_text(encoding='utf-8'))
    family = style['families']['F-D-ildoo']
    if any(family['canonicalMasterApprovals'].get(b, {}).get('runtimePromoted') for b in APPROVED):
        raise RuntimeError('Masters already have runtime consumers. Verify with the construction registrar; do not reset their promotion metadata.')
    for building, (digest, stage_count, anchor) in APPROVED.items():
        source = REVIEW / 'masters' / f'{building}_maintained_front_right.png'
        directory = BASE / 'canonical' / building
        directory.mkdir(parents=True, exist_ok=True)
        target = directory / f'{building}-v3-canonical.png'
        shutil.copyfile(source, target)
        assert sha(target) == digest and target.read_bytes() == source.read_bytes()
        with Image.open(target) as im:
            canvas, mode = list(im.size), im.mode
        lock = {
            'schema': 'hanok-canonical-art-master-v1', 'buildingId': building,
            'anchorId': anchor, 'status': 'approved_canonical_master',
            'approvedBy': 'Jin', 'approvedAt': '2026-09-14', 'approvalEvidence': EVIDENCE,
            'file': target.name, 'sha256': digest, 'bytes': target.stat().st_size,
            'canvas': canvas, 'mode': mode, 'background': 'true transparent RGBA',
            'copiedWithoutReencoding': True,
            'provenance': {'approvedCandidate': relative(source), 'manifest': relative(REVIEW / 'MANIFEST.json')},
            'authority': {
                'styleRegistry': 'docs/assets/STYLE_LOCK.json#families.F-D-ildoo',
                'role': 'Final appearance and camera authority for this building and its construction sequence.',
                'invariants': ['Exact final PNG bytes including alpha, canvas, framing and material finish.',
                               'Building-specific roof shape, bay count, post axes, recessed doors, floor and stone base.',
                               'Front and rear structural rows enclose a usable volume, not a flat facade.',
                               'Stages reuse shared structural nodes; installed members never drift or change scale.'],
                'constructionCompletion': 'Use this exact file for the final stage. Never regenerate, recolor, crop, warp or resize the stored PNG.',
                'intermediateStages': '34-stage production design is separate from completed intermediate PNG artwork.',
                'historicalAccuracy': 'Illustration identity approval; hidden dimensions and members are teaching reconstructions unless evidenced.',
            },
            'construction': {'stageCount': stage_count, 'completedStage': stage_count,
                             'design': 'docs/assets/ildu_ansarang_shrine_construction_20260914/construction_design.json'},
            'runtime': {'promoted': False, 'reason': 'Master promotion and construction design requested; no completed intermediate series or runtime consumer yet.'},
        }
        manifest = directory / 'CANONICAL_LOCK.json'
        manifest.write_text(json.dumps(lock, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        family['canonSprites'][building] = target.relative_to(BASE).as_posix()
        if relative(target) not in family['anchors']:
            family['anchors'].append(relative(target))
        family['canonicalMasterApprovals'][building] = {
            'status': 'approved_canonical_master', 'approvedBy': 'Jin', 'approvedAt': '2026-09-14',
            'manifest': relative(manifest), 'sourceVersion': f'{building}-v3-maintained-v1',
            'sha256': digest, 'completedAsset': relative(target), 'completedStage': stage_count,
            'scope': '승인한 단일 시점 완성 정본. 마지막 공정은 같은 PNG 바이트를 사용한다. 기둥·보·도리·서까래·지붕은 공통 기준점을 공유한다.',
            'materialOverride': '사람이 돌보고 이용하는 건강한 무광 목재·기와·회벽·석재·단청. 낡음·파손·평면화로 돌아가지 않는다.',
            'derivativeViews': '이 시점만 승인됐다. 이전 8방향 파일은 역사적 참고이며 새 고화질 정본을 대신하지 않는다.',
            'runtimePromoted': False,
        }
        print(building, digest, relative(target))
    note = ' 안사랑채·사당문·사당은 2026-09-14 승인한 canonical/ 하위 고화질 단일 시점을 완성 정본으로 고정했다. 34단계 공정 설계와 실제 공정 그림·런타임 승격 상태는 구분한다.'
    if note.strip() not in family['anchorsNote']:
        family['anchorsNote'] += note
    style_path.write_text(json.dumps(style, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    source_manifest = REVIEW / 'MANIFEST.json'
    record = json.loads(source_manifest.read_text(encoding='utf-8'))
    record.update(status='approved_sources_copied_to_canonical_without_reencoding',
                  approved_by='Jin', approved_on='2026-09-14')
    for master in record['masters']:
        building = master['building']
        master['status'] = 'approved_canonical_source_runtime_not_promoted'
        master['canonical_lock'] = relative(BASE / 'canonical' / building / 'CANONICAL_LOCK.json')
    source_manifest.write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    validation_path = REVIEW / 'VALIDATION.json'
    validation = json.loads(validation_path.read_text(encoding='utf-8'))
    validation['asset_status'] = 'approved_canonical_sources'
    validation['not_completed'] = [s for s in validation['not_completed'] if s != 'User acceptance of the three new masters']
    validation['not_completed'] = ['31 intermediate construction stage images' if s == '34 construction stage images' else s for s in validation['not_completed']]
    validation['canonical_design_validation'] = 'docs/assets/ildu_ansarang_shrine_construction_20260914/design_validation.json'
    validation_path.write_text(json.dumps(validation, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
