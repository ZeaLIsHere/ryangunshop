import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../catalog/model/catalog_product.dart';
import '../model/fixture_item.dart';

/// Bottom sheet menampilkan daftar produk pada fixture yang dipilih.
class FixtureProductSheet extends StatefulWidget {
  const FixtureProductSheet({required this.fixture, super.key});

  final FixtureItem fixture;

  static Future<void> show(BuildContext context, FixtureItem fixture) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FixtureProductSheet(fixture: fixture),
    );
  }

  @override
  State<FixtureProductSheet> createState() => _FixtureProductSheetState();
}

class _FixtureProductSheetState extends State<FixtureProductSheet> {
  String _searchQuery = '';
  List<CatalogProduct>? _localProducts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final repo = AppSessionScope.of(context).productRepository;
    try {
      final records = await repo.listProducts();
      if (!mounted) return;
      setState(() {
        _localProducts = records.map(CatalogProduct.fromRecord).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);

    // Filter produk yang ada di fixture ini
    final sourceProducts = _localProducts ?? const <CatalogProduct>[];
    final allProducts = sourceProducts
        .where((p) => p.fixtureId == widget.fixture.id)
        .toList();

    final filteredProducts = allProducts.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheetBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: widget.fixture.type.backgroundColor,
                    borderRadius: AppRadius.fixtureBorder,
                    border: Border.all(
                      color: widget.fixture.type.accentColor.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Icon(
                    widget.fixture.type.icon,
                    color: widget.fixture.type.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fixture.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.fixture.type.label} · ${allProducts.length} Produk',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Search bar
          if (allProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.xs,
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Cari barang di rak ini…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
            ),
          const Divider(height: 1),
          // Product List
          Flexible(
            child: filteredProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Belum ada produk di ${widget.fixture.name}'
                                : 'Produk tidak ditemukan',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    shrinkWrap: true,
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _ProductRow(
                        product: product,
                        onAddToCart: () {
                          session.cart.addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} ditambahkan ke keranjang kasir',
                              ),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Batal',
                                onPressed: () {
                                  session.cart.updateQuantity(
                                    product.id,
                                    session.cart.items
                                            .firstWhere(
                                              (i) => i.productId == product.id,
                                            )
                                            .quantity -
                                        1,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onAddToCart});

  final CatalogProduct product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.stockStatus == ProductStockStatus.low;
    final isEmptyStock = product.stockStatus == ProductStockStatus.empty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatRupiah(product.price)} / ${product.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isEmptyStock
                            ? AppColors.error.withValues(alpha: 0.1)
                            : isLowStock
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppRadius.fixtureCompact,
                        ),
                      ),
                      child: Text(
                        isEmptyStock
                            ? 'Habis'
                            : isLowStock
                            ? 'Sisa ${product.stock} ${product.unit}'
                            : 'Stok: ${product.stock} ${product.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isEmptyStock
                              ? AppColors.error
                              : isLowStock
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filledTonal(
            icon: const Icon(Icons.add_shopping_cart, size: 20),
            tooltip: 'Tambah ke Kasir',
            onPressed: isEmptyStock ? null : onAddToCart,
          ),
        ],
      ),
    );
  }
}
