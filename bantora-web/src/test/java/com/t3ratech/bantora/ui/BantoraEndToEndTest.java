package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

/**
 * End-to-end test covering the full user journey:
 * 1. View home screen with all 3 columns
 * 2. View popular polls
 * 3. Navigate to poll detail
 * 4. Vote on a poll
 * 5. View results
 * 6. Submit a new idea
 * 
 * Uses seeded data from data.sql
 */
public class BantoraEndToEndTest extends BasePlaywrightTest {

    @Test
    void testEndToEndUserJourney() {
        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        int popularCount = countAriaLabelPrefix("poll_card:popular:");
        int newCount = countAriaLabelPrefix("poll_card:new:");
        int ideasCount = countAriaLabelPrefix("idea_card:");

        assertTrue(popularCount >= 3, "Popular polls count must be >= 3");
        assertTrue(newCount >= 3, "New/AI polls count must be >= 3");
        assertTrue(ideasCount >= 3, "Raw ideas count must be >= 3");
        takeScreenshot("e2e-01-home-counts");

        // Search should reduce at least one column to >= 1 result
        fillTextField("search_input", "unified currency");
        int popularAfterSearch = countAriaLabelPrefix("poll_card:popular:");
        assertTrue(popularAfterSearch >= 1, "Search should return at least 1 popular poll");
        takeScreenshot("e2e-02-search");

        // Vote on first visible poll
        var pollCard = waitForAriaLabelStartsWith("poll_card:popular:");
        String pollCardLabel = pollCard.getAttribute("aria-label");
        assertNotNull(pollCardLabel);
        assertTrue(pollCardLabel.startsWith("poll_card:"));

        String pollId = extractFirstUuidOrFail(pollCardLabel);

        int totalVotesBefore = parseEmbeddedIntOrFail(pollCardLabel, "poll_total_votes:" + pollId + ":");
        waitForAriaLabel("poll_vote_yes_button:" + pollId).click();
        waitForAriaLabelStartsWith("status_message:Vote submitted successfully!");
        waitForAriaLabelContains("poll_vote_disabled:" + pollId + ":true");

        int totalVotesAfter = totalVotesBefore;
        for (int i = 0; i < 60; i++) {
            String updatedPollCardLabel = waitForAriaLabelContains("poll_card:popular:" + pollId).getAttribute("aria-label");
            assertNotNull(updatedPollCardLabel);
            totalVotesAfter = parseEmbeddedIntOrFail(updatedPollCardLabel, "poll_total_votes:" + pollId + ":");
            if (totalVotesAfter >= totalVotesBefore + 1) {
                break;
            }
            page.waitForTimeout(500);
        }
        assertTrue(totalVotesAfter >= totalVotesBefore + 1,
                "Total votes must increase by at least 1. Before: " + totalVotesBefore + ", After: " + totalVotesAfter);
        takeScreenshot("e2e-03-after-vote");

        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        // Submit idea via UI
        if (ariaLabel("search_clear_button").count() > 0) {
            var clear = waitForAriaLabel("search_clear_button");
            clear.scrollIntoViewIfNeeded();
            clear.click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));
        } else {
            fillTextField("search_input", "");
        }

        int ideasBefore = 0;
        for (int i = 0; i < 60; i++) {
            ideasBefore = countAriaLabelPrefix("idea_card:");
            if (ideasBefore > 0) {
                break;
            }
            page.waitForTimeout(250);
        }
        fillTextField("idea_input", "E2E Test Idea: solar charging stations " + System.currentTimeMillis());
        waitForAriaLabel("submit_idea_button").click();
        waitForAriaLabelStartsWith("status_message:Idea submitted successfully!");

        int ideasAfter = ideasBefore;
        for (int i = 0; i < 60; i++) {
            ideasAfter = countAriaLabelPrefix("idea_card:");
            if (ideasAfter >= ideasBefore + 1) {
                break;
            }
            page.waitForTimeout(250);
        }
        assertTrue(ideasAfter >= ideasBefore + 1,
                "Raw ideas count must increase after submission. Before: " + ideasBefore + ", After: " + ideasAfter);
        takeScreenshot("e2e-04-after-idea");

        // Upvote a seeded idea
        final String seededIdeaId = "660e8400-e29b-41d4-a716-446655440001";
        String seededIdeaCardBefore = waitForAriaLabelContains("idea_card:" + seededIdeaId).getAttribute("aria-label");
        assertNotNull(seededIdeaCardBefore);
        int upvotesBefore = parseEmbeddedIntOrFail(seededIdeaCardBefore, "idea_upvotes_count:" + seededIdeaId + ":");

        var upvoteButton = page.locator("[role='button'][aria-label*='idea_upvote_button:" + seededIdeaId + "']");
        if (upvoteButton.count() == 0) {
            upvoteButton = ariaLabelContains("idea_upvote_button:" + seededIdeaId);
        }
        assertTrue(upvoteButton.count() > 0, "Expected upvote button to be present for idea: " + seededIdeaId);
        upvoteButton.first().scrollIntoViewIfNeeded();
        upvoteButton.first().click(new com.microsoft.playwright.Locator.ClickOptions().setForce(true));

        int upvotesAfter = upvotesBefore;
        for (int i = 0; i < 60; i++) {
            String seededIdeaCardAfter = waitForAriaLabelContains("idea_card:" + seededIdeaId).getAttribute("aria-label");
            assertNotNull(seededIdeaCardAfter);
            upvotesAfter = parseEmbeddedIntOrFail(seededIdeaCardAfter, "idea_upvotes_count:" + seededIdeaId + ":");
            if (upvotesAfter >= upvotesBefore + 1) {
                break;
            }
            page.waitForTimeout(250);
        }
        assertTrue(upvotesAfter >= upvotesBefore + 1,
                "Upvote count must increase by at least 1. Before: " + upvotesBefore + ", After: " + upvotesAfter);
        takeScreenshot("e2e-05-after-upvote");
    }
}

