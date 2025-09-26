import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Banner para mostrar sucesso na criação de evento
/// Exibe temporariamente no topo da página home
class EventCreatedBanner extends StatelessWidget {
  final String eventName;
  final String groupName;
  final VoidCallback? onClose;

  const EventCreatedBanner({
    super.key,
    required this.eventName,
    required this.groupName,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Ícone de sucesso (bola verde com certo branco)
          const SizedBox(
            width: 24,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrandColors.planning,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),

          const SizedBox(width: Gaps.xs),

          // Texto
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                children: [
                  TextSpan(
                    text: eventName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' added to '),
                  TextSpan(
                    text: groupName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '!'),
                ],
              ),
            ),
          ),

          const SizedBox(width: Gaps.xs),

          // Botão fechar
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: BrandColors.text2, size: 20),
          ),
        ],
      ),
    );
  }
}
