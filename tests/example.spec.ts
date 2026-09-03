import { expect, test, type Locator, type Page, type TestInfo } from '@playwright/test';

const appOrigin = 'http://127.0.0.1:4173';
const expectedBlockedHosts = new Set([
  'accounts.google.com',
  'analytics.google.com',
  'api.revenuecat.com',
  'app-measurement.com',
  'firebase.googleapis.com',
  'firestore.googleapis.com',
  'fonts.gstatic.com',
  'identitytoolkit.googleapis.com',
  'securetoken.googleapis.com',
  'www.google-analytics.com',
]);

function hostOf(url: string): string | undefined {
  try {
    return new URL(url).hostname;
  } catch {
    return undefined;
  }
}

function isLocalApplicationResource(url: string): boolean {
  try {
    return new URL(url).origin === appOrigin;
  } catch {
    return false;
  }
}

type PaintRegion = { label: string; locator: Locator };
type ContrastCounts = {
  label: string;
  opaquePixels: number;
  darkPixels: number;
  lightPixels: number;
};

async function expectRegionsToBePainted(
  page: Page,
  testInfo: TestInfo,
  regions: ReadonlyArray<PaintRegion>,
  elapsedBootMs: () => number,
  remainingBootTimeout: (phase: string) => number,
): Promise<void> {
  const attempts: Array<{ elapsedBootMs: number; regions: ContrastCounts[] }> = [];
  let finalScreenshot: Buffer | undefined;
  let finalContrastCounts: ContrastCounts[] | undefined;

  try {
    while (true) {
      remainingBootTimeout('Consent paint capture');
      const boxes = await Promise.all(
        regions.map(async ({ label, locator }) => {
          const box = await locator.boundingBox();
          if (box === null) {
            throw new Error(`Cannot inspect painted ${label}: semantic box is absent.`);
          }
          if (
            !Number.isFinite(box.x) ||
            !Number.isFinite(box.y) ||
            !Number.isFinite(box.width) ||
            !Number.isFinite(box.height) ||
            box.width <= 0 ||
            box.height <= 0
          ) {
            throw new Error(`Cannot inspect painted ${label}: semantic box is invalid.`);
          }
          return { label, ...box };
        }),
      );
      const screenshot = await page.screenshot({ type: 'png', scale: 'css' });
      finalScreenshot = screenshot;
      const contrastCounts = await page.evaluate(
        async ({ encodedScreenshot, boxes }) => {
          const image = new Image();
          image.src = `data:image/png;base64,${encodedScreenshot}`;
          await image.decode();

          const canvas = document.createElement('canvas');
          canvas.width = image.naturalWidth;
          canvas.height = image.naturalHeight;
          const context = canvas.getContext('2d', { willReadFrequently: true });
          if (context === null) {
            throw new Error('Cannot inspect the captured Consent frame.');
          }
          context.drawImage(image, 0, 0);

          return boxes.map((box) => {
            const left = Math.max(0, Math.floor(box.x));
            const top = Math.max(0, Math.floor(box.y));
            const right = Math.min(canvas.width, Math.ceil(box.x + box.width));
            const bottom = Math.min(canvas.height, Math.ceil(box.y + box.height));
            if (right <= left || bottom <= top) {
              throw new Error(`Cannot inspect painted ${box.label}: crop is off-screen.`);
            }
            const pixels = context.getImageData(left, top, right - left, bottom - top).data;
            let opaquePixels = 0;
            let darkPixels = 0;
            let lightPixels = 0;
            for (let index = 0; index < pixels.length; index += 4) {
              if (pixels[index + 3] < 250) {
                continue;
              }
              opaquePixels += 1;
              const luminance =
                0.2126 * pixels[index] +
                0.7152 * pixels[index + 1] +
                0.0722 * pixels[index + 2];
              if (luminance <= 130) {
                darkPixels += 1;
              }
              if (luminance >= 220) {
                lightPixels += 1;
              }
            }
            return { label: box.label, opaquePixels, darkPixels, lightPixels };
          });
        },
        { encodedScreenshot: screenshot.toString('base64'), boxes },
      );
      finalContrastCounts = contrastCounts;
      attempts.push({ elapsedBootMs: elapsedBootMs(), regions: contrastCounts });

      for (const { label, opaquePixels } of contrastCounts) {
        if (opaquePixels <= 50) {
          throw new Error(`${label} crop must contain opaque pixels.`);
        }
      }
      if (
        contrastCounts.every(
          ({ darkPixels, lightPixels }) => darkPixels > 50 && lightPixels > 50,
        )
      ) {
        remainingBootTimeout('Consent paint verification');
        return;
      }

      await page.waitForTimeout(
        Math.min(250, remainingBootTimeout('Consent paint readiness')),
      );
    }
  } finally {
    if (finalScreenshot !== undefined) {
      await testInfo.attach('consent-painted-frame', {
        body: finalScreenshot,
        contentType: 'image/png',
      });
    }
    await testInfo.attach('consent-painted-contrast', {
      body: JSON.stringify({ attempts, final: finalContrastCounts }),
      contentType: 'application/json',
    });
  }
}

test('boots the release consent screen without production network access', async ({
  context,
  page,
}, testInfo) => {
  const expectedBlockedRequests: string[] = [];
  const expectedBlockedRequestUrls: string[] = [];
  const expectedBlockedConsoleDiagnostics: Array<{
    browser: string;
    message: string;
    request: string;
  }> = [];
  const expectedBlockedConsoleRequestIndexes = new Set<number>();
  const unexpectedBlockedRequests: string[] = [];
  const expectedBlockedWebSockets: string[] = [];
  const unexpectedBlockedWebSockets: string[] = [];
  const actualNonLocalResponses: string[] = [];
  const consoleErrors: string[] = [];
  const pageErrors: string[] = [];
  const bootStartedAt = performance.now();
  const bootBudgetMs = 30_000;
  const readiness = {
    navigationCompletedMs: null as number | null,
    accessibilityTriggerVisibleMs: null as number | null,
    accessibilityActivationCompletedMs: null as number | null,
    consentHeadingVisibleMs: null as number | null,
    consentPaintCapturedMs: null as number | null,
  };
  const elapsedBootMs = () => Math.round(performance.now() - bootStartedAt);
  const remainingBootTimeout = (phase: string) => {
    const remaining = bootBudgetMs - elapsedBootMs();
    if (remaining <= 0) {
      throw new Error(
        `Release boot deadline of ${bootBudgetMs}ms elapsed before ${phase}.`,
      );
    }
    return remaining;
  };

  // A test failure here catches a production request added to release boot.
  // Only generated application resources from this exact local origin run.
  await context.route('**/*', async (route) => {
    const request = route.request();
    const url = request.url();
    if (url.startsWith('blob:') || url.startsWith('data:')) {
      await route.continue();
      return;
    }

    if (isLocalApplicationResource(url)) {
      await route.continue();
      return;
    }

    const requestLabel = `${request.method()} ${hostOf(url) ?? url}`;
    if (expectedBlockedHosts.has(hostOf(url) ?? '')) {
      expectedBlockedRequests.push(requestLabel);
      expectedBlockedRequestUrls.push(url);
    } else {
      unexpectedBlockedRequests.push(requestLabel);
    }
    await route.abort('blockedbyclient');
  });
  await context.routeWebSocket('**/*', async (webSocket) => {
    const host = hostOf(webSocket.url());
    const socketLabel = `WS ${host ?? webSocket.url()}`;
    if (expectedBlockedHosts.has(host ?? '')) {
      expectedBlockedWebSockets.push(socketLabel);
    } else {
      unexpectedBlockedWebSockets.push(socketLabel);
    }
    await webSocket.close({ code: 1008, reason: 'Blocked by release test' });
  });
  page.on('console', (message) => {
    if (message.type() !== 'error') {
      return;
    }
    const diagnostic = message.text();
    const chromiumBlockedByClient =
      diagnostic === 'Failed to load resource: net::ERR_BLOCKED_BY_CLIENT.Inspector';
    const requestIndex = chromiumBlockedByClient
      ? expectedBlockedRequestUrls.findIndex(
          (_, index) => !expectedBlockedConsoleRequestIndexes.has(index),
        )
      : testInfo.project.name.startsWith('firefox')
        ? expectedBlockedRequestUrls.findIndex(
            (url, index) =>
              !expectedBlockedConsoleRequestIndexes.has(index) &&
              diagnostic ===
                `[JavaScript Error: "Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at ${url}. (Reason: CORS request did not succeed). Status code: (null)."]`,
          )
        : -1;
    if (requestIndex >= 0) {
      expectedBlockedConsoleRequestIndexes.add(requestIndex);
      // Chromium has a single exact diagnostic without a URL. Firefox is accepted
      // only for its complete generated diagnostic containing the intercepted URL.
      // An application error that merely embeds this text remains a test failure.
      expectedBlockedConsoleDiagnostics.push(
        {
          browser: testInfo.project.name,
          message: diagnostic,
          request: expectedBlockedRequests[requestIndex],
        },
      );
    } else {
      consoleErrors.push(message.text());
    }
  });
  page.on('pageerror', (error) => pageErrors.push(error.message));
  page.on('response', (response) => {
    if (!isLocalApplicationResource(response.url())) {
      actualNonLocalResponses.push(
        `${response.request().method()} ${hostOf(response.url()) ?? response.url()}`,
      );
    }
  });

  testInfo.annotations.push({
    type: 'git-sha',
    description: String(testInfo.config.metadata.gitSha),
  });

  // Observe browser primitives before the production document executes. The
  // release app must not use an automation-only scheduler or fake visibility.
  await page.addInitScript(() => {
    const originalRequest = window.requestAnimationFrame;
    const originalCancel = window.cancelAnimationFrame;
    Object.defineProperty(window, '__hangulSoriBootEnvironment', {
      value: () => ({
        requestAnimationFramePreserved: window.requestAnimationFrame === originalRequest,
        cancelAnimationFramePreserved: window.cancelAnimationFrame === originalCancel,
        visibilityStatePreserved: !Object.prototype.hasOwnProperty.call(document, 'visibilityState'),
        hiddenPreserved: !Object.prototype.hasOwnProperty.call(document, 'hidden'),
      }),
    });
  });

  try {
    const response = await page.goto('/', {
      waitUntil: 'domcontentloaded',
      timeout: remainingBootTimeout('navigation'),
    });
    readiness.navigationCompletedMs = elapsedBootMs();

    expect(response?.ok()).toBeTruthy();
    const enableAccessibility = page.getByRole('button', {
      name: 'Enable accessibility',
    });
    await expect(enableAccessibility).toBeVisible({
      timeout: remainingBootTimeout('the accessibility trigger'),
    });
    readiness.accessibilityTriggerVisibleMs = elapsedBootMs();
    // The trigger starts outside the Flutter canvas in several browser engines.
    // Dispatch its documented activation event without substituting app logic.
    await enableAccessibility.dispatchEvent('click', undefined, {
      timeout: remainingBootTimeout('accessibility activation'),
    });
    readiness.accessibilityActivationCompletedMs = elapsedBootMs();

    const consentHeading = page.getByRole('heading', {
      name: 'Welcome to Hangul Sori',
      exact: true,
    });
    await expect(consentHeading).toBeVisible({
      timeout: remainingBootTimeout('the Consent screen'),
    });
    readiness.consentHeadingVisibleMs = elapsedBootMs();
    const bootEnvironment = await page.evaluate(() => {
      const readEnvironment = Reflect.get(window, '__hangulSoriBootEnvironment') as
        () => Record<string, boolean>;
      return readEnvironment();
    });
    await testInfo.attach('release-boot-environment', {
      body: JSON.stringify(bootEnvironment),
      contentType: 'application/json',
    });
    expect(bootEnvironment).toEqual({
      requestAnimationFramePreserved: true,
      cancelAnimationFramePreserved: true,
      visibilityStatePreserved: true,
      hiddenPreserved: true,
    });
    await expect(page.getByRole('button', { name: 'Privacy policy' })).toBeEnabled();
    await expect(
      page.getByRole('button', { name: 'Terms of service' }),
    ).toBeEnabled();
    const viewDemo = page.getByRole('button', { name: 'View demo' });
    await expect(viewDemo).toBeEnabled();
    await expectRegionsToBePainted(
      page,
      testInfo,
      [
        { label: 'Consent heading', locator: consentHeading },
        { label: 'View demo button', locator: viewDemo },
      ],
      elapsedBootMs,
      remainingBootTimeout,
    );
    readiness.consentPaintCapturedMs = elapsedBootMs();
    await viewDemo.click();
    await expect(
      page.getByRole('heading', {
        name: /Explore Hangul Sori/,
      }),
    ).toBeVisible();

    expect(actualNonLocalResponses).toEqual([]);
    expect(unexpectedBlockedRequests).toEqual([]);
    expect(unexpectedBlockedWebSockets).toEqual([]);
    expect(consoleErrors).toEqual([]);
    expect(pageErrors).toEqual([]);
  } finally {
    await testInfo.attach('release-boot-network-audit', {
      body: JSON.stringify({
        gitSha: String(testInfo.config.metadata.gitSha),
        browser: testInfo.project.name,
        readiness: {
          budgetMs: bootBudgetMs,
          elapsedAtAuditMs: elapsedBootMs(),
          ...readiness,
        },
        expectedAborts: expectedBlockedRequests,
        expectedBlockedConsoleDiagnostics,
        expectedBlockedWebSockets,
        unexpectedBlockedRequests,
        unexpectedBlockedWebSockets,
        actualNonLocalResponses,
        consoleErrors,
        pageErrors,
      }),
      contentType: 'application/json',
    });
  }
});
