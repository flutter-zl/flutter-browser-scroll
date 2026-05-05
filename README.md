# flutter_browser_scroll

Experimental Flutter Web package that lets the browser own the outermost scroll.

## Acknowledgment

Built on top of [Mouad Debbar's flutter-browser-scroll](https://github.com/mdebbar/flutter-browser-scroll) proof of concept. Thank you.

## Status

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
- Programmatic browser scrolls do not currently synthesize the same `ScrollStartNotification` and `ScrollEndNotification` sequence as Flutter-driven animations.

The package also includes a narrow platform-view and iframe carve-out in its iOS touch guard. This prevents the package from blocking native touch behavior inside embedded DOM content while still avoiding double-scroll for marked inner Flutter scrollables.

## Next Features

- Revealed-content placeholder height for lazy Flutter lists.
- `animateTo` and `jumpTo` delegation to browser scroll.
- Nested Flutter scrollable overscroll forwarding.
- Comprehensive demo coverage for iframes, keyboard scroll, overlays, and programmatic scroll.
