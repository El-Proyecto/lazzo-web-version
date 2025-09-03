import 'package:flutter/material.dart';
import '../../../../../shared/constants/spacing.dart';
import '../common/pill_button.dart';

class InlineDateEditor extends StatefulWidget {
  const InlineDateEditor({
    super.key,
    required this.title,
    this.initial,
    required this.onCancel,
    required this.onSave,
    this.firstDate,
    this.lastDate,
  });

  final String title;
  final DateTime? initial;
  final VoidCallback onCancel;
  final ValueChanged<DateTime> onSave;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<InlineDateEditor> createState() => _InlineDateEditorState();
}

class _InlineDateEditorState extends State<InlineDateEditor> {
  DateTime? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(1900, 1, 1);
    final last = widget.lastDate ?? now;

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
          // Conteúdo com “respiro”
          Padding(
            padding: const EdgeInsets.only(top: kActionRowClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final initial = _picked ?? DateTime(now.year - 18, now.month, now.day);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial.isBefore(first) || initial.isAfter(last)
                          ? last
                          : initial,
                      firstDate: first,
                      lastDate: last,
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
                      color: const Color(0xFF2B2B2B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _picked != null
                          ? '${_picked!.day.toString().padLeft(2, '0')}/${_picked!.month.toString().padLeft(2, '0')}/${_picked!.year}'
                          : 'Select a date…',
                      style: const TextStyle(color: Color(0xFFF2F2F2), fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ações
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
                    final d = _picked;
                    if (d == null) {
                      _toast('Select a date.');
                      return;
                    }
                    widget.onSave(d);
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
