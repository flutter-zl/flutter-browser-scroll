// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'browser_scroll_controller.dart';

/// Freezes the browser page while a modal route is open.
///
/// Add it to `MaterialApp.navigatorObservers` or `Navigator.observers`:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: <NavigatorObserver>[
///     BrowserScrollRouteObserver(controller),
///   ],
/// )
/// ```
///
/// Any [PopupRoute], which covers `showDialog`, `showModalBottomSheet`,
/// menus, and dropdowns, takes a lock on push and releases it on pop. Page
/// routes do not. The page stays frozen until the last popup is gone.
class BrowserScrollRouteObserver extends NavigatorObserver {
  BrowserScrollRouteObserver(this.controller);

  /// The controller whose page is frozen while a popup is open.
  final BrowserScrollController controller;

  final Set<Route<dynamic>> _locked = <Route<dynamic>>{};

  void _lock(Route<dynamic>? route) {
    if (route is PopupRoute && _locked.add(route)) {
      controller.lockPageScroll();
    }
  }

  void _unlock(Route<dynamic>? route) {
    if (route != null && _locked.remove(route)) {
      controller.unlockPageScroll();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _lock(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _unlock(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _unlock(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _unlock(oldRoute);
    _lock(newRoute);
  }
}
