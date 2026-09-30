"""Replace foundation-sized, vertically stretched roof with sheets 059/061/066.

Printed plan dimensions are kept distinct from elevation tracing and fitted
tile cross-sections. Body, doors, columns, other buildings and artwork survive.
"""
from pathlib import Path
import bpy,bmesh,sys,json,hashlib,math,shutil,numpy as np
from mathutils import Matrix,Vector
sys.path.insert(0,str(Path(__file__).parent))
from repair_masonry_coping import OUT,fingerprint
from northern_timber_sections import groups
import canonical_surface_reuse as art
from northern_tile_ends import give_tile_shells_depth
sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
import reconstruction_geometry as g
import reference_detail_geometry as d

HALF_W,HALF_D=4.28,3.55
def field(x,y):
 t=min(1.,abs(y)/HALF_D);r=min(1.,abs(x)/HALF_W)**8
 return 3.10+1.45*(1-t)**1.25+r*(.14*t*t+.09*(1-t))
def ridge_lift(x):return .22*(abs(x)/HALF_W)**8
def old_field(x,y):
 t=min(1.,abs(y)/2.97);r=min(1.,abs(x)/4.18)**8
 return 3.70+1.46*(1-t)**1.45+r*(.20*t*t+.08*(1-t))
def unwarp(z):return 3.70+(z-3.)*1.46/2.16 if z>3. else z+.70
def roof_part(o):
 return o.type=='MESH' and o.get('construction_building')=='sadang' and any(s in o.name for s in ('.roof','.joinery.solid roof bedding','.joinery.packed ridge core','.joinery.gable ','.double eave square buyeon','.painted rafter end','.photo rafter rosette','.photo painted rafter collar'))

def apply(scene,c):
 if c.get('shrineRoofCorrection'):return
 rec=next(r for r in c['buildings'] if r['id']=='sadang');origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z');inv=rot.transposed()
 world=lambda p:origin+rot@Vector(p)
 local=lambda o,v:inv@(o.matrix_world@v.co-origin)
 protected={o.name:fingerprint(o) for o in scene.objects if o.type=='MESH' and not roof_part(o)}
 removed=[];retained=[]
 # Keep solid measured gable boards and decorated eave members, changing
 # their registration, never their documented board/post thicknesses.
 for o in list(scene.objects):
  if not roof_part(o):continue
  nm=o.name;oi=o.matrix_world.inverted()
  keep=any(s in nm for s in ('gable thirty','gable 45x27','lower exposed rafters','double eave','painted rafter','photo rafter rosette'))
  if not keep:removed.append(nm);bpy.data.objects.remove(o,do_unlink=True);continue
  retained.append(nm)
  for ids in groups(o.data):
   q=np.array([local(o,o.data.vertices[i]) for i in ids]);lo=q.min(0);hi=q.max(0);mid=(lo+hi)/2
   if 'gable ' in nm:
    q[:,0]+=math.copysign(.10,mid[0]);q[:,1]*=HALF_D/2.97
    for p in q:
     y=p[1];bottom=2.32+.37*(abs(y)/HALF_D)**4
     top=field(HALF_W,y)-(.098 if 'thirty' in nm else .17)
     f=(p[2]-lo[2])/max(hi[2]-lo[2],.001)
     # Polygon upper vertices follow the actual roof curve, not a box.
     p[2]=bottom if f<.01 else top if 'thirty' in nm else bottom+f*(top-bottom)
   elif 'double eave' in nm:
    q[:,0]+=(mid[0]/4.18*.10)
    q[:,1]=math.copysign(3.33,mid[1])+(q[:,1]-mid[1])*.44/(hi[1]-lo[1])
    q[:,2]+=3.055+.14*(abs(mid[0])/4.18)**8-mid[2]
   elif 'lower exposed rafters' in nm:
    # Project each cylindrical section onto its new centreline without
    # changing its radius. The 1010+440 plan split ends the round rafter
    # at 3110; the square buyeon reaches the 3550 roof datum.
    side=1 if mid[1]>0 else -1;x=mid[0]/4.18*HALF_W
    a=Vector((mid[0],side*1.782,3.+(old_field(mid[0],1.782)-3.70)*2.16/1.46-.33))
    # Use PCA to recover the existing member's exact axis and cut section.
    center=q.mean(0);vals,basis=np.linalg.eigh((q-center).T@(q-center));axis=basis[:,-1]
    if axis[1]*side<0:axis=-axis
    along=(q-center)@axis;l,h=along.min(),along.max();u=(along-l)/(h-l)
    a=Vector((x,side*1.95,field(x,side*1.95)-.275));b=Vector((x,side*3.11,field(x,side*3.11)-.275))
    newaxis=(b-a).normalized();r=Vector(axis).rotation_difference(newaxis).to_matrix()
    radial=q-center-along[:,None]*axis
    q=np.array([np.array(a)+(np.array(b-a))*t+np.array(r@Vector(v)) for t,v in zip(u,radial)])
   else:
    # Rosettes and their collars follow the round rafter tip. Keep painted
    # profiles and UVs, including the white underside, byte for byte.
    side=1 if mid[1]>0 else -1;x=mid[0]/4.18*HALF_W
    newy=side*(3.125 if 'rosette' in nm else 3.11 if 'rafter end' in nm else abs(mid[1])+.21)
    z=field(x,newy)-.275
    q+=np.array((x-mid[0],newy-mid[1],z-mid[2]))
   for i,p in zip(ids,q):o.data.vertices[i].co=oi@world(p)
  o.data.update();o['shrineRoofRegistration']=1
 # Generate individual courses with their own 8 mm inward ceramic shell.
 # No transform scales their Z after this point.
 green=bpy.data.materials['North aged blue green'];red=bpy.data.materials['North weathered vermilion'];earth=bpy.data.materials['North earthen plaster'];lime=bpy.data.materials['North lime plaster'];end=bpy.data.materials['North lime tile ends']
 tiles=[bpy.data.materials[f'Ansarang retained V33 main_gate source ceramic {i}'] for i in range(6)]
 g.BATCHES.clear();g.set_transform(world)
 def from_generic(p):
  x,y,z=p;t=min(1,abs(y)/HALF_D);r=min(1,abs(x)/HALF_W)**8
  old=3.1+1.45*(1-t)**1.45+.14*r*t*t+.09*r*(1-t)
  return world((x,y,field(x,y)+(z-old)))
 g.set_transform(from_generic)
 g.roof('North.sadang.roof',(-HALF_W,HALF_W,-HALF_D,HALF_D),3.10,4.55,green,tiles,end,columns=28,turn=.14,ridge_turn=.09,cover_radius=.072,cover_height=.062,channels_between_covers=True,ridge_courses=0)
 generated=g.flush();g.BATCHES.clear()
 for o in generated:
  if any(t in o.name for t in ('.rafters','.lower exposed rafters','.round tile ends','.eave beam','.gable timber')):bpy.data.objects.remove(o,do_unlink=True)
 g.set_transform(world)
 # Closed earthen bedding: the lower face is lime plaster, not timber.
 nx,ny=56,48
 for i in range(nx):
  for j in range(ny):
   quad=[(-HALF_W+(i+a)*2*HALF_W/nx,-HALF_D+(j+b)*2*HALF_D/ny) for a,b in ((0,0),(1,0),(1,1),(0,1))]
   top=[(x,y,field(x,y)-.035) for x,y in quad];bot=[(x,y,field(x,y)-.100) for x,y in quad]
   g.face('North.sadang.joinery.solid roof bedding',top,earth);g.face('North.sadang.joinery.solid roof bedding',bot[::-1],earth)
   for k,edge in ((0,j==0),(1,i==nx-1),(2,j==ny-1),(3,i==0)):
    if edge:g.face('North.sadang.joinery.solid roof bedding',[top[k],bot[k],bot[(k+1)%4],top[(k+1)%4]],earth)
 def sweep(name,sections,mat):
  g.face(name,sections[0][::-1],mat);g.face(name,sections[-1],mat)
  for a,b in zip(sections,sections[1:]):
   for k in range(len(a)):g.face(name,[a[k],b[k],b[(k+1)%len(a)],a[(k+1)%len(a)]],mat)
 # Five thin ridge courses above the fitted packing, separate from the
 # roof field height. The drawing's five courses do not mean five tubes.
 sections=[]
 for x in np.linspace(-HALF_W,HALF_W,57):
  z=field(x,0);top=5.065+ridge_lift(x)
  sections.append([(x,y,h) for y,h in ((-.100,z-.10),(-.100,top),(.100,top),(.100,z-.10))])
 sweep('North.sadang.joinery.packed ridge core',sections,tiles[2])
 for level in range(5):
  for i in range(32):
   sections=[]
   for x in (-HALF_W+i*2*HALF_W/32,-HALF_W+(i+1)*2*HALF_W/32):
    z=4.886+level*.052+ridge_lift(x)
    sections.append([(x,.142*math.cos(a),z+.025*math.sin(a)) for a in np.linspace(0,math.tau,16,endpoint=False)])
   sweep('North.sadang.roof.ridge course '+str(level+1),sections,tiles[(i+level)%6])
 # Solid pale lime plugs are inset beneath the covers; no floating discs.
 for side in (-1,1):
  for i in range(28):
   x=-HALF_W+(i+.5)*2*HALF_W/28;y=side*HALF_D;z=field(x,y)+.042
   profile=[(x+.065*math.cos(a),z+.057*math.sin(a)) for a in np.linspace(0,math.pi,17)]
   d.extruded_profile('North.sadang.roof.round tile ends',profile,y-.009,y+.009,end)
  # Chaggo supports below the ridge courses, with the same rhythm as tiles.
  for i in range(28):
   x=-HALF_W+(i+.5)*2*HALF_W/28;lift=ridge_lift(x)
   profile=[(x-.12,4.53+lift),(x+.12,4.53+lift),(x+.12,4.70+lift)]+[(x+.12*math.cos(a),4.70+lift+.075*math.sin(a)) for a in np.linspace(0,math.pi,13)]
   d.extruded_profile('North.sadang.roof.ridge chaggo',profile,side*.12-.022,side*.12+.022,tiles[i%6])
 # 061: three descending ridge courses, and 45 mm x 320 mm bargeboards.
 for side in (-1,1):
  x=side*HALF_W
  for slope in (-1,1):
   for level in range(3):
    sections=[]
    for y0 in np.linspace(0,HALF_D,40):
     y=slope*y0;z=field(x,y)+.105+level*.052+.13*(y0/HALF_D)**16
     sections.append([(x+.092*math.cos(a),y,z+.021*math.sin(a)) for a in np.linspace(0,math.tau,12,endpoint=False)])
    sweep('North.sadang.roof.descending course '+str(level+1),sections,tiles[level])
   # The three courses sit on continuous packing. Without it the upturned
   # ends float above the roof. Side-laid tile noses project beyond the
   # 8560 datum, as drawn in both 059 and 066; they are not body overhang.
   sections=[]
   for y0 in np.linspace(0,HALF_D,40):
    y=slope*y0;lo=field(x,y)-.04;hi=field(x,y)+.196+.13*(y0/HALF_D)**16
    sections.append([(x-.063,y,lo),(x+.063,y,lo),(x+.063,y,hi),(x-.063,y,hi)])
   sweep('North.sadang.roof.descending packed core',sections,tiles[2])
   for j in range(13):
    cy=slope*(j+.5)*HALF_D/13
    for k in range(6):
     aa=k/6;bb=(k+1)/6;verts=[]
     for xx,a in ((side*4.16,aa),(side*4.16,bb),(side*4.59,bb),(side*4.59,aa)):
      yy=slope*(j+a)*HALF_D/13;verts.append((xx,yy,field(HALF_W,yy)+.012-.040*abs(math.cos(a*math.pi))))
     g.face('North.sadang.roof.side laid pans',verts,tiles[j%6])
    # Cover arcs run across the gable, under the descending ridge; their
    # lime plugs and ceramic skin are distinct solid surfaces.
    for k in range(12):
     aa=k*math.pi/12;bb=(k+1)*math.pi/12;verts=[]
     for xx,a in ((side*4.16,aa),(side*4.16,bb),(side*4.59,bb),(side*4.59,aa)):
      yy=cy+.078*math.cos(a);verts.append((xx,yy,field(HALF_W,yy)+.027+.064*math.sin(a)))
     g.face('North.sadang.roof.side laid covers',verts,tiles[j%6])
    profile=[(cy+.072*math.cos(a),field(HALF_W,cy+.072*math.cos(a))+.029+.055*math.sin(a)) for a in np.linspace(0,math.pi,17)]
    old=g.TRANSFORM;g.set_transform(lambda p,side=side:world((side*(4.585+p[1]),p[0],p[2])))
    d.extruded_profile('North.sadang.roof.side lime plugs',profile,-.009,.009,end);g.set_transform(old)
   old=g.TRANSFORM;g.set_transform(lambda p,side=side:world((side*(HALF_W+p[1]),p[0],p[2])))
   ys=np.linspace(0,HALF_D,40)*slope
   upper=[(y,field(HALF_W,y)-.09) for y in ys]
   lower=[(y,z-.32) for y,z in reversed(upper)]
   d.extruded_profile('North.sadang.roof.T45 W320 bargeboard',upper+lower,-.0225,.0225,red);g.set_transform(old)
   sections=[]
   for y0 in np.linspace(0,HALF_D,40):
    y=slope*y0;z=field(HALF_W,y)
    sections.append([(side*4.25,y,z-.10),(side*4.57,y,z-.10),(side*4.57,y,z-.035),(side*4.25,y,z-.035)])
   sweep('North.sadang.roof.gable earthen bedding',sections,earth)
 # Thin eave bindings close the space above the square buyeon; no oversized
 # rounded logs or second roofing layer is introduced.
 for side in (-1,1):
  sections=[]
  for x in np.linspace(-HALF_W,HALF_W,57):
   z=field(x,side*HALF_D)-.080
   sections.append([(x,side*3.525-.038,z-.0375),(x,side*3.525+.038,z-.0375),(x,side*3.525+.038,z+.0375),(x,side*3.525-.038,z+.0375)])
  sweep('North.sadang.roof.eave binding',sections,green)
 # Top ridge end caps from the 061 silhouette; exact tile dimensions are
 # not printed, so these compact caps remain an elevation fit.
 for side in (-1,1):
  sections=[]
  profile=[(-.14,4.875),(.14,4.875),(.14,5.23),(.10,5.31),(0,5.39),(-.10,5.31),(-.14,5.23)]
  for x in (side*(HALF_W-.022),side*(HALF_W+.022)):sections.append([(x,y,z) for y,z in profile])
  sweep('North.sadang.roof.upright end cap',sections,tiles[2])
 added=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
 allnew=[o for o in scene.objects if o.type=='MESH' and o.name not in protected and o.name not in retained]
 src=art.MAP['sadang'];art.ART=src['path'];art.base_image=bpy.data.images.load(str(src['path']),check_existing=True);art.materials={};art.regions=src['regions'];art.mapped=[]
 for o in allnew:
  if not(o.name.startswith('North.sadang.')):continue
  for k,v in {'construction_building':'sadang','northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':o.name,'shrineRoofRebuild':1}.items():o[k]=v
  for m in list(o.modifiers):o.modifiers.remove(m)
  mat=o.data.materials[0]
  if 'source ceramic' in mat.name:
   art.art_uv(o,'tile');o.data.materials[0].name='Reference sadang roof ceramic corrected'
   uv=o.data.uv_layers.get('Canonical gate pigment');x0,y0,x1,y1=src['regions']['tile'][0]
   for loop in uv.data:loop.uv=((x0+x1)/2+(loop.uv.x-(x0+x1)/2)*.045,1-(y0+y1)/2+(loop.uv.y-(1-(y0+y1)/2))*.045)
   o['canonicalSurfaceSource']=str(src['path']);o['canonicalSurfaceKind']='tile'
  elif 'bargeboard' in o.name:
   art.art_uv(o,'post');o.data.materials[0].name='Reference sadang bargeboard red'
  if 'solid roof bedding' in o.name:
   o.data.materials.append(lime)
   for p in o.data.polygons:
    if p.normal.z<-.01:p.material_index=1
  if any(t in o.name for t in ('course','ridge chaggo','round tile ends','upright end cap')):
   for p in o.data.polygons:p.use_smooth=False
 give_tile_shells_depth(scene)
 # Canonical materials have surfaceKind=tile, so the older illustrated-clay
 # helper does not recognize them. Apply thickness to these new open skins
 # explicitly; a material replacement must never remove ceramic volume.
 for o in allnew:
  if o.get('shrineRoofRebuild')!=1 or o.get('canonicalSurfaceKind')!='tile':continue
  bm=bmesh.new();bm.from_mesh(o.data);boundary=any(e.is_boundary for e in bm.edges);bm.free()
  if boundary and not any(m.type=='SOLIDIFY' for m in o.modifiers):
   mod=o.modifiers.new('Ceramic thickness 8 mm','SOLIDIFY');mod.thickness=.008;mod.offset=-1;mod.use_even_offset=True;mod.use_quality_normals=True
   o['tileShellVersion']=1;o['shellThicknessAuthority']='8 mm inward fit; no per-tile printed section'
 bpy.context.view_layer.update()
 assert all(fingerprint(bpy.data.objects[n])==fp for n,fp in protected.items()),'Non-roof mesh changed'
 refs=OUT/'references/sadang';sources=[]
 for suffix,sheet in [('정면도','059'),('우측면도','061'),('지붕평면도','066')]:
  p=next(refs.glob('*사당_'+suffix+'.jpg'));sources.append({'sheet':sheet,'file':str(p.relative_to(OUT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 rec['roofSurvey']={'printedBodyAxes':[6.760,4.200],'printedEaveProjection':[.900,1.450],'printedDepthSplit':[1.010,.440],'roofDatums':[8.560,7.100],'ridgeCourses':5,'descendingCourses':3,'tileSpecification':'한식기와(중와,B형)','tileRuns':28,'tileRunsAuthority':'066 drawing count; schematic, not a printed count','fieldEave':3.100,'fieldRidge':4.550,'ridgeTopCenter':5.119,'ridgeTopEnd':5.390,'verticalAuthority':'059/061 line traces calibrated to 6760/4200 axes; estimated tolerance +/-40 mm, NOT printed heights','trace059':{'displaySize':[1867,1312],'columnAxisX':[596.5,1101.5],'groundY':976,'centerRidgeY':594,'eaveCoverY':737,'upperFieldY':635},'trace061':{'imageSize':[3301,2198],'columnAxisX':[1245,1798],'groundY':1597,'ridgeEndY':887,'roofFieldApexY':986,'eaveEndY':1165},'ceramicShellMeters':.008,'tileSectionAuthority':'Fitted to elevation strokes and canonical curved tile silhouette; no individual tile dimensions printed','sources':sources}
 c['shrineRoofCorrection']={'changedBuilding':'sadang','changedScope':'roof only; columns, rooms, foundation and doors protected','removed':removed,'retainedAndRegistered':retained,'protectedMeshCount':len(protected),'protectedMeshFingerprintSha256':hashlib.sha256(json.dumps(protected,sort_keys=True).encode()).hexdigest(),'previousErrors':['Used foundation 8360x5940 as roof instead of roof datums 8560x7100','Applied 2.16/1.46 vertical stretch to tiles and ridge as well as slope','Main roof field peak confused with top of ridge'],'survey':rec['roofSurvey'],'fullSurveyAccuracyClaimed':False}
 atlas=json.loads((OUT/'atlas-part-map.json').read_text(encoding='utf8'));atlas['mapped']=[r for r in atlas['mapped'] if r['object'] not in removed]+art.mapped
 (OUT/'atlas-part-map.json').write_text(json.dumps(atlas,ensure_ascii=False,indent=2),encoding='utf8');c['canonicalSurfaceReuse']=atlas

if __name__=='__main__':
 path=OUT/'detail-redraw.blend';before=hashlib.sha256(path.read_bytes()).hexdigest()
 backup=OUT/'roof-before-correction.blend'
 if not backup.exists():shutil.copy2(path,backup)
 c=json.loads((OUT/'detail-redraw-contract.json').read_text(encoding='utf8'))
 if '--from-backup' in sys.argv:
  assert c['shrineRoofCorrection']['correctedSceneSha256']==before,'Candidate changed after correction'
  before=hashlib.sha256(backup.read_bytes()).hexdigest();assert before==c['shrineRoofCorrection']['previousSceneSha256']
  c.pop('shrineRoofCorrection');bpy.ops.wm.open_mainfile(filepath=str(backup))
 else:
  assert not c.get('shrineRoofCorrection'),'Already corrected; use explicit --from-backup for a verified iteration'
  bpy.ops.wm.open_mainfile(filepath=str(path))
 apply(bpy.context.scene,c)
 bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
 record=c['shrineRoofCorrection'];record.update(previousSceneSha256=before,correctedSceneSha256=hashlib.sha256(path.read_bytes()).hexdigest())
 (OUT/'sadang-roof-audit.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
 (OUT/'detail-redraw-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
 print('SADANG ROOF CORRECTED',record['correctedSceneSha256'],flush=True)
