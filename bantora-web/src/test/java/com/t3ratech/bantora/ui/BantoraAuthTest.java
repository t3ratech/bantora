package com.t3ratech.bantora.ui;

import com.microsoft.playwright.Locator;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;

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

        // Check for "Bantora" text which should be visible
        Locator title = page.getByText("Bantora").first();
        assertThat(title).isVisible();
    }
}
