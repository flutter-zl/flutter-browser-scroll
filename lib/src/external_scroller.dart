// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

typedef RectCallback = void Function(ui.Rect);

abstract class ExternalScroller {
  /// Whether the scroller owns the whole page, with the Flutter view covering
  /// the browser window, as opposed to one element embedded in a page.
  bool get isFullPage => false;

  double get scrollTop;

  ui.Rect computeVisibleRect();

  void setup() {}

  void addScrollListener(void Function() callback);

  void addVisibleRectListener(RectCallback callback);

  void updateHeight(double height);

  Future<void> scrollTo(double offset, {bool smooth = false});

  void scrollBy(double delta);

  void setNativePanBlocked(bool blocked) {}

  /// Freezes or releases the page scroll for every input: wheel, trackpad,
  /// touch, and keyboard. Used while a popup route is open.
  void setPageScrollLocked(bool locked) {}

  void dispose();
}
