// What an extension says about itself. It comes from the same third party its code does, so it is
// read as strictly as a result is: every field checked, the first bad one named, and nothing
// half-read.

import 'dart:convert';

import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:test/test.dart';

/// §3.3's own example, which every test starts from and then breaks one field of.
Map<String, Object?> manifestData({
  Map<String, Object?> changed = const {},
  List<String> removed = const [],
}) => {
  'id': 'org.example.librivox',
  'name': 'LibriVox',
  'version': '1.4.0',
  'versionCode': 14,
  'apiVersion': '1.0',
  'minAppVersion': '1.0.0',
  'author': 'Example Maintainers',
  'contentRating': 'everyone',
  'domains': ['librivox.org', 'archive.org', '*.us.archive.org'],
  'capabilities': ['latest', 'filters', 'settings'],
  'sources': [
    {'key': 'librivox', 'name': 'LibriVox', 'lang': 'en', 'versionId': 1},
  ],
  'files': {'main.js': 'sha256-abc', 'icon.png': 'sha256-def'},
  ...changed,
}..removeWhere((key, value) => removed.contains(key));

ExtensionManifest read({
  Map<String, Object?> changed = const {},
  List<String> removed = const [],
}) => ExtensionManifest.parse(
  jsonEncode(manifestData(changed: changed, removed: removed)),
);

Matcher refuses(String field) => throwsA(
  isA<ManifestException>().having(
    (error) => error.message,
    'message',
    startsWith('$field:'),
  ),
);

void main() {
  _bookFileCapability();

  test('reads the manifest the architecture writes down', () {
    final manifest = read();

    expect(manifest.id, 'org.example.librivox');
    expect(manifest.name, 'LibriVox');
    expect(manifest.version.toString(), '1.4.0');
    expect(manifest.versionCode, 14);
    expect(manifest.apiVersion, const ApiVersion(1, 0));
    expect(manifest.minAppVersion.toString(), '1.0.0');
    expect(manifest.author, 'Example Maintainers');
    expect(manifest.contentRating, ExtensionContentRating.everyone);
    expect(manifest.domains.domains, [
      'librivox.org',
      'archive.org',
      '*.us.archive.org',
    ]);
    expect(manifest.capabilities, {'latest', 'filters', 'settings'});
    expect(manifest.sources.single.key, 'librivox');
    expect(manifest.sources.single.lang, 'en');
    expect(manifest.files['main.js'], 'sha256-abc');
  });

  test('the domains are the ones the http bridge will enforce', () {
    final domains = read().domains;

    expect(domains.allowsHost('librivox.org'), isTrue);
    expect(domains.allowsHost('ia800.us.archive.org'), isTrue);
    // A wildcard covers subdomains, never the domain itself, so a manifest that needs both lists
    // both — which this one does for archive.org and not for us.archive.org.
    expect(domains.allowsHost('us.archive.org'), isFalse);
    expect(domains.allowsHost('tracker.example.net'), isFalse);
  });

  test('the capabilities it claims map to the optional methods', () {
    expect(read().declaredCapabilities, {
      SourceCapability.latest,
      SourceCapability.filters,
    });
    // A capability a later minor version adds is kept, and means nothing to this app.
    expect(read().capabilities, contains('settings'));
  });

  group('the contract version', () {
    test('this app implements is supported', () {
      expect(read().compatibility(), ApiCompatibility.supported);
    });

    test('a newer minor than this app implements needs a newer app', () {
      expect(
        read(changed: {'apiVersion': '1.4'}).compatibility(),
        ApiCompatibility.needsNewerApp,
      );
      expect(
        read(changed: {'apiVersion': '2.0'}).compatibility(),
        ApiCompatibility.needsNewerApp,
      );
    });

    test('a major this app no longer supports is obsolete', () {
      expect(
        read(changed: {'apiVersion': '1.0'})
            .compatibility(const SupportedApiVersions({2: 1})),
        ApiCompatibility.obsolete,
      );
    });

    test('that is not two numbers is refused', () {
      expect(() => read(changed: {'apiVersion': '1'}), refuses('apiVersion'));
      expect(
        () => read(changed: {'apiVersion': '1.0.1'}),
        refuses('apiVersion'),
      );
      expect(
        () => read(changed: {'apiVersion': '01.0'}),
        refuses('apiVersion'),
      );
      expect(() => read(changed: {'apiVersion': 1.0}), refuses('apiVersion'));
      expect(() => read(removed: ['apiVersion']), refuses('apiVersion'));
    });
  });

  group('the app version it needs', () {
    test('is compared as numbers, not as text', () {
      final manifest = read(changed: {'minAppVersion': '1.10.0'});

      expect(manifest.runsOn(SoftwareVersion.parse('1.9.0')), isFalse);
      expect(manifest.runsOn(SoftwareVersion.parse('1.10.0')), isTrue);
      expect(manifest.runsOn(SoftwareVersion.parse('2.0')), isTrue);
      // Missing parts are zero, so 1.10 and 1.10.0 are one version.
      expect(manifest.runsOn(SoftwareVersion.parse('1.10')), isTrue);
    });

    test('that is not a version is refused', () {
      expect(
        () => read(changed: {'minAppVersion': '1.0-beta'}),
        refuses('minAppVersion'),
      );
      expect(
        () => read(changed: {'minAppVersion': '1.0.0.0.0'}),
        refuses('minAppVersion'),
      );
      expect(() => read(changed: {'version': ''}), refuses('version'));
    });
  });

  group('an id', () {
    test('reads like a reversed domain name', () {
      expect(read(changed: {'id': 'io.github.someone.books'}).id, isNotEmpty);
      expect(read(changed: {'id': 'org.example.libri-vox'}).id, isNotEmpty);
    });

    test('that is a name rather than an identifier is refused', () {
      for (final id in [
        'LibriVox',
        'librivox',
        'org example',
        'org..example',
        '.org.example',
        'org.example.',
        '',
      ]) {
        expect(() => read(changed: {'id': id}), refuses('id'), reason: id);
      }
    });
  });

  group("a source's kind (1.1)", () {
    Map<String, Object?> source({Object? kind}) => {
      'key': 'novels',
      'name': 'Novels',
      'lang': 'en',
      'versionId': 1,
      'kind': ?kind,
    };

    test('is audio when it does not say, as every 1.0 source does not', () {
      expect(read().sources.single.kind, SourceKind.audio);
    });

    test('may say audio outright', () {
      final manifest = read(
        changed: {
          'sources': [source(kind: 'audio')],
        },
      );
      expect(manifest.sources.single.kind, SourceKind.audio);
    });

    test('may be text when the manifest targets 1.1', () {
      final manifest = read(
        changed: {
          'apiVersion': '1.1',
          'sources': [source(kind: 'text')],
        },
      );
      expect(manifest.sources.single.kind, SourceKind.text);
    });

    test('is refused as text when the manifest targets 1.0', () {
      // A 1.0 app ignores fields it does not know, so it would read this source as audio and call
      // resolveMedia on something that has none. Requiring 1.1 keeps it away from that app entirely.
      expect(
        () => read(
          changed: {
            'sources': [source(kind: 'text')],
          },
        ),
        refuses('sources[0].kind'),
      );
    });

    test('is refused when it is a kind this build does not know', () {
      // Read as audio, a later kind would be played as something it is not. Refused, it tells the
      // listener to update instead.
      expect(
        () => read(
          changed: {
            'apiVersion': '1.1',
            'sources': [source(kind: 'comics')],
          },
        ),
        refuses('sources[0].kind'),
      );
    });

    test('may differ between the sources of one extension', () {
      // One extension may offer both, which is why kind lives on the source and not the extension.
      final manifest = read(
        changed: {
          'apiVersion': '1.1',
          'sources': [
            {...source(kind: 'audio'), 'key': 'audio'},
            {...source(kind: 'text'), 'key': 'text'},
          ],
        },
      );
      expect(
        [for (final s in manifest.sources) s.kind],
        [SourceKind.audio, SourceKind.text],
      );
    });
  });

  group('sources', () {
    test('keep the order the manifest lists them in', () {
      final manifest = read(
        changed: {
          'sources': [
            {'key': 'en', 'name': 'English', 'lang': 'en', 'versionId': 1},
            {'key': 'pt', 'name': 'Português', 'lang': 'pt-BR', 'versionId': 2},
          ],
        },
      );

      expect(manifest.sources.map((source) => source.key), ['en', 'pt']);
      expect(manifest.sources.last.lang, 'pt-BR');
    });

    test('each get the id §3.7 gives them, which the extension is part of', () {
      final source = read().sources.single;

      final mine = source.idWithin('org.example.librivox');
      final theirs = source.idWithin('net.example.librivox');

      // The same source key under another extension is another source, so two repositories cannot
      // collide by choosing the same name.
      expect(mine, isNot(theirs));
      // And it is stable: the same four values always give the same id.
      expect(source.idWithin('org.example.librivox'), mine);
    });

    test('a source whose keys have changed gets a new id', () {
      final before = read().sources.single;
      final after = read(
        changed: {
          'sources': [
            {
              'key': 'librivox',
              'name': 'LibriVox',
              'lang': 'en',
              'versionId': 2,
            },
          ],
        },
      ).sources.single;

      expect(
        after.idWithin('org.example.librivox'),
        isNot(before.idWithin('org.example.librivox')),
      );
    });

    test('an extension with none is refused', () {
      expect(() => read(changed: {'sources': <Object?>[]}), refuses('sources'));
      expect(() => read(removed: ['sources']), refuses('sources'));
    });

    test('two sources under one key are refused', () {
      expect(
        () => read(
          changed: {
            'sources': [
              {'key': 'a', 'name': 'One', 'lang': 'en', 'versionId': 1},
              {'key': 'a', 'name': 'Two', 'lang': 'fr', 'versionId': 1},
            ],
          },
        ),
        refuses('sources[1].key'),
      );
    });

    test('a language that is not a tag is refused', () {
      expect(
        () => read(
          changed: {
            'sources': [
              {'key': 'a', 'name': 'One', 'lang': 'English', 'versionId': 1},
            ],
          },
        ),
        refuses('sources[0].lang'),
      );
      // A catalogue that is not one language says so.
      expect(
        read(
          changed: {
            'sources': [
              {'key': 'a', 'name': 'One', 'lang': 'multi', 'versionId': 1},
            ],
          },
        ).sources.single.lang,
        'multi',
      );
    });

    test('a versionId that is not a number is refused', () {
      expect(
        () => read(
          changed: {
            'sources': [
              {'key': 'a', 'name': 'One', 'lang': 'en', 'versionId': '1'},
            ],
          },
        ),
        refuses('sources[0].versionId'),
      );
    });
  });

  group('the permissions summary', () {
    test('a rating this app does not know is read as the strictest', () {
      expect(
        read(changed: {'contentRating': 'teen'}).contentRating,
        ExtensionContentRating.adult,
      );
      expect(
        read(changed: {'contentRating': 'mature'}).contentRating,
        ExtensionContentRating.mature,
      );
      expect(
        read(removed: ['contentRating']).contentRating,
        ExtensionContentRating.everyone,
      );
    });

    test('a domain that is not one is refused, with the reason', () {
      expect(
        () => read(
          changed: {
            'domains': ['*.com'],
          },
        ),
        refuses('domains'),
      );
      expect(
        () => read(
          changed: {
            'domains': ['127.0.0.1'],
          },
        ),
        refuses('domains'),
      );
      expect(
        () => read(
          changed: {
            'domains': ['localhost'],
          },
        ),
        refuses('domains'),
      );
      expect(
        () => read(
          changed: {
            'domains': ['https://example.org/'],
          },
        ),
        refuses('domains'),
      );
      expect(
        () => read(changed: {'domains': 'example.org'}),
        refuses('domains'),
      );
    });

    test('an extension that contacts nothing is allowed', () {
      final manifest = read(changed: {'domains': <Object?>[]});

      expect(manifest.domains.domains, isEmpty);
      expect(manifest.domains.allowsHost('example.org'), isFalse);
    });
  });

  group('a manifest that is not one', () {
    test('is refused rather than half-read', () {
      expect(
        () => ExtensionManifest.parse('not json'),
        throwsA(isA<ManifestException>()),
      );
      expect(
        () => ExtensionManifest.parse('[]'),
        throwsA(isA<ManifestException>()),
      );
      expect(() => read(removed: ['name']), refuses('name'));
      expect(() => read(changed: {'versionCode': 0}), refuses('versionCode'));
      expect(
        () => read(changed: {'versionCode': '14'}),
        refuses('versionCode'),
      );
      expect(() => read(changed: {'name': 'a\u0000b'}), refuses('name'));
    });

    test('an author is not required, because a repository knows its own', () {
      expect(read(removed: ['author']).author, isEmpty);
    });

    test('unknown fields are ignored, so a later version still reads', () {
      final manifest = read(changed: {'sponsorship': 'https://example.org/'});

      expect(manifest.id, 'org.example.librivox');
    });

    test(
      'the file hashes are kept as written, and nothing here trusts them',
      () {
        expect(read(removed: ['files']).files, isEmpty);
        expect(
          () => read(
            changed: {
              'files': {'main.js': 42},
            },
          ),
          refuses('files'),
        );
      },
    );
  });
}

/// The `bookFile` capability (SourceAPI 1.2, ADR-0021).
void _bookFileCapability() {
  group('the bookFile capability (1.2)', () {
    test('is read when the manifest targets 1.2', () {
      final manifest = read(
        changed: {
          'apiVersion': '1.2',
          'capabilities': ['bookFile'],
        },
      );

      expect(
        manifest.declaredCapabilities,
        contains(SourceCapability.bookFile),
      );
    });

    test('is refused when the manifest targets an older version', () {
      // An app that ignored it would read the source as one whose chapters it can ask for, and
      // find there are none to ask for. Requiring 1.2 keeps it away from that app entirely.
      for (final older in ['1.0', '1.1']) {
        expect(
          () => read(
            changed: {
              'apiVersion': older,
              'capabilities': ['bookFile'],
            },
          ),
          refuses('capabilities'),
          reason: older,
        );
      }
    });

    test('a capability this build does not know is still kept', () {
      // §3.7: a later minor version may add one, and an older app ignores it rather than refusing
      // the extension. bookFile is the exception, and the only one.
      final manifest = read(
        changed: {
          'apiVersion': '1.2',
          'capabilities': ['latest', 'somethingLater'],
        },
      );

      expect(manifest.capabilities, contains('somethingLater'));
      expect(manifest.declaredCapabilities, {SourceCapability.latest});
    });
  });
}
