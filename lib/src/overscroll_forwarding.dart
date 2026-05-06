bool shouldForwardOverscroll({
  required double overscroll,
  required double pixels,
  required double minScrollExtent,
  required double maxScrollExtent,
  bool preserveTopOverscroll = false,
  bool isActiveDrag = true,
}) {
  if (overscroll.abs() <= 0.5) {
    return false;
  }
  if (overscroll < 0 && pixels <= minScrollExtent) {
    return !preserveTopOverscroll && isActiveDrag;
  }
  return true;
}
