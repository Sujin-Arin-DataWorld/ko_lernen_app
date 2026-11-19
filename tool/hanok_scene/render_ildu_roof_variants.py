"""Render new standalone roofs at their preserved process frames/cameras."""
from pathlib import Path
import argparse,hashlib,json,sys
import bpy
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--package-root',type=Path,required=True);p.add_argument('--key',choices=['sarang','jung'],required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:]);B=args.package_root.resolve();key=args.key;D=B/'roof-variants/review'/key;D.mkdir(parents=True,exist_ok=True)
    full=read(B/'roof-variants'/(key+'-full-verified.json'));stage=read(B/'roof-variants'/(key+'-stage-verified.json'));assert full['complete'] and stage['complete']
    full_native=B/'roof-variants/native'/key/'full.blend';stage_native=B/'roof-variants/native'/key/'stage.blend'
    source=read(B/'family-r16'/key/'stage-selection.json');rows=[]
    def render(scene,path):
        scene.cycles.samples=24;scene.render.threads_mode='FIXED';scene.render.threads=4;scene.render.use_persistent_data=False;scene.render.image_settings.media_type='IMAGE';scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGB';scene.render.filepath=str(path)
        bpy.ops.render.render(write_still=True);return sha(path)
    assert sha(full_native)==full['sha256'];bpy.ops.wm.open_mainfile(filepath=str(full_native),load_ui=False)
    full_image=D/'full.png';full_digest=render(bpy.context.scene,full_image)
    assert sha(full_native)==full['sha256']
    assert sha(stage_native)==stage['sha256'];bpy.ops.wm.open_mainfile(filepath=str(stage_native),load_ui=False);scene=bpy.context.scene
    owner=next(o for o in read(B/'roof-variants/input/ROOF_SOURCE_MAP.json')['owners'] if o['key']==key)
    first=min([p['requiredStage'] for p in owner['patches']]+[p['requiredStage'] for p in owner['replacements']])
    stages=D/'stages';stages.mkdir(exist_ok=True)
    for step in source['steps']:
        frame=step['sequence'];scene.frame_set(frame);bpy.context.view_layer.update()
        expected={r['object'] for r in stage['patches'] if r['requiredStage']<=frame}
        actual={r['object'] for r in stage['patches'] if not scene.objects[r['object']].hide_render};assert actual==expected
        if frame<first:
            image='review/'+key+'/stages/'+str(frame).zfill(2)+'.png';digest=sha(B/'family-r16'/key/'stages'/(str(frame).zfill(2)+'.png'));reused=True
        else:
            path=stages/(str(frame).zfill(2)+'.png');digest=render(scene,path);image='estate/standalone/'+key+'/stages/'+path.name;reused=False
        rows.append(dict(sequence=frame,processId=step['processId'],label=step['label'],reviewImage=image,sha256=digest,reusedUnchangedEarlierStage=reused,standaloneRoofMembers=len(actual)))
        print('STANDALONE_STAGE_RENDERED',key,frame,'reuse' if reused else 'new',flush=True)
    assert sha(stage_native)==stage['sha256']
    result=dict(complete=True,key=key,fullImage='estate/standalone/'+key+'/full.png',fullImageSha256=full_digest,stages=rows,firstChangedStage=first,fullNativeSha256=full['sha256'],stageNativeSha256=stage['sha256'],cameraLightingAndMaterialsPreserved=True,logicalStageIdsUnchanged=True,runtimeIntegrated=False)
    (B/'roof-variants'/(key+'-renders.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('R16_ROOF_RENDERS_COMPLETE',key,flush=True)
if __name__=='__main__':main()
