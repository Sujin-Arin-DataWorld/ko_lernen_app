"""R3-based, three-value native brush layering; source architecture is immutable."""
import bpy,importlib.util,json,time,sys,shutil
from pathlib import Path
import numpy as np
OUT=Path(__file__).resolve().parent
R4=OUT.parent/'lookdev-sarang-r4'
spec=importlib.util.spec_from_file_location('study',R4/'brush_study.py');study=importlib.util.module_from_spec(spec);spec.loader.exec_module(study)
fix=study.fix;r2=study.r2;s=study.s;s.OUT=OUT
NATIVE=study.NATIVE;EXPECTED=study.EXPECTED
VIEWS={
 'numaru':study.VIEWS['numaru'],
 'eaves':study.VIEWS['eaves'],
 'hero':study.VIEWS['hero'],
 'reverse':dict(position=(21,12,8),target=(12,-1,2.7),ortho=7,resolution=(1100,950))}
PROFILES={
 'wood':dict(base=.96,mid=1.00,light=1.12,darkPaint=.60,midPaint=.94,lightPaint=1.25,coverage=.84),
 'lattice':dict(base=.97,mid=1.,light=1.06,darkPaint=.76,midPaint=.97,lightPaint=1.14,coverage=.65),
 'tile':dict(base=.96,mid=1.,light=1.07,darkPaint=.70,midPaint=.96,lightPaint=1.15,coverage=.80),
 'stone':dict(base=.98,mid=1.,light=1.06,darkPaint=.76,midPaint=.97,lightPaint=1.13,coverage=.72),
 'plaster':dict(base=.99,mid=1.,light=1.015,darkPaint=.92,midPaint=.99,lightPaint=1.04,coverage=.50),
 'paper':dict(base=1.,mid=1.,light=1.005,darkPaint=.975,midPaint=1.,lightPaint=1.015,coverage=.32),
 'endgrain':dict(base=.99,mid=1.,light=1.025,darkPaint=.90,midPaint=.99,lightPaint=1.04,coverage=.40),
 'pigment':dict(base=1.,mid=1.,light=1.01,darkPaint=.97,midPaint=1.,lightPaint=1.02,coverage=.32)}

def write(name,data):
 (OUT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def mathn(t,op,a,b=None,label=None):
 n=r2.node(t,'ShaderNodeMath',label or 'R5 '+op);n.operation=op
 for val,slot in [(a,n.inputs[0]),(b,n.inputs[1])]:
  if val is None:continue
  if hasattr(val,'node'):t.links.new(val,slot)
  else:slot.default_value=val
 return n.outputs[0]

def gray_image_stats(image):
 ar=np.empty(len(image.pixels),np.float32);image.pixels.foreach_get(ar);w,h=image.size;ar=ar.reshape(h,w,4)
 stats={}
 for k,(x,y) in dict(wood=(0,1),tile=(1,1),stone=(0,0),plaster=(1,0)).items():
  rgb=ar[int(h*(y*.5+.03)):int(h*(y*.5+.47)),int(w*(x*.5+.03)):int(w*(x*.5+.47)),:3]
  v=rgb@np.array([.2126,.7152,.0722]);stats[k]=[float(q) for q in np.quantile(v,[.08,.18,.30,.72,.88,.97])]
 return stats

def pigment(t,base,mult,alpha,label):
 n=r2.mix(t,base,(mult,mult,mult,1),1,label+' pigment','MULTIPLY')
 # Each layer remains independently editable, including its coverage.
 blend=r2.node(t,'ShaderNodeMixRGB',label);t.links.new(base,blend.inputs[1]);t.links.new(n,blend.inputs[2])
 if hasattr(alpha,'node'):t.links.new(alpha,blend.inputs[0])
 else:blend.inputs[0].default_value=alpha
 return blend.outputs[0]

def apply(mat,category,atlas,stats,wood,normalizer,source_mean):
 new=mat.copy();new.name='PAINT R5 '+category+' | '+mat.name.split(' | ',1)[-1];new['r5_role']=category
 t=new.node_tree
 if category in ['wood','lattice']:
  im=study.labeled(t,'Generated hand painted wood pigment')
  assert im and im.type=='TEX_IMAGE'
  outputs=[l.to_socket for l in list(im.outputs['Color'].links)]
  im.image=wood;im.label='R5 authored broad timber colour planes'
  calibrated=r2.mix(t,im.outputs['Color'],normalizer,1,'R5 preserve source pigment mean without averaging','MULTIPLY')
  for dest in outputs:t.links.new(calibrated,dest)
  scale=study.labeled(t,'Hand painted timber physical scale')
  if scale:scale.inputs[1].default_value=(1.3,1.2,1) if category=='wood' else (3.4,.9,1)
  for n in t.nodes:
   if n.type=='BUMP' and n.label in ['Shallow brush ridges and planed fibres','Fine directional open pores']:
    n.inputs['Strength'].default_value*=.28
 # Reuse the existing source UV address, never edit UVs or average source colours.
 _,gray=study.mask(t,category,atlas)
 gray.node.label='R5 source brush alpha'
 panel='wood' if category in ['wood','lattice','endgrain'] else 'plaster' if category in ['paper','pigment'] else category
 a,b,c,d,e,f=stats[panel]
 if category in ['wood','lattice']:
  # Spatially broad stroke alpha drives colour planes. Do not posterize fine grain.
  tone=lambda value:tuple(source_mean[i]*value for i in range(3))+(1,)
  planes=r2.ramp(t,gray,[(a,tone(.78)),(b,tone(.78)),(c,tone(1.0)),(d,tone(1.0)),(e,tone(1.28)),(f,tone(1.28))],'R5 broad DARK MID LIGHT pigment planes')
  paint=r2.mix(t,calibrated,planes,.80 if category=='wood' else .45,'R5 broad planes with residual material tooth')
  grade=study.labeled(t,'Warm maintained chestnut pigment, restrained orange')
  assert grade;t.links.new(paint,grade.inputs['Color'])
 dark=r2.ramp(t,gray,[(a,1),(b,0)],'R5 DARK paint mask')
 mid=r2.ramp(t,gray,[(b,0),(c,1),(d,1),(e,0)],'R5 MID paint mask')
 bright=r2.ramp(t,gray,[(e,0),(f,1)],'R5 LIGHT paint mask')
 profile=dict(PROFILES[category])
 if category in ['wood','lattice']:
  profile.update(base=.99,mid=1.,light=1.025,darkPaint=.91,midPaint=1.,lightPaint=1.07)
 masks=[mathn(t,'MULTIPLY',m,profile['coverage'],'R5 '+label+' coverage') for label,m in [('dark',dark),('mid',mid),('light',bright)]]
 for bsdf in [n for n in t.nodes if n.type=='BSDF_PRINCIPLED']:
  original=bsdf.inputs['Base Color'].links[0].from_socket if bsdf.inputs['Base Color'].is_linked else None
  if original is None:
   rgb=r2.node(t,'ShaderNodeRGB','R5 original constant pigment');rgb.outputs[0].default_value=bsdf.inputs['Base Color'].default_value;original=rgb.outputs[0]
  # Three fill layers establish a narrow value family without baking scene shadows.
  color=pigment(t,original,profile['base'],1,'R5 FILL dark base')
  color=pigment(t,color,profile['mid']/profile['base'],.82,'R5 FILL dominant midtone')
  color=pigment(t,color,profile['light'],mathn(t,'MULTIPLY',bright,.28),'R5 FILL restrained light')
  # Separate paint layers carry selective, broken, visible decisions.
  color=pigment(t,color,profile['darkPaint'],masks[0],'R5 PAINT dark strokes')
  color=pigment(t,color,profile['midPaint'],masks[1],'R5 PAINT mid strokes')
  color=pigment(t,color,profile['lightPaint'],masks[2],'R5 PAINT light strokes')
  t.links.new(color,bsdf.inputs['Base Color'])
  # Keep source relief; colour, rather than more surface noise, carries the brushwork.
 new['candidate_status']='unapproved R5 three-value brush candidate';new['no_source_colour_averaging']=True
 return new

def plaque_state():return fix.plaque_state()

def placed_passes():
 # Deliberate selected placements, not a repeated all-surface texture treatment.
 spec=importlib.util.spec_from_file_location('placed',R4/'selective_strokes.py');placed=importlib.util.module_from_spec(spec);spec.loader.exec_module(placed);s.OUT=OUT
 records={}
 for name,original_strokes in placed.STROKES.items():
  strokes=[dict(v) for v in original_strokes]
  for p in strokes:
   p['width']*=1.25;p['pigment']*=1.7
  records[name]=strokes
  for sl in bpy.data.objects[name].material_slots:
   mat=sl.material.copy();mat.name='PAINT R5 selected | '+name+' | '+sl.material.name;t=mat.node_tree
   gray=study.labeled(t,'R5 source brush alpha').outputs[0]
   factor=1
   for p in strokes:factor=placed.mathnode(t,'ADD',factor,placed.stroke(t,p,gray))
   for bsdf in [n for n in t.nodes if n.type=='BSDF_PRINCIPLED']:
    old=bsdf.inputs['Base Color'].links[0].from_socket
    color=r2.mix(t,old,factor,1,'R5 PAINT selected tapered overlapping passes','MULTIPLY');t.links.new(color,bsdf.inputs['Base Color'])
   sl.link='OBJECT';sl.material=mat
 return records

def render_controls(scene,views):
 result=[]
 oldmanifest=json.loads((R4/'render-manifest.json').read_text(encoding='utf-8'))
 for name in views:
  dest=OUT/('before-'+name+'.png')
  if name in ['numaru','hero']:
   src=(OUT.parent/'lookdev-sarang-r3'/'fixed-numaru.png') if name=='numaru' else R4/'before-hero.png'
   if name=='hero':assert any(x.get('file')==src.name and x['sha256']==s.sha(src) and x['variant']=='fix checkpoint' for x in oldmanifest['renders'])
   shutil.copy2(src,dest);result.append(dict(view=name,variant='R3 fix checkpoint',file=dest.name,sha256=s.sha(dest),**VIEWS[name]))
  elif dest.exists() and '--reuse-controls' in sys.argv:
   result.append(dict(view=name,variant='R3 fix checkpoint',file=dest.name,sha256=s.sha(dest),**VIEWS[name]))
  else:result.append(dict(view=name,variant='R3 fix checkpoint',**s.render(scene,scene.camera,dest.name,**VIEWS[name])))
 return result

def main():
 start=time.monotonic();assert s.sha(NATIVE)==EXPECTED
 bpy.ops.wm.open_mainfile(filepath=str(NATIVE));scene=bpy.context.scene
 objs=[o for o in scene.objects if o.type=='MESH'];names=[o.name for o in objs];assert len(objs)==711
 geometry=s.geometry_state(objs);attrs=r2.attributes(objs);images=r2.image_state();plaques=plaque_state();lighting=study.signature(scene)
 originals={sl.material.name:sl.material for o in objs for sl in o.material_slots if sl.material};material_state={k:s.material_state(m) for k,m in originals.items()}
 scene.cycles.samples=40;scene.cycles.seed=217;scene.render.threads=8
 views=['numaru','eaves','hero','reverse'];renders=render_controls(scene,views)
 atlas=bpy.data.images.load(str(OUT/'textures'/'material-brush-atlas-r1.png'),check_existing=True);atlas.colorspace_settings.name='Non-Color';atlas.pack();stats=gray_image_stats(atlas)
 wood=bpy.data.images.load(str(OUT/'textures'/'wood-colour-planes-r1.png'),check_existing=True);wood.pack()
 oldmean=study.mean_image(bpy.data.images['handpainted-pine-r1.png']);newmean=study.mean_image(wood)
 normalizer=tuple(oldmean[i]/newmean[i] for i in range(3))+(1,)
 replacements={};coverage={};changes=[]
 for ob in objs:
  if ob.name in s.PLAQUES:continue
  for sl in ob.material_slots:
   mat=sl.material;category=study.role(mat) if mat else None;assert category,ob.name
   coverage.setdefault(category,set()).add(ob.name);key=(mat.name,category)
   if key not in replacements:
    new=apply(mat,category,atlas,stats,wood,normalizer,oldmean);replacements[key]=new;changes.append(dict(source=mat.name,candidate=new.name,category=category))
   sl.link='OBJECT';sl.material=replacements[key]
 selected=placed_passes()
 assert material_state=={k:s.material_state(m) for k,m in originals.items()}
 assert geometry==s.geometry_state(objs);assert attrs==r2.attributes(objs);assert plaques==plaque_state();assert lighting==study.signature(scene)
 hero=VIEWS['hero'];scene.camera.location=hero['position'];s.point(scene.camera,hero['target']);scene.camera.data.ortho_scale=hero['ortho'];scene.render.resolution_x,scene.render.resolution_y=hero['resolution']
 path=OUT/'sarang-three-value-brush-candidate.blend';bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False)
 bpy.ops.wm.open_mainfile(filepath=str(path));scene=bpy.context.scene
 assert geometry==s.geometry_state(fix.originals(names));assert attrs==r2.attributes(fix.originals(names));assert plaques==plaque_state();assert lighting==study.signature(scene)
 assert images=={k:v for k,v in r2.image_state().items() if k in images};assert s.sha(NATIVE)==EXPECTED
 write('verification.json',dict(passed=True,savedNativeReopened=True,meshCount=711,allGeometryUvsTransformsAttributesModifiersEqual=True,plaquesEqual=True,sourceImagesPackedBytesEqual=True,
  sourceMaterialsUnchanged=True,lightingAndViewTransformEqual=True,sourceSha256=EXPECTED,candidateNative=path.name,candidateSha256=s.sha(path),newMeshes=0,
  sourceColourAveraging=False,uniformAverageColourWash=False,woodThreeValueRemapping=True,woodResidualPigmentSignal=.20,latticeResidualPigmentSignal=.55,
  hueGrading=False,bakedSceneLighting=False,externalPacksInstalled=False,candidateApproved=False,glbConverted=False,appIntegrated=False,
  coverage={k:len(v) for k,v in coverage.items()},baseProfiles=PROFILES,
  effectiveWoodAndLatticeProfile=dict(base=.99,mid=1.,light=1.025,darkPaint=.91,midPaint=1.,lightPaint=1.07),
  alphaQuantiles=stats,selectedMemberPaintPasses=selected,
  woodPigmentLinearMeanBefore=oldmean,woodPigmentLinearMeanGenerated=newmean,woodPigmentMeanCalibrationMultiplier=normalizer))
 write('material-changes.json',changes)
 for name in views:
  renders.append(dict(view=name,variant='R5 three-value brush candidate',**s.render(scene,scene.camera,'after-'+name+'.png',**VIEWS[name])))
  write('render-manifest.json',dict(renders=renders,matchedCameraLights=True,samples=40,complete=len(renders)==8,seconds=round(time.monotonic()-start,1)))
 print('R5 SAVED REOPENED VERIFIED AND RENDERED',time.monotonic()-start,flush=True)

if __name__=='__main__':main()
