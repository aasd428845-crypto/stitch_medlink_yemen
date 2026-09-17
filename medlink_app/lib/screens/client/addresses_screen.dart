import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/client_address.dart';
import '../../services/order_controller.dart';
import '../../utils/error_mapper.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

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
    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          scrolledUnderElevation: 0,
          foregroundColor: ClientColors.text,
          title: Text(l10n.deliveryAddress),
        ),
        body: ClientGlassBackground(
          child: controller.isLoading && controller.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.addressesLoading),
                    ],
                  ),
                )
              : controller.error != null && controller.addresses.isEmpty
              ? _AddressesError(
                  message: controller.error!,
                  onRetry: () =>
                      context.read<OrderController>().loadAddresses(),
                )
              : controller.addresses.isEmpty
              ? Center(
                  child: ClientCard(
                    padding: const EdgeInsets.all(32),
                    borderRadius: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClientIconBadge(
                          icon: Icons.location_off_outlined,
                          color: ClientColors.textMuted,
                          size: 56,
                          iconSize: 28,
                          shape: BoxShape.circle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAddressesSaved,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.addAddressForDelivery,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: ClientColors.primary,
                  onRefresh: () =>
                      context.read<OrderController>().loadAddresses(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: controller.addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _AddressTile(address: controller.addresses[i]),
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addAddress(context),
          backgroundColor: ClientColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(l10n.addNewAddress),
        ),
      ),
    );
  }

  Future<void> _addAddress(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          Theme(data: AppTheme.clientLight, child: const _AddAddressSheet()),
    );
    if (result == true && mounted) setState(() {});
  }
}

class _AddressesError extends StatelessWidget {
  const _AddressesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClientCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ClientIconBadge(
                icon: Icons.error_outline_rounded,
                color: ClientColors.danger,
                size: 52,
                iconSize: 26,
                shape: BoxShape.circle,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ─── Add Address Bottom Sheet ─────────────────────────────────────────────────

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _governorateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  LatLng? _point;
  bool _saving = false;
  bool _isDefault = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _detailsCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _landmarkCtrl.dispose();
    _governorateCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await context.read<OrderController>().saveAddress(
        label: _labelCtrl.text.trim(),
        addressText: _detailsCtrl.text.trim(),
        latitude: _point?.latitude,
        longitude: _point?.longitude,
        isDefault: _isDefault,
        ownerName: _ownerCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        altPhone: _altPhoneCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        governorate: _governorateCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (e) {
      if (mounted) {
        final message = e.code == '42703'
            ? l10n.dbColumnNotFoundError
            : mapAuthErrorToMessage(l10n, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: ClientColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mapAuthErrorToMessage(l10n, e)),
            backgroundColor: ClientColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      child: Container(
        height: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 20),
        decoration: const BoxDecoration(color: ClientColors.background),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: bottom + 16),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ClientColors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ClientColors.primary,
                            ClientColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.addNewAddress,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Section: معلومات العنوان ──────────────────────────
                _SectionLabel(
                  icon: Icons.location_on_outlined,
                  label: l10n.addressInformation,
                  gradient: const [
                    ClientColors.primary,
                    ClientColors.primaryDark,
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labelCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.addressLabel,
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailsCtrl,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.addressText,
                    prefixIcon: Icon(Icons.edit_location_alt_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),

                // ── Section: الموقع الجغرافي ──────────────────────────
                _SectionLabel(
                  icon: Icons.map_outlined,
                  label: l10n.locationInformation,
                  gradient: const [ClientColors.success, ClientColors.primary],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _governorateCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.governorateLabel,
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.cityDistrictLabel,
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.districtLabel,
                          prefixIcon: Icon(Icons.holiday_village_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _landmarkCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.landmarkLabel,
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // خريطة
                StatefulBuilder(
                  builder: (ctx, setInner) => OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await Navigator.of(context).push<LatLng>(
                        MaterialPageRoute(builder: (_) => const _MapPicker()),
                      );
                      if (selected != null) {
                        setState(() => _point = selected);
                        setInner(() {});
                      }
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      _point == null
                          ? l10n.chooseLocationOnMap
                          : l10n.locationSelected,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _point != null
                          ? ClientColors.success
                          : ClientColors.primary,
                      side: BorderSide(
                        color: _point != null
                            ? ClientColors.success
                            : ClientColors.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Section: معلومات صاحب المنشأة ─────────────────────
                _SectionLabel(
                  icon: Icons.business_outlined,
                  label: l10n.ownerInformation,
                  gradient: const [ClientColors.primaryDark, ClientColors.navy],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ownerCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.ownerNameLabel,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.phoneLabel,
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _altPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.alternatePhoneLabel,
                          prefixIcon: Icon(Icons.phone_callback_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClientCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  borderRadius: 16,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                    activeThumbColor: ClientColors.primary,
                    title: Text(
                      l10n.defaultAddressLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      l10n.defaultAddressHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                  ],
                ),
              ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(l10n.saveAddressButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.gradient,
  });
  final IconData icon;
  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: ClientColors.text,
          ),
        ),
      ],
    );
  }
}

// ─── Address Tile ─────────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address});
  final ClientAddress address;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClientCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientIconBadge(
            icon: address.isDefault
                ? Icons.home_rounded
                : Icons.location_on_outlined,
            color: ClientColors.primary,
            size: 44,
            iconSize: 20,
            borderRadius: 14,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  address.addressText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (address.governorate != null || address.city != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (address.governorate?.isNotEmpty == true)
                        address.governorate!,
                      if (address.city?.isNotEmpty == true) address.city!,
                      if (address.district?.isNotEmpty == true)
                        address.district!,
                    ].join(' - '),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ClientColors.textMuted,
                    ),
                  ),
                ],
                if (address.phone?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: ClientColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        address.phone!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ClientColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (address.isDefault) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ClientColors.primarySoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      l10n.defaultAddressBadge,
                      style: const TextStyle(
                        color: ClientColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: ClientColors.danger),
            onPressed: () =>
                context.read<OrderController>().deleteAddress(address.id),
          ),
        ],
      ),
    );
  }
}

// ─── Map Picker ───────────────────────────────────────────────────────────────

class _MapPicker extends StatefulWidget {
  const _MapPicker();

  @override
  State<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<_MapPicker> {
  static const _default = LatLng(15.3694, 44.1910);
  LatLng _selected = _default;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.chooseLocationOnMap),
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
