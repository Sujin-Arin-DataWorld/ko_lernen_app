import bpy,json,time,hashlib,sys
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate']
changes=json.loads((OUT/'material-changes.json').read_text(encoding='utf-8'))
bindings=json.loads((OUT/'bindings-before.json').read_text(encoding='utf-8'))
manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
missing=sorted({r['old'] for r in changes if r['old'] not in bpy.data.materials})
if missing:
    # Blender discards now unused original materials when saving the candidate.
    # Load the original datablocks solely for the before comparison.
    with bpy.data.libraries.load(manifest['canonical_source'],link=False) as (src,dst):
        dst.materials=missing
cam=scene.camera
original=(cam.location.copy(),cam.rotation_euler.copy(),cam.data.ortho_scale)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.use_persistent_data=True
scene.cycles.use_denoising=True;scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
prior=OUT/'render-manifest.json'
records=json.loads(prior.read_text(encoding='utf-8'))['renders'] if prior.exists() else []
jobs=[('wall',(-1.79,-19.1,.8),11.2,(1280,960)),('courtyard',(-8,-7,.4),29,(1280,960)),('full',None,original[2],(1280,960))]
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
if args:jobs=[j for j in jobs if j[0] in args]
def sha(p):
    with open(p,'rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
for name,center,ortho,res in jobs:
    if center is None:
        cam.location=original[0];cam.rotation_euler=original[1]
    else:
        c=Vector(center)
        direction=Vector((-.9,-1.4,1.5)) if name=='courtyard' else Vector((-1.9,-1.1,1.05))
        cam.location=c+direction.normalized()*80
        cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale=ortho;scene.render.resolution_x=res[0];scene.render.resolution_y=res[1]
    view={'location':list(cam.location),'rotation':list(cam.rotation_euler),'ortho_scale':ortho,'samples':24,'resolution':res,'engine':'CYCLES CPU','threads':scene.render.threads,'persistent_data':scene.render.use_persistent_data,'lights_preserved':True,'source_colour_management_preserved':True}
    for variant in ['before','after']:
        done=next((r for r in records if r['view']==name and r['variant']==variant),None)
        if done and Path(done['path']).exists() and sha(done['path'])==done['sha256']:
            print('KEEP VERIFIED RENDER',name,variant,flush=True)
            continue
        for r in changes:
            slot=bpy.data.objects[r['object']].material_slots[r['slot']]
            if variant=='before':
                slot.link=bindings[r['object']][r['slot']][0];slot.material=bpy.data.materials[r['old']]
            else:
                slot.link='OBJECT';slot.material=bpy.data.materials[r['new']]
        path=OUT/(name+'-'+variant+'.png');scene.render.filepath=str(path)
        print('RENDER',name,variant,flush=True);start=time.monotonic()
        bpy.ops.render.render(write_still=True,scene=scene.name)
        records.append({'view':name,'variant':variant,'path':str(path),'sha256':sha(path),'native_sha256':manifest['canonical_sha256'] if variant=='before' else manifest['candidate_sha256'],'view_settings':view,'seconds':round(time.monotonic()-start,2)})
        (OUT/'render-manifest.json').write_text(json.dumps({'candidate_sha256':manifest['candidate_sha256'],'renders':records},ensure_ascii=False,indent=2),encoding='utf-8')
cam.location=original[0];cam.rotation_euler=original[1];cam.data.ortho_scale=original[2]
print('RENDER COMPLETE',len(records),flush=True)
sys.path.insert(0,str(OUT))
from material_patch import export
export()
