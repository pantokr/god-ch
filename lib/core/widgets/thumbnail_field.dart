import 'app_loader.dart';
import 'trash_icon.dart';
import '../icons.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../../features/home/view/content_widgets.dart';
import 'thumbnail_avatar.dart';

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
    this.aspectRatio,
  });

  final TextEditingController controller;

  /// 이미지가 없을 때 아이콘에 보여줄 이름의 머리글자.
  final String name;

  /// 이미지를 올리고 주소를 돌려준다. 실패하면 null (오류 문구는 [errorOf]가 아니라 예외로 알린다).
  final Future<String?> Function(String fileName, Uint8List bytes) upload;
  final String label;
  final bool enabled;

  /// 있으면 원 대신 이 가로:세로 비의 사각형으로 미리 보여 준다 (실제로 게시되는 모양과 같게).
  final double? aspectRatio;

  /// 사각형 미리보기의 가로 길이.
  static const previewWidth = 128.0;

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
            if (widget.aspectRatio == null)
              ThumbnailAvatar(name: widget.name, url: url, radius: 36)
            else
              Container(
                width: ThumbnailField.previewWidth,
                height: ThumbnailField.previewWidth / widget.aspectRatio!,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: palette.border),
                ),
                child: ContentImage(url),
              ),
            const SizedBox(width: 16),
            // 좁은 화면(대화상자)에서도 넘치지 않게 버튼들은 줄바꿈된다.
            Expanded(
              child: _uploading
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoader(),
                      ),
                    )
                  : widget.enabled
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pick,
                          icon: const Icon(AppIcons.image, size: 18),
                          label: Text(url.isEmpty ? '이미지 선택' : '이미지 변경'),
                        ),
                        if (url.isNotEmpty)
                          TextButton(
                            style: TrashIcon.textStyle(context),
                            onPressed: () =>
                                setState(() => widget.controller.clear()),
                            child: const Text('삭제'),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
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
