import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/auth_controller.dart';
import '../../utils/theme.dart';
import '../branch_manager/branch_manager_design.dart';

class DigitalCardScreen extends StatelessWidget {
  const DigitalCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    if (profile == null) {
      return Theme(
        data: AppTheme.branchManagerLight,
        child: Scaffold(backgroundColor: Colors.transparent, body: BranchGlassBackground(child: const Center(child: CircularProgressIndicator()))),
      );
    }
    final payload = 'medlink-client:${profile.id}';
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BranchColors.onSurface,
          title: const Text('بطاقتي الرقمية'),
        ),
        body: BranchGlassBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                borderRadius: 32,
                tint: 0.82,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: BranchColors.glassHeroGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BranchColors.glassHeroGradient.first.withValues(alpha: .35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(profile.name ?? 'عميل MedLink', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(profile.phone ?? profile.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: BranchColors.onSurface),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: BranchColors.onSurface),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text('اعرض هذا الرمز للتحقق من بطاقتك الرقمية', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}