import 'dart:ui';

import 'package:flutter/material.dart';

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
        color: const Color(0xFF0D1B2A).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A4458).withValues(alpha: .65)),
        boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 24, offset: Offset(0, 12))],
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
          colors: [Color(0xFF123B56), Color(0xFF0D2438), Color(0xFF091724)],
        ),
        border: Border.all(color: Color(0xFF55DDE0), width: .8),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -55,
            bottom: -70,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(width: 170, height: 170, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2255DDE0))),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0x2255DDE0), borderRadius: BorderRadius.circular(99)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, size: 14, color: Color(0xFF75E9E2)),
                  SizedBox(width: 6),
                  Text('MedLink', style: TextStyle(color: Color(0xFFC6FFFB), fontWeight: FontWeight.w800, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 14),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Color(0xFFA8BDC9), height: 1.45)),
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'البحث في الأدوية والمنتجات',
          hintStyle: const TextStyle(color: Color(0xFF7890A0)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF63D9FF)),
          suffixIcon: controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { controller.clear(); onSubmitted(''); }),
          filled: true,
          fillColor: const Color(0xFF0D1B2A),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF29445A))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF63D9FF), width: 1.2)),
        ),
      ),
    );
  }
}
