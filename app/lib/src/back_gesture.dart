/// iOS's back gesture, from a strip wide enough to hit.
///
/// Flutter gives an iOS app the swipe-back gesture for free, and then makes it almost impossible to
/// use: the strip that starts it is 20 logical pixels from the left edge, about three millimetres,
/// and a swipe that begins a finger's width further in does nothing at all. Every screen in this app
/// is a list, and the first few pixels of a drag are eaten by the gesture arena deciding between the
/// list and the gesture, which makes a near miss feel like an app that ignores the gesture entirely.
///
/// Widening it needs no private API. The detector Flutter builds sizes its strip as
/// `max(MediaQuery.padding.left, 20)` — the notch allowance, so that a phone held in landscape with
/// the notch on the left still has somewhere to start the drag. So the page is wrapped in a
/// `MediaQuery` claiming a wider left padding, and the page's own content is given the real padding
/// back immediately inside it, so that nothing else in the app is laid out any differently.
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// How far in from the left edge a back swipe may begin.
///
/// 44 logical pixels: the smallest thing Apple's own guidelines say a finger should be asked to hit,
/// and a little over twice Flutter's own 20. The cost is that a horizontal drag beginning in that
/// strip goes to the gesture rather than to what is under it, which on Browse means an edge swipe
/// between its tabs now goes back instead. Anywhere but the very edge still swipes between them.
const backGestureWidth = 44.0;

/// The iOS page transition, with [backGestureWidth] to start the back gesture from.
class WideBackGesturePageTransitionsBuilder
    extends CupertinoPageTransitionsBuilder {
  const WideBackGesturePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          left: math.max(media.padding.left, backGestureWidth),
        ),
      ),
      child: super.buildTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        // The page itself sees the padding it really has, so a SafeArea inside it is not inset by
        // the width of the gesture strip.
        MediaQuery(data: media, child: child),
      ),
    );
  }
}

/// How each platform moves from one screen to the next.
///
/// Every platform has to be named, because giving [PageTransitionsTheme] any builders replaces the
/// whole set: leaving Android out would cost it its predictive back animation.
const kikuyomiPageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.iOS: WideBackGesturePageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: ZoomPageTransitionsBuilder(),
    TargetPlatform.linux: ZoomPageTransitionsBuilder(),
  },
);
