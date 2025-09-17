import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

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

class _LocationSectionState extends State<LocationSection> {
  LocationState _currentState = LocationState.decideLater;
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

    // Initialize controllers with existing data if available
    if (widget.selectedLocation != null) {
      _locationNameController.text = widget.selectedLocation!.displayName ?? '';
      _addressSearchController.text = widget.selectedLocation!.formattedAddress;
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _locationNameController.dispose();
    _addressSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
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
            SizedBox(height: Gaps.md),
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

        // Toggle buttons
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                text: 'Decide later',
                isSelected: _currentState == LocationState.decideLater,
                onTap: () => _changeState(LocationState.decideLater),
              ),
              _ToggleButton(
                text: 'Set Now',
                isSelected: _currentState == LocationState.setNow,
                onTap: () => _changeState(LocationState.setNow),
              ),
            ],
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.map, size: 40, color: BrandColors.text2),
              Icon(Icons.place, size: 30, color: BrandColors.planning),
            ],
          ),
        ),

        SizedBox(height: Gaps.md),

        // Location info
        if (location.displayName != null) ...[
          Text(
            location.displayName!,
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
        ],
        Text(
          location.formattedAddress,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),

        SizedBox(height: Gaps.md),

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
            SizedBox(width: Gaps.sm),
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

        SizedBox(height: Gaps.md),

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
          SizedBox(height: Gaps.sm),
          _buildSuggestionsList(),
        ],

        SizedBox(height: Gaps.md),

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
            SizedBox(width: Gaps.sm),
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
          padding: EdgeInsets.only(left: Pads.ctlH, right: Gaps.xs),
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
          borderSide: BorderSide(
            color: BrandColors.planning,
            width: 1,
          ), // Green focus
        ),
        contentPadding: EdgeInsets.symmetric(
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
        padding: EdgeInsets.symmetric(
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
            SizedBox(width: Gaps.xs),
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

  void _useCurrentLocation() {
    // Mock current location
    final currentLocation = LocationInfo(
      id: 'current-location',
      displayName: _locationNameController.text.isNotEmpty
          ? _locationNameController.text
          : null,
      formattedAddress: 'Your current location',
      latitude: -23.5505,
      longitude: -46.6333,
    );

    // Hide suggestions and go to state 2
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });

    widget.onLocationChanged?.call(currentLocation);
    HapticFeedback.lightImpact();
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
    _searchDebounceTimer = Timer(Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      // Try native geocoding first, fallback to mock for now
      List<LocationSuggestion> suggestions;

      // TODO: Implement native geocoding
      // suggestions = await _performNativeGeocode(query);

      // For now, use mock suggestions
      suggestions = _getMockSuggestions(query);

      if (mounted) {
        setState(() {
          _suggestions = suggestions.take(3).toList(); // Max 3 suggestions
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions.clear();
          _isSearching = false;
        });
      }
    }
  }

  // Future<List<LocationSuggestion>> _performNativeGeocode(String query) async {
  //   // TODO: Implement native geocoding
  //   // iOS: Use MKLocalSearch and CLGeocoder
  //   // Android: Use Geocoder
  //   // This would be implemented using platform channels or a plugin like geocoding
  //   throw UnimplementedError('Native geocoding not yet implemented');
  // }

  List<LocationSuggestion> _getMockSuggestions(String query) {
    // Mock suggestions - will be replaced with native geocoding
    return [
      LocationSuggestion(
        id: 'mock-1',
        name: '$query Restaurant',
        address: 'Rua Augusta, 123 - São Paulo, SP',
        latitude: -23.5505,
        longitude: -46.6333,
      ),
      LocationSuggestion(
        id: 'mock-2',
        name: '$query Shopping',
        address: 'Av. Paulista, 456 - São Paulo, SP',
        latitude: -23.5618,
        longitude: -46.6565,
      ),
      LocationSuggestion(
        id: 'mock-3',
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
        padding: EdgeInsets.all(Pads.ctlV),
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
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.text2),
              ),
            ),
            SizedBox(width: Gaps.sm),
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
        padding: EdgeInsets.all(Pads.ctlV),
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
            SizedBox(height: Gaps.xs),
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
        padding: EdgeInsets.all(Pads.ctlV),
        child: Row(
          children: [
            Icon(
              isTopMatch ? Icons.star : Icons.location_on,
              color: BrandColors.text2, // Gray for all icons
              size: 18,
            ),
            SizedBox(width: Gaps.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight: isTopMatch
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (suggestion.address != suggestion.name) ...[
                    SizedBox(height: 2),
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

class _ToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ToggleButton({
    required this.text,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Pads.ctlH - 2, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? BrandColors.planning : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        child: Text(
          text,
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
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

  void _searchAddresses(String query) {
    // Mock de sugestões - em produção usar Google Places API ou similar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _searchController.text == query) {
        setState(() {
          _suggestions.clear();
          _suggestions.addAll([
            LocationSuggestion(
              id: '1',
              name: '$query - Rua Principal',
              address: 'Rua Principal, 123, Lisboa',
              latitude: 38.7223,
              longitude: -9.1393,
            ),
            LocationSuggestion(
              id: '2',
              name: '$query - Centro',
              address: 'Centro de $query, Porto',
              latitude: 41.1579,
              longitude: -8.6291,
            ),
          ]);
          _isSearching = false;
        });
      }
    });
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
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: Pads.ctlH, right: Gaps.xs),
              child: Icon(Icons.search, color: BrandColors.text2),
            ),
            suffixIcon: _isSearching
                ? Padding(
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Pads.ctlV,
            ),
          ),
        ),

        // Sugestões
        if (_suggestions.isNotEmpty) ...[
          SizedBox(height: Gaps.sm),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.all(Gaps.xs),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(color: BrandColors.border, height: 1),
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
        SizedBox(height: Gaps.md),
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

  void _useCurrentLocation() {
    // Implementar obtenção da localização atual
    // Por enquanto, usar localização mock
    final location = LocationInfo(
      id: 'current',
      displayName: 'Current Location',
      formattedAddress: 'Your current location',
      latitude: 38.7223,
      longitude: -9.1393,
    );

    _searchController.text = location.displayName ?? '';
    widget.onLocationChanged?.call(location);
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
        padding: EdgeInsets.all(Pads.ctlV),
        child: Row(
          children: [
            Icon(Icons.location_on, color: BrandColors.text2, size: 20),
            SizedBox(width: Gaps.sm),
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
        padding: EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
          border: Border.all(color: BrandColors.planning, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.my_location, color: BrandColors.planning, size: 20),
            SizedBox(width: Gaps.sm),
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
      padding: EdgeInsets.symmetric(horizontal: Pads.ctlH, vertical: Pads.ctlV),
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
          Icon(Icons.edit_location_alt, color: BrandColors.text2, size: 18),
          SizedBox(width: Gaps.xs),
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
