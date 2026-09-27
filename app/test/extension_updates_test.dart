// Checking a repository for updates: what a refreshed index says about what is already installed
// (§3.8, §3.9).
//
// Against a real database and a real server on this machine, with real Ed25519 signatures, because
// the check goes through the same fetcher an install does and that fetcher refuses an index its key
// did not sign. A fixture with a made-up signature would fail every test here for one reason and
// prove nothing about any of them.
//
// Most of these are about *not* acting. A version number is the only thing standing between a
// listener and code they did not ask for, and `revoked` marks a version rather than an extension, so
// nearly every way of getting this wrong ends with the app installing or disabling something on its
// own. Each of those has a test.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/sources/repository_library.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_networking/kikuyomi_networking.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

const _extensionId = 'org.example.librivox';
const _hash =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

const _policy = NetworkPolicy(
  userAgent: 'Kikuyomi/1.0 (test)',
  minimumInterval: Duration.zero,
  requestTimeout: Duration(seconds: 5),
  connectTimeout: Duration(seconds: 5),
);

late SimpleKeyPair _key;
late String _publicKey;
late String _signature;

/// An index offering [_extensionId] at [versionCode], withdrawn or not.
String indexJson({required int versionCode, bool revoked = false}) =>
    jsonEncode({
      'extensions': [
        {
          'id': _extensionId,
          'name': 'LibriVox',
          'version': '1.$versionCode.0',
          'versionCode': versionCode,
          'apiVersion': '1.0',
          'minAppVersion': '1.0.0',
          'contentRating': 'everyone',
          'domains': ['librivox.org'],
          'sources': [
            {
              'key': 'librivox',
              'name': 'LibriVox',
              'lang': 'en',
              'versionId': 1,
            },
          ],
          'package': {'url': 'https://example.org/a.zip', 'sha256': _hash},
          'signature': _signature,
          'revoked': revoked,
        },
      ],
    });

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;
  late RepositoryLibrary repositories;
  late List<HttpServer> servers;

  setUpAll(() async {
    _key = await Ed25519().newKeyPairFromSeed(List.filled(32, 7));
    _publicKey = base64Encode((await _key.extractPublicKey()).bytes);
    _signature = base64Encode(
      (await Ed25519().sign(utf8.encode(_hash), keyPair: _key)).bytes,
    );
  });

  setUp(() {
    db = KikuyomiDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 9, 27));
    servers = [];
    repositories = RepositoryLibrary(
      database: db,
      fetcher: RepositoryFetcher(
        NetworkService(policy: _policy).clientFor('org.kikuyomi.repositories'),
      ),
      clock: clock,
    );
  });

  tearDown(() async {
    for (final server in servers) {
      await server.close(force: true);
    }
    await db.close();
  });

  /// A repository at a local address, serving [index], and added with its key pinned.
  Future<String> serving(String? index, {String name = 'Example'}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(server);
    unawaited(
      server.forEach((request) async {
        final response = request.response;
        if (request.uri.path == '/repo.json') {
          response.write(jsonEncode({'name': name, 'publicKey': _publicKey}));
        } else if (request.uri.path == '/index.json' && index != null) {
          response.write(index);
        } else {
          response.statusCode = 404;
        }
        await response.close();
      }),
    );
    final url = 'http://127.0.0.1:${server.port}/';
    await addRepository(
      db,
      url: url,
      name: name,
      publicKey: _publicKey,
      fingerprint: 'AA:BB',
    );
    return url;
  }

  /// Records [_extensionId] as installed from [from].
  Future<void> installed({
    required String from,
    int versionCode = 14,
    ExtensionStatus status = ExtensionStatus.active,
    ExtensionOrigin origin = ExtensionOrigin.repository,
  }) => recordInstalledExtension(
    db,
    id: _extensionId,
    name: 'LibriVox',
    version: '1.$versionCode.0',
    versionCode: versionCode,
    apiVersion: '1.0',
    status: status,
    origin: origin,
    originHandle: from,
    originName: 'Example',
    installPath: '$_extensionId/$versionCode',
    clock: clock,
  );

  test('nothing added means nothing to check, and nothing asked', () async {
    final check = await repositories.checkForUpdates();

    expect(check.isEmpty, isTrue);
    expect(check.unreachable, isEmpty);
  });

  test('a higher version code is an update', () async {
    final url = await serving(indexJson(versionCode: 15));
    await installed(from: url);

    final check = await repositories.checkForUpdates();

    expect(check.updates.single.id, _extensionId);
    expect(check.updates.single.offeredVersion, '1.15.0');
    expect(check.withdrawn, isEmpty);
  });

  test('the same version is not an update', () async {
    final url = await serving(indexJson(versionCode: 14));
    await installed(from: url);

    expect((await repositories.checkForUpdates()).isEmpty, isTrue);
  });

  test('a lower version is not an update either', () async {
    // A repository may roll its listing back. Following it down would be an install nobody asked
    // for, and `versionCode` is what orders releases, not the version string.
    final url = await serving(indexJson(versionCode: 13));
    await installed(from: url);

    expect((await repositories.checkForUpdates()).isEmpty, isTrue);
  });

  test('a withdrawn entry for the installed version withdraws it', () async {
    final url = await serving(indexJson(versionCode: 14, revoked: true));
    await installed(from: url);

    final check = await repositories.checkForUpdates();

    expect(check.withdrawn.single.id, _extensionId);
    expect(check.updates, isEmpty);
  });

  test('a withdrawn entry for a newer version changes nothing', () async {
    // `revoked` marks a version, not an extension. A listener on 14 whose repository pulls 15 is
    // running code nobody said anything about, and disabling it would be acting on a warning about
    // a version they never had.
    final url = await serving(indexJson(versionCode: 15, revoked: true));
    await installed(from: url);

    expect((await repositories.checkForUpdates()).isEmpty, isTrue);
  });

  test('checking twice does not withdraw twice', () async {
    final url = await serving(indexJson(versionCode: 14, revoked: true));
    await installed(from: url, status: ExtensionStatus.revoked);

    // Already withdrawn, so there is nothing to report and nothing to do. Reporting it again would
    // make every check announce the same disabling to the listener for ever.
    expect((await repositories.checkForUpdates()).isEmpty, isTrue);
  });

  test('an entry offered again restores what was withdrawn', () async {
    // Without this a version pulled back and reinstated would stay disabled for ever, and the
    // listener's only way out would be removing the extension and installing it again.
    final url = await serving(indexJson(versionCode: 14));
    await installed(from: url, status: ExtensionStatus.revoked);

    final check = await repositories.checkForUpdates();

    expect(check.restored.single.id, _extensionId);
  });

  test(
    'a newer version of something withdrawn is an update, not a restoration',
    () async {
      final url = await serving(indexJson(versionCode: 15));
      await installed(from: url, status: ExtensionStatus.revoked);

      final check = await repositories.checkForUpdates();

      expect(check.restored, isEmpty);
      expect(check.updates.single.offeredVersion, '1.15.0');
    },
  );

  test('a folder install is never updated from a repository', () async {
    // Its handle is a folder path, not a repository URL, and an extension an author is editing must
    // not be replaced by whatever a repository happens to publish under the same id.
    final url = await serving(indexJson(versionCode: 15));
    await installed(from: url, origin: ExtensionOrigin.folder);

    expect((await repositories.checkForUpdates()).isEmpty, isTrue);
  });

  test('another repository offering the same id is not consulted', () async {
    // An extension is updated by whoever published the copy that is installed. Otherwise adding a
    // second repository could quietly replace code from the first.
    final mine = await serving(indexJson(versionCode: 14), name: 'Mine');
    await serving(indexJson(versionCode: 99), name: 'Somebody else');
    await installed(from: mine);

    expect((await repositories.checkForUpdates()).isEmpty, isTrue);
  });

  test('one repository being down does not lose the others', () async {
    final down = await serving(null, name: 'Down');
    final up = await serving(indexJson(versionCode: 15), name: 'Up');
    await installed(from: up);

    final check = await repositories.checkForUpdates();

    expect(check.updates.single.repository.url, up);
    expect(check.unreachable.keys, ['Down']);
    expect(check.unreachable['Down'], contains('index.json'));
    expect(down, isNotEmpty);
  });

  test('a check reports without changing anything', () async {
    // Deliberate: applying what was found belongs to `ExtensionLibrary`, which owns the rows and the
    // running sources. A check can then be run to show a listener what is waiting, with nothing
    // happening behind their back.
    final url = await serving(indexJson(versionCode: 14, revoked: true));
    await installed(from: url);

    await repositories.checkForUpdates();

    final row = await readInstalledExtension(db, _extensionId);
    expect(row!.status, ExtensionStatus.active);
  });
}
