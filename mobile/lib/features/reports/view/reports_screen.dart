import 'package:flutter/material.dart';

import '../../../core/data/transaction_repository.dart' as db;
import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/theme/app_radius.dart';
import '../model/daily_report_export.dart';
import '../model/report_scenario.dart';
import '../sample/reports_sample.dart';
import '../view_model/reports_view_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    this.repository,
    this.shareReport = shareDailyReport,
    super.key,
  });
  final db.TransactionRepository? repository;
  final ReportShare shareReport;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsViewModel _model;
  bool _initialized = false;
  int? _dataRevision;
  bool _showAll = false;
  bool _exporting = false;
  String? _exportError;

  bool get _canReport =>
      AppSessionScope.maybeOf(context)?.role != UserRole.cashier;

  Future<void> _export({required bool pdf}) async {
    if (!_canReport ||
        _exporting ||
        _model.status != ReportsStatus.ready ||
        !_model.isLocal) {
      return;
    }
    setState(() {
      _exporting = true;
      _exportError = null;
    });
    try {
      final report = DailyReportExport(_model);
      final bytes = pdf ? await report.pdf() : report.xlsx();
      if (!mounted || !_canReport) return;
      await widget.shareReport(
        bytes,
        report.filename(pdf ? 'pdf' : 'xlsx'),
        pdf ? 'application/pdf' : DailyReportExport.xlsxMimeType,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _exportError = 'Ekspor gagal. Coba lagi lewat tombol bagikan.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = ReportsViewModel(
      repository: widget.repository,
      loadDelay: Duration.zero,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = AppSessionScope.maybeOf(context)?.dataRevision;
    if (_initialized) {
      if (widget.repository == null && revision != _dataRevision) _model.load();
      _dataRevision = revision;
      return;
    }
    _dataRevision = revision;
    _initialized = true;
    final repository =
        widget.repository ??
        AppSessionScope.maybeOf(context)?.transactionRepository;
    if (repository != _model.repository) {
      _model.updateRepository(repository);
    } else {
      _model.load();
    }
  }

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _model.updateRepository(
        widget.repository ??
            AppSessionScope.maybeOf(context)?.transactionRepository,
      );
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _model.selectedDay,
      initialEntryMode:
          MediaQuery.sizeOf(context).width >= AppSpacing.minTouchTarget * 16
          ? DatePickerEntryMode.input
          : DatePickerEntryMode.calendar,
      firstDate: DateTime(1970),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Pilih tanggal laporan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted || day == null) return;
    setState(() => _showAll = false);
    await _model.selectDay(day);
  }

  String _date(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';

  Widget _action(String label, VoidCallback? action) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(
        AppSpacing.minTouchTarget,
        AppSpacing.minTouchTarget,
      ),
    ),
    onPressed: _exporting ? null : action,
    child: Text(label),
  );

  Widget _exportButton(String label, IconData icon, VoidCallback? action) =>
      TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primarySubtle,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
        ),
        onPressed: _exporting ? null : action,
        icon: Icon(icon),
        label: Text(label),
      );

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    ),
  );

  Widget _amount(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_canReport ? 'Laporan harian' : 'Riwayat Nota')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.minTouchTarget * 16,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tanggal laporan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                        ),
                        onPressed: _exporting ? null : _pickDay,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text('Tanggal: ${_date(_model.selectedDay)}'),
                      ),
                      Row(
                        children: [
                          _action('Hari ini', () {
                            setState(() => _showAll = false);
                            _model.selectDay(DateTime.now());
                          }),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Muat ulang',
                            onPressed: _exporting ? null : () => _model.load(),
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_model.isLocal) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pratinjau data contoh · waktu lokal perangkat',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
                if (!_model.isLocal)
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final scenario in ReportScenario.values)
                        _action(
                          scenario.label,
                          () => _model.load(scenario: scenario),
                        ),
                    ],
                  ),
                ..._body(),
                if (_canReport && _model.isLocal)
                  _section('Bagikan laporan', [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'PDF untuk ringkasan · Excel untuk rincian',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            children: [
                              _exportButton(
                                'Bagikan PDF',
                                Icons.picture_as_pdf_outlined,
                                _model.status == ReportsStatus.ready
                                    ? () => _export(pdf: true)
                                    : null,
                              ),
                              _exportButton(
                                'Bagikan Excel',
                                Icons.table_chart_outlined,
                                _model.status == ReportsStatus.ready
                                    ? () => _export(pdf: false)
                                    : null,
                              ),
                            ],
                          ),

                          if (_exporting)
                            const BrandSpinner(label: 'Menyiapkan ekspor…'),
                          if (_exportError != null)
                            Semantics(
                              liveRegion: true,
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                  ),
                                  Text(
                                    _exportError!,
                                    semanticsLabel: _exportError,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Pilih aplikasi atau lokasi penyimpanan di menu berbagi Android. Tidak otomatis tersimpan ke Downloads.',
                          ),
                          const ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text('Isi berkas dan cara menyimpan'),
                            children: [
                              Text(
                                'PDF: ringkasan dan semua produk. Excel (.xlsx): lembar Ringkasan, '
                                'Transaksi (satu baris per nota), dan Barang Terjual '
                                '(kotor sebelum diskon nota). '
                                'Pilih tujuan berbagi atau penyimpanan yang tersedia di Android. '
                                'Berkas belum tersimpan permanen sebelum disimpan lewat tujuan tersebut.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
                const SizedBox(height: AppSpacing.md),
                const ExpansionTile(
                  title: Text('Tentang data laporan'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Transaksi pada perangkat ini saja, bukan gabungan semua perangkat. Tanggal dan jam mengikuti waktu lokal perangkat. Data dapat dibuka offline.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _body() {
    if (_model.status == ReportsStatus.loading) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: BrandSpinner(label: ReportsSample.loadingLabel),
            ),
          ),
        ),
      ];
    }
    if (_model.status == ReportsStatus.failure) {
      return [
        _stateCard(
          icon: Icons.error_outline,
          title: ReportsSample.errorTitle,
          description: ReportsSample.errorDescription,
          action: 'Coba lagi',
          onPressed: () => _model.load(),
          error: true,
        ),
      ];
    }
    if (!_model.hasRecords) {
      return [
        _stateCard(
          icon: Icons.receipt_long_outlined,
          title: ReportsSample.emptyTitle,
          description: 'Tidak ada transaksi pada tanggal ini. Pilih tanggal lain untuk melihat penjualan.',
          action: 'Pilih tanggal lain',
          onPressed: _pickDay,
        ),
        _action('Kembali ke beranda', () => Navigator.of(context).maybePop()),
      ];
    }
    final products = _model.soldProducts;
    return [
      if (_canReport)
        _section('Ringkasan harian', [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: AppRadius.panelBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Penjualan bersih'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatRupiah(_model.totalAmount),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_model.records.length} transaksi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _amount(
                  'Rata-rata per nota',
                  formatRupiah(_model.averageAmount.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _amount('Penjualan kotor', formatRupiah(_model.grossAmount)),
                _amount('Diskon nota', formatRupiah(_model.discountAmount)),
              ],
            ),
          ),
        ]),
      if (_canReport && _model.isLocal) ...[
        _section('Metode pembayaran tercatat', [
          AppCard(
            child: Column(
              children: [
                for (final entry in _model.paymentBreakdown.entries)
                  _amount(
                    '${reportPaymentLabel(entry.key)} · ${entry.value.count} nota',
                    formatRupiah(entry.value.total),
                  ),
              ],
            ),
          ),
        ]),
        _section('Produk terlaris', [
          const Text(
            'Urutan jumlah terjual. Nilai kotor sebelum diskon nota; '
            'nama berasal dari snapshot penjualan terbaru.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (products.isEmpty)
                  const Text('Rincian barang tidak tersimpan.'),
                for (final product in (_showAll ? products : products.take(5)))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${product.quantity} barang · ${formatRupiah(product.gross)}',
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (products.length > 5)
            _action(
              _showAll ? 'Tampilkan 5 teratas' : 'Lihat semua produk',
              () => setState(() => _showAll = !_showAll),
            ),
        ]),
      ],
      _section('Daftar nota', [
        for (var index = 0; index < _model.records.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _model.records[index].title.isEmpty
                        ? '${_model.records[index].timeLabel} · ${_model.records[index].itemCount} barang'
                        : _model.records[index].title,
                  ),
                  Text(_model.records[index].id),
                  Text(
                    '${_model.records[index].timeLabel} · ${_model.isLocal ? reportPaymentLabel(_model.dailyRecords[index].paymentMethod) : _model.records[index].paymentMethod.label}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatRupiah(_model.records[index].total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_model.isLocal)
                    _action(
                      'Lihat nota',
                      () => _openReceipt(_model.dailyRecords[index]),
                    ),
                ],
              ),
            ),
          ),
      ]),
    ];
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String description,
    required String action,
    required VoidCallback onPressed,
    bool error = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              icon,
              size: AppSpacing.minTouchTarget,
              color: error ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _exporting ? null : onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    ),
  );

  void _openReceipt(db.TransactionRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Detail nota')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text(
                  record.id,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${_date(record.createdAt.toLocal())} · '
                  '${TimeOfDay.fromDateTime(record.createdAt.toLocal()).format(context)}',
                ),
                Text(reportPaymentLabel(record.paymentMethod)),
                const Text(
                  'Snapshot barang saat transaksi · tersimpan di perangkat',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (record.items.isEmpty)
                  const Text('Rincian barang tidak tersimpan.'),
                for (final item in record.items) ...[
                  Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${item.quantity} × ${formatRupiah(item.unitPrice)}'),
                  Text(formatRupiah(item.subtotal)),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _amount(
                  'Penjualan kotor',
                  formatRupiah(record.totalAmount + record.discountAmount),
                ),
                _amount('Diskon nota', formatRupiah(record.discountAmount)),
                _amount('Total bayar', formatRupiah(record.totalAmount)),
                if (record.cashReceived != null)
                  _amount('Uang diterima', formatRupiah(record.cashReceived!)),
                if (record.changeAmount != null)
                  _amount('Kembalian', formatRupiah(record.changeAmount!)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
