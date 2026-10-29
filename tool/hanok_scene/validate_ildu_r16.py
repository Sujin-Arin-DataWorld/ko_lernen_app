"""Verify the committed R16 delivery; Blender baking is a separate gate."""
from pathlib import Path
import hashlib,json,argparse,re

def sha(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def validate(root,native_root=None):
    root=Path(root).resolve();d=root/'docs/hanok_r16'
    c=json.loads((d/'APP_ASSET_CONTRACT.json').read_text(encoding='utf-8'))
    assert c['buildingCount']==11 and c['stageCount']==128
    assert not c['runtimeIntegrated'] and not c['glbPbrBakeComplete']
    ids=set();keys=set();count=0
    for b in c['buildings']:
        assert b['key'] not in keys;keys.add(b['key'])
        assert [s['sequence'] for s in b['stages']]==list(range(1,len(b['stages'])+1))
        assert sha(d/b['fullImage'])==b['fullImageSha256']
        for s in b['stages']:
            assert s['processId'] not in ids;ids.add(s['processId']);count+=1
            p=(d/s['reviewImage']).resolve();assert p.is_relative_to(d)
            assert sha(p)==s['sha256']
        assert {f['kind'] for f in b['packedNatives']}=={'full','stage'}
        for f in b['packedNatives']:
            assert not f['externalImagesRequired'] and f['geometryNamesUVHierarchyPropertiesUnchanged']
            if native_root:assert sha(Path(native_root)/b['key']/(f['kind']+'.blend'))==f['sha256']
    assert len(keys)==11 and count==128
    a=json.loads((d/'ARCHIVE.json').read_text(encoding='utf-8'))
    assert a['complete'] and a['remoteRefVerified'] and re.fullmatch('[0-9a-f]{40}',a['commit'])
    promotion=json.loads((d/'CANONICAL_PROMOTION_R16.json').read_text(encoding='utf-8'))
    assert promotion['approved'] is True and promotion['buildingCount']==11 and promotion['stageCount']==128 and promotion['nativeCount']==22
    assert promotion['contractSha256']==sha(d/'APP_ASSET_CONTRACT.json')
    assert promotion['archiveCommit']==a['commit'] and promotion['archiveManifestSha256']==a['manifestSha256']
    assert not promotion['runtimeIntegrated'] and not promotion['glbPbrBakeComplete'] and not promotion['runtimeProgressPolicyChanged']
    registered={(n['building'],n['kind']):(n['variant'],n['path'],n['sha256']) for n in promotion['natives']}
    assert len(registered)==22
    for b in c['buildings']:
        for n in b['packedNatives']:
            assert registered[b['key'],n['kind']]==('r16-native',f"{b['key']}/{n['kind']}.blend",n['sha256'])
            assert n['archiveVariant']=='r16-native' and n['archivePath']==f"{b['key']}/{n['kind']}.blend"
    assert promotion['plaques']['firstStage']==16
    roof=json.loads((d/'ROOF_VARIANT_POLICY.json').read_text(encoding='utf-8'))
    assert roof['standaloneReady'] and not roof['newProgressOrReward'] and not roof['inventedProcessThreshold']
    assert c['roofVariantPolicy']==promotion['roofVariantPolicy']=='ROOF_VARIANT_POLICY.json'
    assert promotion['roofVariantPolicySha256']==sha(d/'ROOF_VARIANT_POLICY.json')
    assert promotion['standaloneNativeCount']==4 and promotion['totalBuildingNativeCount']==26
    assert promotion['standaloneNatives']==roof['natives'] and len(roof['natives'])==4
    extra=a['standaloneRoofs']
    assert extra['complete'] and extra['freshRemoteFetch'] and extra['nativeCount']==4
    assert extra['commit']==roof['archive']['commit'] and re.fullmatch('[0-9a-f]{40}',extra['commit'])
    assert extra['manifestSha256']==roof['archive']['manifestSha256']
    assert {(n['building'],n['kind']) for n in roof['natives']}=={(k,t) for k in ['sarang','jung'] for t in ['full','stage']}
    for b in c['buildings']:
        if b['key'] not in {'sarang','jung'}:continue
        alt=roof['standaloneBuildings'][b['key']]
        assert alt['complete'] and not alt['runtimeIntegrated']
        assert sha(d/alt['fullImage'])==alt['fullImageSha256']
        assert len(alt['stages'])==len(b['stages'])
        for original,standalone in zip(b['stages'],alt['stages']):
            assert (original['sequence'],original['processId'],original['label'])==(standalone['sequence'],standalone['processId'],standalone['label'])
            image=(d/standalone['reviewImage']).resolve();assert image.is_relative_to(d)
            assert sha(image)==standalone['sha256']
    estate=json.loads((d/'estate/RENDER_MANIFEST.json').read_text(encoding='utf-8'))
    assert estate['complete'] and len(estate['layerReceipts'])==15
    assert estate['sha256']==sha(d/'estate/complete.png')==promotion['completedEstateView']['imageSha256']
    assert all(row['settingsSha256']==estate['settingsSha256'] and row['sourceFilesUnchanged'] for row in estate['layerReceipts'])
    print('PASS: R16 canonical 11/128, 22 connected + 4 standalone native contracts, 28 roof-stage variants, estate, private pins')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[2]);p.add_argument('--native-root',type=Path);args=p.parse_args();validate(args.root,args.native_root)
