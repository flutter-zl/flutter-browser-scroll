import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

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
    super.jumpTo(offset);
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

typedef RectCallback = void Function(ui.Rect);

abstract class ExternalScroller {
  double get scrollTop;

  ui.Rect computeVisibleRect();

  void setup() {}

  void addScrollListener(void Function() callback);

  void addVisibleRectListener(RectCallback callback);

  void updateHeight(double height);

  Future<void> scrollTo(double offset, {bool smooth = false});

  void scrollBy(double delta);

  void setNativePanBlocked(bool blocked) {}

  void dispose();
}
