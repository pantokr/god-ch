import 'widgets/app_loader.dart';
import 'icons.dart';

import 'package:flutter/material.dart';

import 'theme.dart';

/// 앱을 켤 때 보이는 스플래시: 로고와 앱 이름. 로그인 상태를 확인하는 동안 최소 1초는 유지된다
/// ([SessionNotifier.minSplash]).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppDepth.brand(context),
                borderRadius: BorderRadius.circular(AppRadius.panel),
                boxShadow: AppDepth.glow(context),
              ),
              child: Icon(AppIcons.handHeart, size: 44, color: palette.onBrand),
            ),
            const SizedBox(height: 20),
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
    );
  }
}
