import 'post_editor_screen.dart';

/// Create-post entry point; delegates to [PostEditorScreen].
class CreatePostScreen extends PostEditorScreen {
  const CreatePostScreen({
    super.key,
    required super.auth,
    required super.api,
    super.initialPlaceId,
  });
}
