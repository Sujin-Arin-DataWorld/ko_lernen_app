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
    if (parameters.size !== 1 || parameters.getAll("token").length !== 1) {
      return null;
    }
    const proof = parameters.get("token");
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
    const fragment = typeof location?.hash === "string" ? location.hash : "";
    const cleanPath =
      typeof location?.pathname === "string" && location.pathname.startsWith("/")
        ? location.pathname
        : "/account-deletion.html";
    history.replaceState(null, "", cleanPath);

    const proof = proofFromFragment(fragment);
    if (!proof) {
      renderStatus("request-unavailable");
      return;
    }

    try {
      const response = await fetchImpl(CONSUMPTION_ENDPOINT, {
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
      renderStatus(
        response?.status === 202 ? "request-received" : "request-unavailable",
      );
    } catch {
      renderStatus("request-unavailable");
    }
  }

  function renderBrowserStatus(document, status) {
    const attribute =
      status === "request-received" ? "receivedMessage" : "unavailableMessage";
    for (const element of document.querySelectorAll("[data-deletion-status]")) {
      const message = element.dataset[attribute];
      if (typeof message === "string") {
        element.textContent = message;
      }
      element.hidden = false;
      element.dataset.state = status;
    }
  }

  function startBrowserPage(root) {
    return consumeDeletionProof({
      location: root.location,
      history: root.history,
      fetchImpl: root.fetch.bind(root),
      renderStatus: (status) => renderBrowserStatus(root.document, status),
    });
  }

  return Object.freeze({
    CONSUMPTION_ENDPOINT,
    consumeDeletionProof,
    proofFromFragment,
    startBrowserPage,
  });
});
