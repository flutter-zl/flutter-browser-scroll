// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide RectCallback;
import 'package:flutter_browser_scroll/src/browser_scroll_controller.dart';
import 'package:flutter_browser_scroll/src/browser_scroll_route_observer.dart';
import 'package:flutter_browser_scroll/src/external_scroller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserScrollRouteObserver', () {
    late _FakeExternalScroller scroller;
    late BrowserScrollController controller;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      scroller = _FakeExternalScroller();
      controller = BrowserScrollController()..scrollerApi = scroller;
      navigatorKey = GlobalKey<NavigatorState>();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildApp() {
      return MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: <NavigatorObserver>[
          BrowserScrollRouteObserver(controller),
        ],
        home: const Scaffold(body: SizedBox.expand()),
      );
    }

    testWidgets('locks while a dialog is open', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      expect(scroller.lockCalls, isEmpty);

      showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) => const AlertDialog(),
      );
      await tester.pumpAndSettle();
      expect(scroller.lockCalls, <bool>[true]);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(scroller.lockCalls, <bool>[true, false]);
    });

    testWidgets('nested popups keep the lock until the last one closes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());

      showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) => const AlertDialog(),
      );
      await tester.pumpAndSettle();
      showModalBottomSheet<void>(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) => const SizedBox(height: 100),
      );
      await tester.pumpAndSettle();
      expect(scroller.lockCalls, <bool>[true]);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(scroller.lockCalls, <bool>[true]);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(scroller.lockCalls, <bool>[true, false]);
    });

    testWidgets('page routes do not lock', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const SizedBox.expand(),
        ),
      );
      await tester.pumpAndSettle();

      expect(scroller.lockCalls, isEmpty);
    });
  });
}

class _FakeExternalScroller implements ExternalScroller {
  @override
  bool get isFullPage => false;

  final List<bool> lockCalls = <bool>[];

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
  Future<void> scrollTo(double offset, {bool smooth = false}) async {}

  @override
  void scrollBy(double delta) {}

  @override
  void setNativePanBlocked(bool blocked) {}

  @override
  void setPageScrollLocked(bool locked) {
    lockCalls.add(locked);
  }

  @override
  void setup() {}

  @override
  void updateHeight(double height) {}
}
