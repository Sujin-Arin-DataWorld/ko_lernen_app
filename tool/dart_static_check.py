"""Dart 구조 검사 — 괄호 균형 · 지시자(library/import) 순서.

`flutter analyze` 를 돌릴 수 없는 환경(원격 컨테이너 등)에서 최소한의 방어선.
분석기 대체가 아니라 **눈으로 못 잡는 구조 오류**만 잡는다.

    python3 tool/dart_static_check.py . $(find lib test -name '*.dart')
"""
import io, re, sys

def strip(src):
    """문자열·주석을 공백으로 치환해 괄호 균형만 남긴다."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        two = src[i:i+2]
        if two == '//':
            j = src.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i)); i = j; continue
        if two == '/*':
            depth, j = 1, i + 2
            while j < n and depth:
                if src[j:j+2] == '/*': depth += 1; j += 2; continue
                if src[j:j+2] == '*/': depth -= 1; j += 2; continue
                j += 1
            out.append(re.sub(r'[^\n]', ' ', src[i:j])); i = j; continue
        if c in '"\'':
            raw = i > 0 and src[i-1] == 'r'
            trip = src[i:i+3] in ('"""', "'''")
            q = src[i:i+3] if trip else c
            j = i + len(q)
            while j < n:
                if not raw and src[j] == '\\': j += 2; continue
                if src[j:j+len(q)] == q: j += len(q); break
                j += 1
            out.append(re.sub(r'[^\n]', ' ', src[i:j])); i = j; continue
        out.append(c); i += 1
    return ''.join(out)

PAIRS = {')': '(', ']': '[', '}': '{'}

def balance(path, code):
    st, errs = [], []
    line = 1
    for ch in code:
        if ch == '\n': line += 1
        elif ch in '([{': st.append((ch, line))
        elif ch in ')]}':
            if not st or st[-1][0] != PAIRS[ch]:
                errs.append('%s:%d 닫는 %s 가 짝이 없음' % (path, line, ch))
                return errs
            st.pop()
    for ch, ln in st:
        errs.append('%s:%d 열린 %s 가 안 닫힘' % (path, ln, ch))
    return errs

KW = re.compile(r'^(library|import|export|part)\b')

def directives(path, code):
    """`library;` → import → 코드 순서. 문자열은 이미 공백으로 지워져 있으므로
    `import '...'` 는 `import` 만 남는다 — 접두사 비교 대신 토큰으로 본다."""
    errs, seen_import, seen_code, pending = [], False, False, False
    for i, raw in enumerate(code.split('\n'), 1):
        t = raw.strip()
        if not t: continue
        if pending:                      # 여러 줄 지시자의 이어지는 줄
            pending = not t.endswith(';')
            continue
        m = KW.match(t)
        kw = m.group(1) if m else None
        if kw in ('import', 'export', 'part'):
            pending = not t.endswith(';')
        if kw == 'library':
            if seen_import or seen_code:
                errs.append('%s:%d `library;` 는 import 보다 앞이어야 한다' % (path, i))
        elif kw in ('import', 'export'):
            seen_import = True
            if seen_code:
                errs.append('%s:%d import 가 코드 뒤에 있다' % (path, i))
        elif kw == 'part':
            seen_import = True
        else:
            seen_code = True
    return errs

TOP = re.compile(
    r'^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+|mixin\s+)*'
    r'(?:class|enum|extension|typedef|mixin)\s+(\w+)', re.M)
TOPVAR = re.compile(r'^(?:const|final)\s+[\w<>,\s\?]*?(\w+)\s*=', re.M)
TOPFN = re.compile(r'^(?:[\w<>,\s\?\.]+?)\s(\w+)\s*\(', re.M)

def declared(code):
    names = set(TOP.findall(code))
    names |= set(TOPVAR.findall(code))
    names |= set(TOPFN.findall(code))
    return names

def main(argv):
    root = argv[1]
    targets = argv[2:]
    problems = []
    for rel in targets:
        src = io.open(root + '/' + rel, encoding='utf-8').read()
        code = strip(src)
        problems += balance(rel, code)
        problems += directives(rel, code)
    if problems:
        print('구조 문제:')
        for p in problems: print('  - ' + p)
        return 1
    print('구조 OK — 괄호 균형 · 지시자 순서 이상 없음 (%d 파일)' % len(targets))
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))
