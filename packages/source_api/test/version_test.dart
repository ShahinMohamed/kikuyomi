// §3.7: minor versions only add, so an app runs anything targeting a minor it has reached. These
// pin down which extensions an app offers to install, and what it says about the rest.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:test/test.dart';

void main() {
  group('the version this app implements', () {
    test('is the one the contract names', () {
      // 1.1 adds text sources (ADR-0019); 1.2 adds a book that is one file (ADR-0021).
      expect(apiVersion, '1.2');
      expect(ApiVersion.parse(apiVersion), const ApiVersion(1, 2));
    });

    test('is the newest one it supports', () {
      expect(supportedApiVersions.newest, ApiVersion.parse(apiVersion));
    });
  });

  group('reading a version', () {
    test('reads MAJOR.MINOR', () {
      expect(ApiVersion.parse('1.0'), const ApiVersion(1, 0));
      expect(ApiVersion.parse('2.13'), const ApiVersion(2, 13));
      expect(ApiVersion.parse('0.0'), const ApiVersion(0, 0));
    });

    test('refuses anything that could be read two ways', () {
      for (final text in [
        '1',
        '1.0.0',
        '01.0',
        '1.00',
        ' 1.0',
        '1.0 ',
        'v1.0',
        '1,0',
        '1.',
        '.0',
        '',
        '1.-1',
        '1.0-beta',
        '9999999999.0',
      ]) {
        expect(ApiVersion.tryParse(text), isNull, reason: text);
        expect(
          () => ApiVersion.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('ordering versions', () {
    test('goes by major first, then minor', () {
      expect(const ApiVersion(1, 9) < const ApiVersion(2, 0), isTrue);
      expect(const ApiVersion(1, 2) < const ApiVersion(1, 10), isTrue);
      expect(const ApiVersion(1, 0) <= const ApiVersion(1, 0), isTrue);
      expect(const ApiVersion(2, 0) > const ApiVersion(1, 99), isTrue);
      expect(const ApiVersion(1, 0) >= const ApiVersion(1, 1), isFalse);
    });

    test('makes equal versions equal, whatever they compare to', () {
      expect(const ApiVersion(1, 0), const ApiVersion(1, 0));
      expect(const ApiVersion(1, 0).hashCode, const ApiVersion(1, 0).hashCode);
      expect(const ApiVersion(1, 0), isNot(const ApiVersion(1, 1)));
      expect([const ApiVersion(1, 2), const ApiVersion(1, 0)]..sort(), [
        const ApiVersion(1, 0),
        const ApiVersion(1, 2),
      ]);
    });

    test('writes itself as a manifest does', () {
      expect(const ApiVersion(1, 0).toString(), '1.0');
    });
  });

  group('an extension targeting a version', () {
    ApiCompatibility check(int major, int minor) =>
        supportedApiVersions.check(ApiVersion(major, minor));

    test('runs when it targets this version', () {
      expect(check(1, 1), ApiCompatibility.supported);
    });

    test('still runs when it targets 1.0', () {
      // The whole promise of a minor version. Every extension that exists targets 1.0, and adding
      // text sources must not cost a single one of them.
      expect(check(1, 0), ApiCompatibility.supported);
    });

    test('runs when it targets an older minor of a supported major', () {
      const app = SupportedApiVersions({1: 4});
      expect(app.check(const ApiVersion(1, 0)), ApiCompatibility.supported);
      expect(app.check(const ApiVersion(1, 4)), ApiCompatibility.supported);
    });

    test('needs a newer app when it targets a newer minor', () {
      expect(check(1, 3), ApiCompatibility.needsNewerApp);
      expect(check(1, 99), ApiCompatibility.needsNewerApp);
    });

    test('needs a newer app when it targets a newer major', () {
      expect(check(2, 0), ApiCompatibility.needsNewerApp);
    });

    test('is obsolete when it targets a major that is no longer supported', () {
      expect(check(0, 9), ApiCompatibility.obsolete);
      const afterTwoPointZero = SupportedApiVersions({2: 1});
      expect(
        afterTwoPointZero.check(const ApiVersion(1, 3)),
        ApiCompatibility.obsolete,
      );
    });

    test('is judged per major during a deprecation window, not by a range', () {
      // 1.x up to 1.4 and 2.x up to 2.1 are supported. 1.7 lies between them and is still too new.
      const app = SupportedApiVersions({1: 4, 2: 1});
      expect(app.newest, const ApiVersion(2, 1));
      expect(app.check(const ApiVersion(1, 4)), ApiCompatibility.supported);
      expect(app.check(const ApiVersion(1, 7)), ApiCompatibility.needsNewerApp);
      expect(app.check(const ApiVersion(2, 1)), ApiCompatibility.supported);
      expect(app.check(const ApiVersion(3, 0)), ApiCompatibility.needsNewerApp);
      expect(app.check(const ApiVersion(0, 1)), ApiCompatibility.obsolete);
    });
  });
}
