import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체의 모서리 둥글기. 부드럽고 넉넉하게 둥글린다.
class AppRadius {
  AppRadius._();

  /// 버튼·입력창·칩·배지 등 작은 요소.
  static const control = 12.0;

  /// 로그인·회원가입 패널 같은 큰 틀.
  static const panel = 24.0;

  /// 카드·팝업 메뉴.
  static const card = 16.0;

  /// 대화상자.
  static const dialog = 24.0;
}

/// 면을 살짝 띄우는 부드러운 그림자 (두 겹: 넓고 옅은 것 + 가깝고 또렷한 것).
class AppShadow {
  AppShadow._();

  static List<BoxShadow> soft(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = dark ? Colors.black : const Color(0xFF2A2F6B);
    return [
      BoxShadow(
        color: c.withValues(alpha: dark ? 0.35 : 0.07),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: c.withValues(alpha: dark ? 0.25 : 0.05),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }
}

/// 입체감을 주는 도구: 겹친 그림자([raised])와 포인트색 그라데이션([brand]).
class AppDepth {
  AppDepth._();

  /// 떠 있는 느낌의 그림자. 넓고 옅은 그림자 위에 가까운 진한 그림자를 겹친다.
  static List<BoxShadow> raised(BuildContext context, {Color? tint}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = tint ?? (dark ? Colors.black : const Color(0xFF2A2F6B));
    return [
      BoxShadow(
        color: c.withValues(alpha: dark ? 0.45 : 0.14),
        blurRadius: 28,
        spreadRadius: -4,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: c.withValues(alpha: dark ? 0.35 : 0.10),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: dark ? 0.04 : 0.9),
        blurRadius: 2,
        offset: const Offset(0, -1),
      ),
    ];
  }

  /// 포인트색이 살짝 밝아졌다 어두워지는 대각선 그라데이션.
  static LinearGradient brand(BuildContext context) {
    final b = context.palette.brand;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(b, Colors.white, 0.22)!,
        b,
        Color.lerp(b, Colors.black, 0.18)!,
      ],
      stops: const [0, 0.5, 1],
    );
  }
}

/// 앱의 색 팔레트. 라이트("소프트 인디고")와 다크("딥 인디고") 두 벌이 있고,
/// 화면에서는 `context.palette`로 꺼내 쓴다 (고정 색 대신 이것을 써야 다크 모드를 따라간다).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ink,
    required this.muted,
    required this.bg,
    required this.surface,
    required this.border,
    required this.brand,
    required this.onBrand,
    required this.accent,
  });

  /// 본문 글자색.
  final Color ink;

  /// 보조 글자색 (날짜, 설명 등).
  final Color muted;

  /// 페이지 배경.
  final Color bg;

  /// 카드·대화상자·입력창 같은 면.
  final Color surface;

  /// 얇은 테두리와 구분선.
  final Color border;

  /// 주 포인트 색 (인디고).
  final Color brand;

  /// [brand] 위에 올리는 글자색.
  final Color onBrand;

  /// 보조 포인트 색 (코랄). 응원 같은 따뜻한 강조에 쓴다.
  final Color accent;

  /// 소프트 인디고: 연한 라벤더 바탕에 흰 카드, 인디고 포인트와 코랄 강조.
  static const light = AppPalette(
    ink: Color(0xFF191B2E),
    muted: Color(0xFF6B6F8D),
    bg: Color(0xFFF3F4FB),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3E5F2),
    brand: Color(0xFF5B5FEF),
    onBrand: Color(0xFFFFFFFF),
    accent: Color(0xFFFF7A6B),
  );

  /// 딥 인디고: 남색에 가까운 먹색 바탕에 밝은 인디고와 코랄.
  static const dark = AppPalette(
    ink: Color(0xFFECEDF8),
    muted: Color(0xFF9A9EBD),
    bg: Color(0xFF0E1020),
    surface: Color(0xFF181B30),
    border: Color(0xFF2B2F4D),
    brand: Color(0xFF8E92FF),
    onBrand: Color(0xFF0E1020),
    accent: Color(0xFFFF9A8C),
  );

  @override
  AppPalette copyWith({
    Color? ink,
    Color? muted,
    Color? bg,
    Color? surface,
    Color? border,
    Color? brand,
    Color? onBrand,
    Color? accent,
  }) => AppPalette(
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    border: border ?? this.border,
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    accent: accent ?? this.accent,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  /// 지금 테마(라이트/다크)의 색 팔레트.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// 기도제목 본문처럼 길게 읽는 글에 쓰는 명조 글꼴.
TextStyle readingStyle(BuildContext context) => GoogleFonts.notoSerifKr(
  textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.85),
);

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

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme =
      ColorScheme.fromSeed(seedColor: p.brand, brightness: brightness).copyWith(
        primary: p.brand,
        onPrimary: p.onBrand,
        surface: p.surface,
        onSurface: p.ink,
        outline: p.border,
        outlineVariant: p.border,
      );
  final radius = BorderRadius.circular(AppRadius.control);
  final shape = RoundedRectangleBorder(borderRadius: radius);

  // 제목은 굵고 촘촘한 산세리프로, 본문과 UI 글자는 그대로 둔다 (긴 글만 [readingStyle]의 명조).
  final base = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: p.ink, displayColor: p.ink);
  TextStyle? serif(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4);
  final textTheme = base.copyWith(
    displayLarge: serif(base.displayLarge),
    displayMedium: serif(base.displayMedium),
    displaySmall: serif(base.displaySmall),
    headlineLarge: serif(base.headlineLarge),
    headlineMedium: serif(base.headlineMedium),
    headlineSmall: serif(base.headlineSmall),
    titleLarge: serif(base.titleLarge),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.bg,
    fontFamily: 'Pretendard',
    fontFamilyFallback: const [
      'Noto Sans KR',
      'Apple SD Gothic Neo',
      'Malgun Gothic',
      'sans-serif',
    ],
    textTheme: textTheme,
    // 눌렀을 때 물결 대신 hover 색으로 반응한다.
    splashFactory: NoSplash.splashFactory,
    hoverColor: p.brand.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const _FadeTransitions(),
      },
    ),
    dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      elevation: 3,
      shadowColor:
          (brightness == Brightness.dark
                  ? Colors.black
                  : const Color(0xFF2A2F6B))
              .withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      color: p.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: p.border.withValues(alpha: 0.7)),
      ),
    ),
    // 입력란은 연하게 채운 둥근 칸이다. 글자 수 표시는 입력란 아래 줄을 차지하므로 숨기고,
    // 안내 문구는 각 입력란의 suffixText·hintText 안에 넣는다 (한도는 maxLength가 그대로 막는다).
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.alphaBlend(
        p.brand.withValues(alpha: brightness == Brightness.dark ? 0.08 : 0.04),
        p.bg,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterStyle: const TextStyle(fontSize: 0, height: 0),
      // 제목이 테두리에 걸쳐지지 않도록, 윤곽선 대신 채운 칸(밑줄형)을 쓴다.
      // 제목은 칸 안에 있다가 입력하면 칸 안쪽 위로 올라간다.
      border: UnderlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: UnderlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: UnderlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: p.brand, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      suffixStyle: TextStyle(color: p.muted, fontSize: 12),
      // 힌트(예시 글자)는 아주 옅게 해서 입력한 값과 확실히 구별되게 한다.
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.45)),
      labelStyle: TextStyle(color: p.muted.withValues(alpha: 0.6)),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.error)
              ? null
              : (states.contains(WidgetState.focused) ? p.brand : p.muted),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        side: BorderSide(color: p.border, width: 1.5),
        foregroundColor: p.ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: p.brand,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: p.border),
      shape: const StadiumBorder(),
      backgroundColor: p.surface,
      selectedColor: p.brand.withValues(alpha: 0.16),
      checkmarkColor: p.brand,
      labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w600),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: p.border),
      ),
    ),
    // 선택 버튼(공개 범위·필터)도 약한 모서리로 맞춘다.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(shape),
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.brand.withValues(alpha: 0.14)
              : p.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.brand : p.ink,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      shape: shape,
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: TextStyle(color: p.bg),
    ),
    // 모바일 하단 탭: 알약 모양 선택 표시.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      height: 68,
      indicatorColor: p.brand.withValues(alpha: 0.16),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? p.brand : p.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.brand : p.muted,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: p.border,
      labelColor: p.brand,
      unselectedLabelColor: p.muted,
      indicatorColor: p.brand,
      tabAlignment: TabAlignment.start,
    ),
  );
}
