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

No platform-view detection. No wheel or touch interception. Add only the small Flutter-side bridges the browser cannot infer from canvas-painted scrollables.

## Next Features

- Revealed-content placeholder height for lazy Flutter lists.
- `animateTo` and `jumpTo` delegation to browser scroll.
- Nested Flutter scrollable overscroll forwarding.
- Comprehensive demo coverage for iframes, keyboard scroll, overlays, and programmatic scroll.
