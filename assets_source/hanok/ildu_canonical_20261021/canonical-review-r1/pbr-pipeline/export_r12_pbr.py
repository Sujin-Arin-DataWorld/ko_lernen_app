"""Export exact R12 member subsets; native file is read-only and never saved.

Start from Blender factory state. Owner names come from the hash-bound selection
contract, not a filename guess. This is candidate delivery, not art approval.
"""
import argparse
import hashlib
import importlib.util
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from r12_export_selection import load_selection, bake_owner_map, require
from r12_native_source import ORIGINAL_R12_SHA256, verified_r12_sha


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--native', required=True)
    parser.add_argument('--owners', required=True)
    parser.add_argument('--owner-map', required=True)
    parser.add_argument('--contract', required=True)
    parser.add_argument('--out', required=True)
    parser.add_argument('--atlas', type=int, default=2048)
    parser.add_argument('--samples', type=int, default=8)
    parser.add_argument('--bake-margin', type=int, default=8,
                        help='Atlas dilation pixels; candidate must pass mip and visible coverage QA')
    parser.add_argument('--chunk-raw-faces', type=int, default=0)
    parser.add_argument('--curriculum-policy')
    parser.add_argument('--catalog', help='Optional explicit path; must match the policy catalog binding')
    parser.add_argument('--exclude-shared-context', action='store_true',
                        help='Explicitly exclude unsupported shared context in curriculum mode')
    parser.add_argument('--validate-selection-only', action='store_true',
                        help='Write selection proof without importing Blender or exporting geometry')
    parser.add_argument('--capture-tangent-inputs', action='store_true',
                        help='Persist exact pre-bake/export arrays for read-only numerical diagnosis')
    parser.add_argument('--paired-normal-frame',action='store_true',
                        help='Experimental explicit frame with a fresh matched original-world-normal bake')
    parser.add_argument('--maximum-interior-frame-fallbacks',type=int,default=64)
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else sys.argv[1:])
    require(1 <= args.bake_margin <= 32, 'Bake margin must be 1..32 pixels')
    require(0 <= args.maximum_interior_frame_fallbacks <= 256,'Explicit interior fallback limit must be 0..256')
    native, out = Path(args.native).resolve(), Path(args.out).resolve()
    expected = verified_r12_sha(native)
    mapping, contract, selected = load_selection(
        args.owner_map, args.contract, args.owners.split(','),
        policy_path=args.curriculum_policy, catalog_path=args.catalog,
        chunk_raw_faces=args.chunk_raw_faces, exclude_shared_context=args.exclude_shared_context)
    require(mapping['sourceNative']['sha256'] == ORIGINAL_R12_SHA256, 'Owner map is not bound to canonical R12')
    require(sha(native) == expected, 'R12 SHA mismatch')
    runner_sha = sha(__file__)
    selection_helper_sha = sha(Path(__file__).with_name('r12_export_selection.py'))
    pipeline_names = ('export_r12_pbr.py', 'r12_pbr_delivery.py', 'r12_native_source.py',
        'r12_export_selection.py', 'r12_uv_pack.py', 'r12_uv_coverage.py',
        'cycles_object_random.py')
    if args.paired_normal_frame:
        pipeline_names+=('r12_stable_frame.py','r12_frame_nodes.py',
            'r12_frame_export.py','r12_paired_surface.py','r12_uv_patch.py')
    pipeline_hashes = {name: sha(Path(__file__).with_name(name)) for name in pipeline_names}
    selection = selected['atlasGroups']
    names = {n for group in selected['sourceOwners'].values() for n in group}
    policy_sha = selected['curriculumPolicySha256']
    out.mkdir(parents=True, exist_ok=True)
    configuration=dict(schemaVersion=1,native=str(native),nativeSha256=expected,
        owners=args.owners.split(','),atlasSize=args.atlas,bakeSamples=args.samples,
        bakeMarginPixels=args.bake_margin,initialProjectionMarginPixels=2*args.bake_margin+2,
        pairedNormalFrame=args.paired_normal_frame,
        maximumInteriorFrameFallbacks=args.maximum_interior_frame_fallbacks,
        captureTangentInputs=args.capture_tangent_inputs,pipelineSourceSha256=pipeline_hashes)
    (out/'export-configuration.json').write_text(json.dumps(configuration,ensure_ascii=False,indent=2),encoding='utf-8')
    (out/'exact-export-selection.json').write_text(json.dumps(selected,ensure_ascii=False,indent=2),encoding='utf-8')
    bake_map_bytes = json.dumps(bake_owner_map(mapping, selected),ensure_ascii=False,indent=2).encode('utf-8')
    (out/'bake-owner-map.json').write_bytes(bake_map_bytes)
    bake_map_sha = hashlib.sha256(bake_map_bytes).hexdigest()
    selection_proof = dict(passed=True, selectionOnly=True, selectedMembers=len(names),
        atlasGroups=len(selection), sharedContextExportSupported=selected['sharedContextExportSupported'],
        excludedSharedContextMembers=len(selected['excludedSharedContextSourceObjects']),
        globalSharedContextMembers=selected['globalSharedContextMemberCount'],
        allNoNewGeometryProcessIds=selected['allNoNewGeometryProcessIds'],
        sourceOwnerMapSha256=selected['sourceOwnerMapSha256'], ownerMapSha256=bake_map_sha,
        curriculumPolicySha256=policy_sha, runnerSha256=runner_sha, selectionHelperSha256=selection_helper_sha,
        nativeSha256=expected, nativeSaved=False, geometryExported=False, runtimePromoted=False,
        curriculumDisplayAssignmentsAreHistoricalProof=False)
    (out/'selection-validation.json').write_text(json.dumps(selection_proof,ensure_ascii=False,indent=2),encoding='utf-8')
    if args.validate_selection_only:
        print('R12_SELECTION_VALIDATED '+json.dumps(selection_proof),flush=True)
        return
    # All policy/path/catalog checks finish before any native import or load.
    import bpy
    from mathutils import Matrix
    started = time.time()
    with bpy.data.libraries.load(str(native), link=False) as (available, dest):
        assert names <= set(available.objects)
        dest.objects = sorted(names)
    # Flatten only detached working copies to contract world transforms. This
    # avoids evaluating unrelated parts of the high-detail estate during bake.
    scene = bpy.data.scenes.new('R12 exact member working copy')
    resolved = {}
    for loaded in dest.objects:
        record = contract['objects'][loaded.name]
        assert loaded.type == 'MESH'
        assert len(loaded.data.vertices) == record['domainCounts']['POINT']
        assert len(loaded.data.polygons) == record['domainCounts']['FACE']
        authored_name = loaded.name
        loaded.name = 'R12 donor | '+authored_name
        ob = loaded.copy()
        ob.data = loaded.data.copy()
        ob.name = authored_name
        ob.parent = None
        ob.animation_data_clear()
        for constraint in list(ob.constraints):
            ob.constraints.remove(constraint)
        ob.matrix_world = Matrix(record['matrixWorld'])
        ob.hide_render = False
        ob['r12SourceObject'] = authored_name
        scene.collection.objects.link(ob)
        resolved[authored_name] = ob
    bpy.context.window.scene = scene
    bpy.context.view_layer.update()
    print('R12 selected source loaded: '+str(len(resolved)), flush=True)
    helper_path = Path(__file__).with_name('r12_pbr_delivery.py')
    helper_sha = sha(helper_path)
    spec = importlib.util.spec_from_file_location('r12_pbr', helper_path)
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    out.mkdir(parents=True, exist_ok=True)
    # View-dependent shaders or random object factors require explicit handling;
    # refuse them instead of silently baking a different surface after joining.
    unsupported=[]
    for ob in resolved.values():
        for slot in ob.material_slots:
            mat=slot.material
            if not mat or not mat.use_nodes:
                continue
            for node,socket in helper._connected_outputs(mat):
                if (node.type == 'OBJECT_INFO' and socket.name != 'Random') or (node.type == 'NEW_GEOMETRY' and socket.name in ('Pointiness','Random Per Island')):
                    unsupported.append([ob.name,mat.name,node.type,socket.name])
    if unsupported:
        (out/'unsupported-surface-inputs.json').write_text(json.dumps(unsupported,ensure_ascii=False,indent=2),encoding='utf-8')
        raise RuntimeError('Unpreserved object/geometry surface inputs; inspect report')
    result = helper.export_review(bpy,out,expected,expected,owners_selection=selection,
                                  atlas_size=args.atlas,samples=args.samples,bake_margin=args.bake_margin,
                                  native_path=str(native),door_definitions=[],
                                  capture_tangent_inputs=args.capture_tangent_inputs,
                                  paired_normal_frame=args.paired_normal_frame,
                                  maximum_interior_fallbacks=args.maximum_interior_frame_fallbacks)
    require(all(sha(Path(__file__).with_name(name)) == digest
                for name, digest in pipeline_hashes.items()),
            'Export pipeline changed during bake; candidate has no reproducible completion receipt')
    result.update(schemaVersion=1, sourceVersion='R12', variant='estate',
                  nativeUnchanged=sha(native)==expected, nativeSaved=False,
                  geometrySimplified=False, publication='private-candidate', runtimePromoted=False,
                  ownerMapSha256=bake_map_sha, sourceOwnerMapSha256=selected['sourceOwnerMapSha256'],
                  contractSha256=selected['contractSha256'], selectionHelperSha256=selection_helper_sha,
                  helperSha256=helper_sha, runnerSha256=runner_sha, elapsedSeconds=time.time()-started,
                  note='Exact transformed evaluated members; production process assignment and visual parity are separate gates.')
    from cycles_object_random import object_random
    result['retainedObjectRandom'] = {name: object_random(name) for name in sorted(names)}
    result['pipelineSourceSha256'] = pipeline_hashes
    result['exportConfigurationSha256']=sha(out/'export-configuration.json')
    result['pairedNormalFrame']=args.paired_normal_frame
    if args.capture_tangent_inputs:
        result['tangentInputSnapshots'] = [dict(file=str(path.relative_to(out)),
            sha256=sha(path),bytes=path.stat().st_size)
            for path in sorted((out/'tangent-inputs').glob('*.npz'))]
    result['curriculumPolicySha256'] = policy_sha
    result['curriculumDisplayAssignmentsAreHistoricalProof'] = False
    result['allNoNewGeometryProcessIds'] = selected['allNoNewGeometryProcessIds']
    result['excludedSharedContextSourceObjects'] = selected['excludedSharedContextSourceObjects']
    (out/'r12-export-receipt.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('R12_EXPORT_COMPLETE '+json.dumps({k:result[k] for k in ('totalBytes','nativeUnchanged','elapsedSeconds')}),flush=True)


if __name__ == '__main__':
    main()
