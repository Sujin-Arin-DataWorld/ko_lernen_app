"""Fast actual-light reproduction on one plane, unchanged saved R4 soil."""
import bpy,json,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;R4=OUT.parent/'living-r4'
meta=json.loads((R4/'actual-lighting-scene.json').read_text(encoding='utf-8'))
source=OUT.parent/'ildu-estate-yard-wall-r1.blend'
names=[r['name'] for r in meta['lights']]
with bpy.data.libraries.load(str(source),link=False) as (src,dst):
    dst.objects=names;dst.worlds=['Warm estate | selected neutral sky.005']
lights=list(dst.objects);world=dst.worlds[0]
v=json.loads((R4/'verification.json').read_text(encoding='utf-8'))
with bpy.data.libraries.load(str(R4/v['library']),link=False) as (src,dst):dst.materials=list(v['material_signatures'])
mat=dst.materials[0]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.world=world
for light in lights:scene.collection.objects.link(light)
bpy.ops.mesh.primitive_plane_add(size=200);plane=bpy.context.object;plane.data.materials.append(mat)
bpy.ops.object.camera_add();scene.camera=bpy.context.object
m=json.loads((R4/'render-manifest.json').read_text(encoding='utf-8'))
c=next(r['camera'] for r in m['renders'] if r['view']=='overview')
scene.camera.location=c['location'];scene.camera.rotation_euler=c['rotation'];scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=c['ortho_scale']
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=64;scene.cycles.seed=15;scene.cycles.use_denoising=True
scene.render.threads_mode='FIXED';scene.render.threads=4;scene.render.use_persistent_data=True
scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.render.use_border=True;scene.render.use_crop_to_border=True
scene.render.border_min_x=775/1280;scene.render.border_max_x=1240/1280
scene.render.border_min_y=1-320/960;scene.render.border_max_y=1-70/960
scene.render.image_settings.file_format='PNG'
for variant in (('after',) if '--linked-only' in sys.argv else ('before','after')):
    if variant=='after':
        if '--linked-only' in sys.argv:
            sys.path.insert(0,str(OUT))
            from lighting_patch import apply_lighting_patch
            fixed,record=apply_lighting_patch(scene,[plane.name])
            (OUT/'light-link-functional-proof.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
        else:
            low=next(o for o in lights if 'low broad courtyard reflection' in o.name)
            low.location.z=6.545;low.rotation_euler=(0,0,0)
    label='linked-after' if '--linked-only' in sys.argv else variant
    scene.render.filepath=str(OUT/('light-proof-'+label+'.png'))
    bpy.ops.render.render(write_still=True)
    print('LIGHT PROOF',variant,flush=True)
