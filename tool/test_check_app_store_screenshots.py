import struct
import tempfile
import unittest
import zlib
from pathlib import Path
from unittest.mock import patch
from check_app_store_screenshots import validate_directory


PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def _chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack('>I', len(payload))
        + kind
        + payload
        + struct.pack('>I', zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def write_chunked_png(path: Path, chunks: list[bytes]) -> None:
    path.write_bytes(PNG_SIGNATURE + b''.join(chunks))


def ihdr_chunk(*, color_type: int = 2, bit_depth: int = 8) -> bytes:
    return _chunk(
        b'IHDR',
        struct.pack('>IIBBBBB', 2752, 2064, bit_depth, color_type, 0, 0, 0),
    )


def write_png(
    path: Path,
    width: int,
    height: int,
    *,
    color_type: int = 2,
    bit_depth: int = 8,
    with_trns: bool = False,
    include_idat: bool = True,
) -> None:
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color_type, 3)
    ihdr = struct.pack('>IIBBBBB', width, height, bit_depth, color_type, 0, 0, 0)
    raw = b''.join(b'\x00' + (b'\x00' * width * channels) for _ in range(height))
    chunks = [_chunk(b'IHDR', ihdr)]
    if with_trns:
        chunks.append(_chunk(b'tRNS', b'\x00\x00\x00\x00\x00\x00'))
    if include_idat:
        chunks.append(_chunk(b'IDAT', zlib.compress(raw)))
    chunks.append(_chunk(b'IEND', b''))
    path.write_bytes(PNG_SIGNATURE + b''.join(chunks))


class AppStoreScreenshotValidatorTest(unittest.TestCase):
    def test_accepts_opaque_13_inch_ipad_landscape_png(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'hanok-map.png', 2752, 2064)

            self.assertEqual(validate_directory(directory, 'ipad-13'), [])

    def test_rejects_alpha_color_type(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'transparent.png', 2752, 2064, color_type=6)

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('transparent.png' in message for message in messages))
        self.assertTrue(any('alpha' in message.lower() for message in messages))

    def test_rejects_trns_transparency(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'indexed-transparency.png', 2752, 2064, with_trns=True)

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('tRNS' in message for message in messages))

    def test_rejects_wrong_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'wrong-size.png', 100, 100)

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('wrong-size.png' in message for message in messages))
        self.assertTrue(any('dimensions' in message.lower() for message in messages))

    def test_rejects_zero_or_eleven_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            self.assertTrue(
                any('at least 1' in message.lower() for message in validate_directory(directory, 'ipad-13')),
            )

            for index in range(11):
                write_png(directory / f'{index}.png', 2752, 2064)
            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('at most 10' in message.lower() for message in messages))

    def test_reports_unknown_target_and_malformed_png_without_throwing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            (directory / 'broken.png').write_bytes(b'not a PNG')

            messages = validate_directory(directory, 'unknown-target')

        self.assertTrue(any('unknown target' in message.lower() for message in messages))
        self.assertTrue(any('broken.png' in message for message in messages))

    def test_reports_missing_folder_and_mixed_path_entries_without_throwing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            missing_messages = validate_directory(directory / 'missing', 'ipad-13')

            write_png(directory / 'valid.png', 2752, 2064)
            (directory / 'notes.txt').write_text('not a screenshot', encoding='utf-8')
            (directory / 'nested').mkdir()
            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('does not exist' in message.lower() for message in missing_messages))
        self.assertTrue(any('notes.txt' in message for message in messages))
        self.assertTrue(any('nested' in message for message in messages))

    def test_rejects_png_with_corrupted_chunk_crc(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            png_path = directory / 'corrupt-crc.png'
            write_png(png_path, 2752, 2064)
            png_data = bytearray(png_path.read_bytes())
            png_data[-1] ^= 0xFF
            png_path.write_bytes(png_data)

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('corrupt-crc.png' in message for message in messages))
        self.assertTrue(any('crc' in message.lower() for message in messages))

    def test_rejects_invalid_ihdr_length_before_reading_its_payload(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            (directory / 'oversized-ihdr.png').write_bytes(
                PNG_SIGNATURE + struct.pack('>I', 14) + b'IHDR',
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('oversized-ihdr.png' in message for message in messages))
        self.assertTrue(any('invalid ihdr chunk length' in message.lower() for message in messages))

    def test_rejects_png_with_undecodable_idat_stream(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_chunked_png(
                directory / 'invalid-idat.png',
                [
                    ihdr_chunk(),
                    _chunk(b'IDAT', b'not-a-zlib-stream'),
                    _chunk(b'IEND', b''),
                ],
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('invalid-idat.png' in message for message in messages))
        self.assertTrue(any('idat' in message.lower() for message in messages))

    def test_rejects_png_without_image_data(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'missing-idat.png', 2752, 2064, include_idat=False)

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('missing-idat.png' in message for message in messages))
        self.assertTrue(any('idat' in message.lower() for message in messages))

    def test_rejects_illegal_ihdr_bit_depth_for_truecolor(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'invalid-ihdr.png', 2752, 2064, bit_depth=1)

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('invalid-ihdr.png' in message for message in messages))
        self.assertTrue(any('bit depth' in message.lower() for message in messages))

    def test_reports_entry_metadata_failure_without_throwing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_png(directory / 'unreadable.png', 2752, 2064)
            original_is_dir = Path.is_dir

            def fail_one_entry(path: Path) -> bool:
                if path.name == 'unreadable.png':
                    raise OSError('metadata denied')
                return original_is_dir(path)

            with patch.object(Path, 'is_dir', autospec=True, side_effect=fail_one_entry):
                messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('unreadable.png' in message for message in messages))
        self.assertTrue(any('metadata' in message.lower() for message in messages))

    def test_rejects_non_contiguous_idat_chunks(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_chunked_png(
                directory / 'split-idat.png',
                [
                    ihdr_chunk(),
                    _chunk(b'IDAT', zlib.compress(b'')[:2]),
                    _chunk(b'tEXt', b'label\x00break'),
                    _chunk(b'IDAT', b'second'),
                    _chunk(b'IEND', b''),
                ],
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('split-idat.png' in message for message in messages))
        self.assertTrue(any('contiguous' in message.lower() for message in messages))

    def test_rejects_plte_for_grayscale_png(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_chunked_png(
                directory / 'grayscale-plte.png',
                [
                    ihdr_chunk(color_type=0),
                    _chunk(b'PLTE', b'\x00\x00\x00'),
                    _chunk(b'IDAT', b'image'),
                    _chunk(b'IEND', b''),
                ],
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('grayscale-plte.png' in message for message in messages))
        self.assertTrue(any('plte' in message.lower() for message in messages))

    def test_rejects_reserved_chunk_name_bit(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_chunked_png(
                directory / 'reserved-bit.png',
                [
                    ihdr_chunk(),
                    _chunk(b'tEbT', b'not permitted'),
                    _chunk(b'IDAT', b'image'),
                    _chunk(b'IEND', b''),
                ],
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('reserved-bit.png' in message for message in messages))
        self.assertTrue(any('reserved' in message.lower() for message in messages))

    def test_rejects_indexed_palette_order_and_entry_boundaries(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_chunked_png(
                directory / 'indexed-order.png',
                [
                    ihdr_chunk(color_type=3, bit_depth=1),
                    _chunk(b'tRNS', b'\x00'),
                    _chunk(b'PLTE', b'\x00\x00\x00'),
                    _chunk(b'IDAT', b'image'),
                    _chunk(b'IEND', b''),
                ],
            )
            write_chunked_png(
                directory / 'indexed-palette-bound.png',
                [
                    ihdr_chunk(color_type=3, bit_depth=1),
                    _chunk(b'PLTE', b'\x00\x00\x00' * 3),
                    _chunk(b'IDAT', b'image'),
                    _chunk(b'IEND', b''),
                ],
            )
            write_chunked_png(
                directory / 'indexed-trns-bound.png',
                [
                    ihdr_chunk(color_type=3, bit_depth=1),
                    _chunk(b'PLTE', b'\x00\x00\x00'),
                    _chunk(b'tRNS', b'\x00\x00'),
                    _chunk(b'IDAT', b'image'),
                    _chunk(b'IEND', b''),
                ],
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('indexed-order.png' in message for message in messages))
        self.assertTrue(any('indexed-palette-bound.png' in message for message in messages))
        self.assertTrue(any('indexed-trns-bound.png' in message for message in messages))

    def test_rejects_truecolor_plte_after_trns(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)
            write_chunked_png(
                directory / 'truecolor-order.png',
                [
                    ihdr_chunk(color_type=2),
                    _chunk(b'tRNS', b'\x00\x00\x00\x00\x00\x00'),
                    _chunk(b'PLTE', b'\x00\x00\x00'),
                    _chunk(b'IDAT', b'image'),
                    _chunk(b'IEND', b''),
                ],
            )

            messages = validate_directory(directory, 'ipad-13')

        self.assertTrue(any('truecolor-order.png' in message for message in messages))
        self.assertTrue(any('plte' in message.lower() for message in messages))


if __name__ == '__main__':
    unittest.main()
