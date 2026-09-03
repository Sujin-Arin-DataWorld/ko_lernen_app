"use strict";
const test = require('node:test');
const assert = require('node:assert/strict');
const { appleOAuthCallback } = require('./apple_oauth_callback');

function invoke(body, overrides = {}) {
  const request = { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' },
    query: {}, body, rawBody: Buffer.from(new URLSearchParams(body).toString()), ...overrides };
  const result = { headers: {} };
  const response = { set(name, value) { result.headers[name.toLowerCase()] = value; return this; },
    status(code) { result.status = code; return this; }, send(body) { result.body = body; return this; } };
  appleOAuthCallback(request, response);
  return result;
}

test('valid Apple POST redirects only to the observed Android app', () => {
  const result = invoke({ code: 'code+/?&', id_token: 'signed.token.value', state: 'nonce-state' });
  assert.equal(result.status, 302);
  assert.equal(result.headers['cache-control'], 'no-store');
  const location = result.headers.location;
  assert.equal(location, 'intent://callback?code=code%2B%2F%3F%26&id_token=signed.token.value&state=nonce-state#Intent;package=com.sujinarin.ko_lernen_app;scheme=signinwithapple;end');
});
test('user denial returns only bounded error and matching state to app', () => {
  const result = invoke({ error: 'user_cancelled_authorize', state: 'random-state' });
  assert.equal(result.status, 302);
  const query = new URLSearchParams(result.headers.location.split('?')[1].split('#')[0]);
  assert.equal(query.get('error'), 'user_cancelled_authorize');
  assert.equal(query.get('state'), 'random-state');
});
for (const [name, body, overrides] of [
  ['GET', {}, { method: 'GET' }],
  ['JSON', {}, { headers: { 'content-type': 'application/json' } }],
  ['query redirect', {}, { query: { redirect_uri: 'https://evil.test' } }],
  ['oversized', {}, { rawBody: Buffer.alloc(32769) }],
  ['open redirect', { code: 'code', id_token: 'token', state: 'state', redirect_uri: 'https://evil.test' }, {}],
  ['intent injection', { code: 'code', id_token: 'token', state: '#Intent;package=evil;end' }, {}],
  ['missing state', { code: 'code', id_token: 'token' }, {}],
  ['duplicate code', { code: ['one', 'two'], id_token: 'token', state: 'state' }, {}],
  ['mixed error', { code: 'code', id_token: 'token', error: 'error', state: 'state' }, {}],
]) {
  test(`rejects ${name} without returning tokens`, () => {
    const result = invoke(body, overrides);
    assert.equal(result.status, 400);
    assert.equal(result.headers.location, undefined);
    assert.equal(result.body, 'Invalid Apple callback.');
    assert.equal(result.headers['cache-control'], 'no-store');
  });
}
