"""Assemble hash-bound estate DELTA candidates without Blender or app writes.

Structural validation is not art, device, performance, or release approval.
Connected roof cuts are never aliased to a standalone asset by this assembler.
"""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path
from urllib.parse import quote, urlsplit

from r12_export_selection import load_selection, require, unique
from validate_r12_glb import validate

CHANNELS = {'baseColor': 'RGBA', 'normal': 'RGB',
            'roughnessMetallic': 'G=roughness,B=metallic', 'specular': 'A'}


def file_binding(path):
    path = Path(path).resolve(strict=True)
    with path.open('rb') as stream:
        checksum = hashlib.file_digest(stream, 'sha256').hexdigest()
    return dict(path=str(path), sha256=checksum, bytes=path.stat().st_size)


def read(path):
    return json.loads(Path(path).read_bytes())


def read_bound(path):
    """Parse and hash the same file snapshot; current bytes are rechecked later."""
    path=Path(path).resolve(strict=True)
    blob=path.read_bytes()
    return json.loads(blob),dict(path=str(path),sha256=hashlib.sha256(blob).hexdigest(),bytes=len(blob))


def require_surface_gate(proof,label):
    """Same fixed decoded-frame contract required by the lossless splitter."""
    require(proof.get('schemaVersion')==2 and proof.get('surfaceGate')=='passed'
            and proof.get('surfaceErrors')==[],label+' surface gate is missing, incomplete or failed')
    audit=proof.get('surfaceAudit',{})
    tolerances={'worldAreaEpsilon':1e-12,'unitLengthAbsolute':1e-3,
                'normalTangentDotAbsolute':1e-3,'handednessAbsolute':1e-4}
    require(audit.get('schemaVersion')==1 and audit.get('tolerances')==tolerances,
            label+' surface audit schema or fixed tolerances differ')
    counts=audit.get('counts',{})
    fields=('trianglesEvaluated','positiveWorldAreaTriangles','degenerateWorldAreaTriangles',
            'invalidFrameVertices','zeroTangentVertices','invalidFrameTriangleIncidents',
            'failingPositiveWorldAreaTriangles','retainedDegenerateInvalidFrameTriangles')
    require(all(type(counts.get(k)) is int and counts[k]>=0 for k in fields),
            label+' surface audit counts are incomplete or invalid')
    require(counts['trianglesEvaluated']==proof.get('metrics',{}).get('triangles')
            ==counts['positiveWorldAreaTriangles']+counts['degenerateWorldAreaTriangles']
            and counts['failingPositiveWorldAreaTriangles']==0
            and counts['invalidFrameTriangleIncidents']==counts['retainedDegenerateInvalidFrameTriangles']
            <=counts['degenerateWorldAreaTriangles'],label+' surface audit contradicts its pass gate')


def safe_id(value):
    require(isinstance(value, str) and re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]{0,95}', value)
            and '..' not in value, 'Unsafe candidate identity')
    return value


def local_file(folder, name):
    require(isinstance(name, str) and Path(name).name == name and '/' not in name and '\\' not in name,
            'Expected a delivery file basename')
    path = (folder/name).resolve(strict=True)
    require(path.parent == folder.resolve(), 'Delivery file escapes export directory')
    return path


def unapproved(value, label, explicit=False):
    require(not str(value.get('status', '')).lower().startswith('approved'), label+' claims approved status')
    for key in ('runtimePromoted', 'visualApproval', 'artApproved', 'deviceApproved'):
        require(value.get(key) in (None, False), label+' claims '+key)
    if explicit:
        require(value.get('runtimePromoted') is False and value.get('visualApproval') is False,
                label+' must explicitly preserve unapproved state')


def equal_numbers(actual, expected, tolerance, label):
    if isinstance(expected, list):
        require(isinstance(actual, list) and len(actual) == len(expected), label+' shape mismatch')
        for a, e in zip(actual, expected):
            equal_numbers(a, e, tolerance, label)
    else:
        require(type(actual) in (float, int) and math.isfinite(actual) and abs(actual-expected) <= tolerance,
                label+' differs')


def assemble_candidate(policy, catalog, bake_map, receipt, deliveries, bindings, contract,
                       *, version, url_base, variant='estate'):
    """Pure assembly. `actual` file bindings in deliveries come from the I/O adapter.

    A process may span multiple disjoint chunks; each process union must be its
    complete delta. One GLB must belong to one native instance. Partial estates
    are recorded explicitly and never gain completion/approval from this check.
    """
    safe_id(version)
    require(variant == 'estate', 'Standalone reuse requires a separate final-asset verifier; unsupported here')
    uri = urlsplit(url_base)
    require(url_base.endswith('/') and not uri.query and not uri.fragment and not uri.username
            and ((uri.scheme in {'http','https'} and uri.netloc)
                 or (uri.scheme == 'asset' and not uri.netloc and uri.path.startswith('/assets/hanok_3d/'))),
            'Invalid candidate URL base')
    require(all(p not in ('.','..') for p in uri.path.split('/')), 'Candidate URL traversal')
    unapproved(policy, 'Policy')
    unapproved(receipt, 'Export receipt', explicit=True)
    for key in ('nativeSaved','geometrySimplified'):
        require(receipt.get(key) is False, 'Export receipt claims native mutation: '+key)
    require(receipt.get('nativeUnchanged') is True and receipt.get('variant') == 'estate',
            'Export receipt must preserve estate native source')
    require(receipt.get('publication') == 'private-candidate', 'Expected private candidate export')
    require(receipt.get('allEstateDelivered') is False, 'Receipt must not claim complete estate delivery')
    for key, binding_key in [('ownerMapSha256','bakeOwnerMap'), ('sourceOwnerMapSha256','sourceOwnerMap'),
                             ('curriculumPolicySha256','policy'), ('contractSha256','geometryContract')]:
        require(receipt.get(key) == bindings[binding_key]['sha256'], 'Receipt binding mismatch: '+key)
    require(bake_map.get('sourceOwnerMapSha256') == bindings['sourceOwnerMap']['sha256'], 'Bake map owner binding mismatch')
    require(bake_map.get('curriculumPolicySha256') == bindings['policy']['sha256'], 'Bake map policy binding mismatch')
    require(policy['originalCatalog'] == bindings['catalog'], 'Actual catalog binding mismatch')
    require(policy['inputBindings']['r12-owner-map.json'] == bindings['sourceOwnerMap'], 'Actual owner map binding mismatch')
    native_sha = bake_map['sourceNative']['sha256']
    require(receipt.get('candidateSha256') == receipt.get('sourceSha256') == native_sha, 'Receipt native binding mismatch')
    require(receipt.get('native') == bake_map['sourceNative']['path'], 'Receipt native path binding mismatch')
    processes = unique(catalog['processes'], 'id', 'catalog process')
    stages = unique(policy['stages'], 'processId', 'policy process')
    require(set(stages) == set(processes), 'Missing/foreign policy stages')
    members = unique(policy['members'], 'sourceObject', 'policy source object')
    groups = unique(bake_map['groups'], 'nativeOwner', 'bake group')
    exports = unique(receipt['owners'], 'owner', 'export receipt group')
    delivered = unique(deliveries, 'owner', 'delivered group')
    require(set(groups) == set(exports) == set(delivered) and bool(groups), 'Missing or extra GLB/receipt/proof group')
    all_names = [n for group in groups.values() for n in group['sourceObjects']]
    require(len(all_names) == len(set(all_names)), 'Duplicate grant mapping: source member exported twice')
    require(receipt.get('totalBytes') == sum(d['actual']['glb']['bytes'] for d in deliveries), 'Receipt total byte count mismatch')
    assets, proofs, stage_sources, seen_sources, seen_hashes, seen_urls = [], [], {}, set(), set(), set()
    for key in sorted(groups):
        group, export, delivery = groups[key], exports[key], delivered[key]
        safe_id(key)
        names = group['sourceObjects']
        require(names and len(names) == len(set(names)) and set(names) <= set(members), 'Invalid bake group member set')
        require(not seen_sources.intersection(names), 'Duplicate grant mapping: source member exported twice')
        seen_sources.update(names)
        pids = {members[n]['displayProcessId'] for n in names}
        instances = {members[n]['nativeOwner'] for n in names}
        require(len(pids) == 1 and None not in pids, 'Group leaks another stage or shared context')
        require(len(instances) == 1, 'One GLB spans native instances; separate instance exports are required')
        pid, instance = next(iter(pids)), next(iter(instances))
        require(pid in stages, 'Unknown process')
        require(key == pid or re.fullmatch(re.escape(pid)+r'__atlas[0-9]{3}', key), 'Bake group ID disagrees with actual delta process')
        stage = stages[pid]
        require(all(members[n]['catalogBuildingId'] == stage['buildingId'] for n in names), 'Group belongs to a foreign logical building')
        require(stage['noNewGeometry'] is False, 'No-new-geometry stage cannot own an asset')
        stage_sources.setdefault(pid, set()).update(names)
        actual, sidecar, proof = delivery['actual'], delivery['sidecar'], delivery['proof']
        unapproved(export, 'Owner receipt')
        unapproved(proof, 'GLB proof', explicit=True)
        require(proof.get('passed') is True and proof.get('errors') == [], 'Invalid GLB validation proof')
        require(proof.get('validator') == 'R12 GLB structural preservation', 'Unsupported GLB proof kind')
        require(proof.get('budgetGate') in ('passed','not_configured'), 'Invalid or failed performance budget proof')
        require(proof.get('worldBoundsGate') == 'passed', 'Geometry proof lacks complete source bounds')
        require_surface_gate(proof,'GLB proof '+key)
        for part, receipt_sha in [('glb','sha256'),('sidecar','sourcePartsSha256')]:
            require(export.get(receipt_sha) == actual[part]['sha256'], 'Stale exported '+part+' hash')
        require(export.get('bytes') == actual['glb']['bytes'], 'GLB byte length mismatch')
        require(Path(actual['glb']['path']).name == export['file'] and
                Path(actual['sidecar']['path']).name == export['sourcePartsFile'], 'Receipt filenames differ from actual inputs')
        inputs = proof['inputs']
        for field, actual_key in [('glb','glb'),('parts','sidecar')]:
            require(inputs.get(field) == actual[actual_key]['path'], 'GLB proof actual path mismatch: '+field)
            require(inputs.get(field+'Sha256') == actual[actual_key]['sha256'], 'Stale GLB proof hash: '+field)
        require(inputs.get('ownerMapSha256') == bindings['bakeOwnerMap']['sha256'] and
                inputs.get('receiptSha256') == bindings['exportReceipt']['sha256'], 'GLB proof owner/receipt binding mismatch')
        require(sidecar.get('owner') == key and sidecar.get('candidateSha256') == sidecar.get('sourceSha256') == native_sha and
                export.get('candidateSha256') == export.get('sourceSha256') == native_sha, 'Sidecar/owner native binding mismatch')
        guard = sidecar.get('atlasChartGuard')
        require(isinstance(guard,dict), 'Missing atlas chart guard; old numeric GLB proof is insufficient')
        require(guard.get('temporaryAtlasOnly') is True and guard.get('originalGeometryChanged') is False
                and guard.get('mipAndPixelCoverageApproved') is False, 'Atlas guard changes source or claims pixel approval')
        chart_count, zero_charts = guard.get('chartCount'), guard.get('retainedZeroWorldAreaCharts')
        require(type(chart_count) is int and chart_count > 0 and isinstance(zero_charts,list)
                and all(type(i) is int and 0 <= i < chart_count for i in zero_charts)
                and len(zero_charts) == len(set(zero_charts)), 'Invalid atlas chart inventory')
        minimum, actual_min = guard.get('minimumMinorTexels'), guard.get('actualMinimumPrincipalSpanTexels')
        require(type(minimum) in (int,float) and math.isfinite(minimum) and minimum > 0
                and type(actual_min) in (int,float) and math.isfinite(actual_min)
                and (len(zero_charts) == chart_count or actual_min+1e-4 >= minimum), 'Atlas chart sampling guard failed')
        parts = unique(sidecar['parts'], 'sourceObject', 'sidecar source object')
        proof_parts = unique(proof['sourceParts'], 'sourceObject', 'proof source object')
        require(set(parts) == set(proof_parts) == set(names), 'Geometry proof/source member union mismatch')
        require(export.get('sourceParts') == len(parts), 'Receipt source part count mismatch')
        require(len({p['partId'] for p in parts.values()}) == len(parts), 'Duplicate sidecar part ID')
        for name, part in parts.items():
            verified = proof_parts[name]
            expected_triangles = part['evaluatedLoopCount'] - 2*part['evaluatedFaceCount']
            require(verified['partId'] == part['partId'] and verified['empty'] is part['evaluatedEmpty'], 'Geometry proof identity mismatch')
            require(verified['expectedTriangles'] == verified['actualTriangles'] == expected_triangles,
                    'Geometry proof triangle mismatch')
            equal_numbers(part['sourceWorld'], contract['objects'][name]['matrixWorld'], 1e-5, 'Source world transform')
            if not part['evaluatedEmpty']:
                require(0 <= verified.get('worldBoundsMaxAbsoluteError', math.inf) <= 1e-4, 'Geometry proof bounds error')
                bounds = part['evaluatedWorldBounds']
                equal_numbers(verified['decodedWorldBoundsBlender'], [bounds['min'],bounds['max']], 1e-4, 'Decoded geometry bounds')
        channels = unique(sidecar['channels'], 'channel', 'sidecar channel')
        receipt_channels = unique(export['channels'], 'channel', 'receipt channel')
        require(set(channels) == set(receipt_channels) == set(actual['channels']) == set(CHANNELS), 'Missing or extra PBR channel')
        images = {i['image']: i for i in proof['images']}
        require(len(images) == len(proof['images']), 'Duplicate material proof image ID')
        material_keys = set()
        by_material = {}
        for channel_proof in proof['materialChannels']:
            channel, material = channel_proof['channel'], channel_proof['material']
            require(channel in CHANNELS and (material,channel) not in material_keys, 'Duplicate/foreign material channel proof')
            material_keys.add((material,channel))
            by_material.setdefault(material,set()).add(channel)
            image = images[channel_proof['image']]
            source, exported, actual_channel = channels[channel], receipt_channels[channel], actual['channels'][channel]
            require(source['sha256'] == exported['sha256'] == actual_channel['sha256'] == image['sha256'], 'Material proof/channel hash mismatch')
            require(source['bytes'] == exported['bytes'] == actual_channel['bytes'] == image['bytes'], 'Material proof/channel size mismatch')
            require(Path(actual_channel['path']).name == source['file'] == exported['file'], 'Material channel filename mismatch')
            require(source['size'] == exported['size'] == [image['width'],image['height']], 'Material proof dimensions mismatch')
            require(channel_proof['sampledChannels'] == CHANNELS[channel], 'Material sampling convention mismatch')
            if channel == 'specular':
                require(image.get('hasAlpha') is True and image.get('packedSourceAlphaParity') == 'passed'
                        and image.get('specularFactor') == 1, 'Specular alpha preservation proof missing')
        require(by_material and all(c == set(CHANNELS) for c in by_material.values()), 'Incomplete material proof')
        metrics = proof['metrics']
        require(metrics['glbBytes'] == actual['glb']['bytes'] and metrics['sourceParts'] == len(parts)
                and metrics['materials'] == len(by_material)
                and metrics['triangles'] == sum(p['actualTriangles'] for p in proof_parts.values()), 'Proof geometry/material metrics mismatch')
        checksum = actual['glb']['sha256']
        url = url_base+quote(export['file'])
        require(checksum not in seen_hashes and url not in seen_urls, 'Duplicate grant mapping: GLB bytes or URL reused')
        seen_hashes.add(checksum); seen_urls.add(url)
        asset_id = safe_id('r12.'+key+'.'+instance+'.estate')
        assets.append(dict(id=asset_id, version=version, processId=pid, buildingId=stage['buildingId'],
                           instanceId=instance, variant='estate', url=url, sha256=checksum, bytes=actual['glb']['bytes']))
        proofs.append(dict(assetId=asset_id, owner=key, sourceObjects=sorted(names),
                           inputBindings=actual, numericValidation=True, visualApproval=False,
                           surfaceGate=proof['surfaceGate'],surfaceAudit=proof['surfaceAudit'],
                           deviceApproved=False, budgetGate=proof['budgetGate'], atlasChartGuard=guard,
                           pixelCenterCoverageStatus='not_provided', warnings=proof.get('warnings',[])))
    stage_status = []
    for pid, stage in sorted(stages.items(), key=lambda item:(item[1]['buildingId'],item[1]['sequence'])):
        require(stage['curriculumContract'] == processes[pid], 'Stage altered original curriculum contract')
        require(stage['createsCredit'] is False and stage['autoCompleteOnNoNewGeometry'] is False and
                stage['earnedRuntimeStageAllowed'] is False, 'Stage claims approval or credit')
        delta = stage['delta']['sourceObjects']
        require(stage['noNewGeometry'] is (not delta), 'Stage no-new-geometry contradiction')
        selected = stage_sources.get(pid,set())
        if selected:
            require(selected == set(delta), 'Cumulative leak or incomplete delta union: '+pid)
        stage_status.append(dict(processId=pid, buildingId=stage['buildingId'], noNewGeometry=stage['noNewGeometry'],
            expectedDeltaMembers=len(delta), candidateDeltaMembers=len(selected),
            status='candidate_delta_verified' if selected else 'no_new_geometry' if not delta else 'incomplete',
            cumulativePriorProcessIds=[p['id'] for p in catalog['processes'] if
                                       p['buildingId']==stage['buildingId'] and p['sequence']<stage['sequence']],
            createsCredit=False, autoCompleteOnNoNewGeometry=False, earnedRuntimeStageAllowed=False))
    buildings = []
    for building in sorted({s['buildingId'] for s in stage_status}):
        relevant = [s for s in stage_status if s['buildingId']==building]
        missing = [s['processId'] for s in relevant if s['status']=='incomplete']
        buildings.append(dict(buildingId=building, candidateDeltaSetComplete=not missing,
                              missingDeltaProcessIds=missing, artApproved=False, deviceApproved=False,
                              standaloneStatus='unsupported_separate_final_asset_required', runtimePromoted=False))
    return dict(schemaVersion=1, catalogId='ildu-processes-v1', status='private_candidate_delta_unapproved',
                assets=assets, stages=stage_status, buildings=buildings, inputBindings=bindings,
                assetEvidence=proofs, assetSemantics='delta_only', sourceVersion='R12',
                runtimePromoted=False, visualApproval=False, deviceApproved=False, createsCredit=False,
                productionManifestWritten=False, urlsPublished=False, allEstateDelivered=False,
                candidateReadiness='blocked_art_device_pixel_coverage',
                limitations=['Numeric validation does not prove art, historical, atlas-density or device-performance approval.',
                             'No-new-geometry stages retain prior selectors and never fabricate an asset or auto-credit.',
                             'Shared context and standalone variants need separate verified delivery contracts.'])


def assemble_from_files(export_dir, proof_dir, policy_path, *, version, url_base):
    folder, proof_dir = Path(export_dir).resolve(strict=True), Path(proof_dir).resolve(strict=True)
    paths = dict(policy=Path(policy_path).resolve(strict=True), bakeOwnerMap=folder/'bake-owner-map.json',
                 exportReceipt=folder/'r12-export-receipt.json')
    snapshots={key:read_bound(path) for key,path in paths.items()}
    policy,bake_map,receipt=(snapshots[key][0] for key in ('policy','bakeOwnerMap','exportReceipt'))
    paths['sourceOwnerMap'] = Path(policy['inputBindings']['r12-owner-map.json']['path'])
    paths['catalog'] = Path(policy['originalCatalog']['path'])
    snapshots['sourceOwnerMap']=read_bound(paths['sourceOwnerMap'])
    owner_map = snapshots['sourceOwnerMap'][0]
    contracts = [Path(b['path']) for b in owner_map['sourceBindings'] if Path(b['path']).name=='full-scene-contract.json']
    require(len(contracts)==1, 'Expected exact geometry contract binding')
    paths['geometryContract'] = contracts[0]
    for key in ('catalog','geometryContract'):
        snapshots[key]=read_bound(paths[key])
    selected_names = {n for group in bake_map['groups'] for n in group['sourceObjects']}
    members = unique(policy['members'],'sourceObject','policy source object')
    require(selected_names <= set(members), 'Unknown baked member')
    native_owners = sorted({members[n]['nativeOwner'] for n in selected_names})
    _, contract, _ = load_selection(paths['sourceOwnerMap'], paths['geometryContract'], native_owners,
                                    policy_path=paths['policy'], exclude_shared_context=True)
    bindings = {key:snapshots[key][1] for key in paths}
    require(contract==snapshots['geometryContract'][0], 'Geometry contract changed during policy selection')
    proof_index = {}
    expected_glbs = {str(local_file(folder, export['file'])) for export in receipt['owners']}
    for path in sorted(proof_dir.glob('*.json')):
        candidate,candidate_binding = read_bound(path)
        if isinstance(candidate,dict) and candidate.get('validator') == 'R12 GLB structural preservation':
            glb = candidate.get('inputs',{}).get('glb')
            if glb not in expected_glbs:
                continue
            require(glb not in proof_index, 'Duplicate validation proofs for actual GLB path')
            proof_index[glb]=(candidate_binding,candidate)
    deliveries=[]
    for export in receipt['owners']:
        glb = local_file(folder, export['file'])
        sidecar_path = local_file(folder, export['sourcePartsFile'])
        sidecar,sidecar_binding = read_bound(sidecar_path)
        require(str(glb) in proof_index, 'Missing GLB validation proof: '+str(glb))
        proof_binding, proof = proof_index[str(glb)]
        actual = dict(glb=file_binding(glb), sidecar=sidecar_binding, proof=proof_binding,
                      channels={c['channel']:file_binding(local_file(folder,c['file'])) for c in sidecar['channels']})
        deliveries.append(dict(owner=export['owner'],actual=actual,sidecar=sidecar,proof=proof))
    # Saved claims must pass independently; fresh decoding cannot silently
    # replace an invalid or unmeasured saved source proof.
    catalog=snapshots['catalog'][0]
    assemble_candidate(policy,catalog,bake_map,receipt,deliveries,bindings,contract,
                       version=version,url_base=url_base)
    validator_binding=file_binding(Path(__file__).with_name('validate_r12_glb.py'))
    fresh_deliveries=[];fresh_evidence=[]
    for delivery in deliveries:
        actual=delivery['actual']
        fresh=validate(actual['glb']['path'],actual['sidecar']['path'],
                       owner_map_path=paths['bakeOwnerMap'],receipt_path=paths['exportReceipt'])
        require(fresh.get('passed') is True and fresh.get('errors')==[],
                'Fresh structural validation failed: '+delivery['owner'])
        require_surface_gate(fresh,'Fresh GLB '+delivery['owner'])
        fresh_deliveries.append(dict(delivery,proof=fresh))
        report_blob=json.dumps(fresh,sort_keys=True,separators=(',',':'),allow_nan=False).encode('utf-8')
        fresh_evidence.append(dict(owner=delivery['owner'],validatorBinding=validator_binding,
            reportCanonicalSha256=hashlib.sha256(report_blob).hexdigest(),report=fresh))
    result=assemble_candidate(policy,catalog,bake_map,receipt,fresh_deliveries,bindings,contract,
                              version=version,url_base=url_base)
    all_bindings=list(bindings.values())+[validator_binding]
    for delivery in deliveries:
        actual=delivery['actual']
        all_bindings.extend(actual[key] for key in ('glb','sidecar','proof'))
        all_bindings.extend(actual['channels'].values())
    for binding in all_bindings:
        require(file_binding(binding['path'])==binding,
                'Input changed during fresh candidate validation: '+binding['path'])
    result.update(currentFilesRevalidated=True,allSavedSurfaceGatesPassed=True,
                  allFreshSurfaceGatesPassed=True,freshValidationEvidence=fresh_evidence)
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for flag in ('export-dir','proof-dir','policy','version','url-base','out'):
        parser.add_argument('--'+flag,required=True)
    args=parser.parse_args()
    output=Path(args.out).resolve()
    require('assets' not in {part.lower() for part in output.parts} and output.name.lower() not in {'ildu_3d_delivery_v1.json','ildu_3d_candidate_v1.json'},
            'Write an audit candidate path; app assets/manifests are outside assembler scope')
    require(not output.exists(), 'Refusing to overwrite an existing candidate artifact')
    manifest=assemble_from_files(args.export_dir,args.proof_dir,args.policy,version=args.version,url_base=args.url_base)
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open('x',encoding='utf8') as stream:
        stream.write(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(dict(path=str(output),assets=len(manifest['assets']),runtimePromoted=False)))


if __name__=='__main__':
    main()
