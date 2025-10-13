// lib/features/profile/presentation/widgets/common/notify_row.dart
import 'package:flutter/material.dart';

class NotifyRow extends StatelessWidget {
  const NotifyRow({
    super.key,
    required this.text,
    required this.value,
    this.onChanged,
  });

  final String text;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 23.19,
            height: 23.19,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(width: 2, color: const Color(0xFFA5A5A5)),
              color: value
                  ? const Color(0xFFA5A5A5).withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Color(0xFFF2F2F2))
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 284.31,
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFF2F2F2),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
