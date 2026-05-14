# flutter_browser_scroll

Experimental Flutter Web package that lets the browser own the outermost scroll.

## Acknowledgment

Built on top of [Mouad Debbar's flutter-browser-scroll](https://github.com/mdebbar/flutter-browser-scroll) proof of concept. Thank you.

## Status

This package is web-only. `BrowserScroller` uses web DOM APIs through its default `JsViewScroller`, so non-web platforms are not supported.

The package is a polyfill-style bridge for browser-driven scrolling while Flutter's engine-level work, such as [flutter/flutter#184102](https://github.com/flutter/flutter/pull/184102), continues to evolve.

## Demo

A comprehensive A/B demo is deployed:

- **After** (package applied): https://flutter-demo-26-after.web.app
- **Before** (no package, same UI): https://flutter-demo-26-before.web.app

Compare inner-list overscroll chaining, the `RefreshIndicator` flow, iframes and platform views, keyboard scroll, and programmatic scroll between the two URLs. Source at [`example/lib/comprehensive.dart`](example/lib/comprehensive.dart).

An earlier snapshot with the iOS Safari/Chrome touch-listener fix is on the [`with-touch-listeners`](https://github.com/flutter-zl/flutter-browser-scroll/tree/with-touch-listeners) branch, with its demo at https://flutter-demo-00-after.web.app and https://flutter-demo-00-before.web.app.

## Installation

Until this package is published to pub.dev, add it as a Git dependency:

```yaml
dependencies:
  flutter_browser_scroll:
    git:
      url: https://github.com/flutter-zl/flutter-browser-scroll.git
      ref: v0.1.0
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

## Things to know

The browser, not Flutter, drives the page scroll. That makes the page feel native, but two things behave differently from a normal `ScrollController`:

- **`animateTo` uses the browser's smooth scroll.** You can still pass a `Duration` and a `Curve`, but the browser picks the actual timing and easing. The same call can look slightly different in Chrome, Safari, and Firefox.
- **Flutter does not see "scroll started" or "scroll ended" events for browser scrolls.** Widgets that rely on those events, such as the auto-hiding `Scrollbar`, scroll-aware FABs, and custom refresh or load indicators, may not react when the user scrolls the page or when `animateTo` runs.

For inner Flutter scrollables, like a `ListView` placed inside the page, no extra setup is needed on desktop or Android: top-edge and bottom-edge overscroll chain to the page automatically. If your inner scrollable hosts a `RefreshIndicator`, wrap it in `BrowserScrollChild(preserveTopOverscroll: true, ...)` so the pull-down arms refresh instead of chaining to the page.

## Known limitations

On mobile browsers, a nested Flutter scrollable inside the browser-scrolled page can double-scroll: the browser pans the document while Flutter also scrolls the inner list. This is a touch-event ordering issue between the browser and Flutter that this package does not paper over in v0.1.0. Desktop browsers do not show the issue.

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

### Pull-to-refresh inside the page

A plain inner Flutter scrollable inside `BrowserScroller` works without any wrapper: top-edge and bottom-edge overscroll chain to the page during active drag.

For a `RefreshIndicator`, wrap the inner scrollable in `BrowserScrollChild(preserveTopOverscroll: true, ...)` so a pull-down at the top arms refresh instead of scrolling the page:

```dart
RefreshIndicator(
  onRefresh: _onRefresh,
  child: BrowserScrollChild(
    preserveTopOverscroll: true,
    child: ListView.builder(
      primary: false,
      physics: const ClampingScrollPhysics(),
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
- Comprehensive demo coverage for iframes, keyboard scroll, overlays, and programmatic scroll.
