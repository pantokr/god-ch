import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/layout/confirm_dialog.dart';

/// 교회 정보 관리 아래의 샘플 데이터 카드: 기도제목 · 말씀 · 모임 견본을 한꺼번에 넣어 화면을 확인한다.
/// 누를 때마다 견본이 새로 더해진다.
class SampleDataCard extends StatefulWidget {
  const SampleDataCard({super.key, required this.churchId});

  final String churchId;

  @override
  State<SampleDataCard> createState() => _SampleDataCardState();
}

class _SampleDataCardState extends State<SampleDataCard> {
  bool _busy = false;

  Future<void> _seed() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = AppScope.read(context).sampleData;
    final ok = await confirmChange(
      context,
      title: '샘플 데이터 넣기',
      body: '기도제목 8개 · 말씀 8개 · 모임 7개를 추가합니다.',
      confirmLabel: '넣기',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await repo.seed(widget.churchId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '기도제목 ${r.prayers} · 말씀 ${r.devotions} · 모임 ${r.meetings}개를 넣었어요.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('넣지 못했습니다\n$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '샘플 데이터',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.tonal(
              onPressed: _busy ? null : _seed,
              child: Text(_busy ? '넣는 중' : '넣기'),
            ),
          ],
        ),
      ),
    );
  }
}
