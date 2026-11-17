"""Closed native roof cap using the user's exact front and side design.

Image-derived displacement is an approximation, not scanned depth. It is
combined with bounded broad facial form and is tested without pigment.
"""
import bpy,math,numpy as np,bmesh
from pathlib import Path

P=Path(__file__).resolve().parent
ROOT=Path('C:/Users/vjinn/.codex/generated_images/01a1501f-48a0-72b0-952f-b9030f42cafe')

def array(im):
 a=np.empty(im.size[0]*im.size[1]*4,np.float32);im.pixels.foreach_get(a);return a.reshape(im.size[1],im.size[0],4)

def smooth(a,rounds=1):
 for _ in range(rounds):
  a=(a*4+np.roll(a,1,0)+np.roll(a,-1,0)+np.roll(a,1,1)+np.roll(a,-1,1))/8
 return a

def make_material(name,im=None,side=False):
 import sarang_reference_colour_r3 as c
 f=c.f;m=bpy.data.materials.new(name);m.use_nodes=True;t=m.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED')
 if im:
  tex=t.nodes.new('ShaderNodeTexImage');tex.image=im;tex.extension='EXTEND';tex.label='User-authored full surface design; not a separate image plane'
  multiply=t.nodes.new('ShaderNodeMixRGB');multiply.blend_type='MULTIPLY';multiply.inputs[0].default_value=1;multiply.inputs[2].default_value=(.50,.56,.51,1);t.links.new(tex.outputs['Color'],multiply.inputs[1]);t.links.new(multiply.outputs[0],bs.inputs['Base Color'])
 else:bs.inputs['Base Color'].default_value=f.rgb('3D5248')
 bs.inputs['Metallic'].default_value=.24;bs.inputs['Roughness'].default_value=.70;bs.inputs['Specular IOR Level'].default_value=.27
 texcoord=t.nodes.new('ShaderNodeNewGeometry');noise=t.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=700;noise.inputs['Detail'].default_value=3;t.links.new(texcoord.outputs['Position'],noise.inputs['Vector'])
 bump=t.nodes.new('ShaderNodeBump');bump.inputs['Distance'].default_value=.00016;bump.inputs['Strength'].default_value=.35;t.links.new(noise.outputs['Fac'],bump.inputs['Height']);t.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
 return m

def build(sc,small_caps=False):
 front=bpy.data.images.load(str(ROOT/'exec-6dc3e9d7-0263-4476-93a4-e250cbe75c2e.png'),check_existing=True);front.pack()
 side=bpy.data.images.load(str(ROOT/'exec-82363520-c4c8-4ac2-9137-e936bc4cdbf6.png'),check_existing=True);side.pack()
 a=array(front);sa=array(side);h,w=a.shape[:2];alpha=a[:,:,3]>.5;ys,xs=np.where(alpha);xmin,xmax=int(xs.min()),int(xs.max());ymin,ymax=int(ys.min()),int(ys.max())
 lum=a[:,:,:3]@np.array([.2126,.7152,.0722]);slum=sa[:,:,:3]@np.array([.2126,.7152,.0722])
 # Grid samples the exact source silhouette, including the large lower arch.
 nx=384;ny=560;u=np.linspace(0,1,nx+1);v=np.linspace(0,1,ny+1);U,V=np.meshgrid(u,v)
 TX=xmin+U*(xmax-xmin);TY=ymin+V*(ymax-ymin);X=np.rint(TX).astype(int);Y=np.rint(TY).astype(int)
 L=lum[Y,X];low,high=np.percentile(lum[alpha],[10,94]);L=np.clip((L-low)/(high-low),0,1)
 # Remove sub-pixel pigment noise before defining carved forms.
 L=smooth(L,5);coarse=smooth(L,28)
 fields=np.load(P/'guardian-depth-fields-r12.npz');region=fields['front'][Y,X]
 def ga(x,z,wx,wz):return np.exp(-2*((U-x)/wx)**2-2*((V-z)/wz)**2)
 # Overall face/head volume remains low relief integrated in the same cap.
 macro=.004*ga(.5,.395,.29,.16)+.003*ga(.5,.59,.34,.19)
 macro+=.005*ga(.5,.398,.075,.044)
 for xx in [.39,.61]:macro-=.0035*ga(xx,.445,.065,.035)
 macro-=.0045*ga(.5,.335,.115,.028)
 detail_mask=np.clip(ga(.5,.63,.38,.18)+ga(.5,.50,.23,.08),0,1)
 depth=.0015+.010*region+.003*coarse+macro+.004*fields['front_lines'][Y,X]*detail_mask
 depth=np.maximum(depth,.001)
 verts=np.stack(((U-.5)*.30,-3.544-depth,6.66+.43*V),axis=-1).reshape(-1,3).tolist();uvs=np.stack((TX/(w-1),TY/(h-1)),axis=-1).reshape(-1,2).tolist();faces=[];matids=[]
 # Retain source alpha cells. Image alpha never controls rendered opacity.
 for j in range(ny):
  for i in range(nx):
   px=int((X[j,i]+X[j+1,i+1])/2);py=int((Y[j,i]+Y[j+1,i+1])/2)
   if alpha[py,px]:
    k=j*(nx+1)+i;faces.append((k,k+1,k+nx+2,k+nx+1));matids.append(0)
 used=sorted({q for f in faces for q in f});mapping={q:i for i,q in enumerate(used)};verts=[verts[i] for i in used];uvs=[uvs[i] for i in used];faces=[tuple(mapping[i] for i in f) for f in faces]
 edges={}
 for f in faces:
  for a0,b0 in zip(f,f[1:]+f[:1]):
   key=tuple(sorted((a0,b0)));edges[key]=None if key in edges else (a0,b0)
 nextv={e[0]:e[1] for e in edges.values() if e is not None}
 loops=[]
 while nextv:
  start=next(iter(nextv));loop=[start];q=start
  while q in nextv:
   q=nextv.pop(q)
   if q==start:break
   loop.append(q)
  loops.append(loop)
 n=len(verts);frontfaces=list(faces);verts.extend([(x,-3.436,z) for x,y,z in list(verts)]);uvs.extend(list(uvs));faces.extend([tuple(i+n for i in reversed(f)) for f in frontfaces]);matids.extend([2]*len(frontfaces));side_uv=[]
 slum=smooth(fields['side'],14)
 def sample_side(u,v):
  xx=float(np.clip(u,0,1))*(slum.shape[1]-1);yy=float(np.clip(v,0,1))*(slum.shape[0]-1)
  ix=int(xx);iy=int(yy);jx=min(ix+1,slum.shape[1]-1);jy=min(iy+1,slum.shape[0]-1);fx=xx-ix;fy=yy-iy
  return float((slum[iy,ix]*(1-fx)+slum[iy,jx]*fx)*(1-fy)+(slum[jy,ix]*(1-fx)+slum[jy,jx]*fx)*fy)
 for loop in loops:
  positions=np.array([[verts[i][0],verts[i][2]] for i in loop]);seg=np.linalg.norm(np.roll(positions,-1,axis=0)-positions,axis=1);dist=np.r_[0,np.cumsum(seg)];length=len(loop);nd=112;rings=[loop]
  weights=np.exp(-.5*(np.arange(-36,37)/12)**2);weights/=weights.sum()
  clean=sum(weight*np.roll(positions,int(k),axis=0) for k,weight in zip(range(-36,37),weights))
  # Side motif keeps its physical aspect. The middle strip spans the depth.
  repeat=.43
  side_width_fraction=.108/(.43*sa.shape[1]/sa.shape[0])
  def uu(t):return .5+(t-.5)*side_width_fraction
  def vv(k):return float(np.clip((positions[k%length,1]-6.66)/.43,0,1))
  for j in range(1,nd):
   t=j/nd;row=[]
   for k,idx in enumerate(loop):
    x,y,z=verts[idx];tangent=clean[(k+20)%length]-clean[(k-20)%length];normal=np.array([tangent[1],-tangent[0]]);normal/=max(np.linalg.norm(normal),1e-8)
    blend=math.sin(math.pi*t);x=x*(1-blend)+clean[k,0]*blend;z=z*(1-blend)+clean[k,1]*blend
    displacement=(sample_side(uu(t),vv(k))-.25)*.0035*math.sin(math.pi*t)**.6
    row.append(len(verts));verts.append((x+normal[0]*displacement,y*(1-t)-3.436*t,z+normal[1]*displacement));uvs.append((uu(t),vv(k)))
   rings.append(row)
  rings.append([i+n for i in loop])
  for j in range(nd):
   for k in range(length):
    q=(k+1)%length;faces.append((rings[j][q],rings[j][k],rings[j+1][k],rings[j+1][q]));matids.append(1);side_uv.append((len(faces)-1,((uu(j/nd),vv(q)),(uu(j/nd),vv(k)),(uu((j+1)/nd),vv(k)),(uu((j+1)/nd),vv(q)))))
 mesh=bpy.data.meshes.new('HS12 exact design integrated closed relief');mesh.from_pydata(verts,[],faces);mesh.update();uv=mesh.uv_layers.new(name='Exact user design continuous body UV')
 for f in mesh.polygons:
  f.material_index=matids[f.index];f.use_smooth=True
  for li in f.loop_indices:uv.data[li].uv=uvs[mesh.loops[li].vertex_index]
 for fi,coords in side_uv:
  for li,co in zip(mesh.polygons[fi].loop_indices,coords):uv.data[li].uv=co
 for m in [make_material('HS12 exact front ceramic bronze design',front),make_material('HS12 exact side cloud relief',side,True),make_material('HS12 fired ceramic back')]:mesh.materials.append(m)
 col=bpy.data.collections.new('HS12 exact measured guardian');sc.collection.children.link(col);o=bpy.data.objects.new('HS12 main exact guardian cap',mesh);col.objects.link(o);o.location.x=12.56;o['construction_parent']='Sarang.numaru roof end ornament.original patterned face';o['design_source']=str(ROOT/'exec-6dc3e9d7-0263-4476-93a4-e250cbe75c2e.png');o['depth_method']='multiscale image-derived approximation plus broad sculpted face; verify clay';o['not_image_plane']=True
 for old in sc.objects:
  if old.name.startswith(('HS9 ','HS8 ','HS6 guardian eave','HS11 ')):old.hide_render=True;old.hide_set(True)
 # Native round eave caps remain at their actual 144mm size; no oversize leaf.
 import guardian_sculpt_r11 as g
 roof_material=next((slot.material for ob in sc.objects if ob.type=='MESH' and ob.name.startswith('Sarang.numaru roof') for slot in ob.material_slots if slot.material and slot.material.get('referenceColourProfile')=='tile'),None)
 if roof_material:
  gray=roof_material.copy();gray.name='HS12 charcoal mount'
 else:
  import sarang_reference_colour_r3 as c
  gray=c.reset_colour(g.make_material('HS12 charcoal mount','303844',0),'tile');gray.name='HS12 charcoal mount'
 for old in list(sc.objects):
  if old.name.startswith('Sarang.numaru roof.ridge stack'):
   clone=old.copy();clone.data=old.data.copy();clone.name='HS12 ridge finish '+old.name;col.objects.link(clone);clone.hide_render=False;clone.hide_set(False);clone['construction_parent']=old.name
   clone.data.materials.clear();clone.data.materials.append(gray)
   bm=bmesh.new();bm.from_mesh(clone.data)
   for face in bm.faces:face.smooth=True
   for edge in bm.edges:edge.smooth=edge.is_manifold and edge.calc_face_angle(0)<.70
   bm.to_mesh(clone.data);bm.free();clone.data.update()
   old.hide_render=True;old.hide_set(True)
 original_base=sc.objects['Sarang.numaru roof end ornament.pale base'];original_base.hide_render=True;original_base.hide_set(True)
 import guardian_mount_r12 as gm
 mount=gm.build_mount(sc,o,gray);mount_checks=gm.get_checks(mount)
 assert mount_checks['allGeometryChecksPassed'],mount_checks
 bm=bmesh.new();bm.from_mesh(mesh);nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.free();assert nonmanifold==0,nonmanifold
 return dict(name=o.name,vertices=len(verts),faces=len(faces),nonManifoldEdges=nonmanifold,closedLoops=len(loops),designWidth=.30,designHeight=.43,sourceFront=-3.544,sourceBack=-3.436,frontReliefDepth=[float(depth.min()),float(depth.max())],sideReliefScale=.0035,sidePatternPhysicalPeriod=repeat,sideSourceWidthFraction=side_width_fraction,mountChecks=mount_checks,frontSource=str(ROOT/'exec-6dc3e9d7-0263-4476-93a4-e250cbe75c2e.png'),sideSource=str(ROOT/'exec-82363520-c4c8-4ac2-9137-e936bc4cdbf6.png'),roundEaves='original 144mm round caps retained; oversized overlays removed',depthIsEstimated=True)
