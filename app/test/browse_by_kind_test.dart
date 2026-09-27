// Browse split by kind (ADR-0019): which sources and which extensions each tab lists.

import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/browse_screen.dart';
import 'package:kikuyomi/src/extensions_screen.dart';
import 'package:kikuyomi/src/sources/source_registry.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import 'browse_test.dart' show librivox, local, orphan;
import 'extensions_view_test.dart' show summary;

const novels = SourceDescription(
  id: 0x4e4f56,
  key: 'novels',
  name: 'Novels',
  lang: 'en',
  capabilities: {},
  extensionId: 'org.example.novels',
  kind: SourceKind.text,
);

/// An extension offering one source of each kind.
const both = [
  SourceDescription(
    id: 1001,
    key: 'talks',
    name: 'Talks',
    lang: 'en',
    capabilities: {},
    extensionId: 'org.example.both',
  ),
  SourceDescription(
    id: 1002,
    key: 'transcripts',
    name: 'Transcripts',
    lang: 'en',
    capabilities: {},
    extensionId: 'org.example.both',
    kind: SourceKind.text,
  ),
];

void main() {
  group('a sources tab', () {
    const sources = [local, librivox, orphan, novels];

    test(
      'lists its own kind, with Local files and missing sources in each',
      () {
        expect(sourcesOfKind(sources, SourceKind.audio), [
          local,
          librivox,
          orphan,
        ]);
        expect(sourcesOfKind(sources, SourceKind.text), [
          local,
          orphan,
          novels,
        ]);
      },
    );
  });

  group('an extensions tab', () {
    final audio = summary(id: 'org.kikuyomi.librivox');
    final text = summary(id: 'org.example.novels', name: 'Novels');
    final mixed = summary(id: 'org.example.both', name: 'Both');
    final broken = summary(id: 'org.example.broken', name: 'Broken');
    final installed = [audio, text, mixed, broken];
    final sources = [librivox, novels, ...both];

    List<String> idsOf(SourceKind kind) => [
      for (final e in extensionsOfKind(installed, sources, kind)) e.id,
    ];

    test('lists the extensions offering its kind', () {
      expect(idsOf(SourceKind.audio), contains('org.kikuyomi.librivox'));
      expect(idsOf(SourceKind.audio), isNot(contains('org.example.novels')));
      expect(idsOf(SourceKind.text), contains('org.example.novels'));
      expect(idsOf(SourceKind.text), isNot(contains('org.kikuyomi.librivox')));
    });

    test('lists one offering both kinds under both', () {
      expect(idsOf(SourceKind.audio), contains('org.example.both'));
      expect(idsOf(SourceKind.text), contains('org.example.both'));
    });

    test('lists one whose sources are unknown under both, so its problem stays in sight', () {
      expect(idsOf(SourceKind.audio), contains('org.example.broken'));
      expect(idsOf(SourceKind.text), contains('org.example.broken'));
    });
  });
}
