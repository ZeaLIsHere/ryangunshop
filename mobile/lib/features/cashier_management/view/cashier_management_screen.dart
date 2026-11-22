import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../view_model/cashier_management_view_model.dart';
import 'invite_cashier_sheet.dart';

/// Halaman pengelolaan kasir dan undangan oleh Pemilik warung.
class CashierManagementScreen extends StatefulWidget {
  const CashierManagementScreen({super.key});

  @override
  State<CashierManagementScreen> createState() =>
      _CashierManagementScreenState();
}

class _CashierManagementScreenState extends State<CashierManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  CashierManagementViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      _viewModel = CashierManagementViewModel(
        session: AppSessionScope.of(context),
      )..load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  void _openInviteSheet() {
    final vm = _viewModel;
    if (vm == null) return;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InviteCashierSheet(
        onInvite: (email) async {
          final ok = await vm.inviteCashier(email);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Undangan berhasil dikirim ke $email'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          return ok;
        },
      ),
    );
  }

  Future<void> _confirmRemoveMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lepas Akses Kasir?'),
        content: Text(
          'Apakah Anda yakin ingin melepas $name dari toko ini? '
          'Kasir akan kehilangan akses operasional toko, namun akun kasirnya tetap utuh '
          'dan dapat diundang kembali sewaktu-waktu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lepas Akses'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _viewModel?.removeMember(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akses $name berhasil dilepas dari toko.'),
          ),
        );
      }
    }
  }

  Future<void> _confirmCancelInvitation(String invId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Undangan?'),
        content: Text('Batalkan undangan kasir untuk $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _viewModel?.cancelInvitation(invId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Undangan untuk $email dibatalkan.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final vm = _viewModel;

    if (!session.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Terbatas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Text(
              'Halaman ini hanya dapat diakses oleh Pemilik toko.',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.error),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Kelola Kasir Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Undang Kasir Baru',
            onPressed: _openInviteSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Kasir Aktif'),
                  if (vm != null && vm.members.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${vm.members.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Undangan'),
                  if (vm != null && vm.pendingInvitations.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${vm.pendingInvitations.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: vm ?? ChangeNotifier(),
          builder: (context, _) {
            if (vm == null || vm.isLoading) {
              return const Center(
                child: BrandSpinner(label: 'Memuat data kasir...'),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Kasir Aktif
                RefreshIndicator(
                  onRefresh: vm.load,
                  child: vm.members.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppSpacing.screen),
                          children: [
                            AppCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Belum Ada Kasir yang Bergabung',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Gunakan tombol "Undang Kasir" untuk menambahkan staf kasir ke toko Anda.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    PrimaryAction(
                                      label: 'Undang Kasir Sekarang',
                                      onPressed: _openInviteSheet,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.screen),
                          itemCount: vm.members.length,
                          itemBuilder: (context, index) {
                            final member = vm.members[index];
                            final joinDate =
                                '${member.joinedAt.day}/${member.joinedAt.month}/${member.joinedAt.year}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        member.userName.isNotEmpty
                                            ? member.userName[0].toUpperCase()
                                            : 'K',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.userName,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          Text(
                                            member.userEmail,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: AppColors.muted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Bergabung sejak: $joinDate',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Lepas Kasir dari Toko',
                                      onPressed: () => _confirmRemoveMember(
                                        member.userId,
                                        member.userName,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Tab 2: Undangan Menunggu
                RefreshIndicator(
                  onRefresh: vm.load,
                  child: vm.pendingInvitations.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppSpacing.screen),
                          children: [
                            AppCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.mail_outline,
                                      size: 48,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Tidak Ada Undangan Menunggu',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Semua undangan kasir telah direspons atau belum ada yang dikirimkan.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.screen),
                          itemCount: vm.pendingInvitations.length,
                          itemBuilder: (context, index) {
                            final inv = vm.pendingInvitations[index];
                            final sendDate =
                                '${inv.createdAt.day}/${inv.createdAt.month}/${inv.createdAt.year}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            AppRadius.controlBorder,
                                      ),
                                      child: const Icon(
                                        Icons.schedule,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.cashierEmail,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          Text(
                                            'Dikirim: $sendDate • Status: Menunggu',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Batalkan Undangan',
                                      onPressed: () =>
                                          _confirmCancelInvitation(
                                        inv.id,
                                        inv.cashierEmail,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.person_add),
        label: const Text('Undang Kasir'),
        onPressed: _openInviteSheet,
      ),
    );
  }
}
