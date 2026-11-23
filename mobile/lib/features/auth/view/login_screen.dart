import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/ryan_app_logo.dart';
import '../view_model/auth_view_model.dart';

/// Layar masuk (Login) akun RyanGunshop.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  AuthViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= AuthViewModel(session: AppSessionScope.of(context));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final vm = _viewModel;
    if (vm == null) return;

    final user = await vm.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || user == null) return;

    // Arahkan berdasarkan role dan status toko
    if (user.isOwner || user.hasActiveStore) {
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListenableBuilder(
                listenable: vm ?? ChangeNotifier(),
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo dan Brand Header
                      Center(
                        child: Column(
                          children: [
                            const RyanAppLogo(
                              size: 64,
                              showWordmark: true,
                              assetPath: RyanAppLogo.defaultAssetPath,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Masuk ke Akun Anda',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Kelola kasir dan operasional warung dengan mudah',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Pesan Error jika ada
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

                      // Form Kartu
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Email Pengguna',
                              hintText: 'contoh@warung.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => vm?.clearError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kata Sandi',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleLogin(),
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
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.controlBorder,
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryLight,
                                      ),
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
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PrimaryAction(
                              label: 'Masuk Sekarang',
                              isLoading: vm?.isLoading ?? false,
                              onPressed: _handleLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Link ke Registrasi
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Belum memiliki akun? ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.register);
                            },
                            child: Text(
                              'Daftar Baru',
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
}
