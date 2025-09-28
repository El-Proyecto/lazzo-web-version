import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Item do menu contextual
class GroupMenuAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;
  final bool isDestructive;

  const GroupMenuAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.textColor,
    this.isDestructive = false,
  });
}

/// Menu contextual para ações do grupo (long-press)
class GroupContextMenu extends StatelessWidget {
  final List<GroupMenuAction> actions;
  final VoidCallback? onClose;

  const GroupContextMenu({super.key, required this.actions, this.onClose});

  /// Exibe o menu contextual relativo ao card
  static Future<void> show({
    required BuildContext context,
    required List<GroupMenuAction> actions,
    required GlobalKey cardKey,
  }) async {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    // Obter posição e tamanho do card
    final renderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final cardPosition = renderBox.localToGlobal(Offset.zero);
    final cardSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Calcular posição do menu (preferencialmente abaixo do card)
    double menuTop = cardPosition.dy + cardSize.height + Gaps.sm;
    double menuLeft = cardPosition.dx + Gaps.md;

    // Se o menu não cabe abaixo, colocar acima
    if (menuTop + 300 > screenSize.height) {
      menuTop = cardPosition.dy - 300 - Gaps.sm;
    }

    // Se o menu não cabe à direita, ajustar à esquerda
    if (menuLeft + 200 > screenSize.width) {
      menuLeft = screenSize.width - 200 - Gaps.md;
    }

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop semi-transparente para fechar o menu
          GestureDetector(
            onTap: () => entry.remove(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.1),
            ),
          ),

          // Destacar o card com borda fina e discreta
          Positioned(
            left: cardPosition.dx,
            top: cardPosition.dy,
            child: Container(
              width: cardSize.width,
              height: cardSize.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: BrandColors.text2.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
          ),

          // Menu contextual
          Positioned(
            left: menuLeft,
            top: menuTop,
            child: GroupContextMenu(
              actions: actions,
              onClose: () => entry.remove(),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map((action) => _buildMenuItem(context, action))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, GroupMenuAction action) {
    return InkWell(
      onTap: () {
        // Fechar o menu
        onClose?.call();
        // Executar a ação
        action.onTap();
      },
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Gaps.sm,
        ),
        child: Row(
          children: [
            Icon(
              action.icon,
              color: action.isDestructive
                  ? BrandColors.cantVote
                  : action.textColor ?? BrandColors.text1,
              size: 20,
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: Text(
                action.title,
                style: AppText.bodyMediumEmph.copyWith(
                  color: action.isDestructive
                      ? BrandColors.cantVote
                      : action.textColor ?? BrandColors.text1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
