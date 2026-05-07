import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'external_scroller.dart';

class JsViewScroller implements ExternalScroller {
  JsViewScroller(int viewId)
      : _hostElement = ui_web.views.getHostElement(viewId) as web.HTMLElement;

  final web.HTMLElement _hostElement;

  late final web.HTMLElement _placeholderElement;
  _StyleSnapshot? _hostStyleSnapshot;
  _StyleSnapshot? _bodyStyleSnapshot;
  _StyleSnapshot? _documentElementStyleSnapshot;
  _StyleSnapshot? _fixedViewStyleSnapshot;
  bool _setupComplete = false;

  final web.EventTarget _scrollTarget = web.window;

  late final JSFunction _jsScrollListener = _scrollListener.toJS;
  late final JSFunction _jsTouchStartListener = _touchStartListener.toJS;
  late final JSFunction _jsTouchMoveListener = _touchMoveListener.toJS;
  late final JSFunction _jsTouchEndListener = _touchEndListener.toJS;
  final List<void Function()> _scrollListeners = <void Function()>[];
  final List<RectCallback> _visibleRectListeners = <RectCallback>[];
  web.IntersectionObserver? _observer;
  Completer<void>? _pendingScrollCompleter;
  Timer? _pendingScrollTimeout;
  Timer? _pendingScrollIdleTimer;
  double? _pendingScrollTarget;

  // Two iOS native-pan paths share this "should we preventDefault touchmove?"
  // decision. They are tracked separately so the source of the block stays
  // explicit:
  //   - _blockNativePanForMarkedChild: set by BrowserScrollChild via
  //     setNativePanBlocked on pointerDown / pointerUp.
  //   - _touchStartedInDetectedInnerScrollable: set by the touchstart
  //     listener after walking the DOM for an flt-semantics-scroll-overflow
  //     under the touch point.
  bool _blockNativePanForMarkedChild = false;
  bool _touchStartedInDetectedInnerScrollable = false;
  bool _touchMoveListenerAttached = false;

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
    if (_setupComplete) {
      return;
    }
    _setupComplete = true;

    if (_hostElement.tagName.toLowerCase() == 'body') {
      _setupFullPageBodyHost();
      return;
    }

    _placeholderElement = _hostElement.cloneNode() as web.HTMLElement;
    _placeholderElement
      ..textContent = ''
      ..removeAttribute('flt-view-id')
      ..removeAttribute('style');
    _hostElement.parentElement!.insertBefore(_placeholderElement, _hostElement);

    _hostStyleSnapshot = _StyleSnapshot.capture(_hostElement);
    _fixElementToViewport(_hostElement);
  }

  void _setupFullPageBodyHost() {
    final web.HTMLElement body = web.document.body!;
    final web.HTMLElement documentElement =
        web.document.documentElement! as web.HTMLElement;

    _bodyStyleSnapshot = _StyleSnapshot.capture(body);
    _documentElementStyleSnapshot = _StyleSnapshot.capture(documentElement);

    _placeholderElement = web.document.createElement('div') as web.HTMLElement;
    _placeholderElement.setAttribute('data-browser-scroll-placeholder', 'true');
    _placeholderElement.style
      ..display = 'block'
      ..width = '100%'
      ..height = '100vh'
      ..pointerEvents = 'none';
    body.insertBefore(_placeholderElement, body.firstChild);

    body.style
      ..position = 'static'
      ..inset = ''
      ..overflow = 'visible'
      ..height = 'auto'
      ..touchAction = 'pan-y'
      ..userSelect = '';
    documentElement.style
      ..overflow = 'auto'
      ..height = 'auto';

    body.addEventListener(
      'touchstart',
      _jsTouchStartListener,
      <String, Object>{'passive': true, 'capture': true}.jsify()!,
    );
    body.addEventListener(
      'touchmove',
      _jsTouchMoveListener,
      <String, Object>{'passive': false, 'capture': true}.jsify()!,
    );
    body.addEventListener(
      'touchend',
      _jsTouchEndListener,
      <String, Object>{'passive': true, 'capture': true}.jsify()!,
    );
    body.addEventListener(
      'touchcancel',
      _jsTouchEndListener,
      <String, Object>{'passive': true, 'capture': true}.jsify()!,
    );
    _touchMoveListenerAttached = true;

    final web.Element? flutterView = body.querySelector('flutter-view');
    if (flutterView case final web.HTMLElement view) {
      _fixedViewStyleSnapshot = _StyleSnapshot.capture(view);
      _fixElementToViewport(view);
    }
  }

  void _touchStartListener(web.Event event) {
    _touchStartedInDetectedInnerScrollable =
        _isTouchInsideInnerFlutterScrollable(event);
  }

  void _touchMoveListener(web.Event event) {
    if (_isPlatformViewEvent(event)) {
      return;
    }
    if (!_blockNativePanForMarkedChild &&
        !_touchStartedInDetectedInnerScrollable) {
      return;
    }
    event.preventDefault();
  }

  void _touchEndListener(web.Event event) {
    _touchStartedInDetectedInnerScrollable = false;
  }

  bool _isPlatformViewEvent(web.Event event) {
    for (final web.EventTarget target in event.composedPath().toDart) {
      if (target.isA<web.Element>()) {
        final web.Element element = target as web.Element;
        final String tagName = element.tagName.toLowerCase();
        if (tagName == 'flt-platform-view' || tagName == 'iframe') {
          return true;
        }
      }
    }
    return false;
  }

  bool _isTouchInsideInnerFlutterScrollable(web.Event event) {
    if (!event.isA<web.TouchEvent>()) {
      return false;
    }
    final web.TouchEvent touchEvent = event as web.TouchEvent;
    // TODO: Track touch identifiers individually for multi-touch gestures.
    final web.Touch? touch = touchEvent.changedTouches.item(0);
    if (touch == null) {
      return false;
    }

    final double x = touch.clientX;
    final double y = touch.clientY;
    final double windowHeight = web.window.innerHeight.toDouble();
    final web.NodeList semanticNodes =
        web.document.body!.querySelectorAll('flt-semantics');
    for (int index = 0; index < semanticNodes.length; index++) {
      final web.Node? node = semanticNodes.item(index);
      if (node case final web.HTMLElement element) {
        final web.Element? firstChild = element.firstElementChild;
        if (firstChild?.tagName.toLowerCase() !=
            'flt-semantics-scroll-overflow') {
          continue;
        }

        final web.DOMRect rect = element.getBoundingClientRect();
        final double height = rect.height.toDouble();
        final bool isInnerScrollable = height < windowHeight - 1.0;
        final bool containsTouch = x >= rect.left &&
            x <= rect.right &&
            y >= rect.top &&
            y <= rect.bottom;
        if (isInnerScrollable && containsTouch) {
          return true;
        }
      }
    }
    return false;
  }

  void _fixElementToViewport(web.HTMLElement element) {
    element.style
      ..position = 'fixed'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..bottom = '0'
      ..width = '100%'
      ..height = '100%';
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
    _checkPendingScroll();
  }

  @override
  void updateHeight(double height) {
    _placeholderElement.style
      ..display = 'block'
      ..width = '100%'
      ..height = '${height}px'
      ..pointerEvents = 'none';
  }

  @override
  Future<void> scrollTo(double offset, {bool smooth = false}) {
    _completePendingScroll();

    final double target = max(0, _placeholderElement.offsetTop + offset);
    final Map<String, Object> options = <String, Object>{
      'top': target,
      'behavior': smooth ? 'smooth' : 'auto',
    };
    (web.window).scrollTo(options.jsify()!);

    if (!smooth) {
      return Future<void>.value();
    }

    final Completer<void> completer = Completer<void>();
    _pendingScrollCompleter = completer;
    _pendingScrollTarget = target;
    _pendingScrollTimeout = Timer(const Duration(seconds: 1), () {
      _completePendingScroll();
    });
    return completer.future;
  }

  @override
  void scrollBy(double delta) {
    web.window.scrollBy(
      <String, Object>{'top': delta, 'behavior': 'auto'}.jsify()!,
    );
  }

  @override
  void setNativePanBlocked(bool blocked) {
    _blockNativePanForMarkedChild = blocked;
  }

  void _checkPendingScroll() {
    final double? target = _pendingScrollTarget;
    if (target == null) {
      return;
    }

    if ((web.window.scrollY - target).abs() < 1.0) {
      _completePendingScroll();
      return;
    }

    // Idle detector: if the browser stops firing scroll events but the target
    // was never reached (for example because the page got shorter mid-scroll),
    // resolve the future after a short quiet period instead of waiting for the
    // 1s safety timeout.
    _pendingScrollIdleTimer?.cancel();
    _pendingScrollIdleTimer = Timer(const Duration(milliseconds: 150), () {
      _completePendingScroll();
    });
  }

  void _completePendingScroll() {
    _pendingScrollTimeout?.cancel();
    _pendingScrollTimeout = null;
    _pendingScrollIdleTimer?.cancel();
    _pendingScrollIdleTimer = null;
    _pendingScrollTarget = null;

    final Completer<void>? completer = _pendingScrollCompleter;
    _pendingScrollCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  void dispose() {
    _completePendingScroll();
    _blockNativePanForMarkedChild = false;
    _observer?.disconnect();
    if (_scrollListeners.isNotEmpty) {
      _scrollTarget.removeEventListener('scroll', _jsScrollListener);
    }
    if (_touchMoveListenerAttached) {
      web.document.body?.removeEventListener(
        'touchstart',
        _jsTouchStartListener,
        <String, Object>{'capture': true}.jsify()!,
      );
      web.document.body?.removeEventListener(
        'touchmove',
        _jsTouchMoveListener,
        <String, Object>{'capture': true}.jsify()!,
      );
      web.document.body?.removeEventListener(
        'touchend',
        _jsTouchEndListener,
        <String, Object>{'capture': true}.jsify()!,
      );
      web.document.body?.removeEventListener(
        'touchcancel',
        _jsTouchEndListener,
        <String, Object>{'capture': true}.jsify()!,
      );
      _touchMoveListenerAttached = false;
    }
    _placeholderElement.remove();
    _hostStyleSnapshot?.restore();
    _bodyStyleSnapshot?.restore();
    _documentElementStyleSnapshot?.restore();
    _fixedViewStyleSnapshot?.restore();
    _hostStyleSnapshot = null;
    _bodyStyleSnapshot = null;
    _documentElementStyleSnapshot = null;
    _fixedViewStyleSnapshot = null;
    _setupComplete = false;
  }
}

class _StyleSnapshot {
  _StyleSnapshot({
    required this.element,
    required this.position,
    required this.inset,
    required this.overflow,
    required this.height,
    required this.width,
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
    required this.touchAction,
    required this.userSelect,
  });

  factory _StyleSnapshot.capture(web.HTMLElement element) {
    return _StyleSnapshot(
      element: element,
      position: element.style.position,
      inset: element.style.inset,
      overflow: element.style.overflow,
      height: element.style.height,
      width: element.style.width,
      top: element.style.top,
      left: element.style.left,
      right: element.style.right,
      bottom: element.style.bottom,
      touchAction: element.style.touchAction,
      userSelect: element.style.userSelect,
    );
  }

  final web.HTMLElement element;
  final String position;
  final String inset;
  final String overflow;
  final String height;
  final String width;
  final String top;
  final String left;
  final String right;
  final String bottom;
  final String touchAction;
  final String userSelect;

  void restore() {
    element.style
      ..position = position
      ..inset = inset
      ..overflow = overflow
      ..height = height
      ..width = width
      ..top = top
      ..left = left
      ..right = right
      ..bottom = bottom
      ..touchAction = touchAction
      ..userSelect = userSelect;
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
