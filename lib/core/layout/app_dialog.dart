import 'package:flutter/material.dart';

/// 바텀시트 대신 쓰는 가운데 대화상자.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required Widget child,
  double maxWidth = 480,
}) => showDialog<T>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    ),
  ),
);
