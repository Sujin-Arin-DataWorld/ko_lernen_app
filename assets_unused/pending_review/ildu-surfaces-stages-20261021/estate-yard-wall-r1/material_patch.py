"""Export/reapply the portable native material patch.

Export: open the local candidate; --python material_patch.py -- export
Reapply: open exact canonical R12; --python material_patch.py -- apply [--output path]
Without --output, reconstructs and verifies in memory only.
"""
import bpy,sys,json,hashlib
from pathlib import Path
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
from audit_source import SOURCE,EXPECTED,state,bindings,write,sha
IMAGE_SIGNATURES={}

def data_signature(data):
    return hashlib.sha256(json.dumps(data,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()

def reachable(m):
    roots=[x for x in m.node_tree.nodes if x.type=='OUTPUT_MATERIAL' and x.is_active_output]
    seen=set();todo=list(roots)
    while todo:
        x=todo.pop()
        if x in seen:continue
        seen.add(x)
        for s in x.inputs:
            for l in s.links:todo.append(l.from_node)
    return seen

def signature(m):
    rr=reachable(m);nodes=[]
    for n in sorted(rr,key=lambda x:x.name):
        p={}
        for k in ['operation','blend_type','data_type','noise_dimensions','normalize','clamp','use_clamp','interpolation_type','vector_type','is_active_output']:
            if hasattr(n,k):p[k]=getattr(n,k)
        if n.type=='VALTORGB':p['ramp']={'mode':n.color_ramp.interpolation,'elements':[(e.position,list(e.color)) for e in n.color_ramp.elements]}
        if n.type=='TEX_IMAGE' and n.image:
            im=n.image
            if im.as_pointer() not in IMAGE_SIGNATURES:
                packed=bytes(im.packed_file.data) if im.packed_file else b''
                IMAGE_SIGNATURES[im.as_pointer()]={'size':list(im.size),'colorspace':im.colorspace_settings.name,'packed_sha256':hashlib.sha256(packed).hexdigest() if packed else None,'source_path':im.filepath if not packed else None}
            p['image']=IMAGE_SIGNATURES[im.as_pointer()]
            p['projection']=n.projection;p['extension']=n.extension;p['interpolation']=n.interpolation
        if n.type=='UVMAP':p['uv_map']=n.uv_map
        if n.type=='VERTEX_COLOR':p['layer_name']=n.layer_name
        inputs=[]
        for i,s in enumerate(n.inputs):
            if s.is_linked:inputs.append([i,[(l.from_node.name,list(l.from_node.outputs).index(l.from_socket)) for l in s.links]])
            elif hasattr(s,'default_value'):
                v=s.default_value
                if hasattr(v,'__iter__') and not isinstance(v,str):v=list(v)
                inputs.append([i,v])
        nodes.append([n.name,n.bl_idname,p,inputs])
    return hashlib.sha256(json.dumps(nodes,sort_keys=True,ensure_ascii=False).encode()).hexdigest()

def export():
    native=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))['candidate_sha256']
    existing=OUT/'material-patch.json'
    if existing.exists():
        prior=json.loads(existing.read_text(encoding='utf-8'))
        if prior.get('candidate_native_sha256')==native and (OUT/prior['library']).exists() and sha(OUT/prior['library'])==prior['library_sha256']:
            print('KEEP VERIFIED MATERIAL PATCH',prior['library_sha256'],flush=True);return
    changes=json.loads((OUT/'material-changes.json').read_text(encoding='utf-8'))
    names={r['new'] for r in changes};mats={bpy.data.materials[n] for n in names}
    sig={m.name:signature(m) for m in mats}
    for m in mats:
        keep=reachable(m)
        for node in list(m.node_tree.nodes):
            if node not in keep:m.node_tree.nodes.remove(node)
        assert signature(m)==sig[m.name]
    library=OUT/'yard-wall-materials.blend'
    bpy.data.libraries.write(str(library),mats,fake_user=True,compress=True)
    with bpy.data.libraries.load(str(library),link=False) as (src,dst):
        inventory={k:len(getattr(src,k)) for k in ['materials','images','node_groups','meshes','objects']}
    assert inventory['objects']==0 and inventory['meshes']==0,'Unexpected scene geometry dependency in material library'
    geometry=json.loads((OUT/'geometry-before.json').read_text(encoding='utf-8'))
    candidate_bindings=json.loads((OUT/'bindings-after.json').read_text(encoding='utf-8'))
    write('material-patch.json',{'source_sha256':EXPECTED,'candidate_native_sha256':native,'library':library.name,'library_sha256':sha(library),'library_datablocks':inventory,'geometry_signature':data_signature(geometry),'candidate_binding_signature':data_signature(candidate_bindings),'material_signatures':sig,'bindings':[{'object':r['object'],'slot':r['slot'],'source_material':r['old'],'material':r['new'],'link':'OBJECT','role':r['role']} for r in changes],'candidate_shader_signatures_match_library':True,'unused_source_texture_nodes_removed':True,'geometry_not_in_library':True})
    print('PATCH EXPORT',library.stat().st_size,'bytes',len(mats),'materials',flush=True)

def apply():
    source=Path(bpy.data.filepath).resolve()
    assert source.is_file() and sha(source)==EXPECTED,'Open the exact canonical source bytes first'
    patch=json.loads((OUT/'material-patch.json').read_text(encoding='utf-8'))
    lib=OUT/patch['library'];assert sha(lib)==patch['library_sha256']
    old_bind=bindings()
    with bpy.data.libraries.load(str(lib),link=False) as (src,dst):dst.materials=list(patch['material_signatures'])
    for name,sig in patch['material_signatures'].items():assert signature(bpy.data.materials[name])==sig,name
    keys=set()
    for r in patch['bindings']:
        o=bpy.data.objects[r['object']];s=o.material_slots[r['slot']]
        assert s.material.name==r['source_material'],r['object']
        s.link=r['link'];s.material=bpy.data.materials[r['material']];keys.add((o.name,r['slot']))
    after=state();assert data_signature(after)==patch['geometry_signature'],'Reconstruction geometry/UV/transform changed'
    new_bind=bindings();bad=[]
    for name,ss in old_bind.items():
        for i,s in enumerate(ss):
            if (name,i) not in keys and new_bind[name][i]!=s:bad.append([name,i])
    assert not bad,'Reconstruction changed nontarget binding'
    assert data_signature(new_bind)==patch['candidate_binding_signature'],'Reconstruction bindings differ from candidate'
    report={'passed':True,'source':str(source),'source_sha256':sha(source),'reference_candidate_native_sha256':patch.get('candidate_native_sha256'),'library_sha256':sha(lib),'render_connected_material_signatures_equal':True,'all_geometry_uv_transforms_equal':True,'all_nontarget_bindings_equal':True,'all_candidate_bindings_equal':True,'verified_objects':len(after),'applied_slots':len(keys),'saved_output':None}
    args=sys.argv[sys.argv.index('--')+1:]
    if '--output' in args:
        output=Path(args[args.index('--output')+1]).resolve()
        assert output!=source,'Canonical overwrite prohibited'
        bpy.ops.wm.save_as_mainfile(filepath=str(output),compress=True);report['saved_output']=str(output)
    write('patch-reconstruction-verification.json',report)
    print(json.dumps(report),flush=True)

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    if args and args[0]=='export':export()
    elif args and args[0]=='apply':apply()
    else:raise ValueError('Specify -- export or -- apply [--output path]')
