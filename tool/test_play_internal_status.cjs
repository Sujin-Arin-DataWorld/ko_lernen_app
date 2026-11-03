'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const { generateKeyPairSync } = require('node:crypto');
const { spawnSync } = require('node:child_process');
const { versionCode, trackName, summarize, accessToken, queryReleases, ENDPOINT, SCOPE } = require('./play_internal_status.cjs');
const release = (state, version = 7602, track = 'internal') => ({
  track, releaseName: 'must not be copied',
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
  assert.match(testing, /target_track:\s+description: [^\n]+\s+required: true\s+type: choice\s+default: internal\s+options:\s+- internal\s+- alpha\s+- beta\s+permissions:/);
  assert.ok(verification.includes('TARGET_TRACK: ${{ inputs.target_track }}'));
});

test('both jobs retain the Node 22 runtime and sparse locked auth dependency install', () => {
  const workflow = fs.readFileSync(path.join(__dirname, '../.github/workflows/play_internal_status.yml'), 'utf8');
  const jobs = workflow.slice(workflow.indexOf('  test:')).split('  verify:');
  assert.equal(jobs.length, 2);
  for (const job of jobs) {
    assert.ok(job.includes("node-version: '22'"));
    assert.ok(job.includes('sparse-checkout-cone-mode: false'));
    assert.ok(job.includes('/functions/tts/package.json'));
    assert.ok(job.includes('/functions/tts/package-lock.json'));
    assert.ok(job.includes('npm ci --ignore-scripts --prefix functions/tts'));
  }
});

test('requires a positive Play versionCode before authentication', () => {
  for (const value of [undefined, '', '0', '-1', '1.2', '7602\n', '021', '2100000001', '$(echo secret)']) {
    assert.throws(() => versionCode(value), /invalid_expected_version/);
  }
  assert.equal(versionCode('7602'), 7602);
});
test('only the allowlisted target tracks are accepted, with internal as the default', async () => {
  assert.equal(trackName(), 'internal');
  for (const track of ['internal', 'alpha', 'beta']) {
    assert.equal(trackName(track), track);
  }
  for (const track of [null, '', 'production', 'Beta', 'beta\n', 'beta/../production',
    'internal?track=beta', 'https://example.invalid', '$(echo secret)', ['beta']]) {
    assert.throws(() => trackName(track), /invalid_target_track/);
    assert.throws(() => summarize({}, 7602, track), /invalid_target_track/);
    let calls = 0;
    await assert.rejects(queryReleases('secret', async () => { calls++; }, track), /invalid_target_track/);
    assert.equal(calls, 0);
  }
});
test('CLI rejects an invalid track before loading auth or printing credentials', () => {
  const result = spawnSync(process.execPath, [path.join(__dirname, 'play_internal_status.cjs')], {
    env: {
      EXPECTED_VERSION_CODE: '7602', TARGET_TRACK: 'production',
      GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: 'private-test-secret',
    },
    encoding: 'utf8',
  });
  assert.equal(result.status, 2);
  assert.equal(result.stdout, '');
  assert.deepEqual(JSON.parse(result.stderr), { error: 'invalid_target_track' });
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
for (const track of ['internal', 'alpha', 'beta']) {
  test(`${track} publication requires the exact version and matching response track`, () => {
    const proof = summarize({ releases: [release('PUBLISHED', 7602, track)] }, 7602, track);
    assert.equal(proof.track, track);
    assert.equal(proof.expectedVersion, 7602);
    assert.equal(proof.verdict, 'published');
    assert.equal(proof.deviceInstallVerified, false);
    assert.equal(JSON.stringify(proof).includes('must not be copied'), false);
    assert.equal(summarize({ releases: [release('PUBLISHED', 2265, track)] }, 7602, track).verdict, 'not_found');
    assert.equal(summarize({ releases: [release('IN_REVIEW', 7602, track),
      release('PUBLISHED', 2265, track)] }, 7602, track).verdict, 'not_published');
    for (const otherTrack of ['internal', 'alpha', 'beta'].filter((value) => value !== track)) {
      assert.throws(() => summarize({ releases: [release('PUBLISHED', 7602, otherTrack)] }, 7602, track), /invalid_response/);
      assert.throws(() => summarize({ releases: [release('PUBLISHED', 7602, track),
        release('PUBLISHED', 7602, otherTrack)] }, 7602, track), /invalid_response/);
    }
  });
  test(`${track} uses only its allowlisted GET endpoint without a request body`, async () => {
    let calls = 0;
    const result = await queryReleases('private-token', async (url, options) => {
      calls++;
      assert.equal(url, ENDPOINT.replace('/tracks/internal/', `/tracks/${track}/`));
      assert.equal(options.method, 'GET');
      assert.equal(options.redirect, 'error');
      assert.equal(options.body, undefined);
      assert.equal(options.headers.Authorization, 'Bearer private-token');
      assert.ok(options.signal instanceof AbortSignal);
      return new Response(JSON.stringify({ releases: [release('PUBLISHED', 7602, track)] }));
    }, track);
    assert.equal(calls, 1);
    assert.equal(summarize(result, 7602, track).verdict, 'published');
  });
}
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
test('redirect statuses and followed or unexpected response URLs cannot certify a release', async () => {
  const endpoint = ENDPOINT.replace('/tracks/internal/', '/tracks/beta/');
  for (const status of [301, 302, 303, 307, 308]) {
    await assert.rejects(queryReleases('secret', async () => new Response('private redirect', {
      status, headers: { Location: 'https://example.invalid/private' },
    }), 'beta'), /api_failed/);
  }
  for (const metadata of [
    { redirected: true, url: endpoint },
    { redirected: false, url: ENDPOINT },
    { redirected: false, url: 'https://example.invalid/private' },
  ]) {
    let bodyReads = 0;
    await assert.rejects(queryReleases('secret', async () => ({
      ok: true, status: 200, ...metadata,
      async text() { bodyReads++; return JSON.stringify({ releases: [release('PUBLISHED', 7602, 'beta')] }); },
    }), 'beta'), /request_failed/);
    assert.equal(bodyReads, 0);
  }
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
