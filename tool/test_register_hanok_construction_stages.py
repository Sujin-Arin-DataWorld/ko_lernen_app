import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from tool.register_hanok_construction_stages import alpha_bbox, register


class RegisterHanokConstructionStagesTest(unittest.TestCase):
    def test_places_stage_on_exact_canvas_center_and_ground(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "stage.png"
            output = root / "registered.png"
            image = Image.new("RGBA", (100, 80), (0, 0, 0, 0))
            ImageDraw.Draw(image).rectangle((20, 25, 79, 69), fill=(90, 50, 20, 255))
            image.save(source)

            report = register(
                source,
                output,
                canvas_size=(240, 160),
                scale_x=2.0,
                scale_y=2.0,
                target_center_x=120.0,
                target_ground_y=145,
            )

            with Image.open(output) as registered:
                bbox = alpha_bbox(registered)
                self.assertEqual(registered.size, (240, 160))
            self.assertEqual(bbox[3], 145)
            self.assertLessEqual(abs((bbox[0] + bbox[2]) / 2.0 - 120.0), 0.5)
            self.assertEqual(bbox[2] - bbox[0], 120)
            self.assertEqual(bbox[3] - bbox[1], 90)
            self.assertEqual(report["outputAlphaBbox"], list(bbox))


if __name__ == "__main__":
    unittest.main()
