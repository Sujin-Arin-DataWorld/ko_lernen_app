"""One bounded correction: deliberately placed marks on a beam and one column."""
import bpy, importlib.util, json, math, time
from pathlib import Path
OUT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('study',OUT/'brush_study.py');study=importlib.util.module_from_spec(spec);spec.loader.exec_module(study)
r2=study.r2;s=study.s;fix=study.fix;s.OUT=OUT
STROKES={
 'Projection.Numaru floor bearer':[
  dict(start=(11.05,-4.535,1.828),direction=(1,0,0),cross=(0,0,1),length=2.05,width=.047,pigment=.18),
  dict(start=(12.8,-4.535,1.914),direction=(1,0,0),cross=(0,0,1),length=1.6,width=.022,pigment=-.12),
  dict(start=(10.6,-4.535,1.779),direction=(1,0,0),cross=(0,0,1),length=1.1,width=.025,pigment=.12)],
 'Craft.Numaru continuous post 12.56':[
  dict(start=(12.58,-4.12,2.52),direction=(0,0,1),cross=(1,0,0),length=1.08,width=.033,pigment=.20),
  dict(start=(12.50,-4.12,2.95),direction=(0,0,1),cross=(1,0,0),length=.79,width=.018,pigment=-.12)]}

def mathnode(t,op,a,b=None):
 n=r2.node(t,'ShaderNodeMath','Placed brush | '+op);n.operation=op
 for value,inp in [(a,n.inputs[0]),(b,n.inputs[1])]:
  if value is None:continue
  if hasattr(value,'node'):t.links.new(value,inp)
  else:inp.default_value=value
 return n.outputs[0]

def vec(t,op,a,b):
 n=r2.node(t,'ShaderNodeVectorMath','Placed brush | '+op);n.operation=op
 for value,inp in [(a,n.inputs[0]),(b,n.inputs[1])]:
  if hasattr(value,'node'):t.links.new(value,inp)
  else:inp.default_value=value
 return n.outputs['Value' if op=='DOT_PRODUCT' else 'Vector']

def clamp(t,v):return mathnode(t,'MINIMUM',mathnode(t,'MAXIMUM',v,0),1)

def stroke(t,p,gray):
 geo=r2.node(t,'ShaderNodeNewGeometry','Placed brush | actual surface position')
 delta=vec(t,'SUBTRACT',geo.outputs['Position'],p['start'])
 u=mathnode(t,'DIVIDE',vec(t,'DOT_PRODUCT',delta,p['direction']),p['length'])
 v=mathnode(t,'DIVIDE',vec(t,'DOT_PRODUCT',delta,p['cross']),p['width'])
 # Tapered terminals, a slight drawn arc, ragged bristle silhouette from the atlas.
 wave=mathnode(t,'MULTIPLY',mathnode(t,'SINE',mathnode(t,'MULTIPLY',clamp(t,u),math.pi)),.15)
 v=mathnode(t,'ADD',v,wave)
 taper=mathnode(t,'POWER',mathnode(t,'MAXIMUM',mathnode(t,'SINE',mathnode(t,'MULTIPLY',clamp(t,u),math.pi)),0),.32)
 edge=mathnode(t,'MULTIPLY',mathnode(t,'SUBTRACT',gray,.5),.45)
 fill=clamp(t,mathnode(t,'MULTIPLY',mathnode(t,'SUBTRACT',mathnode(t,'ADD',taper,edge),mathnode(t,'ABSOLUTE',v)),8))
 extent=mathnode(t,'MULTIPLY',mathnode(t,'GREATER_THAN',u,0),mathnode(t,'LESS_THAN',u,1))
 return mathnode(t,'MULTIPLY',mathnode(t,'MULTIPLY',fill,extent),p['pigment'])

def main():
 start=time.monotonic();source=OUT/'sarang-palette-brush-study.blend';source_sha=s.sha(source)
 bpy.ops.wm.open_mainfile(filepath=str(source));scene=bpy.context.scene
 names=[o.name for o in scene.objects if o.type=='MESH'];objs=fix.originals(names)
 geometry=s.geometry_state(objs);attrs=r2.attributes(objs);images=r2.image_state();plaques=fix.plaque_state();lighting=study.signature(scene)
 for name,strokes in STROKES.items():
  ob=bpy.data.objects[name]
  for sl in ob.material_slots:
   mat=sl.material.copy();mat.name='PLACED brush | '+name+' | '+sl.material.name;t=mat.node_tree
   gray=study.labeled(t,'R4 neutral marks only, no hue shift').outputs[0]
   pigment=1
   for p in strokes:pigment=mathnode(t,'ADD',pigment,stroke(t,p,gray))
   for b in [n for n in t.nodes if n.type=='BSDF_PRINCIPLED']:
    old=b.inputs['Base Color'].links[0].from_socket
    color=r2.mix(t,old,pigment,1,'Selected broad paint passes in existing hue','MULTIPLY');t.links.new(color,b.inputs['Base Color'])
   sl.link='OBJECT';sl.material=mat
 native=OUT/'sarang-palette-brush-selective.blend';bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(native),check_existing=False);bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene
 assert geometry==s.geometry_state(fix.originals(names));assert attrs==r2.attributes(fix.originals(names));assert images==r2.image_state();assert plaques==fix.plaque_state();assert lighting==study.signature(scene);assert source_sha==s.sha(source)
 study.write('selective-verification.json',dict(passed=True,savedNativeReopened=True,all711ExistingMeshGeometryUvsTransformsAttributesModifiersEqual=True,plaquesAndPackedImagesUnchanged=True,lightingUnchanged=True,
  native=native.name,nativeSha256=s.sha(native),sourceNative=source.name,sourceSha256=source_sha,addedMeshes=0,placedStrokeObjectCount=len(STROKES),placedStrokes=STROKES,neutralPigmentOnly=True,candidateApproved=False,appIntegrated=False,glbConverted=False))
 renders=[]
 for name in ['numaru','hero']:
  renders.append(dict(view=name,**s.render(scene,scene.camera,'selective-'+name+'.png',**study.VIEWS[name])))
 study.write('selective-render-manifest.json',dict(renders=renders,matchedBaselineLightCamera=True,seconds=round(time.monotonic()-start,1)))
 print('SELECTIVE BRUSH STUDY COMPLETE',flush=True)
if __name__=='__main__':main()
