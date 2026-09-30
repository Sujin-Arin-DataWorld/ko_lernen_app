"""Apply the user's timber, stone platform and rear-wall corrections together."""
from pathlib import Path
import hashlib
import json
import sys
import bpy
sys.path.insert(0,str(Path(__file__).parent))
from apply_heritage_wood import apply_heritage_wood
from apply_platform_stone import apply_platform_stone
from repair_gokgan_clearance import repair_gokgan_clearance
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
target=N/'estate-fabric.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
source_sha=hashlib.sha256(target.read_bytes()).hexdigest()
contract=json.loads((N/'estate-fabric-contract.json').read_text(encoding='utf8'))
clearance=repair_gokgan_clearance(bpy.context.scene,N)
wood=apply_heritage_wood(bpy.context.scene,N)
paving=apply_platform_stone(bpy.context.scene)
bpy.ops.wm.save_as_mainfile(filepath=str(target),compress=True)
contract.update(gokganRearClearance=clearance,gyeHeritageWood=wood,gyePlatformStone=paving)
contract['requestedCraftSourceSha256']=source_sha
contract['candidateSceneSha256']=hashlib.sha256(target.read_bytes()).hexdigest()
(N/'estate-fabric-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
print('REQUESTED CRAFT APPLIED',len(clearance['movedObjects']),len(wood['mapping']),sum(row['stones'] for row in paving['buildings']),flush=True)
