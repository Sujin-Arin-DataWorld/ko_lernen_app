"""Keep current human designation visible without resaving approved native bytes."""
from pathlib import Path
import json
P=Path(__file__).resolve().parent.parent
f=P/'lookdev-sarang-r5/index.html'
s=f.read_text(encoding='utf-8')
for old,new in {
 '사랑채 재질 시안 R5':'사랑채 정본 재질 R5',
 '검토용 후보':'사용자 승인·정본 지정',
 '이후 · R5 붓결 시안':'이후 · R5 정본 재질',
 '3D 후보입니다.':'3D 재질 작업입니다.',
 '후보 원본 크기':'R5 원본 크기',
 'Blender 후보':'정본 Blender 원본',
 'R5 붓결 후보':'R5 정본 재질',
 'r5-final-3':'canonical-r5',
}.items():
 s=s.replace(old,new)
s=s.replace('</script>', 'split(0);\n</script>')
f.write_text(s,encoding='utf-8')
f=P/'lookdev-buildings-r5/VERIFICATION_SUMMARY.json'
d=json.loads(f.read_text(encoding='utf-8'))
d.update(status='14 building-specific native R5 materials complete and designated canonical by current user instruction',canonicalPromotion=True,canonicalPromotionManifest='../MATERIAL_CANONICAL_PROMOTION_R5.json')
f.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
f=P/'lookdev-buildings-r5/finalize_extension.py'
s=f.read_text(encoding='utf-8')
s=s.replace("    write(HOME/'VERIFICATION_SUMMARY.json',report)","    if (HOME.parent/'MATERIAL_CANONICAL_PROMOTION_R5.json').exists():\n        report.update(status='R5 native materials designated canonical by current user instruction',canonicalPromotion=True,canonicalPromotionManifest='../MATERIAL_CANONICAL_PROMOTION_R5.json')\n    write(HOME/'VERIFICATION_SUMMARY.json',report)")
old="    write(HOME/'CURRENT_STATUS.json',dict(status=report['status'],appliedCandidates=14,approvedReference='sarang R5',newCandidateVisualApproval=False,comparison='index.html',verification='VERIFICATION_SUMMARY.json',next='User visual review before expanding to interactive GLB and construction runtime'))"
new="    current=dict(status=report['status'],appliedCandidates=14,approvedReference='sarang R5',comparison='index.html',verification='VERIFICATION_SUMMARY.json',canonical=report['canonicalPromotion'],glbViewerUpdated=False,appIntegrated=False)\n    if report['canonicalPromotion']:current.update(promotion='../MATERIAL_CANONICAL_PROMOTION_R5.json',publicationAuthorized=True)\n    write(HOME/'CURRENT_STATUS.json',current)"
assert old in s
f.write_text(s.replace(old,new),encoding='utf-8')
f=P/'lookdev-standalone-r5/WORK.md'
s=f.read_text(encoding='utf-8').replace('- [ ] Audit','- [x] Audit').replace('- [ ] Apply','- [x] Apply').replace('- [ ] Add','- [x] Add')
s+='\n## Canonical authority correction\n\nThe user explicitly designated the approved R5 material work canonical. The accepted Sarang native remains byte-identical (cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8). MATERIAL_CANONICAL_PROMOTION_R5.json selects 17 current natives; catalog native/render references follow it. Historic candidate filenames and original comparison images remain archival provenance. Interactive GLB materials and Flutter have not been updated. Both standalone natives passed save/reopen verification: Sarang preserves all 829 original meshes and reuses the approved internal apron backing (830 total), Jung preserves 605 originals. The earlier unlabelled BEFORE display was a presentation error; the accepted native was not rolled back.\n'
f.write_text(s,encoding='utf-8')
print('Current authority labels synchronized; native bytes untouched')
