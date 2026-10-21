"""Check the R6 review package against saved Blender and drawing evidence."""
import hashlib
import json
import argparse
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parent
GATES = ("left", "right", "shrine")
VIEWS = ("hero", "front", "side", "back", "plan", "eaves", "underside")


def read(name):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def basename(value):
    return str(value).replace('\\', '/').rsplit('/', 1)[-1]


def verify(require_upstream=True):
    manifest = read("manifest.json")
    reports = {entry["gate"]: entry for entry in read("validation-summary.json")}
    natives = {entry["gate"]: entry for entry in manifest["nativeFiles"]}
    renders = {(entry["gate"], entry["view"]): entry for entry in manifest["renders"]}
    assert set(natives) == set(reports) == set(GATES)
    assert set(renders) == {(gate, view) for gate in GATES for view in VIEWS}
    assert manifest["status"] == "new-build-rendered-needs-surface-review"
    assert manifest["geometryDesignApprovedByUser"] is True
    assert manifest["surfaceApprovedByUser"] is False
    assert manifest["fullDrawingMatchClaimed"] is False
    assert manifest["surfaceRevision"].startswith("R6")
    details = {}
    for gate in GATES:
        native = natives[gate]
        report = reports[gate]
        actual_sha = sha(ROOT / basename(native["path"]))
        assert actual_sha == native["sha256"] == report["sha256"]
        assert report["allChecksPassed"] and all(check["passed"] for check in report["checks"])
        before = read(f"geometry-before-{gate}.json")
        after = read(f"geometry-after-{gate}.json")
        assert before == after
        for view in VIEWS:
            render = renders[(gate, view)]
            path = ROOT / basename(render["file"])
            assert path.is_file() and path.stat().st_size > 1000
            assert path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n"
            assert render["nativeSha256"] == actual_sha and render["draft"] is False
            assert (ROOT / "surface-before" / f"{gate}-{view}.png").is_file()
            assert (ROOT / "surface-r5" / f"{gate}-{view}.png").is_file()
        details[gate] = {"checksPassed": len(report["checks"]), "geometrySha256": after["geometrySha256"], "nativeSha256": actual_sha}
    receipt = read("reference-textures/source-receipt.json")
    upstream = Path(os.environ.get('ILDU_R12_SOURCE', receipt['sourceBlend']))
    upstream_verified = upstream.is_file()
    if require_upstream and not upstream_verified:
        raise FileNotFoundError('Set ILDU_R12_SOURCE to the canonical R12 blend, or explicitly use --allow-missing-upstream for the portable package checks.')
    if upstream_verified:
        assert sha(upstream) == receipt['sourceBlendSha256']
    for item in receipt["extractedImages"]:
        assert sha(ROOT / 'reference-textures' / basename(item['path'])) == item['sha256']
    return {"passed": True, "renders": len(renders), "gates": details, "sourceSamples": len(receipt["extractedImages"]), 'upstreamNativeHashVerified': upstream_verified}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--allow-missing-upstream', action='store_true')
    opts = parser.parse_args()
    result = json.dumps(verify(not opts.allow_missing_upstream), ensure_ascii=False, indent=2)
    (ROOT / "surface-package-verification.json").write_text(result + "\n", encoding="utf-8")
    print(result)
