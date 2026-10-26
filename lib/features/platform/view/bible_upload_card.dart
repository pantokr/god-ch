import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/app_exception.dart';
import '../../../core/theme.dart';
import '../../bible/data/bible_repository.dart';

/// 앱 운영자 대시보드: 말씀 묵상에서 쓸 성경 본문(verse.csv)을 Storage에 올린다.
/// 한 번 올려 두면 모든 교회가 말씀 묵상에서 구절을 골라 가져올 수 있다.
class BibleUploadCard extends StatefulWidget {
  const BibleUploadCard({super.key});

  @override
  State<BibleUploadCard> createState() => _BibleUploadCardState();
}

class _BibleUploadCardState extends State<BibleUploadCard> {
  late final BibleRepository _bible = AppScope.read(context).bible;
  late Future<bool> _exists = _bible.exists();
  bool _busy = false;
  String? _message;
  bool _error = false;

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (file == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _bible.upload(await file.readAsBytes());
      _message = '성경 본문을 올렸어요.';
      _error = false;
      _exists = _bible.exists();
    } on AppException catch (e) {
      _message = e.message;
      _error = true;
    } catch (e) {
      _message = '올리지 못했어요: $e';
      _error = true;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined, color: palette.muted),
                const SizedBox(width: 10),
                Text('성경 본문', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '말씀 묵상을 쓸 때 구절을 골라 가져오는 데 쓰는 verse.csv 파일이에요. '
              '(개역한글 · 개역개정 · 새번역 · KJV · NIV)',
              style: TextStyle(color: palette.muted),
            ),
            const SizedBox(height: 12),
            FutureBuilder<bool>(
              future: _exists,
              builder: (context, snap) {
                final text = switch (snap.connectionState) {
                  ConnectionState.done =>
                    snap.hasError
                        ? '올린 파일이 있는지 확인하지 못했어요.'
                        : (snap.data == true ? '올려져 있어요.' : '아직 올리지 않았어요.'),
                  _ => '확인하는 중…',
                };
                return Text('상태: $text');
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('verse.csv 올리기'),
                ),
                if (_busy) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _error
                        ? Theme.of(context).colorScheme.error
                        : palette.brand,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
