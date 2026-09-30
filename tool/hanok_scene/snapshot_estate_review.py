"""Publish the final checkpoint status and preserve its review page in Git."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
DIST = Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist')
TARGET = N / 'review-checkpoint'
page = DIST / 'work-status.html'
html = page.read_text(encoding='utf8')
old_sha = 'be3b88f8d5f754cb65e6192545b96fe3c9983dc28df65fc2922f32a6545c4c5c'
new_sha = 'bd921e4b0768bb7b9d0dba5c97fab3ce079e8f3ba649a2a9039334023b79450b'
html = html.replace('2026.09.30 · 기존 작업트리 이어서 작업 중', '2026.09.30 · 커밋 체크포인트 · 다음 세션 재개 계획')
html = re.sub(r'<p class="lead">.*?</p>', '<p class="lead">현재 미술 수정은 여기서 멈추고 같은 작업트리에서 이어갑니다. 기와·무광 표면과 기존 연결은 유지했고, 사랑채·중문채 일부 목재에 손그림 결을 적용했습니다. 기단 윗면에 불규칙 돌을 더하고 곳간채 뒤 담에 여백을 확보했습니다. 넓은 판벽과 나머지 건물의 미술은 아직 남아 있습니다. 아래에 다음 작업 순서와 전후 화면을 정리했습니다.</p>', html, count=1)
html = html.replace('20260930-timber-arris-1', '20260930-craft-2')
html = html.replace('광채·사당 뒤 담</h3><p>광채 기단과 담 사이, 사당 쪽의 여백을 조금 넓히는 위치 조정이 남았습니다. 꽃담 문양과 사당 배치는 보존 대상으로 둡니다.', '곳간채 뒤 담 여백</h3><p>연결된 담 6구간·44개 메시를 조정했습니다. 긴 뒤 담의 벽체 중심부와 기단 사이 간격은 1.116m입니다. 건물 위치와 꽃담 문양은 유지했고 같은 카메라의 전후 화면으로 빈 공간을 확인했습니다.')
html = html.replace('<span class="state todo">후속 작업</span><h3>곳간채 뒤 담 여백', '<span class="state active">후보 반영·검사</span><h3>곳간채 뒤 담 여백')
html = html.replace('estate-arris-overview-20260930.png', 'estate-craft-overview-20260930.png')
html = html.replace(old_sha, new_sha).replace('30개 항목이 모두 통과', '33개 항목이 모두 통과')
html = html.replace('원본 기본 형상 3,311개 메시', '원본 기본 형상 3,298개 메시')
html = html.replace('<th>Git 기준</th>', '<th>커밋 전 기준</th>')
html = html.replace('최종 미술 검토는 진행 중입니다.', '추가 목재·돌 상면·곳간채 뒤 간격 검사도 통과했습니다. 넓은 판벽과 전체 미술 검토는 다음 작업으로 남았습니다.')
section = '''
    <section id="completion-plan">
      <h2>다음 세션의 완성 순서</h2>
      <table><tbody>
        <tr><th>1 · 판벽부터</th><td>사랑채의 넓은 판벽 <code>Sarang floor grain 0~2</code>, 중문채 부속 판벽 <code>Jung plank 0~3</code>에는 이전 재질이 남았습니다. 새 목재가 기둥·보만 바꾸고 끝나지 않도록 넓은 면까지 먼저 마무리합니다.</td></tr>
        <tr><th>2 · 돌 상면·계단</th><td>기단 윗면의 불규칙 돌을 기준으로 큰 디딤돌·착지석·계단의 남은 매끈함과 줄무늬를 검토합니다. 마당은 흙으로 유지합니다.</td></tr>
        <tr><th>3 · 건물별 화풍</th><td>안채의 사진 명암과 흐릿한 결을 우선 다듬고 나머지 건물도 한 채씩 확인합니다. 목재는 각기 다르게, 기와·회벽·돌은 같은 화풍으로 조화시킵니다.</td></tr>
        <tr><th>4 · 고택 전체</th><td>담과 기단의 겹침, 문 회전 공간, 꽃담·지붕 이음, 누락·중복을 전체/배치/마당 화면에서 확인합니다. 승인된 창고 접점은 유지합니다.</td></tr>
        <tr><th>5 · 정원과 앱</th><td>본 건물 미술을 확인한 뒤 정원·정자를 작업합니다. 이후 앱 조작·모바일 성능·용량 검증과 런타임 적용을 진행합니다.</td></tr>
      </tbody></table>
      <p class="note">기존 작업트리 <code>C:\\dev\\hangulsori\\ko_lernen_app_worktrees\\hanok-hwalju-20260928</code>, 브랜치 <code>codex/hanok-hwalju-20260928</code>에서 이어갑니다. 한 번에 눈에 보이는 미술 문제 하나를 해결하고 같은 카메라 전후 2~3장과 전체 화면으로 확인합니다. <a href="completion-plan.md">자세한 완성 계획과 코드 진입점</a></p>
    </section>
    <section>
      <h2>사랑채·중문채 목재와 기단 윗면</h2>
      <p>사랑채에는 따뜻한 오래된 목재, 중문채에는 더 차분하고 짙은 결을 따로 그렸습니다. 현재 3개 목재 재질에 적용했고 넓은 판벽은 다음 작업입니다. 기단 윗면에는 12채와 사당문에 2,196개 얕은 불규칙 돌을 더했습니다. 모든 계단을 새로 만든 것은 아닙니다.</p>
      <div class="comparison">
        <figure><img src="references/sarang-craft-detail-before-20260930.png" alt="목재와 돌 상면 수정 전 사랑채 확대"><figcaption>사랑채 이전</figcaption></figure>
        <figure><img src="references/sarang-craft-detail-after-20260930.png" alt="목재와 돌 상면 수정 후 사랑채 확대"><figcaption>사랑채 현재 · 같은 카메라</figcaption></figure>
        <figure><img src="references/jung-craft-detail-before-20260930.png" alt="목재와 돌 상면 수정 전 중문채 확대"><figcaption>중문채 이전</figcaption></figure>
        <figure><img src="references/jung-craft-detail-after-20260930.png" alt="목재와 돌 상면 수정 후 중문채 확대"><figcaption>중문채 현재 · 같은 카메라</figcaption></figure>
      </div>
      <p class="note">목재를 볼 수 있도록 네 확대 화면에서 지붕을 숨겼습니다. 기본 화면에서는 기와가 보입니다. 새 돌은 건물 기단·계단·주변 돌 포장 범위이며 흙마당은 유지합니다.</p>
    </section>
    <section>
      <h2>곳간채 뒤 담과 기단의 여백</h2>
      <div class="comparison">
        <figure><img src="references/gokgan-gap-before-20260930.png" alt="곳간채 기단과 겹친 이전 뒤 담"><figcaption>이전 · 담과 기단 겹침</figcaption></figure>
        <figure><img src="references/gokgan-gap-after-20260930.png" alt="곳간채 기단과 뒤 담 사이 빈 공간"><figcaption>현재 · 건물 위치를 유지하며 담에 여유 확보</figcaption></figure>
      </div>
      <p>담의 돌·벽체·기와·밑돌을 함께 옮기고 꽃담 문양은 늘이지 않았습니다. 두 화면은 같은 카메라로 기단을 보기 위해 지붕을 숨겼습니다. <a href="estate.html?view=gokganRear&amp;v=20260930-craft-2">최신 3D 간격 보기</a></p>
    </section>
'''
if 'id="completion-plan"' not in html:
    html = html.replace('  <main>', '  <main>\n' + section, 1)
page.write_text(html, encoding='utf8')
shutil.copy2(ROOT / 'docs/plans/2026-09-30-ildu-estate-completion.md', DIST / 'completion-plan.md')


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.paths = set()

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ('src', 'href') and value:
                self.paths.add(value.split('?')[0].split('#')[0])


queue = ['work-status.html', 'estate.html', 'estate-viewer.js', 'completion-plan.md',
         'timber-detail-cameras.json', 'estate/manifest.json', 'estate-fabric-validation.json']
seen = set()
missing = []
while queue:
    relative = queue.pop()
    if not relative or ':' in relative or relative.startswith('/') or relative in seen:
        continue
    seen.add(relative)
    source = (DIST / relative).resolve()
    assert source.is_relative_to(DIST.resolve())
    if not source.is_file():
        missing.append(relative)
        continue
    dest = TARGET / relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest)
    if source.suffix == '.html':
        parser = Links()
        parser.feed(source.read_text(encoding='utf8'))
        queue.extend(str(Path(relative).parent / child) for child in parser.paths)
shutil.copytree(DIST / 'vendor', TARGET / 'vendor', dirs_exist_ok=True)
shutil.copy2(N.parent / 'vendor/LICENSE', TARGET / 'vendor/three/LICENSE')
shutil.copy2(DIST / 'references/sarang-painted-wood-20260930.png', TARGET / 'references/sarang-painted-wood-20260930.png')
shutil.copy2(DIST / 'references/jung-painted-wood-20260930.png', TARGET / 'references/jung-painted-wood-20260930.png')
for path in TARGET.rglob('*'):
    if path.is_file() and path.suffix in {'.json', '.html', '.js', '.svg', '.md'}:
        data = path.read_bytes().replace(b'\r\n', b'\n')
        if path.name in {'work-status.html', 'estate.html', 'estate-viewer.js'}:
            data = data.rstrip() + b'\n'
        path.write_bytes(data)
files = [{'file': str(path.relative_to(TARGET)).replace('\\', '/'),
          'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
         for path in sorted(TARGET.rglob('*')) if path.is_file() and path.name != 'review-files.json']
report = {'sceneSha256': new_sha, 'files': files, 'missingLinks': sorted(missing),
          'glbChunks': 'Kept in the existing local server; regenerate from the checkpoint native scene.',
          'browserReview': 'Latest scene loaded, no browser errors; timber/clearance and roof-visible overview inspected.'}
(TARGET / 'review-files.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print(json.dumps({'files': len(files), 'bytes': sum(row['bytes'] for row in files), 'missingLinks': missing}), flush=True)
