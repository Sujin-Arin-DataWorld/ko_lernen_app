"""Read-only file verification, then write the current candidate ledger/gallery."""
from pathlib import Path
import json,hashlib,subprocess,shutil
from PIL import Image
import numpy as np
HOME=Path(__file__).resolve().parent
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def main():
    sources=json.loads((HOME/'source-audit.json').read_text(encoding='utf-8'));unique={b['native']:b['sha256'] for b in sources}
    assert len(sources)==14
    for path,digest in unique.items():assert sha(Path(path))==digest,path
    rows=[]
    for b in sources:
        out=HOME/b['key'];v=json.loads((out/'verification.json').read_text(encoding='utf-8'));r=json.loads((out/'render-manifest.json').read_text(encoding='utf-8'))
        assert v['passed'] and v['reopened'] and v['version']=='building-r5-2' and v['meshCount']==b['count']
        assert v['sourceSha256']==b['sha256'] and v['geometryUVsTransformsModifiersEqual'] and v['attributesStagesPropertiesEqual'] and v['sourceMaterialGraphsEqual'] and v['sourceImageBytesEqual']
        assert r['complete'] and r['matchedCameraLights'] and len(r['renders'])==4
        assert sha(out/v['candidateNative'])==v['candidateSha256']
        assert all(sha(out/x['file'])==x['sha256'] for x in r['renders'])
        difference={}
        for view in ['hero','detail']:
            before=np.asarray(Image.open(out/('before-'+view+'.png')).convert('RGB'),dtype=np.float32)
            after=np.asarray(Image.open(out/('after-'+view+'.png')).convert('RGB'),dtype=np.float32)
            assert before.shape==after.shape
            bg=np.median(before[:5,:,:].reshape(-1,3),axis=0);foreground=np.max(np.abs(before-bg),axis=2)>8
            delta=np.abs(before-after);difference[view]=dict(meanAbsoluteRgbDifferenceInForeground=float(delta[foreground].mean()),fractionForegroundWithMoreThan3RgbSteps=float((delta.max(axis=2)[foreground]>3).mean()))
            assert difference[view]['meanAbsoluteRgbDifferenceInForeground']>.05,'Identical output '+b['key']
        rows.append(dict(key=b['key'],name=b['name'],meshCount=b['count'],native=b['key']+'/'+v['candidateNative'],sha256=v['candidateSha256'],roles=v['roles'],reopenedPreservationPassed=True,renderCount=4,pixelComparison=difference))
    ref=HOME.parent/'lookdev-sarang-r5/sarang-three-value-brush-candidate.blend'
    assert sha(ref)=='cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8'
    report=dict(date='2026-10-22',status='14 building-specific native material candidates complete; awaiting visual review',buildingCount=14,meshCount=sum(b['count'] for b in sources),renderCount=56,
      unchangedSourceFiles=unique,acceptedSarangR5NativeUnchanged=True,allNativeFilesReopenedAndPreserved=True,allRenderFilesVerified=True,
      canonicalPromotion=False,glbViewerUpdated=False,constructionRuntimeUpdated=False,flutterUpdated=False,rows=rows,freeDiskBytes=shutil.disk_usage(HOME).free)
    if (HOME.parent/'MATERIAL_CANONICAL_PROMOTION_R5.json').exists():
        report.update(status='R5 native materials designated canonical by current user instruction',canonicalPromotion=True,canonicalPromotionManifest='../MATERIAL_CANONICAL_PROMOTION_R5.json')
    write(HOME/'VERIFICATION_SUMMARY.json',report)
    current=dict(status=report['status'],appliedCandidates=14,approvedReference='sarang R5',comparison='index.html',verification='VERIFICATION_SUMMARY.json',canonical=report['canonicalPromotion'],glbViewerUpdated=False,appIntegrated=False)
    if report['canonicalPromotion']:current.update(promotion='../MATERIAL_CANONICAL_PROMOTION_R5.json',publicationAuthorized=True)
    write(HOME/'CURRENT_STATUS.json',current)
    subprocess.run(['python','-X','utf8',str(HOME/'build_gallery.py')],check=True)
    print('ALL VERIFIED',len(rows),report['meshCount'],'meshes',report['renderCount'],'renders')
if __name__=='__main__':main()
