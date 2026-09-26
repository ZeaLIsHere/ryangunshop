import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../view/product_catalog.dart';

/// Entrypoint pratinjau Android terpisah sampai katalog dipasang di app shell.
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RyanGunshop — Katalog contoh',
      theme: AppTheme.light(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Produk')),
        body: const SafeArea(child: ProductCatalog()),
      ),
    ),
  );
}
