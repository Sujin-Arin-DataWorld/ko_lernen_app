"""Preserve Cycles 5.2.2 regular-object Random when joining bake meshes.

Matches Blender v5.2.2 intern/cycles/blender/object.cpp:325,
util/hash.h and scene/object.cpp:541. Instances need their own random_id;
this function deliberately only accepts an authored regular object name.
"""
import struct


def object_random(name):
    mask = 0xffffffff
    h = 0
    # This Blender Windows build uses unsigned char; verified with Korean names.
    for byte in name.encode('utf-8'):
        h = (h * 37 + byte) & mask
    a = b = c = (0xdeadbeef + 8 + 13) & mask
    a = (a + h) & mask
    def rot(x, k):
        return ((x << k) | (x >> (32 - k))) & mask
    c = ((c ^ b) - rot(b, 14)) & mask
    a = ((a ^ c) - rot(c, 11)) & mask
    b = ((b ^ a) - rot(a, 25)) & mask
    c = ((c ^ b) - rot(b, 16)) & mask
    a = ((a ^ c) - rot(c, 4)) & mask
    b = ((b ^ a) - rot(a, 14)) & mask
    c = ((c ^ b) - rot(b, 24)) & mask
    f32 = lambda x: struct.unpack('<f', struct.pack('<f', x))[0]
    return f32(f32(c) * f32(1.0 / f32(mask)))
