// Spike (a) probe. Throwaway.
//
// Answers two questions about Kikuyomi's fork of flutter_qjs 0.3.7 (third_party/flutter_qjs):
//
//  1. Does it build and run, and do the interrupt handler and memory limit that ffi.cpp exposes
//     actually work from Dart? Probes 1 to 6, unchanged in meaning since the Windows run.
//  2. What does the interrupt deadline measure? Upstream's ffi.cpp timed it with clock(), which is
//     wall time in the Windows CRT and process CPU time on POSIX, Android included. Probes 7 to
//     10. Probes 11 and 12 then check what the host is told when the memory limit leaves no room
//     for an error object, which probe 5 met by chance on API 26, synchronously and in an async
//     function.
//  3. Does Kikuyomi's own `ScriptEngine` work on a device? Probes 13 to 19 drive
//     `QuickJsScriptEngine` (packages/platform_adapters) through the interface in
//     packages/source_runtime: load a small extension, call a method, take a typed error, and meet
//     the deadline, the memory limit and a cancellation. These cannot run under `flutter test`,
//     because a plugin's native library is not built there, so they run here. Probe 14 is the one
//     the fork's per-call deadline was written for.
//  4. Does the extension protocol run? Probes 20 to 22 load a small extension through
//     `ExtensionRuntime`, with the real prelude and the real bridges, and call it through
//     `JsSourceAdapter`. The prelude is JavaScript, and only QuickJS can say whether it runs.
//  5. Does the LibriVox extension the app ships work? Probes 23 to 34 run the real
//     app/assets/extensions/librivox/main.js on the real engine against LibriVox answers recorded
//     into assets/librivox/fixtures. Never against the live site: a probe that reached the network
//     would fail for reasons that have nothing to do with the code, and would ask a volunteer-run
//     site for something on every CI run. A URL with no fixture fails the probe.
//
// This is a console probe wearing a Flutter app as a costume, because the plugin's native library
// is only present in a built Flutter application. It runs every probe at start, unattended, and
// writes one line per event:
//
//   QJS_PROBE INFO <key>=<value>
//   QJS_PROBE START <probe>
//   QJS_PROBE PASS <probe> <details>
//   QJS_PROBE FAIL <probe> <details>
//   QJS_PROBE DONE passed=<n> failed=<m>
//
// On Android the lines go through print(), which Flutter forwards to logcat under the tag
// "flutter"; stdout goes nowhere there. On desktop they go to stdout and the process exits with
// the failure count as its status. A START without its PASS or FAIL means the probe hung.
//
// Probes 7 to 10 are measurements. They pass when the measurement is unambiguous and state what it
// found as `verdict=...`; they fail only when the numbers fit no explanation.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:kikuyomi_platform_adapters/kikuyomi_platform_adapters.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';

int _passed = 0;
int _failed = 0;
final List<String> _lines = [];

void _emit(String line) {
  _lines.add(line);
  if (Platform.isAndroid) {
    // ignore: avoid_print
    print(line);
  } else {
    stdout.writeln(line);
  }
}

String _oneLine(Object? text, [int max = 160]) {
  final flat = '$text'.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length > max ? '${flat.substring(0, max)}...' : flat;
}

void _report(String name, bool ok, String detail) {
  ok ? _passed++ : _failed++;
  _emit('QJS_PROBE ${ok ? 'PASS' : 'FAIL'} $name ${_oneLine(detail, 400)}');
}

/// Runs one probe. The body returns its details on success and throws on failure, so a crash is a
/// result rather than the end of the run.
Future<void> _probe(String name, Future<String> Function() body) async {
  _emit('QJS_PROBE START $name');
  final watch = Stopwatch()..start();
  try {
    final detail = await body();
    _report(name, true, '$detail ms=${watch.elapsedMilliseconds}');
  } catch (e) {
    _report(
      name,
      false,
      '${e.runtimeType}: $e ms=${watch.elapsedMilliseconds}',
    );
  }
}

/// A probe that must throw, and throw for the stated reason. The Windows run showed why the
/// reason matters: on the unpatched package everything threw, and a bare "it threw" check scored
/// two false passes. The error text is checked here because nobody reads this run by hand.
Future<void> _probeExpectingThrow(
  String name,
  String expectedError,
  Future<void> Function() body,
) async {
  await _probe(name, () async {
    try {
      await body();
    } catch (e) {
      final text = _oneLine(e);
      if (!text.contains(expectedError)) {
        throw StateError('threw, but not "$expectedError": $text');
      }
      return 'threw as expected: $text';
    }
    throw StateError('completed without throwing, expected "$expectedError"');
  });
}

bool _isInterrupt(Object e) => '$e'.contains('interrupted');

// ---------------------------------------------------------------------------------------------
// The C library's clock(), the very function ffi.cpp's interrupt handler reads, so the probes can
// report how far it moved next to how much wall time passed.

typedef _ClockNative = Long Function();
typedef _ClockDart = int Function();

class _CClock {
  _CClock._(this._clock, this.perSecond, this.library);

  final _ClockDart _clock;

  /// CLOCKS_PER_SEC: 1000 in the Windows CRT, and 1000000 on every POSIX system, as XSI
  /// requires. Android's bionic follows POSIX.
  final int perSecond;
  final String library;

  static _CClock? open() {
    try {
      final (lib, name) = Platform.isWindows
          ? (DynamicLibrary.open('ucrtbase.dll'), 'ucrtbase.dll')
          : Platform.isAndroid
          ? (DynamicLibrary.open('libc.so'), 'libc.so')
          : (DynamicLibrary.process(), 'process');
      final clock = lib.lookupFunction<_ClockNative, _ClockDart>('clock');
      return _CClock._(clock, Platform.isWindows ? 1000 : 1000000, name);
    } catch (_) {
      return null;
    }
  }

  int ticks() => _clock();

  int ms(int fromTicks, int toTicks) =>
      (toTicks - fromTicks) * 1000 ~/ perSecond;
}

final _CClock? _cClock = _CClock.open();

/// CPU time used by the calling thread alone. Neither the deadline nor clock() measures it, which
/// is the point: set beside clock(), it separates a runtime's own work from the rest of the
/// process's.
class _ThreadCpu {
  _ThreadCpu._(this._micros);

  final int Function() _micros;

  static _ThreadCpu? open() {
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        final libc = Platform.isAndroid
            ? DynamicLibrary.open('libc.so')
            : DynamicLibrary.process();
        final gettime = libc
            .lookupFunction<
              Int32 Function(Int32, Pointer<Long>),
              int Function(int, Pointer<Long>)
            >('clock_gettime');
        // struct timespec is two longs on Linux and Android; CLOCK_THREAD_CPUTIME_ID is 3.
        final ts = malloc.allocate<Long>(sizeOf<Long>() * 2);
        return _ThreadCpu._(() {
          if (gettime(3, ts) != 0) throw StateError('clock_gettime failed');
          return ts[0] * 1000000 + ts[1] ~/ 1000;
        });
      }
      if (Platform.isWindows) {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final current = kernel32
            .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
              'GetCurrentThread',
            );
        final times = kernel32
            .lookupFunction<
              Int32 Function(
                Pointer<Void>,
                Pointer<Uint64>,
                Pointer<Uint64>,
                Pointer<Uint64>,
                Pointer<Uint64>,
              ),
              int Function(
                Pointer<Void>,
                Pointer<Uint64>,
                Pointer<Uint64>,
                Pointer<Uint64>,
                Pointer<Uint64>,
              )
            >('GetThreadTimes');
        // Creation, exit, kernel and user time, as FILETIMEs in 100 ns units.
        final ft = malloc.allocate<Uint64>(sizeOf<Uint64>() * 4);
        return _ThreadCpu._(() {
          if (times(current(), ft, ft + 1, ft + 2, ft + 3) == 0) {
            throw StateError('GetThreadTimes failed');
          }
          return (ft[2] + ft[3]) ~/ 10;
        });
      }
    } catch (_) {
      // Fall through: the probes report n/a.
    }
    return null;
  }

  int micros() => _micros();
}

final _ThreadCpu? _threadCpu = _ThreadCpu.open();

/// Wall time, clock() time and the calling thread's CPU time for one span, side by side.
class _Span {
  _Span()
    : _startTicks = _cClock?.ticks(),
      _startThreadMicros = _threadCpu?.micros() {
    _watch.start();
  }

  final Stopwatch _watch = Stopwatch();
  final int? _startTicks;
  final int? _startThreadMicros;
  int? _wallMs;
  int? _clockMs;
  int? _threadCpuMs;

  void stop() {
    _watch.stop();
    _wallMs = _watch.elapsedMilliseconds;
    final start = _startTicks;
    final clock = _cClock;
    if (start != null && clock != null) {
      _clockMs = clock.ms(start, clock.ticks());
    }
    final threadStart = _startThreadMicros;
    final thread = _threadCpu;
    if (threadStart != null && thread != null) {
      _threadCpuMs = (thread.micros() - threadStart) ~/ 1000;
    }
  }

  int get wallMs => _wallMs!;
  int? get clockMs => _clockMs;
  int? get threadCpuMs => _threadCpuMs;

  static String _ms(int? ms) => ms == null ? 'n/a' : '${ms}ms';

  @override
  String toString() =>
      'wall=${wallMs}ms clock=${_ms(_clockMs)} thread-cpu=${_ms(_threadCpuMs)}';
}

/// Makes a Dart function callable from JavaScript as a global.
void _setGlobal(FlutterQjs engine, String name, Function value) {
  final setter = engine.evaluate('(k, v) => { globalThis[k] = v; }');
  try {
    setter.invoke([name, value]);
  } finally {
    setter.free();
  }
}

/// One outcome of running a script against a deadline.
class _Run {
  _Run(this.span, {required this.interrupted, this.result, this.error});

  final _Span span;
  final bool interrupted;
  final Object? result;
  final Object? error;

  bool get completed => !interrupted && error == null;

  String get outcome => interrupted
      ? 'interrupted'
      : error != null
      ? 'threw(${_oneLine(error, 80)})'
      : 'completed($result)';

  @override
  String toString() => '$outcome $span';
}

_Run _runAgainstDeadline(FlutterQjs engine, String script) {
  final span = _Span();
  try {
    final result = engine.evaluate(script);
    span.stop();
    return _Run(span, interrupted: false, result: result);
  } catch (e) {
    span.stop();
    return _Run(span, interrupted: _isInterrupt(e), error: e);
  }
}

// ---------------------------------------------------------------------------------------------

/// The deadline every probe from 7 on uses, in milliseconds.
const _deadlineMs = 1000;

/// How long the bounded scripts in probes 8 and 10 run if nothing interrupts them. Four times the
/// deadline, so "interrupted near the deadline" and "ran to the end" cannot be confused.
const _boundMs = 4000;

/// Probe 9's sleeper runs longer, so the spinner beside it can use a full deadline's worth of CPU
/// even on a loaded machine that gives it a third of a core.
const _sleeperBoundMs = 6000;
const _spinnerMs = 5000;

/// A script that spends almost all of its time blocked in a host call rather than computing.
///
/// `hostSleep` is a Dart function that calls dart:io's sleep(), which blocks the thread without
/// using CPU. The empty inner loop is there only so QuickJS polls its interrupt handler, which it
/// does once every 10000 jumps or calls; it costs about a millisecond per 20 ms nap.
///
/// The argument is a number on purpose: a string argument would restart the deadline (probe 10).
String _blockedScript(int boundMs) =>
    '''
(() => {
  const start = Date.now();
  let naps = 0;
  while (Date.now() - start < $boundMs) {
    hostSleep(20);
    naps++;
    for (let i = 0; i < 20000; i++) {}
  }
  return naps;
})()
''';

void _hostSleep(dynamic ms) =>
    sleep(Duration(milliseconds: (ms as num).toInt()));

/// Pure computation for a fixed stretch of wall time.
String _spinScript(int ms) =>
    '''
(() => {
  const start = Date.now();
  let spins = 0;
  while (Date.now() - start < $ms) { spins++; }
  return spins;
})()
''';

String _hostCallScript(String call) =>
    '''
(() => {
  const start = Date.now();
  let calls = 0;
  while (Date.now() - start < $_boundMs) {
    $call;
    calls++;
  }
  return calls;
})()
''';

/// Probe 8's verdict, which probe 9 needs to read its own result.
String? _blockedVerdict;

/// Probe 9's sleeper: the blocked script under the deadline, in a worker isolate of its own, as the
/// extension runtime's will be.
Future<_Run> _sleeperInIsolate() => Isolate.run(() {
  final engine = FlutterQjs(timeout: _deadlineMs);
  try {
    _setGlobal(engine, 'hostSleep', _hostSleep);
    return _runAgainstDeadline(engine, _blockedScript(_sleeperBoundMs));
  } finally {
    engine.close();
  }
});

/// Probe 9's spinner: pure computation with no deadline, in another isolate.
Future<_Run> _spinnerInIsolate() => Isolate.run(() {
  final engine = FlutterQjs();
  try {
    return _runAgainstDeadline(engine, _spinScript(_spinnerMs));
  } finally {
    engine.close();
  }
});

Future<void> _runAll() async {
  // 1. Does the native library load and evaluate at all?
  await _probe('eval-arithmetic', () async {
    final engine = FlutterQjs();
    engine.dispatch();
    final result = await engine.evaluate('1 + 1');
    engine.close();
    if (result != 2) throw StateError('expected 2, got $result');
    return 'got $result';
  });

  // 2. Cold start, measured on its own so the number means something.
  await _probe('eval-cold-start', () async {
    final engine = FlutterQjs();
    engine.dispatch();
    await engine.evaluate('void 0');
    engine.close();
    return 'runtime created and torn down';
  });

  // 3. Promise and async, which the extension contract depends on entirely.
  await _probe('async-awaited-promise', () async {
    final engine = FlutterQjs();
    engine.dispatch();
    final result = await engine.evaluate(
      '(async () => { const v = await Promise.resolve(40); return v + 2; })()',
    );
    engine.close();
    if (result != 42) throw StateError('expected 42, got $result');
    return 'got $result';
  });

  // 4. The first non-negotiable: can the host stop a runaway script?
  await _probeExpectingThrow(
    'watchdog-interrupt-loop',
    'interrupted',
    () async {
      final engine = FlutterQjs(timeout: 1000);
      engine.dispatch();
      try {
        await engine.evaluate('while (true) {}');
      } finally {
        engine.close();
      }
    },
  );

  // 5. The second non-negotiable: is the memory limit enforced?
  await _probeExpectingThrow(
    'watchdog-memory-limit',
    'out of memory',
    () async {
      final engine = FlutterQjs(memoryLimit: 1024 * 1024);
      engine.dispatch();
      try {
        await engine.evaluate(
          'const a = []; while (true) { a.push(new Array(10000).fill(0)); }',
        );
      } finally {
        engine.close();
      }
    },
  );

  // 6. Does the engine survive an interrupt, or is the runtime poisoned? This matters: a pooled
  //    runtime that cannot be reused after one bad extension is a very different design.
  await _probe('watchdog-reuse-after-interrupt', () async {
    final engine = FlutterQjs(timeout: 500);
    engine.dispatch();
    Object? first;
    try {
      await engine.evaluate('while (true) {}');
    } catch (e) {
      first = e;
    }
    if (first == null || !_isInterrupt(first)) {
      engine.close();
      throw StateError('first run was not interrupted: ${_oneLine(first)}');
    }
    final result = await engine.evaluate('7 * 6');
    engine.close();
    if (result != 42) {
      throw StateError('expected 42 after interrupt, got $result');
    }
    return 'engine usable after interrupt, got $result';
  });

  // 7. Control for 8: a busy loop. Its thread is on the CPU the whole time, so wall time and CPU
  //    time advance together and the deadline fires near 1000 ms whichever clock() measures. It
  //    also checks that clock() read from Dart moves at the rate this probe assumes.
  await _probe('deadline-busy-loop', () async {
    final engine = FlutterQjs(timeout: _deadlineMs);
    try {
      final run = _runAgainstDeadline(engine, 'while (true) {}');
      if (!run.interrupted) {
        throw StateError('not interrupted: ${run.outcome} ${run.span}');
      }
      return 'interrupted ${run.span} deadline=${_deadlineMs}ms';
    } finally {
      engine.close();
    }
  });

  // 8. The clock() question itself: a script that spends 95% of its time blocked in a host call,
  //    so wall time runs about twenty times faster than CPU time. With a wall-clock deadline it
  //    is interrupted near 1000 ms; with a CPU-time deadline it never uses 1000 ms of CPU and runs
  //    to its own 4000 ms bound. Nothing in between has an innocent explanation.
  await _probe('deadline-blocked-in-host', () async {
    final engine = FlutterQjs(timeout: _deadlineMs);
    try {
      _setGlobal(engine, 'hostSleep', _hostSleep);
      final run = _runAgainstDeadline(engine, _blockedScript(_boundMs));
      final wall = run.span.wallMs;
      final String verdict;
      if (run.interrupted && wall < _boundMs ~/ 2) {
        verdict = 'wall-clock';
      } else if (run.completed && wall >= _boundMs - 100) {
        verdict = 'cpu-time';
      } else {
        throw StateError('ambiguous: $run');
      }
      _blockedVerdict = verdict;
      return 'verdict=$verdict $run deadline=${_deadlineMs}ms bound=${_boundMs}ms';
    } finally {
      engine.close();
    }
  });

  // 9. Whose CPU time? POSIX clock() counts every thread in the process, not only the one running
  //    the script. A sleeper, as in 8 but with a 6000 ms bound, runs under the 1000 ms deadline
  //    in one worker isolate and uses almost no CPU of its own. A spinner computes for 5000 ms in
  //    another isolate, with no deadline. If the sleeper's deadline counts only its own thread, it
  //    runs to its bound. If it counts the whole process, the spinner's work drains it and the
  //    sleeper is interrupted although its own thread has used a few tens of milliseconds. A
  //    wall-clock deadline interrupts it too, near 1000 ms; probe 8 tells the two apart.
  //
  //    An earlier design spun two runtimes at once and expected a process-wide clock to fire both
  //    at half the deadline. On a loaded emulator the two threads never had a core each, and the
  //    numbers could not tell a shared budget from two separate ones. This one needs no
  //    parallelism, only the spinner using CPU at all.
  await _probe('deadline-other-threads', () async {
    final (sleeper, spinner) = await (
      _sleeperInIsolate(),
      _spinnerInIsolate(),
    ).wait;
    final ownCpu = sleeper.span.threadCpuMs;
    final String verdict;
    if (sleeper.completed && sleeper.span.wallMs >= _sleeperBoundMs - 100) {
      verdict = 'own-thread-cpu';
    } else if (sleeper.interrupted &&
        (ownCpu == null || ownCpu < _deadlineMs ~/ 2)) {
      verdict = switch (_blockedVerdict) {
        'cpu-time' => 'process-cpu',
        'wall-clock' => 'wall-clock',
        _ => 'not-own-thread-cpu',
      };
    } else {
      throw StateError('ambiguous: sleeper $sleeper; spinner $spinner');
    }
    return 'verdict=$verdict sleeper: $sleeper; spinner: $spinner';
  });

  // 10. When does the deadline start? ffi.cpp restarts it on every entry from Dart into QuickJS,
  //     and converting a JS string for Dart is one of those entries. So a script that calls a
  //     host function with a string argument may restart its own deadline on every call. Two
  //     otherwise identical loops, one passing a number and one a string, show whether it does.
  //     The string loop is judged by the deadline's own clock, which probe 8 identified: it
  //     restarts the deadline only if that clock passes 1000 ms without an interrupt.
  await _probe('deadline-host-call-restart', () async {
    _Run loop(String call) {
      final engine = FlutterQjs(timeout: _deadlineMs);
      try {
        _setGlobal(engine, 'hostNumber', (dynamic n) => null);
        _setGlobal(engine, 'hostString', (dynamic s) => null);
        return _runAgainstDeadline(engine, _hostCallScript(call));
      } finally {
        engine.close();
      }
    }

    final number = loop('hostNumber(1)');
    final string = loop("hostString('x')");
    final stringClock = _blockedVerdict == 'wall-clock'
        ? string.span.wallMs
        : string.span.clockMs ?? string.span.wallMs;
    final String verdict;
    if (number.interrupted &&
        string.completed &&
        stringClock > _deadlineMs * 1.2) {
      verdict = 'string-argument-restarts-deadline';
    } else if (number.interrupted && string.interrupted) {
      verdict = 'deadline-not-restarted';
    } else {
      throw StateError('ambiguous: number $number; string $string');
    }
    return 'verdict=$verdict number: $number; string: $string';
  });

  // 11. What the host is told when the limit leaves no room for the error. When an allocation
  //     would pass the limit, QuickJS builds an InternalError("out of memory"), which allocates
  //     too. If the refused request was small, there may be no room left for the error either,
  //     and QuickJS then throws null instead (JS_ThrowError2 does this on purpose, to avoid
  //     recursing). Probe 5 allocates 80 KB arrays, so whether it meets this depends on the
  //     allocator's size classes: on the first CI run API 26 did, and API 35 and Windows did not.
  //     Empty objects make the refused request tiny, which reproduces it on every platform. The
  //     limit is enforced either way; this is about whether the host can tell why.
  await _probeExpectingThrow(
    'watchdog-memory-limit-small-objects',
    'out of memory',
    () async {
      final engine = FlutterQjs(memoryLimit: 1024 * 1024);
      try {
        await engine.evaluate('const a = []; while (true) { a.push({}); }');
      } finally {
        engine.close();
      }
    },
  );

  // 12. The same, in an async function, which is how extensions will run. The null then arrives
  //     as a promise rejection rather than an exception, and before the fork handled it, Dart's
  //     completeError(null) threw instead of completing, so the awaited future never ended. The
  //     timeout turns such a hang into a failure rather than a run with no DONE line.
  await _probeExpectingThrow(
    'watchdog-memory-limit-async',
    'out of memory',
    () async {
      final engine = FlutterQjs(memoryLimit: 1024 * 1024);
      engine.dispatch();
      try {
        await Future<Object?>.value(
          engine.evaluate(
            '(async () => { const a = []; while (true) { a.push({}); } })()',
          ),
        ).timeout(const Duration(seconds: 5));
      } finally {
        engine.close();
      }
    },
  );
}

// ---------------------------------------------------------------------------------------------
// Probes 13 to 19: Kikuyomi's own `ScriptEngine` (packages/source_runtime) over the fork
// (`QuickJsScriptEngine`, packages/platform_adapters). The probes above test the binding; these
// test the interface the extension system is written against, end to end, in a built app — which
// is the only place it can be tested, because `flutter test` does not build a plugin's native
// library.
//
// Probe 14 is the one the fork's per-call deadline was written for: under the old deadline,
// `while (true) hostLog('x')` ran for ever on every platform.

/// The deadline these probes give a call. Short, so a probe that is not stopped is obvious.
const _engineDeadlineMs = 1000;

const _engineLimits = ScriptRuntimeLimits(
  callTimeout: Duration(milliseconds: _engineDeadlineMs),
);

/// A whole extension, small enough to read: one source, one method, one host call inside it.
const _probeExtension = '''
const extension = {
  sources: {
    probe: {
      async getPopular(page) {
        const suffix = await hostGreet('page ' + page);
        return { items: [{ key: 'b' + page, title: 'Book ' + suffix }], hasNextPage: page < 2 };
      },
      boom() {
        const error = new Error('the source is unhappy');
        error.kind = 'RateLimited';
        error.retryAfterMs = 1500;
        throw error;
      },
    },
  },
};
globalThis.__probe_invoke = function (method, args) {
  return extension.sources.probe[method].apply(null, args);
};
''';

/// Runs [body] with an engine of its own, disposed however it ends.
Future<T> _withEngine<T>(
  Future<T> Function(ScriptEngine engine) body, {
  ScriptRuntimeLimits limits = _engineLimits,
}) async {
  final engine = const QuickJsScriptEngineFactory().create(limits);
  try {
    return await body(engine);
  } finally {
    await engine.dispose();
  }
}

/// The exception [body] fails with, or a failure saying it did not fail.
Future<ScriptException> _failure(Future<Object?> Function() body) async {
  final Object? result;
  try {
    result = await body();
  } on ScriptException catch (e) {
    return e;
  }
  throw StateError('expected a ScriptException, got $result');
}

T _expect<T extends ScriptException>(ScriptException actual) => actual is T
    ? actual
    : throw StateError('expected a $T, got ${actual.runtimeType}: $actual');

/// Cancels through [handle] after [wait], from an isolate of its own, and says when it did.
///
/// Top level on purpose: a closure written inside a probe captures that probe's whole context,
/// including the engine itself, and an engine holds a `Future` and cannot be sent to an isolate.
Future<DateTime> _cancelFromAnotherIsolate(
  ScriptCancelHandle handle,
  Duration wait,
) => Isolate.run(() {
  sleep(wait);
  final sentAt = DateTime.now();
  handle.cancel();
  return sentAt;
});

Future<void> _runEngineProbes() async {
  // 13. A whole extension through the interface: load it, call a method with plain-data arguments,
  //     let it await a host function, and read the result back as plain data.
  await _probe('engine-extension-call', () async {
    return _withEngine((engine) async {
      engine.defineHostFunction(
        'hostGreet',
        (args) async => 'of ${args.first}',
      );
      await engine.evaluate(_probeExtension, name: 'probe-extension.js');
      final result = await engine.call('__probe_invoke', [
        'getPopular',
        [1],
      ]);
      if (result is! Map) throw StateError('expected an object, got $result');
      final items = result['items'];
      final title = items is List && items.isNotEmpty && items.first is Map
          ? (items.first as Map)['title']
          : null;
      if (title != 'Book of page 1') {
        throw StateError('expected "Book of page 1", got ${_oneLine(title)}');
      }
      if (result['hasNextPage'] != true) {
        throw StateError('expected hasNextPage, got $result');
      }
      return 'called getPopular(1) and got $title';
    });
  });

  // 14. The deadline the host arms for one call, which is what the fork's third change is for.
  //     A loop calling a host function with a string argument restarted the old deadline on every
  //     call (probe 10 still records that), so it ran until something else stopped it. Under an
  //     armed deadline it must stop near 1000 ms.
  await _probe('engine-deadline-host-call-loop', () async {
    return _withEngine((engine) async {
      var calls = 0;
      engine.defineHostFunction('hostLog', (args) {
        calls++;
        return null;
      });
      await engine.evaluate(
        'globalThis.__probe_spin = function () { while (true) { hostLog("x"); } };',
      );
      final watch = Stopwatch()..start();
      final failure = _expect<ScriptDeadlineException>(
        await _failure(() => engine.call('__probe_spin', [])),
      );
      watch.stop();
      if (watch.elapsedMilliseconds > _engineDeadlineMs * 3) {
        throw StateError(
          'stopped, but ${watch.elapsedMilliseconds}ms after a '
          '${_engineDeadlineMs}ms deadline',
        );
      }
      return 'stopped after ${watch.elapsedMilliseconds}ms and $calls host calls: '
          '${_oneLine(failure)}';
    });
  });

  // 15. A call that is not running cannot be interrupted: an extension awaiting a host promise
  //     that never settles would hang its caller for ever. The engine bounds the future as well as
  //     the script, so this ends at the deadline too.
  await _probe('engine-deadline-idle-call', () async {
    return _withEngine((engine) async {
      final never = Completer<Object?>();
      engine.defineHostFunction('hostWait', (args) => never.future);
      await engine.evaluate(
        'globalThis.__probe_wait = async function () { await hostWait(); return 1; };',
      );
      final watch = Stopwatch()..start();
      final failure = _expect<ScriptDeadlineException>(
        await _failure(() => engine.call('__probe_wait', [])),
      );
      watch.stop();
      if (watch.elapsedMilliseconds > _engineDeadlineMs * 3) {
        throw StateError('waited ${watch.elapsedMilliseconds}ms');
      }
      return 'stopped after ${watch.elapsedMilliseconds}ms: ${_oneLine(failure)}';
    });
  });

  // 16. The memory limit as a typed error, and a runtime that is still usable afterwards, which is
  //     what §3.6's pooling assumes.
  await _probe('engine-memory-limit-and-reuse', () async {
    return _withEngine(
      limits: const ScriptRuntimeLimits(
        memoryBytes: 1024 * 1024,
        callTimeout: Duration(milliseconds: _engineDeadlineMs),
      ),
      (engine) async {
        await engine.evaluate(
          'globalThis.__probe_eat = function () { const a = []; while (true) { a.push({}); } };'
          'globalThis.__probe_add = function (a, b) { return a + b; };',
        );
        final failure = _expect<ScriptMemoryException>(
          await _failure(() => engine.call('__probe_eat', [])),
        );
        final after = await engine.call('__probe_add', [40, 2]);
        if (after != 42) {
          throw StateError('expected 42 after the limit, got $after');
        }
        return 'typed error, and the runtime still answers: ${_oneLine(failure)}';
      },
    );
  });

  // 17. What an extension throws comes back as a typed error rather than a crash. The adapter turns
  //     the thrown value into one of the contract's error kinds; here the point is only that the
  //     engine reports the throw and stays usable.
  await _probe('engine-typed-error', () async {
    return _withEngine((engine) async {
      await engine.evaluate(_probeExtension, name: 'probe-extension.js');
      final failure = _expect<ScriptThrewException>(
        await _failure(
          () => engine.call('__probe_invoke', ['boom', <Object?>[]]),
        ),
      );
      if (!failure.message.contains('the source is unhappy')) {
        throw StateError('lost the message: ${_oneLine(failure)}');
      }
      return 'reported the throw: ${_oneLine(failure)}';
    });
  });

  // 18. The host can stop a script it is inside: a host function the script itself called cancels
  //     the call, and the call ends as cancelled rather than as a deadline.
  await _probe('engine-cancel-from-host-call', () async {
    return _withEngine(
      // A long deadline, so that a cancellation cannot be mistaken for the watchdog.
      limits: const ScriptRuntimeLimits(callTimeout: Duration(seconds: 10)),
      (engine) async {
        late final ScriptEngine self;
        engine.defineHostFunction('hostStop', (args) {
          self.cancel();
          return null;
        });
        self = engine;
        await engine.evaluate(
          'globalThis.__probe_stoppable = function () { while (true) { hostStop("x"); } };',
        );
        final watch = Stopwatch()..start();
        final failure = _expect<ScriptCancelledException>(
          await _failure(() => engine.call('__probe_stoppable', [])),
        );
        watch.stop();
        return 'cancelled after ${watch.elapsedMilliseconds}ms: ${_oneLine(failure)}';
      },
    );
  });

  // 19. The same from another isolate, which is the case that matters: while a script runs, the
  //     isolate that started it is inside the engine and reaches none of its own messages. The
  //     handle is plain data and the flag behind it is atomic, so another thread can set it.
  await _probe('engine-cancel-from-another-isolate', () async {
    return _withEngine(
      limits: const ScriptRuntimeLimits(callTimeout: Duration(seconds: 10)),
      (engine) async {
        await engine.evaluate(
          'globalThis.__probe_forever = function () { while (true) {} };',
        );
        final handle = engine.cancelHandle;
        if (handle == null) {
          throw StateError('the engine offers no cancel handle');
        }
        final started = DateTime.now();
        final stopping = _cancelFromAnotherIsolate(
          handle,
          const Duration(milliseconds: 500),
        );
        // Let the isolate start before this one disappears into QuickJS.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final watch = Stopwatch()..start();
        final outcome = await _failure(
          () => engine.call('__probe_forever', []),
        );
        watch.stop();
        final sent = (await stopping).difference(started).inMilliseconds;
        final failure = _expect<ScriptCancelledException>(outcome);
        if (watch.elapsedMilliseconds > 5000) {
          throw StateError(
            'cancelled only after ${watch.elapsedMilliseconds}ms, asked at ${sent}ms',
          );
        }
        return 'cancelled from another isolate after ${watch.elapsedMilliseconds}ms, '
            'asked at ${sent}ms: ${_oneLine(failure)}';
      },
    );
  });
}

// ---------------------------------------------------------------------------------------------
// Probes 20 to 22: the extension protocol on the real engine. Everything above the engine is unit
// tested against a fake one, but the prelude is JavaScript and only QuickJS can say whether it
// runs. These load a small extension through `ExtensionRuntime` with the real prelude and the real
// bridges, and call it through `JsSourceAdapter`, which is how the app will.

/// An extension that touches every part of the prelude on its way to one page of results.
const _protocolExtension = r'''
const extension = {
  sources: {
    probe: {
      async getPopular(page) {
        kikuyomi.log.info('looking at page ' + page);
        const url = new URL('/book/12?q=whale#top', 'https://example.org/index.html');
        const document = await kikuyomi.html.parse(
          '<ul id="results"><li class="card"><a href="/book/12">  Moby-Dick\n</a></li></ul>',
          'https://example.org/'
        );
        const link = document.selectFirst('ul#results > li.card > a');
        const hash = await kikuyomi.crypto.hash('sha256', 'abc');
        await kikuyomi.storage.set('last', String(page));
        const stored = await kikuyomi.storage.get('last');
        const text = new TextDecoder().decode(new TextEncoder().encode('héllo'));
        await new Promise((resolve) => setTimeout(resolve, 10));
        return {
          items: [
            {
              key: link.absUrl('href'),
              title: [
                link.text(),
                text,
                btoa('ok'),
                atob('b2s='),
                hash.slice(0, 8),
                url.searchParams.get('q'),
                url.pathname,
                stored,
                kikuyomi.host.apiVersion,
              ].join('|'),
            },
          ],
          hasNextPage: page < 2,
        };
      },
      async search(query, page) {
        try {
          const document = await kikuyomi.html.parse('<p>x</p>', null);
          document.select('li:has(> a)');
          return { items: [{ key: 'k', title: 'it did not refuse' }], hasNextPage: false };
        } catch (error) {
          return { items: [{ key: 'k', title: error.message }], hasNextPage: false };
        }
      },
      getChapters(bookKey) {
        const error = new Error('that book is gone');
        error.kind = 'NotFound';
        throw error;
      },
    },
  },
};
module.exports = extension;
''';

Future<void> _runProtocolProbes() async {
  final console = InMemoryExtensionLog();

  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source) body,
  ) async {
    final engine = const QuickJsScriptEngineFactory().create(
      const ScriptRuntimeLimits(callTimeout: Duration(seconds: 10)),
    );
    final runtime = await ExtensionRuntime.load(
      engine: engine,
      bundle: ExtensionBundle(
        extensionId: 'org.example.probe',
        code: _protocolExtension,
        domains: DomainAllowlist(['example.org']),
      ),
      host: const HostFacts(appVersion: '0.1.0'),
      bridges: [
        HtmlBridge(),
        const CryptoBridge(),
        LogBridge(extensionId: 'org.example.probe', sink: console),
        StorageBridge(
          extensionId: 'org.example.probe',
          store: InMemoryExtensionStore(),
        ),
      ],
    );
    try {
      return await body(
        await JsSourceAdapter.open(runtime: runtime, sourceKey: 'probe'),
      );
    } finally {
      await runtime.dispose();
    }
  }

  // 20. The prelude, the protocol and the adapter together: an extension that uses the log, the
  //     html bridge, the crypto bridge, storage, URL, TextEncoder, TextDecoder, atob, btoa and a
  //     timer, and whose result is decoded into the contract's types.
  await _probe('protocol-extension-end-to-end', () async {
    return withSource((source) async {
      final page = await source.getPopular(1);
      if (page.items.length != 1) {
        throw StateError('expected one book, got ${page.items.length}');
      }
      final book = page.items.single;
      // The version the host reports, not a literal: it moved to 1.1 with text sources, and a
      // probe that pinned the number would have failed on the emulator for the wrong reason.
      final expected =
          'Moby-Dick|héllo|b2s=|ok|ba7816bf|whale|/book/12|1|$apiVersion';
      if (book.title != expected) {
        throw StateError('expected "$expected", got "${book.title}"');
      }
      if (book.key != 'https://example.org/book/12') {
        throw StateError('absUrl gave ${book.key}');
      }
      if (!page.hasNextPage) throw StateError('expected another page');
      if (!console.messages.any((m) => m.text == 'looking at page 1')) {
        throw StateError('the log bridge was not reached');
      }
      return 'the whole prelude ran: ${book.title}';
    });
  });

  // 21. The selectors Phase 0 found `package:html` silently wrong about. The contract says they
  //     throw; an extension catches the error and reads its message.
  await _probe('protocol-refused-selector', () async {
    return withSource((source) async {
      final page = await source.search(
        SearchQuery(text: 'whale', filters: FilterValues(const {})),
        1,
      );
      final message = page.items.single.title;
      if (!message.contains('is not supported')) {
        throw StateError('expected a refusal, got "$message"');
      }
      return 'refused, and the extension could read why: $message';
    });
  });

  // 22. An error thrown with the SDK's shape arrives as its own kind, which is the whole reason
  //     nothing is thrown across the boundary.
  await _probe('protocol-error-kind', () async {
    return withSource((source) async {
      try {
        await source.getChapters('b1');
      } on NotFoundException catch (error) {
        return 'kept its kind: ${_oneLine(error)}';
      } on SourceException catch (error) {
        throw StateError('expected NotFound, got ${error.kind}: $error');
      }
      throw StateError('expected the call to fail');
    });
  });
}

// ---------------------------------------------------------------------------------------------
// Probes 23 to 34: the LibriVox extension the app ships, on the real engine.
//
// The extension is JavaScript, so nothing under `flutter test` can run it: the engine's native
// library only exists inside a built Flutter application. So it runs here, against answers recorded
// from librivox.org into assets/librivox/fixtures and served by a bridge that refuses anything it
// has no fixture for. The point of each probe is what the app would get: the contract's own types,
// decoded by `PlainDataDecoder` with the extension's declared domains, exactly as the app decodes
// them.

/// The LibriVox answers recorded for the requests the extension makes.
///
/// Matched on the parts of the URL the extension builds: a listing, with or without a title or an
/// author, or one book by id. Anything else has no fixture, and the bridge says so rather than
/// reaching the network.
final class _LibriVoxFixtures implements HostBridge {
  _LibriVoxFixtures(this._bodies);

  static Future<_LibriVoxFixtures> load() async {
    const names = [
      'popular-page-1',
      'search-title-whale',
      'search-author-whale',
      'search-author-melville',
      'book-9638',
      'no-results',
    ];
    final bodies = <String, String>{};
    for (final name in names) {
      bodies[name] = await rootBundle.loadString(
        'assets/librivox/fixtures/$name.json',
      );
    }
    return _LibriVoxFixtures(bodies);
  }

  final Map<String, String> _bodies;

  /// Every URL asked for, so a probe can say how many requests one call cost.
  final asked = <String>[];

  @override
  String get module => 'http';

  @override
  Future<Object?> call(String method, List<Object?> arguments) async {
    if (method != 'fetch') {
      throw HostCallException('there is no http.$method');
    }
    final request = arguments.objectAt(0, 'a request');
    final url = '${request['url']}';
    asked.add(url);
    final name = _fixtureFor(url);
    if (name == null) {
      // Not a Network error on purpose: this is the probe refusing, and it should not look like
      // anything the extension could have caused.
      throw HostCallException('the probe has no fixture for $url');
    }
    return {
      'status': 200,
      'url': url,
      'headers': const {'content-type': 'application/json'},
      'body': jsonDecode(_bodies[name]!),
    };
  }

  static String? _fixtureFor(String url) {
    if (!url.startsWith('https://librivox.org/api/feed/audiobooks/')) {
      return null;
    }
    if (url.contains('id=9638')) return 'book-9638';
    if (url.contains('id=')) return 'no-results';
    // %5E is the caret LibriVox needs for a prefix match.
    if (url.contains('title=%5Ewhale')) return 'search-title-whale';
    if (url.contains('author=%5Ewhale')) return 'search-author-whale';
    if (url.contains('title=%5Emelville')) return 'no-results';
    if (url.contains('author=%5Emelville')) return 'search-author-melville';
    if (url.contains('title=') || url.contains('author=')) return 'no-results';
    if (url.contains('offset=0')) return 'popular-page-1';
    return null;
  }
}

Future<void> _runLibriVoxProbes() async {
  final String code;
  try {
    code = await rootBundle.loadString('assets/librivox/main.js');
  } catch (e) {
    _report('librivox-asset', false, 'could not read the extension: $e');
    return;
  }
  final console = InMemoryExtensionLog();

  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source, _LibriVoxFixtures http) body,
  ) async {
    final http = await _LibriVoxFixtures.load();
    final runtime = await ExtensionRuntime.load(
      engine: const QuickJsScriptEngineFactory().create(
        const ScriptRuntimeLimits(callTimeout: Duration(seconds: 10)),
      ),
      bundle: ExtensionBundle(
        extensionId: 'org.kikuyomi.librivox',
        code: code,
        // The manifest's own domains. A URL outside them fails the call, which is the promise the
        // permissions screen makes.
        domains: DomainAllowlist([
          'librivox.org',
          '*.librivox.org',
          'archive.org',
          '*.archive.org',
        ]),
      ),
      host: const HostFacts(appVersion: '1.0.0'),
      bridges: [
        HtmlBridge(),
        const CryptoBridge(),
        LogBridge(extensionId: 'org.kikuyomi.librivox', sink: console),
        StorageBridge(
          extensionId: 'org.kikuyomi.librivox',
          store: InMemoryExtensionStore(),
        ),
        http,
      ],
    );
    try {
      return await body(
        await JsSourceAdapter.open(runtime: runtime, sourceKey: 'librivox'),
        http,
      );
    } finally {
      await runtime.dispose();
    }
  }

  // 23. The extension loads, exports the source the manifest names, and declares exactly the
  //     optional methods it has.
  await _probe('librivox-loads', () async {
    return withSource((source, http) async {
      if (source.capabilities.length != 1 ||
          !source.capabilities.contains(SourceCapability.filters)) {
        throw StateError('capabilities are ${source.capabilities}');
      }
      return 'loaded, and declares ${source.capabilities}';
    });
  });

  // 24. One page of the catalogue, decoded into the contract's BookSummary: the key is the book's
  //     LibriVox id, the cover comes out of the Archive item named in url_zip_file, and a page
  //     shorter than the page size is the last one.
  await _probe('librivox-popular', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      if (page.items.length != 3) {
        throw StateError('expected three books, got ${page.items.length}');
      }
      final first = page.items.first;
      if (first.key != '47' || first.title != 'Count of Monte Cristo') {
        throw StateError('read $first');
      }
      if (first.authors.join() != 'Alexandre Dumas') {
        throw StateError('authors are ${first.authors}');
      }
      if (first.durationMs != 178995000) {
        throw StateError('duration is ${first.durationMs}');
      }
      if ('${first.coverUrl}' !=
          'https://archive.org/services/img/count_monte_cristo_0711_librivox') {
        throw StateError('cover is ${first.coverUrl}');
      }
      if (page.hasNextPage) throw StateError('expected the last page');
      if (http.asked.length != 1) {
        throw StateError('one page cost ${http.asked.length} requests');
      }
      return 'three books, covers and all: ${first.title}';
    });
  });

  // 25. Search with no filter set asks by title and by author and puts the two together, because
  //     LibriVox will not do both at once and a listener typing a word may mean either.
  await _probe('librivox-search-title-and-author', () async {
    return withSource((source, http) async {
      final page = await source.search(const SearchQuery(text: 'whale'), 1);
      final keys = page.items.map((book) => book.key).toList();
      if (keys.join(',') != '11346,16760') {
        throw StateError('found $keys');
      }
      if (http.asked.length != 2) {
        throw StateError('expected two requests, made ${http.asked.length}');
      }
      return 'title first, then author: $keys';
    });
  });

  // 26. The other way round: a name no title starts with, which only the author search finds.
  await _probe('librivox-search-by-author-only', () async {
    return withSource((source, http) async {
      final page = await source.search(const SearchQuery(text: 'melville'), 1);
      final titles = page.items.map((book) => book.title).toList();
      if (titles.length != 3 || !titles.contains('Moby Dick, or the Whale')) {
        throw StateError('found $titles');
      }
      return 'the author search carried it: $titles';
    });
  });

  // 27. A search narrowed by the source's own filter asks once, of that field alone.
  await _probe('librivox-search-one-field', () async {
    return withSource((source, http) async {
      final filters = await source.getFilters();
      final field = filters.whereType<SelectFilter>().single;
      if (field.key != 'field' || field.options.length != 4) {
        throw StateError('the filter is $field');
      }
      final page = await source.search(
        SearchQuery(
          text: 'whale',
          filters: FilterValues({field.key: const SelectValue('title')}),
        ),
        1,
      );
      if (page.items.single.key != '11346') {
        throw StateError('found ${page.items}');
      }
      if (http.asked.length != 1 || !http.asked.single.contains('title=')) {
        throw StateError('asked ${http.asked}');
      }
      return 'one request, titles only: ${page.items.single.title}';
    });
  });

  // 28. A book's details: the HTML summary unwound into plain text with its paragraphs kept, the
  //     readers gathered from its sections, the language name mapped to a BCP 47 tag, and a status
  //     of complete, because every catalogued LibriVox project is finished.
  await _probe('librivox-book-details', () async {
    return withSource((source, http) async {
      final book = await source.getBookDetails('9638');
      if (!book.title.startsWith('Yellowstone National Park')) {
        throw StateError('title is ${book.title}');
      }
      if (book.authors.join() != 'Various') {
        throw StateError('authors are ${book.authors}');
      }
      if (book.narrators.isEmpty || book.narrators.first != 'David Wales') {
        throw StateError('narrators are ${book.narrators}');
      }
      final description = book.description ?? '';
      if (description.contains('<') || description.contains('&nbsp;')) {
        throw StateError('the summary still holds markup: $description');
      }
      if (book.language != 'en') {
        throw StateError('language is ${book.language}');
      }
      if (book.publishedDate != '1868') {
        throw StateError('published is ${book.publishedDate}');
      }
      if (book.publisher != 'LibriVox') {
        throw StateError('publisher is ${book.publisher}');
      }
      if (book.status != BookStatus.complete) {
        throw StateError('status is ${book.status}');
      }
      if (book.genres.isEmpty) throw StateError('no genres');
      if ('${book.webUrl}' !=
          'https://librivox.org/yellowstone-national-park-six-early-pieces-by-various/') {
        throw StateError('web url is ${book.webUrl}');
      }
      if (book.totalDurationMs != 18909000) {
        throw StateError('total is ${book.totalDurationMs}');
      }
      return 'read ${book.title}, ${book.narrators.length} readers, '
          '${description.length} characters of summary';
    });
  });

  // 29. Its chapters are LibriVox's sections, in order, keyed by the section id. The extension
  //     memoises the one document that holds both, so details and chapters together cost one
  //     request rather than two.
  await _probe('librivox-chapters', () async {
    return withSource((source, http) async {
      await source.getBookDetails('9638');
      final chapters = await source.getChapters('9638');
      if (chapters.length != 9) {
        throw StateError('expected nine sections, got ${chapters.length}');
      }
      if (chapters.first.key != '332498') {
        throw StateError('first key is ${chapters.first.key}');
      }
      if (chapters.first.durationMs != 1279000) {
        throw StateError('first duration is ${chapters.first.durationMs}');
      }
      final keys = chapters.map((chapter) => chapter.key).toSet();
      if (keys.length != chapters.length) {
        throw StateError('two chapters share a key');
      }
      if (http.asked.length != 1) {
        throw StateError(
          'details and chapters cost ${http.asked.length} requests',
        );
      }
      return 'nine sections, one request: ${chapters.first.title}';
    });
  });

  // 30. Resolving a chapter gives the file on the Internet Archive, its format and its length, with
  //     the file keyed by its own name so two chapters cut from one file would share it.
  await _probe('librivox-resolve-media', () async {
    return withSource((source, http) async {
      final resolution = await source.resolveMedia(
        const ChapterRef(bookKey: '9638', chapterKey: '332499'),
        const ResolveContext(
          purpose: ResolvePurpose.stream,
          network: NetworkType.unknown,
        ),
      );
      final segment = resolution.segments.single;
      // Without the `www.` LibriVox writes into listen_url; probe 34 is why.
      if ('${segment.request.url}' !=
          'https://archive.org/download/yellowstone6pieces_1502_librivox/'
              'yellowstone6pieces_02_various_64kb.mp3') {
        throw StateError('url is ${segment.request.url}');
      }
      if (segment.fileKey != 'yellowstone6pieces_02_various_64kb.mp3') {
        throw StateError('file key is ${segment.fileKey}');
      }
      if (segment.format != MediaFormat.mp3) {
        throw StateError('format is ${segment.format}');
      }
      if (segment.durationMs != 3183000) {
        throw StateError('duration is ${segment.durationMs}');
      }
      if (segment.range != null) {
        throw StateError('a whole file should have no range');
      }
      if (resolution.expiresAt != null) {
        throw StateError('the Archive URLs do not expire');
      }
      return 'resolved to ${segment.fileKey}';
    });
  });

  // 31. The path the app really takes: the runtime confined to a worker isolate of its own (§3.6),
  //     with http, storage and log proxied back to the isolate that started it. Nothing else runs
  //     QuickJS in a spawned isolate — the tests use a fake engine there, and every probe above it
  //     runs the engine here — so this is the only place that says whether the engine, the native
  //     library and the plain-data crossing all work where the app puts them.
  await _probe('librivox-in-a-worker', () async {
    final http = await _LibriVoxFixtures.load();
    final worker = await ExtensionWorker.start(
      engineFactory: const QuickJsScriptEngineFactory(),
      bundle: ExtensionBundle(
        extensionId: 'org.kikuyomi.librivox',
        code: code,
        domains: DomainAllowlist([
          'librivox.org',
          '*.librivox.org',
          'archive.org',
          '*.archive.org',
        ]),
      ),
      host: const HostFacts(appVersion: '1.0.0'),
      bridges: [
        http,
        StorageBridge(
          extensionId: 'org.kikuyomi.librivox',
          store: InMemoryExtensionStore(),
        ),
        LogBridge(extensionId: 'org.kikuyomi.librivox', sink: console),
      ],
    );
    try {
      final source = await JsSourceAdapter.open(
        runtime: worker,
        sourceKey: 'librivox',
      );
      final page = await source.getPopular(1);
      if (page.items.length != 3) {
        throw StateError('expected three books, got ${page.items.length}');
      }
      final chapters = await source.getChapters('9638');
      if (chapters.length != 9) {
        throw StateError('expected nine sections, got ${chapters.length}');
      }
      if (http.asked.isEmpty) {
        throw StateError('the http bridge was never reached from the worker');
      }
      return 'the worker answered ${page.items.first.title} and '
          '${chapters.length} sections, over ${http.asked.length} requests '
          'proxied back to this isolate';
    } finally {
      await worker.dispose();
    }
  });

  // 32. A search that matches nothing comes back from LibriVox as an error object with status 200.
  //     That is an empty page, not a failure; asked for one book by id, the same answer means the
  //     book is gone, which is NotFound.
  await _probe('librivox-nothing-found', () async {
    return withSource((source, http) async {
      final page = await source.search(const SearchQuery(text: 'zzzz'), 1);
      if (page.items.isNotEmpty || page.hasNextPage) {
        throw StateError('expected an empty page, got $page');
      }
      try {
        await source.getBookDetails('1');
        throw StateError('expected the book to be missing');
      } on NotFoundException catch (error) {
        return 'an empty search is empty, and a missing book is NotFound: '
            '${_oneLine(error)}';
      }
    });
  });

  // 33. The whole of opening and playing one book costs LibriVox one request. Details, chapters
  //     and the audio of every chapter all read the same extended document, and the extension
  //     keeps the fetch itself rather than its result, so calls that overlap join the one already
  //     on its way instead of starting another. This is what made pressing play on a streamed book
  //     slow: one request per chapter, each waiting for the last.
  await _probe('librivox-one-fetch-per-book', () async {
    return withSource((source, http) async {
      await source.getBookDetails('9638');
      final chapters = await source.getChapters('9638');
      // All at once, which is what a book being resolved in the background does.
      final resolutions = await Future.wait([
        for (final chapter in chapters)
          source.resolveMedia(
            ChapterRef(bookKey: '9638', chapterKey: chapter.key),
            const ResolveContext(
              purpose: ResolvePurpose.stream,
              network: NetworkType.unknown,
            ),
          ),
      ]);
      if (resolutions.length != chapters.length) {
        throw StateError(
          'resolved ${resolutions.length} of ${chapters.length}',
        );
      }
      final keys = {
        for (final resolution in resolutions)
          resolution.segments.single.fileKey,
      };
      if (keys.length != chapters.length) {
        throw StateError('$keys is not one file per section');
      }
      if (http.asked.length != 1) {
        throw StateError(
          'details, chapters and ${chapters.length} resolutions cost '
          '${http.asked.length} requests',
        );
      }
      return 'details, ${chapters.length} chapters and ${chapters.length} '
          'resolutions, one request';
    });
  });

  // 34. The audio address the extension hands over is the one with the fewest hops in front of it.
  //     LibriVox writes `www.archive.org` into every `listen_url`, and that host redirects to
  //     `archive.org`, which redirects again to the node the file is really on. A player asks for
  //     a file in ranges, so that extra hop is paid on every seek rather than once. Both hosts are
  //     declared in the manifest; only the host changes.
  await _probe('librivox-audio-url-has-no-extra-hop', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters('9638');
      final resolution = await source.resolveMedia(
        ChapterRef(bookKey: '9638', chapterKey: chapters.first.key),
        const ResolveContext(
          purpose: ResolvePurpose.stream,
          network: NetworkType.unknown,
        ),
      );
      final url = resolution.segments.single.request.url;
      if (url.host != 'archive.org') {
        throw StateError('audio is served from ${url.host}, not archive.org');
      }
      if (!url.path.endsWith('yellowstone6pieces_01_various_64kb.mp3')) {
        throw StateError('$url is not the file of the first section');
      }
      if (http.asked.isEmpty) {
        throw StateError('nothing was fetched');
      }
      return 'the www LibriVox writes into listen_url is gone: $url';
    });
  });
}

// ---------------------------------------------------------------- internet archive and storynory
//
// The two extensions that ship only through the repository. They are here for a reason worth
// writing down: both went out having passed a Node harness, a static manifest check and a green CI
// run, and both failed the moment a book was opened, because nothing had ever decoded what they
// returned with the app's own decoder. That is what these do.

/// The Archive answers recorded for the requests the extension makes.
final class _ArchiveFixtures implements HostBridge {
  _ArchiveFixtures(this._bodies);

  static Future<_ArchiveFixtures> load() async {
    const names = ['popular-page-1', 'search-sherlock', 'item-whale'];
    final bodies = <String, String>{};
    for (final name in names) {
      bodies[name] = await rootBundle.loadString(
        'assets/internetarchive/fixtures/$name.json',
      );
    }
    return _ArchiveFixtures(bodies);
  }

  final Map<String, String> _bodies;
  final asked = <String>[];

  @override
  String get module => 'http';

  @override
  Future<Object?> call(String method, List<Object?> arguments) async {
    if (method != 'fetch') throw HostCallException('there is no http.$method');
    final request = arguments.objectAt(0, 'a request');
    final url = '${request['url']}';
    asked.add(url);
    final name = _fixtureFor(url);
    if (name == null) {
      throw HostCallException('the probe has no fixture for $url');
    }
    return {
      'status': 200,
      'url': url,
      'headers': const {'content-type': 'application/json'},
      'body': jsonDecode(_bodies[name]!),
    };
  }

  static String? _fixtureFor(String url) {
    if (url.startsWith('https://archive.org/metadata/')) {
      return url.endsWith('the_whale_1610.poem_librivox') ? 'item-whale' : null;
    }
    if (!url.startsWith('https://archive.org/advancedsearch.php')) return null;
    if (url.contains('sherlock')) return 'search-sherlock';
    if (url.contains('sort')) return 'popular-page-1';
    return null;
  }
}

/// Storynory's feed, recorded and trimmed to four stories.
///
/// Served as text rather than decoded: the extension asks for `responseType: 'text'` because a feed
/// is XML, and handing it an object would be answering a question it did not ask.
final class _StorynoryFixtures implements HostBridge {
  _StorynoryFixtures(this._feed);

  static Future<_StorynoryFixtures> load() async => _StorynoryFixtures(
    await rootBundle.loadString('assets/storynory/fixtures/feed.xml'),
  );

  final String _feed;
  final asked = <String>[];

  @override
  String get module => 'http';

  @override
  Future<Object?> call(String method, List<Object?> arguments) async {
    if (method != 'fetch') throw HostCallException('there is no http.$method');
    final request = arguments.objectAt(0, 'a request');
    final url = '${request['url']}';
    asked.add(url);
    if (url != 'https://www.storynory.com/feeds/stories') {
      throw HostCallException('the probe has no fixture for $url');
    }
    return {
      'status': 200,
      'url': url,
      'headers': const {'content-type': 'application/rss+xml'},
      'body': _feed,
    };
  }
}

/// Standard Ebooks' pages, recorded: a catalogue page, Frankenstein's page, its table of contents
/// and its first chapter. Served as text, as the extension asks.
final class _StandardEbooksFixtures implements HostBridge {
  _StandardEbooksFixtures(this._pages);

  static const base = 'https://standardebooks.org';

  static Future<_StandardEbooksFixtures> load() async {
    Future<String> page(String name) =>
        rootBundle.loadString('assets/standardebooks/fixtures/$name');
    return _StandardEbooksFixtures({
      '$base/ebooks?per-page=48&page=1&sort=popularity': await page(
        'popular.html',
      ),
      '$base/ebooks/mary-shelley/frankenstein': await page('book.html'),
      '$base/ebooks/mary-shelley/frankenstein/text': await page('toc.html'),
      '$base/ebooks/mary-shelley/frankenstein/text/chapter-1': await page(
        'chapter-1.html',
      ),
    });
  }

  final Map<String, String> _pages;
  final asked = <String>[];

  @override
  String get module => 'http';

  @override
  Future<Object?> call(String method, List<Object?> arguments) async {
    if (method != 'fetch') throw HostCallException('there is no http.$method');
    final request = arguments.objectAt(0, 'a request');
    final url = '${request['url']}';
    asked.add(url);
    final page = _pages[url];
    if (page == null) {
      throw HostCallException('the probe has no fixture for $url');
    }
    return {
      'status': 200,
      'url': url,
      'headers': const {'content-type': 'text/html; charset=utf-8'},
      'body': page,
    };
  }
}

/// Project Gutenberg's answers, recorded: a page of the catalogue, a search, one book's catalogue
/// entry, and the book itself.
///
/// The book is a real transcription with its own header, footer and chapter markup, and with the
/// prose replaced: what the extension reads is the shape of a transcription, not what it says.
final class _GutenbergFixtures implements HostBridge {
  _GutenbergFixtures(this._json, this._book);

  static Future<_GutenbergFixtures> load() async {
    Future<String> asset(String name) =>
        rootBundle.loadString('assets/gutenberg/fixtures/$name');
    return _GutenbergFixtures({
      'https://gutendex.com/books/?sort=popular&page=1': await asset(
        'popular.json',
      ),
      'https://gutendex.com/books/?page=1&search=frankenstein': await asset(
        'search.json',
      ),
      'https://gutendex.com/books/84': await asset('book.json'),
    }, await asset('book.html'));
  }

  final Map<String, String> _json;
  final String _book;
  final asked = <String>[];

  @override
  String get module => 'http';

  @override
  Future<Object?> call(String method, List<Object?> arguments) async {
    if (method != 'fetch') throw HostCallException('there is no http.$method');
    final request = arguments.objectAt(0, 'a request');
    final url = '${request['url']}';
    asked.add(url);
    if (url == 'https://www.gutenberg.org/ebooks/84.html.images') {
      return {
        'status': 200,
        'url': url,
        'headers': const {'content-type': 'text/html; charset=utf-8'},
        'body': _book,
      };
    }
    final body = _json[url];
    if (body == null) {
      throw HostCallException('the probe has no fixture for $url');
    }
    return {
      'status': 200,
      'url': url,
      'headers': const {'content-type': 'application/json'},
      'body': jsonDecode(body),
    };
  }
}

/// The Podcasts source's recorded answers.
///
/// Four documents, because this source has four ways in: a feed, Apple's index by search, Apple's
/// index by id, and a Spotify show page read for the show's name. A request for anything else fails
/// loudly rather than quietly returning nothing, so a probe that meant to exercise one path and
/// took another says so.
final class _PodcastFixtures implements HostBridge {
  _PodcastFixtures(
    this._feed,
    this._search,
    this._lookup,
    this._spotify,
    this._chart,
    this._chartLookup,
  );

  static const feedUrl = 'https://anchor.fm/s/100622f90/podcast/rss';

  /// The Fiction chart's own order, which is the order the extension must hand back. The last of
  /// them is the one the lookup has no feed for, and is expected to disappear.
  static const chartOrder = [
    'Table Read',
    'Sherlock Holmes Short Stories',
    'The Adventure Zone',
    'The NoSleep Podcast',
    'The Sleepy Bookshelf',
    'Six Minutes',
  ];

  static Future<_PodcastFixtures> load() async => _PodcastFixtures(
    await rootBundle.loadString('assets/podcasts/fixtures/feed.xml'),
    await rootBundle.loadString('assets/podcasts/fixtures/apple-search.json'),
    await rootBundle.loadString('assets/podcasts/fixtures/apple-lookup.json'),
    await rootBundle.loadString('assets/podcasts/fixtures/spotify-show.html'),
    await rootBundle.loadString('assets/podcasts/fixtures/chart-fiction.json'),
    await rootBundle.loadString('assets/podcasts/fixtures/chart-lookup.json'),
  );

  final String _feed;
  final String _search;
  final String _lookup;
  final String _spotify;
  final String _chart;
  final String _chartLookup;
  final asked = <String>[];

  @override
  String get module => 'http';

  @override
  Future<Object?> call(String method, List<Object?> arguments) async {
    if (method != 'fetch') throw HostCallException('there is no http.$method');
    final request = arguments.objectAt(0, 'a request');
    final url = '${request['url']}';
    asked.add(url);

    Object? body;
    if (url == feedUrl) {
      body = _feed;
    } else if (url.startsWith('https://itunes.apple.com/search')) {
      // Asked for as JSON, so it arrives decoded, the way the host bridge hands it over.
      body = jsonDecode(_search);
    } else if (url.startsWith('https://itunes.apple.com/lookup')) {
      // One id is a link being resolved; a list of them is a chart being turned into feeds. The
      // two answer differently, and telling them apart by the comma is what the extension's own
      // two call sites amount to.
      body = jsonDecode(url.contains(',') ? _chartLookup : _lookup);
    } else if (url.contains('/rss/toppodcasts/')) {
      // Every genre answers with the same chart. Which genre was asked for is the extension's
      // business; that a page is a chart at all is this probe's.
      body = jsonDecode(_chart);
    } else if (url.startsWith('https://open.spotify.com/show/')) {
      body = _spotify;
    } else {
      throw HostCallException('the probe has no fixture for $url');
    }
    return {
      'status': 200,
      'url': url,
      'headers': const {'content-type': 'text/plain'},
      'body': body,
    };
  }
}

/// Opens [extensionId]'s source over [bridge], with the manifest's own domains.
Future<T> _withExtension<T>({
  required String asset,
  required String extensionId,
  required String sourceKey,
  required List<String> domains,
  required HostBridge http,
  required Future<T> Function(JsSourceAdapter source) body,
  SourceKind kind = SourceKind.audio,
}) async {
  final code = await rootBundle.loadString(asset);
  final runtime = await ExtensionRuntime.load(
    engine: const QuickJsScriptEngineFactory().create(
      const ScriptRuntimeLimits(callTimeout: Duration(seconds: 10)),
    ),
    bundle: ExtensionBundle(
      extensionId: extensionId,
      code: code,
      domains: DomainAllowlist(domains),
    ),
    host: const HostFacts(appVersion: '1.0.0'),
    bridges: [
      HtmlBridge(),
      const CryptoBridge(),
      LogBridge(extensionId: extensionId, sink: InMemoryExtensionLog()),
      StorageBridge(extensionId: extensionId, store: InMemoryExtensionStore()),
      http,
    ],
  );
  try {
    return await body(
      await JsSourceAdapter.open(
        runtime: runtime,
        sourceKey: sourceKey,
        kind: kind,
      ),
    );
  } finally {
    await runtime.dispose();
  }
}

Future<void> _runArchiveProbes() async {
  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source, _ArchiveFixtures http) body,
  ) async {
    final http = await _ArchiveFixtures.load();
    return _withExtension(
      asset: 'assets/internetarchive/main.js',
      extensionId: 'org.kikuyomi.internetarchive',
      sourceKey: 'internetarchive',
      domains: const ['archive.org', '*.archive.org'],
      http: http,
      body: (source) => body(source, http),
    );
  }

  await _probe('archive-loads', () async {
    return withSource((source, http) async {
      if (source.capabilities.length != 1 ||
          !source.capabilities.contains(SourceCapability.filters)) {
        throw StateError('capabilities are ${source.capabilities}');
      }
      return 'loaded, and declares ${source.capabilities}';
    });
  });

  await _probe('archive-popular', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      if (page.items.length != 50) {
        throw StateError('expected fifty, got ${page.items.length}');
      }
      if (page.items.first.key != 'librivoxaudio') {
        throw StateError('first is ${page.items.first.key}');
      }
      if (!page.hasNextPage) throw StateError('expected another page');
      if (http.asked.length != 1) {
        throw StateError('one page cost ${http.asked.length} requests');
      }
      if (!http.asked.single.contains('sort')) {
        throw StateError('popular did not ask for an order: ${http.asked}');
      }
      return 'fifty items, ranked: ${page.items.first.title}';
    });
  });

  await _probe('archive-search', () async {
    return withSource((source, http) async {
      final page = await source.search(const SearchQuery(text: 'sherlock'), 1);
      if (page.items.isEmpty) throw StateError('found nothing');
      if (http.asked.single.contains('sort')) {
        throw StateError(
          'a search should be ranked by relevance, not downloads',
        );
      }
      return 'found ${page.items.length}: ${page.items.first.title}';
    });
  });

  // The probe this whole file exists for. `decodeBookDetails` reads authors, narrators and genres
  // with required: true, and an extension that leaves one out fails here rather than on a listener's
  // first tap — which is how it failed before.
  await _probe('archive-book-details', () async {
    return withSource((source, http) async {
      final book = await source.getBookDetails('the_whale_1610.poem_librivox');
      if (book.title != 'The Whale') throw StateError('title is ${book.title}');
      if (book.authors.join() != 'Ellis Parker Butler') {
        throw StateError('authors are ${book.authors}');
      }
      // Empty and present: the Archive has no narrator field, and saying nothing is not the same
      // as failing to answer.
      if (book.narrators.isNotEmpty) {
        throw StateError('narrators are ${book.narrators}');
      }
      // Split, not one long semicolon-separated string drawn as a single chip.
      if (book.genres.length < 4 || book.genres.any((g) => g.contains(';'))) {
        throw StateError('genres are ${book.genres}');
      }
      final description = book.description ?? '';
      if (description.contains('<')) {
        throw StateError('the description still holds markup: $description');
      }
      if (book.language != 'en') {
        throw StateError('language is ${book.language}');
      }
      if (book.status != BookStatus.complete) {
        throw StateError('status is ${book.status}');
      }
      return 'decoded: ${book.genres.length} genres, no narrators claimed';
    });
  });

  // Sixty audio files, four renderings of each of fifteen chapters, grouped by the `original` every
  // derivative names. Getting this wrong gives a book with sixty chapters.
  await _probe('archive-chapters-are-grouped', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters('the_whale_1610.poem_librivox');
      if (chapters.length != 15) {
        throw StateError('expected fifteen chapters, got ${chapters.length}');
      }
      final keys = chapters.map((c) => c.key).toSet();
      if (keys.length != chapters.length) {
        throw StateError('chapter keys repeat');
      }
      if (chapters.any((c) => c.durationMs == null)) {
        throw StateError('a chapter has no duration');
      }
      if (!chapters.first.title.startsWith('01')) {
        throw StateError('not in track order: ${chapters.first.title}');
      }
      return 'sixty files became ${chapters.length} chapters, in order';
    });
  });

  await _probe('archive-resolve-media', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters('the_whale_1610.poem_librivox');
      final media = await source.resolveMedia(
        ChapterRef(
          bookKey: 'the_whale_1610.poem_librivox',
          chapterKey: chapters.first.key,
        ),
        const ResolveContext(
          purpose: ResolvePurpose.stream,
          network: NetworkType.unknown,
        ),
      );
      final segment = media.segments.single;
      if (!segment.request.url.toString().startsWith(
        'https://archive.org/download/',
      )) {
        throw StateError('url is ${segment.request.url}');
      }
      if (segment.format != MediaFormat.mp3) {
        throw StateError('format is ${segment.format}');
      }
      if (media.expiresAt != null) {
        throw StateError('the Archive serves these without an expiry');
      }
      return 'one segment: ${segment.request.url}';
    });
  });

  await _probe('archive-unknown-item', () async {
    return withSource((source, http) async {
      try {
        await source.getBookDetails('no_such_item_at_all');
        throw StateError('an item that does not exist was read anyway');
      } on SourceException catch (error) {
        return 'refused as ${error.kind}';
      }
    });
  });
}

Future<void> _runStorynoryProbes() async {
  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source, _StorynoryFixtures http) body,
  ) async {
    final http = await _StorynoryFixtures.load();
    return _withExtension(
      asset: 'assets/storynory/main.js',
      extensionId: 'org.kikuyomi.storynory',
      sourceKey: 'storynory',
      // The three hosts the manifest names. The audio one is load-bearing: without it the media
      // URL fails the allowlist and a story will not play.
      domains: const ['storynory.com', '*.storynory.com', '*.libsyn.com'],
      http: http,
      body: (source) => body(source, http),
    );
  }

  await _probe('storynory-loads', () async {
    return withSource((source, http) async {
      if (source.capabilities.isNotEmpty) {
        throw StateError('capabilities are ${source.capabilities}');
      }
      return 'loaded, declaring nothing optional';
    });
  });

  await _probe('storynory-popular', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      if (page.items.length != 4) {
        throw StateError('expected four stories, got ${page.items.length}');
      }
      if (page.hasNextPage) throw StateError('four is the whole fixture');
      if (http.asked.length != 1) {
        throw StateError('a listing cost ${http.asked.length} requests');
      }
      return 'four stories: ${page.items.first.title}';
    });
  });

  await _probe('storynory-search-reads-the-feed-once', () async {
    return withSource((source, http) async {
      final page = await source.search(const SearchQuery(text: 'magic'), 1);
      // Both of the fixture's stories whose titles hold the word, and neither of the two that do
      // not: a search here narrows the feed rather than asking the site anything.
      if (page.items.length != 2) {
        throw StateError('found ${page.items.map((b) => b.title)}');
      }
      if (page.items.any((b) => !b.title.toLowerCase().contains('magic'))) {
        throw StateError(
          'matched something else: ${page.items.map((b) => b.title)}',
        );
      }
      if (http.asked.length != 1) {
        throw StateError('matching locally cost ${http.asked.length} requests');
      }
      return 'matched in the feed already in hand: '
          '${page.items.map((b) => b.title).join(', ')}';
    });
  });

  await _probe('storynory-book-details', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      final book = await source.getBookDetails(page.items.first.key);
      if (book.narrators.isNotEmpty) {
        throw StateError('narrators are ${book.narrators}');
      }
      if (book.genres.isEmpty) {
        throw StateError(
          'the feed names categories; genres are ${book.genres}',
        );
      }
      final description = book.description ?? '';
      if (description.contains('<') || description.contains('CDATA')) {
        throw StateError('the summary still holds markup: $description');
      }
      if (book.totalDurationMs == null || book.totalDurationMs! <= 0) {
        throw StateError('duration is ${book.totalDurationMs}');
      }
      return 'decoded: ${book.genres.join(', ')}';
    });
  });

  await _probe('storynory-one-story-is-one-chapter', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      final chapters = await source.getChapters(page.items.first.key);
      if (chapters.length != 1) {
        throw StateError('expected one chapter, got ${chapters.length}');
      }
      return 'one story, one chapter: ${chapters.single.title}';
    });
  });

  // The probe that proves the libsyn wildcard earns its place: the audio is on another host
  // entirely, and the decoder checks it against the manifest's domains.
  await _probe('storynory-resolve-media', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      final chapters = await source.getChapters(page.items.first.key);
      final media = await source.resolveMedia(
        ChapterRef(
          bookKey: page.items.first.key,
          chapterKey: chapters.single.key,
        ),
        const ResolveContext(
          purpose: ResolvePurpose.stream,
          network: NetworkType.unknown,
        ),
      );
      final segment = media.segments.single;
      if (segment.request.url.host != 'traffic.libsyn.com') {
        throw StateError('url is ${segment.request.url}');
      }
      if (segment.format != MediaFormat.mp3) {
        throw StateError('format is ${segment.format}');
      }
      return 'audio on another host, allowed: ${segment.request.url.host}';
    });
  });
}

Future<void> _runStandardEbooksProbes() async {
  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source, _StandardEbooksFixtures http)
    body,
  ) async {
    final http = await _StandardEbooksFixtures.load();
    return _withExtension(
      asset: 'assets/standardebooks/main.js',
      extensionId: 'org.kikuyomi.standardebooks',
      sourceKey: 'standardebooks',
      domains: const ['standardebooks.org'],
      http: http,
      kind: SourceKind.text,
      body: (source) => body(source, http),
    );
  }

  const frankenstein = 'mary-shelley/frankenstein';

  await _probe('standardebooks-popular', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      if (page.items.length != 48) {
        throw StateError('expected a page of 48, got ${page.items.length}');
      }
      if (!page.hasNextPage) throw StateError('the catalogue has more pages');
      final first = page.items.first;
      if (first.authors.isEmpty || first.coverUrl == null) {
        throw StateError('${first.title} has no author or cover');
      }
      return '48 books, first ${first.title} by ${first.authors.single}';
    });
  });

  await _probe('standardebooks-book-details', () async {
    return withSource((source, http) async {
      final book = await source.getBookDetails(frankenstein);
      if (book.title != 'Frankenstein' ||
          book.authors.join() != 'Mary Shelley') {
        throw StateError('read ${book.title} by ${book.authors}');
      }
      if (!(book.coverUrl?.path.endsWith('/cover.jpg') ?? false)) {
        throw StateError('cover is ${book.coverUrl}, not the cover itself');
      }
      if ((book.description ?? '').contains('<')) {
        throw StateError('the description still holds markup');
      }
      return 'decoded: ${book.genres.join(', ')}';
    });
  });

  await _probe('standardebooks-chapters-leave-out-paperwork', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters(frankenstein);
      final keys = [for (final c in chapters) c.key];
      for (final paperwork in const ['titlepage', 'imprint', 'colophon']) {
        if (keys.contains(paperwork)) {
          throw StateError('listed $paperwork');
        }
      }
      if (!keys.contains('chapter-1')) {
        throw StateError('no chapter-1 in $keys');
      }
      return '${chapters.length} sections, from ${chapters.first.title}';
    });
  });

  // The whole of 1.1 on the real engine: the extension hands over HTML, the adapter decodes it
  // through the contract, and what comes back is blocks.
  await _probe('standardebooks-chapter-content', () async {
    return withSource((source, http) async {
      final content = await source.getChapterContent(
        const ChapterRef(bookKey: frankenstein, chapterKey: 'chapter-1'),
      );
      final heading = content.blocks.whereType<HeadingBlock>().firstOrNull;
      final text = [
        for (final run in heading?.runs ?? const <TextRun>[]) run.text,
      ].join();
      if (text != 'Chapter I') throw StateError('heading is "$text"');
      final paragraphs = content.blocks.whereType<ParagraphBlock>().length;
      if (paragraphs < 10) throw StateError('only $paragraphs paragraphs');
      return '$paragraphs paragraphs under "$text"';
    });
  });
}

Future<void> _runGutenbergProbes() async {
  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source, _GutenbergFixtures http) body,
  ) async {
    final http = await _GutenbergFixtures.load();
    return _withExtension(
      asset: 'assets/gutenberg/main.js',
      extensionId: 'org.kikuyomi.gutenberg',
      sourceKey: 'gutenberg',
      // Two hosts, both load-bearing: the catalogue is Gutendex's and the books are Gutenberg's.
      domains: const ['gutendex.com', 'gutenberg.org', '*.gutenberg.org'],
      http: http,
      kind: SourceKind.text,
      body: (source) => body(source, http),
    );
  }

  await _probe('gutenberg-popular', () async {
    return withSource((source, http) async {
      final page = await source.getPopular(1);
      if (page.items.length != 3) {
        throw StateError('expected three books, got ${page.items.length}');
      }
      if (!page.hasNextPage) throw StateError('the catalogue has more pages');
      final first = page.items.first;
      // The catalogue files a name for shelving; a shelf shows it as a person says it.
      if (first.authors.single.contains(',')) {
        throw StateError('the author is filed, not read: ${first.authors}');
      }
      return '${first.title} by ${first.authors.single}';
    });
  });

  await _probe('gutenberg-search', () async {
    return withSource((source, http) async {
      final page = await source.search(
        const SearchQuery(text: 'frankenstein'),
        1,
      );
      if (page.items.isEmpty) throw StateError('found nothing');
      if (page.hasNextPage) throw StateError('the fixture is one page');
      return 'found ${page.items.first.title}';
    });
  });

  await _probe('gutenberg-book-details', () async {
    return withSource((source, http) async {
      final book = await source.getBookDetails('84');
      if (!book.title.toLowerCase().startsWith('frankenstein')) {
        throw StateError('read ${book.title}');
      }
      if (book.authors.single != 'Mary Wollstonecraft Shelley') {
        throw StateError('the author is ${book.authors}');
      }
      if ((book.description ?? '').isEmpty) throw StateError('no description');
      if (book.genres.isEmpty) throw StateError('no genres');
      return 'decoded: ${book.genres.take(2).join(', ')}';
    });
  });

  await _probe('gutenberg-chapters-are-found-in-one-file', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters('84');
      final keys = [for (final c in chapters) c.key];
      // Gutenberg's own boilerplate and the table of contents are not chapters of the book.
      if (keys.contains('pg-header-heading')) {
        throw StateError('listed the Gutenberg header');
      }
      for (final chapter in chapters) {
        if (chapter.title.toUpperCase() == 'CONTENTS') {
          throw StateError('listed the table of contents');
        }
      }
      if (keys.join(' ') != 'letter1 chap01 chap02') {
        throw StateError('the chapters are $keys');
      }
      return '${chapters.length} sections, from ${chapters.first.title}';
    });
  });

  await _probe('gutenberg-a-chapter-is-a-slice-of-the-book', () async {
    return withSource((source, http) async {
      await source.getChapters('84');
      final before = http.asked.length;
      final content = await source.getChapterContent(
        const ChapterRef(bookKey: '84', chapterKey: 'chap01'),
      );
      // A book is one file, so a chapter of the book already in hand must not fetch it again.
      if (http.asked.length != before) {
        throw StateError(
          'a chapter cost ${http.asked.length - before} requests',
        );
      }
      final heading = content.blocks.whereType<HeadingBlock>().firstOrNull;
      final text = [
        for (final run in heading?.runs ?? const <TextRun>[]) run.text,
      ].join();
      if (text != 'Chapter 1') throw StateError('the heading is "$text"');
      if (content.blocks.whereType<ParagraphBlock>().isEmpty) {
        throw StateError('no prose under the heading');
      }
      return 'one file, ${content.blocks.length} blocks under "$text"';
    });
  });
}

Future<void> _runPodcastProbes() async {
  // The manifest names sixty-three hosts. These are the ones the fixtures actually reach, plus the
  // CloudFront wildcard the audio needs: a probe is not the place to restate a list the app's own
  // test already holds against the manifest, and a shorter one makes it obvious which host each
  // probe below depends on.
  const domains = [
    'anchor.fm',
    '*.anchor.fm',
    '*.cloudfront.net',
    'itunes.apple.com',
    '*.mzstatic.com',
    'open.spotify.com',
  ];

  Future<T> withSource<T>(
    Future<T> Function(JsSourceAdapter source, _PodcastFixtures http) body,
  ) async {
    final http = await _PodcastFixtures.load();
    return _withExtension(
      asset: 'assets/podcasts/main.js',
      extensionId: 'org.kikuyomi.podcasts',
      sourceKey: 'podcasts',
      domains: domains,
      http: http,
      body: (source) => body(source, http),
    );
  }

  await _probe('podcasts-loads', () async {
    return withSource((source, http) async {
      if (source.capabilities.isNotEmpty) {
        throw StateError('capabilities are ${source.capabilities}');
      }
      return 'loaded, declaring nothing optional';
    });
  });

  await _probe('podcasts-recommends-before-anything-is-added', () async {
    return withSource((source, http) async {
      // The screen a listener sees the first time they open this source. It used to be blank,
      // because the shelf is the shows you have opened and you have opened none: a source whose
      // front page is empty looks broken, however correct it is.
      final page = await source.getPopular(1);
      if (page.items.isEmpty) {
        throw StateError('nothing to recommend on a first run');
      }
      if (!page.hasNextPage) {
        throw StateError('there are more charts after the first');
      }
      // The chart, then one batch lookup turning the whole page of ids into feeds. Thirty lookups
      // would be thirty requests for one screen.
      if (http.asked.length != 2) {
        throw StateError('a page of recommendations cost ${http.asked}');
      }
      return 'recommended ${page.items.length}: ${page.items.first.title}';
    });
  });

  await _probe('podcasts-a-chart-keeps-its-own-order', () async {
    return withSource((source, http) async {
      // The order is the recommendation. The lookup answers in an order of its own -- the fixture
      // reverses it on purpose -- so handing back what the lookup said would look fine and be
      // backwards.
      final page = await source.getPopular(1);
      final titles = [for (final item in page.items) item.title];
      final expected = _PodcastFixtures.chartOrder.sublist(
        0,
        _PodcastFixtures.chartOrder.length - 1,
      );
      if (titles.join('|') != expected.join('|')) {
        throw StateError('got $titles, wanted $expected');
      }
      return 'the chart order survived the lookup';
    });
  });

  await _probe('podcasts-a-chart-entry-with-no-feed-is-dropped', () async {
    return withSource((source, http) async {
      // A show Apple charts but does not distribute as a podcast has no feed to open. Offering it
      // would be offering something that fails the moment it is tapped.
      final page = await source.getPopular(1);
      final titles = [for (final item in page.items) item.title];
      if (titles.contains(_PodcastFixtures.chartOrder.last)) {
        throw StateError('offered a show with no feed: $titles');
      }
      if (titles.length != _PodcastFixtures.chartOrder.length - 1) {
        throw StateError('expected one fewer than the chart, got $titles');
      }
      return 'dropped the one that cannot be opened';
    });
  });

  await _probe('podcasts-browsing-runs-out-of-charts', () async {
    return withSource((source, http) async {
      // Paging has to stop somewhere, and an infinite list of the same chart is worse than a short
      // honest one.
      var page = 1;
      while (page < 20) {
        final result = await source.getPopular(page);
        if (!result.hasNextPage) break;
        page += 1;
      }
      if (page >= 20) throw StateError('browsing never ended');
      final past = await source.getPopular(page + 1);
      if (past.items.isNotEmpty) {
        throw StateError('there is a page past the last one');
      }
      return 'ends after $page pages';
    });
  });

  await _probe('podcasts-a-feed-address-is-a-search', () async {
    return withSource((source, http) async {
      final page = await source.search(
        const SearchQuery(text: _PodcastFixtures.feedUrl),
        1,
      );
      if (page.items.length != 1) {
        throw StateError('found ${page.items.map((b) => b.title)}');
      }
      if (page.items.single.key != _PodcastFixtures.feedUrl) {
        throw StateError('the key is not the feed: ${page.items.single.key}');
      }
      if (page.hasNextPage) throw StateError('one address is one answer');
      if (http.asked.length != 1) {
        throw StateError('reading one feed cost ${http.asked.length}');
      }
      return 'pasted an address, got ${page.items.single.title}';
    });
  });

  await _probe('podcasts-search-by-name-uses-the-index', () async {
    return withSource((source, http) async {
      final page = await source.search(
        const SearchQuery(text: 'web novel audio'),
        1,
      );
      if (page.items.isEmpty) throw StateError('the index found nothing');
      // Found without reading a single feed: the whole point of searching an index rather than
      // fetching everything and looking through it.
      if (http.asked.any((url) => url == _PodcastFixtures.feedUrl)) {
        throw StateError('searching fetched a feed: ${http.asked}');
      }
      final found = page.items.first;
      if (!found.key.startsWith('https://')) {
        throw StateError('the key is not a feed address: ${found.key}');
      }
      return 'the index answered with ${found.title}';
    });
  });

  await _probe('podcasts-an-apple-link-is-looked-up-by-id', () async {
    return withSource((source, http) async {
      final page = await source.search(
        const SearchQuery(
          text: 'https://podcasts.apple.com/us/podcast/web-novel-audio/id1772845594',
        ),
        1,
      );
      if (page.items.length != 1) {
        throw StateError('found ${page.items.length}');
      }
      final asked = http.asked.single;
      if (!asked.contains('lookup') || !asked.contains('1772845594')) {
        throw StateError('asked $asked, which is not a lookup by id');
      }
      return 'looked up exactly: ${page.items.single.title}';
    });
  });

  await _probe('podcasts-a-spotify-link-finds-the-feed', () async {
    return withSource((source, http) async {
      // Spotify publishes no feed address, so this is two steps: read the show's name off the
      // public page, then find that name in a podcast index. Nothing here touches Spotify's audio,
      // which is encrypted and not ours to decode.
      final page = await source.search(
        const SearchQuery(
          text: 'https://open.spotify.com/show/7sRS4Y7wK8gS4Emp7qXskL',
        ),
        1,
      );
      if (page.items.isEmpty) throw StateError('nothing came back');
      if (http.asked.length != 2) {
        throw StateError('expected a page then an index, got ${http.asked}');
      }
      if (!http.asked.first.startsWith('https://open.spotify.com/')) {
        throw StateError('did not read the page first: ${http.asked}');
      }
      if (!http.asked.last.contains('itunes.apple.com/search')) {
        throw StateError('did not search the index: ${http.asked}');
      }
      return 'a Spotify link became a feed: ${page.items.first.key}';
    });
  });

  await _probe('podcasts-book-details', () async {
    return withSource((source, http) async {
      final book = await source.getBookDetails(_PodcastFixtures.feedUrl);
      if (book.narrators.isNotEmpty) {
        throw StateError('narrators are ${book.narrators}');
      }
      if (book.genres.isEmpty) {
        throw StateError('the feed names categories; genres are empty');
      }
      final description = book.description ?? '';
      if (description.contains('<') || description.contains('CDATA')) {
        throw StateError('the summary still holds markup: $description');
      }
      if (book.status != BookStatus.ongoing) {
        throw StateError(
          'a podcast without itunes:complete is ongoing, '
          'not ${book.status}',
        );
      }
      // The feed's <link> points at Patreon, which this extension never declared, and a URL it may
      // not reach would fail the whole call if it were handed over.
      if (book.webUrl != null) {
        throw StateError('handed over an unreachable page: ${book.webUrl}');
      }
      return 'decoded, and the off-limits link was dropped';
    });
  });

  await _probe('podcasts-chapters-run-oldest-first', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters(_PodcastFixtures.feedUrl);
      if (chapters.length != 4) {
        throw StateError(
          'expected the fixture\'s four, got ${chapters.length}',
        );
      }
      // A feed is written newest first and a serial is listened to from the start, so this is the
      // one transformation this source makes that a listener would notice immediately if it broke.
      var previous = 0;
      for (final chapter in chapters) {
        final at = chapter.publishedAt?.millisecondsSinceEpoch ?? 0;
        if (at == 0) throw StateError('${chapter.title} has no date');
        if (at < previous) {
          throw StateError('${chapter.title} is out of order');
        }
        previous = at;
      }
      return 'four chapters, oldest first: ${chapters.first.title}';
    });
  });

  await _probe('podcasts-resolve-media', () async {
    return withSource((source, http) async {
      final chapters = await source.getChapters(_PodcastFixtures.feedUrl);
      final media = await source.resolveMedia(
        ChapterRef(
          bookKey: _PodcastFixtures.feedUrl,
          chapterKey: chapters.first.key,
        ),
        const ResolveContext(
          purpose: ResolvePurpose.stream,
          network: NetworkType.unknown,
        ),
      );
      final segment = media.segments.single;
      if (segment.format != MediaFormat.mp3) {
        throw StateError('format is ${segment.format}');
      }
      if (segment.request.url.host != 'anchor.fm') {
        throw StateError('url is ${segment.request.url}');
      }
      return 'playable: ${segment.request.url.host}';
    });
  });

  await _probe('podcasts-the-feed-is-read-once', () async {
    return withSource((source, http) async {
      // Opening a show, reading its chapters and resolving one is the ordinary path, and a four
      // hundred episode feed is not a document to fetch three times for one tap.
      await source.getBookDetails(_PodcastFixtures.feedUrl);
      final chapters = await source.getChapters(_PodcastFixtures.feedUrl);
      await source.resolveMedia(
        ChapterRef(
          bookKey: _PodcastFixtures.feedUrl,
          chapterKey: chapters.first.key,
        ),
        const ResolveContext(
          purpose: ResolvePurpose.stream,
          network: NetworkType.unknown,
        ),
      );
      final feeds = http.asked.where((url) => url == _PodcastFixtures.feedUrl);
      if (feeds.length != 1) {
        throw StateError('the feed was fetched ${feeds.length} times');
      }
      return 'three calls, one fetch';
    });
  });

  await _probe('podcasts-opening-a-show-puts-it-first', () async {
    return withSource((source, http) async {
      final before = await source.getPopular(1);
      if (before.items.any((b) => b.key == _PodcastFixtures.feedUrl)) {
        throw StateError('the show was already there');
      }

      await source.getBookDetails(_PodcastFixtures.feedUrl);
      final after = await source.getPopular(1);

      // First, above the recommendations. What you already follow is what you came for.
      if (after.items.first.key != _PodcastFixtures.feedUrl) {
        throw StateError('page one starts with ${after.items.first.key}');
      }
      if (after.items.length != before.items.length + 1) {
        throw StateError(
          'the page went from ${before.items.length} to ${after.items.length}',
        );
      }
      final keys = [for (final item in after.items) item.key];
      if (keys.toSet().length != keys.length) {
        throw StateError('a show is listed twice');
      }
      return 'kept, and shown first: ${after.items.first.title}';
    });
  });

  await _probe('podcasts-refuses-a-feed-it-may-not-fetch', () async {
    return withSource((source, http) async {
      // The extension checks the host itself, before the bridge does, so that the message names
      // the host rather than the extension. A listener who pastes a feed from somewhere unusual
      // needs to be told which host to ask for.
      try {
        await source.getBookDetails('https://example.org/feed.xml');
      } on Object catch (error) {
        final text = '$error';
        if (!text.contains('example.org')) {
          throw StateError('refused without naming the host: $text');
        }
        if (http.asked.isNotEmpty) {
          throw StateError('it tried anyway: ${http.asked}');
        }
        return 'refused before asking, naming example.org';
      }
      throw StateError('a feed on an undeclared host was accepted');
    });
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _emit('QJS_PROBE INFO probe=spike-a-qjs-probe');
  _emit('QJS_PROBE INFO os=${Platform.operatingSystem}');
  _emit(
    'QJS_PROBE INFO os-version=${_oneLine(Platform.operatingSystemVersion)}',
  );
  _emit('QJS_PROBE INFO cpus=${Platform.numberOfProcessors}');
  _emit('QJS_PROBE INFO dart=${_oneLine(Platform.version, 60)}');
  final clock = _cClock;
  _emit(
    clock == null
        ? 'QJS_PROBE INFO clock=unavailable'
        : 'QJS_PROBE INFO clock=${clock.library} clocks-per-sec=${clock.perSecond}',
  );

  await _runAll();
  await _runEngineProbes();
  await _runProtocolProbes();
  await _runLibriVoxProbes();
  await _runArchiveProbes();
  await _runStorynoryProbes();
  await _runStandardEbooksProbes();
  await _runGutenbergProbes();
  await _runPodcastProbes();

  _emit('QJS_PROBE DONE passed=$_passed failed=$_failed');

  if (Platform.isAndroid || Platform.isIOS) {
    // Mobile apps are not meant to exit themselves. Leave the results on screen instead, for
    // anyone running the probe by hand.
    runApp(_Results(List.of(_lines)));
    return;
  }
  await stdout.flush();
  exit(_failed == 0 ? 0 : 1);
}

class _Results extends StatelessWidget {
  const _Results(this.lines);

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      // No SafeArea: without a WidgetsApp there may be no MediaQuery to read insets from.
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
          child: Text(
            lines.join('\n'),
            style: const TextStyle(color: Color(0xFF000000), fontSize: 11),
          ),
        ),
      ),
    );
  }
}
