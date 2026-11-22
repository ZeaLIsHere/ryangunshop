import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/ryan_app_logo.dart';
import '../view_model/auth_view_model.dart';

/// Layar pendaftaran (Register) dengan pilihan peran Pemilik atau Kasir.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  bool _obscurePassword = true;
  AuthViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= AuthViewModel(session: AppSessionScope.of(context));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final vm = _viewModel;
    if (vm == null) return;

    final user = await vm.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      storeName: _storeNameController.text,
      storeAddress: _storeAddressController.text,
    );

    if (!mounted || user == null) return;

    if (user.isOwner) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.shell,
        (route) => false,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.cashierPending,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = _viewModel;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListenableBuilder(
                listenable: vm ?? ChangeNotifier(),
                builder: (context, _) {
                  final isOwner = vm?.registerRole == UserRole.owner;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand
                      Center(
                        child: Column(
                          children: [
                            const RyanAppLogo(
                              size: 52,
                              showWordmark: false,
                              assetPath: RyanAppLogo.defaultAssetPath,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Pilih Peran Pendaftaran',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Tentukan peran Anda dalam operasional warung',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Role Switcher Cards
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              title: 'Pemilik Toko',
                              subtitle: 'Kelola toko, denah, stok & kasir',
                              icon: Icons.store_outlined,
                              isSelected: isOwner,
                              onTap: () => vm?.setRegisterRole(UserRole.owner),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _RoleCard(
                              title: 'Kasir',
                              subtitle: 'Jual barang & terima pesanan',
                              icon: Icons.point_of_sale_outlined,
                              isSelected: !isOwner,
                              onTap: () => vm?.setRegisterRole(UserRole.cashier),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Pesan Error bila ada
                      if (vm?.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.controlBorder,
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  vm!.errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Form Input
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Data Akun Pengguna',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              label: 'Nama Lengkap',
                              hint: 'Nama Anda',
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => vm?.clearError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Email',
                              hint: 'alamat@email.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => vm?.clearError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildPasswordField(
                              label: 'Kata Sandi',
                              controller: _passwordController,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildPasswordField(
                              label: 'Konfirmasi Kata Sandi',
                              controller: _confirmPasswordController,
                              textInputAction: isOwner
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                            ),

                            // Bagian Khusus Pemilik: Toko
                            if (isOwner) ...[
                              const SizedBox(height: AppSpacing.lg),
                              const Divider(color: AppColors.primaryLight),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Informasi Toko / Warung',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppTextField(
                                label: 'Nama Toko',
                                hint: 'Contoh: Warung Berkah Ryan',
                                controller: _storeNameController,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => vm?.clearError(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                label: 'Alamat Toko (Opsional)',
                                hint: 'Jl. Contoh No. 123',
                                controller: _storeAddressController,
                                textInputAction: TextInputAction.done,
                              ),
                            ] else ...[
                              // Catatan Khusus Kasir
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySubtle,
                                  borderRadius: AppRadius.controlBorder,
                                  border: Border.all(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Akun Kasir tidak memiliki toko otomatis. Anda dapat mulai bekerja setelah mendapatkan dan menerima undangan dari Pemilik toko.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.xl),
                            PrimaryAction(
                              label: isOwner
                                  ? 'Daftar sebagai Pemilik'
                                  : 'Daftar sebagai Kasir',
                              isLoading: vm?.isLoading ?? false,
                              onPressed: _handleRegister,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Link ke Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah memiliki akun? ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'Masuk ke Akun',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required TextInputAction textInputAction,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: 'Minimal 6 karakter',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.controlBorder,
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlBorder,
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.controlBorder,
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.muted,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.controlBorder,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.surface,
          borderRadius: AppRadius.controlBorder,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primaryLight,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.muted,
                  size: 24,
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryDark : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
