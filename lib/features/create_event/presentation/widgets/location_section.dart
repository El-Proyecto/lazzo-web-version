import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/create_event_segmented_control.dart';

/// Seção expansível para seleção de localização
/// Suporta estados: To Define e Address
class LocationSection extends StatefulWidget {
  final LocationInfo? selectedLocation;
  final Function(LocationInfo?)? onLocationChanged;
  final Function(LocationState)? onStateChanged;
  final LocationState initialState;
  final String? validationError;

  const LocationSection({
    super.key,
    this.selectedLocation,
    this.onLocationChanged,
    this.onStateChanged,
    this.initialState = LocationState.decideLater,
    this.validationError,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection>
    with SingleTickerProviderStateMixin {
  LocationState _currentState = LocationState.decideLater;
  late TabController _tabController;
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _addressSearchController =
      TextEditingController();

  // Search state
  Timer? _searchDebounceTimer;
  List<LocationSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;

    // Initialize TabController
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _currentState == LocationState.decideLater ? 0 : 1,
    );

    // Initialize controllers with existing data if available
    if (widget.selectedLocation != null) {
      _locationNameController.text = widget.selectedLocation!.displayName ?? '';
      _addressSearchController.text = widget.selectedLocation!.formattedAddress;
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _tabController.dispose();
    _locationNameController.dispose();
    _addressSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: Pads.sectionV,
        left: Pads.sectionH,
        right: Pads.sectionH,
        bottom: Pads.sectionV,
      ),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          // Header com toggle
          _buildHeader(),

          // Conteúdo expansível
          if (_currentState == LocationState.setNow) ...[
            const SizedBox(height: Gaps.md),
            _buildExpandedContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Location',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),

        // Segmented Control (same as Date & Time)
        SizedBox(
          width: 200, // Fixed width to prevent overflow
          child: CreateEventSegmentedControl(
            controller: _tabController,
            labels: const ['Decide later', 'Set Now'],
            onTap: (index) {
              final newState =
                  index == 0 ? LocationState.decideLater : LocationState.setNow;
              _changeState(newState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    if (widget.selectedLocation != null) {
      // Show location preview when selected
      return _buildLocationPreview();
    } else {
      // Show location input form
      return _buildLocationInput();
    }
  }

  Widget _buildLocationPreview() {
    final location = widget.selectedLocation!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Static map mockup
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.map, size: 40, color: BrandColors.text2),
              Icon(Icons.place, size: 30, color: BrandColors.planning),
            ],
          ),
        ),

        const SizedBox(height: Gaps.md),

        // Location info
        if (location.displayName != null) ...[
          Text(
            location.displayName!,
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          location.formattedAddress,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),

        const SizedBox(height: Gaps.md),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.edit_outlined,
                text: 'Change',
                onTap: () => _resetLocationForEditing(),
                isSecondary: true,
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: _buildActionButton(
                icon: Icons.open_in_new,
                text: 'Open in Maps',
                onTap: () => _openInMaps(location),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Name Field (Optional)
        _buildTextField(
          hintText: 'Location name (optional)',
          icon: Icons.edit_location_alt,
          controller: _locationNameController,
          onChanged: (value) => _updateLocationName(value),
        ),

        const SizedBox(height: Gaps.md),

        // Search Address Field
        _buildTextField(
          hintText: 'Search address or place',
          icon: Icons.search,
          controller: _addressSearchController,
          onChanged: (value) => _handleAddressSearch(value),
          onSubmitted: (value) => _handleEnterKeyPressed(),
          readOnly: false,
        ),

        // Suggestions list
        if (_showSuggestions) ...[
          const SizedBox(height: Gaps.sm),
          _buildSuggestionsList(),
        ],

        const SizedBox(height: Gaps.md),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.my_location,
                text: 'Current location',
                onTap: () => _useCurrentLocation(),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: _buildActionButton(
                icon: Icons.map_outlined,
                text: 'Pick on map',
                onTap: () => _pickOnMap(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    VoidCallback? onTap,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: Pads.ctlH, right: Gaps.xs),
          child: Icon(icon, color: BrandColors.text2, size: 18),
        ),
        filled: true,
        fillColor: BrandColors.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
          borderSide: BorderSide(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
          borderSide: BorderSide(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.smAlt),
          borderSide: const BorderSide(
            color: BrandColors.planning,
            width: 1,
          ), // Green focus
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH - 2,
          vertical: Pads.ctlV,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: Border.all(
            color: isSecondary
                ? BrandColors.text2.withValues(alpha: 0.3)
                : BrandColors.planning,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSecondary ? BrandColors.text2 : BrandColors.planning,
              size: 16,
            ),
            const SizedBox(width: Gaps.xs),
            Flexible(
              child: Text(
                text,
                style: AppText.bodyMedium.copyWith(
                  color: isSecondary ? BrandColors.text1 : BrandColors.planning,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final currentLocation = LocationInfo(
          id: 'current-location-${DateTime.now().millisecondsSinceEpoch}',
          displayName: _locationNameController.text.isNotEmpty
              ? _locationNameController.text
              : placemark.name ?? 'Current Location',
          formattedAddress: _formatAddress(placemark),
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // Hide suggestions
        setState(() {
          _showSuggestions = false;
          _suggestions.clear();
        });

        widget.onLocationChanged?.call(currentLocation);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showLocationError('Failed to get current location: ${e.toString()}');
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      TopBanner.showError(
        context,
        message: message,
      );
    }
  }

  void _pickOnMap() {
    // TODO: Implement map picker functionality
    // For now, create a mock location and go to state 2
    final mockLocation = LocationInfo(
      id: 'map-pick-${DateTime.now().millisecondsSinceEpoch}',
      displayName: _locationNameController.text.isNotEmpty
          ? _locationNameController.text
          : null,
      formattedAddress: 'Selected from map',
      latitude: -23.5505,
      longitude: -46.6333,
    );

    // Hide suggestions and go to state 2
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });

    widget.onLocationChanged?.call(mockLocation);
    HapticFeedback.lightImpact();
  }

  void _openInMaps(LocationInfo location) {
    // TODO: Implement opening in maps
    // This would typically use url_launcher to open maps app
  }

  void _changeState(LocationState newState) {
    setState(() {
      _currentState = newState;
    });

    // Update TabController to match the state
    _tabController.animateTo(newState == LocationState.decideLater ? 0 : 1);

    if (newState == LocationState.decideLater) {
      widget.onLocationChanged?.call(null);
    }
    // Notify parent of state change for validation
    widget.onStateChanged?.call(newState);
  }

  void _updateLocationName(String name) {
    if (widget.selectedLocation != null) {
      final updatedLocation = LocationInfo(
        id: widget.selectedLocation!.id,
        displayName: name.isEmpty ? null : name,
        formattedAddress: widget.selectedLocation!.formattedAddress,
        latitude: widget.selectedLocation!.latitude,
        longitude: widget.selectedLocation!.longitude,
      );
      widget.onLocationChanged?.call(updatedLocation);
    }
  }

  void _handleAddressSearch(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Clear suggestions if query is too short
    if (query.length < 3) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    // Set searching state
    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    // Start new debounce timer (400ms)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      // Use real geocoding
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        return;
      }

      // Reverse geocode each location to get full details
      final results = <LocationSuggestion>[];
      for (var i = 0; i < locations.length && i < 3; i++) {
        final location = locations[i];
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            results.add(LocationSuggestion(
              id: 'geocoded-$i-${DateTime.now().millisecondsSinceEpoch}',
              name: placemark.name ?? query,
              address: _formatAddress(placemark),
              latitude: location.latitude,
              longitude: location.longitude,
            ));
          }
        } catch (e) {
          // Skip this result if reverse geocoding fails
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      // Fallback to mock suggestions if geocoding fails
      if (mounted) {
        setState(() {
          _suggestions = _getFallbackSuggestions(query);
          _isSearching = false;
        });
      }
    }
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    return parts.join(', ');
  }

  List<LocationSuggestion> _getFallbackSuggestions(String query) {
    // Fallback suggestions if geocoding fails
    return [
      LocationSuggestion(
        id: 'fallback-1',
        name: '$query Restaurant',
        address: 'Rua Augusta, 123 - São Paulo, SP',
        latitude: -23.5505,
        longitude: -46.6333,
      ),
      LocationSuggestion(
        id: 'fallback-2',
        name: '$query Shopping',
        address: 'Av. Paulista, 456 - São Paulo, SP',
        latitude: -23.5618,
        longitude: -46.6565,
      ),
      LocationSuggestion(
        id: 'fallback-3',
        name: '$query Plaza',
        address: 'Praça da Sé, 789 - São Paulo, SP',
        latitude: -23.5505,
        longitude: -46.6344,
      ),
    ];
  }

  Widget _buildSuggestionsList() {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: Border.all(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.text2),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Text(
              'Searching...',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: Border.all(
            color: BrandColors.text2.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No results. Try:',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
            const SizedBox(height: Gaps.xs),
            Text(
              '• Pick on map\n• Current location\n• Save name only',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.smAlt),
        border: Border.all(
          color: BrandColors.text2.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: _suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          return _buildSuggestionTile(suggestion, index == 0);
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionTile(LocationSuggestion suggestion, bool isTopMatch) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      borderRadius: BorderRadius.circular(Radii.smAlt),
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        child: Row(
          children: [
            Icon(
              isTopMatch ? Icons.star : Icons.location_on,
              color: BrandColors.text2, // Gray for all icons
              size: 18,
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight:
                          isTopMatch ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (suggestion.address != suggestion.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.address,
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Removed TOP label
          ],
        ),
      ),
    );
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    final location = LocationInfo(
      id: suggestion.id,
      displayName: _locationNameController.text.isNotEmpty
          ? _locationNameController.text
          : null,
      formattedAddress: suggestion.address,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );

    // Hide suggestions and go to state 2 (preview)
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });

    widget.onLocationChanged?.call(location);
    HapticFeedback.lightImpact();
  }

  void _handleEnterKeyPressed() {
    if (_suggestions.isNotEmpty) {
      // Select top match (first suggestion)
      _selectSuggestion(_suggestions.first);
    } else {
      // Try single geocode - for now just show empty state
      setState(() {
        _showSuggestions = true;
        _suggestions.clear(); // This will show the empty state
      });
    }
  }

  void _resetLocationForEditing() {
    // Clear selected location and reset fields for editing
    _locationNameController.clear();
    _addressSearchController.clear();
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });
    widget.onLocationChanged?.call(null);
    HapticFeedback.lightImpact();
  }
}

/// Seletor expandido de localização
class ExpandedLocationPicker extends StatefulWidget {
  final LocationInfo? selectedLocation;
  final Function(LocationInfo?)? onLocationChanged;

  const ExpandedLocationPicker({
    super.key,
    this.selectedLocation,
    this.onLocationChanged,
  });

  @override
  State<ExpandedLocationPicker> createState() => _ExpandedLocationPickerState();
}

class _ExpandedLocationPickerState extends State<ExpandedLocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final List<LocationSuggestion> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedLocation != null) {
      _searchController.text = widget.selectedLocation!.displayName ?? '';
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simular busca de endereços (implementar com serviço real)
    _searchAddresses(query);
  }

  Future<void> _searchAddresses(String query) async {
    try {
      // Use real geocoding
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        if (mounted) {
          setState(() {
            _suggestions.clear();
            _isSearching = false;
          });
        }
        return;
      }

      // Reverse geocode each location to get full details
      final results = <LocationSuggestion>[];
      for (var i = 0; i < locations.length && i < 3; i++) {
        final location = locations[i];
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            results.add(LocationSuggestion(
              id: 'geocoded-$i-${DateTime.now().millisecondsSinceEpoch}',
              name: placemark.name ?? query,
              address: _formatAddressFromPlacemark(placemark),
              latitude: location.latitude,
              longitude: location.longitude,
            ));
          }
        } catch (e) {
          continue;
        }
      }

      if (mounted && _searchController.text == query) {
        setState(() {
          _suggestions.clear();
          _suggestions.addAll(results);
          _isSearching = false;
        });
      }
    } catch (e) {
      // Fallback to mock suggestions
      if (mounted && _searchController.text == query) {
        setState(() {
          _suggestions.clear();
          _suggestions.addAll([
            LocationSuggestion(
              id: 'fallback-1',
              name: '$query - Rua Principal',
              address: 'Rua Principal, 123, Lisboa',
              latitude: 38.7223,
              longitude: -9.1393,
            ),
            LocationSuggestion(
              id: 'fallback-2',
              name: '$query - Centro',
              address: 'Centro de $query, Porto',
              latitude: 41.1579,
              longitude: -8.6291,
            ),
          ]);
          _isSearching = false;
        });
      }
    }
  }

  String _formatAddressFromPlacemark(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de pesquisa
        TextField(
          controller: _searchController,
          style: AppText.bodyLarge.copyWith(color: BrandColors.text1),
          decoration: InputDecoration(
            hintText: 'Search address...',
            hintStyle: AppText.bodyLarge.copyWith(color: BrandColors.text2),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: Pads.ctlH, right: Gaps.xs),
              child: Icon(Icons.search, color: BrandColors.text2),
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          BrandColors.planning,
                        ),
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: BrandColors.bg3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.smAlt),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Pads.ctlV,
            ),
          ),
        ),

        // Sugestões
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: Gaps.sm),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Gaps.xs),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: BrandColors.border, height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return _SuggestionTile(
                  suggestion: suggestion,
                  onTap: () => _selectLocation(suggestion),
                );
              },
            ),
          ),
        ],

        // Localização atual
        const SizedBox(height: Gaps.md),
        _CurrentLocationButton(onTap: _useCurrentLocation),
      ],
    );
  }

  void _selectLocation(LocationSuggestion suggestion) {
    _searchController.text = suggestion.name;
    setState(() {
      _suggestions.clear();
    });

    final location = LocationInfo(
      id: suggestion.id,
      displayName: suggestion.name,
      formattedAddress: suggestion.address,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );

    widget.onLocationChanged?.call(location);
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final location = LocationInfo(
          id: 'current-${DateTime.now().millisecondsSinceEpoch}',
          displayName: placemark.name ?? 'Current Location',
          formattedAddress: _formatAddressFromPlacemark(placemark),
          latitude: position.latitude,
          longitude: position.longitude,
        );

        _searchController.text = location.displayName ?? '';
        widget.onLocationChanged?.call(location);
      }
    } catch (e) {
      _showLocationError('Failed to get current location: ${e.toString()}');
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      TopBanner.showError(
        context,
        message: message,
      );
    }
  }
}

class _SuggestionTile extends StatelessWidget {
  final LocationSuggestion suggestion;
  final VoidCallback? onTap;

  const _SuggestionTile({required this.suggestion, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.all(Pads.ctlV),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: BrandColors.text2, size: 20),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: AppText.bodyLarge.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    suggestion.address,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CurrentLocationButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.smAlt),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: Border.all(color: BrandColors.planning, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.my_location,
                color: BrandColors.planning, size: 20),
            const SizedBox(width: Gaps.sm),
            Text(
              'Use Current Location',
              style: AppText.labelLarge.copyWith(
                color: BrandColors.planning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo para nome customizado da localização
class _CustomNameField extends StatefulWidget {
  const _CustomNameField();

  @override
  State<_CustomNameField> createState() => _CustomNameFieldState();
}

class _CustomNameFieldState extends State<_CustomNameField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH, vertical: Pads.ctlV),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.smAlt),
        border: Border.all(
          color: BrandColors.text2.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_location_alt,
              color: BrandColors.text2, size: 18),
          const SizedBox(width: Gaps.xs),
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              decoration: InputDecoration(
                hintText: 'Custom location name...',
                hintStyle: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estados da seção de localização
enum LocationState { decideLater, setNow }

/// Estados do picker de localização
enum LocationPickerState { input, searching, results, mapConfirm }

/// Informações de localização
class LocationInfo {
  final String id;
  final String? displayName; // Optional custom name
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const LocationInfo({
    required this.id,
    this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      id: json['id'],
      displayName: json['displayName'],
      formattedAddress: json['formattedAddress'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

/// Sugestão de localização
class LocationSuggestion {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const LocationSuggestion({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
