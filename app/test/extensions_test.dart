// Installing an extension from a folder, reloading it, and removing it: Step A's whole point, through
// the pieces that really do it — a real database, real folders on disk, the real registry.
//
// Only the JavaScript engine is missing, because its native library exists only inside a built app. No
// test here opens a source, so nothing needs one; what the engine and the real extension do together is
// checked by the probes in spikes/quickjs_binding.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/sources/drift_extension_store.dart';
import 'package:kikuyomi/src/sources/extension_console.dart';
import 'package:kikuyomi/src/sources/extension_library.dart';
import 'package:kikuyomi/src/sources/source_registry.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_networking/kikuyomi_networking.dart' as net;
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

const appVersion = '1.0.0+1';
const extensionId = 'org.example.librivox';

/// A source folder's `main.js`. Nothing runs it here.
const code = 'export default { librivox: {} };\n';

Map<String, Object?> manifestData({
  Map<String, Object?> changed = const {},
}) => {
  'id': extensionId,
  'name': 'LibriVox',
  'version': '1.4.0',
  'versionCode': 14,
  'apiVersion': '1.0',
  'minAppVersion': '1.0.0',
  'author': 'Example Maintainers',
  'contentRating': 'everyone',
  'domains': ['librivox.org'],
  'capabilities': ['filters'],
  'sources': [
    {'key': 'librivox', 'name': 'LibriVox', 'lang': 'multi', 'versionId': 1},
  ],
  'files': {'main.js': 'sha256-not-the-hash-of-the-edited-file'},
  ...changed,
};

/// An engine that is never started. Opening a source would need one; nothing here does.
final class _NoEngine implements ScriptEngineFactory {
  const _NoEngine();

  @override
  ScriptEngine create(ScriptRuntimeLimits limits) =>
      throw StateError('no test here runs an extension');
}

void main() {
  // The bundled extension is read from the app's own assets, and rootBundle needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late KikuyomiDatabase db;
  late ExtensionConsole console;
  late FakeClock clock;
  late FakeUserFolders folders;
  late ExtensionInstallFolder installs;
  late SourceRegistry registry;
  late ExtensionLibrary library;

  /// Starts the app's extension subsystem the way the composition root does.
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
        installs: installs,
        console: console,
        clock: clock,
      ),
      onError: (id, error, stack) => console.report(id, error),
    );
    library = ExtensionLibrary(
      sources: registry,
      console: console,
      database: db,
      installs: installs,
      folders: folders,
      dropFolder: Directory('${temp.path}/Extensions'),
      clock: clock,
      canInstallFromDropFolder: false,
    );
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('kikuyomi_extensions');
    db = KikuyomiDatabase(NativeDatabase.memory());
    console = ExtensionConsole(clock: clock = FakeClock(_startedAt));
    folders = FakeUserFolders();
    installs = ExtensionInstallFolder(Directory('${temp.path}/installed'));
    await start();
  });

  tearDown(() async {
    await registry.dispose();
    await console.dispose();
    await db.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// A folder holding an extension, as an author's working folder looks.
  Future<Directory> folderWith({
    String name = 'work',
    Map<String, Object?> changed = const {},
    String main = code,
    bool withManifest = true,
  }) async {
    final folder = await Directory('${temp.path}${Platform.pathSeparator}$name')
        .create(recursive: true);
    if (withManifest) {
      await File('${folder.path}/manifest.json')
          .writeAsString(jsonEncode(manifestData(changed: changed)));
    }
    await File('${folder.path}/main.js').writeAsString(main);
    return folder;
  }

  ExtensionSummary? summaryOf(List<ExtensionSummary> all, String id) =>
      all.where((e) => e.id == id).firstOrNull;

  group('going back to an earlier version (§3.9)', () {
    // The versioned directory is what makes this possible: an update is written into a folder of
    // its own rather than over the last one, so the version that worked is still on disk. Nothing
    // here touches the network, which is the point -- an extension is rolled back exactly when
    // something has stopped working, and a listener may well be offline when it does.

    /// Installs [versionCode] of the test extension from a folder.
    Future<ExtensionSummary> installVersion(int versionCode) async {
      final folder = await folderWith(
        name: 'work-$versionCode',
        changed: {'version': '1.$versionCode.0', 'versionCode': versionCode},
      );
      return library.installFromPath(folder.path);
    }

    test('an install keeps what was there before', () async {
      await installVersion(14);
      await installVersion(15);

      expect(await installs.versionsOf(extensionId), [15, 14]);
    });

    test('the summary offers the ones that are not in use', () async {
      await installVersion(14);
      await installVersion(15);

      final summary = summaryOf(await library.read(), extensionId)!;
      expect(summary.earlierVersions, [14]);
      expect(summary.canRollBack, isTrue);
    });

    test('a single install has nowhere to go back to', () async {
      await installVersion(14);

      expect(
        summaryOf(await library.read(), extensionId)!.canRollBack,
        isFalse,
      );
    });

    test('rolling back puts the row and the source on the old one', () async {
      await installVersion(14);
      await installVersion(15);

      final back = await library.rollBackTo(extensionId, 14);

      expect(back.row.versionCode, 14);
      expect(back.row.version, '1.14.0');
      expect(back.isRunnable, isTrue);
      // One extension is one row holding the version in use, so the app, the screen and the next
      // update check all agree about which that is.
      final row = await readInstalledExtension(db, extensionId);
      expect(row!.versionCode, 14);
    });

    test('and the newer one is still there to come back to', () async {
      await installVersion(14);
      await installVersion(15);
      await library.rollBackTo(extensionId, 14);

      final summary = summaryOf(await library.read(), extensionId)!;
      expect(summary.earlierVersions, [15]);
    });

    test('rolling back to the version in use is refused', () async {
      await installVersion(14);

      await expectLater(
        library.rollBackTo(extensionId, 14),
        throwsA(
          isA<ExtensionInstallException>().having(
            (e) => e.message,
            'message',
            contains('already in use'),
          ),
        ),
      );
    });

    test('rolling back to one that was never installed is refused', () async {
      await installVersion(14);

      await expectLater(
        library.rollBackTo(extensionId, 99),
        throwsA(isA<ExtensionInstallException>()),
      );
    });

    test('the extension inside the app cannot be rolled back', () async {
      // Its code is part of the app. There is no earlier copy of it anywhere.
      await expectLater(
        library.rollBackTo('org.kikuyomi.librivox', 1),
        throwsA(
          isA<ExtensionInstallException>().having(
            (e) => e.message,
            'message',
            contains('ships inside Kikuyomi'),
          ),
        ),
      );
    });

    test('uninstalling takes every version with it', () async {
      await installVersion(14);
      await installVersion(15);
      await library.remove(extensionId);

      expect(await installs.versionsOf(extensionId), isEmpty);
    });
  });

  group('the extension that ships inside the app', () {
    test('is listed, and cannot be removed', () async {
      final bundled = summaryOf(await library.read(), 'org.kikuyomi.librivox');

      expect(bundled, isNotNull);
      expect(bundled!.isBundled, isTrue);
      expect(bundled.isUnverified, isFalse, reason: 'its hashes were checked');
      expect(bundled.canReload, isFalse);
      expect(bundled.isRunnable, isTrue);
      await expectLater(
        library.remove(bundled.id),
        throwsA(isA<ExtensionInstallException>()),
      );
    });

    test('keeps the day it arrived when the app starts again', () async {
      final first = summaryOf(await library.read(), 'org.kikuyomi.librivox')!;
      clock.advance(const Duration(days: 2));
      await registry.dispose();
      await start();

      final again = summaryOf(await library.read(), 'org.kikuyomi.librivox')!;
      expect(again.row.installedAt, first.row.installedAt);
    });
  });

  group('installing from a folder', () {
    test('copies the files in and offers its sources', () async {
      final folder = await folderWith();

      final installed = await library.installFromPath(folder.path);

      expect(installed.id, extensionId);
      expect(installed.row.version, '1.4.0');
      expect(installed.row.origin, ExtensionOrigin.folder);
      expect(installed.row.originHandle, folder.absolute.path);
      expect(installed.row.installPath, '$extensionId/14');
      expect(
        registry.sources.where((s) => s.extensionId == extensionId).single.name,
        'LibriVox',
      );
      expect(
        await File(
          '${installs.root.path}${Platform.pathSeparator}$extensionId'
          '${Platform.pathSeparator}14${Platform.pathSeparator}main.js',
        ).readAsString(),
        code,
      );
    });

    test('is unverified, because nothing checked its code (§3.8)', () async {
      // The manifest here names a hash that is not the hash of main.js, which is what an author's
      // folder looks like after an edit. It installs, and says that nothing was checked.
      final installed = await library.installFromPath(
        (await folderWith()).path,
      );

      expect(installed.row.status, ExtensionStatus.untrusted);
      expect(installed.isUnverified, isTrue);
    });

    test('is still installed after a restart', () async {
      await library.installFromPath((await folderWith()).path);

      await registry.dispose();
      await start();

      expect(summaryOf(await library.read(), extensionId)?.isRunnable, isTrue);
      expect(
        registry.sources.where((s) => s.extensionId == extensionId),
        hasLength(1),
      );
    });

    test('survives the folder it came from being deleted', () async {
      final folder = await folderWith();
      await library.installFromPath(folder.path);
      await folder.delete(recursive: true);

      await registry.dispose();
      await start();

      expect(summaryOf(await library.read(), extensionId)?.isRunnable, isTrue);
    });

    test('through the picker, which a cancel leaves alone', () async {
      folders.nextChoice = FakeUserFolder(
        handle: 'content://tree/librivox',
        displayName: 'librivox',
        files: {
          'manifest.json': utf8.encode(jsonEncode(manifestData())),
          'main.js': utf8.encode(code),
        },
      );

      final installed = await library.installFromPickedFolder();

      expect(installed, isNotNull);
      expect(installed!.row.originHandle, 'content://tree/librivox');
      expect(installed.row.originName, 'librivox');

      folders.nextChoice = null;
      expect(await library.installFromPickedFolder(), isNull);
    });

    test('says what is wrong with a folder that is not an extension', () async {
      final folder = await folderWith(withManifest: false);

      await expectLater(
        library.installFromPath(folder.path),
        throwsA(
          isA<ExtensionInstallException>().having(
            (e) => e.message,
            'message',
            contains('manifest.json'),
          ),
        ),
      );
      expect(await readInstalledExtension(db, extensionId), isNull);
    });

    test('refuses one this app is too old for, and installs nothing', () async {
      final folder = await folderWith(changed: {'minAppVersion': '9.0.0'});

      await expectLater(
        library.installFromPath(folder.path),
        throwsA(
          isA<ExtensionInstallException>().having(
            (e) => e.message,
            'message',
            contains('needs Kikuyomi 9.0.0'),
          ),
        ),
      );
      expect(await readInstalledExtension(db, extensionId), isNull);
      expect(
        registry.sources.where((s) => s.extensionId == extensionId),
        isEmpty,
      );
    });

    test('tells the console what it did', () async {
      await library.installFromPath((await folderWith()).path);

      expect(
        console.linesOf(extensionId).map((line) => line.text).join('\n'),
        contains('Installed 1.4.0'),
      );
    });
  });

  group('reloading', () {
    test('picks up an edit without a restart (§3.11)', () async {
      final folder = await folderWith();
      await library.installFromPath(folder.path);
      await File('${folder.path}/main.js')
          .writeAsString('export default {};\n');

      final reloaded = await library.reload(extensionId);

      expect(reloaded.row.installPath, '$extensionId/14');
      expect(
        (await readExtensionPackage(
          installs.filesAt(reloaded.row.installPath!),
          checkHashes: false,
        )).code,
        'export default {};\n',
      );
    });

    test('says so when the folder is gone', () async {
      final folder = await folderWith();
      await library.installFromPath(folder.path);
      await folder.delete(recursive: true);

      await expectLater(
        library.reload(extensionId),
        throwsA(isA<ExtensionInstallException>()),
      );
    });

    test('is not offered for the extension inside the app', () async {
      await expectLater(
        library.reload('org.kikuyomi.librivox'),
        throwsA(
          isA<ExtensionInstallException>().having(
            (e) => e.message,
            'message',
            contains('did not come from a folder'),
          ),
        ),
      );
    });
  });

  group('removing an extension (§3.9)', () {
    late int sourceId;

    setUp(() async {
      await library.installFromPath((await folderWith()).path);
      sourceId = registry.sources
          .firstWhere((s) => s.extensionId == extensionId)
          .id;
    });

    test('takes its code and its row', () async {
      await library.remove(extensionId);

      expect(await readInstalledExtension(db, extensionId), isNull);
      expect(
        await Directory(
          '${installs.root.path}${Platform.pathSeparator}$extensionId',
        ).exists(),
        isFalse,
      );
    });

    /// A book of this extension's source, in the library, which is the only reason §3.9 keeps a
    /// source row after its extension goes.
    Future<void> aBookFromIt() => db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            sourceId: sourceId,
            key: 'a-book',
            title: 'A Book',
            inLibrary: const Value(true),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );

    test('leaves its source as a stub the library can still name', () async {
      await aBookFromIt();
      await library.remove(extensionId);

      final source = registry.describe(sourceId);
      expect(source, isNotNull);
      expect(source!.name, 'LibriVox');
      expect(source.isMissing, isTrue);
      expect(source.canBrowse, isFalse);
      expect(
        registry.browsable.where((s) => s.id == sourceId),
        isEmpty,
        reason: 'Browse does not offer a catalogue that cannot be reached',
      );
    });

    test('a book from it can still say why it will not play', () async {
      await aBookFromIt();
      await library.remove(extensionId);

      await expectLater(
        registry.open(sourceId),
        throwsA(isA<ExtensionMissingException>()),
      );
    });

    test('and with no books left, the source goes too', () async {
      // The stub is there for the books. With none, what is left is a row naming an extension
      // nobody has, which a listener sees as a dead entry in Browse they cannot get rid of.
      await library.remove(extensionId);

      expect(registry.describe(sourceId), isNull);
    });

    test('keeps what the extension had stored', () async {
      final store = DriftExtensionStore(db);
      await store.write(extensionId, 'catalogue', 'audiobooks');

      await library.remove(extensionId);

      expect(await store.readAll(extensionId), {'catalogue': 'audiobooks'});
    });

    test('and the stub is gone once it is installed again', () async {
      await library.remove(extensionId);

      await library.installFromPath((await folderWith(name: 'again')).path);

      final source = registry.describe(sourceId);
      expect(source!.isMissing, isFalse);
      expect(source.canBrowse, isTrue);
      expect(
        registry.sources.where((s) => s.id == sourceId),
        hasLength(1),
        reason: 'the source it had before is the source it has again',
      );
    });

    test('a removal it never had is not a failure', () async {
      await expectLater(library.remove('org.example.nothing'), completes);
    });
  });

  test('the source list is handed out again after every change', () async {
    final counts = <int>[];
    final subscription = registry.changes.listen(
      (sources) => counts.add(sources.length),
    );
    addTearDown(subscription.cancel);

    await library.installFromPath((await folderWith()).path);
    await library.remove(extensionId);
    await pumpEventQueue();

    expect(
      counts,
      [3, 2],
      reason:
          'Local, the bundled extension and the installed one; then, with the '
          'installed one gone and no books left from it to keep a stub for, '
          'Local and the bundled one',
    );
  });
}

final _startedAt = DateTime.utc(2026, 9, 23, 9);
