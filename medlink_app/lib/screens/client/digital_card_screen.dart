import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/auth_controller.dart';
import '../../utils/theme.dart';

class DigitalCardScreen extends StatelessWidget {
  const DigitalCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final payload = 'medlink-client:${profile.id}';
    return Scaffold(
      appBar: AppBar(title: const Text('بطاقتي الرقمية')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Icon(Icons.medical_services_rounded,
                      size: 42, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(profile.name ?? 'عميل MedLink',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(profile.phone ?? profile.email,
                      style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.lg),
                  QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.onSurface,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.onSurface,
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('اعرض هذا الرمز للتحقق من بطاقتك الرقمية'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}