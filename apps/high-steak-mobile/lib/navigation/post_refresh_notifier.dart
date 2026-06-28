import 'package:flutter/material.dart';

/// Broadcasts when post data may be stale so list/detail screens reload.
class PostRefreshNotifier extends ChangeNotifier {
  void markPostsStale() => notifyListeners();
}

class PostRefreshScope extends InheritedNotifier<PostRefreshNotifier> {
  const PostRefreshScope({
    super.key,
    required PostRefreshNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static PostRefreshNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PostRefreshScope>();
    assert(scope != null, 'PostRefreshScope not found in widget tree');
    return scope!.notifier!;
  }

  static PostRefreshNotifier? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PostRefreshScope>()?.notifier;
  }
}

/// Subscribes to [PostRefreshNotifier] and calls [onStale] when posts change.
class PostRefreshSubscription {
  PostRefreshSubscription({
    required BuildContext context,
    required this.onStale,
  }) {
    rebind(context);
  }

  PostRefreshNotifier? _notifier;
  final VoidCallback onStale;

  void rebind(BuildContext context) {
    final next = PostRefreshScope.maybeOf(context);
    if (_notifier == next) return;
    _notifier?.removeListener(onStale);
    _notifier = next;
    _notifier?.addListener(onStale);
  }

  void dispose() {
    _notifier?.removeListener(onStale);
    _notifier = null;
  }
}

void markPostsStale(BuildContext context) {
  PostRefreshScope.maybeOf(context)?.markPostsStale();
}
