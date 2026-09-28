import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/book_details_view.dart';
import 'package:kikuyomi/src/listened_commands.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show
        BookOverview,
        BookProgress,
        ChapterDownload,
        ChapterOverview,
        CoverFiles,
        MarkerOverview;
import 'package:kikuyomi_design_system/kikuyomi_design_system.dart';

/// A covers folder that holds nothing: the view only names a file in it.
final covers = CoverFiles(Directory('covers'));

const threeChapters = [
  ChapterOverview(
    chapterId: 10,
    title: 'Opening',
    durationMs: 600000,
    listened: true,
    current: false,
  ),
  ChapterOverview(
    chapterId: 11,
    title: 'Middle',
    durationMs: 1200000,
    listened: false,
    current: true,
  ),
  ChapterOverview(
    chapterId: 12,
    title: 'End',
    durationMs: 300000,
    listened: false,
    current: false,
  ),
];

const twoMarkers = [
  MarkerOverview(
    title: 'First marker',
    startMs: 0,
    endMs: 60000,
    listened: false,
    current: true,
  ),
  MarkerOverview(
    title: 'Second marker',
    startMs: 60000,
    endMs: 120000,
    listened: false,
    current: false,
  ),
];

BookOverview book({
  BookProgress? progress,
  bool finished = false,
  bool inLibrary = true,
  List<ChapterOverview> chapters = threeChapters,
  List<MarkerOverview> markers = const [],
  String? cover,
}) => BookOverview(
  sourceId: 2,
  bookId: 1,
  title: 'A Book',
  authors: const ['An Author', 'Second Author'],
  narrators: const ['A Narrator'],
  totalDurationMs: 2100000,
  inLibrary: inLibrary,
  chapters: chapters,
  markers: markers,
  progress: progress,
  finished: finished,
  coverFileName: cover,
);

/// Eleven minutes in: a minute into Middle.
final elevenMinutesIn = BookProgress(
  chapterId: 11,
  chapterPositionMs: 60000,
  globalPositionMs: 660000,
  lastPlayedAt: DateTime.utc(2026, 9, 14),
);

/// The details of [overview], recording what was pressed in [pressed].
///
/// Marking the book finished reports chapters 11 and 12 as the ones it marked, as it would for
/// [threeChapters], where only Opening was listened.
Widget details(
  BookOverview overview, [
  List<String>? pressed,
  Map<int, ChapterDownload> chapterDownloads = const {},
  Future<void> Function()? onRefresh,
]) => MaterialApp(
  home: Scaffold(
    body: BookDetailsView(
      book: overview,
      covers: covers,
      chapterDownloads: chapterDownloads,
      onPlayChapter: (chapterId) => pressed?.add('play $chapterId'),
      onPlayFrom: (globalMs) => pressed?.add('play at $globalMs'),
      onDownloadChapters: (chapterIds) =>
          pressed?.add('download ${chapterIds.join(', ')}'),
      onRefresh: onRefresh,
      onOpenDownloadQueue: () => pressed?.add('queue'),
      onRemove: () => pressed?.add('remove'),
      listenedCommands: ListenedCommands(
        markChapters: (chapterIds, listened) async {
          pressed?.add(
            'mark ${chapterIds.join(', ')} ${listened ? 'listened' : 'not listened'}',
          );
          return chapterIds;
        },
        markFinished: () async {
          pressed?.add('mark finished');
          return {11, 12};
        },
        markNotFinished: () async => pressed?.add('mark not finished'),
      ),
    ),
  ),
);

/// Tabs through the screen until the options button of chapter [title] has the keyboard's focus.
Future<void> tabTo(WidgetTester tester, String title) async {
  bool focused() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<PopupMenuButton<bool>>()
          ?.tooltip ==
      'Options for $title';
  for (var i = 0; i < 20 && !focused(); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(focused(), isTrue, reason: 'the options for $title take focus');
}

/// Makes the window tall enough for the list to build every chapter below the cover and buttons.
void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder iconIn(String title, IconData icon) => find.descendant(
  of: find.widgetWithText(ListTile, title),
  matching: find.byIcon(icon),
);

/// Opens the download menu, which hangs off the strip's Download cell.
Future<void> openDownloadMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Download chapters'));
  await tester.pumpAndSettle();
}

/// Holds [title] down, which is how a chapter is picked out.
Future<void> holdChapter(WidgetTester tester, String title) async {
  await tester.longPress(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  _aBookToRead();

  group('playing from a chapter', () {
    testWidgets('tapping a chapter row asks to play from it', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.text('End'));
      await tester.pump();

      expect(pressed, ['play 12']);
    });

    testWidgets('tapping the row a listener is in restarts that chapter', (
      tester,
    ) async {
      // Not a no-op: picking the chapter you are in is how a listener starts it again.
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.text('Middle'));
      await tester.pump();

      expect(pressed, ['play 11']);
    });

    testWidgets('the options menu is not a tap on the row', (tester) async {
      // They sit on the same row and do different things, so the menu must not also play.
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.byTooltip('Options for End'));
      await tester.pumpAndSettle();

      expect(pressed, isEmpty);
    });
  });

  group('a book with a great many chapters', () {
    // A podcast the Podcasts source offers has four hundred and nineteen. Built as a Column of
    // every row inside a ListView, that dropped a phone to about five frames a second whenever
    // anything on the page changed -- and a running download changes it several times a second.
    List<ChapterOverview> manyChapters(int count) => [
      for (var i = 0; i < count; i++)
        ChapterOverview(
          chapterId: 1000 + i,
          title: 'Chapter $i',
          durationMs: 600000,
          listened: false,
          current: i == 0,
        ),
    ];

    testWidgets('builds only the rows that are near the screen', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(details(book(chapters: manyChapters(400))));

      final built = tester.widgetList(find.byType(ListTile)).length;
      expect(
        built,
        lessThan(60),
        reason: 'a lazy list builds what is on screen, not four hundred rows',
      );
      expect(built, greaterThan(0), reason: 'it still builds something');
    });

    testWidgets('and still counts all of them in the heading', (tester) async {
      tallView(tester);
      await tester.pumpWidget(details(book(chapters: manyChapters(400))));

      expect(find.text('400 chapters'), findsOneWidget);
    });

    testWidgets('the ones further down are reachable by scrolling', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(details(book(chapters: manyChapters(400))));

      expect(find.text('Chapter 300'), findsNothing);
      await tester.scrollUntilVisible(find.text('Chapter 300'), 400);

      expect(find.text('Chapter 300'), findsOneWidget);
    });
  });

  group('picking chapters out', () {
    testWidgets('holding one starts a selection', (tester) async {
      tallView(tester);
      await tester.pumpWidget(details(book()));

      await holdChapter(tester, 'Middle');

      expect(find.text('1 selected'), findsOneWidget);
      // The count it replaced is gone: the heading is the bar now.
      expect(find.text('3 chapters'), findsNothing);
    });

    testWidgets('holding more adds to it', (tester) async {
      tallView(tester);
      await tester.pumpWidget(details(book()));

      await holdChapter(tester, 'Middle');
      await holdChapter(tester, 'End');

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('a tap adds instead of playing while selecting', (
      tester,
    ) async {
      // Once you are choosing, you are choosing. A stray tap must not start playback.
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await holdChapter(tester, 'Middle');
      await tester.tap(find.text('End'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);
      expect(pressed, isEmpty);
    });

    testWidgets('tapping a selected chapter takes it back out', (tester) async {
      tallView(tester);
      await tester.pumpWidget(details(book()));

      await holdChapter(tester, 'Middle');
      await holdChapter(tester, 'End');
      await tester.tap(find.text('End'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('downloading takes only what was picked, in book order', (
      tester,
    ) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      // Held out of order on purpose: what is queued follows the book, not the taps.
      await holdChapter(tester, 'End');
      await holdChapter(tester, 'Opening');
      await tester.tap(find.byTooltip('Download 2 chapters'));
      await tester.pumpAndSettle();

      expect(pressed, ['download 10, 12']);
    });

    testWidgets('and the list goes back to normal afterwards', (tester) async {
      tallView(tester);
      await tester.pumpWidget(details(book(), <String>[]));

      await holdChapter(tester, 'Middle');
      await tester.tap(find.byTooltip('Download 1 chapter'));
      await tester.pumpAndSettle();

      expect(find.text('3 chapters'), findsOneWidget);
    });

    testWidgets('select all takes every chapter', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await holdChapter(tester, 'Middle');
      await tester.tap(find.byTooltip('Select every chapter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Download 3 chapters'));
      await tester.pumpAndSettle();

      expect(pressed, ['download 10, 11, 12']);
    });

    testWidgets('stopping leaves the chapters alone', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await holdChapter(tester, 'Middle');
      await tester.tap(find.byTooltip('Stop selecting'));
      await tester.pumpAndSettle();

      expect(find.text('3 chapters'), findsOneWidget);
      expect(pressed, isEmpty);
    });
  });

  group('a single file\'s embedded markers (§4.5)', () {
    testWidgets('play from where the marker begins', (tester) async {
      // They have no chapter id -- where one begins is what identifies it. Before this, every row
      // of a single-file book did nothing at all when tapped, which looked like a broken app.
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(chapters: const [], markers: twoMarkers), pressed),
      );

      await tester.tap(find.text('Second marker'));
      await tester.pump();

      expect(pressed, ['play at 60000']);
    });

    testWidgets('are not offered for download', (tester) async {
      // One file: it is either here or it is not, and there is nothing per-marker to fetch.
      tallView(tester);
      await tester.pumpWidget(
        details(book(chapters: const [], markers: twoMarkers)),
      );

      expect(find.textContaining('Download First marker'), findsNothing);
    });

    testWidgets('cannot be picked out', (tester) async {
      tallView(tester);
      await tester.pumpWidget(
        details(book(chapters: const [], markers: twoMarkers)),
      );

      await holdChapter(tester, 'First marker');

      expect(find.textContaining('selected'), findsNothing);
    });
  });

  group('downloading one chapter', () {
    testWidgets('the arrow asks for that chapter alone', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.byTooltip('Download End'));
      await tester.pump();

      expect(pressed, ['download 12']);
    });

    testWidgets('a chapter already here offers nothing to press', (
      tester,
    ) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(), pressed, {12: ChapterDownload.here}),
      );

      expect(iconIn('End', Icons.download_done), findsOneWidget);
      await tester.tap(find.byTooltip('End is downloaded'));
      await tester.pump();
      expect(pressed, isEmpty);
    });

    testWidgets('a chapter that failed offers another try', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(), pressed, {12: ChapterDownload.failed}),
      );

      await tester.tap(find.byTooltip('End did not download. Try again'));
      await tester.pump();

      expect(pressed, ['download 12']);
    });

    testWidgets('a chapter waiting says so rather than inviting a second ask', (
      tester,
    ) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(), pressed, {12: ChapterDownload.queued}),
      );

      expect(iconIn('End', Icons.hourglass_empty), findsOneWidget);
      await tester.tap(find.byTooltip('End is waiting to download'));
      await tester.pump();
      expect(pressed, isEmpty);
    });
  });

  group('downloading several chapters', () {
    testWidgets('the strip still shows a Download button, not an overflow', (
      tester,
    ) async {
      // It did not. `PopupMenuButton` draws its default three-dot glyph unless it is given a child,
      // and every test here reached the menu by its tooltip, so none of them looked at the cell.
      tallView(tester);
      await tester.pumpWidget(details(book(), <String>[]));

      // Not "no overflow glyph anywhere": every chapter row has one of its own, rightly. What must
      // be there is the cell, with the word a listener is looking for on it.
      expect(find.text('Download'), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('the next chapter is the first unlistened one', (tester) async {
      // Opening is listened, so "next" starts at Middle rather than at the top of the list.
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await openDownloadMenu(tester);
      await tester.tap(find.text('Next chapter'));
      await tester.pumpAndSettle();

      expect(pressed, ['download 11']);
    });

    testWidgets('the next few skip what is already here', (tester) async {
      // A listener asking for five wants five more, not five rows that were already green.
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(), pressed, {11: ChapterDownload.here}),
      );

      await openDownloadMenu(tester);
      await tester.tap(find.text('Next 5 chapters'));
      await tester.pumpAndSettle();

      expect(pressed, ['download 12']);
    });

    testWidgets('all unlistened leaves the listened ones alone', (
      tester,
    ) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await openDownloadMenu(tester);
      await tester.tap(find.text('All unlistened chapters'));
      await tester.pumpAndSettle();

      expect(pressed, ['download 11, 12']);
    });

    testWidgets('all chapters means all of them, listened or not', (
      tester,
    ) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await openDownloadMenu(tester);
      await tester.tap(find.text('All chapters'));
      await tester.pumpAndSettle();

      expect(pressed, ['download 10, 11, 12']);
    });

    testWidgets('the queue is reachable from the same menu', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await openDownloadMenu(tester);
      await tester.tap(find.text('Download queue'));
      await tester.pumpAndSettle();

      expect(pressed, ['queue']);
    });
  });

  group('refreshing from the source', () {
    testWidgets('pulling the page down asks the source again', (tester) async {
      tallView(tester);
      var asked = 0;
      await tester.pumpWidget(
        details(book(), null, const {}, () async => asked++),
      );

      await tester.fling(find.text('A Book'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(asked, 1);
    });

    testWidgets('a book with no source to ask does not offer it', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(details(book()));

      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  testWidgets('shows the title, credits, length and chapters', (tester) async {
    tallView(tester);
    await tester.pumpWidget(details(book()));

    expect(find.text('A Book'), findsOneWidget);
    expect(find.text('An Author, Second Author'), findsOneWidget);
    expect(find.text('A Narrator'), findsOneWidget);
    expect(find.text('35:00'), findsOneWidget);
    for (final (title, length) in [
      ('Opening', '10:00'),
      ('Middle', '20:00'),
      ('End', '5:00'),
    ]) {
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, title),
          matching: find.text(length),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('shows the cover beside what identifies the book', (
    tester,
  ) async {
    // Beside rather than above, so the title, the credits and the length are all on the first
    // screen of a phone instead of below a cover the width of the window.
    await tester.pumpWidget(details(book(cover: '1.jpg')));

    final cover = tester.widget<BookCover>(find.byType(BookCover));
    expect(cover.file!.path, covers.fileOf('1.jpg')!.path);
    expect(cover.semanticLabel, 'Cover of A Book');
    expect(
      tester.getTopRight(find.byType(BookCover)).dx,
      lessThanOrEqualTo(tester.getTopLeft(find.text('A Book')).dx),
    );
    expect(
      tester.getTopLeft(find.text('A Book')).dy,
      lessThan(tester.getBottomLeft(find.byType(BookCover)).dy),
      reason: 'the title sits alongside the cover, not under it',
    );
  });

  testWidgets('keeps the cover one size, whatever the window', (tester) async {
    // A fixed cover is what leaves the metadata a readable column beside it. Sizing it to the
    // window made that column collapse on a narrow one.
    tester.view.physicalSize = const Size(240, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(details(book()));

    expect(tester.getSize(find.byType(BookCover)).width, 120);
  });

  testWidgets('shows the time left on a started book', (tester) async {
    await tester.pumpWidget(details(book(progress: elevenMinutesIn)));

    expect(find.text('24:00 left'), findsOneWidget);
  });

  group('what the play button says', () {
    test('a book never started is started', () {
      expect(playButtonLabel(book()), 'Start');
      expect(playButtonFrom(book()), PlayFrom.savedPosition);
    });

    test('a book left part-way is resumed', () {
      final started = book(progress: elevenMinutesIn);
      expect(playButtonLabel(started), 'Resume');
      expect(playButtonFrom(started), PlayFrom.savedPosition);
    });

    test('a finished book is played again from the top', () {
      // Resuming it would drop the listener at the end, the one place they do not want.
      final done = book(progress: elevenMinutesIn, finished: true);
      expect(playButtonLabel(done), 'Play again');
      expect(playButtonFrom(done), PlayFrom.start);
    });
  });

  testWidgets('marks the chapters listened and the one being listened to', (
    tester,
  ) async {
    tallView(tester);
    await tester.pumpWidget(details(book(progress: elevenMinutesIn)));

    expect(iconIn('Opening', Icons.check), findsOneWidget);
    expect(iconIn('Middle', Icons.graphic_eq), findsOneWidget);
    expect(iconIn('End', Icons.check), findsNothing);
    expect(iconIn('End', Icons.graphic_eq), findsNothing);
  });

  testWidgets('lists embedded markers in place of the one chapter', (
    tester,
  ) async {
    tallView(tester);
    await tester.pumpWidget(
      details(
        book(
          chapters: const [
            ChapterOverview(
              chapterId: 10,
              title: 'A Book',
              durationMs: 2100000,
              listened: false,
              current: false,
            ),
          ],
          markers: const [
            MarkerOverview(
              title: 'Chapter One',
              startMs: 0,
              endMs: 900000,
              listened: true,
              current: false,
            ),
            MarkerOverview(
              title: 'Chapter Two',
              startMs: 900000,
              endMs: 2100000,
              listened: false,
              current: true,
            ),
          ],
        ),
      ),
    );

    expect(find.widgetWithText(ListTile, 'A Book'), findsNothing);
    expect(iconIn('Chapter One', Icons.check), findsOneWidget);
    expect(iconIn('Chapter Two', Icons.graphic_eq), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    // A marker has no listened state of its own to set (§4.5).
    expect(find.byType(PopupMenuButton<bool>), findsNothing);
  });

  testWidgets('says a book marked finished is finished, started or not', (
    tester,
  ) async {
    await tester.pumpWidget(details(book(finished: true)));

    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Mark finished'), findsNothing);
  });

  group("a chapter's menu", () {
    testWidgets('marks a chapter not yet listened listened', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.byTooltip('Options for End'));
      await tester.pumpAndSettle();
      expect(find.text('Mark as not listened'), findsNothing);
      await tester.tap(find.text('Mark as listened'));
      await tester.pumpAndSettle();

      expect(pressed, ['mark 12 listened']);
    });

    testWidgets('marks a listened chapter not listened', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.byTooltip('Options for Opening'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as not listened'));
      await tester.pumpAndSettle();

      expect(pressed, ['mark 10 not listened']);
    });

    testWidgets('is a button named for its chapter', (tester) async {
      tallView(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(details(book()));

      expect(
        tester.getSemantics(find.byTooltip('Options for End')),
        isSemantics(
          tooltip: 'Options for End',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('is reached and used from the keyboard', (tester) async {
      tallView(tester);
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tabTo(tester, 'End');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Mark as listened'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(pressed, ['mark 12 listened']);
    });
  });

  group('marking the whole book', () {
    testWidgets('marks it finished, and Undo marks back what it marked', (
      tester,
    ) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(progress: elevenMinutesIn), pressed),
      );

      await tester.tap(find.text('Mark finished'));
      await tester.pumpAndSettle();
      expect(pressed, ['mark finished']);
      expect(find.text('Marked as finished'), findsOneWidget);

      await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
      await tester.pumpAndSettle();
      expect(pressed, ['mark finished', 'mark 11, 12 not listened']);
    });

    testWidgets('offers a finished book to be marked not finished', (
      tester,
    ) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        details(book(progress: elevenMinutesIn, finished: true), pressed),
      );

      expect(find.text('Mark finished'), findsNothing);
      await tester.tap(find.text('Finished'));
      await tester.pumpAndSettle();
      expect(pressed, ['mark not finished']);
    });

    testWidgets('is one cell of the strip with two faces', (tester) async {
      // A state as much as an action, which is what the strip is for: lit or not says at a glance
      // what a row of identical outlined buttons made you read to find out.
      await tester.pumpWidget(details(book()));
      expect(find.text('Mark finished'), findsOneWidget);
      expect(find.text('Finished'), findsNothing);

      await tester.pumpWidget(details(book(finished: true)));
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('Mark finished'), findsNothing);
    });
  });

  group('removing the book', () {
    testWidgets('asks first, and Cancel keeps it', (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.text('In library'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from library?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from library?'), findsNothing);
      expect(pressed, isEmpty);
    });

    testWidgets('happens once confirmed', (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(details(book(), pressed));

      await tester.tap(find.text('In library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(pressed, ['remove']);
    });

    testWidgets('is not offered for a book already out of the library', (
      tester,
    ) async {
      // The cell stays, saying what is true. Hiding it would move the ones beside it under the
      // listener's finger between one visit and the next.
      await tester.pumpWidget(details(book(inLibrary: false)));

      expect(find.text('In library'), findsNothing);
      expect(find.text('Add to library'), findsOneWidget);
    });
  });
}

/// A book to read shows its chapters in its own words.
///
/// The details page was built for audiobooks, so it said "Mark as listened" over a novel and drew
/// a waveform beside the chapter someone was reading. What is the same for both — the chapter list,
/// marking one done, finishing a book — stays the same; the words and the figures do not.
void _aBookToRead() {
  const chapters = [
    ChapterOverview(
      chapterId: 10,
      title: 'Chapter One',
      durationMs: null,
      wordCount: 2500,
      listened: true,
      current: false,
    ),
    ChapterOverview(
      chapterId: 11,
      title: 'Chapter Two',
      durationMs: null,
      wordCount: 5000,
      listened: false,
      current: true,
    ),
    ChapterOverview(
      chapterId: 12,
      title: 'Chapter Three',
      durationMs: null,
      listened: false,
      current: false,
    ),
  ];

  Widget reading({int wordsPerMinute = 250}) => MaterialApp(
    home: Scaffold(
      body: BookDetailsView(
        book: BookOverview(
          sourceId: 2,
          bookId: 1,
          title: 'A Novel',
          kind: SourceKind.text,
          authors: const ['An Author'],
          narrators: const [],
          totalDurationMs: null,
          inLibrary: true,
          chapters: chapters,
          markers: const [],
          progress: null,
          finished: false,
          coverFileName: null,
        ),
        covers: covers,
        canDownload: false,
        wordsPerMinute: wordsPerMinute,
        chapterDownloads: const {},
        onRemove: () {},
        onOpenDownloadQueue: () {},
        listenedCommands: ListenedCommands(
          markChapters: (_, _) async => {},
          markFinished: () async => {},
          markNotFinished: () async {},
        ),
      ),
    ),
  );

  group('a book to read', () {
    testWidgets('says how long a chapter takes to read, not to play', (
      tester,
    ) async {
      await tester.pumpWidget(reading());

      expect(find.text('~10 m'), findsOneWidget);
      expect(find.text('~20 m'), findsOneWidget);
      // The one whose words have never been counted says nothing rather than guessing.
      expect(find.text('~0 m'), findsNothing);
    });

    testWidgets(
      'says nothing about length when the reader asked not to be told',
      (tester) async {
        await tester.pumpWidget(reading(wordsPerMinute: 0));

        expect(find.textContaining('~'), findsNothing);
      },
    );

    testWidgets('marks a chapter read rather than listened', (tester) async {
      await tester.pumpWidget(reading());

      await tester.tap(find.byType(PopupMenuButton<bool>).first);
      await tester.pumpAndSettle();

      expect(find.text('Mark as unread'), findsOneWidget);
      expect(find.text('Mark as listened'), findsNothing);
      expect(find.text('Mark as not listened'), findsNothing);
    });

    testWidgets('marks where the reader is with a book, not a waveform', (
      tester,
    ) async {
      await tester.pumpWidget(reading());

      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsNothing);
    });

    testWidgets('offers nothing to download', (tester) async {
      await tester.pumpWidget(reading());

      expect(find.text('Download'), findsNothing);
    });
  });
}
