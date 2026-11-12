import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app/app.dart';
import 'core/config/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tidak melakukan apa pun kecuali `FIREBASE_ENABLED=true`. Kegagalan
  // penyalaan tidak menghentikan aplikasi karena kasir tetap berjalan lokal.
  await FirebaseBootstrap.ensureInitialized();
  runApp(RyanGunshopApp(useLocalStorage: !kIsWeb));
}
