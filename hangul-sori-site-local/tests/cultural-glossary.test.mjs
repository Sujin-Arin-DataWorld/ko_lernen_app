import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const canonicalUrl = new URL("../../docs/data/cultural_glossary.json", import.meta.url);
const publicUrl = new URL("../public/data/cultural_glossary.json", import.meta.url);

test("publishes the canonical 23-entry cultural glossary byte for byte", async () => {
  const [canonical, published] = await Promise.all([
    readFile(canonicalUrl),
    readFile(publicUrl),
  ]);
  assert.deepEqual(published, canonical);

  const catalog = JSON.parse(canonical.toString("utf8"));
  assert.equal(catalog.schemaVersion, 1);
  assert.equal(catalog.entries.length, 23);
  assert.deepEqual(
    new Set(catalog.entries.map((entry) => entry.termId)),
    new Set(["hanok", "gye", "sarangbang", "sarangchae", "madang", "jongga", "dancheong", "bojagi", "jangdokdae", "munbangsau", "maehwa", "sagunja", "gat", "chaekgado", "soban", "jagae_mungap", "dojangcheop", "kkachi", "daecheong", "haengnangchae", "anchae", "huwon", "sadang"]),
  );

  const decorationSlugs = [];
  for (const entry of catalog.entries) {
    assert.deepEqual(Object.keys(entry.localizations).sort(), ["de", "en", "ko"]);
    for (const copy of Object.values(entry.localizations)) {
      assert.ok([...copy.meaning].length <= 140);
      assert.ok([...copy.story].length <= 180);
    }
    for (const language of ["de", "en"]) {
      const copy = entry.localizations[language];
      assert.doesNotMatch(`${copy.meaning}${copy.story}`, /[–—]/);
    }
    for (const source of entry.sources) {
      assert.equal(new URL(source.url).protocol, "https:");
    }
    decorationSlugs.push(...entry.decorationSlugs);
  }
  assert.equal(new Set(decorationSlugs).size, decorationSlugs.length);
});

test("marks only explicit first-appearance terms and fails closed in the client", async () => {
  const [site, component] = await Promise.all([
    readFile(new URL("../app/site.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/cultural-glossary.tsx", import.meta.url), "utf8"),
  ]);

  assert.equal((site.match(/termId="hanok"/g) ?? []).length, 1);
  assert.equal((site.match(/termId="gye"/g) ?? []).length, 1);
  assert.match(component, /data-cultural-term=\{termId\}/);
  assert.match(component, /if \(!response\.ok\) return null/);
  assert.match(component, /\.catch\(\(\) => null\)/);
  assert.doesNotMatch(component, /match\(|matchAll\(|new RegExp|replaceAll\(/);
});
