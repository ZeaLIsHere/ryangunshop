import 'package:flutter/material.dart';

import '../../../core/data/product_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/catalog_product.dart';
import '../model/catalog_scenario.dart';
import '../model/catalog_sort.dart';
import '../view_model/catalog_view_model.dart';
import 'catalog_product_card.dart';
import 'product_detail_sheet.dart';
import 'product_form_screen.dart';

/// Isi tab katalog produk RyanGunshop.
class ProductCatalog extends StatefulWidget {
  const ProductCatalog({this.viewModel, this.repository, super.key});

  final CatalogViewModel? viewModel;
  final ProductRepository? repository;

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  late final CatalogViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget.viewModel ?? CatalogViewModel(repository: widget.repository);
    if (_viewModel.isLocal) _viewModel.loadProducts();
  }

  @override
  void didUpdateWidget(ProductCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel == null && oldWidget.repository != widget.repository) {
      _viewModel.updateRepository(widget.repository);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _openProductForm([CatalogProduct? product]) async {
    final result = await Navigator.of(context).push<CatalogProduct>(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          initialProduct: product,
          existingProducts: _viewModel.allProducts,
          isLocal: _viewModel.isLocal,
        ),
      ),
    );

    if (result != null) {
      await _persistProduct(result);
    }
  }

  Future<void> _deleteProduct(CatalogProduct product) async {
    try {
      await _viewModel.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${product.name}" berhasil dihapus.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus produk. Coba lagi.')),
      );
    }
  }

  Future<void> _persistProduct(CatalogProduct product) async {
    try {
      await _viewModel.persistProduct(product);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produk gagal disimpan. Periksa barcode dan coba lagi.',
          ),
        ),
      );
    }
  }

  void _openProductDetail(CatalogProduct product) {
    ProductDetailSheet.show(
      context,
      product: product,
      existingProducts: _viewModel.allProducts,
      isLocal: _viewModel.isLocal,
      onProductUpdated: (updated) {
        _persistProduct(updated);
      },
      onProductDeleted: (deleted) {
        _deleteProduct(deleted);
      },
    );
  }

  void _openSortSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.xs,
                ),
                child: Text(
                  'Urutkan berdasarkan',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (final sort in CatalogSort.values)
                ListTile(
                  leading: Icon(
                    sort.icon,
                    color: sort == _viewModel.sort
                        ? AppColors.primary
                        : AppColors.muted,
                  ),
                  title: Text(sort.label),
                  trailing: sort == _viewModel.sort
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    _viewModel.setSort(sort);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              top: AppSpacing.screen,
              bottom: 80, // ruang untuk FAB
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.controlCompactBorder,
                    ),
                    child: Image.asset(
                      'assets/icon/01_katalog_produk.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Katalog Produk',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Harga, stok, dan posisi rak barang warung.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              const SampleBadge(label: 'Tersimpan di perangkat'),
              const SizedBox(height: AppSpacing.xs),

              // Search Bar dan kontrol urutkan
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _viewModel.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Cari nama produk, barcode, atau rak...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Bersihkan pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  _viewModel.setSearchQuery('');
                                },
                              )
                            : null,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.controlBorder,
                          borderSide: const BorderSide(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.swap_vert),
                    tooltip: 'Urutkan: ${_viewModel.sort.label}',
                    onPressed: _openSortSheet,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final cat in _viewModel.categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _viewModel.selectedCategory == cat,
                          onSelected: (selected) {
                            if (selected) _viewModel.setSelectedCategory(cat);
                          },
                        ),
                      ),
                    FilterChip(
                      avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                      label: const Text('Stok Menipis'),
                      selected: _viewModel.filterLowStockOnly,
                      selectedColor: AppColors.warning.withValues(alpha: 0.2),
                      onSelected: (_) => _viewModel.toggleLowStockFilter(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Content
              ..._buildContent(),
            ],
          ),

          // FAB overlay
          Positioned(
            right: AppSpacing.screen,
            bottom: AppSpacing.screen,
            child: FloatingActionButton.extended(
              heroTag: 'add-product-fab',
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
              onPressed: () => _openProductForm(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    switch (_viewModel.scenario) {
      case CatalogScenario.loading:
        return [
          if (MediaQuery.disableAnimationsOf(context))
            const _CatalogMessage(
              icon: Icons.hourglass_empty,
              color: AppColors.muted,
              title: 'Memuat katalog',
              description: 'Sedang memuat data produk...',
            )
          else
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: BrandSpinner(label: 'Memuat katalog'),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: 'Muat Ulang',
            onPressed: _viewModel.isLocal
                ? _viewModel.loadProducts
                : _viewModel.showSampleProducts,
          ),
        ];
      case CatalogScenario.empty:
        return [
          const _CatalogMessage(
            icon: Icons.inventory_2_outlined,
            color: AppColors.muted,
            title: 'Belum ada produk',
            description: 'Katalog produk warung masih kosong. Tambahkan produk baru sekarang.',
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: 'Tambah Produk',
            icon: Icons.add,
            onPressed: () => _openProductForm(),
          ),
        ];
      case CatalogScenario.failure:
        return [
          const _CatalogMessage(
            icon: Icons.error_outline,
            color: AppColors.error,
            title: 'Katalog gagal dimuat',
            description: 'Terjadi kendala saat membaca data produk dari penyimpanan lokal.',
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: 'Coba lagi',
            onPressed: _viewModel.isLocal
                ? _viewModel.loadProducts
                : _viewModel.showSampleProducts,
          ),
        ];
      case CatalogScenario.withData:
      case CatalogScenario.offline:
        final products = _viewModel.products;
        return [
          if (_viewModel.scenario == CatalogScenario.offline) ...[
            const _CatalogMessage(
              icon: Icons.cloud_off_outlined,
              color: AppColors.warning,
              title: 'Mode Offline',
              description: 'Katalog offline aktif. Semua produk tersimpan lokal dan siap ditransaksikan.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '${products.length} produk',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  _viewModel.sort.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'Tidak ada produk yang cocok dengan pencarian.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            for (final product in products) ...[
              CatalogProductCard(
                product: product,
                onTap: () => _openProductDetail(product),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
        ];
    }
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSpacing.xl),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
