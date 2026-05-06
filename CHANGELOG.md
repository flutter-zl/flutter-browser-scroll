## 0.1.0

* Breaking change: top-edge overscroll inside `BrowserScrollChild` now
  chains to the browser-owned parent page by default.
* Added `BrowserScrollChild.preserveTopOverscroll` for inner scrollables
  that own top-edge gestures, such as `RefreshIndicator`.
* Top-edge chaining is limited to active drag overscroll to avoid forwarding
  bounce-back ballistic overscroll.

## 0.0.1

* Initial experimental browser-driven scrolling package.
