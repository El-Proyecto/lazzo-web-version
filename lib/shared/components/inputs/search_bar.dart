import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Widget de barra de pesquisa tokenizada e reutilizável
class SearchBar extends StatelessWidget {
  final String placeholder;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? prefixIcon;

  const SearchBar({
    super.key,
    required this.placeholder,
    this.value,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: Pads.ctlH, vertical: Pads.ctlV),
      decoration: ShapeDecoration(
        color: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: Row(
        children: [
          // Ícone de pesquisa
          prefixIcon ?? Icon(Icons.search, color: BrandColors.text2, size: 24),
          SizedBox(width: Gaps.md),

          // Campo de texto ou placeholder
          Expanded(
            child: enabled
                ? TextField(
                    onChanged: onChanged,
                    style: AppText.bodyMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: AppText.bodyMediumEmph.copyWith(
                        color: BrandColors.text2,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  )
                : GestureDetector(
                    onTap: onTap,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value ?? placeholder,
                        style: AppText.bodyMediumEmph.copyWith(
                          color: value != null
                              ? BrandColors.text1
                              : BrandColors.text2,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
