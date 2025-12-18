import 'package:bantora_app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'bantora_test_helpers.dart';

const _seededPollId = '550e8400-e29b-41d4-a716-446655440001';

void main() {
  patrolTest('end-to-end user journey', ($) async {
    await $.pumpWidgetAndSettle(const BantoraApp());

    if ($(const Key('search_input')).exists) {
      await $(const Key('logout_button')).tap();
      await $.pumpAndSettle();
    }

    await $(const Key('login_phone_input')).waitUntilVisible();
    final creds = await registerFreshUserViaUi($);

    await $(const Key('logout_button')).tap();
    await $.pumpAndSettle();

    await $(const Key('login_phone_input')).waitUntilVisible();
    await enterTextByKey($, 'login_phone_input', creds.phoneNumberE164);
    await $(const Key('login_password_input')).waitUntilVisible();
    await enterTextByKey($, 'login_password_input', creds.password);
    await $(const Key('login_password_input')).tap();
    await pressEnterToSubmit($);

    await $(const Key('search_input')).waitUntilVisible();

    await openPollsTab($);

    final popularCount = readCountFromTextPrefixOrFail($, 'popular_polls_count:');
    final newCount = readCountFromTextPrefixOrFail($, 'new_polls_count:');

    assertOrFail(popularCount >= 1, 'Popular polls count must be >= 1');
    assertOrFail(newCount >= 1, 'New/AI polls count must be >= 1');

    await takeScreenshot('e2e-01-home-counts');

    await enterTextByKey($, 'search_input', 'unified currency');
    await $.pumpAndSettle();

    assertOrFail(
      $(const Key('poll_card:popular:$_seededPollId')).exists,
      'Search should return seeded popular poll card. pollId: $_seededPollId',
    );

    await takeScreenshot('e2e-02-search');

    final pollId = _seededPollId;

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

    await takeScreenshot('e2e-03-after-vote');

    await openIdeasTab($);

    await clearSearchOrFail($);

    final uniqueToken = DateTime.now().millisecondsSinceEpoch.toString();
    final ideaContent = 'E2E Test Idea: solar charging stations $uniqueToken';

    await enterTextByKey($, 'idea_input', ideaContent);
    await selectIdeaCategoryForSubmission($, 'Economy');
    await enterTextByKey($, 'idea_hashtags_input', '#solar #energy');

    await $(const Key('submit_idea_button')).tap();
    await $.pumpAndSettle();

    await $(const Key('status_message:Idea submitted successfully!')).waitUntilVisible();

    await takeScreenshot('e2e-04-after-idea');

    await openIdeasTab($);

    final ideaId = await waitForAnyIdeaUpvoteButtonIdeaIdOrFail(
      $,
      timeout: const Duration(seconds: 45),
      pollInterval: const Duration(milliseconds: 250),
    );

    final upvoteButton = await scrollToIdeaUpvoteButton($, ideaId);
    final upvotesBefore = readIdeaUpvotesOrFail($, ideaId);

    await upvoteButton.tap();
    await $.pumpAndSettle();

    await $(const Key('status_message:Upvote received!')).waitUntilVisible();

    int upvotesAfter = upvotesBefore;
    for (int i = 0; i < 60; i++) {
      upvotesAfter = readIdeaUpvotesOrFail($, ideaId);
      if (upvotesAfter >= upvotesBefore + 1) {
        break;
      }
      await $.pump(const Duration(milliseconds: 250));
    }

    assertOrFail(
      upvotesAfter >= upvotesBefore + 1,
      'Upvote count must increase by at least 1. Before: $upvotesBefore, After: $upvotesAfter',
    );

    await takeScreenshot('e2e-05-after-upvote');
  });
}
