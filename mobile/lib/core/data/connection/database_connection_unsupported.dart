import 'package:drift/drift.dart';

// ponytail: web database throws UnsupportedError; upgrade to drift/wasm when web persistence is needed.
QueryExecutor openAppDatabase() {
  throw UnsupportedError('Database lokal belum didukung pada platform web');
}
