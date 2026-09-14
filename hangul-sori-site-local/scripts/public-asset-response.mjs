import assert from "node:assert/strict";

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
