// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'external_scroller.dart';

/// A [ScrollController] for a page whose scroll is owned by the browser.
///
/// The browser drives the page. Scroll events from the browser are mirrored
/// into this controller through [syncFromBrowser], which updates
/// [ScrollController.offset] and notifies listeners but does not dispatch any
/// [ScrollNotification]. `ScrollStartNotification`,
/// `ScrollUpdateNotification`, and `ScrollEndNotification` never fire for
/// browser-driven scrolls, `position.isScrollingNotifier` stays `false`, and
/// `position.userScrollDirection` stays `idle`. Code that needs to react to
/// page scrolls should use [addListener].
///
/// [jumpTo] is the one exception: it moves the Flutter position first, which
/// dispatches the usual notifications, and then tells the browser to follow.
class BrowserScrollController extends ScrollController {
  BrowserScrollController();

  ExternalScroller? _scrollerApi;
  void Function(double target)? _prepareTarget;
  int _pageScrollLocks = 0;

  set scrollerApi(ExternalScroller? value) {
    _scrollerApi = value;
    if (_pageScrollLocks > 0) {
      value?.setPageScrollLocked(true);
    }
  }

  set prepareTarget(void Function(double target)? value) {
    _prepareTarget = value;
  }

  /// Whether [lockPageScroll] has been called more times than
  /// [unlockPageScroll].
  bool get isPageScrollLocked => _pageScrollLocks > 0;

  /// Freezes the page so wheel, trackpad, touch, and keyboard input no longer
  /// scroll it. Flutter scrollables and platform views keep working.
  ///
  /// Calls nest: the page stays frozen until every lock has been released
  /// with [unlockPageScroll]. [BrowserScrollRouteObserver] calls this for
  /// modal routes.
  void lockPageScroll() {
    _pageScrollLocks += 1;
    if (_pageScrollLocks == 1) {
      _scrollerApi?.setPageScrollLocked(true);
    }
  }

  /// Releases one lock taken by [lockPageScroll].
  void unlockPageScroll() {
    assert(_pageScrollLocks > 0, 'unlockPageScroll called without a lock.');
    if (_pageScrollLocks == 0) {
      return;
    }
    _pageScrollLocks -= 1;
    if (_pageScrollLocks == 0) {
      _scrollerApi?.setPageScrollLocked(false);
    }
  }

  void syncFromBrowser(double offset) {
    if (!hasClients) {
      return;
    }
    // Browser scroll events should not cancel an active drag activity.
    // ignore: invalid_use_of_protected_member
    positions.first.forcePixels(offset);
  }

  /// Scrolls the page to [offset] using the browser's native smooth scroll.
  ///
  /// The browser picks the timing and easing, so [duration] and [curve] are
  /// ignored except that a [duration] of [Duration.zero] scrolls instantly.
  /// The same call can look slightly different across browsers.
  ///
  /// The returned future completes when the page reaches the target, or
  /// immediately if it is already there. It does not wait for [duration].
  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    final ExternalScroller? scroller = _scrollerApi;
    if (scroller == null) {
      return super.animateTo(offset, duration: duration, curve: curve);
    }
    _prepareTarget?.call(offset);
    return scroller.scrollTo(offset, smooth: duration != Duration.zero);
  }

  @override
  void jumpTo(double value) {
    final ExternalScroller? scroller = _scrollerApi;
    if (scroller == null) {
      super.jumpTo(value);
      return;
    }
    _prepareTarget?.call(value);
    if (hasClients) {
      super.jumpTo(value);
    }
    unawaited(scroller.scrollTo(value));
  }
}
