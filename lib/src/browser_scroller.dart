// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'browser_scroll_child.dart';
import 'browser_scroll_controller.dart';
import 'external_scroller.dart';
import 'js_view_scroller.dart';
import 'overscroll_forwarding.dart';
import 'placeholder_height.dart';

/// Lets the browser own the outermost scroll of a Flutter Web page.
///
/// Wrap the page content in this widget. The browser scrolls the document and
/// the Flutter position mirrors it; see [BrowserScrollController] for how that
/// differs from a normal controller.
///
/// Inner vertical scrollables need no setup. A touch that starts on one
/// scrolls only that scrollable, and its top-edge and bottom-edge overscroll
/// continue into the page. Top-edge overscroll chains only during an active
/// drag; bottom-edge overscroll chains during drag and the fling that follows.
/// While the finger is still down, the page moves in Flutter only and the
/// browser's scroll position catches up when that finger lifts.
/// Wrap a scrollable in [BrowserScrollChild] with `preserveTopOverscroll` to
/// keep top-edge gestures for a `RefreshIndicator`.
///
/// Horizontal inner scrollables are left alone. Their touches do not block
/// the page pan and their edge overscroll never moves the page.
///
/// Inner scrollables default to [ClampingScrollPhysics] on every platform.
/// [BouncingScrollPhysics] stretches past the edge instead of reporting
/// overscroll, so with it the page handoff never triggers. A scrollable that
/// sets its own `physics` keeps them.
class BrowserScroller extends StatefulWidget {
  const BrowserScroller({
    super.key,
    this.controller,
    this.scrollerApi,
    required this.child,
  });

  final BrowserScrollController? controller;
  final ExternalScroller? scrollerApi;
  final Widget child;

  @visibleForTesting
  static BrowserScrollController Function() debugControllerFactory =
      BrowserScrollController.new;

  @visibleForTesting
  static ExternalScroller Function(int viewId) debugScrollerFactory =
      JsViewScroller.new;

  @override
  State<BrowserScroller> createState() => _BrowserScrollerState();
}

class _BrowserScrollerState extends State<BrowserScroller> {
  late final BrowserScrollController _scrollController;
  late final bool _ownsController;
  final PlaceholderHeightTracker _placeholderHeightTracker =
      PlaceholderHeightTracker();
  ExternalScroller? _ownedScrollerApi;
  bool _initialized = false;
  late final int _viewId;
  final Set<int> _nativePanBlockingPointers = <int>{};

  // Notification contexts of the inner vertical scrollables, which are their
  // gesture detectors. Collected from ScrollMetricsNotification, which every
  // scrollable dispatches after its first layout.
  final Set<BuildContext> _innerVerticalScrollables = <BuildContext>{};

  ExternalScroller get scrollerApi => widget.scrollerApi ?? _ownedScrollerApi!;

  late ui.Rect visibleRect;
  double _lastReportedHeight = 0;
  double _pendingOverscrollDelta = 0;
  bool _overscrollFlushScheduled = false;

  // Page offset that a handoff has moved Flutter to while a finger is still
  // down on an inner list. The browser is only scrolled to it when that
  // finger lifts: on iOS WebKit, scrolling the window under a held finger
  // makes pointer events report the finger at a stale position, which Flutter
  // reads as a backward drag of the inner list. `<flutter-view>` is fixed, so
  // the window's own position is not visible while it lags.
  double? _deferredPageOffset;

  // How far the browser page is scrolled past either end, for example during
  // an iOS rubber-band bounce. Full-page only. The content is shifted by this
  // amount so it moves like a native page instead of being clipped.
  double _browserOverscroll = 0;

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;
    _scrollController =
        widget.controller ?? BrowserScroller.debugControllerFactory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _viewId = View.of(context).viewId;

    _ownedScrollerApi = widget.scrollerApi == null
        ? BrowserScroller.debugScrollerFactory(_viewId)
        : null;
    _scrollController
      ..scrollerApi = scrollerApi
      ..prepareTarget = _prepareForTarget;

    scrollerApi.setup();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);

    _syncVisibleRect();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScrollPosition();
      _syncContentHeight();
    });
  }

  void _syncVisibleRect() {
    visibleRect = scrollerApi.computeVisibleRect();
    scrollerApi.addVisibleRectListener(_updateVisibleRect);
  }

  void _updateVisibleRect(ui.Rect newVisibleRect) {
    if (visibleRect != newVisibleRect) {
      setState(() {
        visibleRect = newVisibleRect;
      });
    }
  }

  void _syncScrollPosition() {
    _updateScrollPosition();
    scrollerApi.addScrollListener(_updateScrollPosition);
  }

  void _updateScrollPosition() {
    // The page is ahead of the browser until the finger lifts.
    if (_deferredPageOffset != null) {
      return;
    }
    if (_scrollController.hasClients) {
      final double scrollTop = scrollerApi.scrollTop;
      final double clamped = clampDouble(
        scrollTop,
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.syncFromBrowser(clamped);
      final double overscroll =
          scrollerApi.isFullPage ? scrollTop - clamped : 0;
      if (overscroll != _browserOverscroll) {
        setState(() {
          _browserOverscroll = overscroll;
        });
      }
    }
  }

  void _syncContentHeight() {
    _updateHeight();
    _scrollController.addListener(_updateHeight);
  }

  void _updateHeight() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    final double height = _placeholderHeightTracker.update(
      pixels: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
      viewportDimension: position.viewportDimension,
    );

    if ((height - _lastReportedHeight).abs() < 1.0) {
      return;
    }
    _lastReportedHeight = height;
    scrollerApi.updateHeight(height);
  }

  void _prepareForTarget(double target) {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    final double height = _placeholderHeightTracker.update(
      pixels: target,
      maxScrollExtent: position.maxScrollExtent,
      viewportDimension: position.viewportDimension,
    );

    if ((height - _lastReportedHeight).abs() < 1.0) {
      return;
    }
    _lastReportedHeight = height;
    scrollerApi.updateHeight(height);
  }

  // With semantics off, the engine delivers pointerdown to the framework
  // synchronously, before the browser dispatches the first touchmove. That
  // lets Flutter's own hit test decide whether to block the native page pan.
  void _handlePointerEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch || event.viewId != _viewId) {
      return;
    }
    if (event is PointerDownEvent) {
      if (_hitsInnerVerticalScrollable(event.position)) {
        _nativePanBlockingPointers.add(event.pointer);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _nativePanBlockingPointers.remove(event.pointer);
    } else {
      return;
    }
    scrollerApi.setNativePanBlocked(_nativePanBlockingPointers.isNotEmpty);
    if (_nativePanBlockingPointers.isEmpty) {
      _commitDeferredPageOffset();
    }
  }

  bool _hitsInnerVerticalScrollable(Offset position) {
    final HitTestResult result = HitTestResult();
    GestureBinding.instance.hitTestInView(result, position, _viewId);
    final Set<HitTestTarget> targets = <HitTestTarget>{};
    for (final HitTestEntry entry in result.path) {
      final HitTestTarget target = entry.target;
      targets.add(target);
      if (target is! RenderViewportBase || target.axis != Axis.vertical) {
        continue;
      }
      final ViewportOffset offset = target.offset;
      // The outer page viewport uses NeverScrollableScrollPhysics, so it never
      // accepts a user offset and is skipped here.
      if (offset is ScrollPosition &&
          offset.physics.shouldAcceptUserOffset(offset)) {
        return true;
      }
    }
    // A touch in the gap between two items reaches no item, so the viewport,
    // which only counts as hit through its items, is not in the path. The
    // list's gesture detector still gets the touch and drags the list.
    _innerVerticalScrollables.removeWhere((BuildContext context) {
      return !context.mounted;
    });
    for (final BuildContext context in _innerVerticalScrollables) {
      if (!targets.contains(context.findRenderObject())) {
        continue;
      }
      final ScrollPosition? offset =
          context.findAncestorStateOfType<ScrollableState>()?.position;
      if (offset != null && offset.physics.shouldAcceptUserOffset(offset)) {
        return true;
      }
    }
    return false;
  }

  bool _handleNotification(Notification notification) {
    if (notification is ScrollMetricsNotification) {
      // Depth 0 is the outer page Scrollable itself.
      if (notification.depth > 0 &&
          notification.metrics.axis == Axis.vertical) {
        _innerVerticalScrollables.add(notification.context);
      }
      return false;
    }
    if (notification is OverscrollNotification) {
      return _handleOverscrollNotification(notification);
    }
    return false;
  }

  bool _handleOverscrollNotification(OverscrollNotification notification) {
    // Only vertical overscroll can continue into the page.
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final bool shouldForward = shouldForwardOverscroll(
      overscroll: notification.overscroll,
      pixels: notification.metrics.pixels,
      minScrollExtent: notification.metrics.minScrollExtent,
      maxScrollExtent: notification.metrics.maxScrollExtent,
      preserveTopOverscroll:
          BrowserScrollChildScope.shouldPreserveTopOverscroll(
        notification.context,
      ),
      isActiveDrag: notification.dragDetails != null,
    );
    if (shouldForward) {
      _forwardOverscroll(notification.overscroll);
      return true;
    }
    return false;
  }

  void _forwardOverscroll(double delta) {
    _pendingOverscrollDelta += delta;
    if (_overscrollFlushScheduled) {
      return;
    }

    _overscrollFlushScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _overscrollFlushScheduled = false;
      final double pendingDelta = _pendingOverscrollDelta;
      _pendingOverscrollDelta = 0;
      if (pendingDelta.abs() > 0.5) {
        if (_nativePanBlockingPointers.isNotEmpty &&
            _scrollController.hasClients) {
          _deferPageDelta(pendingDelta);
        } else {
          scrollerApi.scrollBy(pendingDelta);
        }
      }
    });
  }

  void _deferPageDelta(double delta) {
    final ScrollPosition position = _scrollController.position;
    final double target = clampDouble(
      (_deferredPageOffset ?? position.pixels) + delta,
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _deferredPageOffset = target;
    _scrollController.syncFromBrowser(target);
  }

  void _commitDeferredPageOffset() {
    final double? target = _deferredPageOffset;
    if (target == null) {
      return;
    }
    _deferredPageOffset = null;
    scrollerApi.scrollTo(target);
  }

  @override
  void didUpdateWidget(BrowserScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'BrowserScroller does not support changing controller after setup.',
        ),
        ErrorDescription(
          'Create a new BrowserScroller with a new key when changing the '
          'browser scroll controller.',
        ),
      ]);
    }
    if (oldWidget.scrollerApi != widget.scrollerApi) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'BrowserScroller does not support changing scrollerApi after setup.',
        ),
        ErrorDescription(
          'Create a new BrowserScroller with a new key when changing the '
          'browser scroll bridge.',
        ),
      ]);
    }
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handlePointerEvent,
    );
    if (_nativePanBlockingPointers.isNotEmpty) {
      scrollerApi.setNativePanBlocked(false);
    }
    _scrollController
      ..scrollerApi = null
      ..prepareTarget = null;
    if (_ownsController) {
      _scrollController.dispose();
    }
    _ownedScrollerApi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui.Size viewSize = MediaQuery.sizeOf(context);
    // Inner scrollables hand off to the page only through
    // OverscrollNotification, which bouncing physics never send. Default them
    // to clamping so iOS chains too. Physics set on a scrollable still win.
    final ScrollBehavior childScrollBehavior = ScrollConfiguration.of(
      context,
    ).copyWith(physics: const ClampingScrollPhysics());
    // A full page fills the whole view, so it never lags behind a browser
    // toolbar resize. An embedded view follows the on-screen part of its
    // placeholder.
    final ui.Rect drawRect =
        scrollerApi.isFullPage ? Offset.zero & viewSize : visibleRect;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        drawRect.left,
        drawRect.top,
        max(0, viewSize.width - drawRect.right),
        max(0, viewSize.height - drawRect.bottom),
      ),
      child: NotificationListener<Notification>(
        onNotification: _handleNotification,
        child: Transform.translate(
          offset: Offset(0, -_browserOverscroll),
          child: SizedBox(
            width: drawRect.width,
            height: drawRect.height,
            child: Scrollable(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              scrollBehavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              viewportBuilder: (BuildContext context, ViewportOffset offset) {
                return Viewport(
                  offset: offset,
                  axisDirection: AxisDirection.down,
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: ScrollConfiguration(
                        behavior: childScrollBehavior,
                        child: widget.child,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
