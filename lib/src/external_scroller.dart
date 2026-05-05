import 'dart:js_interop';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class BrowserScroller extends StatefulWidget {
  const BrowserScroller({
    super.key,
    required this.scrollerApi,
    required this.child,
  });

  final ExternalScroller scrollerApi;
  final Widget child;

  @override
  State<BrowserScroller> createState() => _BrowserScrollerState();
}

class _BrowserScrollerState extends State<BrowserScroller> {
  final ScrollController _scrollController = ScrollController();

  ExternalScroller get scrollerApi => widget.scrollerApi;

  late ui.Rect visibleRect;

  @override
  void initState() {
    super.initState();

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
      _scrollController.jumpTo(
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
    scrollerApi.updateHeight(_scrollController.position.extentTotal);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    );
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

  void dispose();
}

class JsViewScroller implements ExternalScroller {
  JsViewScroller(int viewId)
      : _hostElement = ui_web.views.getHostElement(viewId) as web.HTMLElement;

  final web.HTMLElement _hostElement;

  late final web.HTMLElement _placeholderElement;

  final web.EventTarget _scrollTarget = web.window;

  late final JSFunction _jsScrollListener = _scrollListener.toJS;
  final List<void Function()> _scrollListeners = <void Function()>[];
  final List<RectCallback> _visibleRectListeners = <RectCallback>[];
  web.IntersectionObserver? _observer;

  ui.Rect _lastVisibleRect = ui.Rect.zero;

  @override
  ui.Rect computeVisibleRect() {
    final ui.Rect placeholderRect =
        _placeholderElement.getBoundingClientRect().toRect();
    final double windowWidth = web.window.innerWidth.toDouble();
    final double windowHeight = web.window.innerHeight.toDouble();
    return placeholderRect.intersect(
      ui.Rect.fromLTWH(0, 0, windowWidth, windowHeight),
    );
  }

  @override
  void setup() {
    _placeholderElement = _hostElement.cloneNode() as web.HTMLElement;
    _hostElement.parentElement!.insertBefore(_placeholderElement, _hostElement);

    _hostElement.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..bottom = '0';
  }

  @override
  double get scrollTop {
    if (_scrollTarget.isA<web.Window>()) {
      return (_scrollTarget as web.Window).scrollY -
          _placeholderElement.offsetTop;
    }
    return (_scrollTarget as web.HTMLElement).scrollTop -
        _placeholderElement.offsetTop;
  }

  @override
  void addVisibleRectListener(RectCallback callback) {
    if (_visibleRectListeners.isEmpty) {
      addScrollListener(_visibleRectListener);
      _addIntersectionObserver(_visibleRectListener);
    }
    _visibleRectListeners.add(callback);
  }

  void _visibleRectListener() {
    final ui.Rect newVisibleRect = computeVisibleRect();

    if (_lastVisibleRect != newVisibleRect) {
      _lastVisibleRect = newVisibleRect;
      for (final RectCallback listener in _visibleRectListeners) {
        listener(newVisibleRect);
      }
    }
  }

  void _addIntersectionObserver(ui.VoidCallback callback) {
    _observer = web.IntersectionObserver(
      (JSArray entries, JSAny observer) {
        for (final web.IntersectionObserverEntry entry
            in entries.toDart.cast<web.IntersectionObserverEntry>()) {
          if (entry.isIntersecting) {
            callback();
          }
        }
      }.toJS,
      web.IntersectionObserverInit(
        threshold: <JSNumber>[
          for (int i = 0; i <= 100; i++) (i / 100).toJS,
        ].toJS,
      ),
    );

    _observer!.observe(_placeholderElement);
  }

  @override
  void addScrollListener(void Function() callback) {
    if (_scrollListeners.isEmpty) {
      _scrollTarget.addEventListener('scroll', _jsScrollListener);
    }
    _scrollListeners.add(callback);
  }

  void _scrollListener() {
    for (final void Function() listener in _scrollListeners) {
      listener();
    }
  }

  @override
  void updateHeight(double height) {
    _placeholderElement.style.height = '${height}px';
  }

  @override
  void dispose() {
    _observer?.disconnect();
    if (_scrollListeners.isNotEmpty) {
      _scrollTarget.removeEventListener('scroll', _jsScrollListener);
    }
  }
}

extension on web.DOMRect {
  ui.Rect toRect() {
    return ui.Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
  }
}
