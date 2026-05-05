import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter_browser_scroll/src/browser_scroll_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserScrollController', () {
    test('jumpTo delegates to ExternalScroller', () {
      final scroller = _FakeExternalScroller();
      final controller = BrowserScrollController()..scrollerApi = scroller;

      controller.jumpTo(250);

      expect(scroller.scrollCalls, <_ScrollCall>[
        const _ScrollCall(250, smooth: false),
      ]);
    });

    test('animateTo delegates smooth scroll to ExternalScroller', () async {
      final scroller = _FakeExternalScroller();
      final controller = BrowserScrollController()..scrollerApi = scroller;

      await controller.animateTo(
        400,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      expect(scroller.scrollCalls, <_ScrollCall>[
        const _ScrollCall(400, smooth: true),
      ]);
    });

    test('prepares placeholder before programmatic scroll', () {
      final prepared = <double>[];
      final scroller = _FakeExternalScroller();
      final controller = BrowserScrollController()
        ..scrollerApi = scroller
        ..prepareTarget = prepared.add;

      controller.jumpTo(600);

      expect(prepared, <double>[600]);
      expect(scroller.scrollCalls.single.offset, 600);
    });
  });
}

class _FakeExternalScroller implements ExternalScroller {
  final List<_ScrollCall> scrollCalls = <_ScrollCall>[];

  @override
  double get scrollTop => 0;

  @override
  void addScrollListener(void Function() callback) {}

  @override
  void addVisibleRectListener(RectCallback callback) {}

  @override
  ui.Rect computeVisibleRect() => ui.Rect.zero;

  @override
  void dispose() {}

  @override
  Future<void> scrollTo(double offset, {bool smooth = false}) async {
    scrollCalls.add(_ScrollCall(offset, smooth: smooth));
  }

  @override
  void scrollBy(double delta) {}

  @override
  void setNativePanBlocked(bool blocked) {}

  @override
  void setup() {}

  @override
  void updateHeight(double height) {}
}

class _ScrollCall {
  const _ScrollCall(this.offset, {required this.smooth});

  final double offset;
  final bool smooth;

  @override
  bool operator ==(Object other) {
    return other is _ScrollCall &&
        other.offset == offset &&
        other.smooth == smooth;
  }

  @override
  int get hashCode => Object.hash(offset, smooth);

  @override
  String toString() => '_ScrollCall($offset, smooth: $smooth)';
}
