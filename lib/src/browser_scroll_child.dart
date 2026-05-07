import 'package:flutter/widgets.dart';

import 'external_scroller.dart';

/// Marks an inner Flutter scrollable as a child of a browser-scrolled page.
///
/// This is required on iOS Safari to prevent the browser from natively panning
/// the document while a Flutter inner scrollable handles the same touch. A
/// `BrowserScrollPhysics` spike showed that making the outer [BrowserScroller]
/// participate in Flutter's gesture arena is not enough: iOS Safari's native
/// pan decision is independent of Flutter's gesture arena, so both systems can
/// scroll simultaneously. See `doc/spikes/browser-scroll-physics-spike.md`
/// for details. Flutter's engine-level browser scrolling work, such as
/// https://github.com/flutter/flutter/pull/184102, can solve this lower in the
/// stack. This package uses an explicit marker instead.
///
/// Use this only for inner Flutter scrollables, such as [ListView], [GridView],
/// and [CustomScrollView]. Do not wrap iframes, platform views, the outer page,
/// or plain non-scrollable content.
///
/// On desktop and Android Chrome this wrapper is not strictly required for
/// plain inner scrollables. On iOS Safari it is required to avoid double-scroll.
class BrowserScrollChild extends StatefulWidget {
  const BrowserScrollChild({
    super.key,
    this.scrollerApi,
    this.preserveTopOverscroll = false,
    required this.child,
  });

  /// The browser scroller used by this child.
  ///
  /// Most apps leave this null so the nearest ancestor `BrowserScroller`
  /// provides the scroller. Pass a value only for tests or custom embedders that
  /// need a different scroller.
  final ExternalScroller? scrollerApi;

  /// Whether top-edge overscroll inside this region should stay with the inner
  /// scrollable instead of chaining to the browser-owned page.
  ///
  /// Set this when the inner scrollable owns top-edge gestures, for example
  /// when it hosts a [RefreshIndicator]. Leave it false for plain inner
  /// scrollables that should let pull-down gestures at the top continue
  /// scrolling the parent page.
  ///
  /// When false, top-edge overscroll forwards to the parent page only during
  /// active drag. Ballistic overscroll from a settle is not forwarded.
  ///
  /// `BrowserScroller` reads this value when deciding whether to forward an
  /// [OverscrollNotification] from a descendant scrollable.
  final bool preserveTopOverscroll;

  /// The inner Flutter scrollable subtree.
  final Widget child;

  @override
  State<BrowserScrollChild> createState() => _BrowserScrollChildState();
}

class _BrowserScrollChildState extends State<BrowserScrollChild> {
  ExternalScroller? _scrollerApi;

  ExternalScroller _scrollerApiFor(BuildContext context) {
    final ExternalScroller? scrollerApi =
        widget.scrollerApi ?? BrowserScrollScope.maybeOf(context);
    assert(
      scrollerApi != null,
      'BrowserScrollChild must be below BrowserScroller or provide '
      'an explicit scrollerApi.',
    );
    return scrollerApi!;
  }

  @override
  void dispose() {
    _scrollerApi?.setNativePanBlocked(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollerApi = _scrollerApiFor(context);
    return BrowserScrollChildScope(
      preserveTopOverscroll: widget.preserveTopOverscroll,
      child: Listener(
        onPointerDown: (_) {
          _scrollerApi!.setNativePanBlocked(true);
        },
        onPointerUp: (_) {
          _scrollerApi!.setNativePanBlocked(false);
        },
        onPointerCancel: (_) {
          _scrollerApi!.setNativePanBlocked(false);
        },
        child: widget.child,
      ),
    );
  }
}

/// Inherited scope that publishes the `BrowserScroller`'s [ExternalScroller] to
/// descendant `BrowserScrollChild` widgets.
///
/// Package-internal: not exported from `flutter_browser_scroll.dart`.
class BrowserScrollScope extends InheritedWidget {
  const BrowserScrollScope({
    super.key,
    required this.scrollerApi,
    required super.child,
  });

  final ExternalScroller scrollerApi;

  static ExternalScroller? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BrowserScrollScope>()
        ?.scrollerApi;
  }

  @override
  bool updateShouldNotify(BrowserScrollScope oldWidget) {
    return oldWidget.scrollerApi != scrollerApi;
  }
}

/// Inherited scope that publishes a [BrowserScrollChild]'s
/// `preserveTopOverscroll` flag to ancestors handling overscroll notifications.
///
/// Package-internal: not exported from `flutter_browser_scroll.dart`.
class BrowserScrollChildScope extends InheritedWidget {
  const BrowserScrollChildScope({
    super.key,
    required this.preserveTopOverscroll,
    required super.child,
  });

  final bool preserveTopOverscroll;

  // Read non-reactively. The overscroll notification handler runs after build,
  // so a transient lookup is enough; we deliberately do not register the
  // notifying context as a dependent.
  static bool shouldPreserveTopOverscroll(BuildContext? context) {
    final scope = context
        ?.getElementForInheritedWidgetOfExactType<BrowserScrollChildScope>()
        ?.widget as BrowserScrollChildScope?;
    return scope?.preserveTopOverscroll ?? false;
  }

  @override
  bool updateShouldNotify(BrowserScrollChildScope oldWidget) => false;
}
