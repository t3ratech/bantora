package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

public class BantoraAuthTest extends BasePlaywrightTest {

    @Test
    void testHomePageLoadsAndShowsAuth() {
        navigateToHome();
        ensureAuthenticated();

        // Verify title
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        int popularPollCards = countAriaLabelPrefix("poll_card:popular:");
        int newPollCards = countAriaLabelPrefix("poll_card:new:");
        int ideaCards = countAriaLabelPrefix("idea_card:");

        assertTrue(popularPollCards >= 3);
        assertTrue(newPollCards >= 3);
        assertTrue(ideaCards >= 3);

        takeScreenshot("01-home-page");
    }
}
