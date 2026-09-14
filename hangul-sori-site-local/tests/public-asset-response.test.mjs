import assert from "node:assert/strict";
import { createServer } from "node:http";
import { once } from "node:events";
import test from "node:test";
import { requestPublicAsset } from "../scripts/public-asset-response.mjs";

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
