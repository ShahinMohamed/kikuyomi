// Builds a publishable repository from a folder of extensions (§3.2, §3.8; ADR-0018).
//
// §3.10 puts `index` and `sign` in the SDK's CLI, which does not exist. This is the part of that job
// the project needs now: take the extensions in this repository, package each one, sign it, and
// write the `repo.json` and `index.json` an app can read. When the SDK arrives this becomes one of
// its commands and this file goes away.
//
// Run it from `packages/extension_manager`:
//
//     dart run tool/build_repository.dart --out ../../repository
//
// The signing key is generated on the first run and kept beside the output, outside the published
// folder. It is a private key: it must not be committed, and `.gitignore` says so. Losing it means
// generating another and every listener re-accepting the repository's new fingerprint, which is
// trust on first use working as designed rather than a disaster.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

const _usage = '''
Builds a repository from a folder of extension folders.

  --extensions <dir>   where the extensions are (default ../../app/assets/extensions)
  --out <dir>          where to write the repository (default ../../repository)
  --name <text>        what the repository calls itself
  --website <url>      where to read about it
  --base <url>         the HTTPS address the output will be served from, for package URLs
  --key <file>         the signing key (default <out>/../repository-signing-key.txt)
''';

Future<void> main(List<String> arguments) async {
  final options = _options(arguments);
  if (options.containsKey('help')) {
    stdout.writeln(_usage);
    return;
  }

  final from = Directory(
    options['extensions'] ?? '../../app/assets/extensions',
  );
  final out = Directory(options['out'] ?? '../../repository');
  final base =
      options['base'] ??
      'https://raw.githubusercontent.com/kikuyomiapp/kikuyomi/HEAD/repository/';
  final keyFile = File(
    options['key'] ?? '${out.parent.path}/repository-signing-key.txt',
  );

  if (!await from.exists()) {
    stderr.writeln('There is no ${from.path} to read extensions from.');
    exitCode = 2;
    return;
  }

  final keyPair = await _signingKey(keyFile);
  final publicKey = await keyPair.extractPublicKey();
  final publicKeyBase64 = base64Encode(publicKey.bytes);

  await out.create(recursive: true);
  final packages = Directory('${out.path}/packages');
  await packages.create(recursive: true);

  final entries = <Map<String, Object?>>[];
  for (final folder in await _extensionFolders(from)) {
    final entry = await _package(
      folder,
      into: packages,
      base: base,
      keyPair: keyPair,
    );
    if (entry != null) entries.add(entry);
  }
  entries.sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));

  await File('${out.path}/repo.json').writeAsString(
    _pretty({
      'formatVersion': repositoryFormatVersion,
      'name': options['name'] ?? 'Kikuyomi',
      if (options['website'] != null) 'website': options['website'],
      'publicKey': publicKeyBase64,
    }),
  );
  await File('${out.path}/index.json').writeAsString(
    _pretty({'formatVersion': repositoryFormatVersion, 'extensions': entries}),
  );

  // Read back what was written, through the app's own parser. A repository that this build cannot
  // read is one no app could, and finding that out here costs nothing.
  RepositoryInfo.parse(await File('${out.path}/repo.json').readAsString());
  final index = RepositoryIndex.parse(
    await File('${out.path}/index.json').readAsString(),
  );

  stdout
    ..writeln('Wrote ${out.path}')
    ..writeln('  ${index.entries.length} extensions, served from $base')
    ..writeln('  signing key ${keyFile.path}')
    ..writeln(
      '  fingerprint ${RepositoryInfo.parse(await File('${out.path}/repo.json').readAsString()).fingerprint}',
    );
}

/// The folders that look like an extension: one holding a `manifest.json`.
Future<List<Directory>> _extensionFolders(Directory from) async {
  final folders = <Directory>[];
  await for (final entry in from.list(followLinks: false)) {
    if (entry is! Directory) continue;
    if (await File('${entry.path}/manifest.json').exists()) folders.add(entry);
  }
  folders.sort((a, b) => a.path.compareTo(b.path));
  return folders;
}

/// Zips [folder], writes it into [into], and returns its index entry.
Future<Map<String, Object?>?> _package(
  Directory folder, {
  required Directory into,
  required String base,
  required SimpleKeyPair keyPair,
}) async {
  final manifestJson = await File('${folder.path}/manifest.json')
      .readAsString();
  final ExtensionManifest manifest;
  try {
    manifest = ExtensionManifest.parse(manifestJson);
  } on ManifestException catch (error) {
    stderr.writeln('Skipping ${folder.path}: ${error.message}');
    return null;
  }

  // Everything directly inside the folder, flat, which is what §3.3 says a package is.
  final archive = Archive();
  await for (final entry in folder.list(followLinks: false)) {
    if (entry is! File) continue;
    final bytes = await entry.readAsBytes();
    archive.addFile(ArchiveFile.bytes(_lastSegment(entry.path), bytes));
  }
  final zipped = ZipEncoder().encode(archive);

  final name = '${manifest.id}-${manifest.versionCode}.zip';
  await File('${into.path}/$name').writeAsBytes(zipped);

  final hash = sha256.convert(zipped).toString();
  // What the signature covers: the package's hash, so the repository is vouching for exactly these
  // bytes. The listing's other fields are only a listing — what an extension is actually allowed to
  // do is read from the manifest inside the verified package at install (ADR-0018).
  final signature = await Ed25519().sign(utf8.encode(hash), keyPair: keyPair);

  final listed = jsonDecode(manifestJson) as Map<String, Object?>
    // A listing is not a package: the per-file hashes describe a package's contents and are checked
    // when it is unpacked.
    ..remove('files');
  return {
    ...listed,
    'package': {
      'url': '${base.endsWith('/') ? base : '$base/'}packages/$name',
      'sha256': hash,
      'size': zipped.length,
    },
    'signature': base64Encode(signature.bytes),
    'revoked': false,
  };
}

/// The repository's signing key, generated on the first run.
///
/// Stored as the base64 of its 32-byte seed, which is all Ed25519 needs to be itself again.
Future<SimpleKeyPair> _signingKey(File file) async {
  if (await file.exists()) {
    final seed = base64Decode((await file.readAsString()).trim());
    return Ed25519().newKeyPairFromSeed(seed);
  }
  final keyPair = await Ed25519().newKeyPair();
  final seed = await keyPair.extractPrivateKeyBytes();
  await file.parent.create(recursive: true);
  await file.writeAsString('${base64Encode(seed)}\n');
  stdout.writeln('Generated a signing key at ${file.path}. Do not commit it.');
  return keyPair;
}

Map<String, String> _options(List<String> arguments) {
  final options = <String, String>{};
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (!argument.startsWith('--')) continue;
    final name = argument.substring(2);
    if (name == 'help') {
      options['help'] = '';
    } else if (i + 1 < arguments.length) {
      options[name] = arguments[++i];
    }
  }
  return options;
}

String _pretty(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

String _lastSegment(String path) =>
    path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty).last;
