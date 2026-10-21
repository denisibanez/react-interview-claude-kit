# Playwright (e2e + visual)

```ts
// playwright.config.ts (only if missing)
import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? 'github' : 'list',
  use: { baseURL: 'http://localhost:3000', trace: 'on-first-retry' },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: { command: 'pnpm dev', url: 'http://localhost:3000', reuseExistingServer: !process.env.CI },
});
```
```ts
// e2e/search.spec.ts
import { test, expect } from '@playwright/test';

test('user searches and opens a product', async ({ page }) => {
  await page.goto('/products');
  await page.getByRole('searchbox', { name: /search/i }).fill('chair');
  await expect(page).toHaveURL(/q=chair/);
  await page.getByRole('link', { name: /chair/i }).first().click();
  await expect(page.getByRole('heading', { level: 1 })).toContainText(/chair/i);
});
```
- Use role-based locators (same philosophy as RTL). Web-first assertions auto-wait.
- Mock the network when the backend is flaky: `await page.route('**/products*', r => r.fulfill({ json: data }))`.
- Visual regression of DS stories: `await page.goto('http://localhost:6006/iframe.html?id=components-button--all-variants'); await expect(page).toHaveScreenshot();`. Baselines are OS-specific, so generate them in CI/Docker.
- First run: `pnpm exec playwright install --with-deps chromium`.
- Debug: `pnpm exec playwright test --ui` or `--debug`, then `show-trace`.
