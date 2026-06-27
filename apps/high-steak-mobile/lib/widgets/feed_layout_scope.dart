import 'package:flutter/material.dart';

import '../utils/feed_layout_controller.dart';

class FeedLayoutScope extends InheritedNotifier<FeedLayoutController> {
  const FeedLayoutScope({
    super.key,
    required FeedLayoutController super.notifier,
    required super.child,
  });

  static FeedLayoutController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FeedLayoutScope>();
    assert(scope != null, 'FeedLayoutScope not found in widget tree');
    return scope!.notifier!;
  }
}
