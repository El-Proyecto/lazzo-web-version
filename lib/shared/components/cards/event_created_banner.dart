import 'package:flutter/material.dart';
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
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Ícone de sucesso (bola verde com certo branco)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: BrandColors.planning,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 16),
          ),

          SizedBox(width: 8),

          // Texto
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                children: [
                  TextSpan(
                    text: eventName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' added to '),
                  TextSpan(
                    text: groupName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '!'),
                ],
              ),
            ),
          ),

          SizedBox(width: 8),

          // Botão fechar
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, color: BrandColors.text2, size: 20),
          ),
        ],
      ),
    );
  }
}
