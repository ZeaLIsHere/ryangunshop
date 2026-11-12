import 'package:drift/drift.dart';

import 'database_connection_unsupported.dart'
    if (dart.library.io) 'database_connection_native.dart'
    as impl;

QueryExecutor openAppDatabase() => impl.openAppDatabase();
