import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

Future<void> takeScreenshot(String name) async {
  final binding = WidgetsBinding.instance;
  if (binding is IntegrationTestWidgetsFlutterBinding) {
    await binding.takeScreenshot(name);
  }
}

Future<void> waitForKeyExists(
  PatrolIntegrationTester $,
  String keyValue, {
  required Duration timeout,
  required Duration pollInterval,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if ($(Key(keyValue)).exists) {
      return;
    }
    await $.pump(pollInterval);
  }

  throw TimeoutException('Key did not appear: $keyValue', timeout);
}

void assertOrFail(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

String? readAnyStatusMessageOrNull(PatrolIntegrationTester $) {
  const prefix = 'status_message:';
  for (final widget in $.tester.allWidgets) {
    final key = widget.key;
    if (key is! ValueKey) {
      continue;
    }

    final dynamic rawValue = key.value;
    if (rawValue is! String) {
      continue;
    }

    final value = rawValue;
    if (!value.startsWith(prefix)) {
      continue;
    }

    final message = value.substring(prefix.length);
    if (message.trim().isEmpty) {
      continue;
    }

    return message;
  }

  return null;
}

Future<String> waitForAnyStatusMessageOrFail(
  PatrolIntegrationTester $, {
  required Duration timeout,
  required Duration pollInterval,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final msg = readAnyStatusMessageOrNull($);
    if (msg != null) {
      return msg;
    }
    await $.pump(pollInterval);
  }

  throw TimeoutException('No status message appeared', timeout);
}

T assertNotNullOrFail<T>(T? value, String message) {
  if (value == null) {
    throw StateError(message);
  }
  return value;
}

int readCountFromTextPrefixOrFail(
  PatrolIntegrationTester $,
  String prefix,
) {
  final textValue = assertNotNullOrFail(
    $(RegExp(prefix)).text,
    'Missing count text starting with: $prefix',
  );

  final match = RegExp('^${RegExp.escape(prefix)}(\\d+)\$')
      .firstMatch(textValue.trim());
  if (match == null) {
    throw StateError('Unable to parse count from text: $textValue');
  }

  return int.parse(match.group(1)!);
}

Future<void> ensureAuthenticated(PatrolIntegrationTester $) async {
  if ($(const Key('search_input')).exists) {
    return;
  }

  if ($(const Key('login_phone_input')).exists) {
    await registerFreshUserViaUi($);
    await $(const Key('search_input')).waitUntilVisible();
    return;
  }

  await $(const Key('login_phone_input')).waitUntilVisible();
  await registerFreshUserViaUi($);
  await $(const Key('search_input')).waitUntilVisible();
}

class RegisteredUserCredentials {
  final String phoneNumberE164;
  final String password;

  const RegisteredUserCredentials({
    required this.phoneNumberE164,
    required this.password,
  });
}

Future<void> pressEnterToSubmit(PatrolIntegrationTester $) async {
  await $.tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await $.pumpAndSettle();
}

Future<RegisteredUserCredentials> registerFreshUserViaUi(PatrolIntegrationTester $) async {
  await $(const Key('go_to_register_button')).tap();
  await $.pumpAndSettle();

  final suffix = (DateTime.now().millisecondsSinceEpoch % 10000000).toString().padLeft(7, '0');
  final phoneNumberE164 = '+26377$suffix';
  final password = 'TestPass123!';

  if ($(const Key('register_country_code_input')).exists) {
    await $(const Key('register_country_code_input')).tap();
    await $.pumpAndSettle();

    if ($(const Key('register_country_search_input')).exists) {
      await enterTextByKey($, 'register_country_search_input', 'ZW');
      await $.pumpAndSettle();
    }

    if ($(Key('register_country_option:ZW')).exists) {
      await $(Key('register_country_option:ZW')).tap();
      await $.pumpAndSettle();
    }
  }

  await $(const Key('register_phone_input')).waitUntilVisible();
  await enterTextByKey($, 'register_phone_input', phoneNumberE164);

  await takeScreenshot('auth-01-register-after-phone');

  await $(const Key('register_password_input')).scrollTo();
  await enterTextByKey($, 'register_password_input', password);

  await $(const Key('register_confirm_password_input')).scrollTo();
  await enterTextByKey($, 'register_confirm_password_input', password);

  await $(const Key('register_confirm_password_input')).tap();
  await pressEnterToSubmit($);

  await $(const Key('search_input')).waitUntilVisible();

  return RegisteredUserCredentials(phoneNumberE164: phoneNumberE164, password: password);
}

Future<void> openPollsTab(PatrolIntegrationTester $) async {
  await $(const Key('tab_polls')).waitUntilVisible();
  await $(const Key('tab_polls')).tap();
  await $.pumpAndSettle();

  await $(const Key('search_input')).waitUntilVisible();
}

Future<void> openIdeasTab(PatrolIntegrationTester $) async {
  await $(const Key('tab_ideas')).waitUntilVisible();
  await $(const Key('tab_ideas')).tap();
  await $.pumpAndSettle();

  await $(const Key('idea_input')).waitUntilVisible();
  await $(const Key('submit_idea_button')).waitUntilVisible();
}

Future<void> enterTextByKey(
  PatrolIntegrationTester $,
  String keyValue,
  String text,
) async {
  await $(Key(keyValue)).enterText(text);
  await $.pumpAndSettle();
}

Future<void> clearSearchOrFail(PatrolIntegrationTester $) async {
  if (!$(const Key('search_input')).exists) {
    throw StateError('Search input is not present');
  }

  if ($(const Key('search_clear_button')).exists) {
    await $(const Key('search_clear_button')).tap();
    await $.pumpAndSettle();
    return;
  }

  await enterTextByKey($, 'search_input', '');
}

Future<void> selectIdeaCategoryForSubmission(
  PatrolIntegrationTester $,
  String categoryName,
) async {
  await $(const Key('idea_category_select')).tap();
  await $.pumpAndSettle();

  await $(categoryName).tap();
  await $.pumpAndSettle();
}

String readFirstPollIdOrFail(PatrolIntegrationTester $) {
  const prefix = 'poll_total_votes_text:';
  for (final widget in $.tester.allWidgets) {
    final key = widget.key;
    if (key is! ValueKey) {
      continue;
    }

    final dynamic rawValue = key.value;
    if (rawValue is! String) {
      continue;
    }

    final value = rawValue;
    if (!value.startsWith(prefix)) {
      continue;
    }

    final pollId = value.substring(prefix.length).trim();
    if (pollId.isEmpty) {
      continue;
    }

    return pollId;
  }

  throw StateError('Unable to find any poll IDs on the Polls tab');
}

int readPollTotalVotesOrFail(PatrolIntegrationTester $, String pollId) {
  final votesText = $(Key('poll_total_votes_text:$pollId')).text;
  final textValue = assertNotNullOrFail(votesText, 'Missing total votes text for pollId: $pollId');
  final match = RegExp('^(\\d+)').firstMatch(textValue.trim());
  if (match == null) {
    throw StateError('Unable to parse total votes from text: $textValue');
  }
  return int.parse(match.group(1)!);
}

int readIdeaUpvotesOrFail(PatrolIntegrationTester $, String ideaId) {
  final upvotesText = $(Key('idea_upvotes_text:$ideaId')).text;
  final textValue = assertNotNullOrFail(upvotesText, 'Missing upvotes text for ideaId: $ideaId');
  final match = RegExp('^(\\d+)').firstMatch(textValue.trim());
  if (match == null) {
    throw StateError('Unable to parse upvotes from text: $textValue');
  }
  return int.parse(match.group(1)!);
}

Future<PatrolFinder> scrollToIdeaUpvoteButton(
  PatrolIntegrationTester $,
  String ideaId,
) {
  if (!$(const Key('ideas_list')).exists) {
    throw StateError('Ideas list is not present; are you on the Ideas tab?');
  }

  return $(Key('idea_upvote_button:$ideaId')).scrollTo(
    view: $(const Key('ideas_list')).finder,
  );
}

int readIdeasCountOrFail(PatrolIntegrationTester $) {
  final textValue = $(const Key('ideas_count_text')).text;
  final raw = assertNotNullOrFail(textValue, 'Missing ideas count marker');
  final match = RegExp('^ideas_count:(\\d+)\$').firstMatch(raw.trim());
  if (match == null) {
    throw StateError('Unable to parse ideas count from text: $raw');
  }
  return int.parse(match.group(1)!);
}

Future<void> waitForIdeasCountAtLeast(
  PatrolIntegrationTester $,
  int minCount, {
  required Duration timeout,
  required Duration pollInterval,
}) async {
  if (minCount < 0) {
    throw StateError('minCount must be >= 0');
  }

  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (!$(const Key('ideas_count_text')).exists) {
      await $.pump(pollInterval);
      continue;
    }

    final count = readIdeasCountOrFail($);
    if (count >= minCount) {
      return;
    }
    await $.pump(pollInterval);
  }

  throw TimeoutException('Ideas count did not reach $minCount', timeout);
}

String _extractIdeaIdFromUpvoteButtonKeyOrFail(Key key) {
  if (key is! ValueKey) {
    throw StateError('Unexpected upvote button key type: ${key.runtimeType}');
  }

  final dynamic rawValue = key.value;
  if (rawValue is! String) {
    throw StateError('Unexpected upvote button key value type: ${rawValue.runtimeType}');
  }

  final value = rawValue;
  if (!value.startsWith('idea_upvote_button:')) {
    throw StateError('Unexpected upvote button key value: $value');
  }

  final parts = value.split(':');
  if (parts.length != 2 || parts[1].trim().isEmpty) {
    throw StateError('Unable to extract ideaId from upvote button key: $value');
  }

  return parts[1].trim();
}

Future<String> waitForAnyIdeaUpvoteButtonIdeaIdOrFail(
  PatrolIntegrationTester $, {
  required Duration timeout,
  required Duration pollInterval,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    for (final widget in $.tester.allWidgets) {
      final key = widget.key;
      if (key is ValueKey) {
        final dynamic rawValue = key.value;
        if (rawValue is String && rawValue.startsWith('idea_upvote_button:')) {
          return _extractIdeaIdFromUpvoteButtonKeyOrFail(key);
        }
      }
    }

    int? ideasCount;
    try {
      ideasCount = readIdeasCountOrFail($);
    } catch (_) {
      ideasCount = null;
    }

    if (ideasCount != null && ideasCount <= 0) {
      await $.pump(pollInterval);
      continue;
    }

    if ($(const Key('ideas_list')).exists) {
      await $.tester.drag(
        $(const Key('ideas_list')).finder,
        const Offset(0, -400),
      );
      await $.pumpAndSettle();
    } else {
      await $.pump(pollInterval);
    }
  }

  throw TimeoutException('No idea upvote buttons appeared in Ideas tab', timeout);
}
