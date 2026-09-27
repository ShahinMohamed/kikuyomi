// Loading one extension and calling into it: the protocol between the app and an extension's
// JavaScript, with the engine faked out. What matters here is that a call cannot end in a way the
// app has no answer for — every failure is one of the contract's error kinds, and nothing crosses
// the boundary but plain data.

import 'dart:async';

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('loads the host, then the prelude, then the extension', () async {
    final engine = FakeScriptEngine();
    await ExtensionRuntime.load(
      engine: engine,
      bundle: testBundle(code: 'module.exports = { sources: {} };'),
      host: testHost,
    );

    expect(engine.evaluated, hasLength(3));
    expect(engine.evaluated[0], contains('__kikuyomiHostInfo'));
    expect(engine.evaluated[0], contains('"apiVersion":"$apiVersion"'));
    expect(engine.evaluated[0], contains('"appVersion":"1.2.3"'));
    expect(engine.evaluated[1], kikuyomiPrelude);
    expect(engine.evaluated[2], contains('__kikuyomiRuntime.setExtension'));
    expect(engine.evaluated[2], contains('module.exports = { sources: {} };'));
    // The host function is installed before anything is evaluated, because the prelude captures it
    // as it runs and deletes the global.
    expect(engine.hostFunctions, contains(HostApi.entryPoint));
  });

  test('a bundle that ends in a comment still closes its wrapper', () async {
    final engine = FakeScriptEngine();
    await ExtensionRuntime.load(
      engine: engine,
      bundle: testBundle(code: 'module.exports = {};\n// the end'),
      host: testHost,
    );

    expect(engine.evaluated[2], endsWith('})());\n'));
  });

  test('reads the sources the extension really exports', () async {
    final (runtime, _) = await loadFake(
      const FakeExtension({'librivox': {}, 'archive': {}}),
    );

    expect(runtime.sourceKeys, ['librivox', 'archive']);
  });

  test('an extension whose code does not run cannot be loaded', () async {
    final engine = FakeScriptEngine()
      ..failNextEvaluate = const ScriptThrewException(
        'SyntaxError: unexpected }',
      );

    expect(
      () => ExtensionRuntime.load(
        engine: engine,
        bundle: testBundle(),
        host: testHost,
      ),
      throwsA(
        isA<ExtensionLoadException>().having(
          (error) => error.toString(),
          'message',
          allOf(contains('org.example.test'), contains('SyntaxError')),
        ),
      ),
    );
  });

  test('an extension that never finishes loading cannot be loaded', () async {
    final engine = FakeScriptEngine()
      ..failNextEvaluate = const ScriptDeadlineException(Duration(seconds: 30));

    expect(
      () => ExtensionRuntime.load(
        engine: engine,
        bundle: testBundle(),
        host: testHost,
      ),
      throwsA(isA<ExtensionLoadException>()),
    );
  });

  test('says which optional methods a source has', () async {
    final (runtime, _) = await loadFake(
      FakeExtension({
        'librivox': {'getPopular': (_) => null, 'getLatest': (_) => null},
      }),
    );

    expect(await runtime.hasMethod('librivox', 'getLatest'), isTrue);
    expect(await runtime.hasMethod('librivox', 'getFilters'), isFalse);
    expect(await runtime.hasMethod('nothing', 'getPopular'), isFalse);
  });

  test('hands a call its arguments and gives back what it answered', () async {
    final (runtime, engine) = await loadFake(
      FakeExtension({
        'librivox': {
          'getBookDetails': (args) => {'key': args.first, 'title': 'Moby-Dick'},
        },
      }),
    );

    final answer = await runtime.invoke('librivox', 'getBookDetails', ['b1']);

    expect(answer, {'key': 'b1', 'title': 'Moby-Dick'});
    expect(engine.calls.last.function, '__kikuyomiRuntime.invoke');
    final (source, method, passed) = engine.calls.last.invocation;
    expect(source, 'librivox');
    expect(method, 'getBookDetails');
    expect(passed, ['b1']);
  });

  test('a call may take as long as its deadline says', () async {
    final (runtime, engine) = await loadFake(
      FakeExtension({
        'librivox': {'getPopular': (_) => null},
      }),
    );

    await runtime.invoke('librivox', 'getPopular', [
      1,
    ], deadline: const Duration(seconds: 5));

    expect(engine.calls.last.deadline, const Duration(seconds: 5));
  });

  group('what an extension throws', () {
    test('keeps its kind and its fields', () async {
      final (runtime, _) = await loadFake(
        FakeExtension({
          'librivox': {
            'getPopular': (_) => throw const RateLimitedException(
              message: 'slow down',
              retryAfterMs: 1500,
            ),
          },
        }),
      );

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<RateLimitedException>()
              .having((e) => e.retryAfterMs, 'retryAfterMs', 1500)
              .having((e) => e.message, 'message', 'slow down'),
        ),
      );
    });

    test('a challenge keeps the page it points at', () async {
      final (runtime, _) = await loadFake(
        FakeExtension({
          'librivox': {
            'getPopular': (_) => throw ChallengeRequiredException(
              Uri.parse('https://example.org/check'),
            ),
          },
        }),
      );

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ChallengeRequiredException>().having(
            (e) => e.url.toString(),
            'url',
            'https://example.org/check',
          ),
        ),
      );
    });

    test('a plain error is Parse, as the contract says', () async {
      final (runtime, _) = await loadFake(
        FakeExtension({
          'librivox': {
            'getPopular': (_) => throw StateError('x is not a function'),
          },
        }),
      );

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('x is not a function'),
          ),
        ),
      );
    });

    test('a thrown string is Parse, carrying what it said', () async {
      final (runtime, _) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => throw 'nope'},
        }),
      );

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having((e) => e.message, 'message', 'nope'),
        ),
      );
    });

    test('calling a method the source does not have fails as Parse', () async {
      final (runtime, _) = await loadFake(
        const FakeExtension({'librivox': {}}),
      );

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('has no getPopular()'),
          ),
        ),
      );
    });
  });

  group('what the watchdog does', () {
    test('a call past its deadline fails as Parse, saying so', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );
      engine.failNextCall = const ScriptDeadlineException(
        Duration(seconds: 30),
      );

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('did not answer within 30 s'),
          ),
        ),
      );
    });

    test('a runtime past its memory limit fails as Parse, saying so', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );
      engine.failNextCall = const ScriptMemoryException(64 * 1024 * 1024);

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('more than 64 MB'),
          ),
        ),
      );
    });

    test('a cancelled call fails rather than looking like a result', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );
      engine.failNextCall = const ScriptCancelledException();

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(isA<ParseException>()),
      );
    });

    test('the runtime is usable again after a limit is reached', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {
            'getPopular': (_) => {'items': <Object?>[], 'hasNextPage': false},
          },
        }),
      );
      engine.failNextCall = const ScriptDeadlineException(
        Duration(seconds: 30),
      );

      await expectLater(
        runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(isA<ParseException>()),
      );
      expect(await runtime.invoke('librivox', 'getPopular', [2]), isA<Map>());
    });
  });

  group('an extension that does not keep to the protocol', () {
    test('an answer that is not a result fails as Parse', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );
      engine.answerInvokeWith = () => 'surprise';

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('instead of a result'),
          ),
        ),
      );
    });

    test('a failure with no error at all is still a failure', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );
      engine.answerInvokeWith = () => {'ok': false};

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(isA<ParseException>()),
      );
    });

    test('an error kind from a later version is read as Parse', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );
      engine.answerInvokeWith = () => {
        'ok': false,
        'error': {'kind': 'Quarantined', 'message': 'from API 1.4'},
      };

      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('Quarantined'),
          ),
        ),
      );
    });

    test('nothing can be called after the runtime is disposed', () async {
      final (runtime, engine) = await loadFake(
        FakeExtension({
          'librivox': {'getPopular': (_) => null},
        }),
      );

      await runtime.dispose();

      expect(engine.disposed, isTrue);
      expect(
        () => runtime.invoke('librivox', 'getPopular', [1]),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('the host function the prelude reaches its bridges through', () {
    test('sends a call to the module it names', () async {
      final log = _RecordingBridge('log');
      final (_, engine) = await loadFake(
        const FakeExtension({}),
        bridges: [log],
      );

      final answer = await engine.hostFunctions[HostApi.entryPoint]!([
        'log',
        'info',
        ['hello'],
      ]);

      expect(log.calls.single.$1, 'info');
      expect(log.calls.single.$2, ['hello']);
      expect(answer, 'log.info');
    });

    test('a module that does not exist is the extension\'s mistake', () async {
      final (_, engine) = await loadFake(const FakeExtension({}));

      expect(
        () =>
            engine.hostFunctions[HostApi.entryPoint]!(['webview', 'open', []]),
        throwsA(
          isA<HostCallException>().having(
            (e) => e.message,
            'message',
            contains('there is no host module "webview"'),
          ),
        ),
      );
    });

    test('a call that names no module at all is refused', () async {
      final (_, engine) = await loadFake(const FakeExtension({}));

      expect(
        () => engine.hostFunctions[HostApi.entryPoint]!([42]),
        throwsA(isA<HostCallException>()),
      );
    });

    test('arguments that are not an array are refused', () async {
      final (_, engine) = await loadFake(
        const FakeExtension({}),
        bridges: [_RecordingBridge('log')],
      );

      expect(
        () =>
            engine.hostFunctions[HostApi.entryPoint]!(['log', 'info', 'oops']),
        throwsA(isA<HostCallException>()),
      );
    });

    test('the timers the prelude asks for come back', () async {
      final (_, engine) = await loadFake(const FakeExtension({}));

      final waited = Stopwatch()..start();
      await engine.hostFunctions[HostApi.entryPoint]!([
        'timer',
        'sleep',
        [20],
      ]);

      expect(waited.elapsedMilliseconds, greaterThanOrEqualTo(15));
    });

    test('a URL is parsed by the host, against its base', () async {
      final (_, engine) = await loadFake(const FakeExtension({}));

      final parsed = await engine.hostFunctions[HostApi.entryPoint]!([
        'url',
        'parse',
        ['/book/12?page=2#top', 'https://example.org/index.html'],
      ]) as Map<Object?, Object?>;

      expect(parsed['href'], 'https://example.org/book/12?page=2#top');
      expect(parsed['protocol'], 'https:');
      expect(parsed['hostname'], 'example.org');
      expect(parsed['pathname'], '/book/12');
      expect(parsed['search'], '?page=2');
      expect(parsed['hash'], '#top');
      expect(parsed['origin'], 'https://example.org');
    });

    test('something that is not a URL comes back as nothing', () async {
      final (_, engine) = await loadFake(const FakeExtension({}));

      expect(
        await engine.hostFunctions[HostApi.entryPoint]!([
          'url',
          'parse',
          ['not a url', null],
        ]),
        isNull,
      );
    });
  });
}

/// A bridge that records what it was asked, for the dispatcher's own tests.
final class _RecordingBridge implements HostBridge {
  _RecordingBridge(this.module);

  @override
  final String module;

  final calls = <(String, List<Object?>)>[];

  @override
  FutureOr<Object?> call(String method, List<Object?> arguments) {
    calls.add((method, arguments));
    return '$module.$method';
  }
}
