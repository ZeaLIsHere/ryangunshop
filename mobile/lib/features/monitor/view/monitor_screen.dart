import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_bootstrap.dart';
import '../../../core/data/monitor_layout_repository.dart';
import '../../../core/data/sync/monitor_sync.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../model/monitor_layout.dart';
import '../view_model/monitor_view_model.dart';
import 'monitor_canvas.dart';
import 'monitor_editor_screen.dart';

/// Halaman Monitor Toko (Mode Pantau Spasial 2.5D Isometrik & Alert Stok).
class MonitorScreen extends StatefulWidget {
  const MonitorScreen({this.viewModel, super.key});
  final MonitorViewModel? viewModel;

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  MonitorViewModel? _model;
  int? _dataRevision;
  MonitorLayoutRepository? _repository;
  bool _leavingRole = false;
  bool _checkingCloud = false;
  bool _filterAlertsOnly = false;
  String? _searchHighlightedId;

  bool get _owner =>
      mounted && AppSessionScope.of(context).role.canManageProducts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppSessionScope.of(context);
    final db = session.database;
    if (_model == null && widget.viewModel != null && _owner) {
      _model = widget.viewModel;
      _model!.load();
    }
    if (_model == null && db != null && _owner) {
      final repo = MonitorLayoutRepository(
        db,
        queue: session.syncQueue,
        fetchRemote: FirebaseBootstrap.isReady
            ? () => fetchMonitorLayout(
                FirebaseFirestore.instance,
                FirebaseBootstrap.storeId,
              )
            : null,
      );
      _repository = repo;
      _model = MonitorViewModel(
        loadLayout: () async {
          await repo.refresh();
          return repo.load();
        },
        loadProducts: () => session.productRepository.listProducts(),
        saveLayout: (layout, revision) => repo.save(
          layout,
          expectedRevision: revision,
          canSave: () => _owner,
        ),
        canEdit: () => _owner,
      );
      _model!.load();
    }
    if (_model != null && _dataRevision != session.dataRevision) {
      _dataRevision = session.dataRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _model?.refreshProducts();
      });
    }
    if (!_owner && _model != null && !_leavingRole) {
      _leavingRole = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _owner) {
          _leavingRole = false;
          return;
        }
        final route = ModalRoute.of(context);
        final navigator = Navigator.of(context);
        navigator.popUntil(
          (candidate) => candidate == route || candidate.isFirst,
        );
        if (route != null && route.isCurrent && navigator.canPop()) {
          navigator.pop();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _model?.dispose();
    super.dispose();
  }

  Future<void> _openEditor() async {
    final model = _model;
    if (model == null || !_owner) return;
    model.edit();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MonitorEditorScreen(viewModel: model)),
    );
    if (mounted) {
      await model.load();
    }
  }

  Future<void> _checkCloud() async {
    if (_checkingCloud || _model == null) return;
    _checkingCloud = true;
    final repo = _repository!;
    await repo.refresh();
    _checkingCloud = false;
    if (!mounted || !_owner) return;
    final pending = await repo.pending();
    if (!mounted || !_owner) return;
    final error = repo.cloudError;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Layout Cloud'),
        content: Text(
          error != null
              ? 'Cloud belum tersedia. Layout lokal tetap aman. Periksa jaringan dan izin toko.'
              : pending.isNotEmpty
              ? 'Layout lokal masih antre. Konflik server atau izin dapat menghambat unggah. Muat versi cloud akan membuang layout dan penempatan lokal yang belum terkirim.'
              : repo.fetchRemote == null
              ? 'Cloud belum diaktifkan. Layout hanya disimpan pada perangkat ini.'
              : 'Pembacaan cloud berhasil. Tidak ada antrean layout lokal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tutup'),
          ),
          if (pending.isNotEmpty && repo.fetchRemote != null)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buang lokal, muat cloud'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (answer == true && _owner) await repo.refresh(discardPending: true);
    if (mounted && _owner) await _model!.load();
  }

  Future<void> _productDetails(
    String? fixtureId, {
    bool alertsOnly = false,
  }) async {
    if (!_owner) return;
    final model = _model!;
    List<dynamic> source() =>
        (fixtureId == null && alertsOnly
                ? model.products
                : model.productsAt(fixtureId))
            .where((p) => !alertsOnly || p.stock <= p.lowStockThreshold)
            .toList();

    final fixture = model.layout?.fixtures
        .where((f) => f.id == fixtureId)
        .firstOrNull;

    Widget content(BuildContext context) => ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final items = source();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alertsOnly
                            ? 'Stok Perlu Perhatian'
                            : fixture?.name ?? 'Belum Ditempatkan',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Stok total produk tercatat di sistem, bukan sensor fisik rak.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (model.productsError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    model.productsError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada produk pada daftar ini.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final p = items[idx];
                            final isOut = p.stock == 0;
                            final isLow =
                                p.stock > 0 && p.stock <= p.lowStockThreshold;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : isLow
                                      ? AppColors.warning.withValues(
                                          alpha: 0.12,
                                        )
                                      : AppColors.primarySubtle,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.squircle,
                                  ),
                                ),
                                child: Icon(
                                  isOut
                                      ? Icons.remove_shopping_cart_outlined
                                      : isLow
                                      ? Icons.warning_amber_rounded
                                      : Icons.inventory_2_outlined,
                                  color: isOut
                                      ? AppColors.error
                                      : isLow
                                      ? AppColors.warning
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${p.category} · ${p.locationLabel}',
                              ),
                              trailing: Text(
                                '${p.stock} ${p.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOut
                                      ? AppColors.error
                                      : isLow
                                      ? AppColors.warning
                                      : AppColors.ink,
                                ),
                              ),
                              onTap: () {
                                final id = model.layout?.assignments[p.id];
                                if (id != null) model.select(id);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (MediaQuery.sizeOf(context).width >= AppSpacing.minTouchTarget * 16) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: AppSpacing.minTouchTarget * 9,
            height: MediaQuery.sizeOf(context).height * .85,
            child: content(context),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: content(context),
        ),
      );
    }
  }

  IconData _fixtureIcon(MonitorFixtureType type) => switch (type) {
    MonitorFixtureType.fridge => Icons.kitchen_outlined,
    MonitorFixtureType.showcase => Icons.storefront_outlined,
    MonitorFixtureType.cashCounter => Icons.point_of_sale_outlined,
    MonitorFixtureType.shelf => Icons.shelves,
  };

  Future<void> _openSpatialSearch() async {
    final model = _model;
    if (model == null || !_owner) return;
    await model.refreshProducts();
    if (!mounted) return;

    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          final q = query.trim().toLowerCase();
          final matches = model.products.where((p) {
            return q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.locationLabel.toLowerCase().contains(q);
          }).toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom) *
                    0.80,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cari Lokasi Produk',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            tooltip: 'Tutup',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Ketik nama produk atau kategori…',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (v) => setSheet(() => query = v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(
                                child: Text(
                                  'Produk tidak ditemukan.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: matches.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final p = matches[index];
                                  final fixtureId =
                                      model.layout?.assignments[p.id];
                                  final fixture = model.layout?.fixtures
                                      .where((f) => f.id == fixtureId)
                                      .firstOrNull;
                                  final isOut = p.stock == 0;
                                  final isLow = p.stock > 0 &&
                                      p.stock <= p.lowStockThreshold;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isOut
                                            ? AppColors.error
                                                .withValues(alpha: 0.12)
                                            : isLow
                                                ? AppColors.warning
                                                    .withValues(alpha: 0.12)
                                                : AppColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.squircle),
                                      ),
                                      child: Icon(
                                        isOut
                                            ? Icons.remove_shopping_cart_outlined
                                            : isLow
                                                ? Icons.warning_amber_rounded
                                                : (fixture != null
                                                    ? _fixtureIcon(fixture.type)
                                                    : Icons
                                                        .inventory_2_outlined),
                                        color: isOut
                                            ? AppColors.error
                                            : isLow
                                                ? AppColors.warning
                                                : AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      fixture != null
                                          ? 'Lokasi: ${fixture.name} (${fixture.type.label})'
                                          : 'Belum ditempatkan di denah',
                                      style: TextStyle(
                                        color: fixture != null
                                            ? AppColors.primary
                                            : AppColors.muted,
                                        fontWeight: fixture != null
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${p.stock} ${p.unit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isOut
                                            ? AppColors.error
                                            : isLow
                                                ? AppColors.warning
                                                : AppColors.ink,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      if (fixtureId != null) {
                                        setState(() {
                                          _searchHighlightedId = fixtureId;
                                        });
                                        model.select(fixtureId);
                                      } else {
                                        _productDetails(null);
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickPeekCard(BuildContext context, MonitorViewModel model) {
    final fixtureId = model.selectedId;
    final fixture = model.layout?.fixtures
        .where((f) => f.id == fixtureId)
        .firstOrNull;
    if (fixture == null) return const SizedBox.shrink();

    final counts = model.counts(fixture.id);
    final prods = model.productsAt(fixture.id);
    final isOut = counts.out > 0;
    final isLow = counts.low > 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOut
                  ? AppColors.error.withValues(alpha: 0.12)
                  : isLow
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
            ),
            child: Icon(
              _fixtureIcon(fixture.type),
              color: isOut
                  ? AppColors.error
                  : isLow
                      ? AppColors.warning
                      : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fixture.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${fixture.type.label} · ${prods.length} produk${isOut ? " · ${counts.out} habis" : ""}${isLow ? " · ${counts.low} menipis" : ""}',
                  style: TextStyle(
                    color: isOut
                        ? AppColors.error
                        : (isLow ? AppColors.warning : AppColors.muted),
                    fontSize: 11,
                    fontWeight: isOut || isLow
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
            ),
            onPressed: () => _productDetails(fixture.id),
            child: const Text('Rincian', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: AppSpacing.xxs),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Tutup',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => model.select(''),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;

    if (!_owner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monitor Toko')),
        body: const Center(child: Text('Monitor hanya untuk pemilik.')),
      );
    }
    if (model == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monitor Toko')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_android_outlined,
                  size: 36,
                  color: AppColors.muted,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Penyimpanan denah lokal tersedia pada aplikasi Android.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Monitor Toko'),
            actions: [
              if (model.layout != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.minTouchTarget - 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    onPressed: _openEditor,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Tata Letak'),
                  ),
                ),
            ],
          ),
          body: () {
            if (model.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Memuat tata letak toko',
                ),
              );
            }

            // 1. KASUS PERTAMA KALI (Belum ada layout tersimpan): Tampilkan Wizard Template
            if (model.layout == null) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  Text(
                    'Atur Tata Letak Toko',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Pilih salah satu susunan awal toko Anda. Anda bisa memindahkan, menambah rak, kulkas, dan etalase kapan saja.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final template in MonitorTemplate.values) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: AspectRatio(
                              aspectRatio: 2,
                              child: ColoredBox(
                                color: AppColors.primarySubtle,
                                child: CustomPaint(
                                  painter: _LayoutPreview(template.create()),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSpacing.minTouchTarget,
                              ),
                            ),
                            onPressed: () {
                              model.chooseTemplate(template);
                              _openEditor();
                            },
                            icon: const Icon(
                              Icons.grid_view_outlined,
                              size: 18,
                            ),
                            label: Text('Gunakan Template ${template.label}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              );
            }

            // 2. KASUS TATA LETAK SUDAH ADA: Tampilan Pantau Spasial 2.5D
            final layout = model.layout!;
            final counts = model.counts(null);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Baris Alert Chips & Navigasi Pantau
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.xs,
                  ),
                  color: AppColors.surface,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: Icon(
                            counts.out > 0
                                ? Icons.error_outline
                                : Icons.warning_amber_outlined,
                            size: 16,
                            color: counts.out > 0
                                ? AppColors.error
                                : AppColors.warning,
                          ),
                          label: Text(
                            '${counts.out} habis · ${counts.low} menipis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: counts.out > 0
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                          backgroundColor:
                              (counts.out > 0
                                      ? AppColors.error
                                      : AppColors.warning)
                                  .withValues(alpha: 0.12),
                          side: BorderSide.none,
                          onPressed: () =>
                              _productDetails(null, alertsOnly: true),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        FilterChip(
                          avatar: Icon(
                            _filterAlertsOnly
                                ? Icons.visibility
                                : Icons.filter_alt_outlined,
                            size: 16,
                            color: _filterAlertsOnly
                                ? AppColors.surface
                                : AppColors.ink,
                          ),
                          label: Text(
                            _filterAlertsOnly
                                ? 'Sorot: Perlu Restok'
                                : 'Sorot Perlu Restok',
                            style: TextStyle(
                              color: _filterAlertsOnly
                                  ? AppColors.surface
                                  : AppColors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          selected: _filterAlertsOnly,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          onSelected: (val) =>
                              setState(() => _filterAlertsOnly = val),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ActionChip(
                          avatar: const Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                          ),
                          label: Text(
                            '${model.productsAt(null).length} belum ditempatkan',
                          ),
                          backgroundColor: AppColors.primarySubtle,
                          side: BorderSide.none,
                          onPressed: () => _productDetails(null),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ActionChip(
                          avatar: const Icon(
                            Icons.search,
                            size: 16,
                          ),
                          label: const Text('Cari Produk'),
                          backgroundColor: AppColors.canvas,
                          side: const BorderSide(
                            color: AppColors.borderSubtle,
                          ),
                          onPressed: _openSpatialSearch,
                        ),
                        if (_repository != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          ActionChip(
                            avatar: const Icon(
                              Icons.cloud_sync_outlined,
                              size: 16,
                            ),
                            label: const Text('Status Cloud'),
                            backgroundColor: AppColors.canvas,
                            side: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                            onPressed: _checkCloud,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Kanvas Isometrik Utama
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MonitorCanvas(
                          layout: layout,
                          selectedId: model.selectedId,
                          editing: false,
                          counts: model.counts,
                          filterAlertsOnly: _filterAlertsOnly,
                          highlightedId: _searchHighlightedId,
                          onSelect: (id) {
                            setState(() {
                              _searchHighlightedId = null;
                            });
                            model.select(id);
                          },
                          onMove: (id, x, y) {},
                        ),
                      ),
                      if (model.selectedId != null &&
                          model.layout?.fixtures
                                  .any((f) => f.id == model.selectedId) ==
                              true)
                        Positioned(
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: _buildQuickPeekCard(context, model),
                        ),
                    ],
                  ),
                ),

                // Daftar Aksesibel Cepat di Bawah (Dapat Digulir Horizontal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Daftar Objek (${layout.fixtures.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Detail stok',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: layout.fixtures.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: AppSpacing.xs),
                          itemBuilder: (context, idx) {
                            final f = layout.fixtures[idx];
                            final n = model.counts(f.id);
                            final isSelected = f.id == model.selectedId;

                            return ActionChip(
                              avatar: Icon(
                                _fixtureIcon(f.type),
                                size: 16,
                                color: isSelected
                                    ? AppColors.surface
                                    : AppColors.primary,
                              ),
                              label: Text(
                                '${idx + 1}. ${f.name}${n.out + n.low > 0 ? " (!)" : ""}',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.surface
                                      : AppColors.ink,
                                ),
                              ),
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : AppColors.primarySubtle,
                              side: BorderSide.none,
                              onPressed: () {
                                model.select(f.id);
                                _productDetails(f.id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }(),
        );
      },
    );
  }
}

/// Preview ortografik editor sederhana untuk wizard pemilihan template awal
class _LayoutPreview extends CustomPainter {
  _LayoutPreview(this.layout);
  final MonitorLayout layout;
  final String? selectedId = null;

  @override
  void paint(Canvas canvas, Size size) {
    final cell =
        (size.width / layout.gridWidth < size.height / layout.gridHeight)
        ? size.width / layout.gridWidth
        : size.height / layout.gridHeight;
    final origin = Offset(
      (size.width - cell * layout.gridWidth) / 2,
      (size.height - cell * layout.gridHeight) / 2,
    );
    final grid = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;
    for (var x = 0; x <= layout.gridWidth; x++) {
      canvas.drawLine(
        origin + Offset(x * cell, 0),
        origin + Offset(x * cell, layout.gridHeight * cell),
        grid,
      );
    }
    for (var y = 0; y <= layout.gridHeight; y++) {
      canvas.drawLine(
        origin + Offset(0, y * cell),
        origin + Offset(layout.gridWidth * cell, y * cell),
        grid,
      );
    }
    for (final fixture in layout.fixtures) {
      final rect = Rect.fromLTWH(
        origin.dx + fixture.x * cell,
        origin.dy + fixture.y * cell,
        fixture.width * cell,
        fixture.height * cell,
      ).deflate(1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(AppRadius.fixtureCompact),
        ),
        Paint()
          ..color = fixture.id == selectedId
              ? AppColors.primary
              : AppColors.primaryLight,
      );
      final label = TextPainter(
        text: TextSpan(
          text: fixture.name,
          style: TextStyle(
            color: fixture.id == selectedId
                ? AppColors.surface
                : AppColors.primaryDark,
            fontSize: AppSpacing.sm,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: rect.width);
      canvas.save();
      canvas.clipRect(rect);
      label.paint(canvas, rect.topLeft);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LayoutPreview oldDelegate) =>
      oldDelegate.layout != layout;
}
