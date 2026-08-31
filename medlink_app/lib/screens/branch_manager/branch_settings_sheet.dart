import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';

/// Settings modal for the branch manager (gear icon in the shell AppBar):
/// editable branch info, payment bank accounts, notification preferences and
/// sign-out. Uses a modern light glass design with soft TextFields and gradient
/// save buttons.
class BranchSettingsSheet extends StatefulWidget {
  const BranchSettingsSheet({super.key});

  @override
  State<BranchSettingsSheet> createState() => _BranchSettingsSheetState();
}

class _BranchSettingsSheetState extends State<BranchSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _governorateCtrl;
  late final TextEditingController _addressCtrl;

  final _accountFormKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();

  bool _savingInfo = false;
  bool _savingAccount = false;
  bool _savingPrefs = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final branch = context.read<BranchController>().branchInfo;
    _nameCtrl = TextEditingController(text: branch?.name ?? '');
    _governorateCtrl = TextEditingController(text: branch?.governorate ?? '');
    _addressCtrl = TextEditingController(text: branch?.addressText ?? '');
    _load();
  }

  Future<void> _load() async {
    final branch = context.read<BranchController>();
    final auth = context.read<AuthController>();
    final profile = auth.profile;
    await branch.loadBranchInfo();
    if (profile != null) await branch.loadNotificationPreferences(profile.id);
    await branch.loadBankAccounts();
    if (mounted) {
      final info = branch.branchInfo;
      if (info != null) {
        _nameCtrl.text = info.name;
        _governorateCtrl.text = info.governorate ?? '';
        _addressCtrl.text = info.addressText ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _governorateCtrl.dispose();
    _addressCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _savingInfo = true;
      _error = null;
    });
    try {
      await context.read<BranchController>().saveBranchInfo(
            name: _nameCtrl.text.trim(),
            governorate: _governorateCtrl.text.trim(),
            addressText: _addressCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الفرع')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _savePrefs() async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) return;
    setState(() => _savingPrefs = true);
    try {
      await context
          .read<BranchController>()
          .saveNotificationPreferences(profile.id);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  Future<void> _addAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() {
      _savingAccount = true;
      _error = null;
    });
    try {
      await context.read<BranchController>().addBankAccount(
            bankName: _bankNameCtrl.text.trim(),
            accountName: _accountNameCtrl.text.trim(),
            accountNumber: _accountNumberCtrl.text.trim(),
          );
      if (mounted) {
        _bankNameCtrl.clear();
        _accountNameCtrl.clear();
        _accountNumberCtrl.clear();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingAccount = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BranchColors.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthController>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchController>();
    final accounts = branch.bankAccounts;
    final profile = context.watch<AuthController>().profile;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: BranchColors.glassBackgroundStart.withValues(alpha: .97),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BranchColors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  PastelIconBadge(
                    icon: LucideIcons.settings,
                    color: BranchColors.primary,
                    gradient: BranchColors.metricBlueGradient,
                    shape: BoxShape.circle,
                    size: 46,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الإعدادات',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        if (profile?.branchName != null)
                          Text(
                            profile!.branchName!,
                            style: const TextStyle(
                                color: BranchColors.onSurfaceVariant,
                                fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: AppSpacing.md),
              ],

              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // ── Branch Info Section ─────────────────────────────
                    _SectionHeader(
                        icon: LucideIcons.store,
                        title: 'بيانات الفرع',
                        gradient: BranchColors.metricBlueGradient),
                    const SizedBox(height: AppSpacing.sm),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SettingsTextField(
                            label: 'اسم الفرع',
                            controller: _nameCtrl,
                            icon: LucideIcons.store,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'الاسم مطلوب'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsTextField(
                            label: 'المحافظة',
                            controller: _governorateCtrl,
                            icon: LucideIcons.mapPin,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsTextField(
                            label: 'العنوان التفصيلي',
                            controller: _addressCtrl,
                            icon: LucideIcons.navigation,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _GradientButton(
                            label: _savingInfo ? 'جاري الحفظ…' : 'حفظ بيانات الفرع',
                            gradient: BranchColors.metricBlueGradient,
                            onPressed: _savingInfo ? null : _saveInfo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Payment Accounts ────────────────────────────────
                    _SectionHeader(
                        icon: LucideIcons.wallet,
                        title: 'حسابات الدفع',
                        gradient: BranchColors.metricGreenGradient),
                    const SizedBox(height: AppSpacing.sm),
                    if (accounts.isEmpty)
                      _EmptyHint(
                          text:
                              'لا توجد حسابات مسجلة بعد. أضف حساباً لإظهاره للعملاء.')
                    else
                      for (final account in accounts)
                        _BankAccountCard(
                          account: account,
                          onSetDefault: () => context
                              .read<BranchController>()
                              .setDefaultBankAccount(
                                  account['id'] as String),
                          onDelete: () => context
                              .read<BranchController>()
                              .deleteBankAccount(
                                  account['id'] as String),
                        ),
                    const SizedBox(height: AppSpacing.sm),
                    Form(
                      key: _accountFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SettingsTextField(
                            label: 'اسم البنك',
                            controller: _bankNameCtrl,
                            icon: LucideIcons.landmark,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'اسم البنك مطلوب'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsTextField(
                            label: 'اسم صاحب الحساب',
                            controller: _accountNameCtrl,
                            icon: LucideIcons.user,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'اسم صاحب الحساب مطلوب'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsTextField(
                            label: 'رقم الحساب',
                            controller: _accountNumberCtrl,
                            icon: LucideIcons.hash,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'رقم الحساب مطلوب'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _GradientButton(
                            label: _savingAccount ? 'جاري الإضافة…' : 'إضافة حساب',
                            gradient: BranchColors.metricGreenGradient,
                            onPressed: _savingAccount ? null : _addAccount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Notifications ───────────────────────────────────
                    _SectionHeader(
                        icon: LucideIcons.bell,
                        title: 'الإشعارات',
                        gradient: BranchColors.metricPurpleGradient),
                    const SizedBox(height: AppSpacing.xs),
                    _PremiumSwitch(
                      value: branch.prefsNewOrders,
                      title: 'طلبات جديدة',
                      subtitle: 'تنبيه عند وصول طلب جديد',
                      onChanged: branch.setPrefNewOrders,
                    ),
                    _PremiumSwitch(
                      value: branch.prefsLowStock,
                      title: 'مخزون منخفض',
                      subtitle: 'تنبيه عند انخفاض كمية أي صنف',
                      onChanged: branch.setPrefLowStock,
                    ),
                    _PremiumSwitch(
                      value: branch.prefsExpiryAlerts,
                      title: 'تنبيهات انتهاء الصلاحية',
                      subtitle: 'تنبيه عند اقتراب صلاحية أي صنف',
                      onChanged: branch.setPrefExpiryAlerts,
                    ),
                    _PremiumSwitch(
                      value: branch.prefsDriverMessages,
                      title: 'رسائل السائقين',
                      subtitle: 'إشعار عند وصول رسالة من سائق',
                      onChanged: branch.setPrefDriverMessages,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GradientButton(
                      label: _savingPrefs
                          ? 'جاري الحفظ…'
                          : 'حفظ تفضيلات الإشعارات',
                      gradient: BranchColors.metricPurpleGradient,
                      onPressed: _savingPrefs ? null : _savePrefs,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Logout ──────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: BranchColors.error.withValues(alpha: .3)),
                        color: BranchColors.error.withValues(alpha: .04),
                      ),
                      child: TextButton.icon(
                        icon: const Icon(LucideIcons.logOut,
                            color: BranchColors.error, size: 18),
                        label: const Text('تسجيل الخروج',
                            style: TextStyle(
                                color: BranchColors.error,
                                fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _confirmLogout,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: .25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BranchColors.onSurface,
                  fontWeight: FontWeight.w900,
                )),
      ],
    );
  }
}

// ─── Settings Text Field ──────────────────────────────────────────────────────

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          color: BranchColors.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: BranchColors.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: BranchColors.onSurfaceVariant),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: BranchColors.glassHeroGradient.first, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BranchColors.error, width: 1),
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.gradient,
    this.onPressed,
  });

  final String label;
  final List<Color> gradient;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: disabled ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(99),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: .32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled ? Colors.grey.shade500 : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─── Premium Switch ───────────────────────────────────────────────────────────

class _PremiumSwitch extends StatelessWidget {
  const _PremiumSwitch({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? BranchColors.glassHeroGradient.first.withValues(alpha: .06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? BranchColors.glassHeroGradient.first.withValues(alpha: .20)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: BranchColors.onSurface,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: BranchColors.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: BranchColors.glassHeroGradient.first,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

// ─── Empty Hint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: BranchColors.onSurfaceVariant, fontSize: 12),
      ),
    );
  }
}

// ─── Bank Account Card ────────────────────────────────────────────────────────

class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({
    required this.account,
    required this.onSetDefault,
    required this.onDelete,
  });

  final Map<String, dynamic> account;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDefault = account['is_default'] as bool? ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? BranchColors.primary.withValues(alpha: .25)
              : Colors.grey.shade200,
          width: isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDefault
                      ? BranchColors.metricBlueGradient
                      : BranchColors.metricGreenGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDefault
                            ? BranchColors.primary
                            : BranchColors.success)
                        .withValues(alpha: .25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(LucideIcons.landmark,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${account['bank_name'] ?? ''} — ${account['account_name'] ?? ''}',
                    style: const TextStyle(
                        color: BranchColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account['account_number'] ?? '',
                    style: const TextStyle(
                        color: BranchColors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: BranchColors.metricOrangeGradient),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.star,
                        size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text('افتراضي',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              )
            else
              IconButton(
                tooltip: 'تعيين كافتراضي',
                icon: const Icon(LucideIcons.star, size: 18),
                color: BranchColors.onSurfaceVariant,
                onPressed: onSetDefault,
              ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(LucideIcons.trash2, size: 18),
              color: BranchColors.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}