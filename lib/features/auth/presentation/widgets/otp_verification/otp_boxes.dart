import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/themes/colors.dart';

class OtpCodeBoxes extends StatefulWidget {
  const OtpCodeBoxes({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onResend,
  });

  final int length;
  final void Function(String code)? onCompleted;
  final VoidCallback? onResend;

  @override
  State<OtpCodeBoxes> createState() => _OtpCodeBoxesState();
}

class _OtpCodeBoxesState extends State<OtpCodeBoxes> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // Rebuild to update visual boxes

    // Notify when complete (6 digits entered)
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
      // Optionally dismiss keyboard
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = _controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          // Visual boxes (decorative only)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (i) {
                final hasDigit = i < currentCode.length;
                final digit = hasDigit ? currentCode[i] : '';
                final isActive = i == currentCode.length;

                return Flexible(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: Gaps.xs / 2),
                    child: _OtpBox(
                      digit: digit,
                      isActive: isActive,
                    ),
                  ),
                );
              }),
            ),
          ),
          // Invisible TextField that captures all input
          Positioned.fill(
            child: Opacity(
              opacity: 0.01, // Nearly invisible but still focusable
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofocus: true,
                maxLength: widget.length,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: _onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.isActive,
  });

  final String digit;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.6,
      child: Container(
        decoration: ShapeDecoration(
          color: BrandColors.bg3,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            side: isActive
                ? const BorderSide(color: BrandColors.planning, width: 2)
                : BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(
            color: BrandColors.text1,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
