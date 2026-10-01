import 'package:flutter/material.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show hideFromContinueShelf, unhideFromContinueShelf;

import '../services.dart';
import '../snack_bars.dart';

/// Takes book [bookId] off the Continue shelf named [shelf], and offers to put it back.
///
/// The undo matters more than it looks. The shelf is the first thing on the screen, a long press is
/// easy to make by accident, and a book that silently vanished from it would look like a book that
/// had lost its place. The message says where it went and when it comes back.
Future<void> hideFromContinue(
  BuildContext context,
  AppServices services,
  int bookId, {
  required String shelf,
  required String usingIt,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final before = await hideFromContinueShelf(
    services.database,
    bookId,
    at: services.clock.now(),
  );
  if (!context.mounted) return;
  offerInSnackBar(
    context,
    messenger,
    message:
        'Removed from $shelf. Your place is kept, and it comes back when '
        'you next $usingIt it.',
    action: 'Undo',
    onPressed: () =>
        unhideFromContinueShelf(services.database, bookId, restoring: before),
  );
}
