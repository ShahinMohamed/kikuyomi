// The host API an extension can reach, and what it does when an extension asks wrongly. Every
// bridge is called the way the prelude calls it, with arguments that have come from JavaScript and
// are therefore untrusted.

import 'dart:convert';
import 'dart:typed_data';

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:test/test.dart';

Matcher refuses(String because) => throwsA(
  isA<HostCallException>().having(
    (error) => error.message,
    'message',
    contains(because),
  ),
);

void main() {
  group('log', () {
    test('writes each level into the console, naming the extension', () {
      final console = InMemoryExtensionLog();
      final log = LogBridge(extensionId: 'org.example.x', sink: console);

      log.call('debug', ['looking for the list']);
      log.call('warn', ['no chapters on the page']);

      expect(console.messages, hasLength(2));
      expect(console.messages.first.level, ExtensionLogLevel.debug);
      expect(console.messages.first.extensionId, 'org.example.x');
      expect(console.messages.last.level, ExtensionLogLevel.warn);
      expect(console.messages.last.text, 'no chapters on the page');
    });

    test('a message is cut to length and made safe to show', () {
      final console = InMemoryExtensionLog();
      final log = LogBridge(extensionId: 'org.example.x', sink: console);

      log.call('info', ['a\tb\nc']);
      log.call('info', ['x' * 2000]);

      expect(console.messages.first.text, 'a b c');
      expect(
        console.messages.last.text.length,
        SourceLimits.maxShortTextLength + 1,
      );
      expect(console.messages.last.text, endsWith('…'));
    });

    test('an extension that logs in a loop is cut off, and told so', () {
      final console = InMemoryExtensionLog();
      var now = DateTime.utc(2026);
      final log = LogBridge(
        extensionId: 'org.example.x',
        sink: console,
        maxPerWindow: 3,
        window: const Duration(seconds: 10),
        now: () => now,
      );

      for (var i = 0; i < 50; i++) {
        log.call('info', ['line $i']);
      }
      expect(console.messages, hasLength(3));

      // The next window says what was lost rather than leaving the console quiet.
      now = now.add(const Duration(seconds: 11));
      log.call('info', ['after the window']);
      expect(console.messages, hasLength(5));
      expect(
        console.messages[3].text,
        contains('47 more messages were dropped'),
      );
      expect(console.messages[3].level, ExtensionLogLevel.warn);
      expect(console.messages.last.text, 'after the window');
    });

    test('a level that does not exist is the extension\'s mistake', () {
      final log = LogBridge(
        extensionId: 'org.example.x',
        sink: InMemoryExtensionLog(),
      );

      expect(() => log.call('shout', ['hi']), refuses('there is no log.shout'));
      expect(() => log.call('info', [42]), refuses('a message is a string'));
    });
  });

  group('host', () {
    test('tells an extension the contract version and the app version', () {
      const facts = HostFacts(appVersion: '1.4.0', features: {'ui.browser'});

      expect(facts.apiVersion, apiVersion);
      expect(facts.toPlainData(), {
        'apiVersion': apiVersion,
        'appVersion': '1.4.0',
        'features': ['ui.browser'],
      });
    });
  });

  group('storage', () {
    test('keeps each extension in its own namespace', () async {
      final store = InMemoryExtensionStore();
      final mine = StorageBridge(extensionId: 'org.example.a', store: store);
      final yours = StorageBridge(extensionId: 'org.example.b', store: store);

      await mine.call('set', ['token', 'mine']);
      await yours.call('set', ['token', 'yours']);

      expect(await mine.call('get', ['token']), 'mine');
      expect(await yours.call('get', ['token']), 'yours');
      expect(store.of('org.example.a'), {'token': 'mine'});
    });

    test('a key that was never set reads as nothing', () async {
      final bridge = StorageBridge(
        extensionId: 'org.example.a',
        store: InMemoryExtensionStore(),
      );

      expect(await bridge.call('get', ['nothing']), isNull);
    });

    test('removing what is not there is not a failure', () async {
      final bridge = StorageBridge(
        extensionId: 'org.example.a',
        store: InMemoryExtensionStore(),
      );

      await bridge.call('remove', ['nothing']);
      await bridge.call('set', ['a', '1']);
      await bridge.call('remove', ['a']);

      expect(await bridge.call('get', ['a']), isNull);
    });

    test('an extension cannot keep more than its share', () async {
      final bridge = StorageBridge(
        extensionId: 'org.example.a',
        store: InMemoryExtensionStore(),
        maxBytes: 1024,
      );

      await bridge.call('set', ['a', 'x' * 500]);

      expect(
        () => bridge.call('set', ['b', 'y' * 600]),
        refuses('storage is full'),
      );
      // Replacing a value counts the new one, not both, so an extension can always write less.
      await bridge.call('set', ['a', 'x' * 10]);
      await bridge.call('set', ['b', 'y' * 600]);
      expect(await bridge.call('get', ['b']), 'y' * 600);
    });

    test('a key must be a key', () async {
      final bridge = StorageBridge(
        extensionId: 'org.example.a',
        store: InMemoryExtensionStore(),
      );

      expect(() => bridge.call('set', ['', 'x']), refuses('1 to 512'));
      expect(() => bridge.call('set', ['k' * 513, 'x']), refuses('1 to 512'));
      expect(
        () => bridge.call('wipe', []),
        refuses('there is no storage.wipe'),
      );
    });
  });

  group('crypto', () {
    const crypto = CryptoBridge();

    test('hashes text the way a site hashes it', () {
      // The digests of "abc", which every implementation agrees on.
      expect(
        crypto.call('hash', ['md5', 'abc']),
        '900150983cd24fb0d6963f7d28e17f72',
      );
      expect(
        crypto.call('hash', ['sha1', 'abc']),
        'a9993e364706816aba3e25717850c26c9cd0d89d',
      );
      expect(
        crypto.call('hash', ['sha256', 'abc']),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('signs with HMAC', () {
      // RFC 4231's second test case.
      expect(
        crypto.call('hmac', ['sha256', 'Jefe', 'what do ya want for nothing?']),
        '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
      );
    });

    test('an algorithm the contract does not have is refused', () {
      expect(() => crypto.call('hash', ['sha3', 'abc']), refuses('sha3'));
      expect(() => crypto.call('hmac', ['md5', 'k', 'd']), refuses('md5'));
      expect(
        () => crypto.call('digest', ['sha256', 'abc']),
        refuses('crypto.digest'),
      );
    });

    test('base64 goes out with padding and comes back either way', () {
      expect(crypto.call('base64Encode', ['hello?']), 'aGVsbG8/');
      expect(
        utf8.decode(crypto.call('base64Decode', ['aGVsbG8/']) as Uint8List),
        'hello?',
      );
      // A site's own token: URL-safe, unpadded. Refusing it would help nobody.
      expect(
        utf8.decode(crypto.call('base64Decode', ['aGVsbG8_']) as Uint8List),
        'hello?',
      );
    });

    test('text that is not base64 is refused', () {
      expect(
        () => crypto.call('base64Decode', ['!!!!']),
        refuses('not base64'),
      );
    });

    group('AES', () {
      final key = Uint8List.fromList(List.generate(16, (i) => i));
      final iv = Uint8List.fromList(List.generate(16, (i) => 16 - i));

      Uint8List encrypted(String mode, List<int> plain) {
        // Encrypting with the same library the bridge decrypts with: the point of the test is that
        // a site's own ciphertext comes back, not that pointycastle agrees with itself about
        // nothing.
        final data = Uint8List.fromList(plain);
        return switch (mode) {
          'cbc' => _cbc(key, iv, data, encrypt: true),
          'ctr' => _ctr(key, iv, data, encrypt: true),
          _ => _gcm(key, iv.sublist(0, 12), data, encrypt: true),
        };
      }

      test('reads back what a site encrypted, in each mode', () {
        for (final mode in ['cbc', 'ctr', 'gcm']) {
          final plain = utf8.encode('{"chapters":[{"id":1}]}');
          final result = crypto.call('aesDecrypt', [
            {
              'mode': mode,
              'key': key,
              'iv': mode == 'gcm' ? iv.sublist(0, 12) : iv,
              'data': encrypted(mode, plain),
            },
          ]) as Uint8List;
          expect(utf8.decode(result), '{"chapters":[{"id":1}]}', reason: mode);
        }
      });

      test('data that was tampered with fails rather than decoding', () {
        final data = encrypted('gcm', utf8.encode('hello'));
        data[0] ^= 0xff;

        expect(
          () => crypto.call('aesDecrypt', [
            {'mode': 'gcm', 'key': key, 'iv': iv.sublist(0, 12), 'data': data},
          ]),
          refuses('could not be decrypted'),
        );
      });

      test('a key or a mode that is not one is refused', () {
        expect(
          () => crypto.call('aesDecrypt', [
            {
              'mode': 'cbc',
              'key': Uint8List(7),
              'iv': iv,
              'data': Uint8List(16),
            },
          ]),
          refuses('16, 24 or 32 bytes'),
        );
        expect(
          () => crypto.call('aesDecrypt', [
            {'mode': 'ecb', 'key': key, 'iv': iv, 'data': Uint8List(16)},
          ]),
          refuses('"cbc", "ctr" or "gcm"'),
        );
        expect(
          () => crypto.call('aesDecrypt', [
            {
              'mode': 'cbc',
              'key': key,
              'iv': Uint8List(8),
              'data': Uint8List(16),
            },
          ]),
          refuses('iv of 16 bytes'),
        );
      });
    });
  });

  group('html', () {
    const page = '''
<!doctype html>
<html><body>
  <ul id="results">
    <li class="card"><h3 class="title"><a href="/book/12">Moby-Dick</a></h3>
      <span class="by">  Herman   Melville
      </span></li>
    <li class="card"><h3 class="title"><a href="/book/13">Omoo</a></h3></li>
  </ul>
</body></html>
''';

    test('finds elements, reads their text and resolves their links', () {
      final html = HtmlBridge();
      final document =
          html.call('parse', [page, 'https://example.org/list']) as int;

      final cards =
          html.call('select', [document, 0, 'ul#results > li.card']) as List;
      expect(cards, hasLength(2));

      final title = html.call('selectFirst', [
        document,
        cards.first,
        'h3.title a',
      ]) as int;
      expect(html.call('text', [document, title]), 'Moby-Dick');
      expect(html.call('attr', [document, title, 'href']), '/book/12');
      expect(
        html.call('absUrl', [document, title, 'href']),
        'https://example.org/book/12',
      );

      final by =
          html.call('selectFirst', [document, cards.first, '.by']) as int;
      // Whitespace collapsed, as the contract says text() gives it.
      expect(html.call('text', [document, by]), 'Herman Melville');
      expect(html.call('html', [document, title]), 'Moby-Dick');
    });

    test('nothing found is nothing, not a failure', () {
      final html = HtmlBridge();
      final document = html.call('parse', [page, null]) as int;

      expect(html.call('select', [document, 0, '.missing']), isEmpty);
      expect(html.call('selectFirst', [document, 0, '.missing']), isNull);
      expect(html.call('attr', [document, 0, 'href']), isNull);
    });

    test(
      'an attribute that is not a URL, or has no base, resolves to nothing',
      () {
        final html = HtmlBridge();
        final document = html.call('parse', [page, null]) as int;
        final link = html.call('selectFirst', [document, 0, 'a']) as int;

        expect(html.call('absUrl', [document, link, 'href']), isNull);
        expect(html.call('absUrl', [document, link, 'src']), isNull);
      },
    );

    test('the selectors that would answer wrongly are refused by name', () {
      final html = HtmlBridge();
      final document = html.call('parse', [page, null]) as int;

      for (final selector in [
        'li:has(> a)',
        'tr:nth-child(2)',
        'tr:nth-last-child(1)',
        'li:nth-of-type(2)',
        'li:only-of-type',
        'td:empty',
        'LI:NTH-CHILD(odd)',
      ]) {
        expect(
          () => html.call('select', [document, 0, selector]),
          refuses('is not supported'),
          reason: selector,
        );
      }
    });

    test('a selector that only mentions one in a quoted value is allowed', () {
      final html = HtmlBridge();
      final document =
          html.call('parse', ['<p data-note=":empty">hello</p>', null]) as int;

      final found =
          html.call('select', [document, 0, r'[data-note=":empty"]']) as List;
      expect(found, hasLength(1));
    });

    test(
      'a selector the parser cannot use says so rather than matching nothing',
      () {
        final html = HtmlBridge();
        final document = html.call('parse', [page, null]) as int;

        expect(
          () => html.call('select', [document, 0, 'li:nth-last-of-type(1)']),
          refuses('could not be used'),
        );
        expect(
          () => html.call('select', [document, 0, '@@']),
          refuses('could not be used'),
        );
      },
    );

    test('a document does not outlive the call that parsed it', () {
      final html = HtmlBridge();
      final document = html.call('parse', [page, null]) as int;

      html.endOfCall();

      expect(
        () => html.call('select', [document, 0, 'a']),
        refuses('has been let go'),
      );
    });

    test('an extension cannot hold more documents than its share', () {
      final html = HtmlBridge(maxDocuments: 2);

      html.call('parse', [page, null]);
      html.call('parse', [page, null]);

      expect(() => html.call('parse', [page, null]), refuses('at once'));
      // Once the call is over there is room again.
      html.endOfCall();
      expect(html.call('parse', [page, null]), isA<int>());
    });

    test('an element from another document is refused', () {
      final html = HtmlBridge();
      final first = html.call('parse', [page, null]) as int;
      final second = html.call('parse', ['<p>other</p>', null]) as int;
      final link = html.call('selectFirst', [first, 0, 'a']) as int;

      expect(
        () => html.call('text', [second, link]),
        refuses('not from this document'),
      );
      expect(() => html.call('text', [99, 0]), refuses('has been let go'));
    });
  });
}

Uint8List _cbc(
  Uint8List key,
  Uint8List iv,
  Uint8List data, {
  required bool encrypt,
}) {
  final cipher =
      pc.PaddedBlockCipherImpl(
        pc.PKCS7Padding(),
        pc.CBCBlockCipher(pc.AESEngine()),
      )..init(
        encrypt,
        pc.PaddedBlockCipherParameters<pc.CipherParameters, Null>(
          pc.ParametersWithIV(pc.KeyParameter(key), iv),
          null,
        ),
      );
  return cipher.process(data);
}

Uint8List _ctr(
  Uint8List key,
  Uint8List iv,
  Uint8List data, {
  required bool encrypt,
}) {
  final cipher = pc.CTRStreamCipher(pc.AESEngine())
    ..init(encrypt, pc.ParametersWithIV(pc.KeyParameter(key), iv));
  return cipher.process(data);
}

Uint8List _gcm(
  Uint8List key,
  Uint8List nonce,
  Uint8List data, {
  required bool encrypt,
}) {
  final cipher = pc.GCMBlockCipher(pc.AESEngine())
    ..init(
      encrypt,
      pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0)),
    );
  return cipher.process(data);
}
