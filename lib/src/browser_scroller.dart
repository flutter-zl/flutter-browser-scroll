import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'browser_scroll_child.dart';
import 'browser_scroll_controller.dart';
import 'external_scroller.dart';
import 'js_view_scroller.dart';
import 'overscroll_forwarding.dart';
import 'placeholder_height.dart';

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

  ExternalScroller get scrollerApi => widget.scrollerApi ?? _ownedScrollerApi!;

  late ui.Rect visibleRect;
  double _lastReportedHeight = 0;
  double _pendingOverscrollDelta = 0;
  bool _overscrollFlushScheduled = false;

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

    _ownedScrollerApi = widget.scrollerApi == null
        ? BrowserScroller.debugScrollerFactory(View.of(context).viewId)
        : null;
    _scrollController
      ..scrollerApi = scrollerApi
      ..prepareTarget = _prepareForTarget;

    scrollerApi.setup();

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
    if (_scrollController.hasClients) {
      _scrollController.syncFromBrowser(
        clampDouble(
          scrollerApi.scrollTop,
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
      );
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

  bool _handleOverscrollNotification(OverscrollNotification notification) {
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
        scrollerApi.scrollBy(pendingDelta);
      }
    });
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        visibleRect.left,
        visibleRect.top,
        max(0, viewSize.width - visibleRect.right),
        max(0, viewSize.height - visibleRect.bottom),
      ),
      child: BrowserScrollScope(
        scrollerApi: scrollerApi,
        child: NotificationListener<OverscrollNotification>(
          onNotification: _handleOverscrollNotification,
          child: SizedBox(
            width: visibleRect.width,
            height: visibleRect.height,
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
                  slivers: <Widget>[SliverToBoxAdapter(child: widget.child)],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
