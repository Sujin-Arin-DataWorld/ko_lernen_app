from pathlib import Path
import json,copy,hashlib,numpy as np
import glb_parts as glb
ROOT=Path(__file__).resolve().parents[2];REVIEW=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';BASE=REVIEW/'terrain';OUT=REVIEW/'side-connections'
SOURCE=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922/existing-estate-v36')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
contract=json.loads((OUT/'connection-contract.json').read_text(encoding='utf8'))
assert sha(SOURCE/'pair-v26.glb')==contract['sourceRealtimeSha256']
source,srcblob=glb.read(SOURCE/'pair-v26.glb')
selected=[i for i,n in enumerate(source['nodes']) if n.get('extras',{}).get('source_object_name') in contract['placements'] and n.get('extras',{}).get('construction_building')=='changgo']
assert len(selected)==199,len(selected)
patch,extra=glb.subset(source,srcblob,selected)
boarding_materials={}
for n in patch['nodes']:
    key=n['extras']['source_object_name'];dz=contract['placements'][key]['zOffset']
    assert 'matrix' not in n
    if dz:n.setdefault('translation',[0.,0.,0.])[1]+=dz
    if contract['placements'][key]['warehouseWallExtension']:
        assert 'rotation' not in n and 'scale' not in n and 'matrix' not in n
        basis=np.array([[1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1]])
        affine=basis@np.array(contract['warehouseWallExtension']['worldMatrixRows'])@np.linalg.inv(basis)
        affine[:3,3]+=np.array(n.pop('translation',[0,0,0]));n['matrix']=affine.T.ravel().tolist()
    n['extras']['connectionPlacementZ']=dz
    # The retained gate boarding has explicit upper/lower faces. Render both
    # winding directions so small ridge openings reveal wood, not the sky.
    if '.roof.boarding' in key:
        for primitive in patch['meshes'][n['mesh']]['primitives']:
            oldmat=primitive['material']
            if oldmat not in boarding_materials:
                mat=copy.deepcopy(patch['materials'][oldmat]);mat['doubleSided']=True;mat['name']=mat.get('name','Wood')+' gate boarding both faces'
                boarding_materials[oldmat]=len(patch['materials']);patch['materials'].append(mat)
            primitive['material']=boarding_materials[oldmat]
glb.write(OUT/'source-components.glb',patch,extra)
doc,blob=glb.read(BASE/'pair-corrected.glb');before=copy.deepcopy(doc);original=blob
removed=[i for i,n in enumerate(doc['nodes']) if n.get('extras',{}).get('source_object_name')=='TerrainFix.continuous rising courtyard'];assert len(removed)==1
for scene in doc['scenes']:scene['nodes']=[i for i in scene['nodes'] if i not in removed]
doc,blob=glb.append(doc,blob,patch,extra)
crafted,craftedblob=glb.read(OUT/'crafted-gates.glb');doc,blob=glb.append(doc,blob,crafted,craftedblob)
ansarang,ansarangblob=glb.read(OUT/'crafted-ansarang.glb');doc,blob=glb.append(doc,blob,ansarang,ansarangblob)
terrain,terrainblob=glb.read(OUT/'terrain-patch.glb');doc,blob=glb.append(doc,blob,terrain,terrainblob)
forecourt=None
if 'forecourt' in contract:
    forecourt,forecourtblob=glb.read(OUT/'crafted-forecourt.glb');doc,blob=glb.append(doc,blob,forecourt,forecourtblob)
doc['asset']['extras']={'approvedPairSha256':sha(BASE/'pair-corrected.glb'),'review':'Both side gates, warehouse and graded yards attached to approved pair'}
digest=glb.write(OUT/'connected.glb',doc,blob)
actual,binary=glb.read(OUT/'connected.glb')
assert binary[:len(original)]==original
for k in ['nodes','meshes','materials']:assert actual[k][:len(before[k])]==before[k]
report={'glbSha256':digest,'bytes':(OUT/'connected.glb').stat().st_size,'approvedPairSha256':sha(BASE/'pair-corrected.glb'),'approvedBinaryBytesRetained':len(original),'approvedNodesMeshesMaterialsIdentical':True,'detachedOldGroundNodes':removed,'addedSourceComponents':len(selected),'addedTerrainObjects':len(terrain['nodes']),'sourceGeometryAndTexturesRecompressed':False,'sourceComponentBytes':len(extra),'runtimePromoted':False}
report['craftedGateAndGardenNodes']=len(crafted['nodes']);report['nativeSceneSha256']=sha(OUT/'scene.blend');report['craftedGlbSha256']=sha(OUT/'crafted-gates.glb')
report['craftedAnsarangNodes']=len(ansarang['nodes']);report['craftedAnsarangSha256']=sha(OUT/'crafted-ansarang.glb')
if forecourt is not None:report['forecourtNodes']=len(forecourt['nodes']);report['forecourtSha256']=sha(OUT/'crafted-forecourt.glb')
(OUT/'delivery-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(json.dumps(report))
