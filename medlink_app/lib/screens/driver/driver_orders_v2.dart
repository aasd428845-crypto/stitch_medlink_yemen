import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'driver_design.dart';
import 'driver_orders_tab.dart';

class DriverOrdersV2 extends StatelessWidget {
  const DriverOrdersV2({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      DriverHero(title: l10n.driverOrdersLabel, subtitle: 'تابع مهام التوصيل وحالة الطلبات من شاشة واحدة.'),
      const Expanded(child: DriverOrdersTab()),
    ]);
  }
}
