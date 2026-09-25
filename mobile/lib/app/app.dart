import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Akar aplikasi RyanGunshop.
class RyanGunshopApp extends StatelessWidget {
  const RyanGunshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RyanGunshop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.shell,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
