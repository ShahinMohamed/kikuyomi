import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds can reach extension and repository hosts', () {
    // Debug and profile each have a development-only manifest overlay. The permission belongs in
    // main so that the release manifest has it too; without it, DNS lookups fail on Android with
    // "No address associated with hostname" even while the device itself is online.
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      RegExp(
        r'<uses-permission\b[^>]*\bandroid:name="android\.permission\.INTERNET"[^>]*/?>',
      ).hasMatch(manifest),
      isTrue,
      reason: 'the production manifest must grant Internet access for extensions and repositories',
    );
  });
}
