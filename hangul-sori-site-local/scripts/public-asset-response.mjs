import assert from "node:assert/strict";
import { createHash } from "node:crypto";

export async function assertPublicAssetBody(response, original, assetUrl) {
  let expected = Buffer.from(original);
  const isHtml = new URL(assetUrl).pathname.endsWith(".html");
  if (isHtml) {
    assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i, `${assetUrl} must serve HTML`);
    const scriptDirective = (response.headers.get("content-security-policy") ?? "")
      .split(";").map(value => value.trim()).find(value => value.startsWith("script-src "));
    const nonce = /^script-src 'nonce-([A-Za-z0-9+/]{24})' 'strict-dynamic'(?:\s|$)/.exec(scriptDirective ?? "")?.[1];
    assert.ok(nonce, `${assetUrl} must declare the production script nonce`);
    // The production Worker adds exactly this nonce to every script tag.
    // Reconstruct that permitted response from the original; do not strip markup.
    expected = Buffer.from(expected.toString("utf8").replace(/<script(?=\s|>)/g, `<script nonce="${nonce}"`));
  }
  const actual = Buffer.from(await response.arrayBuffer());
  assert.ok(actual.byteLength > 0, `${assetUrl} must not be empty`);
  const hash = bytes => createHash("sha256").update(bytes).digest("hex");
  assert.equal(hash(actual), hash(expected), `${assetUrl} must match the owned public asset ${isHtml ? "with only its production script nonce" : "byte-for-byte"}`);
}

export async function requestPublicAsset(assetUrl, request) {
  const url = new URL(assetUrl);
  const options = { headers: { accept: "*/*" } };
  let response = await request(url.href, options);

  // Workers Static Assets serves directory indexes at their canonical folder URL.
  if ([307, 308].includes(response.status) && url.pathname.endsWith("/index.html")) {
    const canonicalUrl = new URL(url);
    canonicalUrl.pathname = canonicalUrl.pathname.slice(0, -"index.html".length);
    const location = response.headers.get("location");
    assert.ok(location, `${assetUrl} index redirect must include a location`);
    assert.equal(
      new URL(location, url).href,
      canonicalUrl.href,
      `${assetUrl} may redirect only to its own canonical directory`,
    );
    await response.body?.cancel();
    response = await request(canonicalUrl.href, options);
  }

  assert.equal(response.status, 200, `${assetUrl} must be available`);
  return response;
}
