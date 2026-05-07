# flutter_browser_scroll example

Sample apps for `flutter_browser_scroll`.

## Run locally

From the package root:

```
cd example
flutter pub get
```

Then pick one entry to run:

- **Minimal page** wrapped in `BrowserScroller`:
  ```
  flutter run -d chrome -t lib/main.dart
  ```
- **Full test suite** with the package applied:
  ```
  flutter run -d chrome -t lib/comprehensive.dart
  ```
- **Same UI without the package** for comparison:
  ```
  flutter run -d chrome -t lib/comprehensive_before.dart
  ```

## Deployed demos

- After (package applied): https://flutter-demo-00-after.web.app
- Before (no package): https://flutter-demo-00-before.web.app
