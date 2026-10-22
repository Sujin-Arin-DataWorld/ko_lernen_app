"""Repair review cameras using actual rendered occupancy and sanctuary locations.
No mesh or material changes. Controls restore the preserved original datablocks.
"""
from pathlib import Path
import bpy,sys,json,importlib.util
import numpy as np
from mathutils import Vector
HOME=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('extension',HOME/'restyle_building.py');a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
s=a.s;r2=a.r2
def rendered_bounds(path):
    im=bpy.data.images.load(str(path),check_existing=False);ar=np.empty(len(im.pixels),np.float32);im.pixels.foreach_get(ar);w,h=im.size;ar=ar.reshape(h,w,4)
    bg=np.median(np.concatenate([ar[:8,:,:3].reshape(-1,3),ar[-8:,:,:3].reshape(-1,3)]),axis=0)
    mask=np.max(np.abs(ar[:,:,:3]-bg),axis=2)>.035
    rows=np.flatnonzero(mask.sum(axis=1)>3);cols=np.flatnonzero(mask.sum(axis=0)>3)
    result=(int(cols[0]),int(rows[0]),int(cols[-1]),int(rows[-1]),w,h);bpy.data.images.remove(im);return result
def main():
    key=sys.argv[sys.argv.index('--')+1];out=HOME/key;s.OUT=out
    v=json.loads((out/'verification.json').read_text(encoding='utf-8'));manifest=json.loads((out/'render-manifest.json').read_text(encoding='utf-8'))
    a.write(out/'review-cameras-previous.json',dict(views=v['views'],renders=manifest))
    path=out/v['candidateNative'];assert s.sha(path)==v['candidateSha256']
    bpy.ops.wm.open_mainfile(filepath=str(path));scene=bpy.context.scene;obs=[o for o in scene.objects if o.type=='MESH']
    geometry=s.geometry_state(obs);attrs=r2.attributes(obs);props=a.object_properties(obs);images=r2.image_state()
    materials={m.name:s.material_state(m) for o in obs for sl in o.material_slots if (m:=sl.material)}
    lo,hi=map(Vector,v['bounds']['bounds']);span=v['bounds']['span'];cam=scene.camera
    if key=='anchae':
        old=v['views']['hero'];x0,y0,x1,y1,w,h=rendered_bounds(out/'before-hero.png')
        cam.location=old['position'];s.point(cam,old['target']);bpy.context.view_layer.update();rotation=cam.rotation_euler.to_quaternion()
        dx=((x0+x1)/2/w-.5)*old['ortho'];dy=((y0+y1)/2/h-.5)*old['ortho']*h/w
        delta=rotation@Vector((dx,dy,0));target=Vector(old['target'])+delta
        hero=dict(old,position=list(Vector(old['position'])+delta),target=list(target),ortho=old['ortho']*max((x1-x0)/w,(y1-y0)/h)*1.12)
        target.z=lo.z+(hi.z-lo.z)*.36
        detail=dict(position=list(target+Vector((1.2,-1.7,.28))*span),target=list(target),ortho=hero['ortho']*.47,resolution=(1100,825))
        evidence=dict(renderedOccupancy=[x0,y0,x1,y1,w,h],targetCorrection=list(delta))
    elif key=='sadang':
        sanctuary=[o for o in obs if 'survey sanctuary' in o.name.lower()]
        assert sanctuary
        centers=[sum((o.matrix_world@Vector(p) for p in o.bound_box),Vector())/8 for o in sanctuary]
        facade=sum(centers,Vector())/len(centers);center=(lo+hi)/2
        vec=facade-center;vec.z=0;axis=max(range(2),key=lambda i:abs(vec[i]));front=Vector((0,0,0));front[axis]=1 if vec[axis]>0 else -1
        side=Vector((-front.y,front.x,0));direction=front*1.8+side*.62+Vector((0,0,.65))
        target=center.copy();target.z=lo.z+(hi.z-lo.z)*.46
        hero=dict(position=list(target+direction*span),target=list(target),ortho=span*1.33,resolution=(1100,825))
        close=facade.copy();close.z=lo.z+(hi.z-lo.z)*.43
        detail=dict(position=list(close+(front*2+side*.12+Vector((0,0,.12)))*span),target=list(close),ortho=span*.55,resolution=(1100,825))
        evidence=dict(sanctuaryMemberCount=len(sanctuary),facadeCenter=list(facade),frontDirection=list(front))
    else:raise ValueError(key)
    views=dict(hero=hero,detail=detail);bindings=[]
    for ob in obs:
        for i,sl in enumerate(ob.material_slots):
            if sl.material and sl.material.get('r5_source_material'):
                bindings.append((ob.name,i,sl.material.name));sl.material=bpy.data.materials[sl.material['r5_source_material']]
    renders=[];light=a.art.study.signature(scene)
    for name,view in views.items():renders.append(dict(variant='source',view=name,**s.render(scene,cam,'before-'+name+'.png',**view)))
    for n,i,mat in bindings:bpy.data.objects[n].material_slots[i].material=bpy.data.materials[mat]
    assert light==a.art.study.signature(scene)
    for name,view in views.items():renders.append(dict(variant='R5 candidate',view=name,**s.render(scene,cam,'after-'+name+'.png',**view)))
    assert geometry==s.geometry_state(obs);assert attrs==r2.attributes(obs);assert props==a.object_properties(obs)
    assert materials=={k:s.material_state(bpy.data.materials[k]) for k in materials}
    cam.location=hero['position'];s.point(cam,hero['target']);cam.data.ortho_scale=hero['ortho']
    bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False,compress=True,relative_remap=False)
    bpy.ops.wm.open_mainfile(filepath=str(path));obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert geometry==s.geometry_state(obs);assert attrs==r2.attributes(obs);assert props==a.object_properties(obs)
    assert images=={k:val for k,val in r2.image_state().items() if k in images}
    assert materials=={k:s.material_state(bpy.data.materials[k]) for k in materials}
    v.update(candidateSha256=s.sha(path),views=views,reviewCameraCorrection=evidence,reviewCameraOnlyMaterialAndGeometryEqual=True)
    v['producerFiles'][Path(__file__).name]=s.sha(Path(__file__))
    a.write(out/'verification.json',v);a.write(out/'controls.json',dict(sourceSha256=v['sourceSha256'],views=views,renders=renders[:2]))
    a.write(out/'render-manifest.json',dict(manifest,renders=renders,reviewCameraCorrection=evidence))
    print('CAMERA REVIEW COMPLETE',key,flush=True)
if __name__=='__main__':main()
