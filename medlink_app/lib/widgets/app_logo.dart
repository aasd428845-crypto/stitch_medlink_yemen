import 'package:flutter/material.dart';

import '../utils/theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: AppColors.onPrimary,
          size: size * 0.55,
        ),
      ),
    );
  }
}
