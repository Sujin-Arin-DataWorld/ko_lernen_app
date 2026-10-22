import bpy,json
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(out.parent/'lookdev-sarang-r1/sarang-lookdev-candidate.blend'))
rows=[]
for ob in bpy.context.scene.objects:
    if ob.type!='MESH':continue
    bb=[ob.matrix_world@Vector(v) for v in ob.bound_box]
    attrs={}
    for key in ['P18 real cut face','P18 image eligible']:
        a=ob.data.attributes.get(key)
        if a:attrs[key]=dict(min=min(v.value for v in a.data),max=max(v.value for v in a.data))
    rows.append(dict(name=ob.name,center=list(sum(bb,Vector())/8),uvs=[v.name for v in ob.data.uv_layers],
        materials=[s.material.name if s.material else None for s in ob.material_slots],attributes=attrs,
        polygons=len(ob.data.polygons),vertices=len(ob.data.vertices)))
(out/'detail-object-audit.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
for r in rows:
    if any(k in r['name'].lower() for k in ['hinge','iron','hardware','latch','pintle','rafter','purlin','original patterned']):print(json.dumps(r,ensure_ascii=False))
for im in bpy.data.images:
    if im.source=='FILE' and 'endgrain' in im.name and im.packed_file:
        (out/'textures'/('source-'+im.name.replace('.png','')+'.png')).write_bytes(im.packed_file.data)
        print('ENDGRAIN IMAGE',im.name,list(im.size))
ob=bpy.data.objects['Craft.Sarang.numaru roof.lower exposed rafters.end grain']
print('CUT UV EXAMPLE',[list(v.uv) for v in ob.data.uv_layers[0].data[:12]])
mat=ob.material_slots[0].material
for n in mat.node_tree.nodes:
    print('CUT NODE',n.name,n.bl_idname, n.image.name if n.type=='TEX_IMAGE' and n.image else '',n.uv_map if n.type=='UVMAP' else '')
