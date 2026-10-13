import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/main.dart' show routeObserver;

/// Mix into a screen's [State] so its data is reloaded whenever a screen
/// pushed on top of it is popped — changes made there are then visible
/// without a manual refresh. Only full-page routes count (the app-wide
/// [routeObserver] ignores dialogs, dropdown menus and bottom sheets), so
/// opening a popup never wipes the screen's filters or form state.
mixin RefreshOnReturn<T extends StatefulWidget> on State<T> implements RouteAware {
  /// Reload the screen's data (usually `_load()`).
  void onReturnedTo();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => onReturnedTo();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
