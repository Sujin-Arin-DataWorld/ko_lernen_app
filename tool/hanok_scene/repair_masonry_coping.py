"""Remove building-only timber accidentally emitted on masonry wall caps."""
from pathlib import Path
import bpy, hashlib, json, math, sys
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TIMBER_SUFFIXES=('.rafters','.lower exposed rafters','.eave beam','.gable timber')

def is_wall(o):
    return o.type=='MESH' and o.get('construction_building')=='north_site' and any(k in o.name for k in (' coping',' earth core',' irregular stone',' inset petal',' inset central petal',' earthen tile bedding'))

def fingerprint(o, ignore_uv_layers=(), material_name_aliases=None):
    h=hashlib.sha256();h.update(np.asarray(o.matrix_world,dtype=np.float32).tobytes())
    for collection,prop,width,dtype in ((o.data.vertices,'co',3,np.float32),(o.data.loops,'vertex_index',1,np.int32),(o.data.polygons,'material_index',1,np.int32)):
        values=np.empty(len(collection)*width,dtype=dtype);collection.foreach_get(prop,values);h.update(values.tobytes())
    for layer in o.data.uv_layers:
        if layer.name in ignore_uv_layers:continue
        h.update(layer.name.encode());values=np.empty(len(layer.data)*2,dtype=np.float32);layer.data.foreach_get('uv',values);h.update(values.tobytes())
    aliases=material_name_aliases or {}
    h.update(json.dumps([aliases.get(m.name,m.name) if m else None for m in o.data.materials]).encode())
    return h.hexdigest()

def masonry_audit(scene):
    records=[];violations=[]
    for o in scene.objects:
        if o.type!='MESH':continue
        n=o.name.lower()
        masonry=is_wall(o) or any(t in n for t in ('fieldstone','stone plinth','stone base','granite','irregular stone','earth core','wall to sarang','wall to ansarang','wall to warehouse'))
        if not masonry:continue
        used=[o.data.materials[i] for i in sorted({p.material_index for p in o.data.polygons})]
        bad=[m.name for m in used if m and (m.get('surfaceKind') in ('wood','post','beam','floor','illustrated_longgrain','illustrated_endgrain') or any(t in m.name.lower() for t in ('pine','walnut','timber',' wood ',' post ',' beam ')))]
        records.append({'object':o.name,'materials':[m.name if m else None for m in used],'woodMaterials':bad})
        if bad:violations.append(records[-1])
    return {'objects':len(records),'woodOnMasonry':violations,'assignments':records}

def apply(scene,c):
    if c.get('wallFinishCorrection'):return c['wallFinishCorrection']
    protected={o.name:fingerprint(o) for o in scene.objects if o.type=='MESH' and not is_wall(o)}
    removed=[]
    for o in list(scene.objects):
        if is_wall(o) and ' coping' in o.name and o.name.endswith(TIMBER_SUFFIXES):
            removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
    assert len(removed)==4*len(c['walls']), (len(removed),len(c['walls']))
    clay=bpy.data.materials['North earthen plaster'];added=[]
    for wall in c['walls']:
        a,b=np.asarray(wall['start']),np.asarray(wall['stop']);delta=b-a;length=float(np.linalg.norm(delta));direction=delta/length;normal=np.array([-direction[1],direction[0]])
        h=wall['height'];base=wall['base']
        # Solid earth packing under the ceramic coping; no exposed timber.
        section=[(-.23,h-.065),(.23,h-.065),(.285,h-.025),(0,h+.055),(-.285,h-.025)]
        vertices=[(*(a+direction*x+normal*y),base+z) for x in (0,length) for y,z in section]
        faces=[tuple(reversed(range(5))),tuple(range(5,10))]+[(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)]
        nm='North.site.'+wall['name']+' earthen tile bedding';mesh=bpy.data.meshes.new(nm);mesh.from_pydata(vertices,[],faces);mesh.materials.append(clay)
        o=bpy.data.objects.new(nm,mesh);scene.collection.objects.link(o)
        for k,v in {'construction_building':'north_site','northExtension':True,'construction_first':1,'construction_last':99,'source_object_name':nm}.items():o[k]=v
        added.append(nm)
    bpy.context.view_layer.update()
    assert all(n in bpy.data.objects and fingerprint(bpy.data.objects[n])==fp for n,fp in protected.items()),'Non-wall surface or geometry changed'
    audit=masonry_audit(scene);assert not audit['woodOnMasonry'],audit['woodOnMasonry']
    result={'removedBuildingRoofTimbers':removed,'earthenBedding':added,'protectedNonWallMeshes':len(protected),'protectedMeshFingerprintSha256':hashlib.sha256(json.dumps(protected,sort_keys=True).encode()).hexdigest(),'masonryObjectsChecked':audit['objects'],'woodOnMasonry':audit['woodOnMasonry'],'authority':'Photographed earth-and-fieldstone walls with ceramic coping; bedding section is a construction interpretation, not a printed survey dimension'}
    c['wallFinishCorrection']=result
    (OUT/'wall-material-audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf8')
    return result

if __name__=='__main__':
    path=OUT/'detail-redraw.blend';before=hashlib.sha256(path.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(path));c=json.loads((OUT/'detail-redraw-contract.json').read_text(encoding='utf8'))
    result=apply(bpy.context.scene,c)
    bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
    after=hashlib.sha256(path.read_bytes()).hexdigest()
    result['previousSceneSha256']=before;result['correctedSceneSha256']=after
    result['equivalentUnchangedViews']=['jar-gate','jar-gate-front','jar-gate-back','sadangmun','anchae','ansarang','sadang','anchae-corner','anchae-kitchen','anchae-hall','sadang-joinery']
    result['equivalentUnchangedModels']=['jar-gate','sadangmun','anchae','ansarang','sadang']
    (OUT/'detail-redraw-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
    print('WALL CORRECTION',len(result['removedBuildingRoofTimbers']),'removed;',result['masonryObjectsChecked'],'masonry objects;',result['protectedNonWallMeshes'],'unchanged non-wall meshes',flush=True)
