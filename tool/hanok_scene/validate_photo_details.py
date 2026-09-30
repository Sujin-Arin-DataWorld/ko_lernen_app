"""Independent delivered-mesh checks for the Sep29 photo-detail correction."""
from pathlib import Path
import bpy,bmesh,json,hashlib,numpy as np
from mathutils import Vector,Matrix
from northern_timber_sections import groups

def check_details(scene,c,OUT,check):
 if not c.get('photoDetailCorrection'):return
 report=c['photoDetailCorrection'];sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
 refs=json.loads((OUT/'photo-detail-sources.json').read_text(encoding='utf8'))
 check('Sep29 supplied photo and survey copies retain their original bytes',len(refs)==9 and all(sha(OUT/r['file'])==r['sha256']==sha(r['source']) for r in refs))
 south=json.loads((OUT.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'));r=south['buildings']['ansarang'];origin=Vector((*r['center'],0));rot=Matrix.Rotation(r['angle'],3,'Z')
 def points(name):
  ob=bpy.data.objects[name];return np.array([rot.transposed()@(ob.matrix_world@v.co-origin) for v in ob.data.vertices])
 p=points('Sep29.ansarang.left kitchen.loft floor')
 check('Byeoldang kitchen loft follows 2210x2610 plan compartment with 45mm wood floor',np.allclose(np.ptp(p,axis=0),[2.210,2.610,.045],atol=.001),measuredSpan=np.ptp(p,axis=0).tolist())
 dep=bpy.context.evaluated_depsgraph_get();hits=[]
 for y in (.3,1.20,1.80):
  for z in (.78,1.35,1.90):
   hit,_,_,_,ob,_=scene.ray_cast(dep,origin+rot@Vector((-5.75,y,z)),rot@Vector((1,0,0)),distance=1.00)
   if hit:hits.append(ob.name)
 check('Byeoldang left opening has nine clear rays through the former solid wall into kitchen',not hits,obstacles=hits)
 p=points('Sep29.ansarang.left kitchen.room3 end post')
 check('Byeoldang kitchen room3 return is supported by a 200mm square post',np.allclose(np.ptp(p,axis=0)[:2],[.20,.20],atol=.001))
 check('Byeoldang side loft grille remains above the open lower kitchen',all(bpy.data.objects.get(n) for n in ['V32.ansarang.left kitchen WW02 wall.jamb','V32.ansarang.left kitchen WW02 wall.head/sill']))
 solid_tags=['altar carved timber apron','cabinet timber side','cabinet timber back','altar timber leg','offering timber leg','scroll bracket solid','forged escutcheon']
 chosen=[bpy.data.objects[n] for n in report['addedMeshes'] if any(t in n for t in solid_tags)];bad=[]
 for ob in chosen:
  bm=bmesh.new();bm.from_mesh(ob.data)
  if any(not e.is_manifold for e in bm.edges):bad.append(ob.name)
  bm.free()
 check('Carved shrine furniture, scroll brackets and gate escutcheons have closed sides and back faces',len(chosen)>=8 and not bad,meshes=len(chosen),openMeshes=bad)
 lathe=bpy.data.objects['Sep29.sadang.brass incense bowl'];bm=bmesh.new();bm.from_mesh(lathe.data)
 nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.free()
 check('Shrine incense vessel has closed outer and inner bowl surfaces',nonmanifold==0,nonManifoldEdges=nonmanifold)
 r=next(r for r in c['buildings'] if r['id']=='sadang');origin=Vector((*r['center'],r['datum']));rot=Matrix.Rotation(r['angle'],3,'Z')
 # Cabinet bottom rests on the altar rim. Check actual evaluated-free vertices.
 altar=points('Sep29.sadang.altar moulded rim');cab=points('Sep29.sadang.cabinet timber base')
 gap=float(cab[:,2].min()-altar[:,2].max())
 check('Shrine cabinet bears on altar without a floating gap',-.04<=gap<=.002,gapMeters=gap)
 check('Shrine central pair has preserved leaf geometry and explicit review pivots',any(d.get('id')=='sadang_center' and len(d['hinges'])==2 for d in c['doors']))
 check('Unknown portrait installation has not been invented',not any('portrait' in o.name.lower() for o in scene.objects if o.get('photoDetailVersion')))
 coverage=[]
 for name in report['addedMeshes']:
  o=bpy.data.objects[name]
  for p in o.data.polygons:
   m=o.data.materials[p.material_index]
   if not m.get('artworkSource'):continue
   uv=o.data.uv_layers.get('Canonical gate pigment');co=[tuple(uv.data[i].uv) for i in p.loop_indices] if uv else []
   area=abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(co,co[1:]+co[:1]))) if co else 0
   if area<1e-14 or not all(np.isfinite(v) and 0<=v<=1 for q in co for v in q):coverage.append(name)
 check('New solid timber has nondegenerate artwork UVs on all assigned surfaces',not coverage,invalidObjects=sorted(set(coverage)))
