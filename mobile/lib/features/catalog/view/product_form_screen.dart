import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/catalog_product.dart';
import '../sample/catalog_sample.dart';

/// Layar formulir tambah / edit produk mobile satu kolom dengan section bertahap.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    this.initialProduct,
    this.existingProducts = const [],
    this.isLocal = false,
    this.onSave,
    super.key,
  });

  final CatalogProduct? initialProduct;
  final List<CatalogProduct> existingProducts;
  final bool isLocal;
  final ValueChanged<CatalogProduct>? onSave;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _barcodeController;

  String _selectedUnit = 'bungkus';
  String _selectedCategory = 'Sembako';
  String _selectedFixtureId = 'contoh-rak-sembako';
  bool _hasSamplePhoto = false;

  List<String> get _units => {
    'bungkus',
    'botol',
    'kotak',
    'pcs',
    'kg',
    'sachet',
    'kaleng',
    _selectedUnit,
  }.toList();
  List<String> get _categories => {
    ...CatalogSample.categories.where(
      (category) => category != CatalogSample.allCategoryLabel,
    ),
    _selectedCategory,
  }.toList();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _costPriceController = TextEditingController(
      text: p == null || p.costPrice == 0 ? '' : p.costPrice.toString(),
    );
    _stockController = TextEditingController(text: p?.stock.toString() ?? '');
    _thresholdController = TextEditingController(
      text: p != null ? p.lowStockThreshold.toString() : '5',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _hasSamplePhoto = p?.hasSamplePhoto ?? false;
    if (p != null) {
      _selectedUnit = p.unit;
      _selectedFixtureId = p.fixtureId;
      _selectedCategory = p.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final product = CatalogProduct(
      id:
          widget.initialProduct?.id ??
          'prod-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      price: int.parse(_priceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      unit: _selectedUnit,
      fixtureId: _selectedFixtureId,
      locationLabel: widget.initialProduct?.locationLabel ?? 'Etalase Toko',
      category: _selectedCategory,
      costPrice: int.tryParse(_costPriceController.text.trim()) ?? 0,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      lowStockThreshold: int.tryParse(_thresholdController.text.trim()) ?? 5,
      hasSamplePhoto: _hasSamplePhoto,
    );

    widget.onSave?.call(product);
    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialProduct != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SampleBadge(
                          label: widget.isLocal
                              ? 'Produk lokal • foto contoh'
                              : 'Pratinjau data contoh',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionHeader(
                        number: '1',
                        title: 'Foto Produk',
                        subtitle: 'Pratinjau pilihan foto untuk katalog',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: AppRadius.cardBorder,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _hasSamplePhoto
                                      ? Icons.image_outlined
                                      : Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary,
                                  size: AppSpacing.xl,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _hasSamplePhoto
                                        ? 'Pratinjau foto contoh aktif'
                                        : 'Belum ada foto produk',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  double.infinity,
                                  AppSpacing.minTouchTarget,
                                ),
                              ),
                              icon: Icon(
                                _hasSamplePhoto
                                    ? Icons.delete_outline
                                    : Icons.photo_library_outlined,
                              ),
                              label: Text(
                                _hasSamplePhoto
                                    ? 'Hapus pratinjau'
                                    : 'Gunakan pratinjau contoh',
                              ),
                              onPressed: () => setState(
                                () => _hasSamplePhoto = !_hasSamplePhoto,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Pratinjau ini hanya contoh; belum memilih atau menyimpan berkas foto.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Section 2: Identitas Produk
                      _SectionHeader(
                        number: '2',
                        title: 'Identitas Produk',
                        subtitle: 'Nama, kategori, dan barcode barang',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _nameController,
                        inputFormatters: [LengthLimitingTextInputFormatter(80)],
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          hintText: 'Misal: Beras Pandan Wangi 1 kg',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Produk',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          for (final cat in _categories)
                            DropdownMenuItem(value: cat, child: Text(cat)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _barcodeController,
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                        decoration: InputDecoration(
                          labelText: 'Barcode / SKU (Opsional)',
                          hintText: '899275321001',
                          prefixIcon: const Icon(Icons.qr_code),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Generate Barcode Otomatis',
                            onPressed: () {
                              final generated =
                                  'RG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                              _barcodeController.text = generated;
                            },
                          ),
                        ),
                        validator: (value) {
                          final barcode = value?.trim();
                          if (barcode == null || barcode.isEmpty) return null;
                          final duplicate = widget.existingProducts.any(
                            (product) =>
                                product.id != widget.initialProduct?.id &&
                                product.barcode?.toLowerCase() ==
                                    barcode.toLowerCase(),
                          );
                          return duplicate
                              ? 'Barcode sudah dipakai produk lain'
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Section 3: Harga & Stok
                      _SectionHeader(
                        number: '3',
                        title: 'Harga & Stok',
                        subtitle: 'Penetapan harga jual, modal, dan kuantitas',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual *',
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga jual wajib diisi';
                          }
                          final price = int.tryParse(value.trim());
                          return price == null || price <= 0
                              ? 'Masukkan harga jual lebih dari nol'
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _costPriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Harga Modal (Opsional)',
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return int.tryParse(value.trim()) == null
                              ? 'Masukkan harga modal berupa angka'
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Stok Saat Ini *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Stok wajib diisi';
                          }
                          return int.tryParse(value.trim()) == null
                              ? 'Masukkan stok berupa angka nol atau lebih'
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Satuan'),
                        items: [
                          for (final unit in _units)
                            DropdownMenuItem(value: unit, child: Text(unit)),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Batas Peringatan Stok Menipis',
                          hintText: 'Misal: 5',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return int.tryParse(value.trim()) == null
                              ? 'Masukkan batas stok berupa angka'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Save Button
              Container(
                padding: const EdgeInsets.all(AppSpacing.screen),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: PrimaryAction(
                  label: isEdit ? 'Simpan Perubahan' : 'Simpan Produk',
                  icon: Icons.check,
                  onPressed: _saveProduct,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
