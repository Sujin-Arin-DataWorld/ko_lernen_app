"""Verify relocated archive inputs without needing a Blender installation."""
from pathlib import Path
import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch


class RelocatedRoofRendererTest(unittest.TestCase):
    def test_relocated_package_wins_over_historical_receipt_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'restored'
            old = Path(directory) / 'old-package'
            native = root / 'roof-variants/native/sarang'
            native.mkdir(parents=True)
            old.mkdir()
            scene = MagicMock()
            scene.objects = {'patch': type('Object', (), {'hide_render': False})()}
            blender = MagicMock()
            blender.context.scene = scene

            def write_json(path, value):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(json.dumps(value), encoding='utf-8')

            for kind in ['full', 'stage']:
                # Both old and relocated bytes are valid. Loading the old path
                # would silently read the wrong package unless explicitly checked.
                data = kind.encode()
                (native / (kind + '.blend')).write_bytes(data)
                (old / (kind + '.blend')).write_bytes(data)
                write_json(root / 'roof-variants' / ('sarang-' + kind + '-verified.json'), {
                    'complete': True, 'native': str(old / (kind + '.blend')),
                    'sha256': hashlib.sha256(data).hexdigest(),
                    'patches': [{'object': 'patch', 'requiredStage': 1}]})
            write_json(root / 'family-r16/sarang/stage-selection.json', {
                'steps': [{'sequence': 1, 'processId': 'same-original-id', 'label': '기와'}]})
            write_json(root / 'roof-variants/input/ROOF_SOURCE_MAP.json', {
                'owners': [{'key': 'sarang', 'patches': [{'requiredStage': 1}], 'replacements': []}]})

            def open_native(*, filepath, load_ui):
                self.assertEqual(Path(filepath).parent, native)

            def render(*, write_still):
                Path(scene.render.filepath).write_bytes(b'render test fixture')

            blender.ops.wm.open_mainfile.side_effect = open_native
            blender.ops.render.render.side_effect = render
            source = Path(__file__).with_name('render_ildu_roof_variants.py')
            spec = importlib.util.spec_from_file_location('roof_renderer_under_test', source)
            module = importlib.util.module_from_spec(spec)
            with patch.dict(sys.modules, {'bpy': blender}):
                spec.loader.exec_module(module)
                with patch.object(sys, 'argv', ['blender', '--', '--package-root', str(root), '--key', 'sarang']):
                    module.main()
            self.assertEqual(blender.ops.wm.open_mainfile.call_count, 2)
            result = json.loads((root / 'roof-variants/sarang-renders.json').read_text(encoding='utf-8'))
            self.assertEqual(result['stages'][0]['processId'], 'same-original-id')


if __name__ == '__main__':
    unittest.main()
