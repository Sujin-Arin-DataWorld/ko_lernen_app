'use strict';

// GET-only release lifecycle evidence. No edit, upload, commit, or rollout call.
// https://developers.google.com/android-publisher/api-ref/rest/v3/applications.tracks.releases/list
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

const PACKAGE = 'com.sujinarin.ko_lernen_app';
const ENDPOINT = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/tracks/internal/releases`;
const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const PREFIX = 'RELEASE_LIFECYCLE_STATE_';
const STATES = new Set([
  'UNSPECIFIED', 'DRAFT', 'NOT_SENT_FOR_REVIEW', 'IN_REVIEW',
  'APPROVED_NOT_PUBLISHED', 'NOT_APPROVED', 'PUBLISHED',
].map((state) => PREFIX + state));

class StatusError extends Error {
  constructor(code) {
    super(code);
    this.code = code;
  }
}

function versionCode(value) {
  if (typeof value !== 'string' || !/^[1-9]\d{0,9}$/.test(value) ||
      Number(value) > 2100000000) {
    throw new StatusError('invalid_expected_version');
  }
  return Number(value);
}

function summarize(data, expectedVersion) {
  if (!data || typeof data !== 'object' || Array.isArray(data) ||
      (data.releases !== undefined && !Array.isArray(data.releases)) ||
      (data.releases?.length ?? 0) > 20) {
    throw new StatusError('invalid_response');
  }
  const releases = (data.releases ?? []).map((release) => {
    if (!release || release.track !== 'internal' ||
        !STATES.has(release.releaseLifecycleState) ||
        !Array.isArray(release.activeArtifacts)) {
      throw new StatusError('invalid_response');
    }
    const versions = release.activeArtifacts.map((artifact) => {
      if (!Number.isInteger(artifact?.versionCode) ||
          artifact.versionCode <= 0 || artifact.versionCode > 2100000000) {
        throw new StatusError('invalid_response');
      }
      return artifact.versionCode;
    });
    // Do not retain release names, account identifiers, or arbitrary response data.
    return { versionCodes: versions, lifecycleState: release.releaseLifecycleState };
  });
  const matches = releases.filter((r) => r.versionCodes.includes(expectedVersion));
  const published = matches.some((r) => r.lifecycleState === PREFIX + 'PUBLISHED');
  return {
    schemaVersion: 1, packageName: PACKAGE, track: 'internal', expectedVersion,
    verdict: published ? 'published' : matches.length ? 'not_published' : 'not_found',
    releases,
    // API publication is not proof that a particular device/account can install.
    deviceInstallVerified: false,
  };
}

async function accessToken(secret, JWTClass) {
  try {
    const credentials = JSON.parse(secret);
    if (credentials.type !== 'service_account' ||
        typeof credentials.client_email !== 'string' ||
        typeof credentials.private_key !== 'string') {
      throw new Error('invalid credentials');
    }
    const jwt = new JWTClass({
      email: credentials.client_email,
      key: credentials.private_key,
      scopes: [SCOPE],
      transporterOptions: {
        timeout: 15000, retry: false,
        // gtoken adds a POST retryConfig; explicitly disable both retry budgets.
        retryConfig: { retry: 0, noResponseRetries: 0 },
      },
    });
    const result = await jwt.authorize();
    if (typeof result.access_token !== 'string' || !result.access_token ||
        /\s/.test(result.access_token)) throw new Error('invalid token');
    return result.access_token;
  } catch (_) {
    // OAuth errors may contain credentials, request headers, or account details.
    throw new StatusError('authentication_failed');
  }
}

async function queryReleases(token, fetchImpl = fetch) {
  let response;
  try {
    response = await fetchImpl(ENDPOINT, {
      method: 'GET', redirect: 'error', signal: AbortSignal.timeout(15000),
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
    });
  } catch (_) {
    throw new StatusError('request_failed');
  }
  if (!response.ok) {
    throw new StatusError(response.status === 403 ? 'permission_denied' :
      response.status === 401 ? 'authentication_failed' : 'api_failed');
  }
  try {
    const text = await response.text();
    if (Buffer.byteLength(text, 'utf8') > 65536) throw new Error('too large');
    return JSON.parse(text);
  } catch (_) {
    throw new StatusError('invalid_response');
  }
}

async function main() {
  try {
    const expected = versionCode(process.env.EXPECTED_VERSION_CODE);
    const secret = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
    delete process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
    // Reuse the checked-in TTS dependency lock; no new package/version resolution.
    const ttsRequire = createRequire(path.join(__dirname, '../functions/tts/package.json'));
    const { JWT } = ttsRequire('google-auth-library');
    const token = await accessToken(secret, JWT);
    const receipt = summarize(await queryReleases(token), expected);
    receipt.checkedAt = new Date().toISOString();
    fs.writeFileSync('play-internal-status.json', JSON.stringify(receipt, null, 2) + '\n');
    console.log(JSON.stringify(receipt));
    process.exitCode = receipt.verdict === 'published' ? 0 : 3;
  } catch (error) {
    // Never print a raw exception, response body, secret, or access token.
    console.error(JSON.stringify({ error: error instanceof StatusError ? error.code : 'verification_failed' }));
    process.exitCode = 2;
  }
}

module.exports = { PACKAGE, ENDPOINT, SCOPE, StatusError, versionCode, summarize, accessToken, queryReleases };
if (require.main === module) main();
