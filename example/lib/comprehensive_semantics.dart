// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'comprehensive.dart';

// Same as comprehensive.dart, with semantics enabled at startup so the web
// engine's tappable-node pointer debouncing can be exercised without a
// screen reader.
void main() {
  registerPlatformViews();
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(const MyApp(useBrowserScroller: true));
}
