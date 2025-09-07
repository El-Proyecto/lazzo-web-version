import 'package:flutter/material.dart';
import '../../../../../shared/constants/spacing.dart';
import '../common/pill_button.dart';

class InlineTextEditor extends StatefulWidget {
  const InlineTextEditor({
    super.key,
    required this.title,
    required this.hint,
    this.initial,
    required this.onCancel,
    required this.onSave,
    this.validator,
    this.normalizer,
    this.keyboardType = TextInputType.text,
  });

  final String title;
  final String hint;
  final String? initial;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;
  final String? Function(String text)? validator;
  final String Function(String text)? normalizer;
  final TextInputType keyboardType;

  @override
  State<InlineTextEditor> createState() => _InlineTextEditorState();
}

class _InlineTextEditorState extends State<InlineTextEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Conteúdo principal (com “respiro” em relação aos botões)
          Padding(
            padding: const EdgeInsets.only(top: Gaps.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: widget.keyboardType,
                  style: const TextStyle(color: Color(0xFFF2F2F2)),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(color: Color(0xFFA5A5A5)),
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ações no topo direito
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                PillButton(
                  label: 'Cancel',
                  background: const Color(0xFF2B2B2B),
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
                    var text = _controller.text;
                    if (widget.normalizer != null) text = widget.normalizer!(text);
                    if (text.trim().isEmpty) {
                      _toast('This field is required.');
                      return;
                    }
                    final err = widget.validator?.call(text);
                    if (err != null) {
                      _toast(err);
                      return;
                    }
                    widget.onSave(text.trim());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
