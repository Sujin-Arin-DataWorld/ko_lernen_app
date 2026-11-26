import hashlib
from PIL import Image
from tool.ildu_retirement_audit import ROOT, native_frames, receipt

def check_frames(test, key):
    paths = native_frames(key)
    test.assertEqual(len(paths), 8)
    hashes = set()
    records = receipt()['runtimeFiles']
    for path in paths:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        test.assertEqual(digest, records[path.relative_to(ROOT).as_posix()]['sha256'])
        hashes.add(digest)
        with Image.open(path) as image:
            test.assertEqual(image.mode, 'RGBA')
            test.assertEqual(image.size, (768, 512))
            alpha = image.getchannel('A')
            test.assertEqual(alpha.getextrema(), (0, 255))
            left, top, right, bottom = alpha.getbbox()
            test.assertGreater(left, 0)
            test.assertGreater(top, 0)
            test.assertLess(right, image.width)
            test.assertLess(bottom, image.height)
    test.assertEqual(len(hashes), 8)
