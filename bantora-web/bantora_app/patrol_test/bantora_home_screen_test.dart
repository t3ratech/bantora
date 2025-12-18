import 'package:bantora_app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'bantora_test_helpers.dart';

const _seededPollId = '550e8400-e29b-41d4-a716-446655440001';

void main() {
  patrolTest('home screen loads with polls and ideas', ($) async {
    await $.pumpWidgetAndSettle(const BantoraApp());

    await ensureAuthenticated($);

    await openPollsTab($);

    final popularCount = readCountFromTextPrefixOrFail($, 'popular_polls_count:');
    final newCount = readCountFromTextPrefixOrFail($, 'new_polls_count:');

    assertOrFail(popularCount >= 1, 'Popular polls count must be >= 1');
    assertOrFail(newCount >= 1, 'New/AI polls count must be >= 1');

    await takeScreenshot('01-home-page');
    await takeScreenshot('01-home-counts-visible');

    await openIdeasTab($);

    final ideaId = await waitForAnyIdeaUpvoteButtonIdeaIdOrFail(
      $,
      timeout: const Duration(seconds: 15),
      pollInterval: const Duration(milliseconds: 250),
    );

    await scrollToIdeaUpvoteButton($, ideaId);
  });

  patrolTest('search returns poll results', ($) async {
    await $.pumpWidgetAndSettle(const BantoraApp());

    await ensureAuthenticated($);

    await openPollsTab($);

    await enterTextByKey($, 'search_input', 'unified currency');
    await $.pumpAndSettle();

    assertOrFail(
      $(const Key('poll_card:popular:$_seededPollId')).exists ||
          $(const Key('poll_card:new:$_seededPollId')).exists,
      'Search should return seeded poll card. pollId: $_seededPollId',
    );

    await takeScreenshot('02-search-results');
  });
}
