import 'package:bantora_app/main.dart';
import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'bantora_test_helpers.dart';

void main() {
  patrolTest('register and login via Enter', ($) async {
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

    await takeScreenshot('auth-02-login-success');
  });
}
