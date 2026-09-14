"""Promote Jin-approved PNG bytes and publish only the learner-facing gallery."""
from pathlib import Path
import copy
import hashlib
import json
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets_unused/pending_review/personal_hanok_v3/four_buildings_construction_29deg_v1'
RUNTIME = 'assets/illustrations/personal_hanok_v3/construction'
DOC = ROOT / 'docs/assets/ildu_four_buildings_construction_20260914'
PUBLIC = ROOT / 'hangul-sori-site-local/public/hanok/construction'
VIEWER = ROOT / 'docs/mockups/four-buildings-construction-29'
APPROVAL = '너무 잘햇어ㅎㅎ 커밋푸시 메인에 병합하고 이걸로 라이브 되게해줘.'
IDS = {'jungmunganchae': 12, 'araechae': 12, 'anchae': 14, 'anchae-store': 11}

def tr(ko, en, de):
    return dict(ko=ko, en=en, de=de)

OBSERVE = {
'site-route': tr('통행길과 방, 마루가 놓일 자리를 함께 살펴봐요.', 'Look at the space for the passage, rooms and open maru.', 'Betrachte den Platz für den Durchgang, die Räume und den offenen Maru.'),
'site-rooms': tr('방 세 칸과 앞 툇마루에 필요한 깊이를 확보해요.', 'The site allows depth for three bays and the front wooden porch.', 'Der Bauplatz bietet Tiefe für drei Gefache und den vorderen Holzvorbau.'),
'site-household': tr('부엌과 방, 대청은 서로 다른 높이와 동선으로 연결돼요.', 'The kitchen, rooms and main hall connect through different floor levels and routes.', 'Küche, Zimmer und Haupthalle sind durch unterschiedliche Bodenhöhen und Wege verbunden.'),
'site-storage': tr('문으로 들어온 물건을 보관할 안쪽 공간도 필요해요.', 'Objects brought through the doors need space inside for storage.', 'Für Gegenstände, die durch die Türen kommen, braucht es innen Lagerfläche.'),
'stone-foundation': tr('초석은 나무기둥을 받쳐요. 기단의 높이는 건물마다 달라요.', 'Stone bases support the wooden posts. The height of the platform varies by building.', 'Steinsockel tragen die Holzpfosten. Die Höhe des Unterbaus unterscheidet sich von Gebäude zu Gebäude.'),
'posts': tr('앞뒤 기둥 사이에 사람이 들어갈 공간의 깊이가 생겨요.', 'The front and rear posts define the depth of a space people can enter.', 'Zwischen den vorderen und hinteren Pfosten entsteht ein begehbarer Raum.'),
'posts-floor-support': tr('큰 기둥뿐 아니라 툇마루 아래의 작은 받침도 바닥을 지탱해요.', 'Alongside the main posts, smaller supports beneath the porch carry its floor.', 'Neben den großen Pfosten tragen kleinere Stützen unter dem Vorbau dessen Boden.'),
'beams-purlins': tr('보는 기둥 사이를 잇고, 도리는 서까래를 받아요. 힘이 아래로 전달되는 연결을 살펴봐요.', 'Beams span between posts, and purlins support the rafters. Follow the connections that carry the load downwards.', 'Balken verbinden die Pfosten, Pfetten tragen die Sparren. Verfolge, wie die Last über diese Verbindungen nach unten gelangt.'),
'hip-frame': tr('안채의 팔작지붕은 모서리에서도 골격이 이어져요.', 'The Anchae roof frame also connects around the corners of its hipped-and-gabled roof.', 'Das Gerüst des Walmdachs mit Giebeln am Anchae ist auch an den Ecken verbunden.'),
'rafters-eaves': tr('서까래는 도리에 걸쳐 처마까지 뻗어요. 벽 밖으로 나온 처마는 비와 햇빛을 가리는 데 도움이 돼요.', 'Rafters rest across the purlins and extend into the eaves. The overhang helps shelter the walls from rain and sunlight.', 'Die Sparren liegen auf den Pfetten und reichen bis zum Dachüberstand. Dieser hilft, die Wände vor Regen und Sonne zu schützen.'),
'roof-bed': tr('서까래 위의 바탕층이 기와를 받을 면을 만들어요.', 'Layers above the rafters form the surface that will carry the roof tiles.', 'Die Schichten über den Sparren bilden die Unterlage für die Dachziegel.'),
'tiles': tr('겹쳐 놓인 기와와 지붕 경사를 따라 빗물이 아래로 흘러요.', 'Rainwater runs down the sloping roof over the overlapping tiles.', 'Regenwasser fließt über die überlappenden Ziegel das geneigte Dach hinunter.'),
'room-walls': tr('벽은 기둥 사이를 채워요. 문과 창 안쪽에는 방의 깊이가 남아 있어요.', 'Walls fill the spaces between posts. The openings still reveal the depth of the rooms.', 'Wände füllen die Felder zwischen den Pfosten. Durch die Öffnungen bleibt die Tiefe der Räume erkennbar.'),
'walls-kitchen': tr('부엌과 온돌방의 바닥 높이가 달라요. 생활에 맞춰 공간을 나눠요.', 'The kitchen and ondol rooms have different floor levels, arranged for everyday activities.', 'Küche und Ondol-Zimmer haben unterschiedliche Bodenhöhen, passend zu ihrer Nutzung im Alltag.'),
'kitchen-loft': tr('다락 바닥을 받치는 나무와 그 아래 부엌 공간을 함께 살펴봐요.', 'Look at the timbers supporting the loft floor and the kitchen space beneath it.', 'Betrachte die Hölzer, die den Zwischenboden tragen, und den Küchenraum darunter.'),
'ondol': tr('온돌방은 바닥을 데우는 공간이에요. 나무 마루와 쓰임이 달라요.', 'An ondol room is heated through its floor. Its use differs from that of a wooden maru.', 'Ein Ondol-Zimmer wird über den Boden beheizt. Es wird anders genutzt als ein hölzerner Maru.'),
'ondol-floors': tr('중문채에도 사람이 쓰던 두 방이 있어요. 방바닥과 열린 마루를 비교해 봐요.', 'The Jungmunganchae also contains two rooms people used. Compare their floors with the open maru.', 'Auch im Jungmunganchae liegen zwei genutzte Räume. Vergleiche ihre Böden mit dem offenen Maru.'),
'open-maru': tr('마루판은 귀틀과 받침 위에 놓여요. 마루 아래에는 빈 공간이 있어요.', 'The floorboards rest on a timber framework and supports, leaving open space beneath the maru.', 'Die Dielen liegen auf einem Holzrahmen mit Stützen. Unter dem Maru bleibt ein Hohlraum.'),
'maru': tr('마루방과 앞 툇마루의 판재 아래로 받침 구조가 이어져요.', 'A supporting framework runs beneath the boards of the maru room and front porch.', 'Unter den Dielen des Maru-Raums und des vorderen Vorbaus liegt ein tragendes Holzgerüst.'),
'daecheong-maru': tr('대청은 앞뒤를 잇는 깊은 공간이에요. 바닥 아래의 귀틀이 마루판을 받쳐요.', 'The main hall is a deep space linking front and back. Timber framing beneath supports the floorboards.', 'Die Haupthalle verbindet als tiefer Raum Vorder- und Rückseite. Ein Holzrahmen darunter trägt die Dielen.'),
'compacted-floor': tr('안채 창고에는 다진 흙바닥을 표현했어요. 마루와 온돌방의 바닥과 비교해 봐요.', 'The Anchae storehouse is shown with a compacted earth floor. Compare it with the maru and ondol floors.', 'Das Lagergebäude des Anchae ist mit einem gestampften Erdboden dargestellt. Vergleiche ihn mit den Böden von Maru und Ondol-Zimmern.'),
'walls-partition': tr('중앙 칸막이를 기준으로 두 보관 공간이 생겨요.', 'A central partition creates two storage spaces.', 'Eine mittlere Trennwand schafft zwei Lagerräume.'),
'gate-changho': tr('문은 문틀에 달려 있어요. 열린 문 너머로 통행길과 방 안쪽이 보여요.', 'The doors hang from their frames. Through the openings, you can see the passage and room interiors.', 'Die Türen hängen in ihren Rahmen. Durch die Öffnungen siehst du den Durchgang und das Innere der Räume.'),
'changho': tr('문짝이 걸리는 곳과 문 뒤의 방을 함께 살펴봐요.', 'Look at where each door leaf is attached and at the room behind it.', 'Betrachte die Befestigung der Türflügel und den Raum dahinter.'),
'doors-vents': tr('물건을 드나들게 하는 문과 작은 환기구는 역할이 달라요.', 'Doors for moving objects and small ventilation openings serve different purposes.', 'Türen für den Transport von Gegenständen und kleine Lüftungsöffnungen haben unterschiedliche Aufgaben.'),
'complete-use': tr('건물의 방과 마루, 일하고 보관하는 공간은 사람의 생활을 위한 자리였어요.', 'Rooms, wooden halls, work areas and storage spaces served the needs of everyday life.', 'Zimmer, Holzhallen, Arbeits- und Lagerräume dienten dem täglichen Leben.')
}
CULTURE = {
'jungmunganchae': tr('중문채는 통행문과 두 방, 열린 마루를 함께 가진 생활 건물이에요. 길이 통하는 곳과 사람이 머무는 곳의 차이를 살펴봐요.', 'The Jungmunganchae combines a passage gate, two rooms and an open maru. Compare the route through the building with the spaces where people stayed.', 'Das Jungmunganchae verbindet einen Tordurchgang, zwei Räume und einen offenen Maru. Vergleiche den Durchgang mit den Bereichen, in denen Menschen verweilten.'),
'araechae': tr('아래채는 세 칸의 실내와 앞 툇마루를 함께 살펴보는 건물이에요. 온돌방과 마루, 바닥을 받치는 구조가 서로 달라요.', 'The Araechae brings together three indoor bays and a front wooden porch. Its ondol rooms, maru and floor supports show different ways of using the space.', 'Beim Araechae gehören drei innere Gefache und ein vorderer Holzvorbau zusammen. Ondol-Zimmer, Maru und Bodenstützen zeigen unterschiedliche Nutzungen des Raums.'),
'anchae': tr('안채에는 부엌과 그 위 다락, 온돌방, 대청이 이어져요. 요리하고 쉬고 오가는 생활을 공간의 높이와 깊이에 맞춰 살펴봐요.', 'The Anchae connects a kitchen and loft, ondol rooms and a main hall. Explore how changes in height and depth accommodate cooking, resting and moving through the house.', 'Das Anchae verbindet Küche und Zwischenboden, Ondol-Zimmer und Haupthalle. Erkunde, wie unterschiedliche Höhen und Tiefen Platz zum Kochen, Ruhen und Durchgehen schaffen.'),
'anchae-store': tr('안채 창고는 물건을 들이고 보관하고 꺼내 쓰던 생활 공간이에요. 두 보관 공간과 출입문, 흙바닥을 살펴봐요. 구체적인 보관 물품이나 거주 방은 단정하지 않아요.', 'The Anchae storehouse was used to bring in, store and retrieve belongings. Explore its two storage spaces, entrances and earth floor. These images do not establish particular stored goods or sleeping rooms.', 'Im Lagergebäude des Anchae wurden Gegenstände hineingebracht, aufbewahrt und wieder herausgeholt. Betrachte die zwei Lagerräume, Eingänge und den Erdboden. Bestimmte Lagergüter oder Schlafräume werden durch diese Bilder nicht belegt.')
}

def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def main():
    selected = json.loads((SOURCE/'construction_catalog.json').read_text(encoding='utf-8'))
    audit = json.loads((SOURCE/'asset_audit.json').read_text(encoding='utf-8'))
    hashes = {row['path']: row['sha256'] for row in audit['images']}
    assert {b['id']:len(b['steps']) for b in selected['buildings']} == IDS
    series, receipt = [], []
    public_catalog = copy.deepcopy(selected)
    public_catalog['status'] = 'approved_canonical'
    public_catalog.pop('generator', None)
    for building, public_building in zip(selected['buildings'], public_catalog['buildings']):
        bid = building['id']
        stages = []
        for stage, public_stage in zip(building['steps'], public_building['steps']):
            blob = (SOURCE/stage['file']).read_bytes()
            digest = hashlib.sha256(blob).hexdigest()
            assert digest == hashes[stage['file']]
            assert blob[:8] == b'\x89PNG\r\n\x1a\n'
            width, height = struct.unpack('>II', blob[16:24])
            assert (width, height) == (1536, 1024)
            filename = f"stage_{stage['number']:02}_{stage['id'].replace('-', '_')}.png"
            relative = f'{RUNTIME}/{bid}/{filename}'
            runtime = ROOT/relative
            web_relative = f'images/{bid}/{filename}'
            for destination in (runtime, PUBLIC/web_relative):
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(blob)
            public_stage['file'] = web_relative
            public_stage['sha256'] = digest
            public_stage['observe'] = OBSERVE[stage['id']]
            row = {
                'stageId': f"{bid}-{stage['id']}", 'buildingId': bid,
                'sequence': stage['number'], 'asset': relative,
                'title': tr(stage['ko'], stage['en'], stage['de']),
                'observe': OBSERVE[stage['id']], 'line': stage['sentence'],
                'scene': tr('건축 공정 그림을 보며 구조와 생활 공간을 설명하는 장면이에요.', 'You are describing a construction illustration and the spaces used in daily life.', 'Du beschreibst eine Darstellung des Bauablaufs und die darin genutzten Alltagsräume.'),
                'task': tr('그림을 보며 이번 공정을 한국어 한 문장으로 설명해 보세요.', 'Describe this stage in one Korean sentence while looking at the picture.', 'Beschreibe diesen Bauschritt beim Betrachten des Bildes mit einem koreanischen Satz.'),
                'exercise': {'kind':'spoken_description'}, 'glossary': [],
                'approvedPngAsset': (SOURCE/ stage['file']).relative_to(ROOT).as_posix(),
                'approvedPngSha256': digest, 'runtimeEncoding':'original PNG; byte-identical',
                'width':width, 'height':height, 'bytes':len(blob), 'sha256':digest,
                'processTags':[stage['id']]
            }
            stages.append(row)
            receipt.append({'buildingId':bid,'sequence':stage['number'],'approvedSource':row['approvedPngAsset'],'runtimeAsset':relative,'publicAsset':f'hangul-sori-site-local/public/hanok/construction/{web_relative}','sha256':digest,'bytes':len(blob)})
        series.append({'buildingId':bid,'name':tr(building['name'],building['en'],building['de']),'canonicalAsset':stages[-1]['asset'],'canonicalSha256':stages[-1]['sha256'],'width':1536,'height':1024,'culture':CULTURE[bid],'stages':stages})
    approval = {'approvedBy':'Jin','approvedOn':'2026-09-14','approval':APPROVAL,'buildingIds':list(IDS),'stageCount':49,'postprocessing':'Original approved RGB PNG bytes; no resizing, recoloring or regenerated replacements.','geometryReview':'Visual adoption does not certify calibrated 29-degree camera geometry or pixel-identical joints across generated stages.'}
    runtime_path = ROOT/'assets/data/ildu_construction_art_v1.json'
    catalog = json.loads(runtime_path.read_text(encoding='utf-8'))
    catalog['series'] = [s for s in catalog['series'] if s['buildingId'] not in IDS] + series
    catalog['additionalApprovals'] = [approval]
    write_json(runtime_path, catalog)
    write_json(DOC/'construction_catalog.json', {'schemaVersion':1,'status':'approved_canonical',**approval,'runtimeRoute':'/hanok/construction','series':series})
    write_json(DOC/'promotion_manifest.json', {'schemaVersion':1,**approval,'files':receipt})
    write_json(PUBLIC/'construction_catalog.json', public_catalog)
    lock_path = ROOT/'docs/assets/STYLE_LOCK.json'
    lock = json.loads(lock_path.read_text(encoding='utf-8'))
    registrations = lock['families']['F-D-ildoo']['approvedConstructionSeries']
    for entry in series:
        bid=entry['buildingId']
        registrations[bid] = {'status':'approved_canonical','approvedBy':'Jin','approvedOn':'2026-09-14','catalog':'assets/data/ildu_construction_art_v1.json','canonicalAsset':entry['canonicalAsset'],'canonicalSha256':entry['canonicalSha256'],'stageCount':len(entry['stages']),'assetDirectory':f'{RUNTIME}/{bid}/','presentation':'정면 29도 부감 목표의 2.5D 누적 공정. 승인 RGB PNG 바이트 그대로 사용. 생성 단계 사이의 미세한 부재 차이는 유지한다.','scope':'앱 /hanok/construction 및 공개 공정 보기. 완성 8면도와 지도 배치는 그대로 유지한다.'}
    write_json(lock_path,lock)
    html=(VIEWER/'index.html').read_text(encoding='utf-8')
    html=html.replace('href="./"', 'href="/"').replace('네 채의 공정 원화 · 제작 검토본','네 채의 한옥 짓기')
    html=html[:html.index('<div class="package-links">')]+ '<footer>사람이 머물고 일하던 한옥의 구조를 한국어와 함께 살펴보세요.</footer>\n'+html[html.index('</main>'):]
    (PUBLIC/'index.html').write_text(html,encoding='utf-8')
    js=(VIEWER/'app.js').read_text(encoding='utf-8').replace("const BASE='../../../assets_unused/pending_review/personal_hanok_v3/four_buildings_construction_29deg_v1/';","const BASE='./';")
    js=js.replace("$('note').textContent=notes[s.id]||'';", "$('note').textContent=s.observe?.[lang]||notes[s.id]||'';")
    (PUBLIC/'app.js').write_text(js,encoding='utf-8')
    shutil.copyfile(VIEWER/'styles.css',PUBLIC/'styles.css')
    print(json.dumps({'approvedStages':len(receipt),'bytes':sum(r['bytes'] for r in receipt),'series':{s['buildingId']:len(s['stages']) for s in catalog['series']}},ensure_ascii=False))

if __name__ == '__main__':
    main()
