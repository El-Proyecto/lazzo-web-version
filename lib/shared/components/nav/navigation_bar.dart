import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

enum NavBarState { normal, eventActive }

class NavigationBar extends StatelessWidget {
  final NavBarState state;
  final int currentIndex;
  final Function(int) onTap;

  const NavigationBar({
    super.key,
    this.state = NavBarState.normal,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.lg,
        vertical: Gaps.xs,
      ),
      decoration: const ShapeDecoration(
        color: BrandColors.bg2,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: BrandColors.bg3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home),
          _buildNavItem(1, Icons.group_outlined, Icons.group),
          _buildCenterButton(),
          _buildNavItem(3, Icons.mail_outline, Icons.mail),
          _buildNavItem(4, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled) {
    final isSelected = currentIndex == index;
    final opacity = isSelected ? 1.0 : 0.6;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            isSelected ? iconFilled : iconOutlined,
            color: BrandColors.text1,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isEventActive = state == NavBarState.eventActive;
    final buttonColor = isEventActive
        ? BrandColors.living
        : BrandColors.planning;
    final icon = isEventActive ? Icons.camera_alt : Icons.add;

    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 44,
        height: 44,
        decoration: ShapeDecoration(
          color: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.smAlt),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
