import 'package:flutter/material.dart';

class CreateProfileHeader extends StatelessWidget {
  const CreateProfileHeader({
    super.key,
    this.title = 'Create Profile',
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left placeholder / leading
          SizedBox(
            width: 25.34,
            height: 24,
            child: leading ?? const SizedBox.shrink(),
          ),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF2F2F2), // Text-1
              fontSize: 22,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.27,
            ),
          ),

          // Right placeholder / trailing
          SizedBox(
            width: 25.34,
            height: 24,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
