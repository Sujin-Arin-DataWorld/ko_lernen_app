"""Native R12 material-only candidate. No geometry, UV, light, or camera edits."""
import bpy, sys, json, math, hashlib
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from audit_source import OUT, SOURCE, EXPECTED, state, bindings, bounds, write, sha

SCENE=bpy.data.scenes['Hangul Sori | Full Ildu Estate']
SCOPE_PATH=OUT.parents[2]/'WALL_SCOPE.json'
if SCOPE_PATH.exists():
    SCOPE=json.loads(SCOPE_PATH.read_text(encoding='utf-8'))
    KNOWN={s for g in SCOPE['knownDedicatedWallGroups'] for s in g['sourceObjects']}
else:
    PATCH=json.loads((OUT/'material-patch.json').read_text(encoding='utf-8'))
    KNOWN={r['object'] for r in PATCH['bindings'] if r['role'] not in ('yard','garden')}
PREFIXES=('ConnectionGarden.wall','ConnectionLeft.high wall lower','North.site.',
    'V27.left_changgo.wall','V27.right_ansarang.wall','V30.left_changgo.wall',
    'V30.right_ansarang.wall','GyeCraft.wall ','GyeCraft.main gate right wall')
YARD={'Illustrated lived courtyard earth':'yard','Garden worked earth with quiet pigment':'garden'}

def n(t,kind,name):
    o=t.nodes.new(kind);o.name='YW1 | '+name;o.label=name;return o
def link(t,s,d):t.links.new(s,d)
def mathn(t,op,a,b,name):
    o=n(t,'ShaderNodeMath',name);o.operation=op
    for i,v in enumerate([a,b]):
        if hasattr(v,'node'):link(t,v,o.inputs[i])
        else:o.inputs[i].default_value=v
    return o.outputs[0]
def vec(t,op,a,b,name):
    o=n(t,'ShaderNodeVectorMath',name);o.operation=op
    for i,v in enumerate([a,b]):
        if hasattr(v,'node'):link(t,v,o.inputs[i])
        else:o.inputs[i].default_value=v
    return o.outputs['Value'] if op in ('DISTANCE','DOT_PRODUCT','LENGTH') else o.outputs['Vector']
def noise(t,c,scale,detail,name):
    o=n(t,'ShaderNodeTexNoise',name);o.inputs['Scale'].default_value=scale;o.inputs['Detail'].default_value=detail;o.inputs['Roughness'].default_value=.57
    link(t,c,o.inputs['Vector']);return o
def ramp(t,fac,lo,hi,name):
    o=n(t,'ShaderNodeValToRGB',name);o.color_ramp.elements[0].color=(*lo,1);o.color_ramp.elements[1].color=(*hi,1);link(t,fac,o.inputs[0]);return o.outputs['Color']
def mix(t,a,b,f,name,kind='MIX'):
    o=n(t,'ShaderNodeMixRGB',name);o.blend_type=kind
    for i,v in enumerate([f,a,b]):
        if hasattr(v,'node'):link(t,v,o.inputs[i])
        else:o.inputs[i].default_value=v
    return o.outputs[0]
def mrange(t,s,a,b,name):
    o=n(t,'ShaderNodeMapRange',name);o.inputs['To Min'].default_value=a;o.inputs['To Max'].default_value=b;link(t,s,o.inputs['Value']);return o.outputs[0]

def compact_points():
    pts=[]
    for o in SCENE.objects:
        if o.type!='MESH' or o.hide_render:continue
        if any(w in o.name.lower() for w in ['stepping stone','finish.step','finish maru stepping']):
            if o.name in ('Estate.path.worn stepping stones','North.anchae.worn stepping stones'):
                # Existing compound path meshes: use native connected stone islands.
                parent=list(range(len(o.data.vertices)))
                def root(i):
                    while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
                    return i
                for e in o.data.edges:
                    a,b=e.vertices;parent[root(b)]=root(a)
                groups={}
                for v in o.data.vertices:groups.setdefault(root(v.index),[]).append(o.matrix_world@v.co)
                for vv in groups.values():
                    p=tuple(sum(v[i] for v in vv)/len(vv) for i in range(3))
                    if not any((Vector(p)-Vector(q)).length<1.35 for q in pts):pts.append(p)
                continue
            lo,hi=bounds(o);p=tuple((a+b)*.5 for a,b in zip(lo,hi))
            if hi[0]-lo[0]<3 and hi[1]-lo[1]<3 and not any((Vector(p)-Vector(q)).length<1.5 for q in pts):pts.append(p)
    if len(pts)>32:pts=[pts[round(i*(len(pts)-1)/31)] for i in range(32)]
    return pts
POINTS=compact_points()

def ground(original,role):
    m=original.copy();m.name='YW1 '+role+' | '+original.name;m['original_material']=original.name;m['candidate']='estate-yard-wall-r1';m['role']=role
    t=m.node_tree;t.nodes.clear()
    out=n(t,'ShaderNodeOutputMaterial','material output');bs=n(t,'ShaderNodeBsdfPrincipled','compacted earth');link(t,bs.outputs[0],out.inputs['Surface'])
    bs.inputs['Roughness'].default_value=.91;bs.inputs['Specular IOR Level'].default_value=.16
    geo=n(t,'ShaderNodeNewGeometry','world position; no UV repeat')
    p=vec(t,'MULTIPLY',geo.outputs['Position'],(1,1,0),'flat world metres')
    warp=noise(t,p,.19,2.2,'irregular broad earth domain')
    off=vec(t,'MULTIPLY',vec(t,'SUBTRACT',warp.outputs['Color'],(.5,.5,.5),'centred domain'),(2.8,2.8,0),'2.8 metre nonperiodic drift')
    warped=vec(t,'ADD',p,off,'warped metre coordinates')
    broad=noise(t,warped,.065,2.0,'broad hand tinted earth, 15 metre scale')
    mid=noise(t,warped,.65,2.3,'settled soil variation, 1.5 metre scale')
    pigment=mix(t,broad.outputs['Fac'],mid.outputs['Fac'],.32,'several soil scales')
    # Linear pigment values: quiet beige ochre, not gravel or terracotta.
    color=ramp(t,pigment,(.285,.218,.142),(.43,.35,.248),'warm tended earth pigment')
    compact=0.0
    if role=='yard':
        for i,point in enumerate(POINTS):
            d=vec(t,'DISTANCE',p,(point[0],point[1],0),'threshold distance %02d'%i)
            d=mathn(t,'MULTIPLY',d,d,'squared distance %02d'%i)
            mask=mathn(t,'EXPONENT',mathn(t,'MULTIPLY',d,-.52,'soft wear radius %02d'%i),0,'settled wear %02d'%i)
            compact=mathn(t,'MAXIMUM',compact,mask,'existing stone route %02d'%i)
        compact=mathn(t,'MULTIPLY',compact,mrange(t,mid.outputs['Fac'],.55,1,'irregular wear feather'),'worn soil softened')
        worn=ramp(t,pigment,(.335,.267,.184),(.45,.374,.277),'slightly paler consolidated footsteps')
        color=mix(t,color,worn,mathn(t,'MULTIPLY',compact,.48,'bounded wear colour'),'existing doorway wear')
    sweep=vec(t,'MULTIPLY',warped,(.7,35,1),'faint brushed soil along surface')
    fine=noise(t,sweep,3.0,1.8,'restrained fine swept earth')
    color=mix(t,color,mrange(t,fine.outputs['Fac'],.96,1.025,'quiet sweep pigment'),1,'soft physical soil tint','MULTIPLY')
    soil_meso=noise(t,warped,2.6,1.7,'quiet 30 to 50 centimetre tended earth')
    color=mix(t,color,mrange(t,soil_meso.outputs['Fac'],.91,1.065,'restrained mid scale earth tint'),1,'nonperiodic shallow loam variation','MULTIPLY')
    link(t,color,bs.inputs['Base Color'])
    micro=noise(t,warped,95,1.5,'very fine compacted earth pores')
    bump=n(t,'ShaderNodeBump','tended earth 1.6mm effective meso relief');bump.inputs['Distance'].default_value=.004;bump.inputs['Strength'].default_value=.4
    link(t,soil_meso.outputs['Fac'],bump.inputs['Height'])
    fine_bump=n(t,'ShaderNodeBump','fine quiet swept earth, no gravel');fine_bump.inputs['Distance'].default_value=.00075;fine_bump.inputs['Strength'].default_value=.24
    relief=mix(t,micro.outputs['Fac'],fine.outputs['Fac'],.24,'fine soil and restrained sweeping');link(t,relief,fine_bump.inputs['Height']);link(t,bump.outputs[0],fine_bump.inputs['Normal']);link(t,fine_bump.outputs[0],bs.inputs['Normal'])
    rough=mrange(t,mid.outputs['Fac'],.86,.96,'dry matte earth response')
    if role=='yard':rough=mathn(t,'SUBTRACT',rough,mathn(t,'MULTIPLY',compact,.065,'subtle consolidated sheen'),'slightly smoother tended route')
    link(t,rough,bs.inputs['Roughness'])
    return m

def wallrole(o,m):
    if not (o.name in KNOWN or o.name.startswith(PREFIXES)):return None
    name=o.name.lower();s=m.name.lower()
    if o.name.startswith(('North.site.jar platform','North.site.path worn','North.site.rear yard chimney','North.site.rear yard gate')):return None
    if any(w in name for w in ['fieldstone','rubble','end stones','bonded end','seated footing','basal fieldstones','lower end']):return 'stone'
    if 'earth core' in name or 'ochre core' in name or name.endswith('.core'):return 'mortar'
    if 'underside bedding' in name:return 'earthwall'
    if any(w in s for w in ['stone ','fieldstone','east stone','granite']):return 'stone'
    if any(w in s for w in ['ochre lime mortar','lower earth']):return 'mortar'
    return None

def wall(original,role):
    m=original.copy();m.name='YW1 '+role+' | '+original.name;m['original_material']=original.name;m['candidate']='estate-yard-wall-r1';m['role']=role
    t=m.node_tree
    bs=next((x for x in t.nodes if x.type=='BSDF_PRINCIPLED'),None)
    if not bs:return m
    old_color=bs.inputs['Base Color'].links[0].from_socket if bs.inputs['Base Color'].is_linked else None
    old_normal=bs.inputs['Normal'].links[0].from_socket if bs.inputs['Normal'].is_linked else None
    geo=n(t,'ShaderNodeNewGeometry','world anchored mineral surface')
    p=geo.outputs['Position']
    # Preserve the source's individual stone pigment/layout. Replacing it with a
    # continuous noise palette made the first full-estate pilot read as concrete.
    broad=noise(t,p,1.7 if role=='stone' else 1.0,2.2,'quiet mineral pigment')
    mid=noise(t,p,16 if role=='stone' else 11,2.3,'hand dressed stone planes' if role=='stone' else 'lime earth trowel marks')
    fine=noise(t,p,125 if role=='stone' else 90,1.8,'fine surface pores')
    if role=='stone':
        c=old_color if old_color else ramp(t,broad.outputs['Fac'],(.255,.235,.192),(.47,.445,.375),'muted warm fieldstone range')
        spec=.28;rr=(.70,.87);dist=.0022;strength=.32
    elif role=='mortar':
        c=ramp(t,broad.outputs['Fac'],(.28,.228,.161),(.37,.315,.23),'recessed ochre lime mortar')
        spec=.14;rr=(.87,.98);dist=.0015;strength=.30
    else:
        c=ramp(t,broad.outputs['Fac'],(.32,.266,.195),(.405,.345,.26),'earthen wall bedding')
        spec=.16;rr=(.83,.95);dist=.0018;strength=.30
    c=mix(t,c,mrange(t,mid.outputs['Fac'],.95,1.035,'bounded mineral plane tint'),1,'no high contrast flecks','MULTIPLY')
    link(t,c,bs.inputs['Base Color']);bs.inputs['Specular IOR Level'].default_value=spec;bs.inputs['Metallic'].default_value=0
    link(t,mrange(t,mid.outputs['Fac'],*rr,'mineral specific roughness'),bs.inputs['Roughness'])
    relief=mix(t,mid.outputs['Fac'],fine.outputs['Fac'],.16,'low contrast physical relief')
    bump=n(t,'ShaderNodeBump','surface only, no displacement');bump.inputs['Distance'].default_value=dist;bump.inputs['Strength'].default_value=strength;link(t,relief,bump.inputs['Height']);link(t,bump.outputs[0],bs.inputs['Normal'])
    if role=='stone' and old_normal:
        link(t,old_normal,bump.inputs['Normal'])
        for nn in t.nodes:
            if nn.type=='NORMAL_MAP':nn.inputs['Strength'].default_value*=.65
    return m

def main():
    global SOURCE
    SOURCE=Path(bpy.data.filepath).resolve()
    assert sha(SOURCE)==EXPECTED
    assert (OUT/'ildu-estate-yard-wall-r1.blend').resolve()!=SOURCE
    before=json.loads((OUT/'geometry-before.json').read_text(encoding='utf-8'))
    bind_before=json.loads((OUT/'bindings-before.json').read_text(encoding='utf-8'))
    records=[];cache={};untouched=[]
    for o in SCENE.objects:
        if o.type!='MESH':continue
        used={p.material_index for p in o.data.polygons}
        for i in sorted(used):
            if i>=len(o.material_slots):continue
            slot=o.material_slots[i];original=slot.material
            if not original:continue
            role=YARD.get(original.name) or wallrole(o,original)
            if not role:
                if o.name in KNOWN or o.name.startswith(PREFIXES):untouched.append([o.name,i,original.name])
                continue
            key=(original.name,role)
            if key not in cache:cache[key]=ground(original,role) if role in ('yard','garden') else wall(original,role)
            slot.link='OBJECT';slot.material=cache[key]
            records.append({'object':o.name,'slot':i,'role':role,'old':original.name,'new':slot.material.name,'bounds':bounds(o),'in_old_wall_scope':o.name in KNOWN})
    write('material-changes.json',records);write('untouched-wall-slots.json',untouched);write('compacted-soil-anchors.json',POINTS)
    after=json.loads(json.dumps(state()));write('geometry-after.json',after)
    assert before==after,'Geometry/UV/object transform changed'
    bind_after=bindings();write('bindings-after.json',bind_after)
    changed_keys={(r['object'],r['slot']) for r in records}
    non_target=[]
    for name,slots in bind_before.items():
        for i,s in enumerate(slots):
            if (name,i) not in changed_keys and list(bind_after[name][i])!=s:non_target.append([name,i])
    assert not non_target,'Nontarget material binding changed'
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ildu-estate-yard-wall-r1.blend'),compress=True)
    manifest={'status':'native-candidate-awaiting-render-review','canonical_source':str(SOURCE),'canonical_sha256':EXPECTED,'candidate':str(OUT/'ildu-estate-yard-wall-r1.blend'),'candidate_sha256':sha(OUT/'ildu-estate-yard-wall-r1.blend'),'geometry_uv_transforms_equal':True,'nontarget_material_bindings_equal':True,'changed_slots':len(records),'changed_objects':len({r['object'] for r in records}),'material_count':len(cache),'compaction_anchor_count':len(POINTS),'app_integrated':False,'new_three_gates_integrated':False,'source_unchanged':sha(SOURCE)==EXPECTED}
    write('manifest.json',manifest)
    print(json.dumps(manifest),flush=True)
if __name__=='__main__':main()
