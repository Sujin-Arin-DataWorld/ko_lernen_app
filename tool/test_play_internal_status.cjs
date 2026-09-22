'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const { generateKeyPairSync } = require('node:crypto');
const { versionCode, summarize, accessToken, queryReleases, ENDPOINT, SCOPE } = require('./play_internal_status.cjs');
const release = (state, version = 7602) => ({
  track: 'internal', releaseName: 'must not be copied',
  releaseLifecycleState: `RELEASE_LIFECYCLE_STATE_${state}`,
  activeArtifacts: [{ versionCode: version }],
});

test('manual verification cannot replace a pending upload or expose its secret to PR tests', () => {
  const workflow = fs.readFileSync(path.join(__dirname, '../.github/workflows/play_internal_status.yml'), 'utf8');
  const [testing, verification] = workflow.split('  verify:');
  assert.equal(testing.includes('secrets.'), false);
  assert.ok(verification.includes("github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'"));
  assert.ok(verification.includes('name: google-play-internal'));
  assert.ok(verification.includes('group: google-play-internal-status'));
  assert.equal(/^\s*group: google-play-internal\s*$/m.test(verification), false);
  assert.equal(verification.includes('PLAY_INTERNAL_RELEASE_ENABLED'), false);
});

test('requires a positive Play versionCode before authentication', () => {
  for (const value of [undefined, '', '0', '-1', '1.2', '7602\n', '021', '2100000001', '$(echo secret)']) {
    assert.throws(() => versionCode(value), /invalid_expected_version/);
  }
  assert.equal(versionCode('7602'), 7602);
});
test('completed upload is not a publication lifecycle state', () => {
  assert.throws(() => summarize({ releases: [release('completed')] }, 7602), /invalid_response/);
});
for (const state of ['UNSPECIFIED', 'DRAFT', 'NOT_SENT_FOR_REVIEW', 'IN_REVIEW', 'APPROVED_NOT_PUBLISHED', 'NOT_APPROVED']) {
  test(`${state} does not certify publication`, () => {
    assert.equal(summarize({ releases: [release(state)] }, 7602).verdict, 'not_published');
  });
}
test('only the exact expected active artifact can certify publication', () => {
  assert.equal(summarize({ releases: [release('PUBLISHED', 2265)] }, 7602).verdict, 'not_found');
  const proof = summarize({ releases: [release('PUBLISHED')] }, 7602);
  assert.equal(proof.verdict, 'published');
  assert.equal(proof.deviceInstallVerified, false);
  assert.equal(JSON.stringify(proof).includes('must not be copied'), false);
});
test('missing releases remains not found, never success', () => {
  assert.equal(summarize({}, 7602).verdict, 'not_found');
  assert.equal(summarize({ releases: [] }, 7602).verdict, 'not_found');
});
test('malformed, wrong-track, unknown, and non-numeric artifacts fail closed', () => {
  for (const data of [null, [], { releases: {} }, { releases: [null] },
    { releases: [{ ...release('PUBLISHED'), track: 'alpha' }] },
    { releases: [{ ...release('PUBLISHED'), activeArtifacts: [{ versionCode: '7602' }] }] },
    { releases: [{ ...release('PUBLISHED'), activeArtifacts: null }] },
    { releases: [release('NEW_UNKNOWN_STATE')] }]) {
    assert.throws(() => summarize(data, 7602), /invalid_response/);
  }
});
test('uses only the fixed GET endpoint, refuses redirects and does not retry', async () => {
  let calls = 0;
  const result = await queryReleases('private-token', async (url, options) => {
    calls++;
    assert.equal(url, ENDPOINT);
    assert.equal(options.method, 'GET');
    assert.equal(options.redirect, 'error');
    assert.equal(options.body, undefined);
    assert.equal(options.headers.Authorization, 'Bearer private-token');
    assert.ok(options.signal instanceof AbortSignal);
    return new Response(JSON.stringify({ releases: [release('PUBLISHED')] }));
  });
  assert.equal(calls, 1);
  assert.equal(summarize(result, 7602).verdict, 'published');
});
test('HTTP and network failures do not expose service messages or credentials', async () => {
  for (const status of [401, 403, 404, 429, 500]) {
    let calls = 0;
    await assert.rejects(queryReleases('secret', async () => {
      calls++;
      return new Response('secret account and headers', { status });
    }), (error) => !error.message.includes('secret'));
    assert.equal(calls, 1);
  }
  await assert.rejects(queryReleases('secret', async () => { throw new Error('secret'); }), /request_failed/);
});
test('invalid or oversized successful API responses fail closed', async () => {
  for (const content of ['<html>error</html>', ' '.repeat(65537)]) {
    await assert.rejects(queryReleases('secret', async () => new Response(content)), /invalid_response/);
  }
});
test('uses the locked Google JWT client with only publisher scope and bounded transport', async () => {
  const secret = JSON.stringify({ type: 'service_account', client_email: 'private', private_key: 'private-key' });
  class JWT {
    constructor(options) {
      assert.deepEqual(options.scopes, [SCOPE]);
      assert.equal(options.transporterOptions.retry, false);
      assert.equal(options.transporterOptions.timeout, 15000);
      assert.equal(options.subject, undefined);
      assert.equal(options.keyFile, undefined);
    }
    async authorize() { return { access_token: 'token' }; }
  }
  assert.equal(await accessToken(secret, JWT), 'token');
  class FailingJWT { async authorize() { throw new Error('private-key'); } }
  await assert.rejects(accessToken(secret, FailingJWT), /authentication_failed/);
  await assert.rejects(accessToken('invalid-secret', JWT), /authentication_failed/);
});

test('actual locked OAuth transport attempts a transient token failure only once', async () => {
  const ttsRequire = createRequire(path.join(__dirname, '../functions/tts/package.json'));
  const { JWT } = ttsRequire('google-auth-library');
  const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const secret = JSON.stringify({
    type: 'service_account', client_email: 'test@example.invalid',
    private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }),
  });
  let calls = 0;
  class FakeTransportJWT extends JWT {
    constructor(options) {
      super(options);
      this.transporter.defaults.adapter = async (config) => {
        calls++;
        assert.equal(config.url, 'https://oauth2.googleapis.com/token');
        assert.equal(config.method, 'POST');
        return { config, status: 503, statusText: 'Unavailable', headers: {}, data: { error: 'temporarily_unavailable' } };
      };
    }
  }
  await assert.rejects(accessToken(secret, FakeTransportJWT), /authentication_failed/);
  assert.equal(calls, 1);
});
