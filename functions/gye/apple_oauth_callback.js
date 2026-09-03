"use strict";

// Matches the pinned sign_in_with_apple 8.1 callback Activity and the Android
// applicationId. This endpoint only relays an untrusted result. Firebase must
// validate the ID token/nonce and the app must validate its one-use state before
// any identity mutation. It never creates an authenticated server session.
const ANDROID_RETURN = '#Intent;package=com.sujinarin.ko_lernen_app;scheme=signinwithapple;end';
const ALLOWED_FIELDS = new Set(['code', 'id_token', 'state', 'user', 'error', 'error_description']);

function appleOAuthCallback(request, response) {
  response.set('Cache-Control', 'no-store');
  response.set('Pragma', 'no-cache');
  response.set('Referrer-Policy', 'no-referrer');
  response.set('X-Content-Type-Options', 'nosniff');
  const invalid = () => response.status(400).send('Invalid Apple callback.');
  const type = request.headers?.['content-type']?.split(';')[0]?.trim().toLowerCase();
  const body = request.body;
  if (request.method !== 'POST' || type !== 'application/x-www-form-urlencoded' ||
      !Buffer.isBuffer(request.rawBody) || request.rawBody.length > 32768 ||
      Object.keys(request.query || {}).length !== 0 || !body || typeof body !== 'object' ||
      Array.isArray(body) || Object.keys(body).some((key) => !ALLOWED_FIELDS.has(key))) {
    return invalid();
  }
  for (const [key, value] of Object.entries(body)) {
    if (typeof value !== 'string' || !value || value.length > (key === 'id_token' ? 16384 : 4096) ||
        /[\u0000-\u001f\u007f]/u.test(value)) return invalid();
  }
  // AuthService creates exactly this alphabet for a 32-character random state.
  if (typeof body.state !== 'string' || !/^[A-Za-z0-9._-]{1,128}$/u.test(body.state)) return invalid();
  if (body.error ? (body.code || body.id_token || body.user) : (!body.code || !body.id_token)) return invalid();
  const fields = new URLSearchParams();
  for (const key of ['code', 'id_token', 'state', 'error']) {
    if (body[key]) fields.set(key, body[key]);
  }
  // Apple can return first-consent profile data as `user`; do not relay it or
  // error descriptions. Optional display names never authorize an account.
  response.set('Location', `intent://callback?${fields.toString()}${ANDROID_RETURN}`);
  return response.status(302).send('');
}

module.exports = { appleOAuthCallback };
