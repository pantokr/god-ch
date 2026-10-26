import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// 썸네일 이미지 입력란. [controller]의 글자가 이미지 주소다 (비어 있으면 이미지가 없는 것).
/// 이미지를 고르면 [upload]로 올리고, 돌려받은 주소를 [controller]에 넣는다.
/// 저장은 이 입력란을 가진 화면의 저장 버튼이 한다.
class ThumbnailField extends StatefulWidget {
  const ThumbnailField({
    super.key,
    required this.controller,
    required this.name,
    required this.upload,
    this.label = '썸네일',
    this.enabled = true,
  });

  final TextEditingController controller;

  /// 이미지가 없을 때 아이콘에 보여줄 이름의 머리글자.
  final String name;

  /// 이미지를 올리고 주소를 돌려준다. 실패하면 null (오류 문구는 [errorOf]가 아니라 예외로 알린다).
  final Future<String?> Function(String fileName, Uint8List bytes) upload;
  final String label;
  final bool enabled;

  @override
  State<ThumbnailField> createState() => _ThumbnailFieldState();
}

class _ThumbnailFieldState extends State<ThumbnailField> {
  bool _uploading = false;
  String? _error;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await widget.upload(file.name, await file.readAsBytes());
      if (url == null) {
        _error = '이미지를 올리지 못했어요.';
      } else {
        widget.controller.text = url;
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final url = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: palette.brand.withValues(alpha: 0.12),
              backgroundImage: url.isEmpty ? null : NetworkImage(url),
              child: url.isEmpty
                  ? Text(
                      widget.name.isEmpty ? '?' : widget.name.characters.first,
                      style: TextStyle(
                        color: palette.brand,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            if (_uploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (widget.enabled) ...[
              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(url.isEmpty ? '이미지 선택' : '이미지 변경'),
              ),
              if (url.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => widget.controller.clear()),
                  child: const Text('삭제'),
                ),
            ],
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
