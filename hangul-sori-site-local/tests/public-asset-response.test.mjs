import assert from "node:assert/strict";
import { createServer } from "node:http";
import { once } from "node:events";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { assertPublicAssetBody, requestPublicAsset } from "../scripts/public-asset-response.mjs";

const productionHtmlUrl = "https://www.hangul-sori.com/hanok/construction/index.html";
async function fetchProductionHtml(original) {
  const { default: worker } = await import(new URL("../dist/server/index.js", import.meta.url));
  return worker.fetch(new Request(productionHtmlUrl), {
    ASSETS: { fetch: async () => new Response(original, { headers: { "content-type": "text/html; charset=utf-8" } }) },
  }, { waitUntil() {}, passThroughOnException() {} });
}

test("accepts the built production Worker's CSP nonce while detecting every other HTML change", async () => {
  const original = await readFile(new URL("../public/hanok/construction/index.html", import.meta.url));
  const url = productionHtmlUrl;
  const response = await fetchProductionHtml(original);
  assert.equal(response.status, 200);
  const rendered = await response.clone().text();
  assert.notEqual(rendered, original.toString("utf8"), "the production hostname must exercise nonce injection");
  await assertPublicAssetBody(response, original, url);

  for (const html of [
    rendered.replace('src="app.js"', 'src="unexpected.js"'),
    `${rendered}<script>alert(1)</script>`,
    rendered.replace(/nonce="[^"]+"/, 'nonce="wrong"'),
    original.toString("utf8"),
  ]) {
    assert.notEqual(html, rendered, "each tampering fixture must change the response");
    await assert.rejects(assertPublicAssetBody(new Response(html, { headers: response.headers }), original, url), /must match the owned public asset/);
  }
  const wrongCsp = new Headers(response.headers);
  wrongCsp.set("content-security-policy", wrongCsp.get("content-security-policy").replace(/nonce-[^']+/, `nonce-${"A".repeat(24)}`));
  await assert.rejects(assertPublicAssetBody(new Response(rendered, { headers: wrongCsp }), original, url), /must match the owned public asset/);
  await assert.rejects(assertPublicAssetBody(new Response(rendered, { headers: { "content-type": "text/html" } }), original, url), /production script nonce/);
  const unchangedAssets = [
    ["original.png", Buffer.from([0, 1, 255, 128])],
    ["app.js", Buffer.from('const example = "<script>";\n')],
    ["styles.css", Buffer.from('/* <script> */\nbody { color: #fff; }\n')],
  ];
  for (const [path, bytes] of unchangedAssets) {
    const assetUrl = `https://hangul-sori.com/${path}`;
    await assertPublicAssetBody(new Response(bytes), bytes, assetUrl);
    const changed = Buffer.from(bytes);
    changed[0] ^= 1;
    await assert.rejects(assertPublicAssetBody(new Response(changed), bytes, assetUrl), /byte-for-byte/);
  }
});

test("applies the CSP nonce exactly once to every script in the original HTML", async () => {
  const original = Buffer.from('<!doctype html><script src="app.js"></script><script type="application/json">{}</script><script>void 0</script>');
  const response = await fetchProductionHtml(original);
  const nonce = /'nonce-([^']+)'/.exec(response.headers.get("content-security-policy"))[1];
  const rendered = await response.clone().text();
  assert.equal((rendered.match(/ nonce="/g) ?? []).length, 3);
  assert.equal(rendered, original.toString("utf8").replace(/<script(?=\s|>)/g, `<script nonce="${nonce}"`));
  await assertPublicAssetBody(response, original, productionHtmlUrl);
});

test("routes every canonical gallery document alias through the secured asset binding", async () => {
  const { default: worker } = await import(new URL("../dist/server/index.js", import.meta.url));
  const original = await readFile(new URL("../public/hanok/construction/index.html", import.meta.url));
  const requestedPaths = [];
  const env = {
    ASSETS: {
      fetch: async request => {
        const pathname = new URL(request.url).pathname;
        requestedPaths.push(pathname);
        if (pathname !== "/hanok/construction/") {
          return new Response(null, {
            status: 307,
            headers: { location: "/hanok/construction/" },
          });
        }
        return new Response(original, {
          headers: { "content-type": "text/html; charset=utf-8" },
        });
      },
    },
  };
  const ctx = { waitUntil() {}, passThroughOnException() {} };

  for (const pathname of [
    "/hanok/construction",
    "/hanok/construction/",
    "/hanok/construction/index.html",
  ]) {
    let response = await worker.fetch(
      new Request(new URL(pathname, productionHtmlUrl)),
      env,
      ctx,
    );
    if (response.status === 307) {
      response = await worker.fetch(
        new Request(new URL(response.headers.get("location"), productionHtmlUrl)),
        env,
        ctx,
      );
    }
    assert.equal(response.status, 200);
    await assertPublicAssetBody(response, original, productionHtmlUrl);
  }

  assert.deepEqual(requestedPaths, [
    "/hanok/construction",
    "/hanok/construction/",
    "/hanok/construction/",
    "/hanok/construction/index.html",
    "/hanok/construction/",
  ]);
});

test("verifies directory indexes through only their exact canonical redirect", async () => {
  const expected = Buffer.from("<!doctype html><title>한옥 공정</title>");
  const seen = [];
  const server = createServer((request, response) => {
    seen.push(request.url);
    if (request.url === "/hanok/construction/" || request.url === "/direct.png") {
      response.writeHead(200).end(expected);
      return;
    }
    const redirects = {
      "/hanok/construction/index.html": [307, "/hanok/construction/"],
      "/elsewhere/index.html": [307, "/hanok/construction/"],
      "/external/index.html": [307, "https://example.invalid/"],
      "/query/index.html": [307, "/query/?changed=1"],
      "/chain/index.html": [308, "/chain/"],
      "/chain/": [307, "/hanok/construction/"],
      "/redirect.png": [307, "/direct.png"],
      "/missing/index.html": [307, null],
    };
    const redirect = redirects[request.url];
    if (redirect) {
      response.writeHead(redirect[0], redirect[1] ? { location: redirect[1] } : {}).end();
      return;
    }
    response.writeHead(404).end();
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const origin = `http://127.0.0.1:${server.address().port}`;
  const request = (url, options) => fetch(url, { ...options, redirect: "manual" });
  try {
    for (const path of ["/hanok/construction/index.html", "/direct.png"]) {
      const response = await requestPublicAsset(`${origin}${path}`, request);
      assert.deepEqual(Buffer.from(await response.arrayBuffer()), expected);
    }
    for (const path of ["/elsewhere/index.html", "/external/index.html", "/query/index.html"]) {
      await assert.rejects(requestPublicAsset(`${origin}${path}`, request), /own canonical directory/);
    }
    for (const path of ["/chain/index.html", "/redirect.png", "/unknown.png"]) {
      await assert.rejects(requestPublicAsset(`${origin}${path}`, request), /must be available/);
    }
    await assert.rejects(requestPublicAsset(`${origin}/missing/index.html`, request), /include a location/);
    assert.equal(seen.filter(path => path === "/hanok/construction/").length, 1, "invalid redirects are never followed");
  } finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});
