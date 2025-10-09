import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/components/common/create_event_segmented_control.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

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

        // Segmented Control
        SizedBox(
          width: 200, // Fixed width to prevent overflow
          child: CreateEventSegmentedControl(
            controller: _tabController,
            labels: const ['Decide later', 'Set Now'],
            onTap: (index) {
              final newState = index == 0
                  ? LocationState.decideLater
                  : LocationState.setNow;
              _changeState(newState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    if (widget.selectedLocation != null &&
        widget.selectedLocation!.formattedAddress.isNotEmpty) {
      // Show location preview only when there's an actual address
      // Custom name only should stay in input mode
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
        // Google Maps preview
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.smAlt),
            border: Border.all(color: BrandColors.border, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(location.latitude, location.longitude),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('event_location'),
                position: LatLng(location.latitude, location.longitude),
                infoWindow: InfoWindow(
                  title: location.displayName ?? 'Localização do Evento',
                  snippet: location.formattedAddress,
                ),
              ),
            },
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            onTap: (_) =>
                _openInMaps(location), // Ao clicar no mapa, abrir Maps
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

  void _useCurrentLocation() async {
    try {
      // Verificar e solicitar permissões de localização
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissão negada, usar localização mock
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissões negadas permanentemente, usar localização mock
        _useDefaultLocation();
        return;
      }

      // Obter localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Converter coordenadas para endereço legível
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String formattedAddress = 'Localização Atual';
      if (placemarks.isNotEmpty) {
        formattedAddress = _buildFormattedAddress(placemarks.first);
      }

      final currentLocation = LocationInfo(
        id: 'current-location-${DateTime.now().millisecondsSinceEpoch}',
        displayName: _locationNameController.text.isNotEmpty
            ? _locationNameController.text
            : 'Localização Atual',
        formattedAddress: formattedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Hide suggestions and update location
      setState(() {
        _showSuggestions = false;
        _suggestions.clear();
      });

      widget.onLocationChanged?.call(currentLocation);
      widget.onStateChanged?.call(LocationState.setNow);
      HapticFeedback.lightImpact();
    } catch (e) {
      // Erro ao obter localização, usar localização padrão
      print('Erro ao obter localização atual: $e');
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    // Localização padrão caso não consiga obter GPS
    final defaultLocation = LocationInfo(
      id: 'default-location',
      displayName: _locationNameController.text.isNotEmpty
          ? _locationNameController.text
          : 'Localização Atual',
      formattedAddress: 'Rua do Porto, 456, Lisboa, Portugal',
      latitude: 38.7223,
      longitude: -9.1393,
    );

    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });

    widget.onLocationChanged?.call(defaultLocation);
    widget.onStateChanged?.call(LocationState.setNow);
    HapticFeedback.lightImpact();
  }

  void _pickOnMap() async {
    // Abrir Google Maps em modo de seleção de localização
    try {
      // Obter localização atual para centrar o mapa
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Se não conseguir obter localização, usar Lisboa como padrão
        currentPosition = null;
      }

      final lat = currentPosition?.latitude ?? 38.7223;
      final lng = currentPosition?.longitude ?? -9.1393;

      // URLs para abrir Google Maps em modo de seleção
      List<String> mapUrls = [
        // Google Maps web com parâmetro de seleção
        'https://www.google.com/maps/@$lat,$lng,15z',
        // Fallback para Apple Maps
        'maps://maps.apple.com/?q=$lat,$lng&ll=$lat,$lng&z=15',
      ];

      bool launched = false;

      for (String mapUrl in mapUrls) {
        try {
          Uri uri = Uri.parse(mapUrl);
          if (await canLaunchUrl(uri)) {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (launched) break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!launched && mounted) {
        // Se não conseguir abrir mapas, mostrar um diálogo personalizado
        _showMapPickerDialog();
      }
    } catch (e) {
      print('Erro ao abrir Pick on Map: $e');
      _showMapPickerDialog();
    }
  }

  void _showMapPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        title: Text(
          'Escolher no Mapa',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),
        content: Text(
          'Esta funcionalidade abrirá Google Maps para você escolher uma localização. Por agora, vamos usar uma localização de exemplo.',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppText.labelLarge.copyWith(color: BrandColors.text2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _useExamplePickedLocation();
            },
            child: Text(
              'Usar Exemplo',
              style: AppText.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useExamplePickedLocation() {
    // Localização de exemplo escolhida "no mapa"
    final pickedLocation = LocationInfo(
      id: 'map-picked-${DateTime.now().millisecondsSinceEpoch}',
      displayName: _locationNameController.text.isNotEmpty
          ? _locationNameController.text
          : 'Local Escolhido no Mapa',
      formattedAddress: 'Praça do Comércio, Lisboa, Portugal',
      latitude: 38.7071,
      longitude: -9.1359,
    );

    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });

    widget.onLocationChanged?.call(pickedLocation);
    widget.onStateChanged?.call(LocationState.setNow);
    HapticFeedback.lightImpact();
  }

  void _openInMaps(LocationInfo location) async {
    final lat = location.latitude;
    final lng = location.longitude;
    final label = Uri.encodeComponent(
      location.displayName ?? location.formattedAddress,
    );

    // Platform-specific URL schemes - ordered by preference and platform
    List<String> mapUrls = [
      // iOS-specific Google Maps schemes (most reliable on iOS)
      'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14',
      'googlemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14',
      // iOS Apple Maps (native)
      'maps://maps.apple.com/?q=$lat,$lng&ll=$lat,$lng&z=14',
      // Cross-platform Google Maps web URLs
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      'https://maps.google.com/?q=$lat,$lng',
      // Android-specific schemes (still included for compatibility)
      'geo:$lat,$lng?q=$lat,$lng($label)',
      'google.navigation:q=$lat,$lng',
      // Final web fallback
      'https://maps.google.com/maps?q=$lat,$lng&ll=$lat,$lng&z=16',
    ];

    bool launched = false;

    // Try each URL scheme until one works
    for (String mapUrl in mapUrls) {
      try {
        Uri uri = Uri.parse(mapUrl);

        // Check if the URL can be launched
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            // Successfully launched, break out of loop
            break;
          }
        }
      } catch (e) {
        // Log error for debugging but continue to next URL scheme
        print('Failed to launch $mapUrl: $e');
        continue;
      }
    }

    // Show error if no map app could be opened
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir o mapa. Certifique-se de que tem uma aplicação de mapas instalada.',
            style: AppText.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: BrandColors.cantVote,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _changeState(LocationState newState) {
    setState(() {
      _currentState = newState;
    });

    // Update tab controller to match new state
    final newIndex = newState == LocationState.decideLater ? 0 : 1;
    if (_tabController.index != newIndex) {
      _tabController.animateTo(newIndex);
    }

    if (newState == LocationState.decideLater) {
      widget.onLocationChanged?.call(null);
    }
    // Notify parent of state change for validation
    widget.onStateChanged?.call(newState);
  }

  void _updateLocationName(String name) {
    if (widget.selectedLocation != null &&
        widget.selectedLocation!.formattedAddress.isNotEmpty) {
      // Update existing location with real address
      final updatedLocation = LocationInfo(
        id: widget.selectedLocation!.id,
        displayName: name.isEmpty ? null : name,
        formattedAddress: widget.selectedLocation!.formattedAddress,
        latitude: widget.selectedLocation!.latitude,
        longitude: widget.selectedLocation!.longitude,
      );
      widget.onLocationChanged?.call(updatedLocation);
    } else if (name.isNotEmpty) {
      // Create custom name only location (won't trigger preview due to empty address)
      final customNameLocation = LocationInfo(
        id: 'custom-name-${DateTime.now().millisecondsSinceEpoch}',
        displayName: name,
        formattedAddress: '', // Empty address keeps it in input mode
        latitude: 0.0,
        longitude: 0.0,
      );
      widget.onLocationChanged?.call(customNameLocation);
    } else {
      // Clear location if name is empty and no existing location with address
      widget.onLocationChanged?.call(null);
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
      // Use real geocoding implementation - limited to 3 results
      List<LocationSuggestion> suggestions = await _performNativeGeocode(query);

      if (mounted) {
        setState(() {
          _suggestions = suggestions.take(3).toList(); // Exactly 3 suggestions
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // In case of error, show empty list
          _suggestions = [];
          _isSearching = false;
        });
      }
    }
  }

  /// Native geocoding implementation using geocoding package
  /// Converts address strings to coordinates and readable names
  /// Limited to 3 results, prioritizing user's location context
  Future<List<LocationSuggestion>> _performNativeGeocode(String query) async {
    try {
      // Get user's current location for context (if available)
      Position? userLocation;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          userLocation = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        // Continue without user location if unavailable
      }

      // Get locations from address query
      List<Location> locations = await locationFromAddress(query);
      List<LocationSuggestion> suggestions = [];

      // If we have user location, sort results by distance
      if (userLocation != null) {
        locations.sort((a, b) {
          double distanceA = Geolocator.distanceBetween(
            userLocation!.latitude,
            userLocation.longitude,
            a.latitude,
            a.longitude,
          );
          double distanceB = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }

      // Process exactly 3 results (or fewer if not available)
      for (int i = 0; i < locations.length && i < 3; i++) {
        Location location = locations[i];

        try {
          // Get readable address from coordinates
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks.first;

            // Build formatted address
            String formattedAddress = _buildFormattedAddress(placemark);
            String displayName = _buildDisplayName(placemark, query);

            suggestions.add(
              LocationSuggestion(
                id: '${location.latitude}_${location.longitude}',
                name: displayName,
                address: formattedAddress,
                latitude: location.latitude,
                longitude: location.longitude,
              ),
            );
          }
        } catch (e) {
          // If reverse geocoding fails, use basic info
          suggestions.add(
            LocationSuggestion(
              id: '${location.latitude}_${location.longitude}',
              name: query,
              address:
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
              latitude: location.latitude,
              longitude: location.longitude,
            ),
          );
        }
      }

      return suggestions;
    } catch (e) {
      // Return empty list on geocoding failure
      return [];
    }
  }

  /// Build formatted address from placemark
  String _buildFormattedAddress(Placemark placemark) {
    List<String> parts = [];

    if (placemark.street?.isNotEmpty == true) parts.add(placemark.street!);
    if (placemark.locality?.isNotEmpty == true) parts.add(placemark.locality!);
    if (placemark.administrativeArea?.isNotEmpty == true)
      parts.add(placemark.administrativeArea!);
    if (placemark.country?.isNotEmpty == true) parts.add(placemark.country!);

    return parts.join(', ');
  }

  /// Build display name from placemark and query
  String _buildDisplayName(Placemark placemark, String query) {
    // Prefer name, then locality, then fall back to query
    if (placemark.name?.isNotEmpty == true &&
        placemark.name != placemark.street) {
      return placemark.name!;
    }
    if (placemark.locality?.isNotEmpty == true) {
      return placemark.locality!;
    }
    return query;
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
                      fontWeight: isTopMatch
                          ? FontWeight.w600
                          : FontWeight.normal,
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
      // If no suggestions but user typed something, create location with address only
      final addressText = _addressSearchController.text.trim();
      if (addressText.isNotEmpty) {
        final addressOnlyLocation = LocationInfo(
          id: 'typed-address-${DateTime.now().millisecondsSinceEpoch}',
          displayName: _locationNameController.text.isNotEmpty
              ? _locationNameController.text
              : null,
          formattedAddress: addressText,
          latitude: 0.0, // Default coordinates
          longitude: 0.0,
        );

        setState(() {
          _showSuggestions = false;
          _suggestions.clear();
        });

        widget.onLocationChanged?.call(addressOnlyLocation);
        HapticFeedback.lightImpact();
      } else {
        // Show empty state if nothing typed
        setState(() {
          _showSuggestions = true;
          _suggestions.clear(); // This will show the empty state
        });
      }
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

    // Notify parent that location is cleared
    widget.onLocationChanged?.call(null);

    // If we're clearing location but still in "Set Now" mode,
    // the parent validation should handle the state appropriately
    // Don't force state change here - let parent decide

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

  void _useCurrentLocation() {
    // Implementar obtenção da localização atual
    // Por enquanto, usar localização mock
    final location = const LocationInfo(
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
            const Icon(
              Icons.my_location,
              color: BrandColors.planning,
              size: 20,
            ),
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
        horizontal: Pads.ctlH,
        vertical: Pads.ctlV,
      ),
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
          const Icon(
            Icons.edit_location_alt,
            color: BrandColors.text2,
            size: 18,
          ),
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
