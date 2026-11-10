import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme.dart';
import '../widgets/brand_mark.dart';
import 'app_dialog.dart';

/// 앱 정보 창: 앱 이름, 버전, 개발자, 문의. 오른쪽 계정 띠 맨 아래의 정보 버튼이 연다.
Future<void> showAppInfo(BuildContext context) =>
    showAppDialog<void>(context, maxWidth: 360, child: const _AppInfo());

/// 기기에서 버전을 읽지 못할 때 보이는 버전. pubspec.yaml의 version(빌드 번호 제외)과 같게 둔다.
const _fallbackVersion = '1.0.0';

class _AppInfo extends StatelessWidget {
  const _AppInfo();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // 글씨가 커져도 라벨이 값에 맞닿지 않게 칸 너비가 글씨 배율을 따르고, 사이에 여백을 둔다.
            width: MediaQuery.textScalerOf(context).scale(72) + 8,
            child: Text(
              label,
              style: TextStyle(color: palette.muted, fontSize: 14),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: BrandLogo(size: 64)),
        const SizedBox(height: 14),
        Text(
          '같이',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: palette.border),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) {
            final info = snap.data;
            // 불러오지 못해도 버전은 비지 않는다 (pubspec.yaml의 version과 같게 둔다).
            final version = info?.version;
            return row(
              '버전',
              version == null || version.isEmpty ? _fallbackVersion : version,
            );
          },
        ),
        Divider(height: 1, color: palette.border),
        row('개발자', 'panto'),
        Divider(height: 1, color: palette.border),
        row('문의', 'pantokrator3841@gmail.com'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}
