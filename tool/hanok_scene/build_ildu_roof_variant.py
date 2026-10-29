"""Add verified standalone roof geometry to a NEW R16 full/stage derivative.

Existing connected natives are never saved. New complements inherit the actual
source member stage; they do not award progress or expose future building parts.
"""
from pathlib import Path
import argparse, hashlib, json, sys
import bpy

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def materials(ob):return [(s.link,s.material) for s in ob.material_slots]
def material_names(ob):return [(s.link,s.material.name if s.material else None) for s in ob.material_slots]
def assign(ob,slots):
    assert len(ob.material_slots)==len(slots),(ob.name,len(ob.material_slots),len(slots))
    for slot,(link,mat) in zip(ob.material_slots,slots):slot.link=link;slot.material=mat
def required_inputs(material):
    todo=[material.node_tree] if material and material.use_nodes else [];seen=set();attrs=set();uvs=set()
    while todo:
        tree=todo.pop()
        if tree.as_pointer() in seen:continue
        seen.add(tree.as_pointer())
        for node in tree.nodes:
            if node.type=='GROUP' and node.node_tree:todo.append(node.node_tree)
            elif node.type=='ATTRIBUTE' and node.attribute_name and node.attribute_type=='GEOMETRY':attrs.add(node.attribute_name)
            elif node.type=='UVMAP' and node.uv_map:uvs.add(node.uv_map)
    return attrs,uvs
def check_material_addresses(ob):
    attrs=set(ob.data.attributes.keys());uvs=set(ob.data.uv_layers.keys())
    for slot in ob.material_slots:
        need_attr,need_uv=required_inputs(slot.material)
        assert need_attr<=attrs,(ob.name,'missing attributes',need_attr-attrs)
        assert need_uv<=uvs,(ob.name,'missing UV',need_uv-uvs)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--package-root',type=Path,required=True);parser.add_argument('--key',choices=['sarang','jung'],required=True);parser.add_argument('--kind',choices=['full','stage'],required=True)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);B=args.package_root.resolve();key=args.key;kind=args.kind
    directory=B/'roof-variants';mapping=read(directory/'input/ROOF_SOURCE_MAP.json');owner=next(o for o in mapping['owners'] if o['key']==key)
    verified=read(directory/'input/ROOF_LIBRARY_VERIFIED.json');library=directory/'input'/verified['file'];assert verified['complete'] and sha(library)==verified['sha256']
    source=B/'native'/key/(kind+'.blend');original_sha=sha(source);stage=read(B/'family-r16'/key/'stage-selection.json');max_stage=len(stage['steps'])
    bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False);scene=bpy.context.scene
    originals={n:scene.objects[n] for n in stage['requiredStage']}
    before={n:dict(data=o.data,materials=material_names(o),matrix=[list(r) for r in o.matrix_world],parent=o.parent) for n,o in originals.items()}
    original_ids={o.as_pointer() for o in bpy.data.objects}
    requested=[r['name'] for category in ['patches','replacements','hiddenHelpers'] for r in owner[category]]
    print('APPEND_ROOF_VARIANT',key,kind,len(requested),flush=True)
    with bpy.data.libraries.load(str(library),link=False) as (a,z):
        assert set(requested)<=set(a.objects);z.objects=requested.copy()
    loaded=dict(zip(requested,z.objects));new=[];patch_rows=[]
    for row in owner['replacements']:
        original=originals[row['target']];slots=materials(original)
        original.data=loaded[row['name']].data.copy();assign(original,slots);check_material_addresses(original)
    for row in owner['patches']:
        candidates=[originals[n] for n in row['materialSourceCandidates']]
        signatures={tuple(material_names(o)) for o in candidates}
        assert len(signatures)==1,(row['name'],'ambiguous R16 material bindings',row['materialSourceCandidates'])
        source_member=candidates[0];ob=loaded[row['name']]
        assert isinstance(row['requiredStage'],int) and 1<=row['requiredStage']<=max_stage
        assign(ob,materials(source_member));check_material_addresses(ob)
        ob.name='R16 standalone complement | '+row['name'].split(' | ',1)[1]
        ob['r16StandaloneRoof']=True;ob['r16SourceMembers']=json.dumps(row['materialSourceCandidates']);ob['requiredStage']=row['requiredStage'];ob['rewardCreditAllowed']=False
        scene.collection.objects.link(ob);new.append(ob)
        if kind=='stage':
            for frame in range(1,max_stage+1):
                ob.hide_render=row['hideRender'] or frame<row['requiredStage'];ob.hide_viewport=ob.hide_render
                ob.keyframe_insert(data_path='hide_render',frame=frame);ob.keyframe_insert(data_path='hide_viewport',frame=frame)
        else:ob.hide_render=row['hideRender'];ob.hide_viewport=row['hideRender']
        patch_rows.append(dict(object=ob.name,sourceMembers=row['materialSourceCandidates'],requiredStage=row['requiredStage'],materials=material_names(ob),donorObject=row['name'],donorRawGeometrySha256=row['rawGeometrySha256']))
    for row in owner['hiddenHelpers']:
        ob=loaded[row['name']];assert ob.hide_render
        scene.collection.objects.link(ob);ob['r16StandaloneHiddenHelper']=True;ob.hide_render=True;ob.hide_viewport=True;new.append(ob)
    keep={o.as_pointer() for o in new}
    for ob in list(bpy.data.objects):
        if ob.as_pointer() not in original_ids and ob.as_pointer() not in keep and not ob.users_collection:bpy.data.objects.remove(ob,do_unlink=True)
    replaced={r['target'] for r in owner['replacements']}
    for name,ob in originals.items():
        assert name in replaced or ob.data==before[name]['data'],name
        assert material_names(ob)==before[name]['materials'],name
        assert [list(r) for r in ob.matrix_world]==before[name]['matrix'] and ob.parent==before[name]['parent'],name
    scene['r16DisplayVariant']='standalone-complete-roof';scene['r16ConnectedSourceSha256']=original_sha;scene['r16NewProgressOrReward']=False
    scene.frame_set(max_stage)
    bpy.ops.file.pack_all();bpy.data.orphans_purge(do_recursive=True)
    assert all(im.packed_file for im in bpy.data.images if im.source=='FILE' and im.users), 'Unpacked image'
    out=directory/'native'/key/(kind+'.blend');out.parent.mkdir(parents=True,exist_ok=True);assert not out.exists()
    bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out),compress=True,relative_remap=True)
    output_sha=sha(out);assert sha(source)==original_sha and sha(library)==verified['sha256']
    bpy.ops.wm.open_mainfile(filepath=str(out),load_ui=False);scene=bpy.context.scene
    selected=[]
    for frame in (range(1,max_stage+1) if kind=='stage' else [max_stage]):
        scene.frame_set(frame);bpy.context.view_layer.update()
        actual={n for n in originals if not scene.objects[n].hide_render}
        expected=set(stage['steps'][frame-1]['visibleObjects']);assert actual==expected,(key,kind,frame,'original visibility drift')
        expected_new={r['object'] for r in patch_rows if frame>=r['requiredStage']}
        actual_new={r['object'] for r in patch_rows if not scene.objects[r['object']].hide_render};assert actual_new==expected_new,(frame,'patch selection')
        selected.append(dict(sequence=frame,processId=stage['steps'][frame-1]['processId'],originalVisible=len(actual),standaloneRoofVisible=len(actual_new)))
    scene.frame_set(max_stage)
    report=dict(complete=True,key=key,kind=kind,native=str(out),sha256=output_sha,sourceConnectedNativeSha256=original_sha,sourceFilesUnchanged=True,roofLibrarySha256=verified['sha256'],patches=patch_rows,repairedMeshObjects=sorted(replaced),hiddenHelpers=len(owner['hiddenHelpers']),nonRoofDataMaterialsTransformsHierarchyPreserved=True,packedImages=True,reopened=True,stageSelections=selected,logicalProcessIdsUnchanged=True,newProgressOrReward=False,runtimeIntegrated=False)
    (directory/(key+'-'+kind+'-verified.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('R16_STANDALONE_ROOF_VERIFIED',key,kind,len(patch_rows),output_sha,flush=True)

if __name__=='__main__':main()
