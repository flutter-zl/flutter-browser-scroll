# flutter_browser_scroll

Experimental Flutter Web package that lets the browser own the outermost scroll.

## Acknowledgment

Built on top of [Mouad Debbar's flutter-browser-scroll](https://github.com/mdebbar/flutter-browser-scroll) proof of concept. Thank you.

## Status

This package is web-only. `BrowserScroller` uses web DOM APIs through its default `JsViewScroller`, so non-web platforms are not supported.

This repository is a fresh restart. The first baseline is intentionally small and should stay close to the original proof of concept before adding the production pieces from Flutter PR [#184102](https://github.com/flutter/flutter/pull/184102).

The target mental model:

```
 Browser owns outer scroll
 |
 v
 Package listens to the browser scroll event
 |
 v
 Flutter ScrollController syncs to the reported position
```

No platform-view scroll reimplementation. No wheel interception. The package only adds the small Flutter-side bridges the browser cannot infer from canvas-painted scrollables, plus a narrow touch-event guard so inner Flutter scrollables do not double-scroll the document on iOS Safari.

## Current API caveats

`BrowserScrollController` delegates document movement to the browser. It is close to `ScrollController`, but it is not a perfect drop-in replacement for every timing and notification contract:

- `jumpTo` updates Flutter's attached scroll position synchronously when one exists, then asks the browser to move the document.
- `animateTo` uses browser smooth scrolling for non-zero durations. The browser chooses the exact timing and curve, so custom Flutter `Duration` and `Curve` values are not honored exactly.
- The returned `animateTo` future resolves when the browser reaches the target, appears idle, is superseded, or hits a timeout.
- Programmatic browser scrolls do not synthesize the same `ScrollStartNotification` and `ScrollEndNotification` sequence as Flutter-driven animations. Widgets or app code that depend on those notifications, such as auto-hiding `Scrollbar`s, scroll-aware FABs, or custom refresh/load indicators, may not observe programmatic browser scroll start/end.

The package also includes a narrow platform-view and iframe carve-out in its iOS touch guard. This prevents the package from blocking native touch behavior inside embedded DOM content while still avoiding double-scroll for marked inner Flutter scrollables.

On iOS Safari, wrap inner Flutter scrollables in `BrowserScrollTouchRegion` for reliable touch handoff. The package also has a semantics-based fallback for unmarked inner scrollables, which requires `SemanticsBinding.instance.ensureSemantics()` and may miss inner scrollables that lack the `flt-semantics-scroll-overflow` marker.

## Usage

### Basic page

Use `runWidget` with the current Flutter view, then wrap the outer page content in `BrowserScroller`. The widget creates and disposes the default browser scroller for the current Flutter view. That default scroller is bound to the first `View` where the widget is mounted.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_browser_scroll/flutter_browser_scroll.dart';

void main() {
  runWidget(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return View(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BrowserScroller(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 100; i++) Text('Item $i'),
        ],
      ),
    );
  }
}
```

### Programmatic scroll

Use `BrowserScrollController` when a FAB, button, or service needs to scroll the browser-owned page. Pass the controller to `BrowserScroller`, then call the normal `ScrollController` methods.

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BrowserScrollController _controller = BrowserScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        BrowserScroller(
          controller: _controller,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 100; i++) Text('Item $i'),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              _controller.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: const Icon(Icons.arrow_upward),
          ),
        ),
      ],
    );
  }
}
```

### Inner Flutter scrollables on iOS

When you place a Flutter `ListView` or other scrollable inside the browser-scrolled page, wrap it in `BrowserScrollTouchRegion`. This prevents iOS Safari from panning the document while Flutter is already handling the inner scrollable gesture. At the bottom edge, overscroll is forwarded to the browser-owned parent page.

For a plain inner scrollable, set `forwardTopOverscroll: true` if pull-down gestures at the top should continue scrolling the parent page. Leave it false for scrollables with `RefreshIndicator`, so top-edge overscroll can arm refresh instead of chaining to the page.

```dart
BrowserScroller(
  child: Column(
    children: <Widget>[
      SizedBox(
        height: 400,
        child: BrowserScrollTouchRegion(
          forwardTopOverscroll: true,
          child: ListView.builder(
            primary: false,
            physics: const ClampingScrollPhysics(),
            itemCount: 50,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text('Inner item $index'));
            },
          ),
        ),
      ),
    ],
  ),
)
```

### Advanced custom scroller

Most apps can omit `scrollerApi`. Pass one only when a widget test needs a fake scroller or an embedder scrolls a custom container instead of `window`. `BrowserScroller` calls `setup()` for the provided scroller. When you create the scroller, you also dispose it.

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ExternalScroller? _customScroller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _customScroller ??= JsViewScroller(View.of(context).viewId);
  }

  @override
  void dispose() {
    _customScroller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrowserScroller(
      scrollerApi: _customScroller!,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 100; i++) Text('Item $i'),
        ],
      ),
    );
  }
}
```

## Implemented pieces

- Revealed-content placeholder height for lazy Flutter lists.
- `animateTo` and `jumpTo` delegation to browser scroll.
- Nested Flutter scrollable overscroll forwarding.
- Comprehensive demo coverage for iframes, keyboard scroll, overlays, and programmatic scroll.
