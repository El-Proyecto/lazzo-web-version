import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/common/common_bottom_sheet.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'location_section.dart';
import '../providers/event_providers.dart';
import '../../domain/entities/event.dart';

/// Bottom sheet para confirmar a criação do evento
/// Mostra resumo de todas as informações do evento
class ConfirmEventBottomSheet extends ConsumerStatefulWidget {
  final String eventName;
  final String? eventEmoji;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final LocationInfo? selectedLocation;
  final Function(String eventId)? onEventCreated; // Changed to receive eventId

  const ConfirmEventBottomSheet({
    super.key,
    required this.eventName,
    this.eventEmoji,
    this.selectedDate,
    this.selectedTime,
    this.endDate,
    this.endTime,
    this.selectedLocation,
    this.onEventCreated,
  });

  @override
  ConsumerState<ConfirmEventBottomSheet> createState() =>
      _ConfirmEventBottomSheetState();
}

class _ConfirmEventBottomSheetState
    extends ConsumerState<ConfirmEventBottomSheet> {
  bool _isCreating = false;
  late final String _displayEmoji;

  @override
  void initState() {
    super.initState();
    // Use calendar emoji as default if none selected
    _displayEmoji = widget.eventEmoji ?? '🗓️';
  }

  /// Cria o evento usando os providers do Riverpod
  Future<void> _createEvent() async {
    // Prevent double-tap
    if (_isCreating) return;

    setState(() {
      _isCreating = true;
    });
    final controller = ref.read(createEventControllerProvider.notifier);

    try {
      // Criar entidade de localização se necessário
      EventLocation? eventLocation;
      if (widget.selectedLocation != null) {
        eventLocation = EventLocation(
          id: widget.selectedLocation!.id,
          displayName: widget.selectedLocation!.displayName ?? '',
          formattedAddress: widget.selectedLocation!.formattedAddress,
          latitude: widget.selectedLocation!.latitude,
          longitude: widget.selectedLocation!.longitude,
        );
      }

      // Converter TimeOfDay para DateTime se necessário
      DateTime? startDateTime;
      if (widget.selectedDate != null && widget.selectedTime != null) {
        startDateTime = DateTime(
          widget.selectedDate!.year,
          widget.selectedDate!.month,
          widget.selectedDate!.day,
          widget.selectedTime!.hour,
          widget.selectedTime!.minute,
        );
      }

      DateTime? endDateTime;
      if (widget.endDate != null && widget.endTime != null) {
        endDateTime = DateTime(
          widget.endDate!.year,
          widget.endDate!.month,
          widget.endDate!.day,
          widget.endTime!.hour,
          widget.endTime!.minute,
        );
      }

      // Criar entidade do evento
      // Use the pre-generated emoji (same one shown in UI)
      final event = Event(
        id: '', // Será gerado pelo Supabase
        name: widget.eventName,
        emoji: _displayEmoji,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: eventLocation,
        status: EventStatus.pending,
        createdAt: DateTime.now(),
      );

      // Enviar para o Supabase via provider
      await controller.createEvent(event);

      // Obter o ID do evento criado do estado
      final createdEvent = ref.read(createEventControllerProvider).createdEvent;
      if (createdEvent == null || createdEvent.id.isEmpty) {
        throw Exception('Failed to get created event ID');
      }

      // Chamar callback antes de fechar o dialog para garantir execução única
      final eventId = createdEvent.id;

      // Fechar dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Aguardar um frame para garantir que o dialog foi fechado
        await Future.delayed(const Duration(milliseconds: 100));

        // Chamar callback apenas se ainda montado
        if (mounted) {
          widget.onEventCreated?.call(eventId);
        }
      }
    } catch (e) {
      // Reset creating state on error
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        TopBanner.showError(
          context,
          message: 'Error creating event: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonBottomSheet(
      title: 'Confirm Event',
      showGrabber: true,
      onClose: null, // No close button
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name com emoji
          _buildNameRow(),

          const SizedBox(height: Gaps.md),

          // Date & Time
          _buildInfoRow(
            'Date & Time',
            _formatDateTime(),
            Icons.schedule,
          ),

          const SizedBox(height: Gaps.md),

          // Location
          _buildInfoRow(
            'Location',
            _formatLocation(),
            Icons.location_on,
          ),

          const SizedBox(height: 24),

          // Create button with optimistic UI
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreating ? null : () => _createEvent(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCreating
                    ? BrandColors.planning.withOpacity(0.5)
                    : BrandColors.planning,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: BrandColors.planning.withOpacity(0.5),
              ),
              child: _isCreating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              BrandColors.text1,
                            ),
                          ),
                        ),
                        const SizedBox(width: Gaps.sm),
                        Text(
                          'Creating...',
                          style: AppText.titleMediumEmph.copyWith(
                            color: BrandColors.text1,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Create',
                      style: AppText.titleMediumEmph.copyWith(
                        color: BrandColors.text1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: const Icon(Icons.event, color: BrandColors.text2, size: 24),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
              const SizedBox(height: 2),
              Text(
                '$_displayEmoji ${widget.eventName.isEmpty ? 'Untitled Event' : widget.eventName}',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, color: BrandColors.text2, size: 24),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime() {
    if (widget.selectedDate == null && widget.selectedTime == null) {
      return 'Date & time to be decided';
    }

    String result = '';

    if (widget.selectedDate != null) {
      result += _formatDate(widget.selectedDate!);
    }

    if (widget.selectedTime != null) {
      if (result.isNotEmpty) result += ' at ';
      result += _formatTime(widget.selectedTime!);
    }

    // Add end time if available
    if (widget.endTime != null && widget.endTime != widget.selectedTime) {
      result += ' - ${_formatTime(widget.endTime!)}';
    }

    return result.isEmpty ? 'Date & time to be decided' : result;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow';
    } else {
      // Format as "Mon, 15 Sep"
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatLocation() {
    if (widget.selectedLocation == null) {
      return 'Location to be decided';
    }

    // If has custom name, use it
    if (widget.selectedLocation!.displayName != null &&
        widget.selectedLocation!.displayName!.isNotEmpty) {
      return widget.selectedLocation!.displayName!;
    }

    // If has address, use it
    if (widget.selectedLocation!.formattedAddress.isNotEmpty) {
      return widget.selectedLocation!.formattedAddress;
    }

    return 'Location to be decided';
  }
}
