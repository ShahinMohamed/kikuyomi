// An extension package as a repository serves it: one zip.
//
// The two cases worth having written down are the ones that come from real archive tools rather than
// from a spec. Someone zipping the folder rather than its contents produces a package wrapped in one
// directory, which is the commonest mistake an author makes. And an entry naming a path outside the
// archive is not a mistake at all.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:test/test.dart';

/// A zip holding [files], as an archive tool would write one.
Uint8List zipOf(Map<String, String> files) {
  final archive = Archive();
  for (final file in files.entries) {
    final bytes = utf8.encode(file.value);
    archive.addFile(ArchiveFile.bytes(file.key, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

PackageLocation listedAs(Uint8List bytes) => PackageLocation(
  url: 'https://example.org/a.zip',
  sha256: sha256.convert(bytes).toString(),
);

Matcher refuses(String naming) => throwsA(
  isA<PackageRefused>().having((e) => e.message, 'message', contains(naming)),
);

void main() {
  group('reading one', () {
    test('gives back the files it holds', () async {
      final files = ZipExtensionFiles.read(
        zipOf({'manifest.json': '{}', 'main.js': 'export default {}'}),
        description: 'a package',
      );

      expect(utf8.decode(await files.read('manifest.json')), '{}');
      expect(utf8.decode(await files.read('main.js')), 'export default {}');
    });

    test(
      'unwraps the folder somebody zipped instead of its contents',
      () async {
        // What every archive tool produces when the folder is dragged in rather than opened.
        final files = ZipExtensionFiles.read(
          zipOf({'librivox/manifest.json': '{}', 'librivox/main.js': 'code'}),
          description: 'a package',
        );

        expect(utf8.decode(await files.read('manifest.json')), '{}');
        expect(files.names, containsAll(['manifest.json', 'main.js']));
      },
    );

    test('leaves out an entry naming somewhere outside itself', () {
      // Not a mistake. An archive is a place where a path like this is somebody trying something.
      final files = ZipExtensionFiles.read(
        zipOf({'../escape.js': 'code', 'main.js': 'code'}),
        description: 'a package',
      );

      expect(files.names, ['main.js']);
    });

    test('says what is there when something expected is not', () async {
      // The message an author gets for a package assembled wrong, and it is worth more than "no
      // such file".
      final files = ZipExtensionFiles.read(
        zipOf({'manifest.json': '{}', 'readme.md': 'hello'}),
        description: 'a package',
      );

      await expectLater(
        files.read('main.js'),
        throwsA(
          isA<ExtensionPackageException>().having(
            (e) => e.message,
            'message',
            allOf(contains('main.js'), contains('readme.md')),
          ),
        ),
      );
    });

    test('bytes that are not a zip are refused', () {
      expect(
        () => ZipExtensionFiles.read(
          Uint8List.fromList(utf8.encode('<!doctype html>')),
          description: 'a package',
        ),
        refuses('not a readable zip'),
      );
    });
  });

  group('checking it is the one that was listed (§3.8)', () {
    test('accepts the bytes the index named', () async {
      final bytes = zipOf({'manifest.json': '{}'});

      final files = ZipExtensionFiles.verified(
        bytes,
        expected: listedAs(bytes),
        description: 'LibriVox 1.4.0',
      );

      expect(utf8.decode(await files.read('manifest.json')), '{}');
    });

    test('refuses bytes that hash to something else', () {
      // What catches a truncated or corrupted download. It proves the bytes are the ones the index
      // listed and nothing about who wrote the index.
      final listed = listedAs(zipOf({'manifest.json': '{}'}));

      expect(
        () => ZipExtensionFiles.verified(
          zipOf({'manifest.json': '{"different": true}'}),
          expected: listed,
          description: 'LibriVox 1.4.0',
        ),
        refuses('not the package the repository listed'),
      );
    });

    test('names both hashes, so the mismatch can be looked into', () {
      final listed = listedAs(zipOf({'a': '1'}));

      expect(
        () => ZipExtensionFiles.verified(
          zipOf({'a': '2'}),
          expected: listed,
          description: 'a package',
        ),
        refuses(listed.sha256),
      );
    });

    test('is checked before the archive is opened at all', () {
      // A package that is not the one listed should not have its contents read, whatever they are.
      expect(
        () => ZipExtensionFiles.verified(
          Uint8List.fromList(utf8.encode('not a zip')),
          expected: listedAs(zipOf({'a': '1'})),
          description: 'a package',
        ),
        refuses('not the package the repository listed'),
      );
    });
  });
}
