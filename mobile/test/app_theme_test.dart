import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/theme/app_colors.dart';
import 'package:ryangunshop/core/theme/app_spacing.dart';
import 'package:ryangunshop/core/theme/app_theme.dart';
import 'package:ryangunshop/core/theme/app_typography.dart';

void main() {
  group('AppTheme', () {
    test('memakai palet warna RyanGunshop', () {
      final theme = AppTheme.light();

      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.onSurface, AppColors.ink);
      expect(theme.colorScheme.onSurfaceVariant, AppColors.muted);
      expect(theme.scaffoldBackgroundColor, AppColors.canvas);
    });

    test('memakai skala tipografi yang disepakati', () {
      final textTheme = AppTheme.light().textTheme;

      expect(textTheme.displaySmall?.fontSize, AppTypography.pageTitleSize);
      expect(textTheme.headlineSmall?.fontSize, AppTypography.sectionTitleSize);
      expect(textTheme.titleMedium?.fontSize, AppTypography.labelSize);
      expect(textTheme.bodyMedium?.fontSize, AppTypography.bodySize);
      expect(textTheme.bodyMedium?.color, AppColors.ink);
      expect(textTheme.bodySmall?.color, AppColors.muted);
    });

    test('menetapkan ukuran tombol pada target sentuh minimum', () {
      final theme = AppTheme.light();
      final minimumSize = theme.filledButtonTheme.style?.minimumSize?.resolve(
        <WidgetState>{},
      );

      expect(
        minimumSize,
        const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
      );
    });
  });
}
