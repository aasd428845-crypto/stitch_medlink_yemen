import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';

/// Settings modal for the branch manager (gear icon in the shell AppBar):
/// editable branch info, payment bank accounts, notification preferences and
/// sign-out. Data is backed by migration 0010 (notification_preferences,
/// branch_bank_accounts, branches_manager_update_own).
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

  // add-account form
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
      await context.read<BranchController>().saveNotificationPreferences(profile.id);
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
    final prefs = branch.bankAccounts;
    final profile = context.watch<AuthController>().profile;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: BranchColors.heroGradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.settings_rounded, color: BranchColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الإعدادات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      profile?.branchName ?? '',
                      style: const TextStyle(color: BranchColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
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
                const _SectionHeader(icon: Icons.storefront_rounded, title: 'بيانات الفرع'),
                const SizedBox(height: AppSpacing.sm),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'اسم الفرع',
                        controller: _nameCtrl,
                        prefixIcon: Icons.store_outlined,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: 'المحافظة',
                        controller: _governorateCtrl,
                        prefixIcon: Icons.map_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: 'العنوان',
                        controller: _addressCtrl,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPrimaryButton(
                        label: 'حفظ بيانات الفرع',
                        onPressed: _saveInfo,
                        isLoading: _savingInfo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionHeader(icon: Icons.account_balance_wallet_rounded, title: 'حسابات الدفع'),
                const SizedBox(height: AppSpacing.sm),
                if (prefs.isEmpty)
                  const _EmptyHint(text: 'لا توجد حسابات مسجلة بعد. أضف حساباً لإظهاره للعملاء.')
                else
                  for (final account in prefs)
                    _BankAccountTile(
                      account: account,
                      onSetDefault: () => context
                          .read<BranchController>()
                          .setDefaultBankAccount(account['id'] as String),
                      onDelete: () => context
                          .read<BranchController>()
                          .deleteBankAccount(account['id'] as String),
                    ),
                const SizedBox(height: AppSpacing.sm),
                Form(
                  key: _accountFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'اسم البنك',
                        controller: _bankNameCtrl,
                        prefixIcon: Icons.account_balance_rounded,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'اسم البنك مطلوب' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: 'اسم صاحب الحساب',
                        controller: _accountNameCtrl,
                        prefixIcon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'اسم صاحب الحساب مطلوب' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: 'رقم الحساب',
                        controller: _accountNumberCtrl,
                        prefixIcon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'رقم الحساب مطلوب' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPrimaryButton(
                        label: 'إضافة حساب',
                        onPressed: _addAccount,
                        isLoading: _savingAccount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionHeader(icon: Icons.notifications_rounded, title: 'الإشعارات'),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  value: branch.prefsNewOrders,
                  onChanged: (v) => branch.setPrefNewOrders(v),
                  title: const Text('طلبات جديدة', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('تنبيه عند وصول طلب جديد إلى الفرع'),
                  activeTrackColor: BranchColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: branch.prefsLowStock,
                  onChanged: (v) => branch.setPrefLowStock(v),
                  title: const Text('مخزون منخفض', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('تنبيه عند انخفاض كمية أي صنف عن حد إعادة الطلب'),
                  activeTrackColor: BranchColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: branch.prefsExpiryAlerts,
                  onChanged: (v) => branch.setPrefExpiryAlerts(v),
                  title: const Text('تنبيهات انتهاء الصلاحية', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('تنبيه عند اقتراب صلاحية أي صنف في المخزون'),
                  activeTrackColor: BranchColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: branch.prefsDriverMessages,
                  onChanged: (v) => branch.setPrefDriverMessages(v),
                  title: const Text('رسائل السائقين', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('إشعار عند وصول رسالة من أحد السائقين'),
                  activeTrackColor: BranchColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: 'حفظ تفضيلات الإشعارات',
                  onPressed: _savePrefs,
                  isLoading: _savingPrefs,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: BranchColors.error),
                  label: const Text('تسجيل الخروج', style: TextStyle(color: BranchColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: BranchColors.error),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: _confirmLogout,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: BranchColors.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: BranchColors.primary),
        ),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(color: BranchColors.onSurface, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return BranchManagerSurface(
      padding: const EdgeInsets.all(13),
      child: Text(
        text,
        style: const TextStyle(color: BranchColors.onSurfaceVariant, fontSize: 12),
      ),
    );
  }
}

class _BankAccountTile extends StatelessWidget {
  const _BankAccountTile({
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
    return BranchManagerSurface(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDefault ? BranchColors.primary : BranchColors.success)
                  .withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: 19,
              color: isDefault ? BranchColors.primary : BranchColors.success,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${account['bank_name'] ?? ''} — ${account['account_name'] ?? ''}',
                  style: const TextStyle(color: BranchColors.onSurface, fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  account['account_number'] ?? '',
                  style: const TextStyle(color: BranchColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isDefault)
            IconButton(
              tooltip: 'تعيين كافتراضي',
              icon: const Icon(Icons.star_outline_rounded, size: 20),
              color: BranchColors.onSurfaceVariant,
              onPressed: onSetDefault,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.star_rounded, size: 20, color: BranchColors.warning),
            ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: BranchColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}