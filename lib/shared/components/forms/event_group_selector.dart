import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../dialogs/emoji_selector_dialog.dart';

/// Widget tokenizado para seleção de nome e grupo do evento
/// Combina emoji, campo de nome editável e seleção de grupo
class EventGroupSelector extends StatelessWidget {
  final String eventName;
  final String eventEmoji;
  final GroupInfo? selectedGroup;
  final Function(String)? onEmojiPressed;
  final Function(String)? onEventNameChanged;
  final VoidCallback? onGroupPressed;
  final String? nameError;
  final String? groupError;

  const EventGroupSelector({
    super.key,
    required this.eventName,
    required this.eventEmoji,
    this.selectedGroup,
    this.onEmojiPressed,
    this.onEventNameChanged,
    this.onGroupPressed,
    this.nameError,
    this.groupError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Ícone do evento
            GestureDetector(
              onTap: () => _showEmojiSelector(context),
              child: Container(
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
            ),

            SizedBox(width: Gaps.xs),

            // Campo de nome
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
                    border: nameError != null
                        ? Border.all(color: Colors.red, width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          eventName,
                          style: AppText.bodyLarge.copyWith(
                            color: eventName == 'Add Event Name'
                                ? BrandColors.text2
                                : BrandColors.text1,
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
                  border: groupError != null
                      ? Border.all(color: Colors.red, width: 1)
                      : null,
                ),
                child: Center(
                  child: selectedGroup != null
                      ? _GroupIcon(group: selectedGroup!)
                      : Icon(
                          Icons.group_add,
                          color: BrandColors.text2,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),

        // Error messages
        if (nameError != null || groupError != null) ...[
          SizedBox(height: Gaps.xxs),
          if (nameError != null)
            Padding(
              padding: EdgeInsets.only(left: 48 + Gaps.xs),
              child: Text(
                nameError!,
                style: AppText.bodyMedium.copyWith(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          if (groupError != null)
            Text(
              groupError!,
              style: AppText.bodyMedium.copyWith(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
        ],
      ],
    );
  }

  void _showEventNameEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventNameEditBottomSheet(
        initialName: eventName,
        onChanged: onEventNameChanged,
      ),
    );
  }

  void _showEmojiSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiSelectorBottomSheet(
        selectedEmoji: eventEmoji,
        onEmojiSelected: onEmojiPressed,
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

class _EventNameEditBottomSheet extends StatefulWidget {
  final String initialName;
  final ValueChanged<String>? onChanged;

  const _EventNameEditBottomSheet({required this.initialName, this.onChanged});

  @override
  State<_EventNameEditBottomSheet> createState() =>
      _EventNameEditBottomSheetState();
}

class _EventNameEditBottomSheetState extends State<_EventNameEditBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Start with empty field, only use initialName as placeholder context
    _controller = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: keyboardHeight > 0 ? maxHeight : screenHeight * 0.4,
      ),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: Gaps.lg,
          right: Gaps.lg,
          top: Gaps.lg,
          bottom: Gaps.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
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
                hintText:
                    widget.initialName.isNotEmpty &&
                        widget.initialName != 'e.g., Dinner at Tasca'
                    ? widget.initialName
                    : 'e.g., Dinner at Tasca',
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
                    style: TextButton.styleFrom(
                      backgroundColor: BrandColors.bg3,
                      padding: EdgeInsets.symmetric(vertical: Pads.ctlV),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
    };
  }

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      memberCount: json['memberCount'],
    );
  }
}
