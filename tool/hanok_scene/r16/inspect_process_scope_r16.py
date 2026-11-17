"""Read-only stage scope audit; writes only its review JSON beside this helper."""
import collections
import hashlib
import json
import struct
import subprocess
from pathlib import Path

P = Path(__file__).resolve().parent
CAN = P.parents[2]
R12 = P.parents[6]
REPO = Path('C:/dev/hangulsori/ko_lernen_app')
PROCESS = Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-hwalju-20260928/assets/data/ildu_processes_v1.json')


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def binding(path):
    with path.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    return dict(path=str(path), sha256=digest, bytes=path.stat().st_size)


catalog = read(CAN / 'catalog.json')
native_manifest = read(P.parents[3] / 'canonical-11-20261023/CANONICAL_MANIFEST.json')
keys = {r['key'] for r in native_manifest['buildings']}
processes = read(PROCESS)
process_by_id = {r['id']: r for r in processes['processes']}
policy_path = R12 / 'mapping/r12-curriculum-display-policy.json'
policy = read(policy_path)
policy_by_id = {r['processId']: r for r in policy['stages']}
art_path = REPO / 'assets/data/ildu_construction_art_v1.json'
sarang_path = REPO / 'assets/data/sarangchae_construction_v3.json'
download_path = REPO / 'assets/data/hanok_download_manifest.json'
world = read(REPO / 'assets/data/ildu_world_manifest_v1.json')
art = read(art_path)
sarang = read(sarang_path)
download = read(download_path)
runtime_by_asset = {}
for series in art['series']:
    for stage in series['stages']:
        runtime_by_asset[stage['asset']] = dict(seriesId=series['buildingId'], stageId=stage['stageId'], sequence=stage['sequence'])
for stage in sarang['stages']:
    runtime_by_asset[stage['assetPath']] = dict(seriesId=sarang['id'], stageId=stage['stageId'], sequence=stage['sequence'])
out = dict(schemaVersion=1, repo=str(REPO), repoHead=subprocess.check_output(['git', '-C', str(REPO), 'rev-parse', 'HEAD'], text=True).strip(),
           authority='Source curriculum process catalog and native canonical review catalog; current app artwork catalogs are recorded separately.',
           sourceBindings=[binding(f) for f in [PROCESS, CAN / 'catalog.json', policy_path, art_path, sarang_path, download_path]],
           currentMainHasFullProcessCatalog=(REPO / 'assets/data/ildu_processes_v1.json').exists(),
           logicalCatalogProcessCount=len(processes['processes']), buildings=[], additionalNativeGroups=[],
           appLoaders=[str(REPO / 'lib/models/sarangchae_construction.dart'), str(REPO / 'lib/models/ildu_construction_art.dart'), str(REPO / 'lib/data/ildu_turntable_catalog.dart')])
for building in catalog['buildings']:
    key = building['key']
    glb_path = CAN / 'models' / (key + '.glb')
    if not glb_path.exists():
        if key not in keys:
            out['additionalNativeGroups'].append(dict(key=key, buildingId=building.get('buildingId'), stageCount=len(building['steps']), note='No building GLB at expected path; preserve context separately.'))
            continue
        raise FileNotFoundError(glb_path)
    with glb_path.open('rb') as stream:
        stream.read(12)
        size, kind = struct.unpack('<II', stream.read(8))
        gltf = json.loads(stream.read(size))
    members = [r['extras'] for r in gltf.get('nodes', []) if 'reviewStage' in r.get('extras', {})]
    null_members = [r for r in members if r.get('processId') is None]
    steps = []
    for stage in building['steps']:
        pid = stage['id']
        proc = process_by_id.get(pid)
        pol = policy_by_id.get(pid)
        seq = stage['sequence']
        steps.append(dict(processId=pid, sequence=seq, label=stage['label'], isFinal=stage['isFinal'],
                          catalogContractMatches=proc is not None and proc['sequence'] == seq and proc['buildingId'] == building['buildingId'],
                          seriesId=proc.get('seriesId') if proc else None,
                          processTags=proc.get('processTags') if proc else None,
                          requiredCourseUnitIds=proc.get('requiredCourseUnitIds') if proc else None,
                          legacyArtAsset=proc.get('legacyArtAsset') if proc else None,
                          currentRuntimeArt=runtime_by_asset.get(proc.get('legacyArtAsset')) if proc else None,
                          newGLBMembers=sum(r['reviewStage'] == seq for r in members),
                          cumulativeGLBMembers=sum(r['reviewStage'] <= seq for r in members),
                          noNewGLBGeometry=not any(r['reviewStage'] == seq for r in members),
                          policyNoNewGeometry=pol.get('noNewGeometry') if pol else None,
                          policyClassification=pol.get('classification') if pol else None,
                          policyDisplayLimitation=pol.get('displayLimitation') if pol else None))
    ids = {s['processId'] for s in steps}
    record = dict(key=key, catalogBuildingId=building.get('buildingId'), name=building['name'], stageCount=len(steps), steps=steps,
                  canonicalGLB=binding(glb_path), glbMemberCount=len(members),
                  reviewStageHistogram=dict(collections.Counter(r['reviewStage'] for r in members)),
                  foreignNonNullProcessAssignments=[r for r in members if r.get('processId') is not None and r['processId'] not in ids],
                  nullProcessContextOrUnresolvedMembers=null_members,
                  nullProcessPolicy='Keep processId null, assignmentStatus and original reviewStage; final review visibility is not a new curriculum process identity.',
                  downloadPackIds=sorted({pack['id'] for pack in download['packs'] if any(asset['asset'] in {s.get('legacyArtAsset') for s in steps} for asset in pack['assets'])}),
                  worldEntityExists=building.get('buildingId') in {r['id'] for r in world['buildings'] + world['gates']})
    pack_alias = {'ansarang': 'ansarangchae', 'toilet': 'toilet', 'toilet1': 'toilet', 'sadangmun': 'sadangmun'}
    pack_id = pack_alias.get(key, building.get('buildingId'))
    if pack_id in {pack['id'] for pack in download['packs']}:
        record['downloadPackIds'] = sorted(set(record['downloadPackIds'] + [pack_id]))
    record['runtimeArtSeriesIds'] = sorted({s['currentRuntimeArt']['seriesId'] for s in steps if s['currentRuntimeArt']})
    (out['buildings'] if key in keys else out['additionalNativeGroups']).append(record)
out.update(buildingCount=len(out['buildings']), buildingStageCuts=sum(b['stageCount'] for b in out['buildings']),
           allNativeInstanceStageCuts=sum(b['stageCount'] for b in out['buildings'] + out['additionalNativeGroups']),
           runtimeApprovedArtStageCount=sum(len(s['stages']) for s in art['series']), runtimeSarangStageCount=len(sarang['stages']),
           nullProcessMembersInElevenBuildings=sum(len(b['nullProcessContextOrUnresolvedMembers']) for b in out['buildings']))
out['renderContract'] = dict(
    materialPolicy='Apply copied materials to every occupied original mesh slot, including initially hidden objects; reuse those material bindings for every construction cut.',
    cumulativeSelector='For each existing sequence n, show canonical source objects with preserved reviewStage <= n, respecting explicit source hidden-object policy; do not derive new process IDs.',
    cameraPolicy='One fixed approved complete-building camera, resolution, scale, lighting, world and exposure for every stage of that building. Do not refit each partial stage.',
    emptyStagePolicy='Keep existing process ID and order even when visible geometry repeats; reuse the prior selector/render with an explicit reason. No invented components or learning credit.',
    contextPolicy='Unresolved process/context paving retains null processId and original reviewStage; separately report it and its render visibility.',
    requiredManifestFields=['processId', 'sequence', 'nativeSha256', 'sourceObjectNames or visibleSetSha256', 'newMembers', 'visibleMembers', 'isFinal', 'camera', 'materialBindingSha256', 'file', 'sha256', 'reuse reason if any'],
    nativeRecipe=str(P / 'produce.py') + ':190-215',
    caveat='Existing produce.construction references production base verification and lock; adapt to R16 candidate paths and include separately authorized visual proxy objects without changing original mapping.')
out['runtimeExportContract'] = dict(
    assembler=str(R12 / 'canonical/sources/app-export-tools/build_r12_process_delivery.py'),
    splitter=str(R12 / 'canonical/sources/app-export-tools/split_r12_process_glb.py'),
    semantics='delta_only; each process asset must contain exactly its verified policy delta; cumulative display unions prior process assets.',
    requiredBindings=['exact native SHA and path', 'source owner map', 'curriculum display policy', 'original process catalog', 'geometry contract', 'GLB sidecar sourceObject/partId selection', 'source matrices', 'receipt and structural proof'],
    gates=['No-new-geometry stages retain prior selectors and no fabricated asset.', 'Context and standalone variants require separate contracts.', 'Rendering must not grant credit, auto-complete or imply runtime promotion.', 'Current app assets/manifests remain outside this audit.'])
out['runtimeExportContract']['existingExporterNativeHashGuard'] = dict(
    module=str(R12 / 'canonical/sources/app-export-tools/r12_native_source.py'),
    accepted=['b954f76cdccc26619cf977497ac45509dabebc5e45f194ad5396e1d655e734b5', 'b3b51dec9f2d4a7629912326bb224e8cf5595c2a874a1c3c85075a5f742af434'],
    r16Compatibility='Existing exporter rejects R16 material derivative hashes; a separately verified and explicitly bound derivative contract is required.')
out['selectorDifferencesFromOriginalR12DisplayPolicy'] = [
    dict(key=b['key'], processId=s['processId'], noNewCanonicalGLBGeometry=s['noNewGLBGeometry'], policyNoNewGeometry=s['policyNoNewGeometry'])
    for b in out['buildings'] for s in b['steps'] if s['noNewGLBGeometry'] != s['policyNoNewGeometry']]
out['selectorAuthorityWarning'] = 'Canonical review GLB map and original R12 curriculum display policy are different source snapshots. Keep IDs/order intact; do not silently substitute their member selections.'
out['notes'] = [
    'Eleven buildings have 128 canonical review cuts. Gates add 32 instance cuts, giving 160; duplicated left/right hyeopmun uses the same six logical process IDs, so catalog contains 154 unique processes.',
    'Runtime approved art series count and Sarang sequence are independent catalogs; the full native process catalog is absent from the inspected main assets/data.',
    'gokgan and north/south toilets have native process cuts but no corresponding approved runtime stage-art series in the inspected JSONs.',
    'Current maintained warm-stone worktree tool/hanok_scene has older export/render helpers; R12 process delivery tool snapshot is under canonical/sources/app-export-tools.',
]
dest = P / 'PROCESS_STYLE_SCOPE_R16.json'
dest.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('PROCESS SCOPE', str(dest), 'buildings', out['buildingCount'], 'cuts', out['buildingStageCuts'], 'null members', out['nullProcessMembersInElevenBuildings'])
