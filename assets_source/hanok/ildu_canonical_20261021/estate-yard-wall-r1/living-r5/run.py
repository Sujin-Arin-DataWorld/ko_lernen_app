"""Replay R4, repair its ground fill and secondary scope, verify, then render."""
import bpy,hashlib,importlib.util,json,shutil,sys,time
from pathlib import Path
OUT=Path(__file__).resolve().parent;BASE=OUT.parent;R4=BASE/'living-r4'
sys.path.insert(0,str(BASE));sys.path.insert(0,str(OUT))
from audit_source import state,bindings
from material_patch import signature,reachable
from scope_patch import patch_scope
from lighting_patch import apply_lighting_patch,SOURCE_LIGHT


def sha(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()


def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
def write(name,value):(OUT/name).write_text(json.dumps(value,ensure_ascii=False,indent=2),encoding='utf-8')


def light_state(data):
    return dict(type=data.type,energy=data.energy,color=list(data.color),size=getattr(data,'size',None),
        shape=getattr(data,'shape',None),spread=getattr(data,'spread',None),
        emission=[{s.name:list(s.default_value) if hasattr(s.default_value,'__iter__') else s.default_value
                   for s in n.inputs if hasattr(s,'default_value')} for n in data.node_tree.nodes if n.type=='EMISSION'] if data.node_tree else [])


def reconstruct_r4():
    spec=importlib.util.spec_from_file_location('r4_replay',R4/'run.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    prior=module.reconstruct_r3();report=module.apply_saved(prior)
    assert report['library_sha256']=='5be498fbf7f8d95011610c4c380fa6efb23ecf3b042907cab6d184d6959ec9de'
    return report


def build(prior):
    scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate'];bpy.context.window.scene=scene
    before,old_bind=state(),bindings()
    source=bpy.data.materials[prior['bindings'][0]['new']]
    source_sig=signature(source)
    source_lights={o.name:light_state(o.data) for o in scene.objects if o.type=='LIGHT'}
    revised=patch_scope(source,json.loads((OUT/'ground-scope.json').read_text(encoding='utf-8')))
    changed=[]
    for rec in prior['bindings']:
        slot=bpy.data.objects[rec['object']].material_slots[rec['slot']]
        assert slot.material==source
        slot.material=revised
        changed.append(dict(rec,old=source.name,new=revised.name))
    fixed,light_report=apply_lighting_patch(scene,[r['object'] for r in changed])
    bpy.context.view_layer.update()
    after=state()
    assert set(after)-set(before)=={fixed.name}
    assert all(after[name]==value for name,value in before.items()), 'An existing geometry/UV/transform changed'
    assert all(light_state(bpy.data.objects[n].data)==v for n,v in source_lights.items())
    assert signature(source)==source_sig
    allowed={(r['object'],r['slot']) for r in changed}
    new_bind=bindings()
    assert all(new_bind[n][i]==v for n,slots in old_bind.items() for i,v in enumerate(slots) if (n,i) not in allowed)
    sig=signature(revised);keep=reachable(revised)
    for n in list(revised.node_tree.nodes):
        if n not in keep:revised.node_tree.nodes.remove(n)
    assert signature(revised)==sig
    library=OUT/'continuous-yard-r5.blend'
    bpy.data.libraries.write(str(library),{revised,fixed.data},fake_user=True,compress=True)
    data_name=fixed.data.name
    with bpy.data.libraries.load(str(library),link=False) as (src,dst):
        inventory={k:len(getattr(src,k)) for k in ('materials','lights','objects','meshes','images','collections')}
        dst.materials=[revised.name];dst.lights=[data_name]
    assert inventory['objects']==inventory['meshes']==inventory['collections']==0
    assert signature(dst.materials[0])==sig
    assert light_state(dst.lights[0])==light_state(fixed.data)
    bpy.data.materials.remove(dst.materials[0]);bpy.data.lights.remove(dst.lights[0])
    report=dict(passed=True,source_sha256=prior['source_sha256'],r4_library_sha256=prior['library_sha256'],
        library=library.name,library_sha256=sha(library),library_datablocks=inventory,
        material_signatures={revised.name:sig},light_data_name=data_name,light_data_state=light_state(fixed.data),
        bindings=changed,lighting_patch=light_report,
        all_existing_geometry_uv_transforms_equal=True,verified_existing_objects=len(before),
        existing_geometry_signature=digest(before),new_objects=[dict(name=fixed.name,type='LIGHT')],
        original_soil_shader_unchanged=True,all_existing_light_data_equal=True,
        non_target_bindings_equal=True,saved_material_and_light_reloaded_equal=True,
        ground_scope_sha256=sha(OUT/'ground-scope.json'),scope_code_sha256=sha(OUT/'scope_patch.py'),
        light_code_sha256=sha(OUT/'lighting_patch.py'),app_integrated=False)
    write('verification.json',report);print('R5 VERIFIED, ONE GROUND-ONLY LIGHT',inventory,flush=True)
    return report


def apply_saved(prior):
    report=json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
    assert prior['library_sha256']==report['r4_library_sha256']
    assert digest(state())==report['existing_geometry_signature']
    library=OUT/report['library'];assert sha(library)==report['library_sha256']
    names=tuple(report['material_signatures'])
    with bpy.data.libraries.load(str(library),link=False) as (src,dst):
        dst.materials=list(names);dst.lights=[report['light_data_name']]
    mats=dict(zip(names,dst.materials))
    for n,m in mats.items():assert signature(m)==report['material_signatures'][n]
    assert light_state(dst.lights[0])==report['light_data_state']
    for r in report['bindings']:
        slot=bpy.data.objects[r['object']].material_slots[r['slot']]
        assert slot.material.name==r['old'];slot.material=mats[r['new']]
    scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate'];bpy.context.window.scene=scene
    fixed,record=apply_lighting_patch(scene,[r['object'] for r in report['bindings']],dst.lights[0])
    assert record==report['lighting_patch']
    return report


def render(report,views):
    scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate']
    prior=json.loads((R4/'render-manifest.json').read_text(encoding='utf-8'))
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.seed=15
    scene.cycles.use_denoising=True;scene.render.use_persistent_data=True
    scene.render.threads_mode='FIXED';scene.render.threads=8
    scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
    scene.render.use_border=False;scene.render.use_crop_to_border=False
    scene.render.image_settings.file_format='PNG'
    path=OUT/'render-manifest.json'
    manifest=json.loads(path.read_text(encoding='utf-8')) if path.exists() else dict(
        source_sha256=report['source_sha256'],r4_library_sha256=report['r4_library_sha256'],
        library_sha256=report['library_sha256'],lighting_patch=report['lighting_patch'],renders=[])
    assert manifest['library_sha256']==report['library_sha256']
    for view in views:
        a=next(r for r in prior['renders'] if r['view']==view and r['variant']=='B')
        c=a['camera'];scene.camera.location=c['location'];scene.camera.rotation_euler=c['rotation'];scene.camera.data.ortho_scale=c['ortho_scale']
        source=R4/a['file'];assert sha(source)==a['sha256']
        target=OUT/(view+'-A.png');shutil.copyfile(source,target)
        manifest['renders']=[r for r in manifest['renders'] if r['view']!=view]
        common=dict(view=view,camera=c,samples=24,seed=15,resolution=[1280,960])
        manifest['renders'].append(dict(common,variant='A',file=target.name,sha256=sha(target),reused_from=str(source)))
        target=OUT/(view+'-B.png');scene.render.filepath=str(target);start=time.monotonic()
        print('RENDER R5',view,flush=True);bpy.ops.render.render(write_still=True,scene=scene.name)
        manifest['renders'].append(dict(common,variant='B',file=target.name,sha256=sha(target),
            library_sha256=report['library_sha256'],lighting='linked ground-only corrected fill',
            all_other_source_lights_retained=True,seconds=round(time.monotonic()-start,2)))
        write('render-manifest.json',manifest);print('SAVED R5',view,flush=True)


if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    prior=reconstruct_r4();report=apply_saved(prior) if 'apply' in args else build(prior)
    if 'render' in args:render(report,args[args.index('render')+1:] or ['overview','full','detail'])
