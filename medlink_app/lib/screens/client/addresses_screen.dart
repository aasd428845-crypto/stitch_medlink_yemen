import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/client_address.dart';
import '../../services/order_controller.dart';
import '../../utils/theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderController>().loadAddresses(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<OrderController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deliveryAddress)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAddress(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.addNewAddress),
      ),
      body: controller.addresses.isEmpty
          ? const Center(child: Text('لا توجد عناوين محفوظة'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: controller.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, i) => _AddressTile(address: controller.addresses[i]),
            ),
    );
  }

  Future<void> _addAddress(BuildContext context) async {
    final label = TextEditingController();
    final details = TextEditingController();
    LatLng? point;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.addNewAddress),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.addressLabel,
                  ),
                ),
                TextField(
                  controller: details,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.addressText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await Navigator.of(context).push<LatLng>(
                      MaterialPageRoute(builder: (_) => const _MapPicker()),
                    );
                    if (selected != null) setState(() => point = selected);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(point == null
                      ? 'اختيار الموقع من الخريطة'
                      : 'تم تحديد الموقع ✓'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (label.text.trim().isEmpty || details.text.trim().isEmpty) return;
                await context.read<OrderController>().saveAddress(
                      label: label.text.trim(),
                      addressText: details.text.trim(),
                      latitude: point?.latitude,
                      longitude: point?.longitude,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: Text(AppLocalizations.of(context)!.saveAddress),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address});
  final ClientAddress address;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          address.isDefault ? Icons.home_rounded : Icons.location_on_outlined,
          color: AppColors.primary,
        ),
        title: Text(address.label),
        subtitle: Text(address.addressText),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => context.read<OrderController>().deleteAddress(address.id),
        ),
      ),
    );
  }
}

class _MapPicker extends StatefulWidget {
  const _MapPicker();

  @override
  State<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<_MapPicker> {
  static const _default = LatLng(15.3694, 44.1910); // Sana'a map centre only.
  LatLng _selected = _default;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('حدد موقع العنوان'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ],
        ),
        body: GoogleMap(
          initialCameraPosition: const CameraPosition(target: _default, zoom: 13),
          markers: {
            Marker(
              markerId: const MarkerId('selected-address'),
              position: _selected,
            ),
          },
          onTap: (point) => setState(() => _selected = point),
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
      );
}