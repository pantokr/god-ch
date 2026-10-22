import 'package:flutter/material.dart';

/// 앱 전체의 모서리 둥글기. 아주 약하게만 둥글린다.
class AppRadius {
  AppRadius._();

  /// 버튼·입력창·칩·배지 등 작은 요소.
  static const control = 4.0;

  /// 카드·팝업 메뉴.
  static const card = 6.0;

  /// 대화상자.
  static const dialog = 8.0;
}

class AppColors {
  AppColors._();

  static const brand = Color(0xFF5B5BD6);
  static const ink = Color(0xFF1F1F29);
  static const muted = Color(0xFF6B6B76);
  static const bg = Color(0xFFF6F6F9);
  static const border = Color(0xFFE3E3EA);
}

/// 플랫폼 기본 전환(슬라이드) 대신 웹처럼 부드러운 페이드를 쓴다.
class _FadeTransitions extends PageTransitionsBuilder {
  const _FadeTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    surface: Colors.white,
  );
  final radius = BorderRadius.circular(AppRadius.control);
  final shape = RoundedRectangleBorder(borderRadius: radius);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamilyFallback: const [
      'Pretendard',
      'Noto Sans KR',
      'Apple SD Gothic Neo',
      'Malgun Gothic',
      'sans-serif',
    ],
    textTheme: Typography.blackMountainView.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    // 눌렀을 때 물결 대신 hover 색으로 반응한다.
    splashFactory: NoSplash.splashFactory,
    hoverColor: AppColors.brand.withValues(alpha: 0.06),
    highlightColor: Colors.transparent,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values) p: const _FadeTransitions(),
      },
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      space: 1,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 40),
        foregroundColor: AppColors.ink,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
    ),
    chipTheme: ChipThemeData(
      side: const BorderSide(color: AppColors.border),
      shape: shape,
      backgroundColor: Colors.white,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    // 선택 버튼(공개 범위·필터)도 약한 모서리로 맞춘다.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(shape),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(shape: shape),
    // 모바일 하단 탭: 그림자 없이 위쪽 테두리만 둔다.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: AppColors.brand.withValues(alpha: 0.12),
      indicatorShape: shape,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.brand
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.brand
              : AppColors.muted,
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: AppColors.border,
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.brand,
      tabAlignment: TabAlignment.start,
    ),
  );
}
