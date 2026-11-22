import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/cashier_invitation.dart';

/// Layar penampung kasir yang belum terhubung dengan toko.
class CashierPendingInvitationScreen extends StatefulWidget {
  const CashierPendingInvitationScreen({super.key});

  @override
  State<CashierPendingInvitationScreen> createState() =>
      _CashierPendingInvitationScreenState();
}

class _CashierPendingInvitationScreenState
    extends State<CashierPendingInvitationScreen> {
  List<CashierInvitation> _invitations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvitations());
  }

  Future<void> _loadInvitations() async {
    final session = AppSessionScope.of(context);
    final user = session.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await session.authRepository.listCashierInvitations(user.email);
      if (!mounted) return;
      setState(() {
        _invitations = list.where((i) => i.isPending).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat daftar undangan. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation(CashierInvitation invitation) async {
    final session = AppSessionScope.of(context);
    final user = session.currentUser;
    if (user == null) return;

    try {
      await session.authRepository.acceptInvitation(
        invitationId: invitation.id,
        cashierId: user.id,
      );
      await session.refreshCurrentUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil bergabung dengan toko ${invitation.storeName}!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Beralih ke layar operasional toko
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.shell,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectInvitation(CashierInvitation invitation) async {
    final session = AppSessionScope.of(context);
    try {
      await session.authRepository.rejectInvitation(invitation.id);
      await _loadInvitations();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Undangan toko ditolak.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final session = AppSessionScope.of(context);
    await session.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final user = session.currentUser;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Menunggu Undangan Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _loadInvitations,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInvitations,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Profil Kasir
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'K',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Akun Kasir',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: AppRadius.controlBorder,
                              ),
                              child: Text(
                                'Kasir - Belum Terhubung Toko',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bagian Undangan Masuk
                Text(
                  'Undangan Bergabung ke Toko',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Terima undangan dari Pemilik warung untuk mengaktifkan akses kasir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: BrandSpinner(label: 'Memeriksa undangan...'),
                    ),
                  )
                else if (_errorMessage != null)
                  AppCard(
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PrimaryAction(
                          label: 'Coba Lagi',
                          onPressed: _loadInvitations,
                        ),
                      ],
                    ),
                  )
                else if (_invitations.isEmpty)
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 48,
                            color: AppColors.muted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Belum Ada Undangan Toko',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'Berikan email Anda (${user?.email}) kepada Pemilik toko agar dapat diundang ke tokonya.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Periksa Ulang'),
                            onPressed: _loadInvitations,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._invitations.map((inv) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      inv.storeName,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: AppRadius.controlBorder,
                                    ),
                                    child: Text(
                                      'Undangan',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.primaryDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Pengundang: ${inv.ownerEmail}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _rejectInvitation(inv),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(
                                          color: AppColors.error,
                                        ),
                                      ),
                                      child: const Text('Tolak'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _acceptInvitation(inv),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.surface,
                                      ),
                                      child: const Text('Terima'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),

                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Keluar dari Akun Ini'),
                    onPressed: _handleLogout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
