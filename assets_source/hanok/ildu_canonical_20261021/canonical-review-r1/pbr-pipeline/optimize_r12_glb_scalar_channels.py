"""Co-pack exact 8-bit RM RGB and specular A in a private GLB candidate.

Only scalar texture channels are repacked. Geometry, source identity, base color
and normal images remain exact. Unknown extension reference semantics, 16-bit
scalar PNGs and interlaced/palette scalar PNGs fail closed, never down-convert.
"""
from __future__ import annotations

import argparse
import copy
import io
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image

from optimize_r12_glb_textures import (
    PNG_SIGNATURE, OptimizationError, png_chunk, read_glb, read_png,
    require, sha, view_bytes, write_glb,
)
from validate_r12_glb import Glb


ALLOWED_EXTENSIONS = {'KHR_materials_specular', 'KHR_materials_ior', 'KHR_texture_transform'}


def extension_guard(value):
    if isinstance(value, dict):
        require(set(value.get('extensions', {})) <= ALLOWED_EXTENSIONS,
                'Unsupported extension reference semantics')
        for key, child in value.items():
            if key != 'extras':
                extension_guard(child)
    elif isinstance(value, list):
        for child in value:
            extension_guard(child)


def texture_refs(doc):
    """Yield actual supported material textureInfo records, never extras."""
    for mi, mat in enumerate(doc.get('materials', [])):
        pbr = mat.get('pbrMetallicRoughness', {})
        spec = mat.get('extensions', {}).get('KHR_materials_specular', {})
        for role, info in [('baseColor', pbr.get('baseColorTexture')),
                           ('roughnessMetallic', pbr.get('metallicRoughnessTexture')),
                           ('normal', mat.get('normalTexture')),
                           ('occlusion', mat.get('occlusionTexture')),
                           ('emissive', mat.get('emissiveTexture')),
                           ('specular', spec.get('specularTexture')),
                           ('specularColor', spec.get('specularColorTexture'))]:
            if info is not None:
                require(type(info.get('index')) is int and 0 <= info['index'] < len(doc.get('textures', [])),
                        'Invalid material texture reference')
                yield mi, role, info


def accessor_views(accessor):
    if 'bufferView' in accessor:
        yield accessor
    if 'sparse' in accessor:
        yield accessor['sparse']['indices']
        yield accessor['sparse']['values']


def decode_scalar_png(data, alpha_required=False):
    chunks, _, header = read_png(data)
    require(header['bitDepth'] == 8, 'Scalar PNG must be 8-bit; native 16-bit conversion is unsupported')
    require(header['colorType'] in (2, 6) and header['interlace'] == 0,
            'Only noninterlaced RGB/RGBA scalar PNGs are supported')
    require(not any(kind in (b'tRNS', b'sBIT') for kind, _, _ in chunks),
            'Scalar PNG tRNS/sBIT requires an explicit metadata conversion')
    require(not alpha_required or header['colorType'] == 6, 'Specular PNG requires explicit alpha')
    with Image.open(io.BytesIO(data)) as image:
        image.load()
        require(image.mode in ('RGB', 'RGBA'), 'Unexpected decoded scalar image mode')
        pixels = np.array(image.convert('RGBA'), dtype=np.uint8)
    return pixels, chunks, header


def pack_scalar_png(rm_data, spec_data):
    rm, chunks, header = decode_scalar_png(rm_data)
    spec, _, spec_header = decode_scalar_png(spec_data, alpha_required=True)
    require((header['width'], header['height']) == (spec_header['width'], spec_header['height']),
            'Scalar image dimensions differ')
    combined = rm.copy()
    combined[:, :, 3] = spec[:, :, 3]
    # PNG filters may change, but every decoded channel bit must stay exact.
    encoded = io.BytesIO()
    Image.fromarray(combined).save(encoded, format='PNG', compress_level=9, optimize=True)
    fresh_chunks, _, _ = read_png(encoded.getvalue())
    new_idat = b''.join(raw for kind, _, raw in fresh_chunks if kind == b'IDAT')
    result, inserted = bytearray(PNG_SIGNATURE), False
    for kind, body, raw in chunks:
        if kind == b'IHDR':
            width, height, depth, _, compression, filtering, interlace = struct.unpack('>IIBBBBB', body)
            result.extend(png_chunk(kind, struct.pack('>IIBBBBB', width, height, depth, 6,
                                                     compression, filtering, interlace)))
        elif kind == b'IDAT':
            if not inserted:
                result.extend(new_idat)
                inserted = True
        else:
            result.extend(raw)
    result = bytes(result)
    actual, after_chunks, _ = decode_scalar_png(result, alpha_required=True)
    require(np.array_equal(actual[:, :, :3], rm[:, :, :3]), 'Roughness/metallic RGB changed')
    require(np.array_equal(actual[:, :, 3], spec[:, :, 3]), 'Specular alpha changed')
    require([raw for kind, _, raw in chunks if kind not in (b'IHDR', b'IDAT')] ==
            [raw for kind, _, raw in after_chunks if kind not in (b'IHDR', b'IDAT')],
            'RM ancillary PNG metadata changed')
    return result, {'size': [header['width'], header['height']], 'bitDepth': 8,
                    'originalRmSha256': sha(rm_data), 'originalSpecularSha256': sha(spec_data),
                    'packedSha256': sha(result), 'rmRgbDecodedSha256': sha(rm[:, :, :3].tobytes()),
                    'specularAlphaDecodedSha256': sha(spec[:, :, 3].tobytes()),
                    'rmRgbDecodedBytesExact': True, 'specularAlphaDecodedBytesExact': True,
                    'rmAncillaryChunksPreserved': True, 'resized': False}


def optimize_glb(original):
    doc, payload = read_glb(original)
    require(not any('sparse' in accessor for accessor in doc.get('accessors', [])),
            'Sparse accessors are outside the R12 delivery contract')
    require(set(doc.get('extensionsUsed', []) + doc.get('extensionsRequired', [])) <= ALLOWED_EXTENSIONS,
            'Unsupported extension reference semantics')
    extension_guard(doc)
    refs = list(texture_refs(doc))
    images, textures, views = doc.get('images', []), doc.get('textures', []), doc.get('bufferViews', [])
    for texture in textures:
        require(type(texture.get('source')) is int and 0 <= texture['source'] < len(images), 'Invalid texture image source')
    for image in images:
        require('uri' not in image and image.get('mimeType') == 'image/png', 'Only embedded PNG images supported')
        view_bytes(doc, payload, image['bufferView'])
    require(len({image['bufferView'] for image in images}) == len(images), 'Image bufferView aliases unsupported')
    updated = copy.deepcopy(doc)
    replacements, pairs, removed_texture_candidates, removed_image_candidates = {}, [], set(), set()
    desired_alpha, image_reports = {}, {}
    for mi, mat in enumerate(doc.get('materials', [])):
        rm = mat.get('pbrMetallicRoughness', {}).get('metallicRoughnessTexture')
        spec = mat.get('extensions', {}).get('KHR_materials_specular', {}).get('specularTexture')
        if not rm or not spec:
            continue
        rt, st = textures[rm['index']], textures[spec['index']]
        require(rt.get('sampler') == st.get('sampler'), 'Scalar samplers differ')
        require(rm.get('texCoord', 0) == spec.get('texCoord', 0) and
                rm.get('extensions', {}) == spec.get('extensions', {}), 'Scalar texCoord/transform differs')
        ri, si = rt['source'], st['source']
        rm_data = view_bytes(doc, payload, images[ri]['bufferView'])
        spec_data = view_bytes(doc, payload, images[si]['bufferView'])
        spec_pixels, _, _ = decode_scalar_png(spec_data, alpha_required=True)
        alpha = spec_pixels[:, :, 3].tobytes()
        require(ri not in desired_alpha or desired_alpha[ri] == alpha,
                'Shared RM image has conflicting specular alpha')
        desired_alpha[ri] = alpha
        if ri not in image_reports:
            packed, proof = pack_scalar_png(rm_data, spec_data)
            if ri != si:
                replacements[images[ri]['bufferView']] = packed
            image_reports[ri] = {'roughnessMetallicImage': ri, 'specularImage': si, **proof}
        updated['materials'][mi]['extensions']['KHR_materials_specular']['specularTexture']['index'] = rm['index']
        pairs.append({'material': mi, 'rmTexture': rm['index'], 'oldSpecularTexture': spec['index'],
                      'rmImage': ri, 'oldSpecularImage': si})
        if rm['index'] != spec['index']:
            removed_texture_candidates.add(spec['index'])
            removed_image_candidates.add(si)
    require(pairs, 'No compatible scalar pairs found')
    for _, role, info in refs:
        image_id = textures[info['index']]['source']
        if image_id in desired_alpha:
            require(role in ('roughnessMetallic', 'occlusion', 'specular'),
                    'RM image also has non-scalar/color-space semantics')
            if role == 'specular':
                current, _, _ = decode_scalar_png(view_bytes(doc, payload, images[image_id]['bufferView']), True)
                require(current[:, :, 3].tobytes() == desired_alpha[image_id],
                        'Packing would change an existing shared specular alpha use')
    referenced_textures = {info['index'] for _, _, info in texture_refs(updated)}
    removed_textures = removed_texture_candidates - referenced_textures
    texture_map = {old: new for new, old in enumerate(i for i in range(len(textures)) if i not in removed_textures)}
    updated['textures'] = [texture for i, texture in enumerate(updated['textures']) if i not in removed_textures]
    for _, _, info in texture_refs_before_remap(updated, len(textures)):
        info['index'] = texture_map[info['index']]
    referenced_images = {texture['source'] for texture in updated['textures']}
    removed_images = removed_image_candidates - referenced_images
    image_map = {old: new for new, old in enumerate(i for i in range(len(images)) if i not in removed_images)}
    updated['images'] = [image for i, image in enumerate(updated['images']) if i not in removed_images]
    for texture in updated['textures']:
        texture['source'] = image_map[texture['source']]
    removed_views = {images[i]['bufferView'] for i in removed_images}
    changed_views = set(replacements) | removed_views
    for accessor in doc.get('accessors', []):
        for item in accessor_views(accessor):
            require(item['bufferView'] not in changed_views, 'Accessor aliases scalar image data')
    intervals = []
    for vi in changed_views:
        start, end = views[vi].get('byteOffset', 0), views[vi].get('byteOffset', 0) + views[vi]['byteLength']
        for other_vi, other in enumerate(views):
            if other_vi != vi:
                other_start = other.get('byteOffset', 0)
                require(other_start >= end or other_start + other['byteLength'] <= start, 'Scalar image overlaps another bufferView')
        intervals.append((start, end, vi))
    out, cursor, shifts = bytearray(), 0, []
    for start, end, vi in sorted(intervals):
        out.extend(payload[cursor:start])
        data = b'' if vi in removed_views else replacements[vi]
        updated['bufferViews'][vi]['byteOffset'] = len(out)
        updated['bufferViews'][vi]['byteLength'] = len(data)
        out.extend(data)
        out.extend(b'\0' * ((end - start - len(data)) % 4))
        shifts.append((end, len(out) - end))
        cursor = end
    out.extend(payload[cursor:])
    for vi, view in enumerate(views):
        if vi not in changed_views:
            start = view.get('byteOffset', 0)
            shift = next((amount for end, amount in reversed(shifts) if end <= start), 0)
            if shift or 'byteOffset' in view:
                updated['bufferViews'][vi]['byteOffset'] = start + shift
    view_map = {old: new for new, old in enumerate(i for i in range(len(views)) if i not in removed_views)}
    updated['bufferViews'] = [view for i, view in enumerate(updated['bufferViews']) if i not in removed_views]
    for image in updated['images']:
        image['bufferView'] = view_map[image['bufferView']]
    for accessor in updated.get('accessors', []):
        for item in accessor_views(accessor):
            item['bufferView'] = view_map[item['bufferView']]
    updated['buffers'][0]['byteLength'] = len(out)
    candidate = write_glb(updated, out) if changed_views or removed_textures else original
    checked, checked_payload = read_glb(candidate)
    require(checked == updated, 'Unexpected candidate metadata change')
    preserved = []
    for old_vi, new_vi in view_map.items():
        if old_vi in replacements:
            continue
        before = view_bytes(doc, payload, old_vi)
        require(before == view_bytes(checked, checked_payload, new_vi), 'Retained bufferView changed')
        preserved.append({'oldBufferView': old_vi, 'newBufferView': new_vi, 'bytes': len(before), 'sha256': sha(before)})
    before_glb, after_glb = Glb(original), Glb(candidate)
    for ai in range(len(doc.get('accessors', []))):
        before, after = before_glb.array(ai), after_glb.array(ai)
        require(before.dtype == after.dtype and before.shape == after.shape and before.tobytes() == after.tobytes(),
                'Decoded accessor bytes changed')
        restored_metadata = copy.deepcopy(checked['accessors'][ai])
        for old_item, new_item in zip(accessor_views(doc['accessors'][ai]), accessor_views(restored_metadata)):
            require(new_item['bufferView'] == view_map[old_item['bufferView']], 'Accessor view remap differs')
            new_item['bufferView'] = old_item['bufferView']
        require(restored_metadata == doc['accessors'][ai], 'Accessor metadata changed beyond view index remap')
    for ri, proof in image_reports.items():
        final = view_bytes(checked, checked_payload, checked['images'][image_map[ri]]['bufferView'])
        pixels, _, _ = decode_scalar_png(final, True)
        require(sha(pixels[:, :, :3].tobytes()) == proof['rmRgbDecodedSha256'] and
                sha(pixels[:, :, 3].tobytes()) == proof['specularAlphaDecodedSha256'], 'Final scalar channel proof failed')
        proof['packedSha256'] = sha(final)
        proof['imageBytesChanged'] = images[ri]['bufferView'] in replacements
    for key in ('meshes', 'nodes', 'scenes', 'scene', 'samplers', 'extras', 'extensionsUsed', 'extensionsRequired'):
        require(checked.get(key) == doc.get(key), 'Unrelated semantic metadata changed: ' + key)
    report = {'schemaVersion': 1, 'status': 'private_exact_scalar_channel_candidate',
              'sourceGlbSha256': sha(original), 'candidateGlbSha256': sha(candidate),
              'sourceGlbBytes': len(original), 'candidateGlbBytes': len(candidate), 'savedGlbBytes': len(original) - len(candidate),
              'pairs': pairs, 'channelProofs': list(image_reports.values()),
              'removedTextureIndices': sorted(removed_textures), 'removedImageIndices': sorted(removed_images),
              'removedBufferViewIndices': sorted(removed_views), 'bufferViewIndexMap': view_map,
              'imageIndexMap': image_map, 'textureIndexMap': texture_map,
              'removedTextureMetadata': [doc['textures'][i] for i in sorted(removed_textures)],
              'removedImageMetadata': [doc['images'][i] for i in sorted(removed_images)],
              'removedBufferViewMetadata': [views[i] for i in sorted(removed_views)],
              'preservedBufferViews': preserved, 'allDecodedAccessorBytesExact': True,
              'geometryAndSourceIdentityBufferBytesExact': True, 'unrelatedImageBytesExact': True,
              'sourceImageCount': len(images), 'candidateImageCount': len(checked['images']),
              'runtimePromoted': False, 'visualApproval': False, 'browserGpuTextureCount': 'not_measured',
              'browserPixelComparison': 'not_run',
              'limitations': ['8-bit RGB/RGBA scalar PNGs only; other images retain original bytes and bit depth.',
                              'BufferView/image/texture indices may be remapped; source accessor values and all geometry bytes stay exact.',
                              'This preserves existing bake artifacts; it does not repair or approve source art.',
                              'Actual browser pixels, mip sampling and GPU allocation count still require measurement.']}
    return candidate, report


def texture_refs_before_remap(doc, original_count):
    # Removed texture rows temporarily make old indices out of range. Enumerate
    # refs against a temporary list of the old length, without altering metadata.
    textures = doc['textures']
    doc['textures'] = [None] * original_count
    try:
        yield from texture_refs(doc)
    finally:
        doc['textures'] = textures


def optimize_file(source, output_directory, source_art_status='unreviewed'):
    source, output_directory = Path(source).resolve(), Path(output_directory).resolve()
    require(not output_directory.exists(), 'Candidate output directory already exists')
    require(not source.is_relative_to(output_directory), 'Output must not contain source')
    original = source.read_bytes()
    candidate, report = optimize_glb(original)
    require(sha(source.read_bytes()) == sha(original), 'Source changed during optimization')
    report.update(sourcePath=str(source), candidatePath=str(output_directory / source.name), sourceArtStatus=source_art_status)
    output_directory.mkdir(parents=True, exist_ok=False)
    with (output_directory / source.name).open('xb') as stream:
        stream.write(candidate)
    require(sha((output_directory / source.name).read_bytes()) == report['candidateGlbSha256'], 'Written candidate differs')
    with (output_directory / 'scalar-channel-optimization-report.json').open('x', encoding='utf-8') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2, allow_nan=False)
        stream.write('\n')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--out-dir', type=Path, required=True)
    parser.add_argument('--source-art-status', default='unreviewed')
    args = parser.parse_args()
    report = optimize_file(args.input, args.out_dir, args.source_art_status)
    print(json.dumps({k: report[k] for k in ('status', 'candidatePath', 'candidateGlbSha256', 'sourceGlbBytes',
                                          'candidateGlbBytes', 'savedGlbBytes', 'sourceImageCount', 'candidateImageCount')}, indent=2))


if __name__ == '__main__':
    main()
