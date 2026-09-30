"""Separate, centred review GLBs; never overwrites the accepted estate GLB."""
from pathlib import Path
import bpy,sys,json,math,hashlib,argparse
from mathutils import Matrix,Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_courtyard_photo_repair import OUT
from review_gltf_pigment import preserve_tints
bpy.ops.wm.open_mainfile(filepath=str(OUT/'detail-redraw.blend'));s=bpy.context.scene
c=json.loads((OUT/'detail-redraw-contract.json').read_text(encoding='utf8'));sc=json.loads((OUT.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'))
rs={r['id']:r for r in c['buildings']};rs['ansarang']={**sc['buildings']['ansarang'],'datum':0};rs['jar-gate']={**c['rearYardGate'],'datum':1.5}
out=OUT/'review3d';out.mkdir(exist_ok=True);base={o.name:o.matrix_world.copy() for o in s.objects if o.type=='MESH'}
p=argparse.ArgumentParser();p.add_argument('--only');args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
report=json.loads((OUT/'redraw-3d-manifest.json').read_text()) if args.only else []
for ident,state in [('jar-gate','open'),('jar-gate','closed'),('sadangmun','open'),('sadangmun','closed'),('anchae','open'),('ansarang','open'),('sadang','closed'),('sadang','open')]:
 if args.only and ident!=args.only:continue
 for ob in s.objects:
  ob.select_set(False)
  if ob.name in base:ob.matrix_world=base[ob.name].copy()
 selected=[o for o in s.objects if o.type=='MESH' and not o.hide_render and (o.name.startswith('North.site.rear yard gate') if ident=='jar-gate' else o.get('construction_building')==ident)]
 if state=='open':
  for door in c['doors']+sc['doors']:
   pre=door['prefix']
   ok=(ident=='jar-gate' and 'rear yard gate.plank door' in pre) or (ident=='sadangmun' and door['building']=='sadangmun') or (ident=='ansarang' and door.get('id')=='ansarang_front3') or (ident=='anchae' and ('daechong rear door' in pre or 'hall room ' in pre or pre=='North.anchae.kitchen'))
   ok=ok or (ident=='sadang' and door.get('id')=='sadang_center')
   if not ok:continue
   for i,h in enumerate(door['hinges']):
    theta=math.radians((40 if i==0 else 73) if ident in ('jar-gate','sadangmun') else 76)*door['rotationSigns'][i];hinge=Vector(h)
    tr=Matrix.Translation(hinge)@Matrix.Rotation(theta,4,'Z')@Matrix.Translation(-hinge)
    leaves=door.get('leafGroups',[[j+1] for j in range(len(door['hinges']))])[i]
    for ob in selected:
     if any(ob.name.startswith(pre+f'.leaf{k}.') for k in leaves):ob.matrix_world=tr@base[ob.name]
    for f in door.get('folds',[]):
     if f['group']==i:
      fh=Vector(f['hinge']);fold=Matrix.Translation(fh)@Matrix.Rotation(abs(theta)*f['relativeSign'],4,'Z')@Matrix.Translation(-fh)
      for ob in selected:
       if ob.name.startswith(pre+f'.leaf{f["leaf"]}.'):ob.matrix_world=tr@fold@base[ob.name]
 r=rs[ident];local=Matrix.Rotation(-r['angle'],4,'Z')@Matrix.Translation(Vector((-r['center'][0],-r['center'][1],-r['datum'])))
 for ob in selected:
  ob.matrix_world=local@ob.matrix_world;ob.hide_set(False);ob.select_set(True)
 bpy.context.view_layer.objects.active=selected[0];bpy.context.view_layer.update()
 path=out/f'{ident}-{state}.glb'
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=False,export_draco_mesh_compression_enable=True,export_draco_mesh_compression_level=6,export_draco_position_quantization=16,export_draco_normal_quantization=12,export_draco_texcoord_quantization=16)
 preserve_tints(path)
 report=[r for r in report if not(r['building']==ident and r['state']==state)]
 report.append({'building':ident,'state':state,'file':path.name,'meshes':len(selected),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'candidateSceneSha256':hashlib.sha256((OUT/'detail-redraw.blend').read_bytes()).hexdigest(),'positionQuantizationBits':16})
 (OUT/'redraw-3d-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf8');print('REVIEW EXPORTED',ident,state,path.stat().st_size,flush=True)
