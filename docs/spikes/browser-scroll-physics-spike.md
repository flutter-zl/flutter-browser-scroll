# BrowserScrollPhysics Spike Result

## Goal

Test whether a package-local `BrowserScrollPhysics` can remove the need for
`BrowserScrollChild` by making the outer `BrowserScroller` participate in
Flutter's gesture arena, similar to Flutter PR
https://github.com/flutter/flutter/pull/184102.

## Spike Changes

Branch: `zl/spike-browser-scroll-physics`

Implemented:

- Added internal `BrowserScrollPhysics`.
- Replaced outer `BrowserScroller` physics from `NeverScrollableScrollPhysics`
  to `BrowserScrollPhysics`.
- Changed browser-to-Flutter sync from `jumpTo` to `forcePixels`.
- Preserved exact top and bottom edge overscroll, closer to the PR behavior.
- Removed `BrowserScrollChild` from TEST 1 only.
- Added debug logs for browser touch events, browser scroll events, outer scroll
  physics, overscroll forwarding, and TEST 1 inner scroll notifications.

## Manual Result

The spike does not remove the need for `BrowserScrollChild` on iOS Safari.

Observed in TEST 1:

```text
touchstart inner=false blockNativePan=false
|
v
touchmove allow native pan
|
v
TEST 1 inner ListView scrolls
|
v
browser scroll event also fires
|
v
syncFromBrowser updates outer position
```

So both systems move during the same touch:

- Flutter scrolls the inner `ListView`.
- iOS Safari also pans the browser document.

That is the original double-scroll problem.

## Important Log Evidence

Inner list scrolls:

```text
[Test1Scroll] ... pixels=... drag=true
```

Browser also scrolls during the same gesture:

```text
[BrowserScroll] touchmove allow native pan inner=false blockNativePan=false
[BrowserScroll] browser scroll event scrollTop=...
[BrowserScroll] syncFromBrowser raw=... target=... current=...
```

Outer `BrowserScrollPhysics` does participate later:

```text
[BrowserScrollPhysics] applyUserOffset ...
[BrowserScrollPhysics] boundary ... overscroll=...
[BrowserScroll] overscroll ... forward=true
[BrowserScroll] window.scrollBy ...
```

But native browser pan is still allowed at the same time:

```text
touchmove allow native pan inner=false blockNativePan=false
```

This creates two parent-scroll sources:

```text
browser native pan
+
BrowserScrollPhysics overscroll forwarding
=
shaky / double parent scroll
```

## Conclusion

`BrowserScrollPhysics` alone is not enough for the package.

It helps the outer Flutter `Scrollable` participate in Flutter's gesture system,
but it does not stop iOS Safari from natively panning the document when the
touch starts inside a canvas-painted Flutter inner list.

The package still needs an explicit way to block native pan for inner Flutter
scrollables on iOS Safari. Today that is `BrowserScrollChild`.

## Recommendation

Abandon the spike as a marker-removal path.

Keep the marker-based API:

```dart
BrowserScrollChild(
  child: ListView(...),
)
```

Use the newer API direction for refresh cases:

```dart
BrowserScrollChild(
  preserveTopOverscroll: true,
  child: ListView.builder(...),
)
```

Keep `forcePixels` as a useful fix, because browser-to-Flutter sync should not
cancel active drag activity.

Do not keep `BrowserScrollPhysics` for the marker-removal goal unless we find a
separate reason it improves behavior with the marker still present.
