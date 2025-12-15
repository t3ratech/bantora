package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

/**
 * Test for Bantora Home Screen - 3-column layout with Popular, New/AI polls, and Raw Ideas
 * Uses seeded data from data.sql
 */
public class BantoraHomeScreenTest extends BasePlaywrightTest {

    @Test
    void testHomeScreenLoadsWithThreeColumns() {
        navigateToHome();
        ensureAuthenticated();

        assertThat(page).hasTitle("Bantora - African Polling Platform");

        int popularPollCards = countAriaLabelPrefix("poll_card:popular:");
        int newPollCards = countAriaLabelPrefix("poll_card:new:");
        int ideaCards = countAriaLabelPrefix("idea_card:");

        assertTrue(popularPollCards >= 3, "Popular polls count must be >= 3");
        assertTrue(newPollCards >= 3, "New/AI polls count must be >= 3");
        assertTrue(ideaCards >= 3, "Raw ideas count must be >= 3");

        takeScreenshot("01-home-counts-visible");
    }

    @Test
    void testSearchReturnsResults() {
        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        // Search for a known seeded poll term
        fillTextField("search_input", "unified currency");

        int popularPollCards = countAriaLabelPrefix("poll_card:popular:");
        assertTrue(popularPollCards >= 1, "Search should return at least 1 popular poll result");

        takeScreenshot("02-search-results");
    }
}
