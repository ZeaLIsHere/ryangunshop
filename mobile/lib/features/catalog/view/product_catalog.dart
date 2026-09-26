import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../model/catalog_scenario.dart';
import '../view_model/catalog_view_model.dart';
import 'catalog_product_card.dart';

/// Isi tab katalog. App bar dan navigasi tetap disediakan app shell.
class ProductCatalog extends StatefulWidget {
  const ProductCatalog({super.key});

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  final CatalogViewModel _viewModel = CatalogViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text('Katalog produk', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lihat harga, stok, dan letak produk di warung.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Align(
            alignment: Alignment.centerLeft,
            child: SampleBadge(label: 'Pratinjau · data contoh lokal'),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<CatalogScenario>(
            initialValue: _viewModel.scenario,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Skenario contoh'),
            items: [
              for (final scenario in CatalogScenario.values)
                DropdownMenuItem(value: scenario, child: Text(scenario.label)),
            ],
            onChanged: (scenario) {
              if (scenario != null) _viewModel.selectScenario(scenario);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._buildContent(),
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
              title: 'Memuat katalog contoh',
              description:
                  'Simulasi pemuatan. Belum menghubungi layanan apa pun.',
            )
          else
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: BrandSpinner(label: 'Memuat katalog contoh'),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: 'Tampilkan contoh',
            onPressed: _viewModel.showSampleProducts,
          ),
        ];
      case CatalogScenario.empty:
        return [
          const _CatalogMessage(
            icon: Icons.inventory_2_outlined,
            color: AppColors.muted,
            title: 'Belum ada produk',
            description:
                'Ini simulasi katalog kosong. Tampilkan data contoh untuk '
                'melihat susunan produk. Formulir tambah menyusul di tahap berikutnya.',
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: 'Tampilkan contoh',
            onPressed: _viewModel.showSampleProducts,
          ),
        ];
      case CatalogScenario.failure:
        return [
          const _CatalogMessage(
            icon: Icons.error_outline,
            color: AppColors.error,
            title: 'Katalog contoh gagal dimuat',
            description:
                'Ini simulasi kegagalan. Coba lagi untuk menampilkan '
                'data contoh lokal.',
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: 'Coba lagi',
            onPressed: _viewModel.showSampleProducts,
          ),
        ];
      case CatalogScenario.withData:
      case CatalogScenario.offline:
        return [
          if (_viewModel.scenario == CatalogScenario.offline) ...[
            const _CatalogMessage(
              icon: Icons.cloud_off_outlined,
              color: AppColors.warning,
              title: 'Offline · simulasi',
              description:
                  'Data contoh lokal tetap dapat dilihat. '
                  'Belum ada sinkronisasi atau pemeriksaan koneksi.',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            '${_viewModel.products.length} produk contoh',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final product in _viewModel.products) ...[
            CatalogProductCard(product: product),
            const SizedBox(height: AppSpacing.sm),
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
