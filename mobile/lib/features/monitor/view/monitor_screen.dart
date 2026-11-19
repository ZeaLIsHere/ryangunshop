import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_bootstrap.dart';
import '../../../core/data/sync/monitor_sync.dart';
import 'monitor_canvas.dart';

import '../../../core/data/monitor_layout_repository.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../model/monitor_layout.dart';
import '../view_model/monitor_view_model.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({this.viewModel, super.key});
  final MonitorViewModel? viewModel;
  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  MonitorViewModel? _model;
  bool _allowPop = false;
  int? _dataRevision;
  MonitorLayoutRepository? _repository;
  bool _leavingRole = false;
  bool _checkingCloud = false;
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
        // Tutup juga dialog/sheet di atas Monitor, bukan hanya route paling atas.
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

  Future<void> _leave() async {
    final model = _model;
    if (model?.saving ?? false) return;
    if (model?.dirty ?? false) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Simpan perubahan?'),
          content: const Text('Perubahan tata letak belum disimpan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('Tetap edit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Buang perubahan'),
            ),
            FilledButton(
              onPressed: model!.conflict
                  ? null
                  : () => Navigator.pop(context, 'save'),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == 'stay') return;
      if (choice == 'save' && !await model!.save()) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _cancel() async {
    final model = _model!;
    if (model.dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Buang perubahan tata letak?'),
          content: const Text(
            'Tata letak yang sudah tersimpan tetap dipertahankan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tetap edit'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buang perubahan'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    final hadConflict = model.conflict;
    model.cancel();
    if (hadConflict) await model.load();
  }

  Future<void> _rename() async {
    final model = _model!;
    final fixture = model.selected;
    if (fixture == null) return;
    var name = fixture.name;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nama objek'),
        content: TextFormField(
          initialValue: name,
          onChanged: (value) => name = value,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nama rak atau objek'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.trim()),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );

    if (mounted && _owner && value != null) model.change(name: value);
  }

  Future<void> _delete() async {
    final model = _model!;
    final selected = model.selected;
    if (selected == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${selected.name}?'),
        content: const Text(
          'Produk tidak dihapus. Penempatannya dilepas saat Simpan; stok tidak berubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus objek'),
          ),
        ],
      ),
    );
    if (mounted && _owner && yes == true) model.remove();
  }

  Future<void> _checkCloud() async {
    if (!_owner || _checkingCloud || _model!.editing || _model!.saving) return;
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
        title: const Text('Status layout cloud'),
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
          if (pending.isNotEmpty &&
              repo.fetchRemote != null &&
              !_model!.editing)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buang lokal, muat cloud'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (answer == true && _owner) await repo.refresh(discardPending: true);
    if (mounted && _owner && !_model!.editing) await _model!.load();
  }

  Future<void> _assignProducts() async {
    final model = _model!;
    final fixture = model.selected;
    if (!_owner || fixture == null || !model.editing) return;
    await model.refreshProducts();
    if (!mounted || !_owner || model.productsError != null) return;
    final chosen = model.productsAt(fixture.id).map((p) => p.id).toSet();
    var query = '';
    String? category;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom) *
                  .85,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  children: [
                    Text(
                      'Produk di ${fixture.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Produk dari rak lain dipindahkan setelah konfirmasi dan Simpan.',
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cari produk',
                      ),
                      onChanged: (v) => setSheet(() => query = v.toLowerCase()),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: category == null,
                            onSelected: (_) => setSheet(() => category = null),
                          ),
                          for (final c
                              in model.products.map((p) => p.category).toSet())
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                              ),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: category == c,
                                onSelected: (_) => setSheet(() => category = c),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final p in model.products.where(
                            (p) =>
                                p.name.toLowerCase().contains(query) &&
                                (category == null || p.category == category),
                          ))
                            CheckboxListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                '${p.stock} ${p.unit} · ${p.locationLabel}',
                              ),
                              value: chosen.contains(p.id),
                              onChanged: (value) => setSheet(() {
                                if (value == true) {
                                  chosen.add(p.id);
                                } else {
                                  chosen.remove(p.id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Terapkan ${chosen.length} produk'),
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
      ),
    );
    if (!mounted || !_owner || confirmed != true) return;
    model.assign({
      for (final e in model.layout!.assignments.entries)
        if (e.value != fixture.id && !chosen.contains(e.key)) e.key: e.value,
      for (final id in chosen) id: fixture.id,
    });
  }

  Future<void> _productDetails(
    String? fixtureId, {
    bool alertsOnly = false,
  }) async {
    if (!_owner) return;
    final model = _model!;
    source() =>
        (fixtureId == null && alertsOnly
                ? model.products
                : model.productsAt(fixtureId))
            .where((p) => !alertsOnly || p.stock <= p.lowStockThreshold)
            .toList();
    final fixture = model.layout!.fixtures
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
                Text(
                  alertsOnly
                      ? 'Stok perlu perhatian'
                      : fixture?.name ?? 'Belum ditempatkan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Stok total tercatat produk, bukan hitungan fisik per rak.',
                ),
                if (model.productsError != null) Text(model.productsError!),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text('Belum ada produk pada daftar ini.'),
                        )
                      : ListView(
                          children: [
                            for (final p in items)
                              ListTile(
                                leading: Icon(
                                  p.stock == 0
                                      ? Icons.error_outline
                                      : p.stock <= p.lowStockThreshold
                                      ? Icons.warning_amber_outlined
                                      : Icons.inventory_2_outlined,
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${p.stock} ${p.unit} · ${p.stock == 0
                                      ? 'Habis'
                                      : p.stock <= p.lowStockThreshold
                                      ? 'Menipis'
                                      : 'Tersedia'}',
                                ),
                                onTap: () {
                                  final id = model.layout!.assignments[p.id];
                                  if (id != null) model.select(id);
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
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

  Widget _button(String label, IconData icon, VoidCallback? action) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
        ),
        onPressed: action,
        icon: Icon(icon),
        label: Text(label),
      );

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return PopScope(
      canPop:
          !_owner ||
          _allowPop ||
          (!(_model?.dirty ?? false) && !(_model?.saving ?? false)),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitor'),
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _leave,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: !_owner
            ? const Center(child: Text('Monitor hanya untuk pemilik.'))
            : model == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_android_outlined),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Editor tata letak tersedia pada aplikasi Android dengan penyimpanan lokal.',
                      ),
                      TextButton(
                        onPressed: _leave,
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                ),
              )
            : ListenableBuilder(
                listenable: model,
                builder: (context, _) {
                  if (model.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Memuat tata letak',
                      ),
                    );
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.minTouchTarget * 22,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        children: [
                          if (model.error != null) ...[
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                  ),
                                  Text(model.error!),
                                  if (!model.editing)
                                    TextButton(
                                      onPressed: model.load,
                                      child: const Text('Coba lagi'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (model.layout == null && model.error == null) ...[
                            Text(
                              'Atur tata letak toko',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Pilih susunan awal, lalu sesuaikan rak dan objek. Produk serta stok tidak berubah.',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            for (final template in MonitorTemplate.values) ...[
                              AppCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 2,
                                      child: CustomPaint(
                                        painter: _LayoutPreview(
                                          template.create(),
                                        ),
                                      ),
                                    ),
                                    _button(
                                      template.label,
                                      Icons.grid_view_outlined,
                                      () => model.chooseTemplate(template),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                          if (model.layout != null) ...[
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                if (!model.editing)
                                  _button(
                                    'Edit tata letak',
                                    Icons.edit_outlined,
                                    model.edit,
                                  ),
                                if (!model.editing)
                                  _button(
                                    'Muat ulang',
                                    Icons.refresh,
                                    model.load,
                                  ),
                                if (model.editing)
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(
                                        AppSpacing.minTouchTarget,
                                        AppSpacing.minTouchTarget,
                                      ),
                                    ),
                                    onPressed: model.saving || model.conflict
                                        ? null
                                        : model.save,
                                    icon: Icon(
                                      model.saving
                                          ? Icons.hourglass_top
                                          : Icons.check,
                                    ),
                                    label: Text(
                                      model.saving ? 'Menyimpan…' : 'Simpan',
                                    ),
                                  ),
                                if (model.editing)
                                  _button(
                                    'Batal',
                                    Icons.close,
                                    model.saving ? null : _cancel,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              model.editing
                                  ? 'Edit tata letak'
                                  : 'Tata letak tersimpan',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Stok total produk menurut lokasi utama; bukan hitungan fisik per rak. Tersimpan lokal; status cloud diperiksa terpisah.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (model.productsError != null)
                              Text(model.productsError!),
                            Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                _button(
                                  '${model.counts(null).out} habis · ${model.counts(null).low} menipis',
                                  Icons.warning_amber_outlined,
                                  () => _productDetails(null, alertsOnly: true),
                                ),
                                _button(
                                  '${model.productsAt(null).length} belum ditempatkan',
                                  Icons.inventory_2_outlined,
                                  () => _productDetails(null),
                                ),
                                if (_repository != null)
                                  _button(
                                    'Periksa cloud',
                                    Icons.cloud_sync_outlined,
                                    model.editing || model.saving
                                        ? null
                                        : _checkCloud,
                                  ),
                              ],
                            ),
                            MonitorCanvas(
                              layout: model.layout!,
                              selectedId: model.selectedId,
                              editing:
                                  model.editing &&
                                  !model.saving &&
                                  !model.conflict,
                              counts: model.counts,
                              onSelect: (id) {
                                model.select(id);
                                if (!model.editing) _productDetails(id);
                              },
                              onMove: (id, x, y) {
                                model.select(id);
                                final f = model.selected!;
                                model.change(dx: x - f.x, dy: y - f.y);
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Objek toko',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (model.editing)
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  for (final type in MonitorFixtureType.values)
                                    _button(
                                      'Tambah ${type.label.toLowerCase()}',
                                      Icons.add,
                                      model.saving || model.conflict
                                          ? null
                                          : () => model.add(type),
                                    ),
                                ],
                              ),
                            if (model.layout!.fixtures.isEmpty)
                              const Text(
                                'Belum ada objek. Tambahkan rak, kulkas, atau meja kasir.',
                              ),
                            for (final fixture in model.layout!.fixtures)
                              Semantics(
                                label:
                                    '${fixture.type.label}, ${fixture.name}, ${model.productsAt(fixture.id).length} jenis produk, ${model.counts(fixture.id).out} habis, ${model.counts(fixture.id).low} menipis',
                                selected: fixture.id == model.selectedId,
                                child: ListTile(
                                  selected: fixture.id == model.selectedId,
                                  leading: Icon(
                                    fixture.type == MonitorFixtureType.fridge
                                        ? Icons.kitchen_outlined
                                        : fixture.type ==
                                              MonitorFixtureType.cashCounter
                                        ? Icons.point_of_sale
                                        : Icons.shelves,
                                  ),
                                  title: Text(
                                    '${model.layout!.fixtures.indexOf(fixture) + 1}. ${fixture.name}',
                                  ),
                                  subtitle: Text(
                                    '${fixture.type.label} · ${model.productsAt(fixture.id).length} jenis produk · ${model.counts(fixture.id).out} habis · ${model.counts(fixture.id).low} menipis',
                                  ),
                                  trailing: model.editing
                                      ? const Icon(Icons.edit_outlined)
                                      : null,
                                  onTap: model.saving
                                      ? null
                                      : () {
                                          model.select(fixture.id);
                                          if (!model.editing) {
                                            _productDetails(fixture.id);
                                          }
                                        },
                                ),
                              ),
                            if (model.selected != null && model.editing) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Atur ${model.selected!.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const Text(
                                      'Pindahkan satu petak. Posisi bertumpuk atau di luar area ditolak.',
                                    ),
                                    if (model.selected!.type !=
                                        MonitorFixtureType.cashCounter)
                                      _button(
                                        'Tempatkan produk',
                                        Icons.inventory_2_outlined,
                                        model.saving || model.conflict
                                            ? null
                                            : _assignProducts,
                                      ),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        _button(
                                          'Kiri',
                                          Icons.arrow_back,
                                          model.saving || model.conflict
                                              ? null
                                              : () => model.change(dx: -1),
                                        ),
                                        _button(
                                          'Kanan',
                                          Icons.arrow_forward,
                                          model.saving || model.conflict
                                              ? null
                                              : () => model.change(dx: 1),
                                        ),
                                        _button(
                                          'Atas',
                                          Icons.arrow_upward,
                                          model.saving || model.conflict
                                              ? null
                                              : () => model.change(dy: -1),
                                        ),
                                        _button(
                                          'Bawah',
                                          Icons.arrow_downward,
                                          model.saving || model.conflict
                                              ? null
                                              : () => model.change(dy: 1),
                                        ),
                                        _button(
                                          'Putar 90°',
                                          Icons.rotate_right,
                                          model.saving || model.conflict
                                              ? null
                                              : () =>
                                                    model.change(rotate: true),
                                        ),
                                        _button(
                                          'Ubah nama',
                                          Icons.drive_file_rename_outline,
                                          model.saving || model.conflict
                                              ? null
                                              : _rename,
                                        ),
                                        _button(
                                          'Hapus objek',
                                          Icons.delete_outline,
                                          model.saving || model.conflict
                                              ? null
                                              : _delete,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Preview ortografik editor; painter isometrik dan hit-test masuk tahap Pantau.
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
      oldDelegate.layout != layout || oldDelegate.selectedId != selectedId;
}
