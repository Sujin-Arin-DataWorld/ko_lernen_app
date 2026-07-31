"use strict";

const {
  createPrivateKey,
  sign,
} = require("node:crypto");

const APPLE_AUDIENCE = "https://appleid.apple.com";
const APPLE_TOKEN_URL = `${APPLE_AUDIENCE}/auth/token`;
const APPLE_REVOKE_URL = `${APPLE_AUDIENCE}/auth/revoke`;
const CLIENT_SECRET_LIFETIME_SECONDS = 300;
const APPLE_REQUEST_TIMEOUT_MILLIS = 15000;
const MAX_AUTHORIZATION_CODE_LENGTH = 4096;
const MAX_PROVIDER_TOKEN_LENGTH = 16384;
const MAX_PRIVATE_KEY_LENGTH = 32768;
const SAFE_ERROR_MESSAGE = "Apple authorization revocation failed.";

class AppleRevocationError extends Error {
  constructor(code) {
    super(SAFE_ERROR_MESSAGE);
    this.name = "AppleRevocationError";
    this.code = code;
  }
}

function fail(code) {
  throw new AppleRevocationError(code);
}

function isBoundedString(value, maxLength) {
  return typeof value === "string" &&
    value.length > 0 &&
    value.length <= maxLength;
}

function requiredAuthorizationCode(value) {
  if (!isBoundedString(value, MAX_AUTHORIZATION_CODE_LENGTH) ||
      value.trim() !== value ||
      /[\u0000-\u001f\u007f]/u.test(value)) {
    fail("apple/revocation-input-invalid");
  }
  return value;
}

function requiredProviderToken(value) {
  if (!isBoundedString(value, MAX_PROVIDER_TOKEN_LENGTH) ||
      value.trim() !== value ||
      /[\u0000-\u0020\u007f]/u.test(value)) {
    fail("apple/revocation-response-invalid");
  }
  return value;
}

function requiredClientId(value) {
  if (!isBoundedString(value, 255) ||
      !/^[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$/u.test(value)) {
    fail("apple/revocation-config-invalid");
  }
  return value;
}

function requiredAppleIdentifier(value) {
  if (typeof value !== "string" ||
      !/^[A-Z0-9]{10}$/u.test(value)) {
    fail("apple/revocation-config-invalid");
  }
  return value;
}

function requiredPrivateKey(value) {
  if (!isBoundedString(value, MAX_PRIVATE_KEY_LENGTH)) {
    fail("apple/revocation-config-invalid");
  }
  let key;
  try {
    key = createPrivateKey(value);
  } catch {
    fail("apple/revocation-config-invalid");
  }
  if (key.asymmetricKeyType !== "ec" ||
      key.asymmetricKeyDetails?.namedCurve !== "prime256v1") {
    fail("apple/revocation-config-invalid");
  }
  return key;
}

function requiredNowSeconds(value) {
  if (!Number.isSafeInteger(value) || value < 0) {
    fail("apple/revocation-config-invalid");
  }
  return value;
}

function encodeJson(value) {
  return Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
}

function createClientSecret({
  clientId,
  teamId,
  keyId,
  privateKey,
  issuedAt,
}) {
  const header = encodeJson({
    alg: "ES256",
    kid: keyId,
  });
  const payload = encodeJson({
    iss: teamId,
    iat: issuedAt,
    exp: issuedAt + CLIENT_SECRET_LIFETIME_SECONDS,
    aud: APPLE_AUDIENCE,
    sub: clientId,
  });
  const signingInput = `${header}.${payload}`;
  let signature;
  try {
    signature = sign(
      "sha256",
      Buffer.from(signingInput, "utf8"),
      {
        key: privateKey,
        dsaEncoding: "ieee-p1363",
      },
    ).toString("base64url");
  } catch {
    fail("apple/revocation-config-invalid");
  }
  return `${signingInput}.${signature}`;
}

function createAppleRevocationAdapter({
  getClientId,
  getTeamId,
  getKeyId,
  getPrivateKey,
  fetch = globalThis.fetch,
  nowSeconds = () => Math.floor(Date.now() / 1000),
} = {}) {
  if (typeof getClientId !== "function" ||
      typeof getTeamId !== "function" ||
      typeof getKeyId !== "function" ||
      typeof getPrivateKey !== "function" ||
      typeof fetch !== "function" ||
      typeof nowSeconds !== "function") {
    throw new TypeError("Apple revocation adapter dependencies are required.");
  }

  const postForm = async (url, fields) => {
    let response;
    try {
      response = await fetch(url, {
        method: "POST",
        redirect: "error",
        signal: AbortSignal.timeout(APPLE_REQUEST_TIMEOUT_MILLIS),
        headers: {
          "content-type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams(fields).toString(),
      });
    } catch {
      fail("apple/revocation-network-failed");
    }
    let status;
    try {
      status = response?.status;
    } catch {
      fail("apple/revocation-response-invalid");
    }
    if (!Number.isInteger(status) ||
        status < 100 ||
        status > 599) {
      fail("apple/revocation-response-invalid");
    }
    if (status !== 200) {
      fail("apple/revocation-provider-failed");
    }
    return response;
  };

  return async function revokeAppleAuthorizationCode({
    authorizationCode,
  } = {}) {
    const transientCode = requiredAuthorizationCode(authorizationCode);
    let clientId;
    let teamId;
    let keyId;
    let privateKey;
    let issuedAt;
    try {
      clientId = requiredClientId(getClientId());
      teamId = requiredAppleIdentifier(getTeamId());
      keyId = requiredAppleIdentifier(getKeyId());
      privateKey = requiredPrivateKey(getPrivateKey());
      issuedAt = requiredNowSeconds(nowSeconds());
    } catch (error) {
      if (error instanceof AppleRevocationError) throw error;
      fail("apple/revocation-config-invalid");
    }

    const clientSecret = createClientSecret({
      clientId,
      teamId,
      keyId,
      privateKey,
      issuedAt,
    });
    const exchangeResponse = await postForm(APPLE_TOKEN_URL, {
      client_id: clientId,
      client_secret: clientSecret,
      code: transientCode,
      grant_type: "authorization_code",
    });
    let tokenResponse;
    try {
      tokenResponse = await exchangeResponse.json();
    } catch {
      fail("apple/revocation-response-invalid");
    }
    let refreshToken;
    try {
      refreshToken = requiredProviderToken(tokenResponse?.refresh_token);
    } catch {
      fail("apple/revocation-response-invalid");
    }
    await postForm(APPLE_REVOKE_URL, {
      client_id: clientId,
      client_secret: clientSecret,
      token: refreshToken,
      token_type_hint: "refresh_token",
    });
  };
}

module.exports = {
  APPLE_REVOKE_URL,
  APPLE_TOKEN_URL,
  AppleRevocationError,
  createAppleRevocationAdapter,
};
