"""Compose the actual R16 layers by camera depth in Blender 5.2."""
from pathlib import Path
import argparse, hashlib, json, sys
import bpy

KEYS=['context','sarang','jung','anchae','arae','angotgan','ansarang','gokgan','changgo','sadang','toilet','toilet1','left','right','shrine']
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--package-root',type=Path,required=True);p.add_argument('--preview-key',choices=KEYS)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:]);B=args.package_root.resolve();D=B/'estate';L=D/'layers'
    keys=[args.preview_key] if args.preview_key else KEYS
    receipts=[read(L/(key+'.json')) for key in keys]
    assert all(r['complete'] and r['sourceFilesUnchanged'] and sha(L/r['image'])==r['sha256'] for r in receipts)
    assert len({r['settingsSha256'] for r in receipts})==1
    bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
    group=bpy.data.node_groups.new('R16 full estate depth assembly','CompositorNodeTree')
    group.interface.new_socket(name='Image',in_out='OUTPUT',socket_type='NodeSocketColor')
    scene.compositing_node_group=group
    previous=None;depth=None
    for index,r in enumerate(receipts):
        node=group.nodes.new('CompositorNodeImage');node.name=r['key'];node.label=r['key'];node.image=bpy.data.images.load(str(L/r['image']),check_existing=False);node.location=(index*240,300)
        print('LAYER_SOCKETS',r['key'],list(node.outputs.keys()),flush=True)
        image=node.outputs['Combined'];z=node.outputs['Depth']
        if previous is not None:
            combine=group.nodes.new('CompositorNodeZcombine');combine.inputs['Use Alpha'].default_value=True;combine.inputs['Anti-Alias'].default_value=True;combine.location=(index*240,0)
            for source,target in [(previous,combine.inputs[0]),(depth,combine.inputs[1]),(image,combine.inputs[2]),(z,combine.inputs[3])]:group.links.new(source,target)
            previous=combine.outputs['Result'];depth=combine.outputs['Depth']
        else:previous=image;depth=z
    alpha=group.nodes.new('CompositorNodeAlphaOver');alpha.inputs['Factor'].default_value=1
    def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    alpha.inputs['Background'].default_value=(*[linear(v/255) for v in [250,246,236]],1)
    group.links.new(previous,alpha.inputs['Foreground']);out=group.nodes.new('NodeGroupOutput');group.links.new(alpha.outputs[0],out.inputs['Image'])
    camera=bpy.data.cameras.new('compositor evaluation');ob=bpy.data.objects.new(camera.name,camera);scene.collection.objects.link(ob);scene.camera=ob
    scene.render.engine='CYCLES';scene.cycles.samples=1;scene.render.threads_mode='FIXED';scene.render.threads=2;scene.render.film_transparent=True
    scene.render.resolution_x,scene.render.resolution_y=receipts[0]['settings']['camera']['resolution'];scene.render.resolution_percentage=100
    light=receipts[0]['settings']['light'];scene.view_settings.view_transform=light['viewTransform'];scene.view_settings.look=light['look'];scene.view_settings.exposure=light['exposure']
    scene.render.use_compositing=True;scene.render.image_settings.media_type='IMAGE';scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGB';scene.render.image_settings.color_depth='8'
    output=D/('preview-'+args.preview_key+'.png' if args.preview_key else 'complete.png');scene.render.filepath=str(output)
    bpy.ops.render.render(write_still=True)
    report=dict(complete=not args.preview_key,preview=bool(args.preview_key),layers=keys,settings=receipts[0]['settings'],settingsSha256=receipts[0]['settingsSha256'],image=output.name,sha256=sha(output),layerReceipts=receipts,geometryRedrawn=False,placement='original stored world coordinates; rebuilt gates use original assembly matrices',crossBuildingBounceAndShadow='layers preserve self shadows; cross-layer indirect lighting is not a single-scene path trace',runtimeIntegrated=False)
    name='PREVIEW_'+args.preview_key+'.json' if args.preview_key else 'RENDER_MANIFEST.json'
    (D/name).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('ESTATE_COMPOSED',output,flush=True)
if __name__=='__main__':main()
