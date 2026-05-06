import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'comprehensive.dart';

void main() {
  registerPlatformViews();
  runApp(const MyApp(useBrowserScroller: false));
  SemanticsBinding.instance.ensureSemantics();
}
