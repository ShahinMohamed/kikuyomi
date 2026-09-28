// What a fresh install starts with, and what it must never undo.
//
// Two rules carry the weight here. A first run installs everything the app ships with and pins the
// official repository, so the app is useful with no network at all. Every run after that leaves the
// listener's decisions alone — above all the decision to remove something, which a re-install on
// the next restart would quietly reverse.
//
// Against a real database and the app's real assets, because the point of the change is that the
// packages in `assets/extensions/` are readable, hash-checked and installable as they ship.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/sources/drift_extension_store.dart';
import 'package:kikuyomi/src/sources/extension_console.dart';
import 'package:kikuyomi/src/sources/extension_library.dart';
import 'package:kikuyomi/src/sources/first_run.dart';
import 'package:kikuyomi/src/sources/source_registry.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_networking/kikuyomi_networking.dart' as net;
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

const appVersion = '1.0.0+1';

/// An engine that is never started: nothing here runs an extension's code.
final class _NoEngine implements ScriptEngineFactory {
  const _NoEngine();

  @override
  ScriptEngine create(ScriptRuntimeLimits limits) =>
      throw UnsupportedError('no engine in this test');
}

void main() {
  // The assets are read through rootBundle, which needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late KikuyomiDatabase db;
  late InMemorySettingsStore settings;
  late ExtensionConsole console;
  late FakeClock clock;
  late SourceRegistry registry;
  late ExtensionLibrary library;

  Future<void> start() async {
    registry = await SourceRegistry.start(
      database: db,
      network: net.NetworkService(
        policy: const net.NetworkPolicy(userAgent: 'Kikuyomi/1.0.0'),
      ),
      store: DriftExtensionStore(db),
      log: console,
      host: const HostFacts(appVersion: appVersion),
      engineFactory: const _NoEngine(),
      appVersion: appVersion,
      extensions: await readExtensionsAtStart(
        database: db,
        installs: ExtensionInstallFolder(Directory('${temp.path}/installed')),
        console: console,
        clock: clock,
      ),
      onError: (id, error, stack) => console.report(id, error),
    );
    library = ExtensionLibrary(
      sources: registry,
      console: console,
      database: db,
      installs: ExtensionInstallFolder(Directory('${temp.path}/installed')),
      folders: FakeUserFolders(),
      dropFolder: Directory('${temp.path}/Extensions'),
      clock: clock,
      canInstallFromDropFolder: false,
    );
  }

  Future<void> seed() => seedOfficialRepository(
    database: db,
    settings: settings,
    extensions: library,
    console: console,
  );

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('kikuyomi_first_run');
    db = KikuyomiDatabase(NativeDatabase.memory());
    settings = InMemorySettingsStore();
    console = ExtensionConsole(clock: clock = FakeClock(DateTime.utc(2026, 9)));
    await start();
  });

  tearDown(() async {
    await registry.dispose();
    await console.dispose();
    await db.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<List<ExtensionRow>> installed() => readInstalledExtensions(db);

  group('a first run', () {
    test('installs every extension the app ships with', () async {
      await seed();

      expect(
        {for (final row in await installed()) row.id},
        {
          'org.kikuyomi.librivox',
          'org.kikuyomi.internetarchive',
          'org.kikuyomi.storynory',
          'org.kikuyomi.podcasts',
          'org.kikuyomi.standardebooks',
          'org.kikuyomi.gutenberg',
        },
      );
    });

    test(
      'records them as coming from the repository, not as bundled',
      () async {
        // The whole reason for doing it this way: §3.9's update check looks at the repository an
        // extension came from, and a bundled one came from nowhere, so it could never be updated.
        await seed();

        for (final row in await installed()) {
          expect(row.origin, ExtensionOrigin.repository, reason: row.id);
          expect(row.originHandle, officialRepositoryUrl, reason: row.id);
        }
      },
    );

    test('and as active, because their hashes were checked', () async {
      await seed();

      for (final row in await installed()) {
        expect(row.status, ExtensionStatus.active, reason: row.id);
      }
    });

    test('pins the official repository', () async {
      await seed();

      final repository = await readRepositoryAt(db, officialRepositoryUrl);
      expect(repository, isNotNull);
      expect(repository!.name, 'Kikuyomi official');
      expect(repository.publicKey, isNotEmpty);
      expect(repository.fingerprint, contains(':'));
    });

    test('gives every shipped source to Browse', () async {
      await seed();

      final ids = {for (final source in registry.sources) source.key};
      expect(ids, containsAll(['librivox', 'internetarchive', 'podcasts']));
    });
  });

  group('every run after the first', () {
    test('changes nothing', () async {
      await seed();
      final before = await installed();

      await seed();

      expect(await installed(), hasLength(before.length));
      expect(
        await readRepositoryAt(db, officialRepositoryUrl),
        isNotNull,
        reason: 'and does not add the repository twice',
      );
    });

    test('does not put back an extension the listener removed', () async {
      // The one that would be worst to get wrong: a removal undone by the next restart is not a
      // removal. A fresh install and a removal look the same in the table, so the difference is
      // remembered in settings rather than inferred.
      await seed();
      await library.remove('org.kikuyomi.storynory');

      await seed();

      expect({
        for (final row in await installed()) row.id,
      }, isNot(contains('org.kikuyomi.storynory')));
    });

    test('installs an extension shipped since the last start', () async {
      // An install seeded before Standard Ebooks shipped, recorded as the app then recorded it:
      // seeded, with no list of what was offered.
      await settings.write(AppSettings.shippedExtensionsSeeded, true);

      await seed();

      expect({
        for (final row in await installed()) row.id,
      }, contains('org.kikuyomi.standardebooks'));
      expect(
        settings.read(AppSettings.shippedExtensionsOffered),
        containsAll(shippedExtensionNames),
      );
    });

    test('does not put back a later extension the listener removed', () async {
      await seed();
      await library.remove('org.kikuyomi.standardebooks');

      await seed();

      expect({
        for (final row in await installed()) row.id,
      }, isNot(contains('org.kikuyomi.standardebooks')));
    });

    test('does not add the repository back after it was removed', () async {
      await seed();
      final repository = await readRepositoryAt(db, officialRepositoryUrl);
      await removeRepository(db, repository!.id);

      await seed();

      expect(await readRepositoryAt(db, officialRepositoryUrl), isNull);
    });

    test('leaves a newer version alone', () async {
      // A listener on a version newer than the app shipped with must not be walked backwards.
      await seed();
      final row = (await installed()).firstWhere(
        (e) => e.id == 'org.kikuyomi.podcasts',
      );
      await recordInstalledExtension(
        db,
        id: row.id,
        name: row.name,
        version: '9.9.9',
        versionCode: 999,
        apiVersion: row.apiVersion,
        status: ExtensionStatus.active,
        origin: ExtensionOrigin.repository,
        originHandle: officialRepositoryUrl,
        installPath: row.installPath,
        clock: clock,
      );

      await seed();

      final after = (await installed()).firstWhere((e) => e.id == row.id);
      expect(after.versionCode, 999);
    });
  });

  test(
    'an install left over as bundled is moved onto the repository',
    () async {
      // What an existing library looks like: LibriVox was bundled inside the app, so its row says it
      // came from nowhere and nothing would ever offer it an update.
      await recordInstalledExtension(
        db,
        id: 'org.kikuyomi.librivox',
        name: 'LibriVox',
        version: '1.0.0',
        versionCode: 1,
        apiVersion: '1.0',
        status: ExtensionStatus.active,
        origin: ExtensionOrigin.bundled,
        clock: clock,
      );
      await settings.write(AppSettings.shippedExtensionsSeeded, true);

      await seed();

      final row = (await installed()).firstWhere(
        (e) => e.id == 'org.kikuyomi.librivox',
      );
      expect(row.origin, ExtensionOrigin.repository);
      expect(row.originHandle, officialRepositoryUrl);
    },
  );
}
