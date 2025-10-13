import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Seção expansível para seleção de localização (P1 - sem Google Maps)
/// Suporta estados: To Define e Address
class LocationSectionP1 extends StatefulWidget {
  final LocationInfo? selectedLocation;
  final Function(LocationInfo?)? onLocationChanged;
  final Function(LocationState)? onStateChanged;
  final LocationState initialState;
  final String? validationError;

  const LocationSectionP1({
    super.key,
    this.selectedLocation,
    this.onLocationChanged,
    this.onStateChanged,
    this.initialState = LocationState.decideLater,
    this.validationError,
  });

  @override
  State<LocationSectionP1> createState() => _LocationSectionP1State();
}

class _LocationSectionP1State extends State<LocationSectionP1>
    with SingleTickerProviderStateMixin {
  LocationState _currentState = LocationState.decideLater;
  late TabController _tabController;
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _addressSearchController =
      TextEditingController();

  // Search state (mock for P1)
  Timer? _searchDebounceTimer;
  List<LocationSuggestion> _suggestions = [];
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
      children: [
        // Ícone
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: const Icon(
            Icons.location_on,
            color: BrandColors.text2,
            size: 20,
          ),
        ),

        const SizedBox(width: Gaps.md),

        // Título e estado
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.xs),
              Text(
                _getLocationStateText(),
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ],
          ),
        ),

        // Toggle button
        IconButton(
          onPressed: _toggleLocationState,
          icon: Icon(
            _currentState == LocationState.decideLater
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_up,
            color: BrandColors.text2,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        // Validation error
        if (widget.validationError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Pads.ctlV),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              widget.validationError!,
              style: AppText.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
          const SizedBox(height: Gaps.md),
        ],

        // Tab controller para "To Define" vs "Address"
        Container(
          decoration: BoxDecoration(
            color: BrandColors.bg3,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: BrandColors.planning,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            labelColor: BrandColors.text1,
            unselectedLabelColor: BrandColors.text2,
            labelStyle: AppText.bodyMedium,
            unselectedLabelStyle: AppText.bodyMedium,
            onTap: _onTabChanged,
            tabs: const [
              Tab(text: 'A Definir'),
              Tab(text: 'Endereço'),
            ],
          ),
        ),

        const SizedBox(height: Gaps.md),

        // Tab view content
        SizedBox(
          height: 200, // Fixed height for P1 simplicity
          child: TabBarView(
            controller: _tabController,
            children: [_buildToDefineTab(), _buildAddressTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildToDefineTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome do Local',
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.sm),

        TextField(
          controller: _locationNameController,
          onChanged: _onLocationNameChanged,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
          decoration: InputDecoration(
            hintText: 'Ex: Casa do João, Restaurante X...',
            hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              borderSide: const BorderSide(color: BrandColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              borderSide: const BorderSide(color: BrandColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              borderSide: const BorderSide(color: BrandColors.planning),
            ),
            fillColor: BrandColors.bg1,
            filled: true,
          ),
        ),

        const SizedBox(height: Gaps.sm),

        Text(
          'O endereço específico será definido mais tarde',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
      ],
    );
  }

  Widget _buildAddressTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Endereço',
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.sm),

        TextField(
          controller: _addressSearchController,
          onChanged: _onAddressSearchChanged,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
          decoration: InputDecoration(
            hintText: 'Digite o endereço...',
            hintStyle: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            prefixIcon: const Icon(Icons.search, color: BrandColors.text2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              borderSide: const BorderSide(color: BrandColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              borderSide: const BorderSide(color: BrandColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              borderSide: const BorderSide(color: BrandColors.planning),
            ),
            fillColor: BrandColors.bg1,
            filled: true,
          ),
        ),

        const SizedBox(height: Gaps.sm),

        // Mock suggestions for P1
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: BrandColors.bg1,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: BrandColors.border),
            ),
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: BrandColors.text2,
                  ),
                  title: Text(
                    suggestion.name,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  subtitle: Text(
                    suggestion.address,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                  onTap: () => _onSuggestionSelected(suggestion),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  String _getLocationStateText() {
    switch (_currentState) {
      case LocationState.decideLater:
        return 'A definir';
      case LocationState.setNow:
        if (widget.selectedLocation?.displayName?.isNotEmpty == true) {
          return widget.selectedLocation!.displayName!;
        } else if (widget.selectedLocation?.formattedAddress.isNotEmpty ==
            true) {
          return widget.selectedLocation!.formattedAddress;
        }
        return 'Definir agora';
    }
  }

  void _toggleLocationState() {
    setState(() {
      if (_currentState == LocationState.decideLater) {
        _currentState = LocationState.setNow;
        _tabController.animateTo(0);
      } else {
        _currentState = LocationState.decideLater;
        _clearLocation();
      }
    });
    widget.onStateChanged?.call(_currentState);
  }

  void _onTabChanged(int index) {
    // Tab changes are handled by the TabController
  }

  void _onLocationNameChanged(String value) {
    final location = LocationInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      displayName: value,
      formattedAddress: 'A definir',
      latitude: 0.0,
      longitude: 0.0,
    );
    widget.onLocationChanged?.call(value.isNotEmpty ? location : null);
  }

  void _onAddressSearchChanged(String value) {
    _searchDebounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
      widget.onLocationChanged?.call(null);
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performMockSearch(value);
    });
  }

  void _performMockSearch(String query) {
    // Mock search results for P1

    // Simulate API delay
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _suggestions = [
          LocationSuggestion(
            name: '$query - Localização 1',
            address: 'Rua Example 123, Lisboa',
            lat: 38.7223,
            lng: -9.1393,
          ),
          LocationSuggestion(
            name: '$query - Localização 2',
            address: 'Avenida Test 456, Porto',
            lat: 41.1579,
            lng: -8.6291,
          ),
        ];
        _showSuggestions = true;
      });
    });
  }

  void _onSuggestionSelected(LocationSuggestion suggestion) {
    setState(() {
      _addressSearchController.text = suggestion.address;
      _showSuggestions = false;
    });

    final location = LocationInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      displayName: suggestion.name,
      formattedAddress: suggestion.address,
      latitude: suggestion.lat,
      longitude: suggestion.lng,
    );

    widget.onLocationChanged?.call(location);
  }

  void _clearLocation() {
    _locationNameController.clear();
    _addressSearchController.clear();
    widget.onLocationChanged?.call(null);
  }
}

// Mock classes for P1
class LocationSuggestion {
  final String name;
  final String address;
  final double lat;
  final double lng;

  LocationSuggestion({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

// These should match the original classes from location_section.dart
enum LocationState { decideLater, setNow }

class LocationInfo {
  final String id;
  final String? displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  LocationInfo({
    required this.id,
    this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}
