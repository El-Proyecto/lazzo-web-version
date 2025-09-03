import 'package:flutter/material.dart';

class AuthHomepageCenterText extends StatelessWidget {
  const AuthHomepageCenterText({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 315,
      height: 84,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Plans Made ',
                    style: TextStyle(
                      color: const Color(0xFFF2F2F2),
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.88,
                    ),
                  ),
                  TextSpan(
                    text: 'Easy\n',
                    style: TextStyle(
                      color: const Color(0xFFF2F2F2),
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white, // underline branco
                      height: 0.88,
                    ),
                  ),
                  TextSpan(
                    text: '\nPeople Made ',
                    style: TextStyle(
                      color: const Color(0xFFF2F2F2),
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.88,
                    ),
                  ),
                  TextSpan(
                    text: 'Closer',
                    style: TextStyle(
                      color: const Color(0xFFF2F2F2),
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white, // underline branco
                      height: 0.88,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}