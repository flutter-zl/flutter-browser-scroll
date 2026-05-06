import 'package:flutter_browser_scroll/src/overscroll_forwarding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldForwardOverscroll', () {
    test('ignores tiny deltas', () {
      expect(
        shouldForwardOverscroll(
          overscroll: 0.25,
          pixels: 50,
          minScrollExtent: 0,
          maxScrollExtent: 100,
        ),
        isFalse,
      );
    });

    test('forwards overscroll away from exact edges', () {
      expect(
        shouldForwardOverscroll(
          overscroll: 20,
          pixels: 99.9,
          minScrollExtent: 0,
          maxScrollExtent: 100,
        ),
        isTrue,
      );
      expect(
        shouldForwardOverscroll(
          overscroll: -20,
          pixels: 0.1,
          minScrollExtent: 0,
          maxScrollExtent: 100,
        ),
        isTrue,
      );
    });

    test('forwards top-edge overscroll by default', () {
      expect(
        shouldForwardOverscroll(
          overscroll: -20,
          pixels: 0,
          minScrollExtent: 0,
          maxScrollExtent: 100,
        ),
        isTrue,
      );
    });

    test('preserves top-edge overscroll when opted in', () {
      expect(
        shouldForwardOverscroll(
          overscroll: -20,
          pixels: 0,
          minScrollExtent: 0,
          maxScrollExtent: 100,
          preserveTopOverscroll: true,
        ),
        isFalse,
      );
    });

    test('does not forward top-edge ballistic overscroll', () {
      expect(
        shouldForwardOverscroll(
          overscroll: -20,
          pixels: 0,
          minScrollExtent: 0,
          maxScrollExtent: 100,
          isActiveDrag: false,
        ),
        isFalse,
      );
    });

    test('forwards positive overscroll at bottom edge', () {
      expect(
        shouldForwardOverscroll(
          overscroll: 20,
          pixels: 100,
          minScrollExtent: 0,
          maxScrollExtent: 100,
        ),
        isTrue,
      );
    });
  });
}
