import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../catalog/model/catalog_product.dart';
import '../view_model/scanner_view_model.dart';

/// Jalan keluar tanpa kamera untuk memilih produk dari data contoh.
class ManualProductSearchScreen extends StatefulWidget {
  const ManualProductSearchScreen({
    required this.viewModel,
    this.isLocal = false,
    super.key,
  });

  final ScannerViewModel viewModel;
  final bool isLocal;

  @override
  State<ManualProductSearchScreen> createState() =>
      _ManualProductSearchScreenState();
}

class _ManualProductSearchScreenState extends State<ManualProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = widget.viewModel.searchProducts(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Produk Manual')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SampleBadge(
                  label: widget.isLocal
                      ? 'Pencarian produk lokal'
                      : 'Pencarian data contoh',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  labelText: 'Nama atau barcode produk',
                  hintText: 'Contoh: Mi instan',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (products.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          color: AppColors.muted,
                          size: AppSpacing.xl,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _query.isEmpty
                              ? 'Belum ada produk di katalog'
                              : 'Produk tidak ditemukan',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _query.isEmpty
                              ? 'Kembali ke pemindai untuk mencoba lagi.'
                              : 'Ubah nama atau barcode yang dicari.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton.icon(
                          onPressed: _query.isEmpty
                              ? () => Navigator.of(context).pop()
                              : () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                          icon: Icon(
                            _query.isEmpty ? Icons.arrow_back : Icons.refresh,
                          ),
                          label: Text(
                            _query.isEmpty ? 'Kembali' : 'Hapus pencarian',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final CatalogProduct product = products[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${formatRupiah(product.price)} · ${product.locationLabel}\n${product.barcode ?? 'Tanpa barcode'}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(product),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
