"""Validate approved bytes and shared 2.5D design topology, not unrendered artwork."""
from pathlib import Path
from copy import deepcopy
import argparse
import json
from PIL import Image
from promote_ansarang_shrine_masters import APPROVED, sha

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'docs/assets/ildu_ansarang_shrine_construction_20260914/construction_design.json'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(data):
    require({b['id'] for b in data['buildings']} == set(APPROVED), 'building inventory')
    results = []
    for building in data['buildings']:
        bid = building['id']
        digest, count, _ = APPROVED[bid]
        canonical, geometry, steps = (building[k] for k in ('canonical', 'geometry', 'steps'))
        path = ROOT / canonical['assetPath']
        expected_path = f'assets_unused/pending_review/personal_hanok_v3/canonical/{bid}/{bid}-v3-canonical.png'
        require(canonical['assetPath'] == expected_path, f'{bid}: canonical path')
        require(sha(path) == digest == canonical['sha256'], f'{bid}: canonical hash')
        lock = json.loads((ROOT / canonical['lockPath']).read_text(encoding='utf-8'))
        require(lock['sha256'] == digest and lock['status'] == 'approved_canonical_master', f'{bid}: approval lock')
        with Image.open(path) as im:
            require(list(im.size) == canonical['canvas'] and im.mode == 'RGBA', f'{bid}: canvas/alpha')
            if bid == 'ansarangchae':
                require(all(im.getpixel(p)[3] == 0 for p in ((1330, 590), (1419, 759))), 'right porch openings')
        require(geometry['finalImageTransform'] == 'identity', f'{bid}: final transform')
        nodes = geometry['nodes']
        width, height = canonical['canvas']
        for key, node in nodes.items():
            x, y = node['xy']
            require(0 <= x <= width and 0 <= y <= height, f'{bid}: out-of-canvas node {key}')
        members = {m['id']: m for m in geometry['members']}
        require(len(members) == len(geometry['members']), f'{bid}: duplicate member')
        for mid, m in members.items():
            require(all(n in nodes for n in m['nodes']), f'{bid}: missing node {mid}')
            references = m.get('supports', []) + ([m['attachmentTo']] if m.get('attachmentTo') else [])
            require(all(ref in members for ref in references), f'{bid}: missing supporting member {mid}')
            if m['group'] == 'posts':
                padstone = members['padstone.' + mid.split('.', 1)[1]]
                require(m['supportNode'] == padstone['contactNode'] == m['nodes'][0], f'{bid}: floating post {mid}')
                require(m['topNode'] == m['nodes'][-1], f'{bid}: post head {mid}')
                require(nodes[m['supportNode']]['xy'][1] > nodes[m['topNode']]['xy'][1], f'{bid}: post has no height')
            if m.get('registrationStation'):
                require(m['nodes'][0] == m['ridgeNode'] and m['nodes'][-1] == m['eaveNode'], f'{bid}: rafter ends')
                side = mid.split('.')[1]
                for j, support in enumerate(m['supportNodes'], 1):
                    require(support in m['nodes'] and support in members[f'purlin.{side}.{j}']['nodes'], f'{bid}: floating rafter support')
            if m.get('supportsRoofRail'):
                destination = m['nodes'][-1]
                rails = [v for k, v in members.items() if k.startswith('purlin.')]
                require(destination.startswith('ridge.station.') or any(destination in rail['nodes'] for rail in rails), f'{bid}: roof support misses rail')
        front = geometry['volume']['frontRow']
        rear = geometry['volume']['rearRow']
        require(len(front) == len(rear) == building['bayCount'] + 1, f'{bid}: bay count')
        require(all(nodes[f]['xy'] != nodes[r]['xy'] for f, r in zip(front, rear)), f'{bid}: flattened volume')
        expected_posts = 2 if bid == 'sadangmun' else 2 * (building['bayCount'] + 1)
        require(sum(m['group'] == 'posts' for m in members.values()) == expected_posts, f'{bid}: physical post count')
        for i in range(9):
            require(members[f'rafter.front.{i}']['ridgeNode'] == members[f'rafter.rear.{i}']['ridgeNode'], f'{bid}: split roof ridge')
        require(('hip.corner' in members) == (bid == 'ansarangchae'), f'{bid}: building-specific roof')
        require(len(steps) == count, f'{bid}: stage count')
        installed = set()
        for number, stage in enumerate(steps, 1):
            require(stage['number'] == number, f'{bid}: stage sequence')
            require(stage['geometryRef'] == bid + ':shared', f'{bid}: geometry reference')
            require(not set(stage).intersection(('camera', 'geometry', 'nodes', 'transform')), f'{bid}: per-stage geometry drift')
            require(stage['prerequisites'] == ([number - 1] if number > 1 else []), f'{bid}: sequence prerequisites')
            installed.update(stage['adds'])
            require(set(stage['installed']) == installed, f'{bid}: installed structure changed')
            for group in installed:
                require(set(building['dependencies'].get(group, [])) <= installed, f'{bid}: unsupported {group}')
            for field in ('title', 'sentence', 'observe'):
                require(all(stage[field].get(lang, '').strip() for lang in ('ko', 'en', 'de')), f'{bid}: missing language')
            if number < count:
                require(stage['artworkStatus'] == 'generated_reconstruction', f'{bid}: intermediate status')
                expected_asset = f"assets/illustrations/personal_hanok_v3/construction/{bid}/stage_{number:02d}_"
                require(stage.get('assetPath', '').startswith(expected_asset), f'{bid}: false intermediate artwork')
                require(sha(ROOT / stage['assetPath']) == stage['sha256'], f'{bid}: intermediate hash')
            else:
                require(stage['id'] == 'complete' and stage['artworkStatus'] == 'approved_canonical', f'{bid}: final status')
                require(stage['assetPath'] == canonical['assetPath'] and stage['sha256'] == digest, f'{bid}: final does not reuse exact master')
        if bid != 'ansarangchae':
            require(not installed.intersection(('ondol', 'maruPorch')), f'{bid}: dwelling features on non-residential building')
        results.append({'building': bid, 'stages': count, 'nodes': len(nodes), 'members': len(members),
                        'approvedSha256': digest, 'physicalPosts': expected_posts, 'result': 'passed'})
    return results


def check_rejection_probes(data):
    cases = {
        'changed master': lambda b: b['canonical'].update(sha256='0' * 64),
        'flat facade': lambda b: b['geometry']['volume'].update(rearRow=b['geometry']['volume']['frontRow']),
        'floating post': lambda b: b['geometry']['members'][0].update(supportNode='F1.foot'),
        'floating rafter': lambda b: next(m for m in b['geometry']['members'] if m['id'] == 'rafter.front.0').update(supportNodes=['F0.foot', 'F1.foot']),
        'different stage camera': lambda b: b['steps'][3].update(camera={'zoom': 1.1}),
        'removed installed post': lambda b: b['steps'][4]['installed'].remove('posts'),
        'wrong final image': lambda b: b['steps'][-1].update(assetPath='wrong.png'),
        'pretend intermediate image': lambda b: b['steps'][0].update(assetPath=b['canonical']['assetPath']),
    }
    for name, mutate in cases.items():
        changed = deepcopy(data)
        mutate(changed['buildings'][0])
        try:
            validate(changed)
        except ValueError:
            continue
        raise ValueError('Invalid design was accepted: ' + name)
    return list(cases)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-report', action='store_true')
    args = parser.parse_args()
    data = json.loads(DESIGN.read_text(encoding='utf-8'))
    result = {'scope': 'Canonical PNG byte identity and authored shared design topology. No intermediate PNG alignment or runtime claim.',
              'buildings': validate(data), 'rejectedInvalidDesigns': check_rejection_probes(data),
              'intermediateArtworkRendered': 31, 'intermediateArtworkPlanned': 31,
              'rasterAlignmentTargetPx': 2, 'rasterAlignmentMeasured': False}
    if args.write_report:
        DESIGN.with_name('design_validation.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
