bool shouldForwardOverscroll({
  required double overscroll,
  required double pixels,
  required double minScrollExtent,
  required double maxScrollExtent,
}) {
  if (overscroll.abs() <= 0.5) {
    return false;
  }
  if (overscroll < 0 && pixels <= minScrollExtent) {
    return false;
  }
  return true;
}
