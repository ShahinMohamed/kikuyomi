import 'dart:async';

import 'package:flutter/material.dart';

/// What a reading surface needs to drive the bar above it.
final class ReaderChromeControls {
  const ReaderChromeControls({required this.toggle, required this.hide});

  /// The reader tapped the page: show the bar if it is hidden, hide it if it is showing.
  final VoidCallback toggle;

  /// The reader started reading — scrolled, or turned a page — so the bar goes out of the way.
  final VoidCallback hide;
}

/// The frame around a book being read: a bar with the chapter's name that gets out of the way.
///
/// The bar used to stay on the screen for as long as the book was open, which is a line of the page
/// given to a title the reader already knows. Now it shows when a chapter opens and leaves on its
/// own a few seconds later, leaves as soon as the reader starts scrolling, and comes back for a tap
/// on the page — which is how every reading app people are used to behaves.
///
/// The bar is laid **over** the page rather than above it. Taking it out of the layout would move
/// every line of text up by its height each time it came or went, and since where the reader is
/// gets saved as a fraction of the chapter's length, a page that changes length under them would
/// save a place that drifts.
///
/// With a screen reader on, the bar never hides by itself: someone who cannot see it go cannot know
/// to tap for it, and the controls on it are the only way to the chapter list.
class ReaderChrome extends StatefulWidget {
  const ReaderChrome({
    super.key,
    required this.appBar,
    required this.builder,
    this.revealKey,
    this.hideAfter = const Duration(seconds: 3),
  });

  final PreferredSizeWidget appBar;

  /// Builds the page, given what it needs to show and hide the bar.
  final Widget Function(BuildContext context, ReaderChromeControls controls)
  builder;

  /// Shows the bar again whenever this changes: a new chapter is somewhere new, and the reader
  /// should be told where.
  final Object? revealKey;

  /// How long the bar stays after it appears, unless something hides it sooner.
  final Duration hideAfter;

  @override
  State<ReaderChrome> createState() => _ReaderChromeState();
}

class _ReaderChromeState extends State<ReaderChrome> {
  bool _visible = true;
  Timer? _hideLater;

  late final _controls = ReaderChromeControls(toggle: _toggle, hide: _hide);

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(ReaderChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealKey != widget.revealKey) _show();
  }

  @override
  void dispose() {
    _hideLater?.cancel();
    super.dispose();
  }

  bool get _mayHide =>
      !(MediaQuery.maybeAccessibleNavigationOf(context) ?? false);

  void _scheduleHide() {
    _hideLater?.cancel();
    _hideLater = Timer(widget.hideAfter, _hide);
  }

  void _show() {
    _scheduleHide();
    if (!_visible) setState(() => _visible = true);
  }

  void _hide() {
    _hideLater?.cancel();
    if (!mounted || !_visible || !_mayHide) return;
    setState(() => _visible = false);
  }

  void _toggle() => _visible ? _hide() : _show();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The system's own bar along the top of a phone. With the reader's bar gone, text scrolling
    // underneath it would have the clock and the battery printed over it, so the strip it sits in
    // stays solid. Nothing on a desktop, where there is no such bar.
    final statusBar = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _HidingBar(
        visible: _visible,
        // Reaching for a button on the bar is using it, so it stays a while longer rather than
        // leaving under the reader's finger.
        onTouched: _scheduleHide,
        child: widget.appBar,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: widget.builder(context, _controls)),
          if (statusBar > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusBar,
              child: ColoredBox(color: theme.colorScheme.surface),
            ),
        ],
      ),
    );
  }
}

/// [child], sliding up out of sight when not [visible] and taking no taps while it is gone.
class _HidingBar extends StatelessWidget implements PreferredSizeWidget {
  const _HidingBar({
    required this.visible,
    required this.onTouched,
    required this.child,
  });

  final bool visible;
  final VoidCallback onTouched;
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    return Listener(
      onPointerDown: (_) => onTouched(),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, -1),
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            child: child,
          ),
        ),
      ),
    );
  }
}
