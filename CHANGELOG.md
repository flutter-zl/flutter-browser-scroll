## Unreleased

* Added `BrowserScrollController.lockPageScroll` and `unlockPageScroll` to
  freeze the page for wheel, trackpad, touch, and keyboard input, and
  `BrowserScrollRouteObserver` to do so automatically while a `PopupRoute`
  is open.
* `ExternalScroller` gained `setPageScrollLocked`. The default is a no-op, so
  existing implementations keep compiling but do not freeze the page.
* `JsViewScroller` now sets `scrollbar-gutter: stable` on the document so a
  page lock does not shift content sideways on desktop.
* Overscroll from horizontal inner scrollables no longer scrolls the page.
  Only vertical overscroll is forwarded.
* `BrowserScrollController.animateTo` now completes immediately when the page
  is already at the target instead of waiting for the one-second safety
  timeout.
* Touches that start on an inner vertical Flutter scrollable no longer also
  pan the page on mobile browsers. `BrowserScroller` hit-tests each touch-down
  and cancels the browser's pan for that touch.
* While a finger that started on an inner list is still down, handoff moves
  the page in Flutter only, and the browser's scroll position catches up when
  the finger lifts. Scrolling the window under a held finger made iOS WebKit
  report stale pointer positions, which showed as the inner list stepping
  back a few pixels during the handoff.
* Inner scrollables inside `BrowserScroller` now default to
  `ClampingScrollPhysics`, so overscroll hands off to the page on iOS too. A
  scrollable that sets its own `physics` keeps them.
* A full-page `BrowserScroller` now draws into the whole Flutter view instead
  of the on-screen part of its placeholder, so it no longer lags behind a
  browser toolbar resize. During a browser rubber-band bounce past either end,
  the content now moves with the page instead of being clipped.
* `ExternalScroller` gained `isFullPage`. The default is `false`, which keeps
  the embedded behavior.

## 0.1.0

* Breaking change: renamed `BrowserScrollTouchRegion` to
  `BrowserScrollChild`.
* Breaking change: top-edge overscroll inside `BrowserScrollChild` now
  chains to the browser-owned parent page by default.
* Added `BrowserScrollChild.preserveTopOverscroll` for inner scrollables
  that own top-edge gestures, such as `RefreshIndicator`.
* Top-edge chaining is limited to active drag overscroll to avoid forwarding
  bounce-back ballistic overscroll.
* Bottom-edge overscroll still forwards drag and ballistic overscroll to the
  browser-owned parent page.
* `BrowserScrollController.syncFromBrowser` now uses `forcePixels` so browser
  scroll events do not cancel an active Flutter drag.

## 0.0.1

* Initial experimental browser-driven scrolling package.
