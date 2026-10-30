import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme.dart';

/// 앱 종료 확인 창의 광고 자리. 크기가 [width] x [height]로 고정되어 있어서
/// 광고를 아직 불러오지 못했거나 불러오기에 실패해도 창의 모양이 같다 (그동안은 빈 자리가 보인다).
/// 광고를 불러오면 같은 자리에 그대로 들어가고, 불러오지 못하면 빈 자리로 남는다.
///
/// 지금 쓰는 광고 단위는 구글이 공개한 **테스트용**이다. 실제 광고를 내려면 애드몹에서 만든 앱 ID(Android 매니페스트의
/// `com.google.android.gms.ads.APPLICATION_ID`)와 광고 단위 ID([unitId])로 바꾼다.
class ExitAdSlot extends StatefulWidget {
  const ExitAdSlot({super.key});

  /// 광고 크기 (중간 직사각형 300 x 250). 광고가 없어도 이 크기를 차지한다.
  static const width = 300.0;
  static const height = 250.0;

  /// 구글 공개 테스트 배너 광고 단위. 출시 전에 실제 단위 ID로 바꾼다.
  static const unitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  State<ExitAdSlot> createState() => _ExitAdSlotState();
}

class _ExitAdSlotState extends State<ExitAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // 웹에서는 광고를 쓰지 않는다 (빈 자리만 둔다).
    if (kIsWeb) return;
    _ad = BannerAd(
      adUnitId: ExitAdSlot.unitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          // 불러오지 못하면 빈 자리로 둔다.
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: ExitAdSlot.width,
      height: ExitAdSlot.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.brand.withValues(alpha: 0.05),
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _loaded && _ad != null
            ? AdWidget(ad: _ad!)
            : Center(
                child: Text(
                  '광고',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ),
      ),
    );
  }
}
