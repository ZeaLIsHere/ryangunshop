import 'dart:async';

import 'package:flutter/material.dart';

import '../core/data/app_database.dart';
import '../core/session/app_session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
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
    _session.addListener(_refreshStartup);
    _session.loadLocalSummary();
  }

  void _refreshStartup() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_refreshStartup);
    final database = _database;
    final pendingWrites = database == null
        ? null
        : _session.finishLocalWrites();
    if (_ownsSession) {
      _session.dispose();
    }
    if (database != null) {
      unawaited(
        pendingWrites!.whenComplete(database.close).catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isLocalCartReady) {
      return AppSessionScope(
        session: _session,
        child: MaterialApp(
          title: 'RyanGunshop',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _session.isLocalCartLoadFailed
                        ? Icons.error_outline
                        : Icons.inventory_2_outlined,
                    color: _session.isLocalCartLoadFailed
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _session.isLocalCartLoadFailed
                        ? 'Data keranjang gagal dimuat'
                        : 'Menyiapkan data kasir lokal',
                  ),
                  if (_session.isLocalCartLoadFailed)
                    TextButton.icon(
                      onPressed: _session.loadLocalCart,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
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
