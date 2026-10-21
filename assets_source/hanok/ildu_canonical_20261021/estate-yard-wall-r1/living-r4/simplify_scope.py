"""Decompose the existing finite footprint; internal edges never feather."""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent
path = OUT/'ground-scope.json'
data = json.loads(path.read_text(encoding='utf-8'))
scope = next(d for d in data['zones'] if d['type']=='scope')
outer = [tuple(p) for p in data.get('original_scope_polygon',scope['polygon'])]


def cross(a,b,c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def area(poly):
    return sum(a[0]*b[1]-a[1]*b[0] for a,b in zip(poly,poly[1:]+poly[:1]))/2


def hull(points):
    points = sorted(set(points))
    lower,upper = [],[]
    for chain, seq in ((lower,points),(upper,list(reversed(points)))):
        for p in seq:
            while len(chain)>=2 and cross(chain[-2],chain[-1],p)<=1e-8:
                chain.pop()
            chain.append(p)
    return lower[:-1]+upper[:-1]


if area(outer)<0:
    outer.reverse()
remaining = list(outer)
pieces = []
while len(remaining)>3:
    for i,b in enumerate(remaining):
        a,c = remaining[i-1],remaining[(i+1)%len(remaining)]
        if cross(a,b,c)<=1e-8:
            continue
        if any(all(cross(x,y,p)>=-1e-8 for x,y in ((a,b),(b,c),(c,a)))
               for p in remaining if p not in (a,b,c)):
            continue
        pieces.append([a,b,c])
        remaining.pop(i)
        break
    else:
        raise ValueError('Scope cannot be triangulated')
pieces.append(remaining)
merged = True
while merged:
    merged = False
    for i in range(len(pieces)):
        for j in range(i+1,len(pieces)):
            if len(set(pieces[i])&set(pieces[j]))<2:
                continue
            candidate = hull(pieces[i]+pieces[j])
            if abs(area(candidate)-area(pieces[i])-area(pieces[j]))<1e-7:
                pieces[i]=candidate
                pieces.pop(j)
                merged=True
                break
        if merged:
            break
assert abs(sum(area(p) for p in pieces)-area(outer))<1e-7
outer_edges = list(zip(outer,outer[1:]+outer[:1]))
new = []
for i,piece in enumerate(pieces):
    internal = [k for k,(a,b) in enumerate(zip(piece,piece[1:]+piece[:1]))
                if not any(abs(cross(u,v,a))<1e-7 and abs(cross(u,v,b))<1e-7
                           for u,v in outer_edges)]
    new.append(dict(name='interior piece '+str(i),type='scope',polygon=piece,
                    feather=scope['feather'],hard_edges=internal))
for definition in data['zones']:
    if definition['type']=='scope':
        continue
    # Semantic regions are blended statistics, so their convex hull is suitable.
    definition['polygon']=hull([tuple(p) for p in definition['polygon']])
    new.append(definition)
data['original_scope_polygon']=outer
data['scope_decomposition']={'area_equal':True,'piece_count':len(pieces),
    'internal_edges':'hard inclusion, no feather; union has no diagonal seams'}
data['zones']=new
path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print('Scope area preserved:',round(area(outer),3),'m2;',len(pieces),'convex pieces')
