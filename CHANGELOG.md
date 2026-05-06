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
