"""Stone and plaster only, on preserved R4 Sarang native geometry."""
import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
f=c.f;p=c.p;D=P/'sarang-surface-r5'

def stone(old):
 m=old.copy();m.name='HS surface5 stone | '+old.name;t=m.node_tree
 bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED')
 geo=f.node(t,'ShaderNodeNewGeometry','R5 stone metric coordinates');co=geo.outputs['Position']
 seed=p.craft.illustration.member_value(t)
 col=f.ramp(t,seed,[(0,f.rgb('9D8F7A')),(.35,f.rgb('BEAC90')),(.70,f.rgb('CDBDA2')),(1,f.rgb('DDD0B9'))],'R5 related individual mineral bodies')
 clouds=f.noise(t,co,7.5,2.4,'R5 mineral cloud boundaries')
 wash=f.ramp(t,clouds,[(.25,(.49,.48,.44,1)),(.43,(.76,.74,.68,1)),(.60,(1,1,1,1)),(.76,(1.07,1.04,.99,1))],'R5 visible warm grey mineral cloud')
 col=f.mix(t,col,wash,.72,'R5 mineral colour depth','MULTIPLY')
 grains=f.noise(t,co,28,2.2,'R5 medium mineral flecks')
 flecks=f.ramp(t,grains,[(.29,(.20,.17,.13,1)),(.37,(.43,.38,.29,1)),(.46,(1,1,1,1)),(.70,(1.08,1.06,1.01,1))],'R5 separated iron mineral flecks')
 col=f.mix(t,col,flecks,.68,'R5 readable sparse freckles','MULTIPLY')
 vor=f.node(t,'ShaderNodeTexVoronoi','R5 granular pinholes');t.links.new(co,vor.inputs['Vector']);vor.inputs['Scale'].default_value=57
 pores=f.ramp(t,vor.outputs['Distance'],[(.055,(.15,.12,.09,1)),(.17,(.51,.45,.36,1)),(.24,(1,1,1,1))],'R5 small inset pores')
 col=f.mix(t,col,pores,.68,'R5 occasional pitted stone','MULTIPLY')
 h=f.mix(t,grains,pores,.45,'R5 mineral relief')
 f.normal(t,bs,h,.006,.014,.30)
 f.attach(t,bs.inputs['Roughness'],f.scalar(t,'ADD',.73,f.scalar(t,'MULTIPLY',grains,.15)))
 bs.inputs['Specular IOR Level'].default_value=.23
 f.attach(t,bs.inputs['Base Color'],f.contact(t,col,'stone'))
 m['surface5']='stone';return prune(m)

def wall(source):
 m=source.copy();m.name='HS surface5 restored limewash | '+source.name;t=m.node_tree
 bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED')
 tex=next(n for n in t.nodes if n.type=='TEX_IMAGE' and n.image and n.image.name.startswith('gye-limewash-brush-v26'))
 print('WALL IMAGE',tex.image.name,list(tex.image.size),bool(tex.image.packed_file),tex.image.filepath,flush=True)
 assert tex.image.size[0]>0
 # Preserve authored UV mapping and independent broad/trowel/brush normal layers.
 norm=next((n for n in t.nodes if n.label=='HS white r2 brush luma normalization'),None)
 g=norm.outputs[0] if norm else f.gray(t,tex.outputs['Color'],'R5 original limewash density')
 col=f.ramp(t,g,[(.08,f.rgb('B5AB97')),(.38,f.rgb('C9BFAC')),(.70,f.rgb('D5CCBA')),(.94,f.rgb('DDD5C6'))],'R5 warm ivory original hand plaster')
 f.attach(t,bs.inputs['Base Color'],col)
 f.attach(t,bs.inputs['Roughness'],.88);bs.inputs['Specular IOR Level'].default_value=.20
 # Earlier trowel surface is kept; remove only decorative paint overlays.
 normal=next((n for n in t.nodes if n.label=='HS white r2 shallow trowel facet gradients'),None)
 if normal:t.links.new(normal.outputs['Normal'],bs.inputs['Normal'])
 else:f.normal(t,bs,g,.0012,.002,.18)
 m['surface5']='plaster';m['restoredImage']=tex.image.name
 return prune(m)

def prune(m):
 t=m.node_tree;keep=p.live(t)
 for n in list(t.nodes):
  if n not in keep:t.nodes.remove(n)
 return m

def main():
 D.mkdir(exist_ok=True);v=p.read(P/'sarang-detail-r4/verification.json');src=P/'sarang-detail-r4'/v['native']
 assert p.sha(src)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(src));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 before=p.architecture(obs);assert before==v['geometry'];lighting=c.fixed_scene(sc)
 oldsrc=P/'sarang/sarang-hangulsori-r2-refined.blend';oldhash=p.sha(oldsrc)
 names=[r['material'] for r in p.read(P/'wall-source-r5.json')]
 with bpy.data.libraries.load(str(oldsrc),link=False) as (a,b):b.materials=list(names)
 restored=dict(zip(names,b.materials));cache={};unchanged={};changes=[]
 for row in p.read(P/'sarang/material-inventory.json'):
  ob=sc.objects[row['object']];sl=ob.material_slots[row['slot']];kind=row['role']
  if row['preserved'] or kind not in ('stone','plaster'):
   unchanged[(ob.name,row['slot'])]=p.s.material_state(sl.material);continue
  key=(sl.material.name,kind)
  if key not in cache:cache[key]=stone(sl.material) if kind=='stone' else wall(restored[row['material']])
  sl.link='OBJECT';sl.material=cache[key];changes.append(dict(object=ob.name,slot=row['slot'],kind=kind))
 assert p.architecture(obs)==before;assert c.fixed_scene(sc)==lighting
 assert unchanged=={k:p.s.material_state(sc.objects[k[0]].material_slots[k[1]].material) for k in unchanged}
 assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
 sc.render.resolution_x=1800;sc.render.resolution_y=1200;sc.cycles.samples=96
 bpy.context.preferences.filepaths.save_version=0;native=D/'sarang-surface-r5.blend';assert not native.exists()
 bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
 assert p.architecture([sc.objects[n] for n in lock['objects']])==before;assert c.fixed_scene(sc)==lighting
 assert unchanged=={k:p.s.material_state(sc.objects[k[0]].material_slots[k[1]].material) for k in unchanged}
 p.write(D/'verification.json',dict(geometry=before,reopened=True,fixedCameraLightingExposure=True,otherMaterialsUnchanged=True,processBindingCount=711,source=str(src),sourceSha256=v['nativeSha256'],native=native.name,nativeSha256=p.sha(native),restoredWallSource=str(oldsrc),restoredWallSourceSha256=oldhash,changes=changes,userApproved=False,runtimeIntegrated=False))
 sc.render.resolution_x=1200;sc.render.resolution_y=800
 p.write(D/'preview.json',p.render(sc,D,'preview.png',48))
 assert p.sha(src)==v['nativeSha256'] and p.sha(oldsrc)==oldhash and c.preserve_check()
 print('R5 STONE AND WALL PREVIEW VERIFIED',flush=True)
if __name__=='__main__':main()
