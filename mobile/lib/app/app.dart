import 'package:flutter/material.dart';

import '../core/data/app_database.dart';
import '../core/session/app_session.dart';
import '../core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Akar aplikasi RyanGunshop.
class RyanGunshopApp extends StatefulWidget {
  const RyanGunshopApp({this.session, this.useLocalStorage = false, super.key});

  /// Sesi yang dipakai aplikasi. Bila kosong, aplikasi membuat sesinya sendiri.
  /// Pengujian dapat mengoper sesi agar keadaan awal mudah diatur.
  final AppSession? session;
  final bool useLocalStorage;

  @override
  State<RyanGunshopApp> createState() => _RyanGunshopAppState();
}

class _RyanGunshopAppState extends State<RyanGunshopApp> {
  late final AppDatabase? _database =
      widget.session == null && widget.useLocalStorage
      ? AppDatabase(openAppDatabase())
      : null;
  late final AppSession _session =
      widget.session ?? AppSession(database: _database);
  late final bool _ownsSession = widget.session == null;

  @override
  void initState() {
    super.initState();
    _session.loadLocalSummary();
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSessionScope(
      session: _session,
      child: MaterialApp(
        title: 'RyanGunshop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
