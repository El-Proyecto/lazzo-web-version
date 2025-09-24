// lib/features/profile/presentation/widgets/common/link_tile.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../shared/constants/spacing.dart';
import 'pill_button.dart';

class LinkTile extends StatefulWidget {
  const LinkTile({
    super.key,
    required this.icon, // FontAwesome icon (ex.: FontAwesomeIcons.instagram)
    required this.label, // "Instagram" | "TikTok" | "Spotify"
    required this.value, // "Tap to Add" ou URL
    this.onTap, // tap no tile (para entrar em edição, p.ex.)
    // ---- Edição ----
    this.isEditing = false,
    this.onCancelEdit,
    this.onSaveEdit,
    this.hintText,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  final bool isEditing;
  final VoidCallback? onCancelEdit;
  final ValueChanged<String>? onSaveEdit;
  final String? hintText;

  @override
  State<LinkTile> createState() => _LinkTileState();
}

class _LinkTileState extends State<LinkTile> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(
      text: widget.value.toLowerCase() == 'tap to add' ? '' : widget.value,
    );
  }

  @override
  void didUpdateWidget(covariant LinkTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando entra em modo edição, sincroniza o valor
    if (widget.isEditing && !oldWidget.isEditing) {
      _c.text = widget.value.toLowerCase() == 'tap to add' ? '' : widget.value;
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String? _validateUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return 'This field is required.';
    final uri = Uri.tryParse(v);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http'))) {
      return 'Enter a valid URL (https://...)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // ---- Modo visualização ----
    if (!widget.isEditing) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 370,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: const Color(0xFF2B2B2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F282828),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              FaIcon(widget.icon, size: 18, color: const Color(0xFFF2F2F2)),
              const SizedBox(width: 12),
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
              const Spacer(),
              SizedBox(
                width: 180, // mais espaço para URL
                child: Text(
                  widget.value,
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
      );
    }

    // ---- Modo edição ----
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ícone + label à esquerda, botões à direita
          Row(
            children: [
              FaIcon(widget.icon, size: 18, color: const Color(0xFFF2F2F2)),
              const SizedBox(width: 12),
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
              const Spacer(),
              PillButton(
                label: 'Cancel',
                background: const Color(0xFF1E1E1E),
                fg: const Color(0xFFA5A5A5),
                icon: Icons.close,
                onTap: widget.onCancelEdit,
              ),
              const SizedBox(width: 8),
              PillButton(
                label: 'Save',
                background: const Color(0xFF2BB956),
                fg: const Color(0xFFF2F2F2),
                icon: Icons.check,
                onTap: () {
                  final v = _c.text;
                  final err = _validateUrl(v);
                  if (err != null) {
                    _toast(err);
                    return;
                  }
                  widget.onSaveEdit?.call(v.trim());
                },
              ),
            ],
          ),

          // “respiro” entre header e input
          SizedBox(height: Gaps.xl),

          TextField(
            controller: _c,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Color(0xFFF2F2F2), fontSize: 16),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'https://example.com/...',
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
      ),
    );
  }
}
