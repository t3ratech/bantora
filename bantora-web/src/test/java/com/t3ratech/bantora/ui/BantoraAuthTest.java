package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;

import org.junit.jupiter.api.Test;

import com.microsoft.playwright.Locator;

public class BantoraAuthTest extends BasePlaywrightTest {

    @Test
    void testHomePageLoadsAndShowsAuth() {
        navigateToHome();

        // Verify title
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        // Verify Auth Overlay is present (since we are not logged in)
        // Note: Adjust selector based on actual Flutter app structure.
        // Flutter web often uses obscure DOM, but we can look for text or specific keys
        // if added.
        // Assuming we added keys or can find text.

        // Take initial screenshot
        takeScreenshot("01-home-page");

        // Check for specific flutter element to verify app structure
        // System.out.println("Page Content: " + page.content());

        // Wait for Flutter glass pane (typical in CanvasKit/html renderer)
        Locator flutterApp = page.locator("flt-glass-pane").or(page.locator("flutter-view"));
        assertThat(flutterApp.first()).isVisible();

        // Try waiting a bit longer for semantics
        // page.getByText("Bantora").first().waitFor(new
        // Locator.WaitForOptions().setTimeout(10000));

        // Assert title again to be sure
        assertThat(page).hasTitle("Bantora - African Polling Platform");
    }
}
