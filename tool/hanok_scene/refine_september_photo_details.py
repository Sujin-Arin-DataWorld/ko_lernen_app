"""Targeted solid details from the supplied Sep29 photographs and sheets 048/050.

Keeps all placements, measured post/door/roof dimensions and non-target meshes.
Interior furniture and pigment aging are photo interpretations, not surveys.
"""
from pathlib import Path
import bpy,bmesh,sys,json,math,hashlib,shutil,random,numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from repair_masonry_coping import OUT,fingerprint
from refine_northern_materials import geometry_fingerprint
from northern_timber_sections import groups
import canonical_surface_reuse as art
from northern_courtyard_photo_repair import g,d,tag_flush
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def register_sources():
 sources=[('d9d7ca05-de85-4662-88bc-85719ccaca17','sadang-side-sep29','Porch, sculpted brackets, weathered gable boards'),('84730e65-3a90-4e17-a209-e486ccf8e332','sadang-front-sep29','Single-double-single doors, round columns, painted brackets'),('38a23fb2-ee37-4a75-a144-2c3b0d859ec1','sadang-altar-sep29','Cabinet, altar, brass candle stands, incense vessel, woven mats; unmeasured'),('4c59eea7-d33b-40d6-874a-7c4847c1863e','jeong-yeochang-portrait-reference','Identity reference; installation location unknown and not modeled'),('e795d0fb-8c31-4257-80c8-9c06f9b5c175','ansarang-left-sep29','Open kitchen under loft, side opening; sheets048/050 control geometry'),('50adc951-f135-4f4e-a942-ed116b9edd51','sadangmun-front-sep29','Closed gate hardware, subdued red paint, green framing, flower wall'),('e744bda3-ae43-415e-a0f6-d063f83c0dbe','sadangmun-front-sep29-duplicate','Additional supplied gate photograph')]
 records=[]
 for token,name,role in sources:
  src=Path('C:/Users/vjinn/AppData/Local/Temp')/('codex-clipboard-'+token+'.png');dst=OUT/'references/photos'/(name+'.png');shutil.copy2(src,dst)
  records.append({'source':str(src),'file':str(dst.relative_to(OUT)),'sha256':sha(src),'copySha256':sha(dst),'role':role})
 survey=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/ildu_Blueprint/안사랑채')
 for suffix,slug in [('좌,우측면도','ansarang-survey050'),('종단면도','ansarang-survey052')]:
  src=next(survey.glob('*'+suffix+'.jpg'));dst=OUT/'references/survey-audit'/(slug+'.jpg');shutil.copy2(src,dst)
  records.append({'source':str(src),'file':str(dst.relative_to(OUT)),'sha256':sha(src),'copySha256':sha(dst),'role':'Measured 2007 survey; geometry authority'})
 (OUT/'photo-detail-sources.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8');return records

def setup_art(bid):
 src=art.MAP[bid];art.ART=src['path'];art.base_image=bpy.data.images.load(str(art.ART),check_existing=True);art.regions=src['regions'];art.materials={};art.mapped=[]

def color_mat(name,color,metal=0):
 m=art.new_material(name);bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=.45 if metal else .88;bs.inputs['Specular IOR Level'].default_value=.25;return m

def tint_material(original,bid,factor):
 # A supported texture * constant expression: exported as glTF baseColorFactor.
 m=original.copy();m.name='Sep29 '+bid+' '+original.name;n=m.node_tree.nodes;l=m.node_tree.links;bs=n.get('Principled BSDF')
 link=next((a for a in l if a.to_socket==bs.inputs['Base Color']),None)
 if link:
  source=link.from_socket;l.remove(link);mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(*factor,1);l.new(source,mix.inputs[1]);l.new(mix.outputs[0],bs.inputs['Base Color'])
 else:bs.inputs['Base Color'].default_value=tuple(bs.inputs['Base Color'].default_value[i]*factor[i] for i in range(3))+(1,)
 m['photoPigmentFit']='Sep29 photograph tonal calibration; original artwork bytes retained';return m

def main():
 sources=register_sources();source=OUT/'detail-redraw.blend';backup=OUT/'photo-details-before.blend'
 if not backup.exists():shutil.copy2(source,backup);shutil.copy2(OUT/'detail-redraw-contract.json',OUT/'photo-details-before-contract.json')
 # Reproducible retries always begin at the exact pre-detail scene.
 bpy.ops.wm.open_mainfile(filepath=str(backup));scene=bpy.context.scene;bpy.context.view_layer.update()
 c=json.loads((OUT/'photo-details-before-contract.json').read_text(encoding='utf8'));south=json.loads((OUT.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'))
 targets={'sadang','sadangmun','ansarang'};protected={o.name:fingerprint(o) for o in scene.objects if o.type=='MESH' and o.get('construction_building') not in targets}
 roof_before={o.name:geometry_fingerprint(o) for o in scene.objects if o.type=='MESH' and o.get('construction_building')=='sadang' and 'roof.' in o.name}
 records={r['id']:r for r in c['buildings']};records['ansarang']={**south['buildings']['ansarang'],'datum':0};added=[];removed=[];changes=[]
 def basis(bid):
  r=records[bid];origin=Vector((*r['center'],r['datum']));rot=Matrix.Rotation(r['angle'],3,'Z');return origin,rot,lambda p:origin+rot@Vector(p)
 def finish(bid,wood_names=()):
  obs=tag_flush(bid);setup_art(bid)
  for o in obs:
   if any(t in o.name for t in wood_names):art.art_uv(o,'wood')
   o['photoDetailVersion']=1;o['detailAuthority']='Sep29 photo guided detail; see photo-detail-audit.json for printed vs fitted dimensions'
  added.extend(o.name for o in obs);return obs
 def remove(name):
  o=bpy.data.objects.get(name)
  if o:removed.append(name);bpy.data.objects.remove(o,do_unlink=True)
 def stroke(name,pts,rad,mat):
  for a,b in zip(pts,pts[1:]):g.rod(name,a,b,rad,mat,8)
 def lathe(name,x,y,z,profile,mat,n=48):
  # Closed profile includes its base and inner bowl, all surfaces modeled.
  for (r0,h0),(r1,h1) in zip(profile,profile[1:]):
   if r0==0 and r1==0:continue
   for i in range(n):
    a,b=math.tau*i/n,math.tau*(i+1)/n
    g.face(name,[(x+r0*math.cos(a),y+r0*math.sin(a),z+h0),(x+r0*math.cos(b),y+r0*math.sin(b),z+h0),(x+r1*math.cos(b),y+r1*math.sin(b),z+h1),(x+r1*math.cos(a),y+r1*math.sin(a),z+h1)],mat)
 lime=bpy.data.materials['North lime plaster'];earth=bpy.data.materials['North earthen plaster'];green=bpy.data.materials['North aged blue green'];red=bpy.data.materials['North weathered vermilion'];wood=bpy.data.materials['North anchae wood'];iron=bpy.data.materials['North forged iron']
 brass=color_mat('Sep29 aged brass',(.33,.22,.075),.72);wax=color_mat('Sep29 ivory candles',(.78,.70,.50));mat_straw=color_mat('Sep29 woven straw',(.38,.32,.18));mat_thread=color_mat('Sep29 straw cross weave',(.50,.43,.27));blue=color_mat('Sep29 indigo mat binding',(.028,.065,.13));clay=color_mat('Sep29 kitchen earth',(.24,.19,.13));black=color_mat('Sep29 cast iron',(.028,.028,.025),.32)
 # Tone saturated atlas pigments using independent material copies, so other
 # buildings never change as a side effect of sharing the old material.
 toned={}
 for o in scene.objects:
  if o.type!='MESH' or o.get('construction_building') not in ('sadang','sadangmun'):continue
  bid=o['construction_building']
  for i,m in enumerate(o.data.materials):
   if not m:continue
   redwood=m.get('surfaceKind')=='post' or (bid=='sadangmun' and m.get('surfaceKind') in ('wood','beam'))
   if not redwood:continue
   key=(m.name,bid)
   if key not in toned:toned[key]=tint_material(m,bid,(.46,.59,.68) if bid=='sadangmun' else (.64,.77,.82))
   o.data.materials[i]=toned[key]
 # Weathered gable boards from the supplied close-up: material swatches only,
 # mapped to each closed board, never a photograph pasted across a facade.
 for bid in ('sadang','sadangmun'):
  photo=OUT/'references/photos/sadang-side-sep29.png';art.ART=photo;art.base_image=bpy.data.images.load(str(photo),check_existing=True);art.materials={};art.mapped=[]
  art.regions={'wood':[(.54,.025,.60,.15),(.69,.025,.75,.15),(.83,.025,.89,.15)]}
  for o in scene.objects:
   if o.type=='MESH' and o.get('construction_building')==bid and any(k in o.name for k in ('gable thirty','gable 45x27','solid gable boarding')):art.art_uv(o,'wood');o['photoWeatheredBoard']=True
 # --- Byeoldang left kitchen, below the retained loft grille. ---
 origin,rot,world=basis('ansarang');g.BATCHES.clear();g.set_transform(world)
 wall=bpy.data.objects['V32.ansarang.left kitchen WW02 wall'];wall.data=wall.data.copy();oi=wall.matrix_world.inverted();inv=rot.transposed();kill=[]
 for ids in groups(wall.data):
  p=np.array([inv@(wall.matrix_world@wall.data.vertices[i].co-origin) for i in ids]);lo,hi=p.min(0),p.max(0)
  # Open down to the earth floor; keep the loft spandrel and existing grille.
  if lo[2]<2.20:
   if hi[2]<=2.20:kill+=ids
   else:
    for i,q in zip(ids,p):q[2]=max(q[2],2.20);wall.data.vertices[i].co=oi@world(q)
 if kill:
  bm=bmesh.new();bm.from_mesh(wall.data);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.verts[i] for i in kill],context='VERTS');bm.to_mesh(wall.data);bm.free()
 wall.data.update();changes.append(wall.name)
 nm='Sep29.ansarang.left kitchen'
 g.box(nm+'.room3 end post',(-5.46,-.48,1.83),(.20,.20,2.66),wood)
 g.box(nm+'.loft cross lintel',(-5.46,.825,2.165),(.20,2.61,.13),wood)
 g.box(nm+'.loft floor',(-4.355,.825,2.205),(2.21,2.61,.045),wood)
 for y in np.arange(-.32,2.1,.37):g.box(nm+'.loft underside joist',(-4.355,y,2.105),(2.21,.09,.15),wood)
 # The partition against room3 extends down to the lower kitchen floor.
 g.box(nm+'.room3 lower return',(-4.355,-.48,.73),(2.21,.12,.50),earth)
 g.box(nm+'.flue wall',(-3.005,.825,1.55),(.52,2.61,2.14),earth)
 # Built earthen hearth against the room, with actual firebox cavities below.
 for x0,x1 in [(-5.20,-4.85),(-4.55,-4.04),(-3.72,-3.29)]:g.box(nm+'.hearth pier',((x0+x1)/2,-.04,.72),(x1-x0,.64,.38),earth)
 g.box(nm+'.hearth top',(-4.245,-.04,.9475),(1.91,.64,.075),earth)
 g.box(nm+'.firebox back',(-4.245,-.315,.73),(1.91,.09,.40),black)
 for x,rad in [(-4.92,.18),(-4.30,.21),(-3.61,.24)]:
  lathe(nm+'.pot lid',x,-.04,.985,[(0,0),(rad,0),(rad*.94,.036),(rad*.6,.062),(0,.083),(0,0)],black)
  g.rod(nm+'.pot lid knob',(x,-.04,1.06),(x,-.04,1.11),.022,black,16)
 finish('ansarang',('loft cross lintel','loft floor','loft underside joist','room3 end post'))
 # --- Shrine: dimensional carved structure and the documented room contents. ---
 origin,rot,world=basis('sadang');g.BATCHES.clear();g.set_transform(world);nm='Sep29.sadang'
 # Side wall timber framing, visible in the side reference at roughly mid-height.
 for side in (-1,1):
  g.box(nm+'.side horizontal red rail',(side*3.388,.63,1.65),(.15,2.94,.13),red)
  g.box(nm+'.side lower red sill',(side*3.388,.63,.575),(.15,2.94,.13),red)
 # Painted rafters over the room continue into the porch structure.
 for x in np.arange(-3.22,3.30,.24):
  for y0,y1,z0,z1 in [(-.88,.60,2.94,3.47),(.60,2.10,3.47,2.94)]:g.rod(nm+'.interior green rafter',(x,y0,z0),(x,y1,z1),.066,green,16)
 # Full perimeter of the low interior rear wall; room is not an empty shell.
 for z in (.62,2.39):g.box(nm+'.interior rear rail',(0,2.045,z),(6.62,.10,.14),red)
 # Furniture proportions fitted inside the measured room. Cabinet sits on altar.
 table_z=1.33;tab_y=1.02
 g.box(nm+'.altar timber top',(0,tab_y,table_z),(2.48,.78,.065),wood)
 g.box(nm+'.altar moulded rim',(0,tab_y,table_z+.039),(2.55,.81,.027),wood)
 for x in (-1.04,1.04):
  for y in (tab_y-.28,tab_y+.28):g.box(nm+'.altar timber leg',(x,y,.94),(.085,.085,.81),wood)
  g.box(nm+'.altar side stretcher',(x,tab_y,.73),(.052,.61,.065),wood)
 g.box(nm+'.altar rear stretcher',(0,tab_y+.28,.75),(2.12,.055,.065),wood)
 profile=[(-1.19,1.296),(1.19,1.296),(1.19,1.13),(1.08,1.10),(.96,1.10),(.91,1.14),(.86,1.21),(.76,1.244),(-.76,1.244),(-.86,1.21),(-.91,1.14),(-.96,1.10),(-1.08,1.10),(-1.19,1.13)]
 for y in (tab_y-.31,tab_y+.31):d.extruded_profile(nm+'.altar carved timber apron',profile,y-.032,y+.032,wood)
 # Cabinet case is closed at back/sides and framed at front, with separate lattice.
 cb=1.39;cy=1.15
 g.box(nm+'.cabinet timber base',(0,cy,cb),(1.02,.43,.075),wood)
 g.box(nm+'.cabinet timber back',(0,cy+.19,1.92),(.88,.035,1.0),wood)
 for x in (-.455,.455):g.box(nm+'.cabinet timber side',(x,cy,1.92),(.045,.40,1.0),wood)
 for z in (1.45,2.41):g.box(nm+'.cabinet timber rail',(0,cy-.19,z),(.94,.05,.065),wood)
 for x in (-.435,0,.435):g.box(nm+'.cabinet timber stile',(x,cy-.205,1.925),(.035,.04,.89),wood)
 for x in np.arange(-.40,.415,.036):g.box(nm+'.cabinet timber lattice',(x,cy-.21,1.95),(.011,.025,.82),wood)
 for z in (1.55,1.60,1.66,2.22,2.28,2.33):g.box(nm+'.cabinet timber lattice',(0,cy-.212,z),(.83,.025,.011),wood)
 d.extruded_profile(nm+'.cabinet timber pediment',[(-.55,2.425),(.55,2.425),(.55,2.48),(0,2.60),(-.55,2.48)],cy-.23,cy+.23,wood)
 for x in (-.40,-.02,.02,.40):
  for z in (1.56,2.30):g.box(nm+'.cabinet brass fittings',(x,cy-.235,z),(.03,.008,.04),brass)
 for x in (-.047,.047):g.torus(nm+'.cabinet brass pulls',(x,cy-.25,1.96),.012,.0025,brass)
 # Pair of turned brass candlesticks with ivory candles.
 for x in (-.94,.94):
  lathe(nm+'.brass candle stand',x,.96,1.378,[(0,0),(.10,0),(.115,.012),(.09,.038),(.028,.065),(.018,.34),(.035,.36),(.025,.40),(.018,.46),(.095,.47),(.099,.485),(.027,.485),(.02,.50),(0,.50),(0,0)],brass)
  g.rod(nm+'.ivory candle',(x,.96,1.865),(x,.96,2.12),.023,wax,24)
 # Low foreground offering table and incense bowl; physically hollow vessel.
 g.box(nm+'.offering timber top',(0,.08,.91),(.76,.48,.045),wood)
 for x in (-.31,.31):
  for y in (-.09,.25):g.box(nm+'.offering timber leg',(x,y,.72),(.045,.045,.37),wood)
 g.box(nm+'.offering timber drawer',(0,-.11,.84),(.60,.025,.085),wood);g.rod(nm+'.drawer brass pull',(-.045,-.13,.84),(.045,-.13,.84),.006,brass)
 lathe(nm+'.brass incense bowl',0,.08,.936,[(0,0),(.095,0),(.10,.018),(.12,.034),(.16,.08),(.16,.13),(.18,.15),(.18,.165),(.147,.165),(.143,.125),(.13,.08),(.07,.05),(0,.05),(0,0)],brass)
 # Woven mat boards with subtle modelled warp/weft and indigo cloth bindings.
 for x in (-2.16,0,2.16):
  g.box(nm+'.woven straw mat',(x,.64,.545),(2.09,2.67,.014),mat_straw)
  for y in (-.69,1.97):g.box(nm+'.mat indigo hem',(x,y,.555),(2.09,.018,.006),blue)
  for xx in (x-1.036,x+1.036):g.box(nm+'.mat indigo hem',(xx,.64,.555),(.018,2.67,.006),blue)
  for yy in np.arange(-.67,1.95,.016):g.box(nm+'.mat woven reed',(x,float(yy),.554),(2.05,.004,.003),mat_thread)
 # Sculpted lotus bracket caps at all four front column centres. The cut edge
 # remains real green wood; motifs decorate it rather than replacing its volume.
 ochre=color_mat('Sep29 dancheong ochre',(.55,.34,.075));cream=color_mat('Sep29 dancheong cream',(.72,.62,.41));paintred=color_mat('Sep29 dancheong crimson',(.31,.048,.025));paintblue=color_mat('Sep29 dancheong blue',(.036,.16,.25))
 for x in (-3.38,-1.23,1.22,3.38):
  # Profile seen from the side: forward scroll with a curved bearing nose.
  prof=[(-.20,2.53),(.45,2.53),(.54,2.62),(.57,2.73),(.55,2.80),(.51,2.79),(.49,2.70),(.42,2.64),(.31,2.64),(.21,2.67),(.04,2.70),(-.20,2.70)]
  old=g.TRANSFORM;g.set_transform(lambda p,x=x:world((x+p[1],-2.10-p[0],p[2])))
  d.extruded_profile(nm+'.scroll bracket solid',prof,-.075,.075,green)
  path=[(-.17,2.58),(.18,2.58),(.38,2.58),(.47,2.65),(.515,2.745)]
  for side in (-1,1):
   for delta,mat,rad in [(0,cream,.009),(.020,paintred,.006),(.035,ochre,.004)]:stroke(nm+'.scroll painted contour',[(a,side*.076,z+delta) for a,z in path],rad,mat)
  g.set_transform(old)
  # Ring bands wrapped round the column: viewable from front and side.
  for z,mat in [(2.16,cream),(2.18,paintblue),(2.20,ochre),(2.22,paintred)]:g.rod(nm+'.painted column band',(x,-2.1,z),(x,-2.1,z+.012),.1215,mat,48)
  for side in (-1,1):
   y=-2.1+side*.1225;z=2.325
   g.rod(nm+'.lotus circular field',(x,y,z),(x,y+side*.003,z),.083,green,40)
   for k in range(8):
    t=k*math.tau/8;cx=x+math.cos(t)*.043;cz=z+math.sin(t)*.043
    poly=[(cx+.029*math.cos(q)*math.cos(t)-.016*math.sin(q)*math.sin(t),cz+.029*math.cos(q)*math.sin(t)+.016*math.sin(q)*math.cos(t)) for q in np.linspace(0,math.tau,17)[:-1]]
    d.extruded_profile(nm+'.lotus painted petal',poly,y+side*.004,y+side*.005,paintred)
    stroke(nm+'.lotus petal outline',[(a,y+side*.006,b) for a,b in poly+[poly[0]]],.0018,cream)
   g.rod(nm+'.lotus ochre centre',(x,y+side*.006,z),(x,y+side*.008,z),.016,ochre,24)
 obs=finish('sadang',('altar','cabinet timber','offering timber'))
 # Cabinet/altar use the same canonical wood, with a dark red lacquer factor.
 cache={}
 for o in obs:
  if any(t in o.name for t in ('altar','cabinet timber')):
   for i,m in enumerate(o.data.materials):
    if m.name not in cache:cache[m.name]=tint_material(m,'altar',(.48,.26,.24))
    o.data.materials[i]=cache[m.name]
 # Opening only the existing central pair for the interior review. Door leaves,
 # frame sizes and their closed positions remain unchanged in the native scene.
 c['doors'].append({'building':'sadang','id':'sadang_center','prefix':'North.sadang.survey sanctuary 1','hinges':[list(world((x,-.887,.64))) for x in (-.527,.517)],'rotationSigns':[-1,1],'width':1.08,'height':1.52,'doorBottom':.64,'state':'closed','authority':'Existing leaf side axes; outward opening inspection, angle not surveyed'})
 # --- Gate: raised scalloped iron escutcheons, ring knuckles and board joints. ---
 origin,rot,world=basis('sadangmun');g.BATCHES.clear();g.set_transform(world)
 for leaf,sign in [(1,-1),(2,1)]:
  nm=f'North.sadangmun.taegeuk leaves.leaf{leaf}'
  remove(nm+'.iron ring')
  x=sign*.064;z=1.09
  prof=[(x+.030*(1+.12*math.cos(6*t))*math.cos(t),z+.032+.045*(1+.12*math.cos(6*t))*math.sin(t)) for t in np.linspace(0,math.tau,33)[:-1]]
  d.extruded_profile(nm+'.Sep29 forged escutcheon',prof,-.049,-.042,iron)
  g.rod(nm+'.Sep29 ring knuckle',(x,-.049,z+.023),(x,-.072,z+.023),.012,iron,20)
  for i in range(64):
   a,b=math.tau*i/64,math.tau*(i+1)/64
   g.rod(nm+'.Sep29 forged ring',(x+.044*math.cos(a),-.070,z-.018+.044*math.sin(a)),(x+.044*math.cos(b),-.070,z-.018+.044*math.sin(b)),.006,iron,10)
  for xx in [sign*v for v in (.105,.215,.325,.435)]:
   for zz in (.52,1.68):
    # Small forged domed head, not a circular flat decal.
    g.rod(nm+'.Sep29 domed nail',(xx,-.041,zz),(xx,-.046,zz),.0095,iron,16,r2=.007)
  # Fine dark seams retain the THK30 board and individual stile structure.
  for xx in [sign*v for v in (.128,.252,.376)]:g.box(nm+'.Sep29 seam shadow',(xx,-.0406,1.10),(.0017,.0012,1.495),black)
 finish('sadangmun')
 # Weathered red on new red members uses the existing shrine atlas, preserving
 # all surfaces of each new solid beam and its cut ends.
 setup_art('sadang')
 for name in added:
  o=bpy.data.objects[name]
  if o['construction_building']=='sadang' and any(k in name for k in ('side horizontal red','side lower red','interior rear rail')):
   art.art_uv(o,'post');o.data.materials[0]=tint_material(o.data.materials[0],'sadang',(.64,.77,.82))
 g.set_transform(lambda p:p);bpy.context.view_layer.update()
 assert all(n in bpy.data.objects and fingerprint(bpy.data.objects[n])==f for n,f in protected.items()),'Non-target geometry/material bindings changed'
 assert all(geometry_fingerprint(bpy.data.objects[n])==f for n,f in roof_before.items()),'Corrected Sadang roof geometry changed'
 assert all(sha(OUT/r['file'])==r['sha256'] for r in sources)
 c['photoDetailCorrection']={'previousSceneSha256':sha(backup),'changedBuildings':sorted(targets),'protectedOtherMeshes':len(protected),'roofMeshesPreserved':len(roof_before),'addedMeshes':added,'removedMeshes':removed,'modifiedGeometry':changes,'layoutAndMainSectionsChanged':False,'sourcesManifest':'photo-detail-sources.json','printedDimensions':{'ansarangKitchenDepth':2.610,'ansarangKitchenWidth':2.210,'ansarangRoom3Depth':1.650,'ansarangLoftBoardThickness':.045},'fittedDetails':['Loft floor vertical datum 2.205 from photo/elevation fit','Furniture dimensions fitted to room; placement/order from interior photograph','Pigment fading, bracket scroll curves and ironwork relief','Portrait not placed; installation position unknown'],'skills':['reference-to-3d','closed-surface-uv-coverage','blender-modeling']}
 bpy.ops.wm.save_as_mainfile(filepath=str(source),compress=True);c['photoDetailCorrection']['correctedSceneSha256']=sha(source)
 (OUT/'detail-redraw-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
 (OUT/'photo-detail-audit.json').write_text(json.dumps(c['photoDetailCorrection'],ensure_ascii=False,indent=2),encoding='utf8')
 print('PHOTO DETAILS SAVED',len(added),'new meshes;',len(protected),'other meshes unchanged',flush=True)

if __name__=='__main__':main()
