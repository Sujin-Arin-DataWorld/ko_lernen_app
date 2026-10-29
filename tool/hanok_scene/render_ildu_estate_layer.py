"""Render one immutable R16 estate layer with a shared camera and lighting.

blender -b -t 4 --python render_ildu_estate_layer.py -- --package-root PATH --key sarang
Inputs are never saved. Full-estate assembly uses original stored world coordinates.
"""
from pathlib import Path
import argparse, hashlib, json, math, sys
import bpy
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view

KEYS=['sarang','jung','anchae','arae','angotgan','ansarang','gokgan','changgo','sadang','toilet','toilet1']
CAMERA=dict(position=[-32,-63,72],target=[8,17,2],orthoScale=94,resolution=[1600,1700])
LIGHT=dict(sunEnergy=3.5,sunColor=[1,.904661,.745404],sunDirection=[-10,-12,20],sunAngle=.244346,worldColor=[.806952,.854993,.913099],worldStrength=.75,fillPosition=[24,-36,21],fillEnergy=8100,fillSize=42,exposure=.2,viewTransform='AgX',look='AgX - Medium High Contrast')

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def point(ob,target):ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
def write(p,data):p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def main():
    p=argparse.ArgumentParser();p.add_argument('--package-root',type=Path,required=True);p.add_argument('--key',choices=['context',*KEYS,'left','right','shrine'],required=True);p.add_argument('--samples',type=int,default=24)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:]);B=args.package_root.resolve();key=args.key
    R=B/'inputs/r12/surface-redesign-20261018/gate-rebuild/drawing-r4';D=B/'estate/layers';D.mkdir(parents=True,exist_ok=True)
    sources=[]
    if key in KEYS:
        native=B/'native'/key/'full.blend';before=sha(native)
        c=next(x for x in read(B/'APP_ASSET_CONTRACT.json')['buildings'] if x['key']==key)
        assert before==next(x['sha256'] for x in c['packedNatives'] if x['kind']=='full')
        bpy.ops.wm.open_mainfile(filepath=str(native),load_ui=False)
        scene=bpy.context.scene
        names=set(read(B/'family-r16'/key/'stage-selection.json')['steps'][-1]['visibleObjects'])
        assert names<=set(scene.objects.keys()),key
        for ob in scene.objects:
            if ob.type=='MESH':ob.hide_render=ob.name not in names
        members=[scene.objects[n] for n in sorted(names)]
        sources.append(dict(path=str(native),sha256=before))
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
        if key=='context':
            native=R/'canonical-review-r1/ildu-estate-r5-three-gates-canonical.blend'
            before=sha(native);assert before=='3195809855213946a330048b3b86cd3f75ccddac045dbaf640909cee4de36d48'
            groups=read(R/'construction/contracts/r12-owner-map.json')['groups']
            def wall(n):return n.startswith('ConnectionLeft.') or '.wall' in n.lower() or n.startswith('GyeCraft.wall')
            desired={n for g in groups if g['nativeOwner'] not in KEYS for n in g['sourceObjects'] if g['nativeOwner'] not in ['left_changgo','right_ansarang','sadangmun'] or wall(n)}
            transform=Matrix.Identity(4)
        else:
            native=B/'gates/native'/(key+'-material.blend');before=sha(native)
            desired=set(read(R/'construction'/(key+'-object-stage-map.json'))['assignments'])
            transform=Matrix(next(x['matrix'] for x in read(R/'canonical-review-r1/assembly-verification.json')['assembly'] if x['gate']==key))
        with bpy.data.libraries.load(str(native),link=False) as (available,loaded):
            names=sorted(desired&set(available.objects));assert len(names)==len(desired),(key,len(desired)-len(names));loaded.objects=names.copy()
        members=[]
        for name,ob in zip(names,loaded.objects):
            if not ob:raise ValueError('Missing member '+name)
            matrix=transform@ob.matrix_world.copy();scene.collection.objects.link(ob);ob.matrix_world=matrix
            if ob.type=='MESH':ob.hide_render=False;members.append(ob)
        sources.append(dict(path=str(native),sha256=before))
    # Native data, topology, UV and source hierarchy remain unmodified on disk.
    for ob in list(scene.objects):
        if ob.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(ob,do_unlink=True)
    world=bpy.data.worlds.new('R16 shared estate sky');world.use_nodes=True;scene.world=world
    nodes=world.node_tree.nodes;nodes.clear();bg=nodes.new('ShaderNodeBackground');out=nodes.new('ShaderNodeOutputWorld');world.node_tree.links.new(bg.outputs[0],out.inputs[0]);bg.inputs['Color'].default_value=(*LIGHT['worldColor'],1);bg.inputs['Strength'].default_value=LIGHT['worldStrength']
    sun_data=bpy.data.lights.new('R16 estate sun','SUN');sun_data.energy=LIGHT['sunEnergy'];sun_data.color=LIGHT['sunColor'];sun_data.angle=LIGHT['sunAngle'];sun=bpy.data.objects.new(sun_data.name,sun_data);scene.collection.objects.link(sun);sun.location=Vector(CAMERA['target'])+Vector(LIGHT['sunDirection']);point(sun,CAMERA['target'])
    fill_data=bpy.data.lights.new('R16 estate fill','AREA');fill_data.energy=LIGHT['fillEnergy'];fill_data.shape='DISK';fill_data.size=LIGHT['fillSize'];fill_data.color=LIGHT['sunColor'];fill=bpy.data.objects.new(fill_data.name,fill_data);scene.collection.objects.link(fill);fill.location=LIGHT['fillPosition'];point(fill,CAMERA['target'])
    cam_data=bpy.data.cameras.new('R16 shared estate camera');cam=bpy.data.objects.new(cam_data.name,cam_data);scene.collection.objects.link(cam);cam.location=CAMERA['position'];point(cam,CAMERA['target']);cam_data.type='ORTHO';cam_data.ortho_scale=CAMERA['orthoScale'];cam_data.clip_end=400;scene.camera=cam
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=args.samples;scene.cycles.use_denoising=True;scene.cycles.max_bounces=6;scene.cycles.transparent_max_bounces=8;scene.cycles.use_adaptive_sampling=True;scene.cycles.adaptive_threshold=.04;scene.cycles.seed=217
    scene.render.threads_mode='FIXED';scene.render.threads=4;scene.render.use_persistent_data=False;scene.render.film_transparent=True;scene.render.use_freestyle=False;scene.render.use_compositing=False
    scene.view_settings.view_transform=LIGHT['viewTransform'];scene.view_settings.look=LIGHT['look'];scene.view_settings.exposure=LIGHT['exposure']
    scene.render.resolution_x,scene.render.resolution_y=CAMERA['resolution'];scene.render.resolution_percentage=100
    scene.render.image_settings.media_type='MULTI_LAYER_IMAGE';scene.render.image_settings.file_format='OPEN_EXR_MULTILAYER';scene.render.image_settings.color_mode='RGBA';scene.render.image_settings.color_depth='32';scene.render.image_settings.exr_codec='ZIP'
    for view in scene.view_layers:view.use=view==bpy.context.view_layer
    bpy.context.view_layer.use_pass_z=True
    bpy.context.view_layer.update()
    pts=[ob.matrix_world@Vector(v) for ob in members for v in ob.bound_box]
    projected=[world_to_camera_view(scene,cam,v) for v in pts]
    bounds=dict(left=min(v.x for v in projected),right=max(v.x for v in projected),top=1-max(v.y for v in projected),bottom=1-min(v.y for v in projected))
    output=D/(key+'.exr');scene.render.filepath=str(output)
    settings=dict(camera=CAMERA,light=LIGHT)
    fingerprint=hashlib.sha256(json.dumps(settings,sort_keys=True).encode()).hexdigest()
    print('ESTATE_LAYER_RENDER',key,len(members),bounds,flush=True)
    bpy.ops.render.render(write_still=True)
    for source in sources:assert sha(Path(source['path']))==source['sha256']
    write(D/(key+'.json'),dict(complete=True,key=key,meshCount=len(members),sourceFilesUnchanged=True,sources=sources,settings=settings,settingsSha256=fingerprint,projectedBounds=bounds,image=output.name,sha256=sha(output),samples=args.samples,scope='completed artwork preview; no learner state'))
    print('ESTATE_LAYER_SAVED',key,flush=True)

if __name__=='__main__':main()
