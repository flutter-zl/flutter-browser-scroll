# flutter_browser_scroll

Experimental Flutter Web package that lets the browser own the outermost scroll.

## Acknowledgment

Built on top of [Mouad Debbar's flutter-browser-scroll](https://github.com/mdebbar/flutter-browser-scroll) proof of concept. Thank you.

## Status

This package is web-only. `BrowserScroller` uses web DOM APIs through its default `JsViewScroller`, so non-web platforms are not supported.

## Demo

A comprehensive A/B demo is deployed:

- **After** (package applied): https://flutter-demo-26-after.web.app
- **Before** (no package, same UI): https://flutter-demo-26-before.web.app

Compare inner-list overscroll chaining, the `RefreshIndicator` flow, iframes and platform views, keyboard scroll, programmatic scroll, and a horizontal carousel between the two URLs. Source at [`example/lib/comprehensive.dart`](example/lib/comprehensive.dart).

## Installation

Until this package is published to pub.dev, add it as a Git dependency:

```yaml
dependencies:
  flutter_browser_scroll:
    git:
      url: https://github.com/flutter-zl/flutter-browser-scroll.git
      ref: main
```

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

No platform-view scroll reimplementation. No wheel interception. The package only adds the small Flutter-side bridges the browser cannot infer from canvas-painted scrollables.

## Behavior differences

Because the browser owns the page scroll, a few things differ from a normal `ScrollController`:

- `animateTo` uses the browser's native smooth scroll. The `duration` and `curve` you pass are ignored.
- Browser scrolls do not emit `ScrollNotification`s. Widgets that depend on them, such as an auto-hiding `Scrollbar` or a FAB that hides on scroll, will not react to page scrolls. Use `controller.addListener` instead.
- Inner scrollables default to `ClampingScrollPhysics` on every platform, so their edge overscroll can hand off to the page. Set `physics` explicitly to override.

## Usage

### Basic page

Wrap your scrollable page content in `BrowserScroller`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_browser_scroll/flutter_browser_scroll.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BrowserScroller(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 100; i++) ListTile(title: Text('Item $i')),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Programmatic scroll

When a button or other widget needs to scroll the page, pass a `BrowserScrollController` to `BrowserScroller`. It works like a normal `ScrollController`.

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BrowserScrollController _controller = BrowserScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BrowserScroller(
          controller: _controller,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 100; i++) ListTile(title: Text('Item $i')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
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
    );
  }
}
```

### Dialogs and bottom sheets

The browser keeps scrolling the page under a Flutter modal unless you tell it not to. Add `BrowserScrollRouteObserver` to freeze the page while any `showDialog`, `showModalBottomSheet`, menu, or dropdown is open:

```dart
MaterialApp(
  navigatorObservers: <NavigatorObserver>[
    BrowserScrollRouteObserver(_controller),
  ],
  home: ...,
)
```

For custom cases, call `_controller.lockPageScroll()` and `unlockPageScroll()` directly. Locks nest, so the page stays frozen until the last one is released.

### Pull-to-refresh inside the page

A plain inner Flutter scrollable inside `BrowserScroller` works without any wrapper. Top-edge overscroll chains to the page during active drag only, so a bounce-back settle does not move the page. Bottom-edge overscroll chains during both drag and the fling that follows it.

For a `RefreshIndicator`, wrap the inner scrollable in `BrowserScrollChild(preserveTopOverscroll: true, ...)` so a pull-down at the top arms refresh instead of scrolling the page:

```dart
RefreshIndicator(
  onRefresh: _onRefresh,
  child: BrowserScrollChild(
    preserveTopOverscroll: true,
    child: ListView.builder(
      primary: false,
      itemCount: 50,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(title: Text('Refresh item $index'));
      },
    ),
  ),
)
```

## Features

- Revealed-content placeholder height for lazy Flutter lists.
- `animateTo` and `jumpTo` delegation to browser scroll.
- Nested Flutter scrollable overscroll forwarding.
- Touches on inner Flutter scrollables do not also pan the page on mobile browsers.
- Page scroll lock for modal routes via `BrowserScrollRouteObserver`.
- Comprehensive demo coverage for iframes, keyboard scroll, overlays, and programmatic scroll.
