// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'comprehensive.dart';

// Same as comprehensive_before.dart, with semantics enabled at startup.
void main() {
  registerPlatformViews();
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(const MyApp(useBrowserScroller: false));
}
