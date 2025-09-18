import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    // apenas 1 dígito; avança foco
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    // se ficou vazio (backspace), recua foco
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // notifica quando completo
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 370,
          height: 80,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onChanged(i, v),
                  ),
                  if (i != widget.length - 1) const SizedBox(width: 8),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      child: Container(
        width: 55,
        height: 80,
        decoration: ShapeDecoration(
          color: const Color(0xFF2B2B2B), // Background-3
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF2F2F2),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
          maxLength: 1,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
