"""Regression: every side-gate purlin bears on real timber at both post axes.

Removing the transverse beams/king posts must fail this test. Ray intersections
use evaluated triangles, not an object's broad bounding box or object count.
"""
from pathlib import Path
import bpy, sys, json, hashlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).parent))
from northern_timber_sections import groups
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'

def check():
 dg=bpy.context.evaluated_depsgraph_get();checks=[]
 for bid in ('left_changgo','right_ansarang'):
  frame=[]
  for o in bpy.context.scene.objects:
   if o.type!='MESH' or o.hide_render or o.get('construction_building')!=bid:continue
   if '.frame.' not in o.name and '.bearing.' not in o.name:continue
   ev=o.evaluated_get(dg);me=ev.to_mesh()
   frame.append((o.name,BVHTree.FromPolygons([o.matrix_world@v.co for v in me.vertices],[list(p.vertices) for p in me.polygons])))
   ev.to_mesh_clear()
  post=bpy.data.objects['V27.'+bid+'.frame.post']
  xs=sorted(sum((post.matrix_world@post.data.vertices[i].co).x for i in ids)/len(ids) for ids in groups(post.data))
  pur=bpy.data.objects['V28.'+bid+'.roof.purlin']
  for ids in groups(pur.data):
   pts=[pur.matrix_world@pur.data.vertices[i].co for i in ids];y=(min(p.y for p in pts)+max(p.y for p in pts))/2;z=min(p.z for p in pts)
   for x in xs:
    hits=[]
    for name,bvh in frame:
     hit,normal,face,distance=bvh.ray_cast(Vector((x,y,z+.002)),Vector((0,0,-1)),2)
     if hit is not None:hits.append((distance-.002,name))
    hit=min(hits) if hits else (None,None)
    checks.append({'gate':bid,'point':[x,y,z],'gap':hit[0],'bearing':hit[1],'pass':hit[0] is not None and -.006<=hit[0]<=.012})
 return checks

if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=str(N/'detail-redraw.blend'));bpy.context.view_layer.update();checks=check()
 out={'sceneSha256':hashlib.sha256((N/'detail-redraw.blend').read_bytes()).hexdigest(),'checks':checks,'passed':sum(c['pass'] for c in checks),'total':len(checks)}
 (N/'gate-bearing-validation.json').write_text(json.dumps(out,indent=2))
 print(json.dumps(out,indent=2),flush=True)
 assert all(c['pass'] for c in checks),'Floating side-gate purlin: missing beam or seat'
