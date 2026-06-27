import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import '../constants/api_constraints.dart';
import '../models/place.dart';
import '../models/review_tag_catalog.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/post_image_picker.dart';
import '../utils/post_validation.dart';
import '../widgets/auth_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/place_picker.dart';
import '../widgets/post_photo_section.dart';
import '../widgets/review_tag_picker.dart';
import '../widgets/star_rating.dart';
import '../widgets/visibility_picker.dart';

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({
    super.key,
    required this.auth,
    required this.api,
    this.postId,
  });

  final AuthController auth;
  final ApiService api;
  final String? postId;

  bool get isEditing => postId != null;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _title = TextEditingController();
  final _comment = TextEditingController();
  final _restaurantName = TextEditingController();
  final _restaurantLocation = TextEditingController();
  final _picker = ImagePicker();

  int _rating = 5;
  PostVisibility _visibility = PostVisibility.public;
  List<String> _keepImageUrls = [];
  List<XFile> _newImages = [];
  List<String> _selectedTagIds = [];
  PlaceSummary? _selectedPlace;
  ReviewTagCatalog? _tagCatalog;
  bool _loading = true;
  bool _loadingTags = true;
  bool _pickingPhotos = false;
  bool _submitting = false;
  String? _error;
  bool _notAllowed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _restoreLostAndroidPhotos();
  }

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    _restaurantName.dispose();
    _restaurantLocation.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadTags(),
      if (widget.isEditing) _loadPost() else Future.value(),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _restoreLostAndroidPhotos() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty || !mounted) return;
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        setState(() => _newImages = [..._newImages, ...files]);
      } else if (response.exception != null) {
        setState(() => _error = pickerErrorMessage(response.exception!));
      }
    } catch (_) {}
  }

  Future<void> _loadTags() async {
    try {
      final catalog = await widget.api.fetchReviewTags();
      if (!mounted) return;
      setState(() {
        _tagCatalog = catalog;
        _loadingTags = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingTags = false;
      });
    }
  }

  Future<void> _loadPost() async {
    try {
      final post = await widget.api.fetchPost(widget.postId!);
      if (!mounted) return;

      if (post.author.id != widget.auth.user?.id) {
        setState(() => _notAllowed = true);
        return;
      }

      _title.text = post.title;
      _comment.text = post.comment ?? '';
      _restaurantName.text = post.restaurantName ?? '';
      _restaurantLocation.text = post.restaurantLocation ?? '';
      setState(() {
        _rating = post.rating;
        _visibility = post.visibility;
        _keepImageUrls = List.of(post.imageUrls);
        _selectedTagIds = post.tags.map((tag) => tag.id).toList();
        _selectedPlace = post.place;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _pickImages() async {
    if (_pickingPhotos) return;

    final remaining = ApiConstraints.maxImagesPerPost -
        _keepImageUrls.length -
        _newImages.length;
    if (remaining <= 0) {
      setState(() {
        _error =
            'You can add up to ${ApiConstraints.maxImagesPerPost} photos per post.';
      });
      return;
    }

    setState(() {
      _pickingPhotos = true;
      _error = null;
    });

    try {
      final picked = await pickPostImagesInteractive(
        context,
        _picker,
        remainingSlots: remaining,
      );
      if (!mounted) return;

      if (picked.isEmpty) {
        setState(() => _pickingPhotos = false);
        return;
      }

      for (final file in picked) {
        final length = await file.length();
        if (length > ApiConstraints.maxImageBytes) {
          setState(() {
            _pickingPhotos = false;
            _error =
                '"${file.name}" is too large. Each image must be ${ApiConstraints.maxImageMb} MB or smaller.';
          });
          return;
        }
      }

      setState(() {
        _newImages = [..._newImages, ...picked];
        _pickingPhotos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pickingPhotos = false;
        _error = pickerErrorMessage(e);
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _keepImageUrls = List.of(_keepImageUrls)..removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages = List.of(_newImages)..removeAt(index));
  }

  bool get _hasPhotos => _keepImageUrls.isNotEmpty || _newImages.isNotEmpty;

  Future<void> _submit() async {
    final validationError = validatePostTitle(_title.text) ??
        validatePostComment(_comment.text) ??
        validateRestaurantName(_restaurantName.text) ??
        validateRestaurantLocation(_restaurantLocation.text) ??
        (widget.isEditing
            ? validatePostImageTotals(_keepImageUrls.length, _newImages.length)
            : validatePostImageCount(_newImages.length));
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final SteakPost post;
      if (widget.isEditing) {
        post = await widget.api.updatePost(
          widget.postId!,
          title: _title.text.trim(),
          comment: _comment.text.trim(),
          rating: _rating,
          keepImageUrls: _keepImageUrls,
          newImages: _newImages,
          restaurantName: _selectedPlace?.name ??
              (_restaurantName.text.trim().isEmpty
                  ? null
                  : _restaurantName.text.trim()),
          restaurantLocation: _selectedPlace?.formattedAddress ??
              (_restaurantLocation.text.trim().isEmpty
                  ? null
                  : _restaurantLocation.text.trim()),
          placeId: _selectedPlace?.id,
          visibility: postVisibilityToApi(_visibility),
          tagIds: _selectedTagIds,
        );
      } else {
        post = await widget.api.createPost(
          title: _title.text.trim(),
          comment: _comment.text.trim(),
          rating: _rating,
          images: _newImages,
          restaurantName: _selectedPlace?.name ??
              (_restaurantName.text.trim().isEmpty
                  ? null
                  : _restaurantName.text.trim()),
          restaurantLocation: _selectedPlace?.formattedAddress ??
              (_restaurantLocation.text.trim().isEmpty
                  ? null
                  : _restaurantLocation.text.trim()),
          placeId: _selectedPlace?.id,
          visibility: postVisibilityToApi(_visibility),
          tagIds: _selectedTagIds,
        );
      }
      if (!mounted) return;
      context.go('/posts/${post.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LoadingState(
        message: widget.isEditing ? 'Loading post…' : 'Preparing form…',
      );
    }

    if (_notAllowed) {
      return ErrorState(
        message: 'You can only edit your own posts.',
        onRetry: () => context.go('/feed'),
      );
    }

    final palette = context.palette;
    final theme = Theme.of(context);
    final isEditing = widget.isEditing;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          isEditing ? 'Edit your steak' : 'Rate your steak',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          isEditing
              ? 'Update photos, rating, tags, or visibility.'
              : 'Upload photos, score the experience, and share where you ate.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          AuthErrorBanner(message: _error!),
          const SizedBox(height: 16),
        ],
        Text(
          'JPEG, PNG, or WebP · max ${ApiConstraints.maxImageMb} MB each',
          style: TextStyle(color: palette.creamMuted, fontSize: 13),
        ),
        if (isDesktopPicker) ...[
          const SizedBox(height: 4),
          Text(
            'On macOS, use the file picker to select images from your Mac.',
            style: TextStyle(color: palette.creamMuted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        PostPhotoSection(
          existingImageUrls: _keepImageUrls,
          newImages: _newImages,
          picking: _pickingPhotos,
          onPick: _pickImages,
          onRemoveExisting: _removeExistingImage,
          onRemoveNew: _removeNewImage,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Ribeye night',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Text('Your rating', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        StarRating(value: _rating, size: 32, onChanged: (v) => setState(() => _rating = v)),
        const SizedBox(height: 16),
        if (_loadingTags)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Loading quick tags…'),
          )
        else if (_tagCatalog != null)
          ReviewTagPicker(
            catalog: _tagCatalog!,
            selectedIds: _selectedTagIds,
            onChanged: (ids) => setState(() => _selectedTagIds = ids),
          ),
        const SizedBox(height: 16),
        PlacePicker(
          api: widget.api,
          value: _selectedPlace,
          onChanged: (place) => setState(() {
            _selectedPlace = place;
            if (place != null) {
              _restaurantName.text = place.name;
              _restaurantLocation.text = place.formattedAddress ?? '';
            }
          }),
        ),
        if (_selectedPlace == null) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _restaurantName,
            decoration: const InputDecoration(
              labelText: 'Restaurant name',
              hintText: 'e.g. The Prime Cut',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _restaurantLocation,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Austin, TX',
            ),
            textInputAction: TextInputAction.next,
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _comment,
          decoration: const InputDecoration(
            labelText: 'Comment',
            hintText: 'Cut, seasoning, grill temp, doneness…',
          ),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 16),
        VisibilityPicker(
          value: _visibility,
          onChanged: (v) => setState(() => _visibility = v),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitting || !_hasPhotos ? null : _submit,
            child: Text(
              _submitting
                  ? (isEditing ? 'Saving…' : 'Posting…')
                  : (isEditing ? 'Save changes' : 'Share to feed'),
            ),
          ),
        ),
      ],
    );
  }
}
