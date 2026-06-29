import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/explore_location_service.dart';
import 'cached_api_image.dart';
import '../utils/explore_location_store.dart';

class PlacePicker extends StatefulWidget {
  const PlacePicker({
    super.key,
    required this.api,
    required this.value,
    required this.onChanged,
    this.hideLabel = false,
    this.label = 'Restaurant',
    this.placeholder,
    this.hideFooterHint = false,
    this.maxSuggestionsHeight,
    this.overlaySuggestions = false,
    this.compactSelectedPreview = false,
  });

  final ApiService api;
  final PlaceSummary? value;
  final ValueChanged<PlaceSummary?> onChanged;
  final bool hideLabel;
  final String label;
  final String? placeholder;
  final bool hideFooterHint;
  final double? maxSuggestionsHeight;
  /// Renders autocomplete results in an overlay so they do not expand the parent column.
  final bool overlaySuggestions;
  /// Skips the large photo card for a selected place (use on map-first screens).
  final bool compactSelectedPreview;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  final _controller = TextEditingController();
  final _fieldAnchorKey = GlobalKey();
  final _fieldLink = LayerLink();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _resolving = false;
  String? _error;
  double? _lat;
  double? _lng;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value?.name ?? '';
    unawaited(_loadLocationBias());
  }

  @override
  void didUpdateWidget(covariant PlacePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value?.id != oldWidget.value?.id) {
      _controller.text = widget.value?.name ?? '';
    }
    if (oldWidget.overlaySuggestions != widget.overlaySuggestions) {
      _hideSuggestionsOverlay();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.overlaySuggestions && _suggestions.isNotEmpty) {
      _syncSuggestionsOverlay();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideSuggestionsOverlay();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLocationBias() async {
    final cached = await ExploreLocationStore.readCoords();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _lat = cached.lat;
        _lng = cached.lng;
      });
    }
    unawaited(_refreshLocationBias());
  }

  Future<void> _refreshLocationBias() async {
    final coords = await loadPlaceSearchBias();
    if (!mounted || coords == null) return;
    setState(() {
      _lat = coords.lat;
      _lng = coords.lng;
    });
  }

  void _onQueryChanged(String query) {
    if (widget.value != null && query.trim() == widget.value!.name.trim()) {
      setState(() {
        _suggestions = [];
        _error = null;
      });
      _syncSuggestionsOverlay();
      return;
    }

    widget.onChanged(null);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _error = null;
      });
      _syncSuggestionsOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final results = await widget.api.autocompletePlaces(
          query.trim(),
          lat: _lat,
          lng: _lng,
        );
        if (!mounted) return;
        setState(() => _suggestions = results);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _error = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() => _loading = false);
          _syncSuggestionsOverlay();
        }
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _hideSuggestionsOverlay();
    setState(() {
      _resolving = true;
      _error = null;
      _suggestions = [];
    });
    try {
      final place = await widget.api.resolvePlace({
        'provider': suggestion.provider,
        'providerPlaceId': suggestion.providerPlaceId,
        if (suggestion.name.isNotEmpty) 'name': suggestion.name,
        if (suggestion.formattedAddress != null)
          'formattedAddress': suggestion.formattedAddress,
        if (suggestion.latitude != null) 'latitude': double.parse(suggestion.latitude!),
        if (suggestion.longitude != null) 'longitude': double.parse(suggestion.longitude!),
      });
      if (!mounted) return;
      widget.onChanged(place);
      _controller.text = place.name;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _clearSelection() {
    widget.onChanged(null);
    _controller.clear();
    setState(() => _suggestions = []);
    _hideSuggestionsOverlay();
  }

  double _resolvedSuggestionsHeight(BuildContext context) {
    if (widget.maxSuggestionsHeight != null) {
      return widget.maxSuggestionsHeight!;
    }
    final media = MediaQuery.of(context);
    final visibleHeight = media.size.height - media.viewInsets.bottom;
    return (visibleHeight * 0.28).clamp(120.0, 220.0);
  }

  void _syncSuggestionsOverlay() {
    if (!widget.overlaySuggestions) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_suggestions.isEmpty) {
        _hideSuggestionsOverlay();
        return;
      }
      _showSuggestionsOverlay();
    });
  }

  void _hideSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay() {
    if (!mounted || _suggestions.isEmpty) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final anchorContext = _fieldAnchorKey.currentContext;
    final anchorBox = anchorContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null || !anchorBox.hasSize) return;

    final palette = context.palette;
    final maxHeight = _resolvedSuggestionsHeight(context);
    final width = anchorBox.size.width;

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() => _suggestions = []);
                  _hideSuggestionsOverlay();
                },
              ),
            ),
            CompositedTransformFollower(
              link: _fieldLink,
              showWhenUnlinked: false,
              offset: Offset(0, anchorBox.size.height + 4),
              child: Material(
                elevation: 8,
                color: palette.charcoalLight,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
                  child: _buildSuggestionsList(palette),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _overlayEntry!.markNeedsBuild();
  }

  Widget _buildSuggestionTile(PlaceSuggestion suggestion) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: suggestion.previewPhotoUrl == null
          ? null
          : _googlePhoto(suggestion.previewPhotoUrl!, size: 40),
      title: Text(
        suggestion.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: suggestion.formattedAddress == null
          ? null
          : Text(
              suggestion.formattedAddress!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => _selectSuggestion(suggestion),
    );
  }

  Widget _buildSuggestionsList(AppPalette palette) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: palette.cardBorder.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, index) => _buildSuggestionTile(_suggestions[index]),
    );
  }

  Widget _googlePhoto(String photoUrl, {double size = 48}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedApiImage(
            imageUrl: photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: CachedApiImage.memCacheWidth(context, size),
            cacheHeight: CachedApiImage.memCacheHeight(context, size),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('© Google', style: TextStyle(color: Colors.white, fontSize: 8)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final showInlineSuggestions =
        _suggestions.isNotEmpty && !widget.overlaySuggestions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          key: _fieldAnchorKey,
          link: _fieldLink,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: widget.hideLabel ? null : widget.label,
                    hintText: widget.placeholder ?? 'Search restaurants near you',
                  ),
                  onChanged: _onQueryChanged,
                  onTap: () {
                    if (widget.overlaySuggestions && _suggestions.isNotEmpty) {
                      _syncSuggestionsOverlay();
                    }
                  },
                  enabled: !_resolving,
                ),
              ),
              if (widget.value != null) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: _clearSelection, child: const Text('Clear')),
              ],
            ],
          ),
        ),
        if (_loading || _resolving)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Searching…', style: TextStyle(color: palette.creamMuted, fontSize: 13)),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.errorText),
            ),
          ),
        if (widget.value?.previewPhotoUrl != null && !widget.compactSelectedPreview)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _googlePhoto(widget.value!.previewPhotoUrl!, size: 72),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.value!.name, style: theme.textTheme.titleSmall),
                        if (widget.value!.formattedAddress != null)
                          Text(
                            widget.value!.formattedAddress!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: palette.creamMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (widget.value?.formattedAddress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.value!.formattedAddress!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.creamMuted, fontSize: 13),
            ),
          ),
        if (showInlineSuggestions)
          Card(
            margin: const EdgeInsets.only(top: 8),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _resolvedSuggestionsHeight(context),
              ),
              child: _buildSuggestionsList(palette),
            ),
          ),
        if (!widget.hideFooterHint && widget.value == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.placeholder != null
                  ? 'Pick a restaurant from map search, or leave blank and type the name below.'
                  : 'Pick a place from search, or leave blank and type the name below.',
              style: TextStyle(color: palette.creamMuted, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
