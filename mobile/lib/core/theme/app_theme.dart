import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema terang RyanGunshop.
///
/// Bahasa desain: satu aksen slate blue yang dipakai hemat, permukaan netral
/// dingin, garis hairline sebagai pemisah, dan shadow biru yang sangat lembut.
/// Seluruh nilai diambil dari token di `core/theme`. Widget tidak boleh menulis
/// warna, ukuran teks, atau radius secara langsung.
abstract final class AppTheme {
  /// Skema warna Material 3 dari palet RyanGunshop.
  ///
  /// Warna dari `AppColors` dipasang eksplisit agar identitas visual tidak
  /// bergeser bila algoritma tonal Material berubah.
  static final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        onSecondary: AppColors.surface,
        secondaryContainer: AppColors.primarySubtle,
        onSecondaryContainer: AppColors.primaryDark,
        error: AppColors.error,
        onError: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        outline: AppColors.borderSubtle,
        outlineVariant: AppColors.primaryLight,
        surfaceContainerLowest: AppColors.surface,
        surfaceContainerLow: AppColors.primarySubtle,
        surfaceContainer: AppColors.canvas,
        surfaceContainerHigh: AppColors.primaryLight,
        surfaceContainerHighest: AppColors.primaryLight,
        inverseSurface: AppColors.primaryDark,
        onInverseSurface: AppColors.surface,
        inversePrimary: AppColors.accent,
        scrim: AppColors.ink,
        shadow: AppColors.primary.withValues(alpha: 0.12),
      );

  /// Warna shadow bernuansa violet yang lembut, bukan hitam pekat.
  static final Color softShadow = AppColors.primary.withValues(alpha: 0.07);

  /// Tema terang aplikasi.
  static ThemeData light() {
    final textTheme = AppTypography.textTheme(
      ink: AppColors.ink,
      muted: AppColors.muted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      textTheme: textTheme,
      shadowColor: softShadow,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),
      splashFactory: InkRipple.splashFactory,

      // App bar terang dan tenang: permukaan putih di atas kanvas, tanpa elevasi.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontSize: AppTypography.sectionTitleSize,
          fontWeight: AppTypography.semibold,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),

      // Navigasi bawah terang dengan indikator slate blue muda.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? AppTypography.semibold
                : AppTypography.medium,
          ),
        ),
      ),

      // Kartu hairline dengan border subtle dan sudut membulat 16 dp.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: AppSpacing.md,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.controlBorder,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlBorder,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          side: const BorderSide(color: AppColors.primaryLight),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlBorder,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.controlBorder,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.surface
                : AppColors.ink,
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.primaryLight),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
          ),
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.controlBorder,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.ink,
          fontWeight: AppTypography.medium,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: AppTypography.semibold,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.muted,
        textColor: AppColors.ink,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.controlBorder,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.panelBorder,
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: AppTypography.semibold,
        ),
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.controlBorder,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: AppRadius.fixtureBorder,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.surface),
      ),
    );
  }
}
