import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SwipeToStart extends StatefulWidget {
  const SwipeToStart({
    super.key,
    required this.onStart, // <- novo callback
  });

  /// Chamado uma única vez quando o swipe atinge o limiar (começar registo, etc.)
  final VoidCallback onStart;

  @override
  State<SwipeToStart> createState() => _SwipeToStartState();
}

class _SwipeToStartState extends State<SwipeToStart> {
  double _offset = 0.0;
  bool _swiped = false;

  static const double _maxOffset = 180.0;
  static const double _threshold = 150.0;

  @override
  void initState() {
    super.initState();
    _offset = 0.0;
    _swiped = false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_swiped) return; // já disparou, ignora mais swipes neste ciclo
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(0.0, _maxOffset);
      if (_offset > _threshold && !_swiped) {
        _swiped = true;
        // Dispara a ação definida pelo pai (ex.: navegar para /phone com flow: register)
        widget.onStart();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_swiped) {
      setState(() {
        _offset = 0.0; // volta ao início se não atingiu o limiar
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 296,
      height: 86,
      child: Stack(
        children: [
          // Background
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 296,
              height: 86,
              decoration: ShapeDecoration(
                color: const Color(0xFF2B2B2B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),

          // Swipe handle (circle)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 12 + _offset,
            top: 9,
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                width: 69,
                height: 69,
                decoration: ShapeDecoration(
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 2,
                      color: const Color(0xFF30D343),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main icon inside handle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 30 + _offset,
            top: 31,
            child: SizedBox(
              width: 33,
              height: 33,
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.solidHeart,
                  color: const Color(0xFF30D343),
                  size: 28,
                ),
              ),
            ),
          ),

          // Decorative arrows
          const Positioned(
            left: 215,
            top: 32,
            child: Opacity(
              opacity: 0.66,
              child: FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 22),
            ),
          ),
          const Positioned(
            left: 237,
            top: 32,
            child: Opacity(
              opacity: 0.33,
              child: FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 22),
            ),
          ),
          const Positioned(
            left: 259,
            top: 32,
            child: FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 22),
          ),

          // Swipe text
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 95 + _offset,
            top: 31,
            child: Text(
              _swiped ? '' : 'Swipe to Start!',
              style: const TextStyle(
                color: Color(0xFFF2F2F2),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.50,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
