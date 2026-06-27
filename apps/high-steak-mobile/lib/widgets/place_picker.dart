import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';

class PlacePicker extends StatefulWidget {
  const PlacePicker({
    super.key,
    required this.api,
    required this.value,
    required this.onChanged,
  });

  final ApiService api;
  final PlaceSummary? value;
  final ValueChanged<PlaceSummary?> onChanged;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _resolving = false;
  String? _error;
  double? _lat;
  double? _lng;

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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLocationBias() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (_) {}
  }

  void _onQueryChanged(String query) {
    widget.onChanged(null);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _error = null;
      });
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
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
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
  }

  Widget _googlePhoto(String photoUrl, {double size = 48}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            resolveApiImageUrl(photoUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Restaurant',
                  hintText: 'Search restaurants near you',
                ),
                onChanged: _onQueryChanged,
                enabled: !_resolving,
              ),
            ),
            if (widget.value != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: _clearSelection, child: const Text('Clear')),
            ],
          ],
        ),
        if (_loading || _resolving)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Searching…', style: TextStyle(color: palette.creamMuted, fontSize: 13)),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: palette.errorText)),
          ),
        if (widget.value?.previewPhotoUrl != null)
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
              style: TextStyle(color: palette.creamMuted, fontSize: 13),
            ),
          ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: _suggestions
                  .map(
                    (suggestion) => ListTile(
                      leading: suggestion.previewPhotoUrl == null
                          ? null
                          : _googlePhoto(suggestion.previewPhotoUrl!, size: 48),
                      title: Text(suggestion.name),
                      subtitle: suggestion.formattedAddress == null
                          ? null
                          : Text(suggestion.formattedAddress!),
                      onTap: () => _selectSuggestion(suggestion),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (widget.value == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Pick a place from search, or leave blank and type the name below.',
              style: TextStyle(color: palette.creamMuted, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
