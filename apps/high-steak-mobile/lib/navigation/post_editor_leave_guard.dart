import 'package:flutter/material.dart';

/// Coordinates unsaved-change prompts for post create/edit across PopScope,
/// go_router [GoRoute.onExit], and shell navigation (tabs, app bar back).
class PostEditorLeaveGuard extends ChangeNotifier {
  bool _active = false;
  bool _isDirty = false;
  bool _allowLeave = false;
  Future<bool> Function()? _confirmLeave;

  bool get shouldBlockLeave => _active && _isDirty && !_allowLeave;

  void bindEditor({
    required bool isDirty,
    required bool allowLeave,
    required Future<bool> Function() confirmLeave,
  }) {
    _active = true;
    _isDirty = isDirty;
    _allowLeave = allowLeave;
    _confirmLeave = confirmLeave;
    notifyListeners();
  }

  void unbindEditor() {
    _active = false;
    _isDirty = false;
    _allowLeave = false;
    _confirmLeave = null;
    notifyListeners();
  }

  Future<bool> requestLeave() async {
    if (!shouldBlockLeave) return true;
    return _confirmLeave?.call() ?? true;
  }
}

class PostEditorLeaveScope extends InheritedNotifier<PostEditorLeaveGuard> {
  const PostEditorLeaveScope({
    super.key,
    required PostEditorLeaveGuard notifier,
    required super.child,
  }) : super(notifier: notifier);

  static PostEditorLeaveGuard of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PostEditorLeaveScope>();
    assert(scope != null, 'PostEditorLeaveScope not found in widget tree');
    return scope!.notifier!;
  }

  static PostEditorLeaveGuard? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PostEditorLeaveScope>()
        ?.notifier;
  }
}

bool isPostEditorPath(String path) =>
    path == '/post/new' || (path.startsWith('/posts/') && path.endsWith('/edit'));

Future<bool> confirmPostEditorLeave(BuildContext context) {
  final guard = PostEditorLeaveScope.maybeOf(context);
  if (guard == null) return Future.value(true);
  return guard.requestLeave();
}
