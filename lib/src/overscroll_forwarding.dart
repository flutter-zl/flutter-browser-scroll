bool shouldForwardOverscroll({
  required double overscroll,
  required double pixels,
  required double minScrollExtent,
  required double maxScrollExtent,
  bool forwardTopOverscroll = false,
}) {
  if (overscroll.abs() <= 0.5) {
    return false;
  }
  if (!forwardTopOverscroll && overscroll < 0 && pixels <= minScrollExtent) {
    return false;
  }
  return true;
}
