import 'package:bantora_app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'bantora_test_helpers.dart';

void main() {
  patrolTest('vote increments and disables buttons', ($) async {
    await $.pumpWidgetAndSettle(const BantoraApp());

    await ensureAuthenticated($);

    await openPollsTab($);

    final pollId = readFirstPollIdOrFail($);

    final totalVotesBefore = readPollTotalVotesOrFail($, pollId);

    await $(Key('poll_vote_yes_button:$pollId')).scrollTo().tap();
    await $.pumpAndSettle();

    await $(const Key('status_message:Vote submitted successfully!')).waitUntilVisible();

    await waitForKeyExists(
      $,
      'poll_vote_disabled:$pollId:true',
      timeout: const Duration(seconds: 15),
      pollInterval: const Duration(milliseconds: 250),
    );

    int totalVotesAfter = totalVotesBefore;
    for (int i = 0; i < 60; i++) {
      totalVotesAfter = readPollTotalVotesOrFail($, pollId);
      if (totalVotesAfter >= totalVotesBefore + 1) {
        break;
      }
      await $.pump(const Duration(milliseconds: 250));
    }

    assertOrFail(
      totalVotesAfter >= totalVotesBefore + 1,
      'Total votes must increase by at least 1. Before: $totalVotesBefore, After: $totalVotesAfter',
    );

    await takeScreenshot('01-vote-increments-and-disables');
  });
}
