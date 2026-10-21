"""Exact R12 sources: original checkpoint and byte-audited packed derivative.

The packed derivative changes resource storage only. Its preservation receipt
compares every mesh/UV, object transform/material slot, scene membership and
190 image payload hashes before save and after a fresh Blender reopen.
"""
import hashlib
from pathlib import Path

ORIGINAL_R12_SHA256 = 'b954f76cdccc26619cf977497ac45509dabebc5e45f194ad5396e1d655e734b5'
PACKED_R12_SHA256 = 'b3b51dec9f2d4a7629912326bb224e8cf5595c2a874a1c3c85075a5f742af434'


def verified_r12_sha(path):
    with Path(path).open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual not in {ORIGINAL_R12_SHA256, PACKED_R12_SHA256}:
        raise RuntimeError('R12 source SHA mismatch')
    return actual
