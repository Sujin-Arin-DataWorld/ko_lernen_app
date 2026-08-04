"""Dart 멤버 검사 — 토큰 클래스에 **없는 멤버**를 쓰고 있지 않은가.

심볼 검사기는 최상위 이름만 봐서 `SoriSurfaces.of(ctx).card` 같은 오류를
놓친다(2026-08-04 실제 발생). 자주 쓰이고 멤버가 유한한 토큰 클래스만 대조한다.

    python3 tool/dart_member_check.py . lib/screens/foo.dart
"""
import io, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dart_static_check import strip

ROOT, TARGETS = sys.argv[1], sys.argv[2:]

# 심볼 검사기는 최상위 이름만 본다. `SoriSurfaces.of(ctx).card` 처럼
# **없는 멤버**는 잡지 못했다 — 실제로 그 버그가 났다. 토큰 클래스의
# 멤버는 종류가 적고 자주 쓰이므로 여기서 따로 대조한다.
CLASSES = ('SoriColors', 'SoriSurfaces', 'Spacing', 'SoriRadius', 'SoriShadow')

def members_of(code, name):
    m = re.search(r'^class %s\b' % name, code, re.M)
    if not m: return None
    i = code.index('{', m.start())
    depth, j = 0, i
    while j < len(code):
        if code[j] == '{': depth += 1
        elif code[j] == '}':
            depth -= 1
            if depth == 0: break
        j += 1
    body = code[i:j]
    out = set()
    out |= set(re.findall(r'\b(?:static\s+)?(?:const|final)\s+[\w<>\?\.]+\s+(\w+)\s*[=;]', body))
    out |= set(re.findall(r'^\s*static\s+const\s+(\w+)\s*=', body, re.M))
    out |= set(re.findall(r'^\s*static\s+\w[\w<>\?\.]*\s+(\w+)\s*[\(=]', body, re.M))
    out |= set(re.findall(r'^\s*(?:static\s+)?[\w<>\?\.]+\s+get\s+(\w+)', body, re.M))
    return out

tokens = strip(io.open(os.path.join(ROOT, 'lib/widgets/sori/tokens.dart'),
                       encoding='utf-8').read())
TABLE = {}
for c in CLASSES:
    m = members_of(tokens, c)
    if m is not None:
        TABLE[c] = m

bad = []
for rel in TARGETS:
    code = strip(io.open(os.path.join(ROOT, rel), encoding='utf-8').read())
    for c, allowed in TABLE.items():
        # 직접 접근: SoriColors.primary / Spacing.md
        for mem in re.findall(r'\b%s\.(\w+)' % c, code):
            if mem.startswith('_') or mem in ('of','light','dark') or mem in allowed: continue
            bad.append('%s: `%s.%s` 없음' % (rel, c, mem))
        # of(ctx) 를 거친 접근: SoriSurfaces.of(ctx).card
        for mem in re.findall(r'\b%s\.of\([^)]*\)\.(\w+)' % c, code):
            if mem in allowed: continue
            bad.append('%s: `%s.of(...).%s` 없음' % (rel, c, mem))

if bad:
    print('멤버 문제 %d건:' % len(bad))
    for b in sorted(set(bad)): print('  - ' + b)
    sys.exit(1)
print('멤버 OK — %s 대조 (%d 파일)' % ('/'.join(TABLE), len(TARGETS)))
