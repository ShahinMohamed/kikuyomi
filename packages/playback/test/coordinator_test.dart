import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_playback/kikuyomi_playback.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';

const s = 1000;

Duration sec(int n) => Duration(seconds: n);

ChapterPosition at(int chapterId, int offsetMs) =>
    ChapterPosition(chapterId: chapterId, offsetMs: offsetMs);

QueuePosition q(int item, int offsetMs) =>
    QueuePosition(itemIndex: item, offsetMs: offsetMs);

/// Two chapters, one 300 s file each.
Timeline twoFileBook() => Timeline.build(
  files: const [
    TimelineFile(id: 1, durationMs: 300 * s),
    TimelineFile(id: 2, durationMs: 300 * s),
  ],
  chapters: [
    TimelineChapter(
      id: 1,
      title: 'One',
      segments: const [TimelineSegment(fileId: 1)],
    ),
    TimelineChapter(
      id: 2,
      title: 'Two',
      segments: const [TimelineSegment(fileId: 2)],
    ),
  ],
);

/// Three chapters in one 600 s file, so every chapter boundary is inside the file.
Timeline oneFileBook() => Timeline.build(
  files: const [TimelineFile(id: 1, durationMs: 600 * s)],
  chapters: [
    TimelineChapter(
      id: 1,
      title: 'One',
      segments: const [TimelineSegment(fileId: 1, endMs: 200 * s)],
    ),
    TimelineChapter(
      id: 2,
      title: 'Two',
      segments: const [
        TimelineSegment(fileId: 1, startMs: 200 * s, endMs: 400 * s),
      ],
    ),
    TimelineChapter(
      id: 3,
      title: 'Three',
      segments: const [TimelineSegment(fileId: 1, startMs: 400 * s)],
    ),
  ],
);

/// Three chapters, one 300 s file each, with file [estimated]'s duration only an estimate.
Timeline estimatedBook({int estimated = 1, bool estimate = true}) =>
    Timeline.build(
      files: [
        for (final id in [1, 2, 3])
          TimelineFile(
            id: id,
            durationMs: 300 * s,
            durationIsEstimate: estimate && id == estimated,
          ),
      ],
      chapters: [
        for (final (id, title) in [(1, 'One'), (2, 'Two'), (3, 'Three')])
          TimelineChapter(
            id: id,
            title: title,
            segments: [TimelineSegment(fileId: id)],
          ),
      ],
    );

/// One chapter to each of [seconds], in a file of its own, with ids and file ids counting from 1.
Timeline chaptersOf(List<int> seconds) => Timeline.build(
  files: [
    for (final (index, length) in seconds.indexed)
      TimelineFile(id: index + 1, durationMs: length * s),
  ],
  chapters: [
    for (final index in Iterable<int>.generate(seconds.length))
      TimelineChapter(
        id: index + 1,
        title: 'Chapter ${index + 1}',
        segments: [TimelineSegment(fileId: index + 1)],
      ),
  ],
);

/// A single hour-long file, the book's one chapter, whose three embedded markers of 20 minutes stand
/// in for chapters (§4.5).
Timeline markedBook() => Timeline.build(
  files: const [TimelineFile(id: 1, durationMs: 3600 * s)],
  chapters: [
    TimelineChapter(
      id: 1,
      title: 'The Book',
      segments: const [TimelineSegment(fileId: 1)],
    ),
  ],
  markersByFile: const {
    1: [
      TimelineMarker(title: 'One', startMs: 0),
      TimelineMarker(title: 'Two', startMs: 1200 * s),
      TimelineMarker(title: 'Three', startMs: 2400 * s),
    ],
  },
);

void main() {
  late FakeClock clock;
  late FakeEngine engine;
  late FakeResolver resolver;
  late FakeStore store;
  late PlaybackCoordinator coordinator;

  setUp(() {
    clock = FakeClock();
    engine = FakeEngine();
    resolver = FakeResolver();
    store = FakeStore();
    coordinator = PlaybackCoordinator(
      engine: engine,
      resolver: resolver,
      store: store,
      clock: clock,
    );
  });

  tearDown(() => coordinator.close());

  Future<void> openBook({
    int bookId = 1,
    Timeline? timeline,
    ChapterPosition? resumeFrom,
    Duration pausedFor = Duration.zero,
    bool finished = false,
  }) => coordinator.open(
    PlaybackRequest(
      bookId: bookId,
      timeline: timeline ?? twoFileBook(),
      resumeFrom: resumeFrom,
      pausedFor: pausedFor,
      finished: finished,
    ),
  );

  /// Every progress save so far, as its chapter, offset and whether it recorded the chapter
  /// listened.
  List<(int, int, bool)> saved() => [
    for (final p in store.progress)
      (p.position.chapterId, p.position.offsetMs, p.listened),
  ];

  /// Emits an engine event and lets the coordinator's queue drain.
  Future<void> emit(EngineEvent event) async {
    engine.emit(event);
    await pumpEventQueue();
  }

  PlayerReady ready() {
    expect(coordinator.state, isA<PlayerReady>());
    return coordinator.state as PlayerReady;
  }

  group('opening a book', () {
    test('a book that will not load leaves the next one openable', () async {
      // The engine is left holding a source it could not open, and the next book a listener reaches
      // for is often a local one that has nothing to do with the one that failed. One unplayable book
      // must not cost them the rest of the library until the app is restarted.
      engine.nextLoadFailure = StateError('the player could not open it');

      await openBook(bookId: 7);

      expect(coordinator.state, isA<PlayerFailed>());
      expect((coordinator.state as PlayerFailed).bookId, 7);

      await openBook(bookId: 8, timeline: oneFileBook());

      expect(coordinator.state, isA<PlayerReady>());
      expect(
        engine.loaded,
        hasLength(1),
        reason: 'the second book, not the one that failed, is what is loaded',
      );
      await coordinator.play();
      expect(engine.playing, isTrue);
    });

    test(
      'resolves every file and loads at the start, without playing',
      () async {
        await openBook();
        expect(engine.loaded.map((e) => e.media?.uri.path), [
          '/books/1.m4a',
          '/books/2.m4a',
        ]);
        expect(engine.loadedAt, q(0, 0));
        expect(engine.calls, isNot(contains('play')));
        expect(ready().position, at(1, 0));
        expect(store.progress, isEmpty, reason: 'loading is not listening');
      },
    );

    test(
      'resumes a saved position with smart rewind applied, via load',
      () async {
        // Loading at the position rather than seeking to it is spike (b)'s rule: a combined seek
        // into another item drops the offset.
        await openBook(
          resumeFrom: at(2, 60 * s),
          pausedFor: const Duration(hours: 3),
        );
        expect(engine.loadedAt, q(1, 30 * s));
        expect(engine.calls, isNot(contains('seek')));
      },
    );

    test('reports a file that cannot be resolved', () async {
      resolver.failing.add(1);
      await openBook();
      expect(coordinator.state, isA<PlayerFailed>());
    });

    test(
      'a streamed book resolves the file it starts on, and no other',
      () async {
        // SourceAPI 1.0's "before a chapter is resolved": the layout is known, the URLs are not,
        // and fetching them all before the engine is loaded is a call to the source per chapter
        // before a note is heard. Only the file being played is resolved; the rest are handed over
        // as they are, for the engine to ask about when it opens them.
        resolver.streamed.addAll({1, 2});

        await openBook(resumeFrom: at(2, 0));

        expect(resolver.requests.first.fileId, 2);
        expect(engine.loaded.map((e) => e.media?.uri.path), [
          null,
          '/books/2.m4a',
        ]);
        expect(coordinator.state, isA<PlayerReady>());
      },
    );

    test('a streamed book resolves the rest in the background', () async {
      resolver.streamed.addAll({1, 2});

      await openBook();
      await pumpEventQueue();

      expect(resolver.requests.map((r) => r.fileId), [1, 2]);
    });

    test(
      'a file it does not start on failing does not stop it opening',
      () async {
        resolver.streamed.addAll({1, 2});
        resolver.failing.add(2);

        await openBook();
        await pumpEventQueue();

        expect(coordinator.state, isA<PlayerReady>());
      },
    );

    test('a local book still has every file resolved up front', () async {
      // Nothing about local playback changes: every file is on the device, so every file is in
      // hand, and the engine is handed a queue with nothing left to work out.
      await openBook();

      expect(engine.loaded.map((e) => e.media?.uri.path), [
        '/books/1.m4a',
        '/books/2.m4a',
      ]);
    });

    test('opening another book saves the first before leaving it', () async {
      await openBook(bookId: 1);
      await coordinator.play();
      clock.advance(sec(10));
      await emit(EnginePositionChanged(q(0, 10 * s)));

      await openBook(bookId: 2);

      expect(
        engine.calls.lastIndexOf('pause'),
        lessThan(engine.calls.lastIndexOf('load')),
      );
      expect(store.sessions.single.bookId, 1);
      expect(store.progress.last.bookId, 1);
      expect(ready().bookId, 2);
    });
  });

  group('playing and progress', () {
    test(
      'play and pause drive the engine and save progress and listening',
      () async {
        await openBook();
        await coordinator.play();
        expect(ready().playing, isTrue);

        clock.advance(sec(10));
        await emit(EnginePositionChanged(q(0, 10 * s)));
        await coordinator.pause();

        expect(engine.playing, isFalse);
        expect(ready().playing, isFalse);
        expect(store.progress.last.position, at(1, 10 * s));
        expect(store.sessions.single.listened, sec(10));
      },
    );

    test('progress writes are throttled during playback', () async {
      await openBook();
      await coordinator.play();
      for (var i = 1; i <= 12; i++) {
        clock.advance(sec(1));
        await emit(EnginePositionChanged(q(0, i * s)));
      }
      expect(
        [for (final p in store.progress) p.position.offsetMs],
        [1 * s, 6 * s, 11 * s],
      );
    });

    test(
      'the global position is saved alongside the chapter position',
      () async {
        await openBook();
        await coordinator.play();
        await emit(EnginePositionChanged(q(1, 5 * s)));
        expect(store.progress.last.position, at(2, 5 * s));
        expect(store.progress.last.globalMs, 305 * s);
      },
    );
  });

  group('completion (spike b)', () {
    test(
      'saves the end of the book and ignores the zero reported afterwards',
      () async {
        await openBook();
        await coordinator.play();
        await emit(EnginePositionChanged(q(1, 299 * s)));
        await emit(const EngineCompleted());
        await emit(EnginePositionChanged(q(0, 0)));

        expect(store.progress.last.position, at(2, 300 * s));
        final state = ready();
        expect(state.finished, isTrue);
        expect(state.playing, isFalse);
        expect(
          state.globalMs,
          600 * s,
          reason: 'the displayed position must not reset',
        );
      },
    );

    test('playing a finished book starts it again', () async {
      await openBook();
      await coordinator.play();
      await emit(const EngineCompleted());
      await coordinator.play();
      expect(engine.lastSeek, q(0, 0));
      expect(ready().finished, isFalse);
    });
  });

  group('listened state (§4.5)', () {
    test('a chapter is recorded listened once progress is saved at its threshold, and not before', () async {
      // Each chapter lasts 300 s, so 30 seconds is the larger: listened from 270 s.
      await openBook();
      await coordinator.seekTo(270 * s - 1);
      await coordinator.seekTo(270 * s);
      expect(saved(), [(1, 270 * s - 1, false), (1, 270 * s, true)]);
    });

    test('a long chapter is listened 3 percent short of its end', () async {
      // 20 minutes: 3 percent is 36 seconds, more than 30, so listened from 1164 s.
      await openBook(timeline: chaptersOf([1200, 300]));
      await coordinator.seekTo(1164 * s - 1);
      await coordinator.seekTo(1164 * s);
      expect(saved(), [(1, 1164 * s - 1, false), (1, 1164 * s, true)]);
    });

    test('a chapter of 30 seconds or less is listened as soon as progress is saved in it', () async {
      await openBook(timeline: chaptersOf([300, 20, 300]));
      await coordinator.seekTo(100 * s);
      await coordinator.nextChapter();
      expect(saved().last, (2, 0, true));
    });

    test('playback records a chapter as it reaches the threshold', () async {
      await openBook();
      await coordinator.play();
      await emit(EnginePositionChanged(q(0, 265 * s)));
      clock.advance(sec(5));
      await emit(EnginePositionChanged(q(0, 270 * s)));
      expect(saved(), [(1, 265 * s, false), (1, 270 * s, true)]);
    });

    test('a seek past chapters records none of them', () async {
      await openBook(timeline: chaptersOf([300, 300, 300]));
      await coordinator.play();
      await emit(EnginePositionChanged(q(0, 10 * s)));
      await coordinator.seekTo(610 * s);
      await coordinator.skip(sec(-300));
      expect(saved(), [
        (1, 10 * s, false),
        (3, 10 * s, false),
        (2, 10 * s, false),
      ]);
    });

    test(
      'moving on from a chapter short of its threshold does not record it',
      () async {
        await openBook();
        await coordinator.seekTo(250 * s);
        await coordinator.nextChapter();
        await coordinator.skip(sec(60));
        expect(saved(), [
          (1, 250 * s, false),
          (2, 0, false),
          (2, 60 * s, false),
        ]);
      },
    );

    test("in a single file with markers, the file's one chapter is recorded, never a marker", () async {
      await openBook(timeline: markedBook());
      // The end of the first marker, past what would be its own threshold.
      await coordinator.seekTo(1199 * s);
      await coordinator.nextChapter();
      expect(saved(), [(1, 1199 * s, false), (1, 1200 * s, false)]);

      // An hour less 3 percent is 58:12, or 3492 s.
      await coordinator.seekTo(3492 * s);
      expect(saved().last, (1, 3492 * s, true));
      expect(ready().finished, isTrue);
    });

    group('the book is finished', () {
      test('once its last chapter is recorded listened', () async {
        await openBook();
        await coordinator.seekTo(569 * s);
        expect(ready().finished, isFalse);
        await coordinator.seekTo(570 * s);
        expect(ready().finished, isTrue);
        expect(ready().playing, isFalse);
      });

      test('not when an earlier chapter is', () async {
        await openBook();
        await coordinator.seekTo(299 * s);
        expect(saved().last.$3, isTrue);
        expect(ready().finished, isFalse);
      });

      test('when it plays to its end', () async {
        await openBook();
        await coordinator.play();
        await emit(const EngineCompleted());
        expect(saved().last, (2, 300 * s, true));
        expect(ready().finished, isTrue);
      });

      test('when it is stored so and opened', () async {
        await openBook(finished: true, resumeFrom: at(2, 300 * s));
        expect(ready().finished, isTrue);
      });

      test('and stays so as the listener moves back through it', () async {
        await openBook(finished: true, resumeFrom: at(2, 300 * s));
        await coordinator.seekTo(10 * s);
        await coordinator.play();
        await emit(EnginePositionChanged(q(0, 11 * s)));
        expect(ready().finished, isTrue);
        expect(store.listened, isEmpty);
      });
    });

    group('starting a finished book again', () {
      test(
        'records its last chapter not listened, after moving to the beginning',
        () async {
          await openBook();
          await coordinator.play();
          await emit(const EngineCompleted());
          store.writes.clear();

          await coordinator.play();

          expect(engine.lastSeek, q(0, 0));
          expect(store.listened, [(bookId: 1, chapterId: 2, listened: false)]);
          expect(store.writes, ['saveProgress', 'saveChapterListened']);
          expect(store.progress.last.position, at(1, 0));
          expect(ready().finished, isFalse);
        },
      );

      test('is what Play again does for a book opened finished', () async {
        await openBook(finished: true, resumeFrom: at(2, 300 * s));
        await coordinator.startAgain();
        expect(engine.lastSeek, q(0, 0));
        expect(store.listened, [(bookId: 1, chapterId: 2, listened: false)]);
        expect(ready().finished, isFalse);
        expect(ready().position, at(1, 0));
      });

      test('leaves an unfinished book as it is', () async {
        await openBook(resumeFrom: at(2, 100 * s));
        await coordinator.startAgain();
        expect(engine.lastSeek, q(0, 0));
        expect(store.listened, isEmpty);
        expect(ready().finished, isFalse);
      });
    });

    group('marked by hand elsewhere', () {
      test('the last chapter marked listened finishes the open book', () async {
        await openBook();
        await coordinator.onListenedChanged(
          bookId: 1,
          chapterIds: {1, 2},
          listened: true,
        );
        expect(ready().finished, isTrue);
        expect(store.progress, isEmpty, reason: 'it is already stored');
        expect(store.listened, isEmpty);
      });

      test('marked not listened, the book is no longer finished', () async {
        await openBook(finished: true);
        await coordinator.onListenedChanged(
          bookId: 1,
          chapterIds: {2},
          listened: false,
        );
        expect(ready().finished, isFalse);
      });

      test('another chapter, or another book, changes nothing', () async {
        await openBook(finished: true);
        await coordinator.onListenedChanged(
          bookId: 1,
          chapterIds: {1},
          listened: false,
        );
        await coordinator.onListenedChanged(
          bookId: 2,
          chapterIds: {2},
          listened: false,
        );
        expect(ready().finished, isTrue);
      });
    });
  });

  group('navigation', () {
    test('seeking saves the destination immediately', () async {
      await openBook();
      await coordinator.seekTo(400 * s);
      expect(engine.lastSeek, q(1, 100 * s));
      expect(store.progress.last.position, at(2, 100 * s));
    });

    test('skipping back is clamped to the start of the book', () async {
      await openBook();
      await coordinator.seekTo(10 * s);
      await coordinator.skip(sec(-30));
      expect(engine.lastSeek, q(0, 0));
    });

    test('next chapter moves to the start of the next one', () async {
      await openBook();
      await coordinator.seekTo(100 * s);
      await coordinator.nextChapter();
      expect(engine.lastSeek, q(1, 0));
    });

    test('next chapter in the last chapter does nothing', () async {
      await openBook();
      await coordinator.seekTo(400 * s);
      engine.calls.clear();
      await coordinator.nextChapter();
      expect(engine.calls, isEmpty);
    });

    group('going to a chapter a listener picked', () {
      // The book's details screen lists chapters and a tap on one starts there. It gives an
      // identity, not a position: only the Timeline knows what millisecond a chapter begins at, and
      // it is the Timeline that has just been rebuilt if the book's layout changed.
      test('moves to the start of that chapter', () async {
        await openBook();

        await coordinator.goToChapter(2);

        expect(engine.lastSeek, q(1, 0));
      });

      test('works where a chapter starts inside a file', () async {
        // The case a caller computing its own offset gets wrong: three chapters in one file, so the
        // engine stays on item 0 and only the offset moves.
        await openBook(timeline: oneFileBook());

        await coordinator.goToChapter(3);

        expect(engine.lastSeek, q(0, 400 * s));
      });

      test('going to the chapter already playing restarts it', () async {
        await openBook();
        await coordinator.seekTo(100 * s);

        await coordinator.goToChapter(1);

        expect(engine.lastSeek, q(0, 0));
      });

      test('a chapter this book does not have does nothing', () async {
        // §4.4 keeps a chapter whose files could not be laid out, so a details screen can list one
        // the Timeline has never heard of. A tap on it must not land somewhere arbitrary.
        await openBook();
        await coordinator.seekTo(100 * s);
        engine.calls.clear();

        await coordinator.goToChapter(99);

        expect(engine.calls, isEmpty);
      });

      test('with no book open it does nothing', () async {
        await coordinator.goToChapter(1);

        expect(engine.calls, isEmpty);
      });

      test('the destination is saved at once', () async {
        // Like every other seek: a listener who picks a chapter and closes the app has picked it.
        await openBook();

        await coordinator.goToChapter(2);

        expect(store.progress.last.position, at(2, 0));
      });
    });

    test('previous chapter well into a chapter restarts it', () async {
      await openBook();
      await coordinator.seekTo(310 * s);
      await coordinator.previousChapter();
      expect(engine.lastSeek, q(1, 0));
    });

    test(
      'previous chapter near the start goes to the previous chapter',
      () async {
        await openBook();
        await coordinator.seekTo(302 * s);
        await coordinator.previousChapter();
        expect(engine.lastSeek, q(0, 0));
      },
    );

    group('a seek that lands just short of its destination', () {
      // The Windows backend settles a seek to 9000 ms at 8999 ms. With chapters inside one file,
      // that position belongs to the previous chapter.
      const short = 1;

      test('still shows the destination and its chapter', () async {
        await openBook(timeline: oneFileBook());
        await coordinator.nextChapter();
        await emit(EnginePositionChanged(q(0, 200 * s - short)));
        expect(ready().globalMs, 200 * s);
        expect(ready().entry.title, 'Two');
      });

      test('lets next chapter move on instead of repeating itself', () async {
        await openBook(timeline: oneFileBook());
        await coordinator.nextChapter();
        await emit(EnginePositionChanged(q(0, 200 * s - short)));
        await coordinator.nextChapter();
        expect(engine.lastSeek, q(0, 400 * s));
      });

      test('saves no progress at the end of the previous chapter', () async {
        await openBook(timeline: oneFileBook());
        await coordinator.play();
        await coordinator.nextChapter();
        await emit(EnginePositionChanged(q(0, 200 * s - short)));
        expect(store.progress.last.position, at(2, 0));
      });

      test('applies to a book resumed at a chapter start as well', () async {
        await openBook(timeline: oneFileBook(), resumeFrom: at(3, 0));
        await emit(EnginePositionChanged(q(0, 400 * s - short)));
        expect(ready().entry.title, 'Three');
      });

      test('but a position well short of it is taken as reported', () async {
        await openBook(timeline: oneFileBook());
        await coordinator.seekTo(400 * s);
        await emit(EnginePositionChanged(q(0, 390 * s)));
        expect(ready().globalMs, 390 * s);
      });
    });
  });

  group('learning a duration (§4.5)', () {
    EngineItemDurationKnown known(int item, int durationMs) =>
        EngineItemDurationKnown(itemIndex: item, durationMs: durationMs);

    test('an estimate refined mid-book keeps the chapter position and moves global positions', () async {
      await openBook(timeline: estimatedBook(), resumeFrom: at(3, 60 * s));
      expect(ready().globalMs, 660 * s);
      engine.calls.clear();

      await emit(known(0, 312 * s));

      final state = ready();
      expect(state.position, at(3, 60 * s));
      expect(state.globalMs, 672 * s);
      expect(state.totalMs, 912 * s);
      expect(state.entry.startMs, 612 * s);
      expect(
        [for (final entry in state.navigation) entry.startMs],
        [0, 312 * s, 612 * s],
        reason: 'the chapter list moves with the refined file',
      );
      expect(engine.calls, isEmpty, reason: 'nothing needs reloading');

      await coordinator.play();
      await emit(EnginePositionChanged(q(2, 65 * s)));
      expect(store.progress.last.position, at(3, 65 * s));
      expect(store.progress.last.globalMs, 677 * s);
    });

    test('the store receives the learned duration', () async {
      await openBook(timeline: estimatedBook());
      await emit(known(0, 312 * s));
      expect(store.durations.single, (
        bookId: 1,
        fileId: 1,
        durationMs: 312 * s,
      ));
    });

    test('a file longer than its estimate is no longer cut short', () async {
      // Before the refinement, 320 s into a file estimated at 300 s reads as the next chapter.
      await openBook(timeline: estimatedBook());
      await coordinator.play();
      await emit(known(0, 330 * s));
      await emit(EnginePositionChanged(q(0, 320 * s)));
      expect(ready().position, at(1, 320 * s));
      expect(store.progress.last.position, at(1, 320 * s));
    });

    test('an exact duration is left alone', () async {
      await openBook(timeline: estimatedBook(estimate: false));
      await emit(known(0, 312 * s));
      expect(ready().totalMs, 900 * s);
      expect(store.durations, isEmpty);
    });

    test('a difference below the threshold is ignored', () async {
      await openBook(timeline: estimatedBook());
      await emit(known(0, 300 * s + 400));
      expect(ready().totalMs, 900 * s);
      expect(store.durations, isEmpty);
    });

    test('a clipped item says nothing about its file', () async {
      final timeline = Timeline.build(
        files: const [
          TimelineFile(id: 1, durationMs: 600 * s, durationIsEstimate: true),
          TimelineFile(id: 2, durationMs: 300 * s),
        ],
        chapters: [
          TimelineChapter(
            id: 1,
            title: 'One',
            segments: const [TimelineSegment(fileId: 1, endMs: 200 * s)],
          ),
          TimelineChapter(
            id: 2,
            title: 'Two',
            segments: const [TimelineSegment(fileId: 2)],
          ),
          TimelineChapter(
            id: 3,
            title: 'Three',
            segments: const [TimelineSegment(fileId: 1, startMs: 400 * s)],
          ),
        ],
      );
      await openBook(timeline: timeline);
      await emit(known(0, 250 * s));
      await emit(known(2, 250 * s));
      expect(ready().totalMs, 700 * s);
      expect(store.durations, isEmpty);
    });

    test('a duration the layout cannot fit is ignored', () async {
      // Chapter two ends at 400 s into the file, which cannot hold that if it lasts 350 s.
      final timeline = Timeline.build(
        files: const [
          TimelineFile(id: 1, durationMs: 600 * s, durationIsEstimate: true),
        ],
        chapters: [
          TimelineChapter(
            id: 1,
            title: 'One',
            segments: const [TimelineSegment(fileId: 1, endMs: 200 * s)],
          ),
          TimelineChapter(
            id: 2,
            title: 'Two',
            segments: const [
              TimelineSegment(fileId: 1, startMs: 200 * s, endMs: 400 * s),
            ],
          ),
          TimelineChapter(
            id: 3,
            title: 'Three',
            segments: const [TimelineSegment(fileId: 1, startMs: 400 * s)],
          ),
        ],
      );
      await openBook(timeline: timeline);
      await emit(known(0, 350 * s));
      expect(ready().totalMs, 600 * s);
      expect(store.durations, isEmpty);
    });

    test(
      'a seek that lands just short of its destination still lands there',
      () async {
        final timeline = Timeline.build(
          files: const [
            TimelineFile(id: 1, durationMs: 300 * s, durationIsEstimate: true),
            TimelineFile(id: 2, durationMs: 600 * s),
          ],
          chapters: [
            TimelineChapter(
              id: 1,
              title: 'One',
              segments: const [TimelineSegment(fileId: 1)],
            ),
            TimelineChapter(
              id: 2,
              title: 'Two',
              segments: const [TimelineSegment(fileId: 2, endMs: 200 * s)],
            ),
            TimelineChapter(
              id: 3,
              title: 'Three',
              segments: const [TimelineSegment(fileId: 2, startMs: 200 * s)],
            ),
          ],
        );
        await openBook(timeline: timeline, resumeFrom: at(3, 0));
        await emit(known(0, 312 * s));
        await emit(EnginePositionChanged(q(1, 200 * s - 1)));
        expect(ready().entry.title, 'Three');
        expect(ready().globalMs, 512 * s);
      },
    );

    test('an end-of-chapter sleep timer waits for the refined end', () async {
      await openBook(timeline: estimatedBook());
      await coordinator.play();
      await emit(EnginePositionChanged(q(0, 290 * s)));
      await coordinator.startSleepTimer(const SleepAtEndOfChapter());

      await emit(known(0, 330 * s));
      await emit(EnginePositionChanged(q(0, 305 * s)));

      expect(engine.playing, isTrue);
      expect((ready().sleepTimer as SleepTimerRunning).remaining, sec(25));
    });

    test('a finished book stays at its end', () async {
      await openBook(timeline: estimatedBook(estimated: 3));
      await coordinator.play();
      await emit(const EngineCompleted());
      await emit(known(2, 330 * s));
      final state = ready();
      expect(state.finished, isTrue);
      expect(state.totalMs, 930 * s);
      expect(state.globalMs, 930 * s);
    });
  });

  group('speed', () {
    test('is applied, remembered for the book, and splits listening', () async {
      await openBook();
      await coordinator.play();
      clock.advance(sec(20));
      await emit(EnginePositionChanged(q(0, 20 * s)));
      await coordinator.setSpeed(1.5);

      expect(engine.speed, 1.5);
      expect(store.speeds.single, (bookId: 1, speed: 1.5));
      expect(store.sessions.single.speed, 1.0);
      expect(ready().speed, 1.5);
    });

    test('outside 0.5x to 3.5x is rejected', () async {
      await openBook();
      expect(coordinator.setSpeed(4.0), throwsArgumentError);
      expect(coordinator.setSpeed(0.25), throwsArgumentError);
    });
  });

  group('resuming after a pause', () {
    test('applies smart rewind for the length of the pause', () async {
      await openBook();
      await coordinator.play();
      clock.advance(sec(60));
      await emit(EnginePositionChanged(q(0, 60 * s)));
      await coordinator.pause();

      clock.advance(const Duration(minutes: 10));
      await coordinator.play();

      expect(engine.lastSeek, q(0, 50 * s));
      expect(engine.playing, isTrue);
    });

    test('does not rewind after a brief pause', () async {
      await openBook();
      await coordinator.play();
      clock.advance(sec(60));
      await emit(EnginePositionChanged(q(0, 60 * s)));
      await coordinator.pause();
      engine.calls.clear();
      clock.advance(sec(2));
      await coordinator.play();
      expect(engine.calls, isNot(contains('seek')));
    });
  });

  group('sleep timer', () {
    test('fades the volume and pauses when it runs out', () async {
      await openBook();
      await coordinator.startSleepTimer(SleepAfter(sec(60)));
      await coordinator.play();

      clock.advance(sec(50));
      await emit(EnginePositionChanged(q(0, 50 * s)));
      expect(engine.volume, 0.5);

      clock.advance(sec(10));
      await emit(EnginePositionChanged(q(0, 60 * s)));
      expect(engine.playing, isFalse);
      expect(
        engine.volume,
        1.0,
        reason: 'the volume is restored for next time',
      );
      expect(ready().playing, isFalse);
    });

    test('rewinds by the fade on the next play', () async {
      await openBook();
      await coordinator.startSleepTimer(SleepAfter(sec(60)));
      await coordinator.play();
      clock.advance(sec(60));
      await emit(EnginePositionChanged(q(0, 60 * s)));

      await coordinator.play();
      expect(engine.lastSeek, q(0, 40 * s));
    });

    test('for the end of a chapter pauses there, not at the next', () async {
      await openBook();
      await coordinator.play();
      await emit(EnginePositionChanged(q(0, 290 * s)));
      await coordinator.startSleepTimer(const SleepAtEndOfChapter());

      await emit(EnginePositionChanged(q(0, 299 * s)));
      expect(engine.playing, isTrue);

      await emit(EnginePositionChanged(q(1, 1 * s)));
      expect(engine.playing, isFalse);
      expect(ready().sleepTimer, isA<SleepTimerOff>());
    });

    test('for the end of a chapter follows the listener elsewhere', () async {
      await openBook();
      await coordinator.play();
      await emit(EnginePositionChanged(q(0, 10 * s)));
      await coordinator.startSleepTimer(const SleepAtEndOfChapter());

      await coordinator.nextChapter();
      await emit(EnginePositionChanged(q(1, 5 * s)));

      expect(engine.playing, isTrue);
      expect((ready().sleepTimer as SleepTimerRunning).remaining, sec(295));
    });

    test('is reported in the player state', () async {
      await openBook();
      await coordinator.startSleepTimer(SleepAfter(sec(90)));
      final timer = ready().sleepTimer;
      expect(timer, isA<SleepTimerRunning>());
      expect((timer as SleepTimerRunning).remaining, sec(90));
    });

    test('cancelling it restores the volume', () async {
      await openBook();
      await coordinator.startSleepTimer(SleepAfter(sec(60)));
      await coordinator.play();
      clock.advance(sec(50));
      await emit(EnginePositionChanged(q(0, 50 * s)));
      await coordinator.cancelSleepTimer();
      expect(engine.volume, 1.0);
      expect(ready().sleepTimer, isA<SleepTimerOff>());
    });
  });

  group('stream errors (§6.3)', () {
    test(
      'are recovered once by re-resolving and reloading where playback was',
      () async {
        await openBook();
        await coordinator.play();
        await emit(EnginePositionChanged(q(1, 5 * s)));
        resolver.requests.clear();
        engine.calls.clear();

        await emit(EngineFailed(StateError('403')));

        // The file that failed is asked for again, and only it: a book of a hundred chapters is
        // not resolved from end to end because one URL expired.
        expect(resolver.requests.first, (fileId: 2, refresh: true));
        expect(
          resolver.requests.where((r) => r.refresh),
          hasLength(1),
          reason: 'only what failed is re-resolved',
        );
        expect(engine.calls, ['load', 'play']);
        expect(engine.loadedAt, q(1, 5 * s));
        expect(ready().playing, isTrue);
      },
    );

    test('a second failure before any user action is surfaced', () async {
      await openBook();
      await coordinator.play();
      await emit(EngineFailed(StateError('403')));
      await emit(EngineFailed(StateError('403 again')));
      expect(coordinator.state, isA<PlayerFailed>());
    });

    test('a user action re-arms recovery', () async {
      await openBook();
      await coordinator.play();
      await emit(EngineFailed(StateError('403')));
      await coordinator.seekTo(20 * s);
      await emit(EngineFailed(StateError('403 later')));
      expect(coordinator.state, isA<PlayerReady>());
    });

    test('recovery that cannot resolve is surfaced', () async {
      await openBook();
      await coordinator.play();
      resolver.failing.add(1);
      await emit(EngineFailed(StateError('403')));
      expect(coordinator.state, isA<PlayerFailed>());
    });
  });

  group('interruptions (§6.5)', () {
    test('pause playback and save progress at once', () async {
      await openBook();
      await coordinator.play();
      await emit(EnginePositionChanged(q(0, 1 * s)));
      clock.advance(sec(2));
      await emit(EnginePositionChanged(q(0, 3 * s)));

      await coordinator.onSystemAudio(const AudioInterruptionBegan());

      expect(engine.playing, isFalse);
      expect(ready().playing, isFalse);
      expect(store.progress.last.position, at(1, 3 * s));
    });

    test('resume when they end, if the system allows it', () async {
      await openBook();
      await coordinator.play();
      await coordinator.onSystemAudio(const AudioInterruptionBegan());
      await coordinator.onSystemAudio(
        const AudioInterruptionEnded(mayResume: true),
      );
      expect(engine.playing, isTrue);
      expect(ready().playing, isTrue);
    });

    test('stay paused when the system says not to resume', () async {
      await openBook();
      await coordinator.play();
      await coordinator.onSystemAudio(const AudioInterruptionBegan());
      await coordinator.onSystemAudio(
        const AudioInterruptionEnded(mayResume: false),
      );
      expect(engine.playing, isFalse);
    });

    test('never start a book that was already paused', () async {
      await openBook();
      await coordinator.onSystemAudio(const AudioInterruptionBegan());
      await coordinator.onSystemAudio(
        const AudioInterruptionEnded(mayResume: true),
      );
      expect(engine.calls, isNot(contains('play')));
    });

    test(
      'leave the choice to the user once they press play or pause',
      () async {
        await openBook();
        await coordinator.play();
        await coordinator.onSystemAudio(const AudioInterruptionBegan());
        await coordinator.play();
        await coordinator.pause();
        await coordinator.onSystemAudio(
          const AudioInterruptionEnded(mayResume: true),
        );
        expect(engine.playing, isFalse);
      },
    );

    test('apply smart rewind when a long one ends', () async {
      await openBook();
      await coordinator.play();
      clock.advance(sec(60));
      await emit(EnginePositionChanged(q(0, 60 * s)));
      await coordinator.onSystemAudio(const AudioInterruptionBegan());

      clock.advance(const Duration(minutes: 10));
      await coordinator.onSystemAudio(
        const AudioInterruptionEnded(mayResume: true),
      );

      expect(engine.lastSeek, q(0, 50 * s));
      expect(engine.playing, isTrue);
    });

    test('losing the output pauses, and for good', () async {
      await openBook();
      await coordinator.play();
      await coordinator.onSystemAudio(const AudioInterruptionBegan());
      await coordinator.onSystemAudio(const AudioOutputLost());
      await coordinator.onSystemAudio(
        const AudioInterruptionEnded(mayResume: true),
      );
      expect(engine.playing, isFalse);
    });
  });

  test('backgrounding saves progress without pausing', () async {
    await openBook();
    await coordinator.play();
    await emit(EnginePositionChanged(q(0, 1 * s)));
    clock.advance(sec(2));
    await emit(EnginePositionChanged(q(0, 3 * s)));
    await coordinator.onBackgrounded();
    expect(store.progress.last.position, at(1, 3 * s));
    expect(engine.playing, isTrue);
  });
}
