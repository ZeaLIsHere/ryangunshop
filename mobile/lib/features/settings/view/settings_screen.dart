import 'package:flutter/material.dart';

import '../../../core/config/firebase_bootstrap.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../sample/settings_sample.dart';
import '../view_model/settings_view_model.dart';

/// Halaman pengaturan: peran pengguna, akses mode edit, dan info warung.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= SettingsViewModel(session: AppSessionScope.of(context));
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _SettingsContent(viewModel: viewModel),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(text: SettingsSample.rolesSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final role in viewModel.roleOptions) ...[
            _RoleOption(
              role: role,
              isSelected: role == viewModel.selectedRole,
              onTap: () => viewModel.selectRole(role),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            SettingsSample.rolesSectionNote,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(text: SettingsSample.floorPlanAccessTitle),
          const SizedBox(height: AppSpacing.sm),
          _FloorPlanAccessStatus(canEdit: viewModel.canEditFloorPlan),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(text: SettingsSample.storeSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          const _StoreProfileCard(),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(text: SettingsSample.hardwareSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.print_disabled_outlined,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Belum ada printer terhubung',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(text: SettingsSample.syncSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Row(
              children: [
                Icon(
                  FirebaseBootstrap.isReady
                      ? Icons.cloud_done_outlined
                      : (FirebaseBootstrap.enabled
                            ? Icons.cloud_sync_outlined
                            : Icons.storage_outlined),
                  color: FirebaseBootstrap.isReady
                      ? AppColors.success
                      : (FirebaseBootstrap.enabled
                            ? AppColors.warning
                            : AppColors.muted),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    FirebaseBootstrap.isReady
                        ? 'Firebase terhubung (${FirebaseBootstrap.storeId}). Sinkronisasi cloud aktif.'
                        : (FirebaseBootstrap.enabled
                              ? (FirebaseBootstrap.lastError != null
                                    ? 'Gagal terhubung ke Firebase: ${FirebaseBootstrap.lastError}'
                                    : 'Menghubungkan ke Firebase...')
                              : 'Penyimpanan lokal aktif. Sinkronisasi cloud belum tersedia.'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(text: SettingsSample.aboutSectionTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Text(
              SettingsSample.aboutDescription,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.headlineSmall);
  }
}

/// Satu pilihan peran pengguna.
///
/// Keadaan terpilih disampaikan lewat ikon, teks, dan warna sekaligus.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(role.description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Status ketersediaan mode edit denah mengikuti peran yang aktif.
class _FloorPlanAccessStatus extends StatelessWidget {
  const _FloorPlanAccessStatus({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = canEdit ? AppColors.success : AppColors.muted;
    return AppCard(
      child: Row(
        children: [
          Icon(
            canEdit ? Icons.lock_open_outlined : Icons.lock_outline,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              canEdit
                  ? SettingsSample.floorPlanAccessAllowed
                  : SettingsSample.floorPlanAccessLocked,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreProfileCard extends StatelessWidget {
  const _StoreProfileCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.controlCompactBorder,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil warung belum diatur',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Nama dan alamat toko akan tersedia setelah data warung diisi.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
