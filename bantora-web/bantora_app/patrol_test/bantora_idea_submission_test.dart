import 'package:bantora_app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'bantora_test_helpers.dart';

void main() {
  patrolTest('idea submission and upvote works', ($) async {
    await $.pumpWidgetAndSettle(const BantoraApp());

    await ensureAuthenticated($);

    await openIdeasTab($);

    await takeScreenshot('01-idea-input-field');

    final uniqueToken = DateTime.now().millisecondsSinceEpoch.toString();
    final ideaContent = 'Test idea: improve rural connectivity $uniqueToken';

    await enterTextByKey($, 'idea_input', ideaContent);
    await selectIdeaCategoryForSubmission($, 'Economy');
    await enterTextByKey($, 'idea_hashtags_input', '#connectivity #infrastructure');

    await takeScreenshot('02-before-idea-submission');

    await $(const Key('submit_idea_button')).tap();
    await $.pumpAndSettle();

    final ideaSubmitStatus = await waitForAnyStatusMessageOrFail(
      $,
      timeout: const Duration(seconds: 15),
      pollInterval: const Duration(milliseconds: 250),
    );
    assertOrFail(
      ideaSubmitStatus == 'Idea submitted successfully!',
      'Expected idea submit success message, got: $ideaSubmitStatus',
    );

    await takeScreenshot('03-after-idea-submission');

    final ideaId = await waitForAnyIdeaUpvoteButtonIdeaIdOrFail(
      $,
      timeout: const Duration(seconds: 15),
      pollInterval: const Duration(milliseconds: 250),
    );

    final upvoteButton = await scrollToIdeaUpvoteButton($, ideaId);
    final beforeUpvotes = readIdeaUpvotesOrFail($, ideaId);

    await upvoteButton.tap();
    await $.pumpAndSettle();

    final upvoteStatus = await waitForAnyStatusMessageOrFail(
      $,
      timeout: const Duration(seconds: 15),
      pollInterval: const Duration(milliseconds: 250),
    );
    assertOrFail(
      upvoteStatus == 'Upvote received!',
      'Expected upvote success message, got: $upvoteStatus',
    );

    int afterUpvotes = beforeUpvotes;
    for (int i = 0; i < 60; i++) {
      afterUpvotes = readIdeaUpvotesOrFail($, ideaId);
      if (afterUpvotes >= beforeUpvotes + 1) {
        break;
      }
      await $.pump(const Duration(milliseconds: 250));
    }

    assertOrFail(
      afterUpvotes >= beforeUpvotes + 1,
      'Upvote count must increase by at least 1. Before: $beforeUpvotes, After: $afterUpvotes',
    );

    await takeScreenshot('04-upvote-incremented');
  });
}
