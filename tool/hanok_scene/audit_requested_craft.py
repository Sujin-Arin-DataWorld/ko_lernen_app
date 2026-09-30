"""Native and delivered evidence for timber art, paving and moved rear walls."""
import hashlib
import json
import struct
import bpy
from apply_heritage_wood import UV_NAME as WOOD_UV
from apply_platform_stone import UV_NAME as PAVING_UV
from repair_masonry_coping import fingerprint
from repair_gokgan_clearance import footprint, polygon_distance
from northern_timber_sections import groups


def audit_requested_craft(contract,glb_path,directory):
    with glb_path.open('rb') as file:
        file.seek(12);length=struct.unpack('<I',file.read(4))[0];file.seek(20);web=json.loads(file.read(length))
        binary_start=28+length
        def image_sha(material):
            tex=material['pbrMetallicRoughness']['baseColorTexture']
            image=web['images'][web['textures'][tex['index']]['source']]
            view=web['bufferViews'][image['bufferView']]
            file.seek(binary_start+view.get('byteOffset',0))
            return hashlib.sha256(file.read(view['byteLength'])).hexdigest()
        wood=contract.get('gyeHeritageWood',{});material_findings={}
        for name,row in wood.get('materials',{}).items():
            material=bpy.data.materials[name]
            shader=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            node=shader.inputs['Base Color'].links[0].from_node
            path=directory/'materials'/row['image']
            native_good=(node.type=='TEX_IMAGE' and node.image and
                         hashlib.sha256(path.read_bytes()).hexdigest()==row['sha256'])
            variants=[m for m in web['materials'] if m.get('name')==name]
            web_good=bool(variants) and all(image_sha(m)==row['sha256'] and
                m.get('extras',{}).get('gyeHeritageWoodV1')==row['building'] and
                abs(m['pbrMetallicRoughness'].get('roughnessFactor',0)-.90)<.001 for m in variants)
            material_findings[name]={'nativeArtMatches':bool(native_good),'webImageBytesMatch':bool(web_good)}
    nodes={node.get('name'):node for node in web['nodes'] if 'mesh' in node}
    mapping_good=True;primitives=0
    for row in wood.get('mapping',[]):
        ob=bpy.data.objects[row['object']]
        mapping_good &= fingerprint(ob,ignore_uv_layers={WOOD_UV})==row['sourceCoreFingerprint']
        node=nodes.get(ob.name)
        if not node:continue
        for primitive in web['meshes'][node['mesh']]['primitives']:
            material=web['materials'][primitive['material']]
            if material['name'] not in wood['materials']:continue
            coord=material['pbrMetallicRoughness']['baseColorTexture'].get('texCoord',0)
            mapping_good &= coord==row['uvIndex'] and 'TEXCOORD_'+str(coord) in primitive['attributes']
            primitives+=1
    wood_valid=(len(material_findings)==3 and mapping_good and primitives>0 and
                all(all(row.values()) for row in material_findings.values()))
    paving=contract.get('gyePlatformStone',{});paving_findings={}
    for row in paving.get('buildings',[]):
        stones=0;web_good=True
        for name in row['objects']:
            ob=bpy.data.objects[name];stones+=len(list(groups(ob.data)))
            node=nodes.get(name)
            if not node or not node.get('extras',{}).get('gyePlatformStoneV1'):
                web_good=False;continue
            for primitive in web['meshes'][node['mesh']]['primitives']:
                material=web['materials'][primitive['material']]
                pbr=material.get('pbrMetallicRoughness',{});coord=pbr.get('baseColorTexture',{}).get('texCoord',0)
                web_good &= ('baseColorTexture' in pbr and coord==0 and 'TEXCOORD_0' in primitive['attributes']
                             and abs(pbr.get('roughnessFactor',0)-.96)<.001)
        paving_findings[row['building']]={'stoneCountMatches':stones==row['stones'],
                                          'stones':stones,'webStoneSurfaceMatches':bool(web_good)}
    paving_valid=(len(paving_findings)==13 and all(row['stoneCountMatches'] and row['webStoneSurfaceMatches']
                    for row in paving_findings.values()) and paving.get('courtyardEarthChanged') is False)
    clearance=contract.get('gokganRearClearance',{});wall_findings={}
    outline=footprint(bpy.data.objects['North.gokgan.foundation.recessed earth mortar'])
    moved_good=bool(clearance.get('movedObjects')) and all(
        fingerprint(bpy.data.objects[row['object']])==row['afterFingerprint'] and
        nodes.get(row['object'],{}).get('extras',{}).get('gokganRearClearanceV1')
        for row in clearance.get('movedObjects',[]))
    for row in clearance.get('routes',[]):
        current=polygon_distance(outline,footprint(bpy.data.objects[row['core']]))
        wall_findings[row['core']]={'gapMeters':current,'registeredGapMatches':abs(current-row['clearanceMeters'])<.0001}
    long=wall_findings.get('North.site.gwang north.earth core',{}).get('gapMeters',0)
    clearance_valid=(moved_good and len(wall_findings)==6 and long>.95 and
                     all(row['registeredGapMatches'] and row['gapMeters']>.20 for row in wall_findings.values()))
    return {'heritageWood':{'valid':bool(wood_valid),'materials':material_findings,
                           'originalMembersChecked':len(wood.get('mapping',[])),'webPrimitivesChecked':primitives},
            'platformStone':{'valid':bool(paving_valid),'buildings':paving_findings,
                             'courtyardEarthUnchanged':paving.get('courtyardEarthChanged') is False},
            'gokganClearance':{'valid':bool(clearance_valid),'movedWallMeshes':len(clearance.get('movedObjects',[])),
                               'routes':wall_findings,'buildingMoved':clearance.get('buildingMoved')}}
