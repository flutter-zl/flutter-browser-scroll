import 'dart:math' as math;

/// Computes the DOM placeholder height for browser-driven scrolling.
///
/// Flutter's lazy lists often start with an inaccurate [maxScrollExtent]. This
/// tracker reports only the content the user has reached plus one viewport of
/// lookahead, then latches once the real bottom has been reached.
class PlaceholderHeightTracker {
  double _maxReachedPixels = 0;
  bool _reachedBottom = false;

  bool get reachedBottom => _reachedBottom;

  double get maxReachedPixels => _maxReachedPixels;

  double update({
    required double pixels,
    required double maxScrollExtent,
    required double viewportDimension,
  }) {
    final double maxExtent = math.max(0, maxScrollExtent);
    final double viewport = math.max(0, viewportDimension);
    final double clampedPixels = pixels.clamp(0, maxExtent).toDouble();

    if (maxExtent > _maxReachedPixels + 1.0) {
      _reachedBottom = false;
    }

    if (clampedPixels > _maxReachedPixels) {
      _maxReachedPixels = clampedPixels;
    }
    if (_maxReachedPixels > maxExtent) {
      _maxReachedPixels = maxExtent;
    }

    if (clampedPixels >= maxExtent - 1.0) {
      _reachedBottom = true;
    }

    final double lookahead = _reachedBottom
        ? 0
        : (maxExtent - _maxReachedPixels).clamp(0, viewport).toDouble();
    return _maxReachedPixels + viewport + lookahead;
  }
}
