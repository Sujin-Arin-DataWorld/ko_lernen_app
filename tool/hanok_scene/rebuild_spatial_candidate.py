from pathlib import Path
import bpy,json,sys
sys.path.insert(0,str(Path(__file__).parent))
from repair_northern_spatial_detail import repair,OUT
from apply_site002_registration import apply
from northern_courtyard_photo_repair import repair as photos
from northern_anchae_photo_fittings import add as fittings
from northern_survey_corrections import apply as survey
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'))
c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
repair(bpy.context.scene,c);apply(bpy.context.scene,c);photos(bpy.context.scene,c);fittings(bpy.context.scene,c);survey(bpy.context.scene,c)
(OUT/'spatial-detail-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'spatial-detail-study.blend'),compress=True)
print('SPATIAL CANDIDATE COMPLETE',flush=True)
