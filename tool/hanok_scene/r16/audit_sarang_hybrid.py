"""Read-only verification of the user's hybrid-material proposal on Sarangchae."""
import bpy, bmesh, sys, hashlib, json
from pathlib import Path
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
import produce as p
dest=OUT/'sarang'
v=p.read(dest/'verification.json');native=dest/v['native']
assert p.sha(native)==v['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(native))
scene=bpy.context.scene;lock=p.read(dest/'geometry-lock.json')
obs=[scene.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry']
mapping=p.stage_map('sarang',obs)
assert mapping==p.read(dest/'construction-binding.json')
rows=p.read(dest/'material-inventory.json')
tile_names=sorted({r['object'] for r in rows if r['role']=='tile'})
cap_names=sorted({r['object'] for r in rows if r['role']=='tile-end'})
material_report=[];seen=set()
for ob in obs:
 for sl in ob.material_slots:
  m=sl.material
  if not m or m.name in seen or not m.node_tree:continue
  seen.add(m.name);active=p.live(m.node_tree)
  hybrid=[]
  for node in active:
   if node.type!='TEX_WHITE_NOISE':continue
   ancestors=set();todo=[node]
   while todo:
    n=todo.pop()
    if n in ancestors:continue
    ancestors.add(n);todo.extend(l.from_node for sock in n.inputs for l in sock.links)
   has_object=any(n.type=='OBJECT_INFO' and any(l.to_node in ancestors for l in n.outputs['Random'].links) for n in ancestors)
   has_island=any(n.type=='NEW_GEOMETRY' and any(l.to_node in ancestors for l in n.outputs['Random Per Island'].links) for n in ancestors)
   if has_object and has_island:hybrid.append(node.label or node.name)
  material_report.append(dict(name=m.name,role=m.get('hs2_role'),activeHybridRandom=hybrid,
   originalMemberAttributes=sorted({n.attribute_name for n in active if n.type=='ATTRIBUTE'}),
   worldPositionLinked=any(n.type=='NEW_GEOMETRY' and any(l.to_node in active for l in n.outputs['Position'].links) for n in active)))
tile_report=[]
for name in tile_names+cap_names:
 ob=scene.objects[name];bm=bmesh.new();bm.from_mesh(ob.data);bm.faces.ensure_lookup_table();bm.faces.index_update()
 visited=set();sizes=[];predicted=[];rot=ob.matrix_world.to_3x3().normalized()
 for f in bm.faces:
  if f.index in visited:continue
  queue=[f];visited.add(f.index);size=0
  while queue:
   cur=queue.pop();size+=1
   for edge in cur.edges:
    for nxt in edge.link_faces:
     if nxt.index not in visited:visited.add(nxt.index);queue.append(nxt)
  sizes.append(size)
 for f in bm.faces:
  normal=rot@f.normal
  if abs(normal.z)<.28 and f.calc_area()<.015:
   sharp=sum(not e.is_manifold or e.calc_face_angle(0.0)>.7 for e in f.edges)
   if sharp>=len(f.edges)*.5:predicted.append(f.index)
 tile_report.append(dict(object=name,islands=len(sizes),faces=len(bm.faces),isExistingEndObject=name in cap_names,
  proposedHeuristicFaceCount=len(predicted),proposedFaceIndicesSha256=hashlib.sha256(json.dumps(predicted).encode()).hexdigest()))
 bm.free()
assert p.architecture(obs)==v['geometry']
assert p.sha(native)==v['nativeSha256']
report=dict(building='sarang',native=v['native'],nativeSha256=v['nativeSha256'],readOnly=True,geometryVerified=True,
 architectureMeshes=len(obs),displayGroundMeshes=sum(o.type=='MESH' and o.get('displayOnly',False) for o in scene.objects),
 processBindings=len(mapping),tileBodyObjects=len(tile_names),existingEndObjects=len(cap_names),
 materialsWithHybridRandom=sum(bool(m['activeHybridRandom']) for m in material_report),
 heuristicIsNotSemanticClassification=True,materials=material_report,tileObjects=tile_report)
p.write(dest/'hybrid-audit.json',report)
print(json.dumps({k:v for k,v in report.items() if k not in ('materials','tileObjects')},ensure_ascii=False),flush=True)
print(json.dumps(tile_report,ensure_ascii=False),flush=True)
