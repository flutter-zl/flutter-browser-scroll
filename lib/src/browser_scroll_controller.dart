import 'dart:async';

import 'package:flutter/widgets.dart';

import 'external_scroller.dart';

class BrowserScrollController extends ScrollController {
  BrowserScrollController();

  ExternalScroller? _scrollerApi;
  void Function(double target)? _prepareTarget;

  set scrollerApi(ExternalScroller? value) {
    _scrollerApi = value;
  }

  set prepareTarget(void Function(double target)? value) {
    _prepareTarget = value;
  }

  void syncFromBrowser(double offset) {
    if (!hasClients) {
      return;
    }
    // Browser scroll events should not cancel an active drag activity.
    // ignore: invalid_use_of_protected_member
    positions.first.forcePixels(offset);
  }

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
