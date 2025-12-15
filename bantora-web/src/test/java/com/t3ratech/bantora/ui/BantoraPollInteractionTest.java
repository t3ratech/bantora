package com.t3ratech.bantora.ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

/**
 * Test for Poll interactions - voting and disabled states
 */
public class BantoraPollInteractionTest extends BasePlaywrightTest {

    @Test
    void testVoteIncrementsAndDisablesButtons() {
        navigateToHome();
        ensureAuthenticated();
        assertThat(page).hasTitle("Bantora - African Polling Platform");

        // Select the first poll card visible
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

        takeScreenshot("01-vote-increments-and-disables");
    }
}

