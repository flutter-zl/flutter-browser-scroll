import 'package:flutter/widgets.dart';

/// Marks an inner Flutter scrollable as a child of a browser-scrolled page so
/// its top-edge overscroll routing can be customized.
///
/// The only knob is [preserveTopOverscroll], used when the inner scrollable
/// owns top-edge gestures (for example because it hosts a [RefreshIndicator]).
/// Without this wrapper, top-edge overscroll from a plain inner list chains to
/// the browser-owned page during active drag, which is the right default for
/// most lists.
///
/// Use this only for inner Flutter scrollables, such as [ListView], [GridView],
/// and [CustomScrollView]. Do not wrap iframes, platform views, the outer page,
/// or plain non-scrollable content.
class BrowserScrollChild extends StatelessWidget {
  const BrowserScrollChild({
    super.key,
    this.preserveTopOverscroll = false,
    required this.child,
  });

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
  Widget build(BuildContext context) {
    return BrowserScrollChildScope(
      preserveTopOverscroll: preserveTopOverscroll,
      child: child,
    );
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
