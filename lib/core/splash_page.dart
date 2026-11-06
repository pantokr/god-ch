import 'widgets/app_loader.dart';

import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/brand_mark.dart';

/// 앱을 켤 때 보이는 스플래시: 마크(G + 십자가)와 같이, 하단에 God and Church. 로그인 상태를 확인하는 동안 최소 3초는 유지된다
/// ([SessionNotifier.minSplash]).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base = TextStyle(
      color: palette.muted,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
    );
    // 강조: God과 Church의 마지막 ch.
    final strong = base.copyWith(
      color: palette.brand,
      fontWeight: FontWeight.w900,
    );
    return Scaffold(
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppDepth.brand(context),
                        borderRadius: BorderRadius.circular(AppRadius.panel),
                        boxShadow: AppDepth.glow(context),
                      ),
                      alignment: Alignment.center,
                      child: BrandMark(size: 60, color: palette.onBrand),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '같이',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(width: 22, height: 22, child: AppLoader()),
                  ],
                ),
              ),
            ),
            // 하단: God and Church (God과 마지막 ch를 강조).
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      TextSpan(text: 'God', style: strong),
                      const TextSpan(text: ' and Chur'),
                      TextSpan(text: 'ch', style: strong),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
