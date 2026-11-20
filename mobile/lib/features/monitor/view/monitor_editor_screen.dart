import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/monitor_layout.dart';
import '../view_model/monitor_view_model.dart';
import 'monitor_canvas.dart';

/// Halaman khusus editor tata letak toko fullscreen.
class MonitorEditorScreen extends StatefulWidget {
  const MonitorEditorScreen({required this.viewModel, super.key});

  final MonitorViewModel viewModel;

  @override
  State<MonitorEditorScreen> createState() => _MonitorEditorScreenState();
}

class _MonitorEditorScreenState extends State<MonitorEditorScreen> {
  bool _allowPop = false;

  MonitorViewModel get _model => widget.viewModel;

  Future<void> _leave() async {
    if (_model.saving) return;
    if (_model.dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Simpan perubahan tata letak?'),
          content: const Text(
            'Perubahan tata letak belum disimpan ke perangkat.',
          ),
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
              onPressed: _model.conflict
                  ? null
                  : () => Navigator.pop(context, 'save'),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == 'stay') return;
      if (choice == 'save') {
        final ok = await _model.save();
        if (!ok || !mounted) return;
      } else if (choice == 'discard') {
        _model.cancel();
      }
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _saveAndExit() async {
    final ok = await _model.save();
    if (!ok || !mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _openShopSizeDialog() async {
    final layout = _model.layout;
    if (layout == null) return;
    var currentWidth = layout.gridWidth;
    var currentHeight = layout.gridHeight;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ukuran Ruang Toko',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Ukuran saat ini: $currentWidth × $currentHeight petak grid',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Pilihan Cepat (Preset)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final preset in const [
                      (label: 'Kecil (12×12)', w: 12, h: 12),
                      (label: 'Standar (16×16)', w: 16, h: 16),
                      (label: 'Luas (20×20)', w: 20, h: 20),
                      (label: 'Memanjang (12×24)', w: 12, h: 24),
                    ])
                      ChoiceChip(
                        label: Text(preset.label),
                        selected:
                            currentWidth == preset.w &&
                            currentHeight == preset.h,
                        onSelected: (_) {
                          final ok = _model.resizeGrid(preset.w, preset.h);
                          if (ok) {
                            setSheet(() {
                              currentWidth = preset.w;
                              currentHeight = preset.h;
                            });
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Atur Manual',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lebar: $currentWidth petak',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            value: currentWidth.toDouble(),
                            min: 8,
                            max: 32,
                            divisions: 24,
                            label: '$currentWidth',
                            onChanged: (val) {
                              final next = val.round();
                              if (_model.resizeGrid(next, currentHeight)) {
                                setSheet(() => currentWidth = next);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panjang: $currentHeight petak',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            value: currentHeight.toDouble(),
                            min: 8,
                            max: 32,
                            divisions: 24,
                            label: '$currentHeight',
                            onChanged: (val) {
                              final next = val.round();
                              if (_model.resizeGrid(currentWidth, next)) {
                                setSheet(() => currentHeight = next);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_model.error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _model.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Selesai'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _renameFixture() async {
    final fixture = _model.selected;
    if (fixture == null) return;
    var name = fixture.name;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nama Objek'),
        content: TextFormField(
          initialValue: name,
          onChanged: (val) => name = val,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nama rak / etalase'),
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
    if (mounted && value != null) {
      _model.change(name: value);
    }
  }

  Future<void> _deleteFixture() async {
    final selected = _model.selected;
    if (selected == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${selected.name}?'),
        content: const Text(
          'Produk di objek ini tidak dihapus dan kembali ke status belum ditempatkan saat Simpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Objek'),
          ),
        ],
      ),
    );
    if (mounted && yes == true) {
      _model.remove();
    }
  }

  Future<void> _assignProducts(MonitorFixture fixture) async {
    await _model.refreshProducts();
    if (!mounted || _model.productsError != null) return;
    final chosen = _model.productsAt(fixture.id).map((p) => p.id).toSet();
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Produk di ${fixture.name}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${chosen.length} produk terpilih',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cari produk',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setSheet(() => query = v.toLowerCase()),
                    ),
                    const SizedBox(height: AppSpacing.xs),
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
                              in _model.products.map((p) => p.category).toSet())
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
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final p in _model.products.where(
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
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSpacing.minTouchTarget,
                              ),
                            ),
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

    if (!mounted || confirmed != true) return;
    _model.assign({
      for (final e in _model.layout!.assignments.entries)
        if (e.value != fixture.id && !chosen.contains(e.key)) e.key: e.value,
      for (final id in chosen) id: fixture.id,
    });
  }

  IconData _fixtureIcon(MonitorFixtureType type) => switch (type) {
    MonitorFixtureType.fridge => Icons.kitchen_outlined,
    MonitorFixtureType.showcase => Icons.storefront_outlined,
    MonitorFixtureType.cashCounter => Icons.point_of_sale_outlined,
    MonitorFixtureType.shelf => Icons.shelves,
  };

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppSpacing.minTouchTarget * 16;

    return PopScope(
      canPop: _allowPop || (!_model.dirty && !_model.saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Tata Letak'),
          leading: IconButton(
            tooltip: 'Batal',
            onPressed: _leave,
            icon: const Icon(Icons.close),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.minTouchTarget - 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                onPressed: _model.saving || _model.conflict
                    ? null
                    : _saveAndExit,
                icon: Icon(
                  _model.saving ? Icons.hourglass_top : Icons.check,
                  size: 18,
                ),
                label: Text(_model.saving ? 'Menyimpan…' : 'Simpan'),
              ),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            final layout = _model.layout;
            if (layout == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final selected = _model.selected;

            return Stack(
              children: [
                // 1. FULLSCREEN CANVAS (Mengisi 100% Layar)
                Positioned.fill(
                  child: MonitorCanvas(
                    layout: layout,
                    selectedId: _model.selectedId,
                    editing: true,
                    counts: _model.counts,
                    onSelect: (id) => _model.select(id),
                    onMove: (id, x, y) {
                      _model.select(id);
                      final f = _model.selected;
                      if (f != null) {
                        _model.change(dx: x - f.x, dy: y - f.y);
                      }
                    },
                  ),
                ),

                // 2. FLOATING HUD KANAN ATAS (Ukuran Toko & Grid Info)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.ink,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    onPressed: _model.saving ? null : _openShopSizeDialog,
                    icon: const Icon(Icons.aspect_ratio_outlined, size: 16),
                    label: Text(
                      '${layout.gridWidth} × ${layout.gridHeight}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // 3. FLOATING ERROR BANNER (Jika Ada Peringatan)
                if (_model.error != null)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    right: 120,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppRadius.controlCompact,
                        ),
                        border: const Border(
                          left: BorderSide(color: AppColors.error, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _model.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // 4. DOCKED BOTTOM CONTROL DOCK (Ergonomi Jempol)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 600 : double.infinity,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.panel),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: selected == null
                            ? _buildAddObjectsDock(context)
                            : _buildSelectedFixtureDock(context, selected),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Toolbar bawah saat belum ada objek yang dipilih: Tombol tambah rak/kulkas/etalase
  Widget _buildAddObjectsDock(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tambah Objek',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Ketuk objek untuk mengedit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final type in MonitorFixtureType.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ActionChip(
                    avatar: Icon(
                      _fixtureIcon(type),
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      '+ ${type.label} (${type.width}×${type.height})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.primarySubtle,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    onPressed: _model.saving || _model.conflict
                        ? null
                        : () => _model.add(type),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Toolbar bawah saat suatu objek rak/etalase sedang dipilih
  Widget _buildSelectedFixtureDock(
    BuildContext context,
    MonitorFixture fixture,
  ) {
    final theme = Theme.of(context);
    final assignedCount = _model.productsAt(fixture.id).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Baris Header Objek Terpilih
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(AppRadius.squircle),
              ),
              child: Icon(
                _fixtureIcon(fixture.type),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fixture.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${fixture.type.label} (${fixture.width}×${fixture.height}) · Kolom ${fixture.x + 1}, Baris ${fixture.y + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Tutup Pilihan',
              onPressed: () => _model.select(''),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Baris Aksi Utama Kontekstual
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (fixture.type != MonitorFixtureType.cashCounter)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.minTouchTarget - 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                onPressed: _model.saving || _model.conflict
                    ? null
                    : () => _assignProducts(fixture),
                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                label: Text('$assignedCount Produk'),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.minTouchTarget - 4),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              onPressed: _model.saving || _model.conflict
                  ? null
                  : () => _model.change(rotate: true),
              icon: const Icon(Icons.rotate_right, size: 16),
              label: const Text('Putar 90°'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.minTouchTarget - 4),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              onPressed: _model.saving || _model.conflict
                  ? null
                  : _renameFixture,
              icon: const Icon(Icons.drive_file_rename_outline, size: 16),
              label: const Text('Nama'),
            ),
            IconButton.outlined(
              tooltip: 'Hapus Objek',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(
                  AppSpacing.minTouchTarget - 4,
                  AppSpacing.minTouchTarget - 4,
                ),
              ),
              onPressed: _model.saving || _model.conflict
                  ? null
                  : _deleteFixture,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Stepper Nudge 1 Petak (Aman untuk jempol)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Geser 1 Petak:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Geser Kiri',
                visualDensity: VisualDensity.compact,
                onPressed: _model.saving || _model.conflict
                    ? null
                    : () => _model.change(dx: -1),
                icon: const Icon(Icons.arrow_back, size: 18),
              ),
              IconButton(
                tooltip: 'Geser Atas',
                visualDensity: VisualDensity.compact,
                onPressed: _model.saving || _model.conflict
                    ? null
                    : () => _model.change(dy: -1),
                icon: const Icon(Icons.arrow_upward, size: 18),
              ),
              IconButton(
                tooltip: 'Geser Bawah',
                visualDensity: VisualDensity.compact,
                onPressed: _model.saving || _model.conflict
                    ? null
                    : () => _model.change(dy: 1),
                icon: const Icon(Icons.arrow_downward, size: 18),
              ),
              IconButton(
                tooltip: 'Geser Kanan',
                visualDensity: VisualDensity.compact,
                onPressed: _model.saving || _model.conflict
                    ? null
                    : () => _model.change(dx: 1),
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
