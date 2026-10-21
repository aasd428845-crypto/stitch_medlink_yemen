import 'package:flutter/material.dart';

import '../utils/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? ClientColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: foregroundColor ?? Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
