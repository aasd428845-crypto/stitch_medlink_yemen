import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class DigitalCardScreen extends StatelessWidget {
  const DigitalCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    if (profile == null) {
      return Theme(
        data: AppTheme.clientLight,
        child: Scaffold(
          backgroundColor: ClientColors.surface,
          body: ClientGlassBackground(
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
    final payload = 'medlink-client:${profile.id}';
    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ClientColors.text,
          title: Text(AppLocalizations.of(context)!.digitalCardTitle),
        ),
        body: ClientGlassBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClientCard(
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
                          colors: [
                            ClientColors.primary,
                            ClientColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ClientColors.primary.withValues(alpha: .35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name ??
                          AppLocalizations.of(context)!.clientAccountContext,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.phone ?? profile.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: ClientColors.text,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: ClientColors.text,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.digitalCardInstruction,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
