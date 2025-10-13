import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'emoji_selector_dialog.dart';

/// Widget tokenizado para seleção de nome e grupo do evento
/// Combina emoji, campo de nome editável e seleção de grupo
class EventGroupSelector extends StatelessWidget {
  final String eventName;
  final Key? nameFieldKey;
  final Key? groupButtonKey;
  final String eventEmoji;
  final GroupInfo? selectedGroup;
  final Function(String)? onEmojiPressed;
  final Function(String)? onEventNameChanged;
  final VoidCallback? onGroupPressed;
  final String? nameError;
  final String? groupError;
  final bool isGroupReadOnly;

  const EventGroupSelector({
    super.key,
    required this.eventName,
    required this.eventEmoji,
    this.selectedGroup,
    this.nameFieldKey,
    this.groupButtonKey,
    this.onEmojiPressed,
    this.onEventNameChanged,
    this.onGroupPressed,
    this.nameError,
    this.groupError,
    this.isGroupReadOnly = false,
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

            const SizedBox(width: Gaps.xs),

            // Campo de nome
            Expanded(
              child: GestureDetector(
                onTap: () => _showEventNameEditor(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
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
                        child: SizedBox(
                          height: 24, // Fixed height for single line
                          child: Text(
                            eventName,
                            style: AppText.bodyLarge.copyWith(
                              color: eventName == 'Add Event Name'
                                  ? BrandColors.text2
                                  : BrandColors.text1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.edit,
                        color: BrandColors.text2,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: Gaps.xs),

            // Seleção de grupo
            GestureDetector(
              key: groupButtonKey,
              onTap: isGroupReadOnly ? null : onGroupPressed,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isGroupReadOnly ? BrandColors.bg3 : BrandColors.bg2,
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
                          color: isGroupReadOnly
                              ? BrandColors.text2.withValues(alpha: 0.5)
                              : BrandColors.text2,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),

        // Error messages
        if (nameError != null || groupError != null) ...[
          const SizedBox(height: Gaps.xxs),
          if (nameError != null)
            Padding(
              padding: const EdgeInsets.only(left: 48 + Gaps.xs),
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
        nameFieldKey: nameFieldKey,
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
  final Key? nameFieldKey;

  const _EventNameEditBottomSheet({
    required this.initialName,
    this.onChanged,
    this.nameFieldKey,
  });

  @override
  State<_EventNameEditBottomSheet> createState() =>
      _EventNameEditBottomSheetState();
}

class _EventNameEditBottomSheetState extends State<_EventNameEditBottomSheet> {
  late TextEditingController _controller;
  String? _errorMessage;
  bool _showSaveAttempted = false;

  @override
  void initState() {
    super.initState();
    // Start with the current name if it's not the placeholder
    String initialText = '';
    if (widget.initialName.isNotEmpty &&
        widget.initialName != 'Add Event Name' &&
        widget.initialName != 'e.g., Dinner at Tasca') {
      initialText = widget.initialName;
    }
    _controller = TextEditingController(text: initialText);

    // Listen for changes to update button state and clear errors
    _controller.addListener(() {
      setState(() {
        if (_showSaveAttempted && _controller.text.trim().isNotEmpty) {
          _errorMessage = null;
        }
      });
    });
  }

  bool _isFormValid() {
    return _controller.text.trim().isNotEmpty;
  }

  void _handleSave() {
    setState(() {
      _showSaveAttempted = true;
    });

    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Event name is required';
      });
      return;
    }

    widget.onChanged?.call(_controller.text.trim());
    Navigator.of(context).pop();
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
      decoration: const BoxDecoration(
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
            const SizedBox(height: Gaps.md),
            TextField(
              key: widget.nameFieldKey,
              controller: _controller,
              autofocus: true,
              style: AppText.bodyLarge.copyWith(color: BrandColors.text1),
              decoration: InputDecoration(
                hintText: 'e.g., Dinner at Tasca',
                hintStyle: AppText.bodyLarge.copyWith(color: BrandColors.text2),
                filled: true,
                fillColor: BrandColors.bg3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.smAlt),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorMessage,
                errorStyle: AppText.bodyMedium.copyWith(color: Colors.red),
              ),
            ),
            const SizedBox(height: Gaps.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: BrandColors.bg3,
                      padding: const EdgeInsets.symmetric(
                        vertical: Pads.ctlVSm,
                      ),
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
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isFormValid() ? _handleSave : () => _handleSave(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid()
                          ? BrandColors.planning
                          : BrandColors.bg3,
                      padding: const EdgeInsets.symmetric(
                        vertical: Pads.ctlVSm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.smAlt),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: AppText.labelLarge.copyWith(
                        color:
                            _isFormValid() ? Colors.white : BrandColors.text2,
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
