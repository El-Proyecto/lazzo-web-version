// lib/features/profile/presentation/widgets/editor_tiles/editable_text_tile.dart
import 'package:flutter/material.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/themes/colors.dart';
import '../common/pill_button.dart';

class EditableTextTile extends StatefulWidget {
  const EditableTextTile({
    super.key,
    required this.label,
    required this.value, // '' → “Tap to Add”
    required this.isEditing,
    this.requiredAsterisk = false,
    this.hintText,
    this.onTap,
    this.onCancel,
    this.onSave,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final String value;
  final bool isEditing;
  final bool requiredAsterisk;
  final String? hintText;
  final TextInputType keyboardType;
  final VoidCallback? onTap, onCancel;
  final ValueChanged<String>? onSave;

  @override
  State<EditableTextTile> createState() => _EditableTextTileState();
}

class _EditableTextTileState extends State<EditableTextTile> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EditableTextTile old) {
    super.didUpdateWidget(old);
    if (widget.isEditing && !old.isEditing) {
      _c.text = widget.value;
      _c.selection = TextSelection.fromPosition(
        TextPosition(offset: _c.text.length),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showValue = widget.value.isEmpty ? 'Tap to Add' : widget.value;

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
                // Header: título + botões (mesma linha)
                Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Color(0xFFF2F2F2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                            letterSpacing: 0.10,
                          ),
                        ),
                        if (widget.requiredAsterisk) ...const [
                          SizedBox(width: 8),
                          Text(
                            '*',
                            style: TextStyle(color: BrandColors.cantVote),
                          ),
                        ],
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
                        final v = _c.text.trim();
                        if (v.isNotEmpty) widget.onSave?.call(v);
                      },
                    ),
                  ],
                ),
                SizedBox(height: Gaps.xl), // “respiro” entre header e input
                TextField(
                  controller: _c,
                  autofocus: true,
                  keyboardType: widget.keyboardType,
                  style: const TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Type…',
                    hintStyle: const TextStyle(color: Color(0xFFA5A5A5)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
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
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Color(0xFFF2F2F2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.43,
                        letterSpacing: 0.10,
                      ),
                    ),
                    if (widget.requiredAsterisk) ...const [
                      SizedBox(width: 8),
                      Text('*', style: TextStyle(color: BrandColors.cantVote)),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: Text(
                        showValue,
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
