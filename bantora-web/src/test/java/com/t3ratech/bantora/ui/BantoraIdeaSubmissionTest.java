package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

/**
 * Test for Idea submission functionality
 * Tests adding new ideas to the Raw Ideas column
 */
public class BantoraIdeaSubmissionTest extends BasePlaywrightTest {

    private static final String SEEDED_IDEA_ID = "660e8400-e29b-41d4-a716-446655440001";

    @Test
    void testIdeaInputFieldVisible() {
        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        assertTrue(countAriaLabelPrefix("idea_card:") >= 3);

        assertThat(ariaLabel("idea_input").first()).isVisible();
        assertThat(ariaLabel("submit_idea_button").first()).isVisible();

        takeScreenshot("01-idea-input-field");
    }

    @Test
    void testSubmitNewIdea() {
        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        int initialCount = countAriaLabelPrefix("idea_card:");

        fillTextField("idea_input", "Test idea: improve rural connectivity " + System.currentTimeMillis());

        takeScreenshot("02-before-idea-submission");

        ariaLabel("submit_idea_button").first().click();
        waitForAriaLabelContains("status_message:Idea submitted successfully!");

        int afterCount = initialCount;
        for (int i = 0; i < 60; i++) {
            afterCount = countAriaLabelPrefix("idea_card:");
            if (afterCount >= initialCount + 1) {
                break;
            }
            page.waitForTimeout(250);
        }
        assertTrue(afterCount >= initialCount + 1,
                "Raw ideas count must increase after submission. Initial: " + initialCount + ", After: " + afterCount);

        takeScreenshot("03-after-idea-submission");
    }

    @Test
    void testUpvoteIncrementsCount() {
        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        String ideaCardBefore = waitForAriaLabelContains("idea_card:" + SEEDED_IDEA_ID).getAttribute("aria-label");
        assertNotNull(ideaCardBefore);
        int before = parseEmbeddedIntOrFail(ideaCardBefore, "idea_upvotes_count:" + SEEDED_IDEA_ID + ":");

        var upvoteButton = waitForAriaLabelStartsWith("idea_upvote_button:" + SEEDED_IDEA_ID);
        upvoteButton.scrollIntoViewIfNeeded();

        var response = page.waitForResponse(
                r -> r.url().contains("/api/ideas/" + SEEDED_IDEA_ID + "/upvote") && "POST".equalsIgnoreCase(r.request().method()),
                () -> upvoteButton.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true))
        );
        String responseBody = response.text();
        assertTrue(responseBody != null && responseBody.contains("\"success\":true"),
                "Expected upvote API response success=true but got: " + responseBody);

        int after = before;
        for (int i = 0; i < 60; i++) {
            String ideaCardAfter = waitForAriaLabelContains("idea_card:" + SEEDED_IDEA_ID).getAttribute("aria-label");
            assertNotNull(ideaCardAfter);
            after = parseEmbeddedIntOrFail(ideaCardAfter, "idea_upvotes_count:" + SEEDED_IDEA_ID + ":");
            if (after >= before + 1) {
                break;
            }
            page.waitForTimeout(250);
        }
        assertTrue(after >= before + 1, "Upvote count must increase by at least 1. Before: " + before + ", After: " + after);

        takeScreenshot("04-upvote-incremented");
    }
}
