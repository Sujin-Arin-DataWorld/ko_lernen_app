import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile, readdir } from "node:fs/promises";
import { resolve } from "node:path";
import test from "node:test";

const root = resolve(import.meta.dirname, "../..");
const gallery = resolve(root, "hangul-sori-site-local/public/hanok/construction");
const readJson = async path => JSON.parse(await readFile(path, "utf8"));
const hash = bytes => createHash("sha256").update(bytes).digest("hex");

test("the public gallery contains the 49 approved PNGs and no production notes", async () => {
  const catalog = await readJson(resolve(gallery, "construction_catalog.json"));
  const adoption = await readJson(resolve(root, "docs/assets/ildu_four_buildings_construction_20260914/promotion_manifest.json"));
  assert.equal(catalog.status, "approved_canonical");
  assert.deepEqual(catalog.buildings.map(b => [b.id, b.steps.length]), [
    ["jungmunganchae", 12], ["araechae", 12], ["anchae", 14], ["anchae-store", 11]
  ]);
  assert.equal(adoption.files.length, 49);
  for (const building of catalog.buildings) {
    const paths = [];
    for (const stage of building.steps) {
      const record = adoption.files.find(r => r.buildingId === building.id && r.sequence === stage.number);
      assert.ok(record);
      const publicBytes = await readFile(resolve(gallery, stage.file));
      assert.equal(hash(publicBytes), record.sha256);
      assert.equal(hash(publicBytes), stage.sha256);
      assert.equal(publicBytes.readUInt32BE(16), 1536);
      assert.equal(publicBytes.readUInt32BE(20), 1024);
      for (const language of ["ko", "en", "de"]) {
        assert.ok(stage.sentence[language]);
        assert.ok(stage.observe[language]);
      }
      paths.push(stage.file.split("/").at(-1));
    }
    assert.deepEqual((await readdir(resolve(gallery, "images", building.id))).sort(), paths.sort());
  }
  const html = await readFile(resolve(gallery, "index.html"), "utf8");
  const js = await readFile(resolve(gallery, "app.js"), "utf8");
  assert.doesNotMatch(html + js + JSON.stringify(catalog), /assets_unused|pending_review|C:\\\\|\.prompt\.txt|four-buildings-49-png\.zip/);
  assert.match(html, /lang="ko"/);
  assert.match(html, /id="stage-image"/);
  assert.match(js, /const BASE='\.\/';/);
  assert.deepEqual((await readdir(gallery)).sort(), ["app.js", "construction_catalog.json", "images", "index.html", "styles.css"]);
});
