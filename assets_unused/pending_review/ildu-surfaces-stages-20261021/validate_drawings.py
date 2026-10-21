"""Independent saved-mesh measurements. Passing is NOT whole-drawing certification."""
import bpy,json,sys,hashlib,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
P=Path(__file__).resolve().parent
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['left','right','shrine']
# Numbers transcribed independently from 080–083, 089–093 and 086–088.
expected={
 'left':dict(axis=2.08,post=.155,door=1.790,thickness=.025,boards=8,depth=3.11,rafters=10,section=(.120,.120),rafterDepth=2.89,nails=32,rails=8,rail=(.045,.060),boardT=.025),
 'right':dict(axis=1.46,post=.180,door=1.140,thickness=.030,boards=4,depth=1.86,rafters=7,section=(.080,.100),rafterDepth=1.66,nails=24,rails=6,rail=(.035,.065),boardT=.025),
 'shrine':dict(axis=1.35,post=.170,door=1.020,thickness=.030,boards=8,depth=1.94,rafters=7,section=(.075,.090),rafterDepth=1.80,nails=16,rails=6,rail=(.065,.095),boardT=.030)}
summary=[]
for key in args:
 f=P/(key+'-new.blend');bpy.ops.wm.open_mainfile(filepath=str(f))
 sc=next(s for s in bpy.data.scenes if s.get('drawingSource'));bpy.context.window.scene=sc;dg=bpy.context.evaluated_depsgraph_get();dg.update()
 objects=[o for o in sc.objects if o.type=='MESH' and not o.get('studio')];bounds={};bvhs={}
 for o in objects:
  eo=o.evaluated_get(dg);me=eo.to_mesh();vs=[eo.matrix_world@v.co for v in me.vertices];fs=[tuple(p.vertices) for p in me.polygons]
  bounds[o.name]=([min(v[i] for v in vs) for i in range(3)],[max(v[i] for v in vs) for i in range(3)])
  if any(s in o.name for s in ('boarding','rafter ','dori','ridge bearing','cross bearing')):bvhs[o.name]=BVHTree.FromPolygons(vs,fs)
  eo.to_mesh_clear()
 checks=[]
 def check(name,ok,actual=None):checks.append(dict(name=name,passed=bool(ok),actual=actual))
 def group(s):return [o for o in objects if s in o.name]
 def dim(o):
  a,b=bounds[o.name];return [b[i]-a[i] for i in range(3)]
 def rawdim(o):
  verts=raw(o)
  return [max(v[i] for v in verts)-min(v[i] for v in verts) for i in range(3)]
 def close(a,b,tol=.0002):return abs(a-b)<=tol
 def raw(o):return [o.matrix_world@v.co for v in o.data.vertices]
 exp=expected[key]
 posts=group('timber.main post')+group('timber.round main post')
 xs=sorted((bounds[o.name][0][0]+bounds[o.name][1][0])/2 for o in posts)
 check('printed column centre spacing',len(xs)==2 and close(xs[1]-xs[0],exp['axis']),xs)
 check('printed main post section',all(close(dim(o)[0],exp['post']) and close(dim(o)[1],exp['post']) for o in posts),[dim(o)[:2] for o in posts])
 doors=group('door.board ')
 check('door plank count and printed thickness',len(doors)==exp['boards'] and all(close(dim(o)[1],exp['thickness']) for o in doors),[dim(o)[1] for o in doors])
 doorSpan=max(bounds[o.name][1][0] for o in doors)-min(bounds[o.name][0][0] for o in doors)
 check('door pair width; right inferred from two570 rails',close(doorSpan,exp['door'],.003),doorSpan)
 if key=='shrine':check('086 door panel height1500',all(close(dim(o)[2],1.5) for o in doors))
 nails=group('iron.board nail');check('drawing front nail count',len(nails)==exp['nails'],len(nails))
 rails=group('door.rear rail');actualRails=[tuple(round(v,4) for v in dim(o)[1:]) for o in rails]
 check('drawing rear rail count and sections',len(rails)==exp['rails'] and (all(v==exp['rail'] for v in actualRails) if key!='shrine' else actualRails.count((.065,.095))==4 and actualRails.count((.034,.054))==2),actualRails)
 rafters=group('roof.round rafter')+group('roof.square rafter');sections=[]
 for ob in rafters:
  mid=[v for v in raw(ob) if abs(v.y)<.0001]
  sections.append([max(v[i] for v in mid)-min(v[i] for v in mid) for i in (0,2)])
 check('drawing rafter count and body section',len(rafters)==exp['rafters'] and all(close(s[0],exp['section'][0]) and close(s[1],exp['section'][1]) for s in sections),sections)
 check('printed rafter projected length',all(close(dim(o)[1],exp['rafterDepth']) for o in rafters),[dim(o)[1] for o in rafters])
 boards=group('roof.pitched boarding') if key!='shrine' else group('roof.boarding THK30')
 thickness=[]
 for ob in boards:
  a,b=bounds[ob.name];x=(a[0]+b[0])/2;y=(a[1]+b[1])/2+.0002
  top=bvhs[ob.name].ray_cast(Vector((x,y,b[2]+.10)),Vector((0,0,-1)),1)[0]
  bot=bvhs[ob.name].ray_cast(Vector((x,y,a[2]-.10)),Vector((0,0,1)),1)[0]
  thickness.append(top.z-bot.z if top is not None and bot is not None else None)
 check('separate boarding measured thickness',len(boards)>5 and all(t is not None and close(t,exp['boardT'],.0005) for t in thickness),thickness)
 gaps=[]
 for ob in rafters:
  a,b=bounds[ob.name];x=(a[0]+b[0])/2
  for y in (-.47,.017,.47):
   hit=bvhs[ob.name].ray_cast(Vector((x,y,b[2]+.1)),Vector((0,0,-1)),2)[0]
   hits=[bvhs[q.name].ray_cast(Vector((x,y,a[2]-.1)),Vector((0,0,1)),2)[0] for q in boards]
   hits=[h.z for h in hits if h is not None]
   gaps.append(min(hits)-hit.z if hit is not None and hits else None)
 check('actual rafter-to-boarding ray contacts <=1mm',all(g is not None and abs(g)<.001 for g in gaps),gaps)
 if key=='left':
  check('080/083 four octagonal props and four X braces',len(group('octagonal inclined prop'))==4 and len(group('side X brace'))==4)
  check('080 no invented stair flight',not group('foundation.step'))
  check('081 central dori150x150',all(close(dim(o)[1],.150) and close(dim(o)[2],.150) for o in group('timber.central dori')))
  check('081/082 side dori120x120',len(group('timber.side dori'))==2 and all(close(dim(o)[1],.120) and close(dim(o)[2],.120) for o in group('timber.side dori')))
 elif key=='right':
  check('092 ridge dori180x230',all(close(dim(o)[1],.180) and close(dim(o)[2],.230) for o in group('timber.central dori')))
  check('089/092 shinbangmok210x210x1400',all(all(close(a,b) for a,b in zip(dim(o),(.210,1.4,.210))) for o in group('timber.shinbangmok')))
  values=[]
  for i in range(5):
   members=group('foundation.step %d block'%(i+1));values.append(max(bounds[o.name][1][2] for o in members))
  check('092 unequal stair rise datums',all(close(a,b,.008) for a,b in zip(values,(.20,.35,.50,.63,.75))),values)
 else:
  dori=group('timber.dori')
  check('086/087 two longitudinal dori82x150x1800',len(dori)==2 and all(all(close(a,b) for a,b in zip(rawdim(o),(.082,1.8,.15))) for o in dori),[{'raw':rawdim(o),'bevelled':dim(o)} for o in dori])
  check('086 transverse bearing70x80',len(group('cross bearing 70x80'))==2)
  houses=group('door.pivot housing');bottom=min(bounds[o.name][0][2] for o in houses);top=max(bounds[o.name][1][2] for o in houses)
  check('086 pivot outside height1600',close(top-bottom,1.6),top-bottom)
 supports=group('timber.ridge bearing') if key=='left' else group('timber.central dori') if key=='right' else group('timber.cross bearing 70x80')
 contacts=[]
 for member in supports:
  a,b=bounds[member.name];y=(a[1]+b[1])/2
  for ob in rafters:
   ra,rb=bounds[ob.name];x=(ra[0]+rb[0])/2
   top=bvhs[member.name].ray_cast(Vector((x,y,b[2]+.1)),Vector((0,0,-1)),2)[0]
   bot=bvhs[ob.name].ray_cast(Vector((x,y,ra[2]-.1)),Vector((0,0,1)),2)[0]
   contacts.append(bot.z-top.z if top is not None and bot is not None else None)
 check('actual dori-to-rafter ray contacts <=2mm',all(g is not None and abs(g)<.002 for g in contacts),contacts)
 clay=[o for o in objects if o.data.materials and o.data.materials[0].name=='Fresh | clay'];points=[p for o in clay for p in raw(o)]
 wing_points=[p for o in group('roof.wing pan')+group('roof.wing cover') for p in raw(o)]
 half_width={'left':1.54,'right':1.5,'shrine':1.285}[key]
 shoulder={'left':1.18,'right':1.14,'shrine':.82}[key]
 corner={'left':.18,'right':.16,'shrine':.19}[key]
 outer_y=max(abs(p.y) for p in wing_points if abs(p.x)>half_width-.002)
 inner_y=max(abs(p.y) for p in wing_points if abs(p.x)<shoulder+.002)
 check('roof wing fan corners retain inner depth and turn inward at outer edge',
       close(inner_y,exp['depth']/2,.005) and close(outer_y,exp['depth']/2-corner,.005),
       {'innerHalfDepth':inner_y,'outerHalfDepth':outer_y,'interpretedCornerInset':corner})
 span=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
 check('printed roof front-back span within5mm',close(span[1],exp['depth'],.005),span)
 bad=[]
 for ob in clay:
  edges={}
  for p in ob.data.polygons:
   ids=list(p.vertices)
   for a,b in zip(ids,ids[1:]+ids[:1]):e=tuple(sorted((a,b)));edges[e]=edges.get(e,0)+1
  if any(n!=2 for n in edges.values()):bad.append(ob.name)
 check('closed ceramic shells',not bad,bad)
 check('finite geometry',all(math.isfinite(x) for o in objects for v in o.data.vertices for x in v.co))
 check('no imported legacy mesh or linked library',not bpy.data.libraries and all(o.get('source')=='new construction from drawing' for o in objects))
 surface={kind:bpy.data.materials.get('Fresh | '+kind) for kind in ('wood','red','blue','green','clay')}
 image_names={kind:{node.image.name for node in mat.node_tree.nodes if node.type=='TEX_IMAGE' and node.image and node.image.packed_file} if mat else set() for kind,mat in surface.items()}
 check('native wood and clay samples packed in Blender source',
       surface['clay'] and any(surface[kind] for kind in ('wood','red','blue','green'))
       and all(mat.get('surfaceRevision','').startswith('R6') for mat in surface.values() if mat)
       and all({'wood-long-members-trim-v1.png','wood-endgrain-atlas-v1.png'}<=image_names[kind] for kind in ('wood','red','blue','green') if surface[kind])
       and {'gye-clay-matte-v26.png','tile-blue-charcoal-v1.png'}<=image_names['clay'],{kind:sorted(names) for kind,names in image_names.items()})
 stone_mat=bpy.data.materials.get('Fresh | stone')
 stone_images={node.image.name for node in stone_mat.node_tree.nodes if node.type=='TEX_IMAGE' and node.image and node.image.packed_file} if stone_mat else set()
 check('native quiet fieldstone sample packed; rejected gravel sample unused',stone_mat and 'gye-fieldstone-brush-v26.png' in stone_images and 'hanok-granite-v1.png' not in stone_images,sorted(stone_images))
 report=dict(gate=key,file=str(f),sha256=hashlib.sha256(f.read_bytes()).hexdigest(),checks=checks,allChecksPassed=all(q['passed'] for q in checks),fullDrawingMatchClaimed=False,userApproved=False,geometryDesignApprovedByUser=True,surfaceApprovedByUser=False)
 (P/(key+'-validation.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');summary.append(report)
 print(json.dumps({'gate':key,'passed':report['allChecksPassed'],'failures':[q for q in checks if not q['passed']]},ensure_ascii=False),flush=True)
(P/'validation-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
