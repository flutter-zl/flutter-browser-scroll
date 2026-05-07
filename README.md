# flutter_browser_scroll

Experimental Flutter Web package that lets the browser own the outermost scroll.

## Acknowledgment

Built on top of [Mouad Debbar's flutter-browser-scroll](https://github.com/mdebbar/flutter-browser-scroll) proof of concept. Thank you.

## Status

This package is web-only. `BrowserScroller` uses web DOM APIs through its default `JsViewScroller`, so non-web platforms are not supported.

The package is a polyfill-style bridge for browser-driven scrolling while Flutter's engine-level work, such as [flutter/flutter#184102](https://github.com/flutter/flutter/pull/184102), continues to evolve.

## Demo

A comprehensive A/B demo is deployed:

- **After** (package applied): https://flutter-demo-00-after.web.app
- **Before** (no package, same UI): https://flutter-demo-00-before.web.app

Compare TEST 1 (inner list chaining), TEST 3 (`RefreshIndicator`), and inner-list touch on iOS Safari. Source at [`example/lib/comprehensive.dart`](example/lib/comprehensive.dart).

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

No platform-view scroll reimplementation. No wheel interception. The package only adds the small Flutter-side bridges the browser cannot infer from canvas-painted scrollables, plus a narrow touch-event guard so inner Flutter scrollables do not double-scroll the document on iOS Safari.

## Things to know

The browser, not Flutter, drives the page scroll. That makes the page feel native, but two things behave differently from a normal `ScrollController`:

- **`animateTo` uses the browser's smooth scroll.** You can still pass a `Duration` and a `Curve`, but the browser picks the actual timing and easing. The same call can look slightly different in Chrome, Safari, and Firefox.
- **Flutter does not see "scroll started" or "scroll ended" events for browser scrolls.** Widgets that rely on those events, such as the auto-hiding `Scrollbar`, scroll-aware FABs, and custom refresh or load indicators, may not react when the user scrolls the page or when `animateTo` runs.

For inner Flutter scrollables, like a `ListView` placed inside the page:

- On desktop and Android Chrome, no extra setup is needed. Overscroll at the bottom of the inner list chains to the page.
- On iOS Safari, wrap the inner scrollable in `BrowserScrollChild`. Without it, the browser tries to pan the page at the same time Flutter is handling the gesture, which feels like a double-scroll.

Once Flutter's engine-level browser scrolling work, such as [flutter/flutter#184102](https://github.com/flutter/flutter/pull/184102), lands, `BrowserScrollChild` will not be needed.

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

### Inner Flutter scrollables on iOS

Wrap inner Flutter scrollables, such as `ListView`, `GridView`, or `CustomScrollView`, in `BrowserScrollChild`. This stops iOS Safari from panning the page while Flutter handles the inner gesture. By default, overscroll at either edge chains to the page.

Do not wrap iframes, platform views, or non-scrollable content.

If the inner scrollable hosts a `RefreshIndicator`, pass `preserveTopOverscroll: true` so a pull-down arms refresh instead of scrolling the page.

```dart
BrowserScroller(
  child: Column(
    children: <Widget>[
      SizedBox(
        height: 400,
        child: BrowserScrollChild(
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

For a pull-to-refresh list:

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
