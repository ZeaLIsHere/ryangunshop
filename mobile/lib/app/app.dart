import 'package:flutter/material.dart';

import '../core/session/app_session.dart';
import '../core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Akar aplikasi RyanGunshop.
class RyanGunshopApp extends StatefulWidget {
  const RyanGunshopApp({this.session, super.key});

  /// Sesi yang dipakai aplikasi. Bila kosong, aplikasi membuat sesinya sendiri.
  /// Pengujian dapat mengoper sesi agar keadaan awal mudah diatur.
  final AppSession? session;

  @override
  State<RyanGunshopApp> createState() => _RyanGunshopAppState();
}

class _RyanGunshopAppState extends State<RyanGunshopApp> {
  late final AppSession _session = widget.session ?? AppSession();
  late final bool _ownsSession = widget.session == null;

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
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
