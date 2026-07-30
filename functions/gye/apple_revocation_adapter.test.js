"use strict";

const assert = require("node:assert/strict");
const {
  generateKeyPairSync,
  verify,
} = require("node:crypto");
const test = require("node:test");

const {
  createAppleRevocationAdapter,
} = require("./apple_revocation_adapter");

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";
const NOW_SECONDS = 1_800_000_000;

function decodeJsonSegment(segment) {
  return JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));
}

function testSecrets(privateKey) {
  return {
    getClientId: () => "com.example.hangulsori",
    getTeamId: () => "TEAMID1234",
    getKeyId: () => "KEYID12345",
    getPrivateKey: () => privateKey,
  };
}

function errorText(error) {
  return JSON.stringify({
    name: error?.name,
    message: error?.message,
    code: error?.code,
    stack: error?.stack,
  });
}

test("exchanges the transient code then revokes the returned refresh token",
async () => {
  const { privateKey, publicKey } = generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });
  const calls = [];
  const revoke = createAppleRevocationAdapter({
    ...testSecrets(privateKey.export({
      format: "pem",
      type: "pkcs8",
    })),
    fetch: async (url, options) => {
      calls.push({ url, options });
      if (url === APPLE_TOKEN_URL) {
        return {
          status: 200,
          async json() {
            return {
              access_token: "transient-access-token",
              refresh_token: "transient-refresh-token",
              token_type: "Bearer",
              expires_in: 3600,
            };
          },
        };
      }
      return { status: 200 };
    },
    nowSeconds: () => NOW_SECONDS,
  });

  await revoke({ authorizationCode: "one-time-code" });

  assert.equal(calls.length, 2);
  assert.equal(calls[0].url, APPLE_TOKEN_URL);
  assert.equal(calls[0].options.method, "POST");
  assert.equal(calls[0].options.redirect, "error");
  assert.equal(calls[0].options.signal instanceof AbortSignal, true);
  assert.deepEqual(calls[0].options.headers, {
    "content-type": "application/x-www-form-urlencoded",
  });

  const exchangeForm = new URLSearchParams(calls[0].options.body);
  assert.equal(exchangeForm.get("client_id"), "com.example.hangulsori");
  assert.equal(exchangeForm.get("code"), "one-time-code");
  assert.equal(exchangeForm.get("grant_type"), "authorization_code");
  assert.equal(Array.from(exchangeForm.keys()).length, 4);

  const jwt = exchangeForm.get("client_secret");
  const segments = jwt.split(".");
  assert.equal(segments.length, 3);
  assert.deepEqual(decodeJsonSegment(segments[0]), {
    alg: "ES256",
    kid: "KEYID12345",
  });
  assert.deepEqual(decodeJsonSegment(segments[1]), {
    iss: "TEAMID1234",
    iat: NOW_SECONDS,
    exp: NOW_SECONDS + 300,
    aud: "https://appleid.apple.com",
    sub: "com.example.hangulsori",
  });
  assert.equal(
    verify(
      "sha256",
      Buffer.from(`${segments[0]}.${segments[1]}`, "utf8"),
      {
        key: publicKey,
        dsaEncoding: "ieee-p1363",
      },
      Buffer.from(segments[2], "base64url"),
    ),
    true,
  );

  assert.equal(calls[1].url, APPLE_REVOKE_URL);
  assert.equal(calls[1].options.method, "POST");
  assert.equal(calls[1].options.redirect, "error");
  assert.equal(calls[1].options.signal instanceof AbortSignal, true);
  assert.deepEqual(calls[1].options.headers, {
    "content-type": "application/x-www-form-urlencoded",
  });
  const revokeForm = new URLSearchParams(calls[1].options.body);
  assert.equal(revokeForm.get("client_id"), "com.example.hangulsori");
  assert.equal(revokeForm.get("client_secret"), jwt);
  assert.equal(revokeForm.get("token"), "transient-refresh-token");
  assert.equal(revokeForm.get("token_type_hint"), "refresh_token");
  assert.equal(revokeForm.has("code"), false);
  assert.equal(revokeForm.toString().includes("one-time-code"), false);
  assert.equal(Array.from(revokeForm.keys()).length, 4);
});

test("invalid secret material fails with a stable redacted code", async () => {
  const rawCode = "never-log-or-return-me";
  const revoke = createAppleRevocationAdapter({
    ...testSecrets("not-a-private-key"),
    fetch: async () => {
      throw new Error("must not fetch");
    },
    nowSeconds: () => NOW_SECONDS,
  });

  await assert.rejects(
    () => revoke({ authorizationCode: rawCode }),
    (error) => {
      assert.equal(error.code, "apple/revocation-config-invalid");
      assert.equal(errorText(error).includes(rawCode), false);
      assert.equal(errorText(error).includes("not-a-private-key"), false);
      return true;
    },
  );
});

test("provider and network failures expose only allowlisted generic codes",
async (t) => {
  const { privateKey } = generateKeyPairSync("ec", {
    namedCurve: "prime256v1",
  });
  const secrets = testSecrets(privateKey.export({
    format: "pem",
    type: "pkcs8",
  }));
  const rawCode = "private-one-time-code";
  const rawProviderBody = "provider-private-diagnostic";

  await t.test("token exchange non-200 response", async () => {
    const revoke = createAppleRevocationAdapter({
      ...secrets,
      fetch: async () => ({
        status: 400,
        async text() {
          throw new Error("response body must not be read");
        },
        rawProviderBody,
      }),
      nowSeconds: () => NOW_SECONDS,
    });
    await assert.rejects(
      () => revoke({ authorizationCode: rawCode }),
      (error) => {
        assert.equal(error.code, "apple/revocation-provider-failed");
        assert.equal(errorText(error).includes(rawCode), false);
        assert.equal(errorText(error).includes(rawProviderBody), false);
        return true;
      },
    );
  });

  await t.test("token exchange network exception", async () => {
    const revoke = createAppleRevocationAdapter({
      ...secrets,
      fetch: async () => {
        throw new Error(`${rawProviderBody}: ${rawCode}`);
      },
      nowSeconds: () => NOW_SECONDS,
    });
    await assert.rejects(
      () => revoke({ authorizationCode: rawCode }),
      (error) => {
        assert.equal(error.code, "apple/revocation-network-failed");
        assert.equal(errorText(error).includes(rawCode), false);
        assert.equal(errorText(error).includes(rawProviderBody), false);
        return true;
      },
    );
  });

  await t.test("malformed token response", async () => {
    const revoke = createAppleRevocationAdapter({
      ...secrets,
      fetch: async () => ({
        status: 200,
        async json() {
          return { refresh_token: `${rawProviderBody}\n` };
        },
      }),
      nowSeconds: () => NOW_SECONDS,
    });
    await assert.rejects(
      () => revoke({ authorizationCode: rawCode }),
      (error) => {
        assert.equal(error.code, "apple/revocation-response-invalid");
        assert.equal(errorText(error).includes(rawCode), false);
        assert.equal(errorText(error).includes(rawProviderBody), false);
        return true;
      },
    );
  });

  await t.test("revoke non-200 response", async () => {
    let requestCount = 0;
    const revoke = createAppleRevocationAdapter({
      ...secrets,
      fetch: async () => {
        requestCount += 1;
        if (requestCount === 1) {
          return {
            status: 200,
            async json() {
              return { refresh_token: "exchange-refresh-token" };
            },
          };
        }
        return {
          status: 400,
          async text() {
            throw new Error("response body must not be read");
          },
        };
      },
      nowSeconds: () => NOW_SECONDS,
    });
    await assert.rejects(
      () => revoke({ authorizationCode: rawCode }),
      (error) => {
        assert.equal(error.code, "apple/revocation-provider-failed");
        assert.equal(errorText(error).includes(rawCode), false);
        assert.equal(errorText(error).includes("exchange-refresh-token"), false);
        return true;
      },
    );
  });

  await t.test("revoke network exception", async () => {
    const refreshToken = "network-private-refresh-token";
    let requestCount = 0;
    const revoke = createAppleRevocationAdapter({
      ...secrets,
      fetch: async () => {
        requestCount += 1;
        if (requestCount === 1) {
          return {
            status: 200,
            async json() {
              return { refresh_token: refreshToken };
            },
          };
        }
        throw new Error(`${rawCode}:${refreshToken}:${rawProviderBody}`);
      },
      nowSeconds: () => NOW_SECONDS,
    });
    await assert.rejects(
      () => revoke({ authorizationCode: rawCode }),
      (error) => {
        assert.equal(error.code, "apple/revocation-network-failed");
        assert.equal(errorText(error).includes(rawCode), false);
        assert.equal(errorText(error).includes(refreshToken), false);
        assert.equal(errorText(error).includes(rawProviderBody), false);
        return true;
      },
    );
  });
});

test("rejects invalid transient input before requesting secrets or network",
async () => {
  let secretReads = 0;
  let fetches = 0;
  const getSecret = () => {
    secretReads += 1;
    return "unreachable";
  };
  const revoke = createAppleRevocationAdapter({
    getClientId: getSecret,
    getTeamId: getSecret,
    getKeyId: getSecret,
    getPrivateKey: getSecret,
    fetch: async () => {
      fetches += 1;
      return { status: 200 };
    },
  });

  await assert.rejects(
    () => revoke({ authorizationCode: "line\nbreak" }),
    (error) => error?.code === "apple/revocation-input-invalid",
  );
  assert.equal(secretReads, 0);
  assert.equal(fetches, 0);
});
