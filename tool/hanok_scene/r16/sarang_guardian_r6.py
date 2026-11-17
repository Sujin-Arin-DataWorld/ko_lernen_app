import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-guardian-r6'

def simple(name,color,rough=.7,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;b=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');b.inputs['Base Color'].default_value=f.rgb(color);b.inputs['Roughness'].default_value=rough;b.inputs['Metallic'].default_value=metal
 return m

def bounds(o):
 pts=[o.matrix_world@Vector(v) for v in o.bound_box]
 return [min(q[i] for q in pts) for i in range(3)],[max(q[i] for q in pts) for i in range(3)]

def stone(old):
 m=old.copy();m.name='HS R6 mineral stone | '+old.name;t=m.node_tree;bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED')
 co=f.node(t,'ShaderNodeNewGeometry','R6 mineral metric').outputs['Position']
 seed=p.craft.illustration.member_value(t)
 base=f.ramp(t,seed,[(0,f.rgb('AB9980')),(.5,f.rgb('C4B398')),(1,f.rgb('D6C9B3'))],'R6 individual limestone-like pigments')
 n=f.noise(t,co,5.4,2,'R6 large broken mineral patches')
 patch=f.ramp(t,n,[(.26,f.rgb('78644D')),(.38,f.rgb('A48C69')),(.45,f.rgb('C4AF8C')),(.50,f.rgb('DCD0B9')),(.72,f.rgb('E2D9C8'))],'R6 visible irregular ochre patches')
 col=f.mix(t,base,patch,.64,'R6 actual mineral pigment layers')
 pores=f.noise(t,co,36,1.5,'R6 sparse natural pits')
 pit=f.ramp(t,pores,[(.26,(.19,.15,.11,1)),(.33,(.55,.48,.38,1)),(.40,(1,1,1,1))],'R6 dark mineral pores')
 col=f.mix(t,col,pit,.7,'R6 local pit pigment','MULTIPLY')
 f.attach(t,bs.inputs['Base Color'],f.contact(t,col,'stone'));f.normal(t,bs,pit,.004,.016,.23)
 m['guardian6']='stone';return m

def plaque_material(im,name,coords=None):
 m=simple(name,'3B665F',.64,.25);t=m.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED')
 tex=f.node(t,'ShaderNodeTexImage','Approved Dokkaebi relief artwork');tex.image=im;tex.extension='EXTEND'
 if coords:
  lo,hi,axis=coords
  co=f.node(t,'ShaderNodeNewGeometry','Plaque world surface').outputs['Position']
  sub=f.node(t,'ShaderNodeVectorMath','Plaque local origin');sub.operation='SUBTRACT';t.links.new(co,sub.inputs[0]);sub.inputs[1].default_value=lo
  sep=f.node(t,'ShaderNodeSeparateXYZ','Plaque axes');t.links.new(sub.outputs[0],sep.inputs[0])
  uv=f.node(t,'ShaderNodeCombineXYZ','Face projection')
  t.links.new(f.scalar(t,'DIVIDE',sep.outputs[axis],hi[axis]-lo[axis]),uv.inputs['X']);t.links.new(f.scalar(t,'DIVIDE',sep.outputs['Z'],hi[2]-lo[2]),uv.inputs['Y'])
  t.links.new(uv.outputs[0],tex.inputs['Vector'])
 col=f.mix(t,f.rgb('365B56'),tex.outputs['Color'],tex.outputs['Alpha'],'Relief pigment inside face')
 t.links.new(col,bs.inputs['Base Color'])
 g=f.gray(t,tex.outputs['Color'],'Relief fine cavity');f.normal(t,bs,g,.002,.0004,.25)
 return m

def main():
 src=P/'sarang-surface-r5/sarang-surface-r5.blend';srcsha=p.sha(src)
 bpy.ops.wm.open_mainfile(filepath=str(src));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']];before=p.architecture(obs);lighting=c.fixed_scene(sc)
 unchanged={};cache={}
 for r in p.read(P/'sarang/material-inventory.json'):
  o=sc.objects[r['object']];sl=o.material_slots[r['slot']]
  if r['role']=='stone' and not r['preserved']:
   if sl.material.name not in cache:cache[sl.material.name]=stone(sl.material)
   sl.link='OBJECT';sl.material=cache[sl.material.name]
  else:unchanged[(o.name,r['slot'])]=p.s.material_state(sl.material)
 additions=bpy.data.collections.new('HS6 Guardian story and contact repair');sc.collection.children.link(additions)
 added=[];contact=[]
 def move(o):
  for col in list(o.users_collection):col.objects.unlink(o)
  additions.objects.link(o);added.append(o.name)
 for i in range(2):
  parent=sc.objects['V25.upper entry slab '+str(i)];lo,hi=bounds(parent)
  # Existing upper slab undersides are at 1.28; landing paving reaches 1.1236.
  bottom=1.105;top=1.285
  bpy.ops.mesh.primitive_cube_add(size=1,location=((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,(bottom+top)/2));o=bpy.context.object;o.name='HS6 seated entry bedding '+str(i)
  o.dimensions=(hi[0]-lo[0]-.035,hi[1]-lo[1]-.025,top-bottom);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  be=o.modifiers.new('Soft dressed contact edge','BEVEL');be.width=.008;be.segments=3
  o.data.materials.append(next(sl.material for sl in parent.material_slots if sl.material));o['source_member']=parent.name;o['construction_parent']=parent.name;move(o)
  contact.append(dict(parent=parent.name,oldUnderside=lo[2],beddingBottom=bottom,beddingTop=top,slabOverlap=top-lo[2]))
 im=bpy.data.images.load(str(D/'guardian.png'));im.pack()
 edge=simple('HS6 patinated guardian edges','446760',.67,.28)
 # Front face of the existing numaru ridge-end ornament receives surface art.
 target=sc.objects['Sarang.numaru roof end ornament.original patterned face'];lo,hi=bounds(target)
 mat=plaque_material(im,'HS6 guardian ridge face',(lo,hi,0))
 for sl in target.material_slots:sl.link='OBJECT';sl.material=mat
 edgeob=sc.objects['Sarang.numaru roof end ornament.finial edge']
 for sl in edgeob.material_slots:sl.link='OBJECT';sl.material=edge
 excluded={target.name,edgeob.name}
 # Two small removable relief plaques at the circled corner caps. Native meshes,
 # alpha-shaped silhouettes; existing eave/cap architecture remains intact.
 w,h=im.size;pix=list(im.pixels);nx=60;nz=78
 def alpha(u,v):return pix[4*(min(h-1,int(v*(h-1)))*w+min(w-1,int(u*(w-1))))+3]
 verts=[((i/nx-.5)*.26,0,j/nz*.34) for j in range(nz+1) for i in range(nx+1)]
 faces=[]
 for j in range(nz):
  for i in range(nx):
   if alpha((i+.5)/nx,(j+.5)/nz)>.7:
    a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
 mesh=bpy.data.meshes.new('HS6 leaf relief surface');mesh.from_pydata(verts,[],faces);mesh.update();uv=mesh.uv_layers.new(name='Guardian artwork')
 for poly in mesh.polygons:
  for li in poly.loop_indices:
   vi=mesh.loops[li].vertex_index;uv.data[li].uv=(vi%(nx+1)/nx,vi//(nx+1)/nz)
 mesh.materials.append(plaque_material(im,'HS6 corner guardian faces'))
 for i,(x,y,z) in enumerate([(9.17,-5.43,4.82),(15.93,-5.49,4.82)]):
  o=bpy.data.objects.new('HS6 guardian eave seal '+str(i),mesh);additions.objects.link(o);o.location=(x,y,z)
  solid=o.modifiers.new('Thin relief clay backing','SOLIDIFY');solid.thickness=.018
  o['construction_parent']='Sarang.numaru roof.hip round tile ends';o['story_layer']='Dokkaebi guardian fantasy addition';added.append(o.name)
 assert p.architecture(obs)==before;assert c.fixed_scene(sc)==lighting
 assert all(p.s.material_state(sc.objects[n].material_slots[i].material)==state for (n,i),state in unchanged.items() if n not in excluded)
 assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
 bpy.context.preferences.filepaths.save_version=0;sc.render.resolution_x=1800;sc.render.resolution_y=1200
 native=D/'sarang-guardian-r6.blend';assert not native.exists();bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 p.write(D/'verification.json',dict(source=str(src),sourceSha256=srcsha,native=native.name,nativeSha256=p.sha(native),geometry=before,architecture711Preserved=True,processBindingCount=711,sceneLightingExposurePreserved=True,unchangedMaterialsExceptStoneAndGuardian=True,additions=added,contact=contact,ornamentTarget=target.name,userApproved=False,runtimeIntegrated=False))
 sc.render.resolution_x=1200;sc.render.resolution_y=800;p.write(D/'preview.json',p.render(sc,D,'preview.png',48))
 print('GUARDIAN R6 PREVIEW DONE',flush=True)
if __name__=='__main__':main()
