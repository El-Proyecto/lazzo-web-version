import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Seção expansível para seleção de localização
/// Suporta estados: To Define e Address
class LocationSection extends StatefulWidget {
  final LocationInfo? selectedLocation;
  final Function(LocationInfo?)? onLocationChanged;
  final LocationState initialState;

  const LocationSection({
    super.key,
    this.selectedLocation,
    this.onLocationChanged,
    this.initialState = LocationState.decideLater,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  LocationState _currentState = LocationState.decideLater;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
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
    return Column(
      children: [
        // Campo para nome customizado
        _CustomNameField(),

        SizedBox(height: Gaps.md),

        // Seletor de localização
        ExpandedLocationPicker(
          selectedLocation: widget.selectedLocation,
          onLocationChanged: widget.onLocationChanged,
        ),
      ],
    );
  }

  void _changeState(LocationState newState) {
    setState(() {
      _currentState = newState;
    });
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
      _searchController.text = widget.selectedLocation!.displayName;
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
            prefixIcon: Icon(Icons.search, color: BrandColors.text2),
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
      address: suggestion.address,
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
      address: 'Your current location',
      latitude: 38.7223,
      longitude: -9.1393,
    );

    _searchController.text = location.displayName;
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
        border: Border.all(color: BrandColors.text2.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_location_alt, color: BrandColors.text2, size: 18),
          SizedBox(width: Gaps.sm),
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

/// Informações de localização
class LocationInfo {
  final String id;
  final String displayName;
  final String address;
  final double latitude;
  final double longitude;

  const LocationInfo({
    required this.id,
    required this.displayName,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
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
