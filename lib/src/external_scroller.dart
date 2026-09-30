// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

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
