"""Reuse unmodified canonical pixels on closed, measured mesh members.

Semantic region assignments are explicit. No whole-image facade projection,
generated replacement grain, geometry inflation or alteration of approved art.
"""
from pathlib import Path
import bpy, numpy as np, ast, random, hashlib, json
from northern_courtyard_photo_repair import OUT
from refine_northern_materials import geometry_fingerprint

sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for node in ast.parse((Path(__file__).parent/'refine_canonical_gates.py').read_text(encoding='utf8')).body:
 if isinstance(node,ast.FunctionDef) and node.name in ('new_material','pigment','components','art_uv'):
  code=ast.unparse(node).replace("('beam', 'stone', 'tile')", "('beam', 'stone', 'tile', 'floor', 'decoration')")
  exec(compile(code,'canonical UV helper','exec'))

MAP={
 'gate':{'path':OUT.parent/'side-connections/canonical-gate.png','regions':{
  'post':[(.244,.328,.275,.67)],'wood':[(.334,.405,.351,.618),(.389,.406,.405,.619),(.568,.406,.583,.617)],
  'beam':[(.312,.334,.700,.350)],'floor':[(.31,.698,.65,.709)],
  'tile':[(.477,.176,.481,.188)],'stone':[(.396,.789,.449,.807)]}},
 'anchae':{'path':OUT/'references/anchae/canonical.png','regions':{
  'post':[(.4295,.437,.433,.570)],'wood':[(.242,.477,.255,.59)],'beam':[(.352,.610,.413,.621)],
  'floor':[(.59,.606,.67,.613)],'tile':[(.399,.246,.402,.265)],'stone':[(.255,.705,.29,.736)]}},
 'ansarang':{'path':OUT.parent/'side-connections/ansarang-canonical.png','regions':{
  'post':[(.393,.492,.407,.718)],'wood':[(.394,.493,.405,.688)],'beam':[(.239,.688,.371,.700)],
  'floor':[(.468,.697,.53,.713)],'tile':[(.518,.210,.527,.224)],'stone':[(.279,.781,.314,.803)]}},
 'sadang':{'path':OUT/'references/sadang/canonical.png','regions':{
  'post':[(.500,.57,.513,.75)],'wood':[(.250,.793,.280,.800)],'floor':[(.250,.793,.280,.800)],
  'beam':[(.57,.397,.63,.414)],'decoration':[(.371,.461,.465,.482)],
  'tile':[(.462,.255,.468,.269)],'stone':[(.305,.882,.331,.916)]}},
 'sadangmun':{'path':OUT/'references/sadangmun/canonical.png','regions':{
  'post':[(.205,.445,.23,.735)],'wood':[(.285,.45,.31,.70)],'beam':[(.31,.412,.58,.425)],
  'tile':[(.487,.258,.504,.271)],'stone':[(.25,.81,.35,.835)]}},
}

def apply(scene):
 global ART,base_image,materials,regions,mapped
 mapped=[];manifest=[]
 for ident,src in MAP.items():
  ART=src['path'];base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};regions=src['regions']
  manifest.append({'building':ident,'source':str(ART),'sha256':sha(ART),'sourceEdited':False,'regionsNormalizedXY':regions})
  for ob in scene.objects:
   if ob.type!='MESH':continue
   bid=ob.get('construction_building');name=ob.name.lower()
   if ident=='gate':
    if not(name.startswith('north.site.rear yard gate') or bid in ('left_changgo','right_ansarang')):continue
   elif bid!=ident:continue
   mesh=ob.data;original=list(mesh.materials);assignments=[p.material_index for p in mesh.polygons]
   def classify(mat):
    if mat is None:return None
    label=mat.name.lower();k=mat.get('surfaceKind','')
    if any(t in label for t in ('stone','granite')):return 'stone'
    if any(t in label for t in ('source ceramic','illustrated clay')):return 'tile'
    if k=='illustrated_paint_red' or 'vermilion' in label:return 'post'
    if k in ('wood','post','beam','floor','illustrated_longgrain','illustrated_endgrain') or any(t in label for t in ('walnut','plank','lining timber')):
     return 'post' if any(t in name for t in ('column','post')) else 'floor' if any(t in name for t in ('floor','maru','porch boards','under joists','janggwiteul','donggwiteul','binding')) else 'beam' if any(t in name for t in ('beam','head sill','lintel','purlin','head stop','back rail','yeonham')) else 'wood'
    return None
   selected={i:classify(original[i]) for i in set(assignments)}
   selected={i:(k if k in regions else 'wood') for i,k in selected.items() if k}
   if not selected:continue
   before=geometry_fingerprint(ob);saved_uv={};new_mats={}
   colors=[(a.name,a.data_type,a.domain,[tuple(v.color) for v in a.data]) for a in mesh.color_attributes]
   for kind in sorted(set(selected.values())):
    art_uv(ob,kind);mat=mesh.materials[0];mat.name='Reference '+ident+' '+kind;new_mats[kind]=mat
    bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.90 if kind=='tile' else .88
    if kind=='tile':bs.inputs['Specular IOR Level'].default_value=.12
    uv=mesh.uv_layers.get('Canonical gate pigment')
    for p,original_index in zip(mesh.polygons,assignments):
     if selected.get(original_index)!=kind:continue
     for li in p.loop_indices:
      u,v=uv.data[li].uv
      if kind=='tile':
       x0,y0,x1,y1=regions['tile'][0];u=(x0+x1)/2+(u-(x0+x1)/2)*.045;v=1-(y0+y1)/2+(v-(1-(y0+y1)/2))*.045
      saved_uv[li]=(u,v)
   mesh.materials.clear()
   for mat in original:mesh.materials.append(mat)
   remap={}
   for kind,mat in new_mats.items():remap[kind]=len(mesh.materials);mesh.materials.append(mat)
   for p,idx in zip(mesh.polygons,assignments):p.material_index=remap[selected[idx]] if idx in selected else idx
   uv=mesh.uv_layers.get('Canonical gate pigment')
   for li,co in saved_uv.items():uv.data[li].uv=co
   # Mixed meshes retain their plaster underside, iron and original paint.
   for name_,type_,domain_,values in colors:
    attr=mesh.color_attributes.new(name=name_,type=type_,domain=domain_)
    for v,color in zip(attr.data,values):v.color=color
   ob['canonicalSurfaceSource']=str(ART);ob['canonicalSurfaceKind']=','.join(new_mats)
   assert before==geometry_fingerprint(ob)
 for rec in manifest:assert sha(Path(rec['source']))==rec['sha256']
 result={'method':'Semantic artwork-region UVs on volumetric members; originals byte-preserved','sources':manifest,'mapped':mapped,'coverage':'All faces of each mapped component, including returns and ends','generatedSubstituteAlbedo':False}
 (OUT/'atlas-part-map.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
 return result
