"use strict";

(function exposeDeletionPage(root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  }
  if (root && root.document) {
    root.HangulSoriDeletionPage = api;
    const start = () => api.startBrowserPage(root);
    if (root.document.readyState === "loading") {
      root.document.addEventListener("DOMContentLoaded", start, { once: true });
    } else {
      start();
    }
  }
})(typeof globalThis === "object" ? globalThis : undefined, function createDeletionPage() {
  const FIRST_PARTY_ORIGIN = "https://hangul-sori.com";
  const CONSUMPTION_ENDPOINT =
    `${FIRST_PARTY_ORIGIN}/api/request-deletion-by-proof`;
  const PROOF_PATTERN = /^[A-Za-z0-9_-]{43}$/;

  function proofFromFragment(fragment) {
    if (typeof fragment !== "string" || !fragment.startsWith("#")) {
      return null;
    }
    const parameters = new URLSearchParams(fragment.slice(1));
    let parameterCount = 0;
    let tokenCount = 0;
    let proof = null;
    parameters.forEach((value, key) => {
      parameterCount += 1;
      if (key === "token") {
        tokenCount += 1;
        proof = value;
      }
    });
    if (parameterCount !== 1 || tokenCount !== 1) {
      return null;
    }
    return typeof proof === "string" && PROOF_PATTERN.test(proof)
      ? proof
      : null;
  }

  async function consumeDeletionProof({
    location,
    history,
    fetchImpl,
    renderStatus,
  }) {
    const fragment =
      location && typeof location.hash === "string" ? location.hash : "";
    const cleanPath =
      location &&
      typeof location.pathname === "string" &&
      location.pathname.startsWith("/")
        ? location.pathname
        : "/account-deletion.html";
    history.replaceState(null, "", cleanPath);

    const proof = proofFromFragment(fragment);
    if (!proof) {
      renderStatus("request-status");
      return;
    }

    try {
      await fetchImpl(CONSUMPTION_ENDPOINT, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ proof }),
        cache: "no-store",
        credentials: "omit",
        mode: "same-origin",
        redirect: "error",
        referrerPolicy: "no-referrer",
      });
    } catch {}
    renderStatus("request-status");
  }

  function renderBrowserStatus(document) {
    for (const element of document.querySelectorAll("[data-deletion-status]")) {
      const message = element.dataset.genericMessage;
      if (typeof message === "string") {
        element.textContent = message;
      }
      element.hidden = false;
      element.dataset.state = "request-status";
    }
  }

  function startBrowserPage(root) {
    return consumeDeletionProof({
      location: root.location,
      history: root.history,
      fetchImpl: root.fetch.bind(root),
      renderStatus: () => renderBrowserStatus(root.document),
    });
  }

  return Object.freeze({
    CONSUMPTION_ENDPOINT,
    consumeDeletionProof,
    proofFromFragment,
    startBrowserPage,
  });
});
