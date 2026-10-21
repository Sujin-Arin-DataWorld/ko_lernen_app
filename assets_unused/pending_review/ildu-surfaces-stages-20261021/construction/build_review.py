"""Add drawing-grounded display copy and make the independent stage review."""
import hashlib
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent
DESCRIPTIONS = {
    'left': [
        '계단 없이 낮은 흙바닥을 다지고, 양쪽 신방석과 가장자리 돌을 놓아요. 2007년 081·083 도면을 따라 낮은 바닥을 유지했어요.',
        '신방목 위에 기둥 두 개를 세워요. 팔각 버팀대와 X자 보강재, 보와 도리가 지붕을 받을 골조를 만들어요.',
        '둥근 서까래 열 개와 경사진 개판을 올려요. 양쪽 지붕 끝을 받치는 목재와 판재도 함께 이어져요.',
        '개판 위에 흙 바탕을 채우고, 박공 판재와 처마의 평고대·연함을 갖춰 기와가 놓일 면을 만들어요.',
        '암키와와 수키와를 겹쳐 올려요. 양쪽 박공과 용마루까지 이어지는 기와가 지붕을 완성해요.',
        '여덟 장의 판재로 만든 문과 뒤쪽 띠장·둔테·빗장, 철물까지 갖춰요. 도면을 바탕으로 다시 만든 왼쪽 협문의 전체 모습이에요.'],
    'right': [
        '다섯 단의 돌계단을 차례로 놓아요. 단 높이는 아래부터 200·150·150·130·120mm이며, 위쪽 바닥과 양쪽 신방석이 골조를 받아요.',
        '양쪽 신방목과 기둥, 앞뒤 버팀목을 세워요. 보·도리와 측면 판재가 좁은 통로 위의 지붕을 받쳐요.',
        '각진 서까래 일곱 개와 개판을 올려요. 측면으로 이어지는 지붕 판재와 받침도 함께 연결돼요.',
        '개판 위에 흙 바탕과 기와 밑바탕을 놓아요. 박공 판재·평고대·연함이 기와를 받칠 가장자리를 만들어요.',
        '암키와·수키와를 올리고 용마루와 박공 기와를 이어가요. 처마 기와 끝의 회 마감도 원본 부재 그대로 보여요.',
        '네 장의 판재로 된 문과 뒤쪽 띠장·둔테·빗장을 달아요. 고리와 철물을 갖춘 안채 연결 협문의 전체 모습이에요.'],
    'shrine': [
        '문 양쪽에 길게 놓인 신방석 두 개와 가운데 문턱돌을 놓아요. 사당문 도면 086·087의 낮은 기초 구성이에요.',
        '둥근 기둥 두 개와 앞뒤 버팀목 네 개를 세워요. 낮은 기초 위에서 지붕 골조가 시작돼요.',
        '도리·창방·보를 연결하고 문설주와 문턱 목재를 갖춰요. 두 기둥 사이의 골조가 이어져요.',
        '각진 서까래 일곱 개를 나란히 올려요. 이 단계에서는 개판과 지붕 흙을 덮기 전의 구조를 볼 수 있어요.',
        '30mm 개판과 박공 안쪽 판재를 놓고 지붕의 흙 바탕을 채워요. 양쪽 날개 판재와 처마 가장자리도 연결돼요.',
        '암키와·수키와와 양쪽 박공 기와를 이어 올려요. 용마루와 회 마감까지 갖춘 지붕이에요.',
        '여덟 장의 문판과 띠장·빗장·둔테를 달고 고리와 철물을 더해요. 아직 태극 문양이 올라가기 전 모습이에요.',
        '원본 문판 위의 붉은색과 푸른색 태극 문양을 더해요. 사당문 전체 부재가 모두 보이는 완성 모습이에요.']}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest_path = OUT / 'manifest.json'
    data = json.loads(manifest_path.read_text(encoding='utf-8'))
    for gate in data['gates']:
        for step, description in zip(gate['steps'], DESCRIPTIONS[gate['gate']], strict=True):
            step['displayDescription'] = description
            step['displayDescriptionSource'] = 'R6c native member names and 2007 drawing assembly configuration'
            step['legacyLessonCopyShownToReviewerOnly'] = True
    manifest_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    titles = {'left': '사랑채 왼쪽 협문', 'right': '안채 연결 협문', 'shrine': '사당문'}
    slim = [{'gate': g['gate'], 'gateKey': g['gateKey'], 'name': titles[g['gate']], 'objectCount': g['objectCount'],
             'validation': g['validation'], 'steps': [{k: s[k] for k in
                ['sequence', 'label', 'displayDescription', 'image', 'deltaCount', 'memberCount', 'processId', 'unitCount']}
                for s in g['steps']]} for g in data['gates']]
    template = (OUT / 'review-template.html').read_text(encoding='utf-8')
    (OUT / 'index.html').write_text(template.replace('__DATA__', json.dumps(slim, ensure_ascii=False).replace('</', '<\\/')), encoding='utf-8')
    from PIL import Image
    validations = []
    bindings_match = all(sha(Path(p) if Path(p).is_absolute() else OUT / p) == expected
                         for p, expected in data['bindings'].items())
    for gate in data['gates']:
        records = gate['steps']
        native = OUT.parent / (gate['gate'] + '-new.blend')
        original = OUT.parent / (gate['gate'] + '-hero.png')
        final = OUT / records[-1]['image']
        images = []
        for step in records:
            path = OUT / step['image']
            exists = path.exists()
            size = list(Image.open(path).size) if exists else None
            images.append({'image': step['image'], 'exists': exists,
                           'hashMatches': sha(path) == step.get('imageSha256') if exists else False,
                           'resolution': size, 'resolutionMatches': size == step.get('resolution')})
        assignment_file = json.loads((OUT / (gate['gate'] + '-object-stage-map.json')).read_text(encoding='utf-8'))
        expected_objects = set(assignment_file['sourceState']['objects'])
        seen_delta = set()
        cumulative = set()
        partition_pass = True
        for step in records:
            delta = set(step['deltaObjects'])
            partition_pass &= not bool(delta & seen_delta)
            seen_delta |= delta
            cumulative |= delta
            partition_pass &= cumulative == set(step['sourceObjects'])
        partition_pass &= cumulative == expected_objects
        checks = {'gate': gate['gate'], 'imageCount': len(images), 'images': images,
                  'nativeShaMatches': sha(native) == gate['sourceNativeSha256'],
                  'finalImageByteIdenticalToHero': final.exists() and sha(final) == sha(original),
                  'sourceValidationPassed': gate['validation']['passed'],
                  'sourceContractBindingsMatch': bindings_match,
                  'independentPartitionAndCumulativeCheck': partition_pass}
        checks['passed'] = all(i['exists'] and i['hashMatches'] and i['resolutionMatches'] for i in images) and all(
            checks[k] for k in ['nativeShaMatches', 'finalImageByteIdenticalToHero', 'sourceValidationPassed',
                               'sourceContractBindingsMatch', 'independentPartitionAndCumulativeCheck'])
        validations.append(checks)
    verification = {'passed': all(g['passed'] for g in validations), 'renderCount': sum(g['imageCount'] for g in validations),
                    'gates': validations, 'appIntegrated': False, 'userApproved': False}
    (OUT / 'verification.json').write_text(json.dumps(verification, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'passed': verification['passed'], 'renderCount': verification['renderCount']}, ensure_ascii=False))
    if verification['passed']:
        from PIL import Image, ImageDraw, ImageFont
        font = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 20)
        for gate in data['gates']:
            count = len(gate['steps'])
            sheet = Image.new('RGB', (1200, ((count + 2) // 3) * 450), '#f3e8d8')
            draw = ImageDraw.Draw(sheet)
            for i, step in enumerate(gate['steps']):
                image = Image.open(OUT / step['image']).convert('RGB')
                image.thumbnail((390, 390))
                x, y = (i % 3) * 400, (i // 3) * 450
                sheet.paste(image, (x + (400 - image.width) // 2, y))
                draw.text((x + 12, y + 395), f"{step['sequence']}. {step['label']}", fill='#3a2a21', font=font)
                draw.text((x + 12, y + 422), f"누적 {step['memberCount']} / 추가 {step['deltaCount']}", fill='#3a2a21', font=font)
            sheet.save(OUT / (gate['gate'] + '-contact-sheet.jpg'), quality=92)


if __name__ == '__main__':
    main()
