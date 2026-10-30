import 'package:flutter/material.dart';

import '../theme.dart';

/// 프로필 이미지(원)의 테두리. 앱의 모든 프로필 이미지가 같은 테두리를 쓴다.
/// 작은 이미지는 얇게, 큰 이미지는 조금 굵게 그린다. 이미지 위에 겹쳐 그릴 때 쓴다.
BoxDecoration avatarRing(BuildContext context, double radius) {
  final palette = context.palette;
  return BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: palette.brand.withValues(alpha: 0.35),
      width: radius >= 20 ? 1.5 : 1,
    ),
  );
}

/// 둥근 썸네일. [url]이 있으면 그 이미지를, 없거나 불러오지 못하면 [name]의 머리글자를 보여준다.
/// 웹에서 Firebase Storage 이미지는 CORS 때문에 일반 방식으로는 그려지지 않으므로,
/// 실패하면 HTML 이미지 요소로 대신 그리도록 한다 (메인 페이지 이미지와 같은 방식).
class ThumbnailAvatar extends StatelessWidget {
  const ThumbnailAvatar({
    super.key,
    required this.name,
    this.url = '',
    this.radius = 20,
  });

  final String name;
  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: TextStyle(
          color: palette.brand,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Container(
      width: radius * 2,
      height: radius * 2,
      foregroundDecoration: avatarRing(context, radius),
      child: ClipOval(
        child: ColoredBox(
          color: palette.brand.withValues(alpha: 0.12),
          child: url.isEmpty
              ? initial
              : Image.network(
                  url,
                  key: ValueKey(url),
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, error, _) {
                    // 불러오지 못한 이유를 브라우저 콘솔에서 볼 수 있게 남긴다.
                    debugPrint('썸네일을 불러오지 못했어요: $url ($error)');
                    return initial;
                  },
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : initial,
                ),
        ),
      ),
    );
  }
}
