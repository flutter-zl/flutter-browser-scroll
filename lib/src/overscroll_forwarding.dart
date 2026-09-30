// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
