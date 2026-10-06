"""Preserve approved references and build an inspectable, provenance-aware contract.

Reads image pixels only; never resizes, crops, repaints, or generates artwork.
The rectangles below are manually measured raster bounds, not recovered dp.
"""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TEMP = Path('C:/Users/vjinn/AppData/Local/Temp')
GENERATED = Path('C:/Users/vjinn/.codex/generated_images/01a10981-52b8-7171-9152-7c911290e994')
APPROVED = [
    ('main-five-tabs', '메인 5탭', '7b328b4c-5932-4e20-aeec-b7805b2d42b6', None),
    ('intro-01', '01 · 시작 수준과 관심', '2f8aceea-8234-4370-9587-21cd579dcc50', '01-level-a2-selected'),
    ('intro-02', '02 · 학습 경로', 'aa544a3d-342b-4bd5-a41a-bbca41ce7de9', '02-learning-path'),
    ('intro-03', '03 · 첫 소리', 'c4429bf7-ca78-4207-b739-8f4e8d83cd30', '03-learning-preview'),
    ('intro-04', '04 · 게임과 보상', '750135b4-017d-422f-a114-c55c685a4921', '04-games-reward'),
    ('intro-05', '05 · 책과 탈선비', '5fd2ef08-38cf-41c6-9622-efabcd03f75e', '05-book-learning'),
    ('intro-06', '06 · 한옥과 문화', 'f707728f-f0fe-43f9-9ccd-23348763dc36', '06-hanok-culture'),
    ('intro-07', '07 · 동행 선택', '07b14be1-ba3e-4318-9c9e-ede8f6071578', '07-taego-selected'),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def box(name, rect, kind='card'):
    return {'label': name, 'rect': rect, 'kind': kind, 'origin': 'raster-measurement', 'tolerancePx': 3}


def gap(name, start, end):
    return {'label': name, 'start': start, 'end': end, 'px': abs(end[1]-start[1]) or abs(end[0]-start[0]),
            'origin': 'raster-measurement', 'tolerancePx': 3}


SCREENS = [
    {'id': 'today', 'reference': 'main-five-tabs', 'title': 'Heute', 'viewport': [1, 10, 350, 756],
     'boxes': [box('미션 보드', [13, 163, 327, 544]), box('한글 그림 가시 영역', [78, 254, 202, 139], 'image'),
               box('학습 CTA', [25, 407, 303, 50], 'cta'), box('한옥 카드', [25, 509, 303, 119]),
               box('앱 안내 카드', [25, 637, 303, 70]), box('5탭 내비게이션', [1, 707, 350, 59], 'nav')],
     'gaps': [gap('한옥 → 안내 카드', [320, 628], [320, 637])]},
    {'id': 'learn', 'reference': 'main-five-tabs', 'title': 'Lernen', 'viewport': [375, 10, 350, 756],
     'boxes': [box('학습 보드', [387, 111, 327, 596]), box('열린 책 가시 영역', [436, 213, 231, 111], 'image'),
               box('학습 CTA', [399, 339, 304, 50], 'cta'), box('Wörter', [399, 398, 147, 109]),
               box('Hören', [555, 398, 147, 109]), box('Hangul', [399, 514, 147, 109]),
               box('Wiederholen', [555, 514, 147, 109]), box('코스 CTA', [399, 633, 304, 50], 'cta'),
               box('5탭 내비게이션', [375, 707, 350, 59], 'nav')],
     'gaps': [gap('CTA → 카드', [709, 389], [709, 398]), gap('카드 열 간격', [546, 450], [555, 450]),
              gap('카드 행 간격', [709, 507], [709, 514]), gap('카드 → 코스 CTA', [709, 623], [709, 633])]},
    {'id': 'games', 'reference': 'main-five-tabs', 'title': 'Spiele', 'viewport': [748, 10, 350, 756],
     'boxes': [box('게임 보드', [760, 108, 327, 599]), box('도깨비 이미지', [772, 121, 302, 197], 'image'),
               box('게임 CTA', [772, 361, 302, 50], 'cta'), box('초성', [772, 420, 95, 97]),
               box('빈칸', [875, 420, 95, 97]), box('짝 맞추기', [978, 420, 96, 97]),
               box('문장 조립', [772, 525, 147, 97]), box('끝말잇기', [927, 525, 147, 97]),
               box('DIY 단어', [772, 631, 302, 76]), box('5탭 내비게이션', [748, 707, 350, 59], 'nav')],
     'gaps': [gap('CTA → 카드', [1080, 411], [1080, 420]), gap('3열 간격', [867, 464], [875, 464]),
              gap('첫 행 → 둘째 행', [1080, 517], [1080, 525]), gap('둘째 행 → DIY', [1080, 622], [1080, 631])]},
    {'id': 'hanok', 'reference': 'main-five-tabs', 'title': 'Hanok', 'viewport': [1122, 10, 350, 756],
     'boxes': [box('한옥 보드', [1134, 108, 327, 599]), box('한옥 이미지', [1146, 120, 302, 250], 'image'),
               box('건축 CTA', [1146, 476, 302, 50], 'cta'), box('단청 카드', [1146, 536, 302, 108]),
               box('아틀리에 CTA', [1248, 582, 190, 44], 'cta'), box('단청 이미지', [1157, 548, 82, 82], 'image'),
               box('작업 카드', [1146, 654, 302, 53]), box('5탭 내비게이션', [1122, 707, 350, 59], 'nav')],
     'gaps': [gap('CTA → 단청 카드', [1454, 526], [1454, 536]), gap('단청 → 작업 카드', [1454, 644], [1454, 654])]},
    {'id': 'gye', 'reference': 'main-five-tabs', 'title': 'Gye', 'viewport': [1495, 10, 350, 756],
     'boxes': [box('그룹 보드', [1507, 133, 327, 543]), box('함께 읽기 이미지', [1520, 134, 302, 229], 'image'),
               box('코드 참여 CTA', [1520, 478, 302, 44], 'cta'), box('그룹 생성 CTA', [1520, 530, 302, 44], 'cta'),
               box('혼자 계속하기', [1520, 582, 302, 40], 'action'), box('더 알아보기', [1520, 625, 302, 39], 'action'),
               box('5탭 내비게이션', [1495, 707, 350, 59], 'nav')],
     'gaps': [gap('참여 → 생성 CTA', [1828, 522], [1828, 530])]},
]
INTRO_RECTS = {
    '01': ([53, 275, 747, 350], [82, 1634, 688, 91], None),
    '02': ([53, 275, 747, 980], [82, 1506, 688, 106], [241, 1638, 372, 38]),
    '03': ([53, 275, 747, 1068], [82, 1500, 688, 108], [241, 1636, 372, 42]),
    '04': ([53, 275, 747, 930], [82, 1472, 688, 110], [241, 1611, 372, 42]),
    '05': ([53, 275, 747, 1017], [82, 1492, 688, 108], [241, 1625, 372, 43]),
    '06': ([53, 275, 747, 983], [78, 1468, 700, 104], [241, 1595, 372, 44]),
    '07': ([65, 300, 735, 1148], [78, 1488, 700, 104], [241, 1610, 372, 42]),
}
for page, (hero, cta, back) in INTRO_RECTS.items():
    boxes = [box('앱 내용 비교 영역 (기기 프레임 제외)', [53, 53, 747, 1733], 'viewport'),
             box('브랜드 / 단계', [92, 151, 670, 67], 'header'), box('진행 점', [184, 228, 429, 37], 'nav'),
             box('장면 / 주요 구성', hero, 'image'), box('주 CTA', cta, 'cta')]
    if back:
        boxes.append(box('뒤로 글자 가시 영역', back, 'action'))
    if page == '01':
        boxes += [box('A2 수준 선택', [81, 723, 694, 134]), box('관심 1', [81, 990, 337, 234]),
                  box('관심 2', [437, 990, 337, 234]), box('관심 3', [81, 1236, 337, 220]),
                  box('관심 4', [437, 1236, 337, 220])]
        gaps = [gap('관심 카드 열 간격', [418, 1080], [437, 1080]), gap('관심 카드 행 간격', [783, 1224], [783, 1236])]
    elif page == '07':
        boxes += [box('Taego 선택 이미지', [65, 489, 368, 539], 'image'), box('Joy 이미지', [444, 498, 352, 529], 'image'),
                  box('Taego 카드', [65, 489, 368, 673]), box('Joy 카드', [444, 498, 352, 664]),
                  box('Gye 소개 카드', [74, 1178, 710, 291])]
        gaps = [gap('동행 카드 열 간격', [433, 730], [444, 730]), gap('동행 → Gye', [790, 1162], [790, 1178]),
                gap('Gye → CTA', [791, 1469], [791, 1488])]
    else:
        gaps = []
    if back:
        gaps.append(gap('CTA → 뒤로 글자', [788, cta[1]+cta[3]], [788, back[1]]))
    SCREENS.append({'id': f'intro-{page}', 'reference': f'intro-{page}', 'title': f'Einleitung {page}/07',
                    'viewport': [53, 53, 747, 1733], 'boxes': boxes, 'gaps': gaps})

# Current source-confirmed C metrics, used as semantic implementation tokens.
# Raster-derived comparison values stay in separate screen records above.
TOKENS = {
    'main.gutter': (12, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 798),
    'card.padding': (12, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 389),
    'card.radius': (14, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 390),
    'board.radius': (18, 'dp', 'lib/screens/sori_stage/sori_stage_today_screen.dart', 571),
    'learn.card.gap': (10, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 575),
    'learn.card.padding': (8, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 588),
    'learn.card.artHeight': (76, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 592),
    'game.card.gap': (8, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 684),
    'game.card.padding': (6, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 649),
    'game.card.artHeight': (70, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 653),
    'tile.radius': (10, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 648),
    'tile.artToLabel': (4, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 657),
    'game.heroToTitle': (8, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 702),
    'game.titleToCta': (10, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 708),
    'game.ctaToCards': (12, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 714),
    'game.rowGap': (10, 'dp', 'lib/screens/sori_stage/sori_stage_catalog_screen.dart', 720),
    'cta.minHeight': (54, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 516),
    'cta.compactMinHeight': (48, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 516),
    'cta.radius': (9, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 519),
    'cta.paddingX': (12, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 565),
    'cta.paddingY': (10, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 566),
    'cta.depth': (4, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 502),
    'cta.border': (1.3, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 525),
    'cta.labelSize': (21, 'sp', 'lib/widgets/sori/c_gallery/c_materials.dart', 483),
    'cta.compactLabelSize': (16, 'sp', 'lib/widgets/sori/c_gallery/c_materials.dart', 483),
    'cta.arrowWidth': (18, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 579),
    'cta.arrowHeight': (24, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 580),
    'navigation.height': (64, 'dp', 'lib/widgets/sori/adaptive_navigation.dart', 88),
    'intro.bodyGutter': (14, 'dp', 'lib/screens/onboarding_v2/c_onboarding.dart', 104),
    'intro.interestGap': (9, 'dp', 'lib/screens/onboarding_v2/c_onboarding.dart', 397),
    'intro.companionGap': (9, 'dp', 'lib/screens/onboarding_v2/c_onboarding.dart', 790),
    'intro.companionToGye': (14, 'dp', 'lib/screens/onboarding_v2/c_onboarding.dart', 799),
    'touch.min': (48, 'dp', 'lib/widgets/sori/c_gallery/c_materials.dart', 515),
}


def build():
    reference_dir = HERE / 'reference'
    reference_dir.mkdir(parents=True, exist_ok=True)
    records = []
    generated_by_hash = {}
    for path in GENERATED.glob('*.png'):
        with Image.open(path) as im:
            if im.size == (853, 1844):
                generated_by_hash[digest(path)] = str(path)
    for ident, title, temp_id, source_id in APPROVED:
        source = TEMP / f'codex-clipboard-{temp_id}.png'
        destination = reference_dir / f'{ident}.png'
        # A subsequent regeneration can use the preserved copy after Temp cleanup.
        if source.exists():
            if destination.exists() and digest(destination) != digest(source):
                raise RuntimeError(f'Reference replacement requires a new approval version: {ident}')
            if not destination.exists():
                shutil.copyfile(source, destination)
        if not destination.exists():
            raise FileNotFoundError(source)
        with Image.open(destination) as im:
            width, height = im.size
        sha = digest(destination)
        records.append({'id': ident, 'title': title, 'path': f'reference/{ident}.png', 'sourcePath': str(source),
                        'width': width, 'height': height, 'sha256': sha, 'generatedOriginal': generated_by_hash.get(sha),
                        'existingIntroSourceId': source_id, 'approval': 'human latest attachments, 2026-10-05',
                        'includesBakedGermanText': True, 'imageBytesModified': False})
    assets = ROOT / 'assets/illustrations/concept_c'
    region_manifest = json.loads((assets / 'einleitung/source-manifest.json').read_text(encoding='utf-8-sig'))
    region_records = []
    for rec in region_manifest['records']:
        if rec.get('type') != 'unchanged-source-pixel-crop':
            continue
        local = assets / 'einleitung' / Path(rec['path']).name
        if not local.exists():
            raise FileNotFoundError(local)
        region_records.append({'id': rec['id'], 'path': local.relative_to(ROOT).as_posix(),
                               'sourceId': rec['sourceId'], 'sourceRect': rec['sourceRect'],
                               'width': rec['width'], 'height': rec['height'], 'bakedUiText': rec['bakedUiText'],
                               'sha256': digest(local), 'matchesExistingManifest': digest(local) == rec['sha256'],
                               'originalPreservation': 'original source pixels; existing crop, no new image editing'})
    source_paths = sorted({data[2] for data in TOKENS.values()} | {
        'lib/screens/sori_stage/c_stage_chrome.dart', 'lib/widgets/sori/c_gallery/c_palette.dart',
        'lib/widgets/sori/c_gallery/c_objects.dart', 'lib/screens/sori_stage/sori_stage_hanok_screen.dart',
        'lib/screens/sori_stage/sori_stage_gye_screen.dart', 'lib/screens/gye_tab_screen.dart',
        'assets/illustrations/concept_c/einleitung/source-manifest.json'})
    source_snapshot = [{'path': p, 'sha256': digest(ROOT/p)} for p in source_paths]
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    manifest = {'schemaVersion': 1, 'contractId': 'c-approved-visual-20261005-v1', 'date': '2026-10-05',
                'root': str(ROOT), 'head': head, 'authority': 'latest human-approved 8 attachments',
                'screensCovered': 12, 'references': records, 'runtimeRegions': region_records,
                'sourceSnapshot': source_snapshot,
                'historicalMainBoard': {'path': 'assets/illustrations/concept_c/reference_objects.png',
                                       'sha256': digest(assets/'reference_objects.png'),
                                       'role': 'retained art atlas, not latest main spacing/layout authority'},
                'verification': {'referenceCount': len(records), 'unchangedGeneratedOriginals': sum(bool(r['generatedOriginal']) for r in records),
                                 'regionCount': len(region_records), 'regionHashesMatch': all(r['matchesExistingManifest'] for r in region_records),
                                 'newImageGenerationCalls': 0, 'externalDesignConnectorCalls': 0,
                                 'flutterSharedFilesEdited': False, 'deviceQa': 'not performed'}}
    token_list = [{'name': name, 'value': v, 'unit': u, 'origin': 'current-source-exact',
                   'source': path, 'line': line, 'approvalMeaning': 'verified implementation metric; image comparison remains required'}
                  for name, (v, u, path, line) in TOKENS.items()]
    for screen in SCREENS:
        screen['normalization'] = {'comparisonWidth': 390, 'factor': 390/screen['viewport'][2],
                                    'meaning': 'proportional raster comparison only; not recovered device dp'}
    geometry = {'contractId': manifest['contractId'], 'measurementUnit': 'original PNG pixels',
                'rasterBoundsTolerancePx': 3, 'normalizationRule': '390 / content viewport width; exclude phone bezel; preserve aspect ratio',
                'tokens': token_list, 'screens': SCREENS}
    for name, data in [('manifest.json', manifest), ('geometry.json', geometry)]:
        (HERE/name).write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    css = ['/* C approved geometry. dp becomes CSS px at 100%; sp uses rem for text scaling. */', ':root {']
    for name, (v, u, path, line) in TOKENS.items():
        if u == 'sp':
            css.append(f'  --c-{name.replace(".", "-")}: {v/16:g}rem;')
        else:
            css.append(f'  --c-{name.replace(".", "-")}: {v:g}px;')
    css.append('}')
    (HERE/'tokens.css').write_text('\n'.join(css)+'\n', encoding='utf-8')
    # Dart example is documentation only; the C owner integrates shared runtime files.
    dart = ['// Reference constants only. Not imported by the app.', 'abstract final class CApprovedGeometry {']
    for name, (v, u, path, line) in TOKENS.items():
        parts = name.split('.')
        dart_name = parts[0]+''.join(part[0].upper()+part[1:] for part in parts[1:])
        dart.append(f'  static const double {dart_name} = {v:g}; // {u}')
    dart.append('}')
    (HERE/'flutter_geometry_reference.dart.txt').write_text('\n'.join(dart)+'\n', encoding='utf-8')
    tables = ['# 화면별 원본 좌표와 간격', '', '이 표의 값은 원본 PNG의 px입니다. dp로 복구한 값이 아닙니다. 경계·그림자 판독 오차는 ±3px입니다. 비교 갤러리는 원본 위에 HTML 선만 겹칩니다.', '']
    for screen in SCREENS:
        tables += [f'## {screen["title"]}', '', f'내용 비교 영역: `{screen["viewport"]}` (x, y, width, height). 390 너비 비교 배율: {screen["normalization"]["factor"]:.6f}.', '', '| 영역 | x | y | 너비 | 높이 |', '|---|---:|---:|---:|---:|']
        for b in screen['boxes']:
            tables.append('| '+b['label']+' | '+' | '.join(map(str,b['rect']))+' |')
        if screen['gaps']:
            tables += ['', '| 간격 | 원본 px | 390 너비 비례 비교값 |', '|---|---:|---:|']
            for g in screen['gaps']:
                tables.append(f'| {g["label"]} | {g["px"]} | {g["px"]*screen["normalization"]["factor"]:.1f} |')
        tables.append('')
    (HERE/'SCREEN_MEASUREMENTS.md').write_text('\n'.join(tables), encoding='utf-8')
    print(json.dumps(manifest['verification'], ensure_ascii=False))


if __name__ == '__main__':
    build()
