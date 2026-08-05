#!/usr/bin/env python3
"""Validate App Store screenshot folders without image-library dependencies."""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
TARGET_DIMENSIONS = {
    'ipad-13': {
        (2064, 2752),
        (2752, 2064),
        (2048, 2732),
        (2732, 2048),
    },
    'iphone-6.9': {
        (1260, 2736),
        (2736, 1260),
        (1290, 2796),
        (2796, 1290),
        (1320, 2868),
        (2868, 1320),
    },
}
LEGAL_BIT_DEPTHS = {
    0: {1, 2, 4, 8, 16},
    2: {8, 16},
    3: {1, 2, 4, 8},
    4: {8, 16},
    6: {8, 16},
}
KNOWN_CRITICAL_CHUNKS = {b'IHDR', b'PLTE', b'IDAT', b'IEND'}
READ_BLOCK_SIZE = 64 * 1024
MAX_DECOMPRESSED_IMAGE_BYTES = 64 * 1024 * 1024
CHANNELS_BY_COLOR_TYPE = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}
ADAM7_PASSES = (
    (0, 0, 8, 8),
    (4, 0, 8, 8),
    (0, 4, 4, 8),
    (2, 0, 4, 4),
    (0, 2, 2, 4),
    (1, 0, 2, 2),
    (0, 1, 1, 2),
)


def _read_exact(stream, size: int, description: str) -> bytes:
    value = stream.read(size)
    if len(value) != size:
        raise ValueError(f'truncated {description}')
    return value


def _read_chunk_payload(
    stream,
    length: int,
    chunk_type: bytes,
    *,
    capture: bool,
    consume=None,
) -> bytes:
    """CRC-check one chunk while keeping at most one read block in memory."""
    crc = zlib.crc32(chunk_type)
    remaining = length
    captured = bytearray() if capture else None
    while remaining:
        block = _read_exact(stream, min(remaining, READ_BLOCK_SIZE), 'PNG chunk payload')
        crc = zlib.crc32(block, crc)
        if captured is not None:
            captured.extend(block)
        if consume is not None:
            consume(block)
        remaining -= len(block)

    expected_crc = struct.unpack('>I', _read_exact(stream, 4, 'PNG chunk CRC'))[0]
    if (crc & 0xFFFFFFFF) != expected_crc:
        raise ValueError(f'CRC mismatch in {chunk_type.decode("ascii", "replace")} chunk')
    return bytes(captured) if captured is not None else b''


def _expected_image_data_length(
    width: int,
    height: int,
    *,
    bit_depth: int,
    color_type: int,
    interlace: int,
) -> int:
    bits_per_pixel = CHANNELS_BY_COLOR_TYPE[color_type] * bit_depth

    def scanline_length(pixel_width: int) -> int:
        return 1 + ((pixel_width * bits_per_pixel + 7) // 8)

    if interlace == 0:
        return height * scanline_length(width)

    total = 0
    for x_start, y_start, x_step, y_step in ADAM7_PASSES:
        pass_width = 0 if width <= x_start else (width - x_start + x_step - 1) // x_step
        pass_height = 0 if height <= y_start else (height - y_start + y_step - 1) // y_step
        total += pass_height * scanline_length(pass_width)
    return total


def _read_png_metadata(path: Path) -> tuple[int, int, int, bool]:
    """Return width, height, color type, and whether a tRNS chunk is present."""
    with path.open('rb') as stream:
        if _read_exact(stream, len(PNG_SIGNATURE), 'PNG signature') != PNG_SIGNATURE:
            raise ValueError('invalid PNG signature')

        width = height = color_type = None
        seen_idat = False
        idat_ended = False
        seen_plte = False
        palette_entries = 0
        has_trns = False
        chunk_index = 0
        bit_depth = interlace = None
        expected_image_data_length = None
        idat_decoder = None
        decoded_idat_bytes = 0

        def consume_idat(data: bytes) -> None:
            nonlocal decoded_idat_bytes
            if idat_decoder is None or expected_image_data_length is None:
                raise ValueError('IDAT appears before a valid IHDR chunk')
            if idat_decoder.eof:
                raise ValueError('IDAT contains bytes after the zlib stream')

            remaining_output = expected_image_data_length - decoded_idat_bytes
            try:
                output = idat_decoder.decompress(data, remaining_output + 1)
            except zlib.error as error:
                raise ValueError('IDAT zlib stream cannot be decoded') from error
            decoded_idat_bytes += len(output)
            if decoded_idat_bytes > expected_image_data_length:
                raise ValueError('IDAT decompressed image data exceeds its IHDR size')
            if idat_decoder.unconsumed_tail:
                raise ValueError('IDAT decompressed image data exceeds its IHDR size')
            if idat_decoder.unused_data:
                raise ValueError('IDAT zlib stream contains trailing bytes')

        while True:
            header = _read_exact(stream, 8, 'PNG chunk header')
            length = struct.unpack('>I', header[:4])[0]
            chunk_type = header[4:]
            if not all(65 <= value <= 90 or 97 <= value <= 122 for value in chunk_type):
                raise ValueError('invalid PNG chunk type')
            if chunk_type[2] & 0x20:
                raise ValueError('PNG chunk reserved bit must be zero')

            if chunk_index == 0 and chunk_type != b'IHDR':
                raise ValueError('IHDR must be the first PNG chunk')
            if chunk_index == 0 and length != 13:
                raise ValueError('invalid IHDR chunk length')
            if chunk_type == b'IHDR' and chunk_index != 0:
                raise ValueError('duplicate IHDR chunk')
            if chunk_type == b'IDAT' and idat_ended:
                raise ValueError('IDAT chunks must be contiguous')

            payload = _read_chunk_payload(
                stream,
                length,
                chunk_type,
                capture=chunk_type == b'IHDR',
                consume=consume_idat if chunk_type == b'IDAT' else None,
            )
            chunk_index += 1

            if chunk_type[0] & 0x20 == 0 and chunk_type not in KNOWN_CRITICAL_CHUNKS:
                name = chunk_type.decode('ascii')
                raise ValueError(f'unknown critical PNG chunk {name}')

            if seen_idat and chunk_type != b'IDAT':
                idat_ended = True

            if chunk_type == b'IHDR':
                width, height, bit_depth, color_type, compression, filter_method, interlace = (
                    struct.unpack('>IIBBBBB', payload)
                )
                if width == 0 or height == 0:
                    raise ValueError('IHDR width and height must be positive')
                if bit_depth not in LEGAL_BIT_DEPTHS.get(color_type, set()):
                    raise ValueError('illegal IHDR color type or bit depth')
                if compression != 0 or filter_method != 0 or interlace not in (0, 1):
                    raise ValueError('unsupported IHDR encoding')
                expected_image_data_length = _expected_image_data_length(
                    width,
                    height,
                    bit_depth=bit_depth,
                    color_type=color_type,
                    interlace=interlace,
                )
                if expected_image_data_length > MAX_DECOMPRESSED_IMAGE_BYTES:
                    raise ValueError('IHDR image data exceeds the validator size limit')
                idat_decoder = zlib.decompressobj()
            elif chunk_type == b'PLTE':
                if seen_plte or seen_idat:
                    raise ValueError('PLTE must appear once before IDAT')
                if has_trns:
                    raise ValueError('PLTE must appear before tRNS')
                if length == 0 or length > 768 or length % 3:
                    raise ValueError('invalid PLTE chunk length')
                if color_type in (0, 4):
                    raise ValueError('PLTE is not legal for grayscale PNGs')
                palette_entries = length // 3
                if color_type == 3 and palette_entries > 2**bit_depth:
                    raise ValueError('indexed PLTE exceeds the bit-depth palette entry limit')
                seen_plte = True
            elif chunk_type == b'IDAT':
                if color_type == 3 and not seen_plte:
                    raise ValueError('palette PNG is missing PLTE before IDAT')
                seen_idat = True
            elif chunk_type == b'tRNS':
                if has_trns or seen_idat:
                    raise ValueError('tRNS must appear once before IDAT')
                if color_type not in (0, 2, 3):
                    raise ValueError('tRNS is not legal for this PNG color type')
                if color_type == 0 and length != 2:
                    raise ValueError('grayscale tRNS chunk must contain 2 bytes')
                if color_type == 2 and length != 6:
                    raise ValueError('truecolor tRNS chunk must contain 6 bytes')
                if color_type == 3:
                    if not seen_plte:
                        raise ValueError('indexed tRNS must appear after PLTE')
                    if length == 0 or length > palette_entries:
                        raise ValueError('indexed tRNS length exceeds the PLTE entry count')
                has_trns = True
            elif chunk_type == b'IEND':
                if length != 0:
                    raise ValueError('IEND chunk must have zero length')
                if not seen_idat:
                    raise ValueError('PNG is missing IDAT image data')
                if idat_decoder is None or expected_image_data_length is None:
                    raise ValueError('PNG IDAT data is missing a valid IHDR chunk')
                try:
                    remaining_output = expected_image_data_length - decoded_idat_bytes
                    final_output = idat_decoder.flush(remaining_output + 1)
                except zlib.error as error:
                    raise ValueError('IDAT zlib stream cannot be decoded') from error
                decoded_idat_bytes += len(final_output)
                if decoded_idat_bytes > expected_image_data_length:
                    raise ValueError('IDAT decompressed image data exceeds its IHDR size')
                if not idat_decoder.eof:
                    raise ValueError('IDAT zlib stream did not terminate')
                if idat_decoder.unused_data:
                    raise ValueError('IDAT zlib stream contains trailing bytes')
                if decoded_idat_bytes != expected_image_data_length:
                    raise ValueError('IDAT decompressed image data does not match its IHDR size')
                if stream.read(1):
                    raise ValueError('bytes found after IEND chunk')
                return width, height, color_type, has_trns


def validate_directory(path: Path, target: str) -> list[str]:
    """Return every App Store screenshot validation issue found in ``path``."""
    messages: list[str] = []
    accepted_dimensions = TARGET_DIMENSIONS.get(target)
    if accepted_dimensions is None:
        messages.append(f'Unknown target: {target}.')

    if not path.exists():
        return messages + [f'Screenshot folder does not exist: {path}.']
    if not path.is_dir():
        return messages + [f'Screenshot path is not a directory: {path}.']

    try:
        entries = sorted(path.iterdir(), key=lambda entry: entry.name.lower())
    except OSError as error:
        return messages + [f'Cannot read screenshot folder {path}: {error}.']

    png_files: list[Path] = []
    for entry in entries:
        try:
            if entry.is_dir():
                messages.append(f'Nested path entry is not allowed: {entry.name}.')
            elif not entry.is_file():
                messages.append(f'Unsupported screenshot path entry: {entry.name}.')
            elif entry.suffix.lower() != '.png':
                messages.append(f'Non-PNG screenshot file is not allowed: {entry.name}.')
            else:
                png_files.append(entry)
        except OSError as error:
            messages.append(f'{entry.name}: cannot inspect screenshot path metadata ({error}).')

    if not png_files:
        messages.append('Screenshot folder must contain at least 1 PNG file.')
    elif len(png_files) > 10:
        messages.append('Screenshot folder may contain at most 10 PNG files.')

    for png_path in png_files:
        try:
            width, height, color_type, has_trns = _read_png_metadata(png_path)
        except (OSError, ValueError) as error:
            messages.append(f'{png_path.name}: malformed or unreadable PNG ({error}).')
            continue

        if accepted_dimensions is not None and (width, height) not in accepted_dimensions:
            dimensions = ', '.join(f'{item[0]}x{item[1]}' for item in sorted(accepted_dimensions))
            messages.append(
                f'{png_path.name}: dimensions {width}x{height} are not accepted for '
                f'{target}; use one of {dimensions}.',
            )
        if color_type in (4, 6):
            messages.append(
                f'{png_path.name}: PNG color type {color_type} has an alpha channel; '
                'App Store screenshots must not contain alpha.',
            )
        if has_trns:
            messages.append(
                f'{png_path.name}: PNG contains a tRNS transparency chunk; '
                'App Store screenshots must not contain transparency.',
            )

    return messages


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description='Validate App Store screenshot PNGs.')
    parser.add_argument('--target', required=True, choices=sorted(TARGET_DIMENSIONS))
    parser.add_argument('folder', type=Path)
    arguments = parser.parse_args(argv)

    messages = validate_directory(arguments.folder, arguments.target)
    if messages:
        print(f'App Store screenshot validation failed for {arguments.folder}:')
        for message in messages:
            print(f'- {message}')
        return 1

    print(f'App Store screenshot validation passed for {arguments.folder}.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
