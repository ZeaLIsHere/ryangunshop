import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/report_scenario.dart';
import '../model/transaction_record.dart';
import '../sample/reports_sample.dart';
import '../view_model/reports_view_model.dart';

/// Layar riwayat dan laporan transaksi.
///
/// Memakai data contoh, tetapi menyediakan state memuat, kosong, dan gagal yang
/// benar-benar dapat dicoba lewat pemilih skenario.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsViewModel _viewModel = ReportsViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.load();
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
            icon: Icons.receipt_long_outlined,
            color: AppColors.muted,
            title: ReportsSample.emptyTitle,
            description: ReportsSample.emptyDescription,
            actionLabel: 'Kembali ke denah',
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ReportsSample.summaryTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SampleBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRupiah(total),
            style: AppTypography.total(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text('$transactionCount transaksi', style: theme.textTheme.bodySmall),
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
    return AppCard(
      semanticLabel:
          'Transaksi ${record.id}, ${formatRupiah(record.total)}, '
          '${record.paymentMethod.label}',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.timeLabel} · ${record.itemCount} barang',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${record.id} · ${record.paymentMethod.label}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(formatRupiah(record.total), style: theme.textTheme.labelLarge),
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
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
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
