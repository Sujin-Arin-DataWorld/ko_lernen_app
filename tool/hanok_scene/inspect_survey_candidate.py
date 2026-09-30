"""Read-only dimensional inspection of the survey candidate."""
import bpy, json, sys
from pathlib import Path
import numpy as np
from mathutils import Matrix, Vector
sys.path.insert(0, str(Path(__file__).parent))
from northern_timber_sections import groups
OUT = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(OUT / 'spatial-detail-study.blend'))
c = json.loads((OUT / 'spatial-detail-contract.json').read_text(encoding='utf8'))
gate = c['rearYardGate']; inv = Matrix.Rotation(-gate['angle'], 3, 'Z'); origin = Vector((*gate['center'], 1.5))
data = {'gate': {}, 'flowerMeshes': [], 'kitchen': {}}
an=next(r for r in c['buildings'] if r['id']=='anchae');ar=Matrix.Rotation(an['angle'],3,'Z');ao=Vector((*an['center'],an['datum']));ai=ar.inverted()
for o in bpy.context.scene.objects:
    if o.type != 'MESH': continue
    if o.name.startswith('North.site.rear yard gate'):
        p = np.array([inv @ (o.matrix_world @ v.co-origin) for v in o.data.vertices])
        data['gate'][o.name] = {'min': p.min(0).tolist(), 'max': p.max(0).tolist(), 'parts': len(groups(o.data))}
    if 'inset petal' in o.name:
        data['flowerMeshes'].append({'name': o.name, 'polygons': len(o.data.polygons)})
    if 'photo kitchen stove' in o.name or o.name.startswith('North.anchae.kitchen.leaf'):
        data['kitchen'][o.name] = {'materials': [m.name for m in o.data.materials]}
    if 'kitchen high ventilator' in o.name or o.name.startswith('North.anchae.kitchen front'):
        p=np.array([ai@(o.matrix_world@v.co-ao) for v in o.data.vertices])
        data['kitchen'][o.name]={'min':p.min(0).tolist(),'max':p.max(0).tolist(),'hidden':o.hide_render}
data['kitchenRays']=[]
cx=-an['bodyWidth']/2+an['bays'][0]+an['bays'][1]/2
dep=bpy.context.evaluated_depsgraph_get()
for z in (2.45,2.55,2.65,2.75,2.85):
    start=ao+ar@Vector((cx,-3,z));hit,point,_,_,ob,_=bpy.context.scene.ray_cast(dep,start,ar@Vector((0,1,0)),distance=1)
    data['kitchenRays'].append({'z':z,'object':ob.name if hit else None,'local':list(ai@(point-ao)) if hit else None})
(OUT / 'survey-inspection.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf8')
print('SURVEY INSPECTION SAVED', flush=True)
