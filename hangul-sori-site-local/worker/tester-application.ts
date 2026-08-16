type EmailPayload = {
  to: string;
  from: string | { email: string; name?: string };
  replyTo?: string;
  subject: string;
  html: string;
  text: string;
};

export interface TesterApplicationEnv {
  TESTER_EMAIL?: { send(message: EmailPayload): Promise<unknown> };
  TESTER_RATE_LIMIT?: { limit(options: { key: string }): Promise<{ success: boolean }> };
}

const responseHeaders = {
  "cache-control": "no-store",
  "content-type": "application/json; charset=utf-8",
  "x-content-type-options": "nosniff",
};

const submissionHosts = new Set([
  "hangul-sori.com",
  "www.hangul-sori.com",
  "localhost",
  "127.0.0.1",
  "[::1]",
]);

const allowed = {
  locale: new Set<string>(["de", "en", "ko"]),
  platform: new Set<string>(["android", "ios"]),
  explanationLanguage: new Set<string>(["de", "en"]),
  koreanLevel: new Set<string>(["beginner", "hangul-learning", "hangul-reading", "basic-conversation", "intermediate-plus"]),
  focus: new Set<string>(["hangul-reading", "pronunciation-listening", "everyday-korean", "vocabulary-srs", "games-hanok"]),
} as const;

const platformLabels: Record<string, string> = {
  android: "Android",
  ios: "iPhone / iOS",
};

const languageLabels: Record<string, string> = {
  de: "German",
  en: "English",
};

const levelLabels: Record<string, string> = {
  beginner: "Complete beginner",
  "hangul-learning": "Learning Hangul",
  "hangul-reading": "Can read Hangul",
  "basic-conversation": "Basic conversation",
  "intermediate-plus": "Intermediate or above",
};

const focusLabels: Record<string, string> = {
  "hangul-reading": "Hangul & reading",
  "pronunciation-listening": "Pronunciation & listening",
  "everyday-korean": "Everyday Korean",
  "vocabulary-srs": "Vocabulary & SRS",
  "games-hanok": "Mini games & hanok progress",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: responseHeaders });
}

function stringField(value: unknown, maxLength: number) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function escapeHtml(value: string) {
  return value.replace(/[&<>'"]/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "'": "&#39;",
    '"': "&quot;",
  })[character] ?? character);
}

function sameOrigin(request: Request) {
  const origin = request.headers.get("origin");
  if (!origin) return false;
  try {
    return new URL(origin).host === new URL(request.url).host;
  } catch {
    return false;
  }
}

async function anonymousRateLimitKey(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function handleTesterApplication(request: Request, env: TesterApplicationEnv): Promise<Response> {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ ok: false, error: "method_not_allowed" }), {
      status: 405,
      headers: {
        ...responseHeaders,
        allow: "POST",
        "x-hangul-sori-email-binding": typeof env?.TESTER_EMAIL?.send === "function" ? "ready" : "missing",
        "x-hangul-sori-rate-limit-binding": typeof env?.TESTER_RATE_LIMIT?.limit === "function" ? "ready" : "missing",
      },
    });
  }

  const hostname = new URL(request.url).hostname.toLowerCase();
  if (!submissionHosts.has(hostname)) {
    return json({ ok: false, error: "not_found" }, 404);
  }

  if (
    request.headers.get("x-hangul-sori-form") !== "tester-application" ||
    !request.headers.get("content-type")?.toLowerCase().startsWith("application/json") ||
    !sameOrigin(request)
  ) {
    return json({ ok: false, error: "invalid_request" }, 403);
  }

  const emailBinding = env?.TESTER_EMAIL;
  const rateLimitBinding = env?.TESTER_RATE_LIMIT;
  const isProductionHost = hostname === "hangul-sori.com" || hostname === "www.hangul-sori.com";
  if (
    typeof emailBinding?.send !== "function" ||
    (isProductionHost && typeof rateLimitBinding?.limit !== "function")
  ) {
    return json({ ok: false, error: "service_unavailable" }, 503);
  }

  const contentLength = Number(request.headers.get("content-length") ?? 0);
  if (contentLength > 20_000) return json({ ok: false, error: "payload_too_large" }, 413);

  const raw = await request.text();
  if (raw.length > 20_000) return json({ ok: false, error: "payload_too_large" }, 413);

  let input: Record<string, unknown>;
  try {
    input = JSON.parse(raw) as Record<string, unknown>;
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }

  if (stringField(input.website, 200)) return json({ ok: true });

  const locale = stringField(input.locale, 2);
  const name = stringField(input.name, 80);
  const email = stringField(input.email, 254).toLowerCase();
  const platform = stringField(input.platform, 16);
  const device = stringField(input.device, 80);
  const osVersion = stringField(input.osVersion, 40);
  const explanationLanguage = stringField(input.explanationLanguage, 2);
  const koreanLevel = stringField(input.koreanLevel, 32);
  const notes = stringField(input.notes, 800);
  const focus = Array.isArray(input.focus)
    ? [...new Set(input.focus.map((item) => stringField(item, 40)).filter((item) => allowed.focus.has(item)))]
    : [];

  const isValid =
    allowed.locale.has(locale) &&
    name.length >= 2 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) &&
    allowed.platform.has(platform) &&
    allowed.explanationLanguage.has(explanationLanguage) &&
    allowed.koreanLevel.has(koreanLevel) &&
    focus.length > 0 &&
    input.ageConfirmed === true &&
    input.commitment === true &&
    input.privacyAcknowledged === true;

  if (!isValid) return json({ ok: false, error: "invalid_form" }, 400);

  if (rateLimitBinding) {
    const ip = request.headers.get("cf-connecting-ip") ?? "unavailable";
    const [emailLimit, ipLimit] = await Promise.all([
      rateLimitBinding.limit({ key: `email:${await anonymousRateLimitKey(email)}` }),
      rateLimitBinding.limit({ key: `ip:${await anonymousRateLimitKey(ip)}` }),
    ]);
    if (!emailLimit.success || !ipLimit.success) return json({ ok: false, error: "rate_limited" }, 429);
  }

  const submittedAt = new Date().toISOString();
  const focusText = focus.map((item) => focusLabels[item] ?? item).join(", ");
  const rows = [
    ["Name", name],
    ["Invitation email", email],
    ["Platform", platformLabels[platform] ?? platform],
    ["Device", device || "—"],
    ["OS version", osVersion || "—"],
    ["Explanation language", languageLabels[explanationLanguage] ?? explanationLanguage],
    ["Korean level", levelLabels[koreanLevel] ?? koreanLevel],
    ["Testing focus", focusText],
    ["Website language", locale.toUpperCase()],
    ["Submitted", submittedAt],
  ];

  const text = [
    "New Hangul Sori tester application",
    "",
    ...rows.map(([key, value]) => `${key}: ${value}`),
    "",
    `Notes: ${notes || "None"}`,
    "",
    "The applicant confirmed they are at least 16, can send brief feedback, and acknowledged the tester application privacy notice.",
  ].join("\n");

  const tableRows = rows.map(([key, value]) => `<tr><th style="padding:8px 12px;text-align:left;vertical-align:top;color:#5c6660;border-bottom:1px solid #e7e1d1">${escapeHtml(key)}</th><td style="padding:8px 12px;border-bottom:1px solid #e7e1d1">${escapeHtml(value)}</td></tr>`).join("");
  const html = `<div style="font-family:Arial,sans-serif;color:#1a1f1d;line-height:1.55"><h1 style="font-size:22px">New Hangul Sori tester application</h1><table style="width:100%;max-width:680px;border-collapse:collapse">${tableRows}</table><h2 style="margin-top:24px;font-size:16px">Notes</h2><p>${escapeHtml(notes || "None")}</p><p style="margin-top:24px;color:#5c6660;font-size:12px">The applicant confirmed they are at least 16, can send brief feedback, and acknowledged the tester application privacy notice.</p></div>`;

  try {
    await emailBinding.send({
      to: "vjinny2@gmail.com",
      from: { email: "website@hangul-sori.com", name: "Hangul Sori Website" },
      replyTo: email,
      subject: `Hangul Sori tester application · ${platformLabels[platform] ?? platform} · ${locale.toUpperCase()}`,
      html,
      text,
    });
  } catch (error) {
    console.error("tester-application-email-failed", error instanceof Error ? error.message : "unknown error");
    return json({ ok: false, error: "delivery_failed" }, 502);
  }

  return json({ ok: true }, 201);
}
