"""Crop the reported location from real renders and publish a local A/B viewer."""
import hashlib,json
from pathlib import Path
from PIL import Image
OUT=Path(__file__).resolve().parent;R4=OUT.parent/'living-r4'

def sha(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

v=json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
m=json.loads((OUT/'render-manifest.json').read_text(encoding='utf-8'))
assert v['passed'] and sha(OUT/v['library'])==v['library_sha256']==m['library_sha256']
assert sha(OUT/'scope_patch.py')==v['scope_code_sha256']
assert sha(OUT/'lighting_patch.py')==v['light_code_sha256']
assert sha(OUT/'ground-scope.json')==v['ground_scope_sha256']
for view in ('overview','full','detail'):
    pair=[next(r for r in m['renders'] if r['view']==view and r['variant']==variant) for variant in ('A','B')]
    for key in ('camera','samples','seed','resolution'):assert pair[0][key]==pair[1][key]
    for r in pair:
        assert sha(OUT/r['file'])==r['sha256']
        with Image.open(OUT/r['file']) as im:assert im.size==(1280,960)
crop=(775,70,1240,320);proofs=[]
for variant in ('A','B'):
    source=OUT/('overview-'+variant+'.png')
    with Image.open(source) as im:im.crop(crop).save(OUT/('seam-'+variant+'.png'))
    proofs.append(dict(variant=variant,file='seam-'+variant+'.png',sha256=sha(OUT/('seam-'+variant+'.png')),
                       source=source.name,source_sha256=sha(source),source_crop=list(crop),size=[465,250]))
write=lambda name,val:(OUT/name).write_text(json.dumps(val,ensure_ascii=False,indent=2),encoding='utf-8')
write('seam-crop-proof.json',proofs)
source=(R4/'index.html').read_text(encoding='utf-8')
changes={
    '일두고택 · 전체 흙마당 다시보기':'일두고택 · 흙마당 경계 수정',
    '../living-r3/index.html':'../living-r4/index.html',
    '← 이전 마당·담장 비교':'← 직전 흙마당 비교',
    '<h1>전체 흙마당 다시보기</h1>':'<h1>흙마당 경계 수정</h1>',
    '밭과 담장은 유지하고, 넓은 마당의 흙결·입자 밀도·다짐 차이를 조정했습니다. 전체 구도에서 먼저 비교해 주세요.':'잘려 보이던 마당의 빛 경계를 고쳤습니다. 같은 구도에서 계단 앞과 마당 전체를 비교해 주세요.',
    '<div class="controls" aria-label="비교 시점">':'<div class="controls" aria-label="비교 시점">\n<button type="button" data-view="seam" aria-pressed="true">계단 앞 경계</button>',
    'data-view="full" aria-pressed="true"':'data-view="full" aria-pressed="false"',
    'B · 전체 흙결을 조정한 마당':'B · 경계 수정 후',
    'A · 직전 마당':'A · 직전 결과',
    '<div class="compare">':'<div class="compare" style="aspect-ratio:465/250">',
    'full-A.png':'seam-A.png','full-B.png':'seam-B.png',
    '고택 전체 A: 직전 마당':'계단 앞 경계 A: 직전 결과',
    '고택 전체 B: 흙결을 조정한 마당':'계단 앞 경계 B: 경계 수정 후',
    "const names={detail:":"const names={seam:'계단 앞 경계',detail:",
    '같은 카메라·조명입니다. 기존 A와 새 표면 B를 버튼이나 키보드 방향키로 비교하세요.':'같은 카메라입니다. 마당 보조조명을 수정한 전후를 버튼이나 방향키로 비교하세요.',
    "const view=button.dataset.view;":"const view=button.dataset.view;document.querySelector('.compare').style.aspectRatio=view==='seam'?'465 / 250':'4 / 3';",
    'courtyard-soil-r4.blend':'continuous-yard-r5.blend',
    "variant==='A'?'직전 마당':'흙결을 조정한 마당'":"variant==='A'?'직전 결과':'경계 수정 후'",
    '>Blender 재질</a>':'>Blender 재질·조명</a>',
    '밭·풀·담장·건물 형상과 배치는 같습니다. 마당 흙만 조정한 검토 후보입니다. 전체 장면의 문은 기존 모델이며, 새 세 문 결합과 실제 앱 적용은 별도입니다.':'건물·밭의 재질과 배치를 보존하고 마당 보조조명의 방향·높이·연결 대상을 수정했습니다. 전체 장면의 문은 기존 모델이며, 새 세 문 결합과 실제 앱 적용은 별도입니다.',
}
for old,new in changes.items():
    assert old in source,old
    source=source.replace(old,new)
(OUT/'index.html').write_text(source,encoding='utf-8')
write('package-verification.json',dict(passed=True,native_library_sha256=v['library_sha256'],
    rendered_images=6,comparison_crops=2,same_camera_samples_seed_resolution=True,
    lighting_intentionally_changed_only_for_yard_direct_receivers=True,
    existing_geometry_uv_transforms_equal=True,non_target_material_bindings_equal=True,
    app_integrated=False))
print('R5 PACKAGE PASS: 6 actual renders + 2 traceable crops')
