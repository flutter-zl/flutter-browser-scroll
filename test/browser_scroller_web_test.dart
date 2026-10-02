// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_browser_scroll/flutter_browser_scroll.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserScroller', () {
    testWidgets('sets up caller-provided scroller once', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(_TestHost(scrollerApi: scroller));

      expect(scroller.setupCount, 1);
      expect(scroller.scrollListenerCount, 1);
      expect(scroller.visibleRectListenerCount, 1);
    });

    testWidgets('does not dispose caller-provided scroller', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(_TestHost(scrollerApi: scroller));
      await tester.pumpWidget(const SizedBox.shrink());

      expect(scroller.disposeCount, 0);
    });

    testWidgets('does not dispose caller-provided controller', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();
      final controller = _TrackingBrowserScrollController();

      await tester.pumpWidget(
        _TestHost(scrollerApi: scroller, controller: controller),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(controller.disposeCount, 0);
      controller.dispose();
    });

    testWidgets('disposes owned controller', (WidgetTester tester) async {
      final scroller = _FakeExternalScroller();
      final controller = _TrackingBrowserScrollController();
      final BrowserScrollController Function() previousFactory =
          BrowserScroller.debugControllerFactory;
      BrowserScroller.debugControllerFactory = () => controller;
      addTearDown(() {
        BrowserScroller.debugControllerFactory = previousFactory;
      });

      await tester.pumpWidget(_TestHost(scrollerApi: scroller));
      await tester.pumpWidget(const SizedBox.shrink());

      expect(controller.disposeCount, 1);
    });

    testWidgets('throws when scrollerApi changes after setup', (
      WidgetTester tester,
    ) async {
      final firstScroller = _FakeExternalScroller();
      final secondScroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
            key: const ValueKey<String>('host'), scrollerApi: firstScroller),
      );
      final FlutterExceptionHandler? previousOnError = FlutterError.onError;
      Object? exception;
      FlutterError.onError = (FlutterErrorDetails details) {
        exception = details.exception;
      };
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      await tester.pumpWidget(
        _TestHost(
          key: const ValueKey<String>('host'),
          scrollerApi: secondScroller,
        ),
      );

      expect(exception, isA<FlutterError>());
      expect(
        exception.toString(),
        contains('BrowserScroller does not support changing scrollerApi'),
      );
    });

    testWidgets('throws when controller changes after setup', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();
      final firstController = BrowserScrollController();
      final secondController = BrowserScrollController();

      await tester.pumpWidget(
        _TestHost(
          key: const ValueKey<String>('host'),
          controller: firstController,
          scrollerApi: scroller,
        ),
      );
      final FlutterExceptionHandler? previousOnError = FlutterError.onError;
      Object? exception;
      FlutterError.onError = (FlutterErrorDetails details) {
        exception = details.exception;
      };
      addTearDown(() {
        FlutterError.onError = previousOnError;
        firstController.dispose();
        secondController.dispose();
      });

      await tester.pumpWidget(
        _TestHost(
          key: const ValueKey<String>('host'),
          controller: secondController,
          scrollerApi: scroller,
        ),
      );

      expect(exception, isA<FlutterError>());
      expect(
        exception.toString(),
        contains('BrowserScroller does not support changing controller'),
      );
    });

    testWidgets('creates and disposes default scroller', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();
      final ExternalScroller Function(int viewId) previousFactory =
          BrowserScroller.debugScrollerFactory;
      BrowserScroller.debugScrollerFactory = (int viewId) => scroller;
      addTearDown(() {
        BrowserScroller.debugScrollerFactory = previousFactory;
      });

      await tester.pumpWidget(const _DefaultTestHost());
      await tester.pumpWidget(const SizedBox.shrink());

      expect(scroller.setupCount, 1);
      expect(scroller.disposeCount, 1);
    });

    testWidgets('BrowserScrollChild forwards top-edge overscroll by default', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
          scrollerApi: scroller,
          child: BrowserScrollChild(
            child: Builder(
              builder: (BuildContext context) {
                return const SizedBox(
                  key: ValueKey<String>('default-region-target'),
                  width: 800,
                  height: 100,
                );
              },
            ),
          ),
        ),
      );

      _dispatchTopEdgeOverscroll(
        tester.element(
          find.byKey(const ValueKey<String>('default-region-target')),
        ),
      );
      await tester.pump();

      expect(scroller.scrollByCalls, <double>[-20]);
    });

    testWidgets('preserveTopOverscroll keeps top-edge overscroll inner', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
          scrollerApi: scroller,
          child: BrowserScrollChild(
            preserveTopOverscroll: true,
            child: Builder(
              builder: (BuildContext context) {
                return const SizedBox(
                  key: ValueKey<String>('preserve-target'),
                  width: 800,
                  height: 100,
                );
              },
            ),
          ),
        ),
      );

      _dispatchTopEdgeOverscroll(
        tester.element(find.byKey(const ValueKey<String>('preserve-target'))),
      );
      await tester.pump();

      expect(scroller.scrollByCalls, isEmpty);
    });

    testWidgets('BrowserScrollChild suppresses top-edge ballistic overscroll', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
          scrollerApi: scroller,
          child: BrowserScrollChild(
            child: Builder(
              builder: (BuildContext context) {
                return const SizedBox(
                  key: ValueKey<String>('ballistic-target'),
                  width: 800,
                  height: 100,
                );
              },
            ),
          ),
        ),
      );

      _dispatchTopEdgeOverscroll(
        tester.element(find.byKey(const ValueKey<String>('ballistic-target'))),
        isActiveDrag: false,
      );
      await tester.pump();

      expect(scroller.scrollByCalls, isEmpty);
    });

    testWidgets('bare BrowserScroller forwards top-edge overscroll', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
          scrollerApi: scroller,
          child: Builder(
            builder: (BuildContext context) {
              return const SizedBox(
                key: ValueKey<String>('bare-target'),
                width: 800,
                height: 100,
              );
            },
          ),
        ),
      );

      _dispatchTopEdgeOverscroll(
        tester.element(find.byKey(const ValueKey<String>('bare-target'))),
      );
      await tester.pump();

      expect(scroller.scrollByCalls, <double>[-20]);
    });

    testWidgets('blocks native pan for touch on inner vertical list', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(scrollerApi: scroller, child: const _InnerListPage()),
      );

      final TestGesture gesture = await tester.startGesture(
        const Offset(400, 100),
        kind: PointerDeviceKind.touch,
      );
      expect(scroller.nativePanBlockedCalls, <bool>[true]);

      await gesture.up();
      expect(scroller.nativePanBlockedCalls, <bool>[true, false]);
    });

    testWidgets('does not block native pan for touch outside inner list', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(scrollerApi: scroller, child: const _InnerListPage()),
      );

      final TestGesture gesture = await tester.startGesture(
        const Offset(400, 500),
        kind: PointerDeviceKind.touch,
      );
      await gesture.up();

      expect(scroller.nativePanBlockedCalls, <bool>[false, false]);
    });

    testWidgets('does not block native pan for touch on horizontal list', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
          scrollerApi: scroller,
          child: const _InnerListPage(scrollDirection: Axis.horizontal),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        const Offset(400, 100),
        kind: PointerDeviceKind.touch,
      );
      await gesture.up();

      expect(scroller.nativePanBlockedCalls, <bool>[false, false]);
    });

    testWidgets('ignores mouse pointers on inner list', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(scrollerApi: scroller, child: const _InnerListPage()),
      );

      final TestGesture gesture = await tester.startGesture(
        const Offset(400, 100),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();

      expect(scroller.nativePanBlockedCalls, isEmpty);
    });

    testWidgets(
      'inner list chains bottom overscroll to the page on iOS',
      (WidgetTester tester) async {
        final scroller = _FakeExternalScroller();

        await tester.pumpWidget(
          _TestHost(scrollerApi: scroller, child: const _InnerListPage()),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -2500));
        await tester.pump();

        expect(scroller.scrollByCalls, isNotEmpty);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'explicit BouncingScrollPhysics on an inner list is kept',
      (WidgetTester tester) async {
        final scroller = _FakeExternalScroller();

        await tester.pumpWidget(
          _TestHost(
            scrollerApi: scroller,
            child: const _InnerListPage(physics: BouncingScrollPhysics()),
          ),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -2500));
        await tester.pump();

        expect(scroller.scrollByCalls, isEmpty);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('horizontal inner list overscroll does not scroll the page', (
      WidgetTester tester,
    ) async {
      final scroller = _FakeExternalScroller();

      await tester.pumpWidget(
        _TestHost(
          scrollerApi: scroller,
          child: const _InnerListPage(scrollDirection: Axis.horizontal),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(-2500, 0));
      await tester.pump();

      expect(scroller.scrollByCalls, isEmpty);
    });

    // A plain test, not testWidgets: the scroller's safety timeout is a real
    // Timer and FakeAsync would never fire it.
    test('smooth scrollTo to the current position completes at once', () async {
      final TestWidgetsFlutterBinding binding =
          TestWidgetsFlutterBinding.ensureInitialized();
      final scroller = JsViewScroller(
        binding.platformDispatcher.implicitView!.viewId,
      );
      addTearDown(scroller.dispose);
      scroller.setup();
      // Pin to the top so the target is already reached.
      await scroller.scrollTo(0);

      final Stopwatch stopwatch = Stopwatch()..start();
      await scroller.scrollTo(0, smooth: true);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}

class _InnerListPage extends StatelessWidget {
  const _InnerListPage({this.scrollDirection = Axis.vertical, this.physics});

  final Axis scrollDirection;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: scrollDirection,
            physics: physics,
            itemExtent: 100,
            itemCount: 20,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
        const SizedBox(width: 800, height: 900),
      ],
    );
  }
}

class _TestHost extends StatelessWidget {
  const _TestHost({
    super.key,
    required this.scrollerApi,
    this.controller,
    this.child = const SizedBox(width: 800, height: 1200),
  });

  final ExternalScroller scrollerApi;
  final BrowserScrollController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(size: ui.Size(800, 600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: BrowserScroller(
          controller: controller,
          scrollerApi: scrollerApi,
          child: child,
        ),
      ),
    );
  }
}

void _dispatchTopEdgeOverscroll(
  BuildContext context, {
  bool isActiveDrag = true,
}) {
  OverscrollNotification(
    metrics: FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 100,
      pixels: 0,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    ),
    context: context,
    overscroll: -20,
    dragDetails:
        isActiveDrag ? DragUpdateDetails(globalPosition: Offset.zero) : null,
  ).dispatch(context);
}

class _DefaultTestHost extends StatelessWidget {
  const _DefaultTestHost();

  @override
  Widget build(BuildContext context) {
    return const MediaQuery(
      data: MediaQueryData(size: ui.Size(800, 600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: BrowserScroller(
          child: SizedBox(width: 800, height: 1200),
        ),
      ),
    );
  }
}

class _TrackingBrowserScrollController extends BrowserScrollController {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount += 1;
    super.dispose();
  }
}

class _FakeExternalScroller implements ExternalScroller {
  int setupCount = 0;
  int disposeCount = 0;
  int scrollListenerCount = 0;
  int visibleRectListenerCount = 0;
  final List<double> scrollByCalls = <double>[];
  final List<bool> nativePanBlockedCalls = <bool>[];

  @override
  double get scrollTop => 0;

  @override
  void addScrollListener(void Function() callback) {
    scrollListenerCount += 1;
  }

  @override
  void addVisibleRectListener(RectCallback callback) {
    visibleRectListenerCount += 1;
  }

  @override
  ui.Rect computeVisibleRect() {
    return const ui.Rect.fromLTWH(0, 0, 800, 600);
  }

  @override
  void dispose() {
    disposeCount += 1;
  }

  @override
  Future<void> scrollTo(double offset, {bool smooth = false}) async {}

  @override
  void scrollBy(double delta) {
    scrollByCalls.add(delta);
  }

  @override
  void setNativePanBlocked(bool blocked) {
    nativePanBlockedCalls.add(blocked);
  }

  @override
  void setup() {
    setupCount += 1;
  }

  @override
  void updateHeight(double height) {}
}
