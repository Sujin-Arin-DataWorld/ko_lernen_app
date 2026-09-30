"""Correct the three front hwalju positions against sheets 004/005/007/028.

The drawn plan positions are scaled observations, not printed dimensions.
Preserve V26 and its connected Jungmunganchae; write a separate review candidate.
"""
from pathlib import Path
import bpy, bmesh, json, hashlib, math, sys, numpy as np
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
SOURCE=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922/pair-construction-v26')
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
OUT.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'scene.blend'))
s=bpy.context.scene
old=[o for o in s.objects if 'hwalju' in o.name.lower()]

def fingerprint(o):
    h=hashlib.sha256()
    for v in o.data.vertices:h.update(np.asarray(v.co,dtype=np.float32).tobytes())
    for p in o.data.polygons:h.update(np.asarray(p.vertices,dtype=np.int32).tobytes())
    h.update(str([list(r) for r in o.matrix_world]).encode())
    h.update(str(sorted((k,str(o[k])) for k in o.keys())).encode())
    return h.hexdigest()

protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH' and o not in old}
stem=bpy.data.objects['Craft.hwalju continuous timber 15.04']
sleeve=bpy.data.objects['Craft.hwalju pale base sleeve']
foot=bpy.data.objects['Sarang.hwalju stone foot']
added=[]
def meta(o,role):
    o['construction_building']='sarang'
    o['construction_role']=role
    o['construction_first']=5 if role=='posts' else 3
    o['construction_last']=99
    o['source_object_name']=o.name
    o['evidence']='Front hwalju: scaled plan004, front005, side007, detail028; base profile and bearing adjustment interpreted'
    added.append(o)
    return o

def copy_part(template,name):
    ob=template.copy();ob.data=template.data.copy();ob.name=name;s.collection.objects.link(ob)
    # The old sleeves and feet each batch two supports. Copy the right member.
    if template!=stem:
        bm=bmesh.new();bm.from_mesh(ob.data)
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.x<5],context='VERTS')
        bm.to_mesh(ob.data);bm.free()
    return ob

def underside(x,y):
    hits=[]
    for ob in s.objects:
        if ob.type!='MESH' or ob.hide_render or ('roof underside boarding' not in ob.name and 'exposed rafters' not in ob.name):continue
        hit,p,n,face=ob.ray_cast(Vector((x,y,3.7)),Vector((0,0,1)))
        if hit:hits.append((p.z,ob.name))
    assert hits,(x,y)
    return min(hits)

def box(name,bounds,material,role='choseok'):
    x0,x1,y0,y1,z0,z1=bounds
    bpy.ops.mesh.primitive_cube_add(size=1,location=((x0+x1)/2,(y0+y1)/2,(z0+z1)/2))
    ob=bpy.context.object;ob.name=name;ob.dimensions=(x1-x0,y1-y0,z1-z0)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(material)
    bevel=ob.modifiers.new('Stone arris','BEVEL');bevel.width=.014;bevel.segments=2
    meta(ob,role)
    return ob

stone=bpy.data.materials['Pale granite 3']
# Missing local portions of the terrace shown in004. Connect the moved feet to
# existing masonry. This does not rebuild the entire V26 foundation footprint.
for label,x0,x1,y0,y1,top,rows in [
    ('left terrace',-1.31,-.61,-1.28,.30,1.10,3),
    ('left front apron',-.61,1.81,-1.28,-.69,1.10,3),
    ('numaru inner apron',9.34,10.32,-5.16,-4.18,.43,1),
    ('numaru front apron',10.32,14.76,-5.16,-4.51,.43,1),
]:
    along_x=x1-x0>y1-y0
    count=max(1,round(max(x1-x0,y1-y0)/.85))
    for row in range(rows):
        for col in range(count):
            a=(x0 if along_x else y0)+max(x1-x0,y1-y0)*col/count
            b=(x0 if along_x else y0)+max(x1-x0,y1-y0)*(col+1)/count
            bounds=(a+.003,b-.003,y0,y1) if along_x else (x0,x1,a+.003,b-.003)
            box(f'HwaljuFix.{label} masonry {row}-{col}',(*bounds,top*row/rows,top*(row+1)/rows),stone)

specs=[
    {'id':'02-main-left','drawingNo':2,'x':-.91,'y':-.90,'base':1.10,'comment':2},
    {'id':'03-numaru-inner','drawingNo':3,'x':9.68,'y':-4.90,'base':.43,'comment':1},
    {'id':'04-numaru-outer','drawingNo':4,'x':15.76,'y':-5.205,'base':0.0,'comment':1},
]
for spec in specs:
    x,y,base=spec['x'],spec['y'],spec['base'];bearing,object_name=underside(x,y)
    bottom=base+.14
    for template,kind,z0,z1 in [(stem,'timber',bottom,bearing+.008),(sleeve,'pale sleeve',bottom,bottom+1.12),(foot,'stone foot',base,base+.14)]:
        ob=copy_part(template,'HwaljuFix.'+spec['id']+' '+kind)
        points=ob.data.vertices;oldlo=min(v.co.z for v in points);oldhi=max(v.co.z for v in points)
        for v in points:
            v.co.x += x-15.04;v.co.y += y+4.48
            v.co.z=z0+(v.co.z-oldlo)/(oldhi-oldlo)*(z1-z0)
        # Keep the existing near-100 mm timber profile and pale sleeve finish.
        ob.data.update();meta(ob,'posts' if kind!='stone foot' else 'choseok')
    spec.update({'bearingZ':bearing,'bearingObject':object_name,'bottomZ':bottom})
for ob in old:bpy.data.objects.remove(ob,do_unlink=True)
assert all(fingerprint(bpy.data.objects[n])==h for n,h in protected.items())
s['front_hwalju_authority']='004/005/007/028, over painted canonical two-post simplification'
s['front_hwalju_limits']='XY read to approximately 40mm from scan; local terrace infill and current roof bearing heights are reconstruction details. Rear No1 outside this front-marker correction.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)

# Export only the changed parts with the existing V26 baked maps. The unchanged
# building stays byte-identical in its original GLB buffer in merge_hwalju_glb.py.
mapping=json.loads((SOURCE/'realtime-delivery.json').read_text())['materialMapping']
material_indices={name:i for i,name in enumerate(mapping)}
used={m.name:m for o in added for m in o.data.materials}
for name,mat in used.items():
    assert name in mapping,name
    n=mat.node_tree.nodes;l=mat.node_tree.links
    p=next(v for v in n if v.type=='BSDF_PRINCIPLED');specular=p.inputs['Specular IOR Level'].default_value
    n.clear();bs=n.new('ShaderNodeBsdfPrincipled');output=n.new('ShaderNodeOutputMaterial');l.new(bs.outputs[0],output.inputs[0]);bs.inputs['Specular IOR Level'].default_value=specular
    uv=n.new('ShaderNodeUVMap');uv.uv_map='V26 realtime'
    for channel in ('color','normal','roughness'):
        path=SOURCE/'textures'/f'{material_indices[name]:02d}-{channel}.png'
        tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True)
        if channel!='color':tex.image.colorspace_settings.name='Non-Color'
        l.new(uv.outputs[0],tex.inputs[0])
        if channel=='normal':
            normal=n.new('ShaderNodeNormalMap');l.new(tex.outputs['Color'],normal.inputs['Color']);l.new(normal.outputs[0],bs.inputs['Normal'])
        else:l.new(tex.outputs['Color'],bs.inputs['Base Color' if channel=='color' else 'Roughness'])
for o in s.objects:o.select_set(False)
for o in added:
    mesh=o.data;family=mesh.materials[0].name;span=mapping[family]['textureSpanMetres']
    layer=mesh.uv_layers.get('V26 realtime') or mesh.uv_layers.new(name='V26 realtime')
    ref=mesh.uv_layers.get('Reference timber grain')
    for poly in mesh.polygons:
        axes=[i for i in range(3) if i!=max(range(3),key=lambda k:abs(poly.normal[k]))]
        for li in poly.loop_indices:
            if ref:layer.data[li].uv=(ref.data[li].uv.x/span[0],ref.data[li].uv.y/span[1])
            else:
                co=mesh.vertices[mesh.loops[li].vertex_index].co
                layer.data[li].uv=(co[axes[0]]/span[0],co[axes[1]]/span[1])
    mesh.uv_layers.active=layer;layer.active_render=True
    o.hide_render=False;o.hide_set(False);o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'corrected-parts.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report={'sourceSceneSha256':sha(SOURCE/'scene.blend'),'sceneSha256':sha(OUT/'scene.blend'),'frontSupports':specs,'removedObjects':["Craft.hwalju continuous timber 15.04","Craft.hwalju continuous timber -0.79","Craft.hwalju pale base sleeve","Sarang.hwalju stone foot"],'addedObjects':[o.name for o in added],'protectedMeshes':len(protected),'protectedMeshFingerprintsUnchanged':True,'authority':['004 floor plan','005 front elevation','007 right elevation','028 hwalju detail key plan'],'limits':[s['front_hwalju_limits'],'No new material art direction applied in this geometric correction.']}
(OUT/'geometry-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('HWALJU CORRECTION SAVED',json.dumps(specs),flush=True)
