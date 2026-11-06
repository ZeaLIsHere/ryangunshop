import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../../floor_plan/sample/floor_plan_sample.dart';
import '../model/catalog_product.dart';
import '../sample/catalog_sample.dart';

/// Layar formulir tambah / edit produk mobile satu kolom dengan section bertahap.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({this.initialProduct, this.onSave, super.key});

  final CatalogProduct? initialProduct;
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

  final _units = ['bungkus', 'botol', 'kotak', 'pcs', 'kg', 'sachet', 'kaleng'];
  List<String> get _categories => CatalogSample.categories
      .where((category) => category != CatalogSample.allCategoryLabel)
      .toList();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _costPriceController = TextEditingController(
      text: p == null
          ? ''
          : (p.costPrice > 0 ? p.costPrice : (p.price * 0.8).toInt())
                .toString(),
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '10',
    );
    _thresholdController = TextEditingController(
      text: p != null ? p.lowStockThreshold.toString() : '5',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
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

    final fixture = FloorPlanSample.defaultFixtures.firstWhere(
      (f) => f.id == _selectedFixtureId,
      orElse: () => FloorPlanSample.defaultFixtures.first,
    );

    final product = CatalogProduct(
      id:
          widget.initialProduct?.id ??
          'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      price: int.parse(_priceController.text.replaceAll(RegExp(r'\D'), '')),
      stock: int.parse(_stockController.text.replaceAll(RegExp(r'\D'), '')),
      unit: _selectedUnit,
      fixtureId: _selectedFixtureId,
      locationLabel: fixture.name,
      category: _selectedCategory,
      costPrice:
          int.tryParse(
            _costPriceController.text.replaceAll(RegExp(r'\D'), ''),
          ) ??
          0,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Identitas Produk
                      _SectionHeader(
                        number: '1',
                        title: 'Identitas Produk',
                        subtitle: 'Nama, kategori, dan barcode barang',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _nameController,
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
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Section 2: Harga & Stok
                      _SectionHeader(
                        number: '2',
                        title: 'Harga & Stok',
                        subtitle: 'Penetapan harga jual, modal, dan kuantitas',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Jual *',
                                prefixText: 'Rp ',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Harga wajib diisi';
                                }
                                final p = int.tryParse(
                                  value.replaceAll(RegExp(r'\D'), ''),
                                );
                                if (p == null || p <= 0) {
                                  return 'Harga tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Modal',
                                prefixText: 'Rp ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stok Saat Ini *',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Stok wajib diisi';
                                }
                                final s = int.tryParse(
                                  value.replaceAll(RegExp(r'\D'), ''),
                                );
                                if (s == null || s < 0) {
                                  return 'Stok tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Satuan',
                              ),
                              items: [
                                for (final unit in _units)
                                  DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Batas Peringatan Stok Menipis',
                          hintText: 'Misal: 5',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Section 3: Penempatan Denah
                      _SectionHeader(
                        number: '3',
                        title: 'Lokasi Rak & Denah',
                        subtitle: 'Tautkan produk ke objek rak di denah warung',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFixtureId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Rak / Fixture',
                          prefixIcon: Icon(Icons.table_rows_outlined),
                        ),
                        items: [
                          for (final fixture in FloorPlanSample.defaultFixtures)
                            DropdownMenuItem(
                              value: fixture.id,
                              child: Row(
                                children: [
                                  Icon(
                                    fixture.type.icon,
                                    size: 18,
                                    color: fixture.type.accentColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      fixture.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedFixtureId = val);
                          }
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
