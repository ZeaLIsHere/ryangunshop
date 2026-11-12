import 'package:flutter/material.dart';

import '../../../core/data/transaction_repository.dart'
    show TransactionRepository;
import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/report_payment_method.dart';
import '../model/report_scenario.dart';
import '../model/transaction_record.dart';
import '../sample/reports_sample.dart';
import '../view_model/reports_view_model.dart';

/// Layar riwayat dan laporan transaksi.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({this.repository, super.key});

  final TransactionRepository? repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsViewModel _viewModel;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ReportsViewModel(
      repository: widget.repository,
      loadDelay: Duration.zero,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.repository == null) {
        final sessionRepo = AppSessionScope.maybeOf(context)
            ?.transactionRepository;
        if (sessionRepo != null) {
          _viewModel.updateRepository(sessionRepo);
          return;
        }
      }
      _viewModel.load();
    }
  }

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _viewModel.updateRepository(widget.repository);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat transaksi')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SampleBadge(
                    label: _viewModel.isLocal
                        ? 'Tersimpan di perangkat'
                        : 'Laporan contoh',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SummaryCard(
                  total: _viewModel.totalAmount,
                  transactionCount: _viewModel.records.length,
                ),
                const SizedBox(height: AppSpacing.lg),
                _ScenarioSelector(
                  selected: _viewModel.scenario,
                  onSelected: (scenario) => _viewModel.load(scenario: scenario),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_viewModel.status) {
      case ReportsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: BrandSpinner(label: ReportsSample.loadingLabel),
        );
      case ReportsStatus.failure:
        return _MessageState(
          icon: Icons.error_outline,
          color: AppColors.error,
          title: ReportsSample.errorTitle,
          description: ReportsSample.errorDescription,
          actionLabel: 'Coba lagi',
          onAction: () => _viewModel.load(),
        );
      case ReportsStatus.ready:
        if (!_viewModel.hasRecords) {
          return _MessageState(
            assetPath: 'assets/icon/03_riwayat_transaksi.png',
            icon: Icons.receipt_long_outlined,
            color: AppColors.muted,
            title: ReportsSample.emptyTitle,
            description: ReportsSample.emptyDescription,
            actionLabel: 'Kembali ke beranda',
            onAction: () => Navigator.of(context).maybePop(),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final record in _viewModel.records) ...[
              _RecordCard(record: record),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.transactionCount});

  final int total;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.panelBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.16),
                  borderRadius: AppRadius.controlCompactBorder,
                ),
                child: Image.asset(
                  'assets/icon/03_riwayat_transaksi.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  ReportsSample.summaryTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.16),
                  borderRadius: AppRadius.fixtureBorder,
                ),
                child: Text(
                  'Hari ini',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(total),
              style: AppTypography.total(color: AppColors.surface),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$transactionCount transaksi',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pemilih skenario contoh agar setiap state dapat dicoba.
class _ScenarioSelector extends StatelessWidget {
  const _ScenarioSelector({required this.selected, required this.onSelected});

  final ReportScenario selected;
  final ValueChanged<ReportScenario> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ReportsSample.scenarioTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(ReportsSample.scenarioNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final scenario in ReportScenario.values)
              ChoiceChip(
                label: Text(scenario.label),
                selected: scenario == selected,
                onSelected: (_) => onSelected(scenario),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCash = record.paymentMethod == ReportPaymentMethod.cash;
    return AppCard(
      semanticLabel:
          'Transaksi ${record.id}, ${formatRupiah(record.total)}, '
          '${record.paymentMethod.label}',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.controlCompactBorder,
            ),
            child: Icon(
              isCash ? Icons.payments_outlined : Icons.qr_code_2,
              size: 20,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title.isNotEmpty
                      ? '${record.title} · ${record.itemCount} barang'
                      : '${record.timeLabel} · ${record.itemCount} barang',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${record.id} · ${record.paymentMethod.label} · ${record.timeLabel}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatRupiah(record.total),
            style: theme.textTheme.labelLarge?.copyWith(
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// State pesan dengan tindakan lanjutan.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.assetPath,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          assetPath != null
              ? Image.asset(
                  assetPath!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(icon, size: 40, color: color),
                )
              : Icon(icon, size: 40, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
