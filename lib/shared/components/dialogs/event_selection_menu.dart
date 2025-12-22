import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Event selection menu for when multiple events are living/recap
/// Shows above the NavBar center button
class EventSelectionMenu {
  static void show({
    required BuildContext context,
    required List<EventOption> events,
    required Function(EventOption) onEventSelected,
  }) {
    // Get button position (center of screen, bottom)
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final size = MediaQuery.of(context).size;
    // Position above bottom nav bar (82px height + extra margin)
    final buttonPosition = Offset(size.width / 2, size.height - 82);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        (size.width / 2) -
            150, // Center horizontally (assuming ~300px menu width)
        buttonPosition.dy -
            (events.length * 56.0) -
            48, // Above button with more margin
        (size.width / 2) - 150, // Mirror left position for centering
        buttonPosition.dy - Gaps.md, // Gap from bottom
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      color: BrandColors.bg2,
      elevation: 8,
      items: events.map((event) {
        return PopupMenuItem<EventOption>(
          value: event,
          padding: const EdgeInsets.symmetric(
            horizontal: Gaps.xs,
            vertical: Gaps.xxs,
          ),
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: ListTile(
              dense: true,
              enableFeedback: false,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Gaps.xxs,
              ),
              leading: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Text(
                  event.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              title: Text(
                event.name,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((selectedEvent) {
      if (selectedEvent != null) {
        onEventSelected(selectedEvent);
      }
    });
  }
}

/// Event option for selection menu
class EventOption {
  final String id;
  final String name;
  final String emoji;

  const EventOption({
    required this.id,
    required this.name,
    required this.emoji,
  });
}
