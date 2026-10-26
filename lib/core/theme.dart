import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전체의 모서리 둥글기. 아주 약하게만 둥글린다.
class AppRadius {
  AppRadius._();

  /// 버튼·입력창·칩·배지 등 작은 요소.
  static const control = 4.0;

  /// 로그인·회원가입 패널처럼 각지게 보이는 큰 틀 (둥글지 않다).
  static const panel = 0.0;

  /// 카드·팝업 메뉴.
  static const card = 6.0;

  /// 대화상자.
  static const dialog = 8.0;
}

/// 앱의 색 팔레트. 라이트("따뜻한 종이")와 다크("따뜻한 밤") 두 벌이 있고,
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

  /// 주 포인트 색 (숲 녹색).
  final Color brand;

  /// [brand] 위에 올리는 글자색.
  final Color onBrand;

  /// 보조 포인트 색 (금빛). 응원 같은 따뜻한 강조에 쓴다.
  final Color accent;

  /// 따뜻한 종이: 아이보리 바탕에 숲 녹색과 금빛.
  static const light = AppPalette(
    ink: Color(0xFF2B2622),
    muted: Color(0xFF6F665D),
    bg: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFDFA),
    border: Color(0xFFE7E0D5),
    brand: Color(0xFF2F5D50),
    onBrand: Color(0xFFFFFFFF),
    accent: Color(0xFFB8863B),
  );

  /// 따뜻한 밤: 따뜻한 먹색 바탕에 밝은 녹색과 금빛.
  static const dark = AppPalette(
    ink: Color(0xFFF2ECE3),
    muted: Color(0xFFAFA699),
    bg: Color(0xFF171513),
    surface: Color(0xFF211E1B),
    border: Color(0xFF3B352F),
    brand: Color(0xFF86BBA9),
    onBrand: Color(0xFF0F1F1A),
    accent: Color(0xFFD9A85A),
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

  // 제목은 명조, 본문과 UI 글자는 산세리프로 둔다 (입력창·목록은 산세리프를 그대로 쓴다).
  final base = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: p.ink, displayColor: p.ink);
  TextStyle? serif(TextStyle? style) => GoogleFonts.notoSerifKr(
    textStyle: style?.copyWith(fontWeight: FontWeight.w700),
  );
  final textTheme = base.copyWith(
    displayLarge: serif(base.displayLarge),
    displayMedium: serif(base.displayMedium),
    displaySmall: serif(base.displaySmall),
    headlineLarge: serif(base.headlineLarge),
    headlineMedium: serif(base.headlineMedium),
    headlineSmall: serif(base.headlineSmall),
    titleLarge: serif(base.titleLarge),
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
    hoverColor: p.brand.withValues(alpha: 0.07),
    highlightColor: Colors.transparent,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const _FadeTransitions(),
      },
    ),
    dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: p.border),
      ),
    ),
    // 입력란은 둥근 테두리 없이 밑줄만 쓴다. 글자 수 표시는 입력란 아래 줄을 차지하므로 숨기고,
    // 안내 문구는 각 입력란의 suffixText·hintText 안에 넣는다 (한도는 maxLength가 그대로 막는다).
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      counterStyle: const TextStyle(fontSize: 0, height: 0),
      border: UnderlineInputBorder(borderSide: BorderSide(color: p.border)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: p.brand, width: 2),
      ),
      suffixStyle: TextStyle(color: p.muted, fontSize: 12),
      // 힌트(예시 글자)는 아주 옅게 해서 입력한 값과 확실히 구별되게 한다.
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.35)),
      // 입력란 안에 들어가 있는 제목(비어 있을 때)도 옅게, 값이 있거나 선택되어 위로 올라가면 보통 색.
      labelStyle: TextStyle(color: p.muted.withValues(alpha: 0.35)),
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
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: p.border),
        foregroundColor: p.ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: shape,
        minimumSize: const Size(0, 40),
        foregroundColor: p.ink,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: p.border),
      shape: shape,
      backgroundColor: p.surface,
      labelStyle: TextStyle(color: p.ink),
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
      backgroundColor: p.ink,
      contentTextStyle: TextStyle(color: p.bg),
    ),
    // 모바일 하단 탭: 그림자 없이 위쪽 테두리만 둔다.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: p.brand.withValues(alpha: 0.14),
      indicatorShape: shape,
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
