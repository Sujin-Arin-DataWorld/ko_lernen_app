/** Cloudflare Worker entry point for the vinext-starter template. */
import { handleImageOptimization, DEFAULT_DEVICE_SIZES, DEFAULT_IMAGE_SIZES } from "vinext/server/image-optimization";
import handler from "vinext/server/app-router-entry";
import { handleTesterApplication, type TesterApplicationEnv } from "./tester-application";

declare const __HANGUL_SORI_RELEASE_ID__: string;

interface AssetFetcher {
  fetch(request: Request): Promise<Response>;
}

interface Env extends TesterApplicationEnv {
  ASSETS: AssetFetcher;
  IMAGES: {
    input(stream: ReadableStream): {
      transform(options: Record<string, unknown>): {
        output(options: { format: string; quality: number }): Promise<{ response(): Response }>;
      };
    };
  };
}

interface ExecutionContext {
  waitUntil(promise: Promise<unknown>): void;
  passThroughOnException(): void;
}

function createNonce() {
  const bytes = crypto.getRandomValues(new Uint8Array(18));
  return btoa(String.fromCharCode(...bytes));
}

function contentSecurityPolicy(nonce: string) {
  return [
    "default-src 'self'",
    "base-uri 'none'",
    "object-src 'none'",
    "frame-ancestors 'none'",
    "form-action 'self'",
    `script-src 'nonce-${nonce}' 'strict-dynamic' 'self' https://consent.cookiebot.com https://consent.cookiebot.eu https://www.googletagmanager.com`,
    "style-src 'self' 'unsafe-inline' https://consentcdn.cookiebot.com https://consentcdn.cookiebot.eu",
    "font-src 'self' data:",
    "img-src 'self' data: https://imgsct.cookiebot.com https://imgsct.cookiebot.eu https://consentcdn.cookiebot.com https://consentcdn.cookiebot.eu https://*.google-analytics.com",
    "media-src 'self'",
    "frame-src https://consentcdn.cookiebot.com https://consentcdn.cookiebot.eu",
    "connect-src 'self' https://consent.cookiebot.com https://consent.cookiebot.eu https://consentcdn.cookiebot.com https://consentcdn.cookiebot.eu https://*.google-analytics.com https://*.analytics.google.com",
    "worker-src 'self' blob:",
    "upgrade-insecure-requests",
  ].join("; ");
}

async function withSecurityHeaders(response: Response, url: URL) {
  const headers = new Headers(response.headers);
  headers.set("x-hangul-sori-release", __HANGUL_SORI_RELEASE_ID__);
  headers.set("x-content-type-options", "nosniff");
  headers.set("x-frame-options", "DENY");
  headers.set("referrer-policy", "no-referrer");
  headers.set("permissions-policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()");
  headers.set("cross-origin-opener-policy", "same-origin");

  const isLocal = url.hostname === "localhost" || url.hostname === "127.0.0.1";
  let body: BodyInit | null = response.body;
  if (!isLocal) {
    const nonce = createNonce();
    headers.set("content-security-policy", contentSecurityPolicy(nonce));
    if (url.protocol === "https:") {
      headers.set("strict-transport-security", "max-age=63072000; includeSubDomains");
    }
    if (headers.get("content-type")?.toLowerCase().startsWith("text/html")) {
      const html = await response.text();
      body = html.replace(/<script(?=\s|>)/g, `<script nonce="${nonce}"`);
      headers.delete("content-length");
      headers.delete("content-encoding");
    }
  }

  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

// Image security config. SVG sources with .svg extension auto-skip the
// optimization endpoint on the client side (served directly, no proxy).
// To route SVGs through the optimizer (with security headers), set
// dangerouslyAllowSVG: true in next.config.js and uncomment below:
// const imageConfig: ImageConfig = { dangerouslyAllowSVG: true };

const worker = {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/api/tester-application") {
      return withSecurityHeaders(await handleTesterApplication(request, env), url);
    }

    if (url.pathname === "/_vinext/image") {
      const allowedWidths = [...DEFAULT_DEVICE_SIZES, ...DEFAULT_IMAGE_SIZES];
      return withSecurityHeaders(await handleImageOptimization(request, {
        fetchAsset: (path) => env.ASSETS.fetch(new Request(new URL(path, request.url))),
        transformImage: async (body, { width, format, quality }) => {
          const result = await env.IMAGES.input(body).transform(width > 0 ? { width } : {}).output({ format, quality });
          return result.response();
        },
      }, allowedWidths), url);
    }

    const appResponse = await handler.fetch(request, env, ctx);
    if (appResponse.status === 404) {
      const headers = new Headers(appResponse.headers);
      headers.set("content-type", "text/plain; charset=UTF-8");
      headers.delete("content-length");
      headers.delete("content-encoding");
      return withSecurityHeaders(new Response("Not Found", { status: 404, headers }), url);
    }

    return withSecurityHeaders(appResponse, url);
  },
};

export default worker;
