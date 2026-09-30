from pathlib import Path
import bpy,json,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'))
s=bpy.context.scene
report=json.loads((OUT/'geometry-validation.json').read_text(encoding='utf8'))
checks=[]
for spec in report['frontSupports']:
    prefix='HwaljuFix.'+spec['id']
    timber=bpy.data.objects[prefix+' timber'];foot=bpy.data.objects[prefix+' stone foot']
    woodlo=min(v.co.z for v in timber.data.vertices);woodhi=max(v.co.z for v in timber.data.vertices)
    footlo=min(v.co.z for v in foot.data.vertices);foothi=max(v.co.z for v in foot.data.vertices)
    checks.append({'id':spec['id'],'check':'timber bottom meets stone top','gapMetres':woodlo-foothi,'pass':abs(woodlo-foothi)<.001})
    checks.append({'id':spec['id'],'check':'upper end enters roof bearing by <=15mm','overlapMetres':woodhi-spec['bearingZ'],'pass':0<=woodhi-spec['bearingZ']<=.015})
    x,y=spec['x'],spec['y'];supports=[]
    for ob in s.objects:
        if ob.type!='MESH' or ob==foot or 'timber' in ob.name or 'pale sleeve' in ob.name:continue
        inv=ob.matrix_world.inverted();start=inv@Vector((x,y,footlo+.001));direction=inv.to_3x3()@Vector((0,0,-1))
        hit,p,n,face=ob.ray_cast(start,direction)
        if hit:
            z=(ob.matrix_world@p).z
            if z<=footlo+.0001:supports.append((z,ob.name))
    z,name=max(supports)
    checks.append({'id':spec['id'],'check':'foot rests on terrace or ground','support':name,'gapMetres':footlo-z,'pass':abs(footlo-z)<.001})
    # Center read from geometry, not merely the specification.
    xs=[v.co.x for v in foot.data.vertices];ys=[v.co.y for v in foot.data.vertices]
    actual=((min(xs)+max(xs))/2,(min(ys)+max(ys))/2)
    checks.append({'id':spec['id'],'check':'plan center delivered','actualXY':actual,'planXY':[x,y],'pass':max(abs(actual[0]-x),abs(actual[1]-y))<.001})
result={'sceneSha256':hashlib.sha256((OUT/'scene.blend').read_bytes()).hexdigest(),'checks':checks,'allPass':all(c['pass'] for c in checks),'scope':'Front supports only; source scan coordinates are observations with approx40mm uncertainty, not survey dimensions.'}
(OUT/'contact-validation.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result));assert result['allPass']
