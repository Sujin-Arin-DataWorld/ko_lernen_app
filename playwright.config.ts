import { defineConfig, devices } from '@playwright/test';
import { execFileSync } from 'node:child_process';

const appBaseUrl = 'http://127.0.0.1:4173';
const phoneViewport = { width: 390, height: 844 };
const wideViewport = { width: 1440, height: 960 };
const gitSha =
  process.env.GITHUB_SHA ??
  execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: true,
  retries: 0,
  timeout: 45_000,
  metadata: { gitSha },
  reporter: [['line'], ['html', { open: 'never' }]],
  use: {
    baseURL: appBaseUrl,
    serviceWorkers: 'block',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium-phone',
      use: { ...devices['Desktop Chrome'], viewport: phoneViewport },
    },
    {
      name: 'chromium-wide',
      use: { ...devices['Desktop Chrome'], viewport: wideViewport },
    },
    {
      name: 'firefox-phone',
      use: {
        ...devices['Desktop Firefox'],
        viewport: phoneViewport,
      },
    },
    {
      name: 'firefox-wide',
      use: { ...devices['Desktop Firefox'], viewport: wideViewport },
    },
    {
      name: 'webkit-phone',
      use: {
        ...devices['Desktop Safari'],
        viewport: phoneViewport,
      },
    },
    {
      name: 'webkit-wide',
      use: { ...devices['Desktop Safari'], viewport: wideViewport },
    },
  ],
  webServer: {
    command:
      'flutter build web --release --no-web-resources-cdn && python -m http.server 4173 --bind 127.0.0.1 --directory build/web',
    url: `${appBaseUrl}/`,
    reuseExistingServer: false,
    // Includes the full release build; separate from the browser's 30s boot budget.
    timeout: 600_000,
  },
});
