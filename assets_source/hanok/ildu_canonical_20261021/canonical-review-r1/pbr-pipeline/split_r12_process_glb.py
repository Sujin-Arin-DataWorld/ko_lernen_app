"""Lossless static GLB delta splitting. No Blender, simplification or app writes.

Accessor element bytes and embedded images are copied. Only index addressing,
buffer layout and source-part range metadata are rebuilt. No GPU texture sharing
is implied by identical embedded image hashes in separate GLBs.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import struct

import numpy as np

from validate_r12_glb import Glb, active_nodes, SOURCE_ID, COMPONENTS, require, validate
from build_r12_process_delivery import file_binding, read, safe_id, local_file, unapproved, equal_numbers, CHANNELS
from r12_export_selection import load_selection, unique
from r12_uv_coverage import audit_glb


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def pack(doc, payload):
    text=json.dumps(doc,separators=(',',':'),ensure_ascii=False,allow_nan=False).encode('utf8')
    text+=b' '*(-len(text)%4)
    binary=bytes(payload)+b'\0'*(-len(payload)%4)
    return (struct.pack('<4sII',b'glTF',2,28+len(text)+len(binary))+
            struct.pack('<II',len(text),0x4E4F534A)+text+
            struct.pack('<II',len(binary),0x004E4942)+binary)


def split_glb(blob, source_parts, selections):
    """Pure static-subset splitter. Selections must partition every source member.

    Empty selections emit no GLB. Source part IDs are retained even when sparse.
    Input proofs are validated by the file adapter; this function also validates
    layout, source IDs, complete triangle selections and bit-exact output copies.
    """
    source=Glb(blob);doc=source.doc
    require(not any(doc.get(k) for k in ('animations','skins','cameras')), 'Animated/skinned/camera GLBs are unsupported')
    require(set(doc.get('extensionsUsed',[])) <= {'KHR_materials_specular'}, 'Unsupported GLB extensions')
    require(set(doc.get('extensionsRequired',[])) <= {'KHR_materials_specular'}, 'Unsupported required GLB extensions')
    require(not doc.get('extensions'), 'Top-level extension references are unsupported')
    require(len(doc.get('scenes',[]))==1 and doc.get('scene',0)==0, 'Exactly one source scene is required')
    require(not source_parts.get('doors') and not source_parts.get('interactiveDoors'), 'Interactive hinge metadata needs a separate splitter')
    parts=source_parts['parts'];by_name={p['sourceObject']:p for p in parts};by_id={p['partId']:p for p in parts}
    require(len(parts)==len(by_name)==len(by_id), 'Duplicate source part identity')
    flattened=[n for names in selections.values() for n in names]
    require(len(flattened)==len(set(flattened)) and set(flattened)==set(by_name), 'Delta selections must exactly partition source members')
    worlds=active_nodes(doc);parent={}
    for ni in worlds:
        node=doc['nodes'][ni]
        require(not any(k in node for k in ('skin','weights','camera','extensions')), 'Unsupported node dependency')
        for child in node.get('children',[]): parent[child]=ni
    results={}
    for process,names in sorted(selections.items()):
        if not names: continue
        chosen={by_name[n]['partId'] for n in names}
        output=copy.deepcopy(doc)
        output.update(nodes=[],meshes=[],accessors=[],bufferViews=[],buffers=[{'byteLength':0}])
        payload=bytearray();primitive_proofs=[];node_mesh={};ranges={pid:[] for pid in chosen};nodes_by_part={pid:set() for pid in chosen}
        def add_view(data, target=None, metadata=None):
            payload.extend(b'\0'*(-len(payload)%4));index=len(output['bufferViews'])
            view=copy.deepcopy(metadata or {})
            for key in ('byteStride','byteOffset','byteLength','buffer','target'):view.pop(key,None)
            view.update(buffer=0,byteOffset=len(payload),byteLength=len(data))
            if target is not None:view['target']=target
            output['bufferViews'].append(view);payload.extend(data);return index
        def add_accessor(ai,values,target):
            original=doc['accessors'][ai]
            require(original['type'] in ('SCALAR','VEC2','VEC3','VEC4'), 'Matrix vertex attributes are unsupported')
            require(not original.get('extensions'), 'Accessor extensions are unsupported')
            view=source.views[original['bufferView']]
            require(not view.get('extensions'), 'Buffer view extensions are unsupported')
            data=values.tobytes(order='C')
            accessor=copy.deepcopy(original)
            accessor.pop('byteOffset',None)
            accessor.update(bufferView=add_view(data,target),count=len(values))
            for key,fn in [('min',np.min),('max',np.max)]:
                if key in original:accessor[key]=fn(values,axis=0).tolist()
            index=len(output['accessors']);output['accessors'].append(accessor);return index,data
        # Keep every encoded image and its metadata byte-for-byte except its new view reference.
        image_proofs=[]
        for image in output.get('images',[]):
            require('uri' not in image and 'bufferView' in image, 'External images are unsupported')
            old_view=image['bufferView'];data=bytes(source.view(old_view))
            require(not source.views[old_view].get('byteStride') and not source.views[old_view].get('extensions'), 'Unsupported image view')
            image['bufferView']=add_view(data,metadata=source.views[old_view])
            image_proofs.append({'sha256':sha(data),'bytes':len(data)})
        for ni in sorted(worlds):
            node=doc['nodes'][ni]
            if 'mesh' not in node:continue
            old_mesh=doc['meshes'][node['mesh']]
            require(not old_mesh.get('weights') and not old_mesh.get('extensions'), 'Morph/extended mesh is unsupported')
            new_mesh=copy.deepcopy(old_mesh);new_mesh['primitives']=[]
            for pi,primitive in enumerate(old_mesh['primitives']):
                require(primitive.get('mode',4)==4 and not primitive.get('targets') and not primitive.get('extensions'), 'Only static uncompressed triangles are supported')
                attrs=primitive['attributes'];require(SOURCE_ID in attrs, 'Source ID attribute missing')
                old_indices=source.array(primitive['indices'])[:,0]
                require(len(old_indices)%3==0,'Invalid triangle index count')
                triangles=old_indices.reshape(-1,3)
                ids=source.array(attrs[SOURCE_ID])[:,0]
                require(np.equal(ids,np.floor(ids)).all() and set(map(int,ids)) <= set(by_id),'Foreign/fractional source IDs')
                require(int(old_indices.max())<len(ids),'Source triangle index out of bounds')
                per_triangle=ids[triangles]
                require(np.equal(per_triangle,per_triangle[:,:1]).all(),'Mixed source parts in one triangle')
                keep=np.isin(per_triangle[:,0],list(chosen))
                if not keep.any():continue
                retained=np.flatnonzero(keep);old_triangles=triangles[keep]
                vertex_indices,inverse=np.unique(old_triangles.reshape(-1),return_inverse=True)
                new_primitive=copy.deepcopy(primitive);new_primitive['attributes']={}
                attr_proofs={}
                for semantic,ai in attrs.items():
                    values=source.array(ai)
                    require(len(values)==len(ids),'Attribute/source vertex count mismatch')
                    new_ai,data=add_accessor(ai,values[vertex_indices],34962)
                    new_primitive['attributes'][semantic]=new_ai
                    attr_proofs[semantic]={'sourceAccessor':ai,'outputAccessor':new_ai,'elementBytesSha256':sha(data)}
                index_accessor=primitive['indices'];index_spec=doc['accessors'][index_accessor]
                require(index_spec['type']=='SCALAR' and index_spec['componentType'] in (5121,5123,5125),'Invalid index component format')
                new_indices=inverse.astype(COMPONENTS[index_spec['componentType']]).reshape(-1,1)
                new_primitive['indices'],_=add_accessor(index_accessor,new_indices,34963)
                new_pi=len(new_mesh['primitives']);new_mesh['primitives'].append(new_primitive)
                part_ids=per_triangle[keep,0].astype(np.int64)
                start=0
                while start<len(part_ids):
                    pid=int(part_ids[start]);end=start+1
                    while end<len(part_ids) and part_ids[end]==pid:end+=1
                    ranges[pid].append(dict(node=ni,mesh=len(output['meshes']),primitive=new_pi,firstTriangle=start,endTriangle=end))
                    nodes_by_part[pid].add(ni);start=end
                primitive_proofs.append(dict(sourceNode=ni,sourceMesh=node['mesh'],sourcePrimitive=pi,
                    outputMesh=len(output['meshes']),outputPrimitive=new_pi,
                    sourceTriangleIndices=retained.tolist(),sourceVertexIndices=vertex_indices.tolist(),
                    attributes=attr_proofs,sourceVertexCount=len(ids),retainedVertexCount=len(vertex_indices),
                    allOutputVerticesReferenced=len(np.unique(new_indices))==len(vertex_indices)))
            if new_mesh['primitives']:
                node_mesh[ni]=len(output['meshes']);output['meshes'].append(new_mesh)
        keep_nodes=set(node_mesh)
        for ni in worlds:
            extra=doc['nodes'][ni].get('extras',{})
            if extra.get('p17EmptyEvaluatedMesh') and extra.get('p17SourcePartId') in chosen:
                pid=extra['p17SourcePartId'];keep_nodes.add(ni);nodes_by_part[pid].add(ni)
        require(output['meshes'],'Identity-only delta needs a separate zero-surface contract')
        for ni in list(keep_nodes):
            while ni in parent:ni=parent[ni];keep_nodes.add(ni)
        node_map={old:new for new,old in enumerate(sorted(keep_nodes))}
        for old in sorted(keep_nodes):
            node=copy.deepcopy(doc['nodes'][old]);node.pop('mesh',None)
            if old in node_mesh:node['mesh']=node_mesh[old]
            if 'children' in node:node['children']=[node_map[n] for n in node['children'] if n in keep_nodes]
            extras=node.get('extras',{})
            if 'p17SourcePartIds' in extras:extras['p17SourcePartIds']=[i for i in extras['p17SourcePartIds'] if i in chosen]
            if extras.get('p17SourcePartId') not in chosen:extras.pop('p17SourcePartId',None)
            output['nodes'].append(node)
        output['scenes'][0]['nodes']=[node_map[n] for n in doc['scenes'][0]['nodes'] if n in keep_nodes]
        output['buffers'][0]['byteLength']=len(payload)
        split_parts=copy.deepcopy(source_parts);split_parts.update(owner=process,parts=[])
        split_parts['unboundLeafParts']=[n for n in source_parts.get('unboundLeafParts',[]) if n in names]
        split_parts['parentAtlasChartGuard']=copy.deepcopy(source_parts.get('atlasChartGuard'))
        split_parts['splitProvenance']={'sourceGlbSha256':sha(blob),'method':'raw accessor element copy and vertex/index compaction',
                                      'authoredGeometryOrUvsChanged':False,'texturesRebaked':False}
        for part in parts:
            if part['partId'] not in chosen:continue
            new=copy.deepcopy(part);pid=part['partId']
            require(nodes_by_part[pid],'Selected source part lost all geometry/identity nodes')
            new['glbNodeIndices']=sorted(node_map[n] for n in nodes_by_part[pid])
            new['glbTriangleRanges']=[dict(r,node=node_map[r['node']]) for r in ranges[pid]]
            new['parentBakeRanges']={k:new.pop(k) for k in ('vertexStart','vertexEnd','loopStart','loopEnd','faceStart','faceEnd') if k in new}
            split_parts['parts'].append(new)
        result_blob=pack(output,payload);decoded=Glb(result_blob)
        # Independent byte comparisons after serialization, including every extra attribute.
        for proof in primitive_proofs:
            prim=decoded.doc['meshes'][proof['outputMesh']]['primitives'][proof['outputPrimitive']]
            vi=np.asarray(proof['sourceVertexIndices'],dtype=np.int64)
            for semantic,ap in proof['attributes'].items():
                require(decoded.array(prim['attributes'][semantic]).tobytes()==source.array(ap['sourceAccessor'])[vi].tobytes(), 'Attribute byte preservation failed')
        for i,image in enumerate(decoded.doc['images']):
            require(bytes(decoded.view(image['bufferView']))==bytes(source.view(doc['images'][i]['bufferView'])),'Image bytes changed')
            require({k:v for k,v in image.items() if k!='bufferView'}=={k:v for k,v in doc['images'][i].items() if k!='bufferView'},'Image metadata changed')
        for field in ('materials','textures','samplers','extensionsUsed','extensionsRequired'):
            require(decoded.doc.get(field)==doc.get(field),'Texture/material metadata changed')
        decoded_worlds=active_nodes(decoded.doc)
        require(all(np.array_equal(decoded_worlds[new],worlds[old]) for old,new in node_map.items()),'Node world transform changed')
        results[process]=dict(blob=result_blob,sidecar=split_parts,proof=dict(
            processId=process,sourceGlbSha256=sha(blob),outputGlbSha256=sha(result_blob),
            sourcePartIds=sorted(chosen),sourceObjects=sorted(names),primitiveCopies=primitive_proofs,
            sourceNodeToOutputNode=node_map,images=image_proofs,attributeElementBytesExact=True,
            imageBytesAndMetadataExact=True,nodeWorldTransformsExact=True,
            allOutputVerticesReferenced=all(p['allOutputVerticesReferenced'] for p in primitive_proofs),
            geometrySimplified=False,runtimePromoted=False,visualApproval=False,
            gpuTextureSharingClaimed=False))
    return results


def check_surface(proof, label):
    """Require the decoded frame gate separately from structural preservation."""
    require(proof.get('schemaVersion') == 2 and proof.get('surfaceGate') == 'passed'
            and proof.get('surfaceErrors') == [], label+' surface gate is missing, incomplete or failed')
    audit=proof.get('surfaceAudit',{})
    tolerances={'worldAreaEpsilon':1e-12,'unitLengthAbsolute':1e-3,
                'normalTangentDotAbsolute':1e-3,'handednessAbsolute':1e-4}
    require(audit.get('schemaVersion') == 1 and audit.get('tolerances') == tolerances,
            label+' surface audit schema or fixed tolerances differ')
    counts=audit.get('counts',{})
    fields=('trianglesEvaluated','positiveWorldAreaTriangles','degenerateWorldAreaTriangles',
            'invalidFrameVertices','zeroTangentVertices','invalidFrameTriangleIncidents',
            'failingPositiveWorldAreaTriangles','retainedDegenerateInvalidFrameTriangles')
    require(all(type(counts.get(k)) is int and counts[k] >= 0 for k in fields),
            label+' surface audit counts are incomplete or invalid')
    require(counts['trianglesEvaluated'] == proof.get('metrics',{}).get('triangles')
            == counts['positiveWorldAreaTriangles']+counts['degenerateWorldAreaTriangles']
            and counts['failingPositiveWorldAreaTriangles'] == 0
            and counts['invalidFrameTriangleIncidents'] == counts['retainedDegenerateInvalidFrameTriangles']
            <= counts['degenerateWorldAreaTriangles'], label+' surface audit contradicts its pass gate')


def check_coverage(proof, bindings, texture_size):
    """A decoded-pixel audit is required independently of the native atlas guard."""
    require(proof.get('visualApproval') is False, 'UV coverage must not claim visual approval')
    for field, key in [('glb','glb'), ('sourceParts','sidecar')]:
        require(proof.get(field) == bindings[key]['path'] and
                proof.get(field+'Sha256') == bindings[key]['sha256'], 'Stale UV coverage binding: '+field)
    require(proof.get('schemaVersion') == 2 and proof.get('textureSize') == texture_size,
            'UV proof schema or atlas dimensions differ')
    for field in ('worldAreaProvided','centerCoveragePass','minorSpanPass',
                  'sourceTriangleCountsExact','allInputTrianglesRetained'):
        require(proof.get(field) is True, 'Missing or failed UV proof: '+field)
    require(proof.get('zeroCenterFailureIslands') == 0 and proof.get('minorSpanFailureIslands') == 0,
            'UV proof reports unpaintable source islands')
    require(proof.get('minimumMinorSpanTexels') == 2.0, 'UV proof changed the two-texel threshold')


def check_source_contract(sidecar, bake_map, receipt, proof, coverage, bindings, selection):
    """Pure fail-closed prerequisite checks; the adapter binds bytes and policy."""
    for value,label in [(receipt,'Full-owner receipt'),(proof,'Full-owner proof')]:
        unapproved(value,label,explicit=True)
    require(receipt.get('variant') == 'estate' and receipt.get('publication') == 'private-candidate'
            and receipt.get('allEstateDelivered') is False, 'Only private partial estate sources are supported')
    require(receipt.get('nativeUnchanged') is True and receipt.get('nativeSaved') is False
            and receipt.get('geometrySimplified') is False, 'Native mutation or simplification is unsupported')
    for key,binding in [('ownerMapSha256','bakeOwnerMap'),('sourceOwnerMapSha256','sourceOwnerMap'),
                        ('contractSha256','geometryContract')]:
        require(receipt.get(key) == bindings[binding]['sha256'], 'Full-owner receipt binding mismatch: '+key)
    require(bake_map.get('sourceOwnerMapSha256') == bindings['sourceOwnerMap']['sha256'], 'Source owner-map binding mismatch')
    require(bake_map.get('curriculumPolicySha256') is None and receipt.get('curriculumPolicySha256') is None,
            'Input must be a whole native owner bake, not an already staged export')
    native_sha=bake_map['sourceNative']['sha256']
    require(receipt.get('native') == bake_map['sourceNative']['path'], 'Source native path mismatch')
    require(receipt.get('candidateSha256') == receipt.get('sourceSha256') ==
            sidecar.get('candidateSha256') == sidecar.get('sourceSha256') == native_sha, 'Source native hash mismatch')
    groups=unique(bake_map['groups'],'nativeOwner','source bake group')
    owners=unique(receipt['owners'],'owner','source export owner')
    require(set(groups) == set(owners) == {sidecar['owner']}, 'Exactly one complete native owner source is required')
    owner=owners[sidecar['owner']]
    unapproved(owner,'Owner receipt')
    names=[p['sourceObject'] for p in sidecar['parts']]
    expected=selection['sourceOwners']
    require(set(expected) == {sidecar['owner']} and set(names) == set(expected[sidecar['owner']])
            == set(groups[sidecar['owner']]['sourceObjects']) and len(names) == len(set(names)),
            'Source is not the exact whole native owner member set')
    require(not selection['excludedSharedContextSourceObjects'], 'Shared context cannot be split into earned stages')
    require(owner.get('sourceParts') == len(names), 'Full-owner source part count mismatch')
    require(owner.get('candidateSha256') == owner.get('sourceSha256') == native_sha, 'Owner native binding mismatch')
    for key,hash_key,file_key in [('glb','sha256','file'),('sidecar','sourcePartsSha256','sourcePartsFile')]:
        require(owner.get(hash_key) == bindings[key]['sha256'] and owner.get(file_key) == Path(bindings[key]['path']).name,
                'Stale source owner '+key+' receipt')
    require(owner.get('bytes') == receipt.get('totalBytes') == bindings['glb']['bytes'], 'Source receipt byte count mismatch')
    require(proof.get('validator') == 'R12 GLB structural preservation' and proof.get('passed') is True
            and proof.get('errors') == [] and proof.get('worldBoundsGate') == 'passed'
            and proof.get('budgetGate') in ('passed','not_configured'), 'Source structural proof is incomplete or failed')
    check_surface(proof,'Source')
    inputs=proof['inputs']
    for field,key in [('glb','glb'),('parts','sidecar')]:
        require(inputs.get(field) == bindings[key]['path'] and inputs.get(field+'Sha256') == bindings[key]['sha256'],
                'Stale source structural proof: '+field)
    for field,key in [('ownerMapSha256','bakeOwnerMap'),('receiptSha256','exportReceipt')]:
        require(inputs.get(field) == bindings[key]['sha256'], 'Source structural proof receipt/map mismatch')
    guard=sidecar.get('atlasChartGuard',{})
    require(guard.get('temporaryAtlasOnly') is True and guard.get('originalGeometryChanged') is False
            and guard.get('mipAndPixelCoverageApproved') is False, 'Missing or invalid source atlas guard')
    channels=unique(sidecar['channels'],'channel','source channel')
    exported=unique(owner['channels'],'channel','receipt channel')
    require(set(channels) == set(exported) == set(bindings['channels']) == set(CHANNELS), 'Missing or foreign PBR channels')
    images={i['image']:i for i in proof['images']}
    require(len(images) == len(proof['images']) and all(type(i) is int and i >= 0 for i in images),
            'Duplicate or invalid proof image index')
    sampled={}
    for item in proof['materialChannels']:
        key=(item['material'],item['channel'])
        require(key not in sampled and item['channel'] in CHANNELS, 'Invalid or duplicate material sampling proof')
        sampled[key]=item
        channel=channels[item['channel']];actual=bindings['channels'][item['channel']];image=images[item['image']]
        require(channel == exported[item['channel']], 'Sidecar/receipt channel metadata differs')
        require(channel['sha256'] == actual['sha256'] == image['sha256'] and
                channel['bytes'] == actual['bytes'] == image['bytes'] and
                channel['size'] == [image['width'],image['height']] and
                channel['file'] == Path(actual['path']).name, 'Material image hash/metadata mismatch')
        require(item['sampledChannels'] == CHANNELS[item['channel']], 'Material sampling convention changed')
        if item['channel'] == 'specular':
            require(image.get('hasAlpha') is True and image.get('packedSourceAlphaParity') == 'passed'
                    and image.get('specularFactor') == 1, 'Specular source alpha proof missing')
    require(sampled and all({c for m,c in sampled if m == material} == set(CHANNELS)
                            for material in {m for m,c in sampled}), 'Incomplete material sampling proof')
    sizes={tuple(c['size']) for c in channels.values()}
    require(len(sizes) == 1, 'Source atlas channel dimensions differ')
    check_coverage(coverage,bindings,list(next(iter(sizes))))


def load_policy_selection(policy_path, native_owner, names):
    """Re-use the strict policy binder; reject partial logical-building deltas."""
    policy_path=Path(policy_path).resolve(strict=True);policy=read(policy_path)
    owner_path=Path(policy['inputBindings']['r12-owner-map.json']['path'])
    mapping=read(owner_path)
    contracts=[Path(b['path']) for b in mapping['sourceBindings'] if Path(b['path']).name == 'full-scene-contract.json']
    require(len(contracts) == 1, 'Expected one exact source geometry contract')
    mapping,contract,selection=load_selection(owner_path,contracts[0],[native_owner],policy_path=policy_path)
    members=unique(policy['members'],'sourceObject','policy member')
    require(set(names) <= set(members), 'Unknown source members')
    buildings={members[n]['catalogBuildingId'] for n in names}
    require(len(buildings) == 1 and None not in buildings, 'One verified logical building per split is required')
    stages=[s for s in policy['stages'] if s['buildingId'] in buildings]
    delta={s['processId']:s['delta']['sourceObjects'] for s in stages}
    flat=[n for v in delta.values() for n in v]
    require(len(flat) == len(set(flat)) and set(flat) == set(names),
            'Whole logical-building policy delta union differs; separate/multi-instance contracts are unsupported')
    require({k:sorted(v) for k,v in delta.items() if v} == selection['unchunkedGroups'], 'Policy delta selection mismatch')
    return mapping,selection,stages,dict(policy=file_binding(policy_path),sourceOwnerMap=file_binding(owner_path),
            geometryContract=file_binding(contracts[0]),catalog=file_binding(policy['originalCatalog']['path']))


def write_json(path, value):
    with Path(path).open('x',encoding='utf-8',newline='\n') as stream:
        json.dump(value,stream,ensure_ascii=False,indent=2,allow_nan=False)
        stream.write('\n')


def split_from_files(glb_path, parts_path, owner_map_path, receipt_path, proof_path, coverage_path,
                     policy_path, out_dir):
    """Write new private files only after full source receipt/proof/policy binding.

    A failed output check leaves diagnostic artifacts and never a passing summary.
    Full parent textures remain embedded; their decoded memory may be duplicated
    by the renderer until a separately implemented GPU-sharing strategy is tested.
    """
    paths={k:Path(v).resolve(strict=True) for k,v in dict(glb=glb_path,sidecar=parts_path,
        bakeOwnerMap=owner_map_path,exportReceipt=receipt_path,validationProof=proof_path,
        uvCoverage=coverage_path).items()}
    folder=Path(out_dir).resolve()
    require(not folder.exists(), 'Output directory already exists; original and prior candidates are never overwritten')
    require('assets' not in {p.lower() for p in folder.parts} and folder not in [p.parent for p in paths.values()],
            'Output must be a new private artifact directory, outside app assets/source folders')
    sidecar,bake_map,receipt,proof,coverage=(read(paths[k]) for k in
        ('sidecar','bakeOwnerMap','exportReceipt','validationProof','uvCoverage'))
    names=[p['sourceObject'] for p in sidecar['parts']]
    mapping,selection,stages,policy_bindings=load_policy_selection(policy_path,sidecar['owner'],names)
    require(bake_map.get('sourceNative') == mapping['sourceNative'], 'Bake map and canonical source native differ')
    bindings={k:file_binding(p) for k,p in paths.items()} | policy_bindings
    bindings['channels']={c['channel']:file_binding(local_file(paths['sidecar'].parent,c['file'])) for c in sidecar['channels']}
    contract=read(bindings['geometryContract']['path'])
    for part in sidecar['parts']:
        equal_numbers(part['sourceWorld'],contract['objects'][part['sourceObject']]['matrixWorld'],1e-5,
                      'Sidecar/native-contract world transform')
    check_source_contract(sidecar,bake_map,receipt,proof,coverage,bindings,selection)
    # Repeat numeric source validation against current bytes, not only saved claims.
    fresh=validate(paths['glb'],paths['sidecar'],owner_map_path=paths['bakeOwnerMap'],receipt_path=paths['exportReceipt'])
    check_source_contract(sidecar,bake_map,receipt,fresh,coverage,bindings,selection)
    selections={s['processId']:s['delta']['sourceObjects'] for s in stages}
    for key in selections:safe_id(key)
    results=split_glb(paths['glb'].read_bytes(),sidecar,selections)
    # Check source inputs still bind before any output is written.
    for key,path in paths.items():require(file_binding(path) == bindings[key], 'Source changed during split: '+key)
    for key,binding in policy_bindings.items():
        require(file_binding(binding['path']) == binding, 'Policy/contract input changed during split: '+key)
    folder.mkdir(parents=True,exist_ok=False)
    proof_dir=folder/'proofs';proof_dir.mkdir()
    new_map=dict(sourceNative=mapping['sourceNative'],sourceOwnerMapSha256=bindings['sourceOwnerMap']['sha256'],
                 curriculumPolicySha256=bindings['policy']['sha256'],
                 groups=[dict(nativeOwner=key,sourceObjects=selections[key]) for key in sorted(results)])
    map_path=folder/'bake-owner-map.json';write_json(map_path,new_map)
    for actual in bindings['channels'].values():
        data=Path(actual['path']).read_bytes()
        require(sha(data) == actual['sha256'] and len(data) == actual['bytes'], 'Source channel changed during split')
        with (folder/Path(actual['path']).name).open('xb') as stream:stream.write(data)
    exported=[]
    for key,result in results.items():
        glb_out=folder/(key+'.glb');parts_out=folder/(key+'-source-parts.json')
        result['sidecar']['atlasChartGuardScope']='unchanged parent atlas; subset coverage independently audited in proofs'
        result['sidecar']['splitProvenance']['inputBindings']=bindings
        with glb_out.open('xb') as stream:stream.write(result['blob'])
        write_json(parts_out,result['sidecar'])
        write_json(proof_dir/(key+'-byte-copy.json'),result['proof'] | {'inputBindings':bindings})
        decoded=Glb(result['blob'])
        exported.append(dict(owner=key,file=glb_out.name,bytes=len(result['blob']),sha256=sha(result['blob']),
            sourceParts=len(result['sidecar']['parts']),sourcePartsFile=parts_out.name,sourcePartsSha256=file_binding(parts_out)['sha256'],
            sourceSha256=sidecar['sourceSha256'],candidateSha256=sidecar['candidateSha256'],
            channels=sidecar['channels'],meshes=len(decoded.doc['meshes']),nodes=len(decoded.doc['nodes']),
            materials=len(decoded.doc['materials']),images=len(decoded.doc['images']),
            runtimePromoted=False,visualApproval=False))
    new_receipt=dict(schemaVersion=1,sourceVersion='R12',variant='estate',scope='lossless whole-owner split into process deltas',
        native=bake_map['sourceNative']['path'],sourceSha256=sidecar['sourceSha256'],candidateSha256=sidecar['candidateSha256'],
        nativeUnchanged=True,nativeSaved=False,geometrySimplified=False,publication='private-candidate',
        allEstateDelivered=False,runtimePromoted=False,visualApproval=False,owners=exported,
        ownerMapSha256=file_binding(map_path)['sha256'],sourceOwnerMapSha256=bindings['sourceOwnerMap']['sha256'],
        curriculumPolicySha256=bindings['policy']['sha256'],contractSha256=bindings['geometryContract']['sha256'],
        totalBytes=sum(o['bytes'] for o in exported),inputBindings=bindings,splitter=file_binding(__file__),
        gpuTextureSharingClaimed=False,authoredGeometryOrUvsChanged=False,texturesRebaked=False)
    receipt_out=folder/'r12-export-receipt.json';write_json(receipt_out,new_receipt)
    audits=[]
    size=sidecar['channels'][0]['size']
    for owner in exported:
        key=owner['owner'];glb_out=folder/owner['file'];parts_out=folder/owner['sourcePartsFile']
        structural=validate(glb_out,parts_out,owner_map_path=map_path,receipt_path=receipt_out)
        write_json(proof_dir/(key+'-validation.json'),structural)
        require(structural['passed'] and structural['worldBoundsGate'] == 'passed', 'Split structural validation failed: '+key)
        check_surface(structural,'Split '+key)
        uv=audit_glb(glb_out,parts_out,size)
        write_json(proof_dir/(key+'-uv-coverage.json'),uv)
        check_coverage(uv,{'glb':file_binding(glb_out),'sidecar':file_binding(parts_out)},size)
        audits.append(dict(processId=key,memberCount=owner['sourceParts'],geometryBytes=structural['metrics']['geometryBytes'],
            triangles=structural['metrics']['triangles'],vertices=structural['metrics']['vertices'],
            surfaceGate=structural['surfaceGate'],surfaceErrors=structural['surfaceErrors'],
            structuralProof=file_binding(proof_dir/(key+'-validation.json')),
            uvCoverageProof=file_binding(proof_dir/(key+'-uv-coverage.json')),
            byteCopyProof=file_binding(proof_dir/(key+'-byte-copy.json'))))
    summary=dict(schemaVersion=1,status='private_delta_split_numeric_checks_passed_unapproved',
        inputBindings=bindings,outputReceipt=file_binding(receipt_out),stages=audits,
        sourceSurfaceGate=fresh['surfaceGate'],allOutputSurfaceGatesPassed=True,
        noNewGeometryStages=[dict(processId=s['processId'],noNewGeometry=True,asset=None,createsCredit=False,
            autoCompleteOnNoNewGeometry=False,cumulativePriorSourceObjects=s['cumulativePrior']['sourceObjects'])
            for s in stages if s['noNewGeometry']],
        sourceMembers=len(names),deltaMembers=sum(a['memberCount'] for a in audits),
        attributeElementBytesExact=True,imageBytesAndMetadataExact=True,nodeWorldTransformsExact=True,
        compactedGeometryBytes=sum(a['geometryBytes'] for a in audits),sourceGeometryBytes=fresh['metrics']['geometryBytes'],
        textureHashesIdenticalAcrossOutputs=True,embeddedTextureBytesPerGlb=fresh['metrics']['textureBytes'],
        repeatedEmbeddedTextureBytes=fresh['metrics']['textureBytes']*len(results),
        estimatedRgba8BytesWithoutGpuSharing=fresh['metrics']['textureRgba8DecodedBytes']*len(results),
        gpuTextureSharingClaimed=False,performanceApproved=False,visualApproval=False,deviceApproved=False,
        runtimePromoted=False,allEstateDelivered=False,standaloneReuseSupported=False,
        limitations=['Whole-parent atlases are duplicated in each GLB; GPU sharing is not implemented or measured.',
                     'Numeric pixel coverage does not establish mip quality, visual, device or performance approval.',
                     'No-new-geometry final stages produce no asset and grant no automatic credit.',
                     'Other buildings, shared context and standalone variants are not delivered by this split.'])
    write_json(folder/'split-summary.json',summary)
    return summary


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for flag in ('glb','parts','owner-map','export-receipt','validation-proof','uv-coverage','curriculum-policy','out'):
        parser.add_argument('--'+flag,required=True,type=Path)
    args=parser.parse_args()
    result=split_from_files(args.glb,args.parts,args.owner_map,args.export_receipt,args.validation_proof,
                            args.uv_coverage,args.curriculum_policy,args.out)
    print(json.dumps(dict(output=str(args.out),stages=len(result['stages']),members=result['deltaMembers'],runtimePromoted=False)))


if __name__=='__main__':main()
