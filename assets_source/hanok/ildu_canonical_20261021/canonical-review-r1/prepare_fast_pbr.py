from pathlib import Path
import hashlib,json
OUT=Path(__file__).resolve().parent
source=OUT/'pbr-pipeline/r12_pbr_delivery.py'
s=source.read_text(encoding='utf-8')
old="""    combined.calc_loop_triangles()
    face_triangles = {}
    for triangle in combined.loop_triangles:
        face_triangles.setdefault(triangle.polygon_index, []).append(tuple(triangle.loops))
"""
new="""    cache_key=(combined.as_pointer(),len(combined.polygons),len(combined.loops))
    cached=getattr(_extract,'_triangulation_cache',None)
    if cached is not None and cached[0]==cache_key:
        face_triangles=cached[1]
    else:
        combined.calc_loop_triangles()
        face_triangles = {}
        for triangle in combined.loop_triangles:
            face_triangles.setdefault(triangle.polygon_index, []).append(tuple(triangle.loops))
        _extract._triangulation_cache=(cache_key,face_triangles)
"""
assert s.count(old)==1
p=OUT/'pbr-pipeline/r12_pbr_delivery_fast.py';p.write_text(s.replace(old,new),encoding='utf-8')
(OUT/'pbr-pipeline/FAST_EXTRACT_RECEIPT.json').write_text(json.dumps(dict(sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest(),snapshotSha256=hashlib.sha256(p.read_bytes()).hexdigest(),change='Cache unchanged combined mesh triangulation between exact individual-member extractions. No geometry/UV/material changes.'),indent=2),encoding='utf-8')

