"""Read-only source audit plus reproducible mockup manifest; never edits artwork."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('build/five-tabs-preview'))
parser.add_argument('--baseline', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
fixture = json.loads((root / 'test/support/five_tabs_preview/first_activity.json').read_text(encoding='utf-8-sig'))
baseline = json.loads(args.baseline.read_text(encoding='utf-8-sig')) if args.baseline else None
ids = ['course','vocab_packs','grammar','word_web','pronunciation','listening','scenarios','smalltalk','hangul','calligraphy','srs','my_words','daily_game','chosung','syllable_cross','cloze','speed_match','sentence_arcade','kkeunmari','custom_practice']
assets=[]
for activity_id in ids:
    relative=f'assets/illustrations/activities/{activity_id}.webp'
    source=root / relative
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    with Image.open(source) as image:
        size=image.size
    assert size == (800,600), (activity_id,size)
    if baseline:
        original=next(a for a in baseline['activities'] if a['id']==activity_id)
        assert digest==original['sha256'],activity_id
    assets.append(dict(id=activity_id,path=relative,bytes=source.stat().st_size,sha256=digest,width=size[0],height=size[1]))
files=[]
for source in sorted(args.output.rglob('*.png')):
    with Image.open(source) as image:
        size=image.size
    files.append(dict(path=source.relative_to(args.output).as_posix(),width=size[0],height=size[1],bytes=source.stat().st_size))
manifest=dict(activity_count=20,learn_count=12,games_count=8,assets=assets,source_art_modified=False,compared_to_baseline=bool(baseline),baseline_sha=baseline['baseline_sha'] if baseline else None,fixture=fixture,fixture_semantics={'first_experience':'empty-history first course link, resolved by actual CourseMissionBrief/direct destination probe','learning_result':'seeded all-correct example, 7 quiz + 2 boss answers, zero claimed awarded XP','gye_member':'illustrative group Morgenlicht, 4 members, 3 of 7 weekly learning days','hanok':'original current runtime preview; updating copy demonstrates pending refresh','bojagi':'independent already-earned pending/opening/stamp-result example, not a reward from onboarding or this first activity','audio':'visual control only; no TTS/audio backend invoked','navigation':'preview-local state only; selected activities preserve catalog identity but do not launch production routes'},companion_video={'selected_mascot':'tiger / Taego','source':'assets/video/character/tiger_sitting2.mp4','source_sha256':hashlib.sha256((root/'assets/video/character/tiger_sitting2.mp4').read_bytes()).hexdigest(),'production_api':'HomeHeroClips.tigerSitting2 derived from unchanged CharacterClips.tigerSitting2; existing CharacterClipPlayer lifecycle/video lease','reserved_logical_size':[144,125],'source_frame_size':[144,144],'composition':'card-edge; only empty lower matte is outside viewport','png_representation':'original video frame at1second, test/support/five_tabs_preview/video_poster.png','motion_evidence':'Separate playable artifact supplied by controller; PNG does not establish video playback'},screenshots=files,limitations=['No production routing, storage, account mutation, reward writes, deployment or physical-device QA.','Automated renderer and fixture gestures are not beginner observation.','The preview assessment uses deterministic example choices; production assessment logic remains authoritative.'])
args.output.mkdir(parents=True,exist_ok=True)
(args.output/'fixture-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'verified_original_art':len(assets),'png_count':len(files),'source_hashes_unchanged':True,'manifest':str(args.output/'fixture-manifest.json')}))
