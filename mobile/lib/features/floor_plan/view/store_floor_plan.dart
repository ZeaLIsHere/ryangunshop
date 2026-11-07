import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/fixture_item.dart';
import '../view_model/floor_plan_view_model.dart';
import 'fixture_product_sheet.dart';
import 'fixture_tile.dart';
import 'mode_switch.dart';
import 'sync_pill.dart';

/// Kanvas denah 2D interaktif warung RyanGunshop.
class StoreFloorPlan extends StatefulWidget {
  const StoreFloorPlan({
    this.viewModel,
    this.initialHighlightFixtureId,
    this.onOpenPanorama,
    super.key,
  });

  final FloorPlanViewModel? viewModel;
  final String? initialHighlightFixtureId;
  final VoidCallback? onOpenPanorama;

  @override
  State<StoreFloorPlan> createState() => _StoreFloorPlanState();
}

class _StoreFloorPlanState extends State<StoreFloorPlan> {
  late final FloorPlanViewModel _viewModel;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? FloorPlanViewModel();
    if (widget.initialHighlightFixtureId != null) {
      _viewModel.highlightFixture(widget.initialHighlightFixtureId);
    }
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    _transformController.dispose();
    super.dispose();
  }

  void _handleFixtureTap(FixtureItem fixture) {
    if (_viewModel.isEditMode) {
      _viewModel.selectFixture(fixture.id);
    } else {
      _viewModel.selectFixture(fixture.id);
      FixtureProductSheet.show(context, fixture);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);
    final canEdit = session.canEditFloorPlan;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Column(
            children: [
              // Top control bar: Mode Switch, Sync Status & Edit Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.xs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryLight),
                  ),
                ),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ModeSwitch(
                      currentMode: ViewMode.floorPlan2D,
                      onModeChanged: (mode) {
                        if (mode == ViewMode.panorama360) {
                          widget.onOpenPanorama?.call();
                        }
                      },
                    ),
                    const SyncPill(),
                    if (canEdit)
                      IconButton.filledTonal(
                        icon: Icon(
                          _viewModel.isEditMode
                              ? Icons.check
                              : Icons.edit_outlined,
                          size: 18,
                        ),
                        tooltip: _viewModel.isEditMode
                            ? 'Selesai Edit'
                            : 'Edit Denah',
                        style: _viewModel.isEditMode
                            ? IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                              )
                            : null,
                        onPressed: _viewModel.toggleEditMode,
                      ),
                  ],
                ),
              ),

              // Banner status jika dalam mode edit
              if (_viewModel.isEditMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.xs,
                  ),
                  color: AppColors.primaryLight,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Mode Edit Denah: Geser untuk memindahkan, atau pilih objek untuk opsi.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Blueprint Canvas
              Expanded(
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformController,
                      boundaryMargin: const EdgeInsets.all(80),
                      minScale: 0.6,
                      maxScale: 2.5,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            margin: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.panelBorder,
                              border: Border.all(
                                color: AppColors.primaryLight,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final canvasWidth = constraints.maxWidth;
                                final canvasHeight = constraints.maxHeight;

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Grid lines & dot-matrix custom painter
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _FloorPlanGridPainter(),
                                      ),
                                    ),

                                    // Floor Boundaries & Dimensions Header
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface.withValues(
                                            alpha: 0.92,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryLight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: AppColors.success,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '8.0m x 6.0m • Skala 0.5m',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.ink,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Indikator Pintu Masuk
                                    Positioned(
                                      bottom: 0,
                                      left: canvasWidth * 0.08,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryDark,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                        ),
                                        child: Text(
                                          'PINTU MASUK',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.surface,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                      ),
                                    ),

                                    // Fixture tiles
                                    for (final fixture in _viewModel.fixtures)
                                      _buildPositionedFixture(
                                        fixture,
                                        canvasWidth,
                                        canvasHeight,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Reset Zoom Button
                    Positioned(
                      bottom: AppSpacing.screen,
                      left: AppSpacing.screen,
                      child: FloatingActionButton.small(
                        heroTag: 'reset-zoom-fab',
                        tooltip: 'Reset Tampilan',
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        onPressed: () {
                          _transformController.value = Matrix4.identity();
                        },
                        child: const Icon(Icons.center_focus_strong, size: 20),
                      ),
                    ),

                    // Floating Controls during Edit Mode
                    if (_viewModel.isEditMode)
                      Positioned(
                        left: AppSpacing.screen,
                        right: AppSpacing.screen,
                        bottom: AppSpacing.screen,
                        child: _buildEditToolbar(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPositionedFixture(
    FixtureItem fixture,
    double canvasWidth,
    double canvasHeight,
  ) {
    final left = fixture.x * canvasWidth;
    final top = fixture.y * canvasHeight;
    final width = fixture.width * canvasWidth;
    final height = fixture.height * canvasHeight;
    final isSelected = _viewModel.selectedFixtureId == fixture.id;
    final isHighlighted = _viewModel.highlightedFixtureId == fixture.id;

    Widget tileWidget = SizedBox(
      width: width,
      height: height,
      child: FixtureTile(
        fixture: fixture,
        isSelected: isSelected,
        isHighlighted: isHighlighted,
        isEditMode: _viewModel.isEditMode,
        onTap: () => _handleFixtureTap(fixture),
      ),
    );

    if (_viewModel.isEditMode) {
      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onPanUpdate: (details) {
            final deltaX = details.delta.dx / canvasWidth;
            final deltaY = details.delta.dy / canvasHeight;
            _viewModel.updateFixturePosition(
              fixture.id,
              fixture.x + deltaX,
              fixture.y + deltaY,
            );
          },
          child: tileWidget,
        ),
      );
    }

    return Positioned(left: left, top: top, child: tileWidget);
  }

  Widget _buildEditToolbar(BuildContext context) {
    final selectedFixture = _viewModel.selectedFixture;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.controlBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.add_box_outlined,
                color: AppColors.primary,
              ),
              tooltip: 'Tambah Objek',
              onPressed: () => _showAddFixtureDialog(context),
            ),
            if (selectedFixture != null) ...[
              IconButton(
                icon: const Icon(Icons.rotate_right, color: AppColors.primary),
                tooltip: 'Putar Objek',
                onPressed: () => _viewModel.rotateFixture(selectedFixture.id),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: AppColors.primary),
                tooltip: 'Perbesar Objek',
                onPressed: () =>
                    _viewModel.resizeFixture(selectedFixture.id, delta: 0.05),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out, color: AppColors.primary),
                tooltip: 'Perkecil Objek',
                onPressed: () =>
                    _viewModel.resizeFixture(selectedFixture.id, delta: -0.05),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_all_outlined,
                  color: AppColors.primary,
                ),
                tooltip: 'Duplikat Objek',
                onPressed: () =>
                    _viewModel.duplicateFixture(selectedFixture.id),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: AppColors.primary),
                tooltip: 'Ganti Nama',
                onPressed: () => _showRenameDialog(context, selectedFixture),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Hapus Objek',
                onPressed: () => _viewModel.deleteFixture(selectedFixture.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddFixtureDialog(BuildContext context) {
    FixtureType selectedType = FixtureType.shelf;
    final nameController = TextEditingController(text: 'Rak Baru');

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Objek Warung'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Objek',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<FixtureType>(
                initialValue: selectedType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jenis Objek'),
                items: [
                  for (final type in FixtureType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 18, color: type.accentColor),
                          const SizedBox(width: AppSpacing.xs),
                          Text(type.label),
                        ],
                      ),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  _viewModel.addFixture(type: selectedType, name: name);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, FixtureItem fixture) {
    final nameController = TextEditingController(text: fixture.name);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Nama Objek'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Baru',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                _viewModel.renameFixture(fixture.id, newName);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk menggambar matriks grid titik (dot matrix) dan garis halus kanvas denah.
class _FloorPlanGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
