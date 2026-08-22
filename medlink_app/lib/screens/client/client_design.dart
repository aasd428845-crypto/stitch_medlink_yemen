import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class ClientDesignSurface extends StatelessWidget {
  const ClientDesignSurface({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: .65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnightNavy.withValues(alpha: .19),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ClientHero extends StatelessWidget {
  const ClientHero({super.key, required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryContainer,
            AppColors.deepBlue,
            AppColors.surfaceContainerLowest,
          ],
        ),
        border: Border.all(color: AppColors.tertiary, width: .8),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -55,
            bottom: -70,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary.withValues(alpha: .13),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, size: 14, color: AppColors.tertiary),
                  SizedBox(width: 6),
                  Text('MedLink', style: TextStyle(color: AppColors.onTertiaryContainer, fontWeight: FontWeight.w800, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 14),
               Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, height: 1.45)),
            ],
          ),
        ],
      ),
    );
  }
}

class ClientSearchField extends StatelessWidget {
  const ClientSearchField({super.key, required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
         style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'البحث في الأدوية والمنتجات',
          hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { controller.clear(); onSubmitted(''); }),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}
