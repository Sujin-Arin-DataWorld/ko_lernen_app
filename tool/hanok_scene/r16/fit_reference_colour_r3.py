"""Calibrate each material independently under the locked render-2 lighting."""
import bpy, sys, json, math
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
f=c.f;p=c.p;D=c.D
def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def main():
 native=D/'sarang-reference-colour.blend'
 verify=p.read(D/'verification.json');assert p.sha(native)==verify['nativeSha256']
 checks=p.read(D/'colour-check.json');cal={};second='--pass2' in sys.argv
 for k,v in checks.items():
  cal[k]=[max(.12,min(2.0,linear(a)/max(.001,linear(b)))) for a,b in zip(v['reference'][1],v['current'][1])]
 cal['column']=cal['lower_board'];cal['beam']=cal['apron'];cal['rafter']=cal['lower_board']
 cal['floor']=cal['lower_board'];cal['frame']=[.94,.94,.94];cal['lattice']=[.94,.94,.94]
 cal['endgrain']=cal['lower_board'];cal['door_panel']=[1,1,1]
 if second:
  cal['stone']=[1,1,.92]
  cal['tile']=[1,1,1]
  cal['frame']=[1,1,1];cal['lattice']=[1,1,1]
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 assert p.architecture(obs)==verify['geometry'];before=c.fixed_scene(sc)
 materials={sl.material for ob in obs for sl in ob.material_slots if sl.material and sl.material.get('referenceColourProfile')}
 changed=[]
 for mat in materials:
  key=mat['referenceColourProfile'];t=mat.node_tree
  if key not in cal:continue
  factors=cal[key]
  for n in t.nodes:
   if n.type!='VALTORGB' or 'Reference only ' not in n.label:continue
   rampkey=n.label.split('Reference only ')[-1]
   if rampkey not in cal:continue
   factors=cal[rampkey]
   for e in n.color_ramp.elements:
    # Inverse measured display error on this member family, never scene exposure.
    for axis in range(3):e.color[axis]=max(.001,min(1,e.color[axis]*factors[axis]))
   if rampkey=='stone' and not second:
    # Give the darkest stone body and pale mineral faces room in the same ramp.
    els=n.color_ramp.elements
    for axis in range(3):
     mid=els[1].color[axis]
     els[0].color[axis]=max(.012,mid+(els[0].color[axis]-mid)*3.3)
     els[-1].color[axis]=min(.85,mid+(els[-1].color[axis]-mid)*1.5)
    els[0].position=.18;els[1].position=.48;els[-1].position=.72
  if key=='stone' and second:
   # Replace large muddy colour patches with quieter, smaller mineral mottles.
   for n in t.nodes:
    if n.type=='TEX_NOISE' and 'Reference stone minerals' in n.label:n.inputs['Scale'].default_value=24
    if n.type=='MATH' and 'Reference mineral and block variation' in n.label:
     for link in n.inputs[0].links:link.from_node.inputs[1].default_value=.46
     for link in n.inputs[1].links:link.from_node.inputs[1].default_value=.28
  mat['referenceLocalCalibration']=json.dumps(factors)
  changed.append(dict(material=mat.name,profile=key,linearRgbFactor=factors))
 assert c.fixed_scene(sc)==before;assert p.architecture(obs)==verify['geometry']
 assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
 assert json.loads(json.dumps(c.fixed_scene(sc)))==p.read(D/'fixed-render-state.json')
 assert p.architecture([sc.objects[n] for n in lock['objects']])==verify['geometry']
 previous=p.read(D/'calibration.json') if (D/'calibration.json').exists() else None
 p.write(D/'calibration.json',dict(method='Independent material colour calibration from native preview measurements; fixed scene',factors=cal,changed=changed,previous=previous))
 verify['nativeSha256']=p.sha(native);verify['localMaterialCalibration']=True
 verify['render1And2Preserved']=c.preserve_check();p.write(D/'verification.json',verify)
 final='--final' in sys.argv
 sc.render.resolution_x=1800 if final else 1200;sc.render.resolution_y=1200 if final else 800
 p.write(D/('render.json' if final else 'preview.json'),p.render(sc,D,'render.png' if final else 'preview.png',96 if final else 48))
 assert c.preserve_check();print('LOCAL COLOUR FIT COMPLETE',flush=True)
if __name__=='__main__':main()
