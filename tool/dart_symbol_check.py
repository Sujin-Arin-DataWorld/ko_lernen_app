"""Dart 심볼 검사 — 레포 최상위 이름을 import 없이 쓰고 있지 않은가.

대문자 시작 타입과 `k` 접두 상수만 본다. 레포에 없는 이름은 Flutter/Dart SDK 로
보고 건너뛴다. `import` 누락과 오타를 잡는다.

    python3 tool/dart_symbol_check.py . lib/screens/foo.dart
"""
import io, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dart_static_check import strip

ROOT = sys.argv[1]
TARGETS = sys.argv[2:]

# 한 줄 안에서만 매칭한다. 문자 클래스에 \s 를 넣으면 줄을 넘어가서
# 들여쓴 위젯 생성자까지 "최상위 선언"으로 잡힌다 — 그게 1차 시도의 오진 원인.
H = r'[^\S\n]'
TYPE = re.compile(
    r'^(?:abstract|sealed|final|base|interface|mixin)?%s*'
    r'(?:class|enum|extension|mixin|typedef)%s+(\w+)' % (H, H), re.M)
VAR = re.compile(r'^(?:const|final)%s+[\w<>,\?\.%s]*?(\w+)%s*=' % (H, H, H), re.M)
FN = re.compile(r'^(?:[\w<>,\?\.\[\]%s]+)%s(\w+)%s*\(' % (H, H, H), re.M)

def declared(code):
    return set(TYPE.findall(code)) | set(VAR.findall(code)) | set(FN.findall(code))

IMP = re.compile(r"^\s*import\s+'([^']+)'", re.M)
EXP = re.compile(r"^\s*export\s+'([^']+)'(?:\s+show\s+([^;]+))?\s*;", re.M)
IDENT = re.compile(r'\b([A-Za-z_]\w*)\b')

RAW, CODE = {}, {}
for base in ('lib', 'test'):
    for d, _, fs in os.walk(os.path.join(ROOT, base)):
        for f in fs:
            if not f.endswith('.dart'): continue
            p = os.path.join(d, f)
            rel = os.path.relpath(p, ROOT).replace('\\', '/')
            RAW[rel] = io.open(p, encoding='utf-8').read()
            CODE[rel] = strip(RAW[rel])

# 대문자 시작(타입·위젯)과 k접두 상수만 본다. 소문자 최상위 이름은
# 테스트 헬퍼의 지역 선언과 구별이 어려워 오진이 난다.
PUB = re.compile(r'^([A-Z]|k[A-Z])')
repo = {}
for rel, code in CODE.items():
    for n in declared(code):
        if PUB.match(n):
            repo.setdefault(n, set()).add(rel)

def resolve(rel, spec):
    if spec.startswith('package:ko_lernen_app/'):
        return 'lib/' + spec[len('package:ko_lernen_app/'):]
    if spec.startswith('package:') or spec.startswith('dart:'):
        return None
    return os.path.normpath(os.path.join(os.path.dirname(rel), spec)).replace('\\', '/')

MISSING = []

def exported(rel, seen):
    """rel 이 밖으로 내보내는 이름 = 자기 선언 + 재수출."""
    if rel in seen: return set()
    seen.add(rel)
    if rel not in CODE:
        MISSING.append(rel); return set()
    names = declared(CODE[rel])
    for spec, show in EXP.findall(RAW[rel]):
        tgt = resolve(rel, spec)
        if not tgt: continue
        if show.strip():
            names |= {s.strip() for s in show.split(',') if s.strip()}
        else:
            names |= exported(tgt, seen)
    return names

def visible(rel):
    names = declared(CODE[rel])
    for spec in IMP.findall(RAW[rel]):
        tgt = resolve(rel, spec)
        if not tgt: continue
        names |= exported(tgt, set())
    return names

bad = []
for rel in TARGETS:
    body = IMP.sub('', CODE[rel])
    seen = visible(rel)
    for name in sorted(set(IDENT.findall(body))):
        if name in seen: continue
        if name not in repo: continue        # 레포에 없음 = Flutter/Dart SDK
        if rel in repo[name]: continue
        bad.append('%s: `%s` — 선언은 %s 에 있는데 import 가 없다'
                   % (rel, name, ', '.join(sorted(repo[name]))))
for m in sorted(set(MISSING)):
    bad.append('import 대상 파일이 없다: %s' % m)

if bad:
    print('심볼 문제 %d건:' % len(bad))
    for b in bad: print('  - ' + b)
    sys.exit(1)
print('심볼 OK — 레포 선언 %d개와 대조, 누락 import 없음 (%d 파일)' % (len(repo), len(TARGETS)))
