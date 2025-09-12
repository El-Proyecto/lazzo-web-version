import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Widget para seleção de grupo
/// Inclui ícone do evento, nome e botão para seleção de grupo
class EventGroupSelector extends StatelessWidget {
  final String eventEmoji;
  final String eventName;
  final GroupInfo? selectedGroup;
  final VoidCallback? onGroupPressed;
  final ValueChanged<String>? onEventNameChanged;

  const EventGroupSelector({
    super.key,
    required this.eventEmoji,
    required this.eventName,
    this.selectedGroup,
    this.onGroupPressed,
    this.onEventNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícone do evento
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
          child: Center(
            child: Text(eventEmoji, style: const TextStyle(fontSize: 32)),
          ),
        ),

        SizedBox(width: Gaps.xs),

        // Nome do evento
        Expanded(
          child: GestureDetector(
            onTap: () => _showEventNameEditor(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlV,
              ),
              decoration: BoxDecoration(
                color: BrandColors.bg2,
                borderRadius: BorderRadius.circular(Radii.smAlt),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      eventName,
                      style: AppText.bodyLarge.copyWith(
                        color: BrandColors.text1,
                      ),
                    ),
                  ),
                  Icon(Icons.edit, color: BrandColors.text2, size: 16),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: Gaps.xs),

        // Seleção de grupo
        GestureDetector(
          onTap: onGroupPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BrandColors.bg2,
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
            child: Center(
              child: selectedGroup != null
                  ? _GroupIcon(group: selectedGroup!)
                  : Icon(Icons.group_add, color: BrandColors.text2, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  void _showEventNameEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EventNameEditDialog(
        initialName: eventName,
        onChanged: onEventNameChanged,
      ),
    );
  }
}

class _GroupIcon extends StatelessWidget {
  final GroupInfo group;

  const _GroupIcon({required this.group});

  @override
  Widget build(BuildContext context) {
    if (group.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Image.network(
          group.imageUrl!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _DefaultGroupIcon(name: group.name);
          },
        ),
      );
    }

    return _DefaultGroupIcon(name: group.name);
  }
}

class _DefaultGroupIcon extends StatelessWidget {
  final String name;

  const _DefaultGroupIcon({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EventNameEditDialog extends StatefulWidget {
  final String initialName;
  final ValueChanged<String>? onChanged;

  const _EventNameEditDialog({required this.initialName, this.onChanged});

  @override
  State<_EventNameEditDialog> createState() => _EventNameEditDialogState();
}

class _EventNameEditDialogState extends State<_EventNameEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BrandColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Padding(
        padding: EdgeInsets.all(Gaps.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Event Name',
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
            ),

            SizedBox(height: Gaps.md),

            TextField(
              controller: _controller,
              autofocus: true,
              style: AppText.bodyLarge.copyWith(color: BrandColors.text1),
              decoration: InputDecoration(
                hintText: 'Enter event name',
                hintStyle: AppText.bodyLarge.copyWith(color: BrandColors.text2),
                filled: true,
                fillColor: BrandColors.bg3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.smAlt),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            SizedBox(height: Gaps.lg),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppText.labelLarge.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Gaps.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onChanged?.call(_controller.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.planning,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: AppText.labelLarge.copyWith(
                        color: BrandColors.text1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo para informações do grupo
class GroupInfo {
  final String id;
  final String name;
  final String? imageUrl;
  final int memberCount;

  const GroupInfo({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.memberCount,
  });
}
