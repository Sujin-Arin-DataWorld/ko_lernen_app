"""Native semantic relief, fitted to measured original roof components. No image nodes."""
import bpy,math,numpy as np
from mathutils import Vector

def make_material(name,hexcol,metal=.12):
 import sarang_reference_colour_r3 as c
 f=c.f;m=bpy.data.materials.new(name);m.use_nodes=True;t=m.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED');rgb=f.rgb(hexcol)
 bs.inputs['Base Color'].default_value=rgb;bs.inputs['Roughness'].default_value=.72;bs.inputs['Metallic'].default_value=metal
 noise=t.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=360;noise.inputs['Detail'].default_value=2
 geo=t.nodes.new('ShaderNodeNewGeometry');t.links.new(geo.outputs['Position'],noise.inputs['Vector'])
 bump=t.nodes.new('ShaderNodeBump');bump.inputs['Distance'].default_value=.00012;bump.inputs['Strength'].default_value=.2;t.links.new(noise.outputs['Fac'],bump.inputs['Height']);t.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
 m.diffuse_color=rgb;return m

def relief(x,v,kind):
 """Sculpted features in face coordinates: sockets, brows, cheeks, muzzle and fangs."""
 cx=.72 if kind=='main' else .79;cz=.41 if kind=='main' else .48;sz=.27 if kind=='main' else .37
 X=x/cx;Z=(v-cz)/sz
 def ga(a,b,sx,sz):return np.exp(-2*((X-a)/sx)**2-2*((Z-b)/sz)**2)
 h=.001+.014*ga(0,-.08,.94,.96)+.005*ga(0,-.57,.68,.38)
 for s in [-1,1]:
  h+=.009*ga(s*.48,-.20,.36,.34) # broad cheekbone
  h-=.010*ga(s*.34,.13,.27,.23) # deep almond socket
  h+=.0055*ga(s*.32,.12,.095,.14) # inset iris, same ceramic
  h-=.003*ga(s*.31,.13,.040,.08) # pupil depression
  h-=.0035*ga(s*.12,-.17,.075,.065) # nostril cut
 h+=.016*ga(0,-.06,.26,.26)+.006*ga(0,.18,.16,.34)
 h-=.012*ga(0,-.40,.48,.20) # broad open smile
 h+=.003*ga(0,-.57,.40,.10) # curled lower lip
 def stroke(points,width,height,domain='face'):
  nonlocal h
  xx,zz=(X,Z) if domain=='face' else (x,v)
  dist=np.full_like(x,100.0)
  pts=np.asarray(points,float)
  for a,b in zip(pts[:-1],pts[1:]):
   d=b-a;t=np.clip(((xx-a[0])*d[0]+(zz-a[1])*d[1])/(d@d+1e-12),0,1)
   dist=np.minimum(dist,(xx-a[0]-t*d[0])**2+(zz-a[1]-t*d[1])**2)
  ridge=np.exp(-2*dist/width**2);h+=height*ridge
 def bezier(p0,p1,p2,p3):
  ts=np.linspace(0,1,32);return [(1-t)**3*np.array(p0)+3*(1-t)**2*t*np.array(p1)+3*(1-t)*t*t*np.array(p2)+t**3*np.array(p3) for t in ts]
 for s in [-1,1]:
  # Swept eyebrows carry a clear relief silhouette even without pigment.
  stroke(bezier((s*.12,.32),(s*.28,.52),(s*.56,.48),(s*.67,.27)),.09,.009)
  stroke(bezier((s*.08,-.35),(s*.25,-.56),(s*.48,-.46),(s*.56,-.29)),.038,.0035)
  # Ears and spiral cheek marks are modeled ridges.
  stroke([(s*.63,.03),(s*.91,.25),(s*.76,-.12),(s*.63,.03)],.035,.004)
  tt=np.linspace(0,math.pi*2.1,44);rr=np.linspace(.16,.025,len(tt))
  stroke([(s*(.58+r*math.cos(t)),-.19+r*math.sin(t)) for r,t in zip(rr,tt)],.027,.0033)
  # Tapered fangs: broad roots, pointed lower end.
  tt=np.clip((Z+.52)/.29,0,1);width=.077*tt
  fang=np.clip(1-np.abs(X-s*.255)/(width+1e-5),0,1)*np.sin(np.pi*tt/2)
  h+=.010*fang*((Z>=-.52)&(Z<=-.23))
  # Horns are tapered curved relief, not shading from a source picture.
  ts=np.linspace(0,1,30)
  for t in ts:
   px=s*(.48-.12*t+.05*math.sin(t*math.pi));pz=.58+.43*t
   h+=.00095*(1-t*.70)*ga(px,pz,.14*(1-t)+.025,.09)
  # Six swept locks on each side; every lock has a physical crest and groove.
  for k in range(6):
   a=.12+k*.09;z=.63+k*.055
   pts=bezier((s*.09,z),(s*(.43+a*.25),z+.16),(s*(.68+a*.15),z+.10),(s*(.62+a*.22),z-.18))
   stroke(pts,.045,.0024)
 # Low headband ridge and central flame mark.
 stroke(bezier((-.60,.60),(-.18,.68),(.18,.68),(.60,.60)),.04,.003)
 stroke([(0,.51),(-.07,.67),(.03,.79),(.02,.66),(.10,.61),(0,.51)],.025,.003)
 if kind=='main':
  for px,pz,radius in [(0,.88,.12),(-.57,.75,.10),(.57,.75,.10),(-.70,.22,.11),(.70,.22,.11),(-.45,.10,.09),(.45,.10,.09),(0,.12,.11)]:
   ts=np.linspace(0,math.pi*2.3,52);rs=np.linspace(radius,.012,len(ts))
   stroke([(px+r*math.cos(t),pz+r*.60*math.sin(t)) for r,t in zip(rs,ts)],.018,.0035,'body')
 return np.maximum(h,.0005)

def build_guardians(sc,original_rows):
 col=bpy.data.collections.new('HS11 measured sculpted guardian roof caps');sc.collection.children.link(col)
 body=make_material('HS11 fired mineral teal guardian','56604E');edge=make_material('HS11 worn mineral ridge','817A5C');dark=make_material('HS11 charcoal mounting ceramic','535D64',.02)
 for o in sc.objects:
  if o.name.startswith(('HS9 ','HS8 ','HS6 guardian eave')):o.hide_render=True;o.hide_set(True)
 # Undo the accidental ornament pattern on unrelated base/ridge surfaces.
 for o in sc.objects:
  if o.name=='Sarang.numaru roof end ornament.pale base' or o.name.startswith('Sarang.numaru roof.ridge stack'):
   for sl in o.material_slots:sl.link='OBJECT';sl.material=dark
 frontrow=next(r for r in original_rows if r['name']=='Sarang.numaru roof end ornament.original patterned face')
 polygon=np.array([[(q[0]-12.56)/.15,(q[2]-6.66)/.43] for q in frontrow['points']])
 def perimeter(poly,n):
  closed=np.vstack((poly,poly[0]));seg=np.linalg.norm(np.diff(closed,axis=0),axis=1);cum=np.r_[0,np.cumsum(seg)];out=[]
  for d in np.linspace(0,cum[-1],n,endpoint=False):
   i=min(len(seg)-1,np.searchsorted(cum,d,side='right')-1);t=(d-cum[i])/seg[i];out.append(closed[i]*(1-t)+closed[i+1]*t)
  return np.array(out)
 report=[]
 for name,kind,center,width,height,yfront,depth in [
  ('HS11 main measured guardian','main',(12.56,6.66),.30,.43,-3.544,.108),
  ('HS11 left round guardian cap','round',(9.195,4.793),.144,.144,-5.401,.027),
  ('HS11 right round guardian cap','round',(15.925,4.793),.144,.144,-5.401,.027)]:
  nb=240;nr=72;ctr=np.array([0,.47 if kind=='main' else .5])
  if kind=='main':outer=perimeter(polygon,nb)
  else:
   t=np.linspace(0,2*math.pi,nb,endpoint=False);outer=np.stack((np.cos(t),.5+.5*np.sin(t)),axis=1)
  # Orient CCW in XZ so the outward front normal is -Y.
  area=np.sum(outer[:,0]*np.roll(outer[:,1],-1)-np.roll(outer[:,0],-1)*outer[:,1])
  if area<0:outer=outer[::-1]
  points=[ctr]
  radii=[0]
  for j in range(1,nr+1):
   t=j/nr;points.extend(ctr+(outer-ctr)*t);radii.extend([t]*nb)
  a=np.asarray(points);r=np.asarray(radii);X=a[:,0];V=a[:,1]
  H=np.full_like(X,.001)
  # Flush outer foot plus rounded integral rim.
  H*=np.minimum(1,(1-r)/.065);H+=np.exp(-((r-.957)/.018)**2)*(.0022 if kind=='round' else .004)
  verts=[(center[0]+x*width/2,yfront-h,center[1]+v*height) for (x,v),h in zip(a,H)]
  faces=[];mids=[]
  for k in range(nb):faces.append((0,1+k,1+(k+1)%nb));mids.append(0)
  for j in range(1,nr):
   st=1+(j-1)*nb;nt=st+nb
   for k in range(nb):q=(k+1)%nb;faces.append((st+k,nt+k,nt+q,st+q));mids.append(1 if j>=nr-4 and j<=nr-2 else 0)
  n=len(verts);verts.extend([(x,yfront+depth,z) for x,y,z in verts]);faces.extend([tuple(i+n for i in reversed(face)) for face in list(faces)]);mids.extend(list(mids))
  boundary=[1+(nr-1)*nb+k for k in range(nb)]
  # Side moulding is curved solid geometry, with small integral beads.
  rings=[boundary]
  for j in range(1,9):
   t=j/9;row=[]
   for k,idx in enumerate(boundary):
    x,y,z=verts[idx];xx=(x-center[0]);zz=z-(center[1]+ctr[1]*height);bead=.0012*math.sin(math.pi*t)*(0.65+.35*math.cos(k*math.pi/8))
    radius=max(math.hypot(xx,zz),1e-6);row.append(len(verts));verts.append((x-xx/radius*bead,yfront+depth*t,z-zz/radius*bead))
   rings.append(row)
  rings.append([i+n for i in boundary])
  for j in range(len(rings)-1):
   for k in range(nb):q=(k+1)%nb;faces.append((rings[j][q],rings[j][k],rings[j+1][k],rings[j+1][q]));mids.append(0)
  mesh=bpy.data.meshes.new(name+' solid relief');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);col.objects.link(o);mesh.materials.append(body);mesh.materials.append(edge)
  for poly,mi in zip(mesh.polygons,mids):poly.use_smooth=True;poly.material_index=mi
  o['construction_parent']='Sarang.numaru roof end ornament.original patterned face' if kind=='main' else 'Sarang.numaru roof.hip round tile ends';o['semantic_relief']='modeled sockets, brow ridges, cheekbones, nose, grin, fangs, horns, swept locks, cloud ridges';o['image_texture_used']=False
  co=np.array(verts);report.append(dict(name=name,type=kind,boundsMin=co.min(axis=0).tolist(),boundsMax=co.max(axis=0).tolist(),sourceWidth=width,sourceHeight=height,sourceFront=yfront,reliefDepth=float(H.max()),vertices=len(verts),faces=len(faces),imageTexture=False))
 import guardian_volume_r11
 for row in report:
  row['sculptParts']=guardian_volume_r11.add_sculpt(sc,sc.objects[row['name']],row['type'])
 return report
