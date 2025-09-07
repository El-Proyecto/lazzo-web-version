// lib/features/profile/presentation/widgets/editor_tiles/editable_birthdate_tile.dart
import 'package:flutter/material.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/themes/colors.dart';
import '../../../../../shared/utils/formatters.dart';
import '../common/pill_button.dart';

class EditableBirthDateTile extends StatefulWidget {
  const EditableBirthDateTile({
    super.key,
    required this.value,
    required this.isEditing,
    this.onTap,
    this.onCancel,
    this.onSave,
  });

  final DateTime? value;
  final bool isEditing;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final ValueChanged<DateTime>? onSave;

  @override
  State<EditableBirthDateTile> createState() => _EditableBirthDateTileState();
}

class _EditableBirthDateTileState extends State<EditableBirthDateTile> {
  DateTime? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.value;
  }

  @override
  void didUpdateWidget(covariant EditableBirthDateTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _picked = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final collapsedText = widget.value != null
        ? formatDdMMyyyy(widget.value!)
        : 'Tap to Add';

    return Container(
      width: 370,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: ShapeDecoration(
        color: const Color(0xFF2B2B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x3F282828),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: widget.isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: título + botões
                Row(
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Birth Date',
                          style: TextStyle(
                            color: Color(0xFFF2F2F2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                            letterSpacing: 0.10,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '*',
                          style: TextStyle(color: BrandColors.cantVote),
                        ),
                      ],
                    ),
                    const Spacer(),
                    PillButton(
                      label: 'Cancel',
                      background: const Color(0xFF1E1E1E),
                      fg: const Color(0xFFA5A5A5),
                      icon: Icons.close,
                      onTap: widget.onCancel,
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      label: 'Save',
                      background: const Color(0xFF2BB956),
                      fg: const Color(0xFFF2F2F2),
                      icon: Icons.check,
                      onTap: () {
                        if (_picked == null) return;
                        widget.onSave?.call(_picked!);
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.xl),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final initial =
                        _picked ?? DateTime(now.year - 18, now.month, now.day);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(1900, 1, 1),
                      lastDate: now,
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF2BB956),
                            surface: Color(0xFF1E1E1E),
                            onSurface: Color(0xFFF2F2F2),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _picked = picked);
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _picked != null
                          ? formatDdMMyyyy(_picked!)
                          : 'Select your birth date…',
                      style: const TextStyle(
                        color: Color(0xFFF2F2F2),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    const Text(
                      'Birth Date',
                      style: TextStyle(
                        color: Color(0xFFF2F2F2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.43,
                        letterSpacing: 0.10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '*',
                      style: TextStyle(color: BrandColors.cantVote),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: Text(
                        collapsedText,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA5A5A5),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform.rotate(
                      angle: -1.5708,
                      child: const Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: Color(0xFFA5A5A5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
