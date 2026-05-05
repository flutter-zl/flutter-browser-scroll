import 'package:flutter_browser_scroll/src/placeholder_height.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceholderHeightTracker', () {
    test('starts with one viewport of lookahead', () {
      final tracker = PlaceholderHeightTracker();

      final height = tracker.update(
        pixels: 0,
        maxScrollExtent: 3000,
        viewportDimension: 600,
      );

      expect(height, 1200);
      expect(tracker.maxReachedPixels, 0);
      expect(tracker.reachedBottom, isFalse);
    });

    test('grows from the furthest reached pixel plus lookahead', () {
      final tracker = PlaceholderHeightTracker();

      tracker.update(pixels: 0, maxScrollExtent: 3000, viewportDimension: 600);
      final height = tracker.update(
        pixels: 1500,
        maxScrollExtent: 3000,
        viewportDimension: 600,
      );

      expect(height, 2700);
      expect(tracker.maxReachedPixels, 1500);
      expect(tracker.reachedBottom, isFalse);
    });

    test('shrinks lookahead near bottom and latches at bottom', () {
      final tracker = PlaceholderHeightTracker();

      final nearBottom = tracker.update(
        pixels: 2800,
        maxScrollExtent: 3000,
        viewportDimension: 600,
      );
      final bottom = tracker.update(
        pixels: 3000,
        maxScrollExtent: 3000,
        viewportDimension: 600,
      );

      expect(nearBottom, 3600);
      expect(bottom, 3600);
      expect(tracker.reachedBottom, isTrue);

      final backUp = tracker.update(
        pixels: 1000,
        maxScrollExtent: 6000,
        viewportDimension: 600,
      );

      expect(backUp, 4200);
      expect(tracker.reachedBottom, isFalse);
    });

    test('caps max reached pixels when lazy estimate shrinks', () {
      final tracker = PlaceholderHeightTracker();

      tracker.update(
        pixels: 5000,
        maxScrollExtent: 5000,
        viewportDimension: 600,
      );
      final height = tracker.update(
        pixels: 1000,
        maxScrollExtent: 3000,
        viewportDimension: 600,
      );

      expect(tracker.maxReachedPixels, 3000);
      expect(height, 3600);
    });
  });
}
