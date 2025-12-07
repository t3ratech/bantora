import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
    await page.goto('/');

    // Expect a title "to contain" a substring.
    await expect(page).toHaveTitle(/Bantora/);
});

test('shows polls', async ({ page }) => {
    await page.goto('/');

    // Check if the main container is visible
    // Note: Flutter renders to canvas, so standard selectors might be tricky.
    // We might need to rely on accessibility labels if implemented, or visual regression.
    // For now, just checking if the page loads without error.

    // Wait for some time to ensure Flutter app loads
    await page.waitForTimeout(3000);

    // Take a screenshot
    await page.screenshot({ path: 'homepage.png' });
});
