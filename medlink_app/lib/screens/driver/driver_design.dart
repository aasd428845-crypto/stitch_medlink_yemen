import 'dart:ui';
import 'package:flutter/material.dart';

class DriverSurface extends StatelessWidget {
  const DriverSurface({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(margin: margin, padding: padding, decoration: BoxDecoration(color: const Color(0xFF0D1B2A).withValues(alpha: .9), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF29445A).withValues(alpha: .75)), boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 24, offset: Offset(0, 12))]), child: child);
}

class DriverHero extends StatelessWidget {
  const DriverHero({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF123B56), Color(0xFF0D2438), Color(0xFF091724)]), border: Border.all(color: const Color(0xFF63D9FF).withValues(alpha: .35))),
    child: Stack(children: [
      Positioned(right: -55, top: -70, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(width: 170, height: 170, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2263D9FF))))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0x2263D9FF), borderRadius: BorderRadius.circular(99)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_shipping_rounded, size: 14, color: Color(0xFF7BE4FF)), SizedBox(width: 6), Text('MedLink Driver', style: TextStyle(color: Color(0xFFC9F5FF), fontWeight: FontWeight.w800, fontSize: 12))])),
        const SizedBox(height: 14),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Color(0xFFA8BDC9), height: 1.45)),
      ]),
    ]),
  );
}
