import '../../../core/icons.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/back_navigation.dart';

import '../../../app/app_scope.dart';
import '../../../app/routes.dart';
import '../../../core/format.dart';
import '../../../core/layout/app_dialog.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/church_content.dart';
import '../../../data/models/member.dart';
import '../../bible/view/bible_picker_dialog.dart';
import '../view_model/content_list_view_model.dart';
import 'content_widgets.dart';

/// 콘텐츠 관리: 교회 운영자 전용. 한 종류(공지·일정 …)의 글을 추가 · 수정 · 삭제한다.
/// 콘텐츠 관리 화면에서 들어오며, 왼쪽 위 화살표로 돌아간다.
class ContentEditPage extends StatelessWidget {
  const ContentEditPage({super.key, required this.me, required this.kind});

  final Member me;
  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final narrow = MediaQuery.sizeOf(context).width < kNarrow;
    // 바탕을 채워서, 아래에 깔린 이전 화면(콘텐츠 관리 카드)이 비쳐 보이지 않게 한다.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: narrow ? 8 : 28),
                Row(
                  children: [
                    IconButton(
                      tooltip: '콘텐츠 관리',
                      icon: const Icon(AppIcons.arrowLeft),
                      onPressed: () =>
                          context.goBack(Routes.contentEdit(me.churchId)),
                    ),
                    Expanded(
                      child: Text(
                        '${kind.label} 관리',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _KindTab(me: me, kind: kind),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindTab extends StatelessWidget {
  const _KindTab({required this.me, required this.kind});

  final Member me;
  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ContentListViewModel>(
      create: (context) => ContentListViewModel(
        AppScope.read(context).contents,
        me.churchId,
        kind,
      ),
      builder: (context, vm) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: vm.busy ? null : () => _edit(context, vm),
                icon: const Icon(AppIcons.plus, size: 18),
                label: Text('${kind.label} 추가'),
              ),
            ),
            const SizedBox(height: 16),
            ContentStream(
              stream: vm.items,
              builder: (context, items) {
                if (items.isEmpty) {
                  return EmptyHint('등록된 ${kind.label}이(가) 없어요.');
                }
                return Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          title: Text(
                            items[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(fmtDate(items[i].date)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: '수정',
                                icon: const Icon(
                                  AppIcons.pencilSimple,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _edit(context, vm, content: items[i]),
                              ),
                              IconButton(
                                tooltip: '삭제',
                                icon: const Icon(AppIcons.trash, size: 20),
                                onPressed: () =>
                                    _confirmDelete(context, vm, items[i]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    ContentListViewModel vm, {
    ChurchContent? content,
  }) => editContent(context, vm, content: content);

  Future<void> _confirmDelete(
    BuildContext context,
    ContentListViewModel vm,
    ChurchContent content,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${kind.label} 삭제'),
        content: Text('"${content.title}"을(를) 삭제할까요? 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!await vm.delete(content.id) && vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }
}

/// 글 추가·수정 양식을 열고, 저장하면 [vm]의 종류로 저장한다 (콘텐츠 관리 목록과 종류별 화면이 함께 쓴다).
/// [areas]는 고를 수 있는 영역 이름들이다. 없으면 그 종류의 글에 이미 적힌 영역을 쓴다.
Future<void> editContent(
  BuildContext context,
  ContentListViewModel vm, {
  ChurchContent? content,
  List<String>? areas,
}) async {
  final names = areas ?? await _areasOf(vm);
  if (!context.mounted) return;
  final result = await showAppDialog<_FormResult>(
    context,
    maxWidth: 560,
    child: _ContentForm(
      kind: vm.kind,
      categories: names,
      initial: content,
      upload: vm.uploadImage,
      errorOf: () => vm.error,
    ),
  );
  if (result == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await vm.save(
    id: content?.id,
    title: result.title,
    body: result.body,
    date: result.date,
    imageUrls: result.imageUrls,
    videoUrl: result.videoUrl,
    category: result.category,
  );
  if (!ok && vm.error != null) {
    messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
  }
}

Future<List<String>> _areasOf(ContentListViewModel vm) async {
  try {
    final items = await vm.items.first;
    return {
      for (final c in items)
        if (c.category.isNotEmpty) c.category,
    }.toList()..sort();
  } catch (_) {
    return const [];
  }
}

class _FormResult {
  const _FormResult({
    required this.title,
    required this.body,
    required this.date,
    required this.imageUrls,
    required this.videoUrl,
    required this.category,
  });

  final String title;
  final String body;
  final DateTime date;
  final List<String> imageUrls;
  final String videoUrl;
  final String category;
}

/// 종류에 맞는 입력칸을 보여 주는 추가·수정 양식. 저장하면 입력값을 돌려준다.
/// 이미지는 고른 즉시 Storage에 올리고, 글에는 올라간 이미지의 주소만 담는다.
class _ContentForm extends StatefulWidget {
  const _ContentForm({
    required this.kind,
    required this.upload,
    required this.errorOf,
    required this.categories,
    this.initial,
  });

  final ContentKind kind;
  final ChurchContent? initial;

  /// 고를 수 있는 영역 이름들.
  final List<String> categories;

  /// 이미지를 올리고 주소를 돌려준다. 실패하면 null.
  final Future<String?> Function(String fileName, Uint8List bytes) upload;

  /// 마지막 업로드 실패 이유.
  final String? Function() errorOf;

  @override
  State<_ContentForm> createState() => _ContentFormState();
}

class _ContentFormState extends State<_ContentForm> {
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _body = TextEditingController(text: widget.initial?.body);
  late final _video = TextEditingController(text: widget.initial?.videoUrl);
  late String _area = widget.initial?.category ?? '';
  late DateTime _date = widget.initial?.date ?? DateTime.now();

  // 공지: [썸네일, 배경] 두 칸. 사진첩: 여러 장.
  late String? _thumb = widget.initial?.thumbnail;
  late String? _background = widget.initial?.background;
  late final List<String> _photos = [...?widget.initial?.imageUrls];

  bool _uploading = false;
  String? _error;

  ContentKind get _kind => widget.kind;

  // 종류마다 쓰는 입력칸과 안내 문구가 다르다.
  bool get _hasDate => const {
    ContentKind.event,
    ContentKind.sermon,
    ContentKind.devotion,
  }.contains(_kind);
  bool get _isNotice => _kind == ContentKind.notice;
  bool get _isPhoto => _kind == ContentKind.photo;
  bool get _hasVideo => _kind == ContentKind.sermon;

  /// 구조가 분류별로 골라 보여줄 수 있는 종류 (공지 · 사진첩 · 설교영상).
  bool get _hasCategory => const {
    ContentKind.notice,
    ContentKind.photo,
    ContentKind.sermon,
  }.contains(_kind);

  String get _titleLabel => switch (_kind) {
    ContentKind.photo => '앨범 제목',
    ContentKind.devotion => '말씀 구절 (예: 시편 23:1-6)',
    _ => '제목',
  };
  String get _bodyLabel => switch (_kind) {
    ContentKind.event => '장소 · 설명',
    ContentKind.sermon => '설교 요약',
    ContentKind.devotion => '묵상 내용',
    _ => '내용',
  };
  String get _dateLabel => switch (_kind) {
    ContentKind.event => '일정 날짜',
    ContentKind.sermon => '설교한 날',
    _ => '묵상 날짜',
  };

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _video.dispose();
    super.dispose();
  }

  /// 성경 구절을 골라 제목(구절)과 본문에 넣는다. 본문에 이미 쓴 글이 있으면 그 앞에 구절을 둔다.
  Future<void> _pickVerse() async {
    final pick = await showAppDialog<BiblePick>(
      context,
      child: const BiblePickerDialog(),
    );
    if (pick == null) return;
    setState(() {
      _title.text = pick.title;
      final written = _body.text.trim();
      _body.text = written.isEmpty ? pick.body : '${pick.body}\n\n$written';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// 이미지를 골라 올린다. [multiple]이면 여러 장을 한꺼번에 고를 수 있다.
  Future<List<String>> _pickAndUpload({required bool multiple}) async {
    final files = multiple
        ? await FilePicker.pickFiles(type: FileType.image)
        : [?await FilePicker.pickFile(type: FileType.image)];
    if (files.isEmpty) return const [];
    setState(() {
      _uploading = true;
      _error = null;
    });
    final urls = <String>[];
    for (final f in files) {
      final url = await widget.upload(f.name, await f.readAsBytes());
      if (url == null) {
        _error = widget.errorOf() ?? '이미지를 올리지 못했어요.';
        break;
      }
      urls.add(url);
    }
    if (mounted) setState(() => _uploading = false);
    return urls;
  }

  Future<void> _setThumb() async {
    final urls = await _pickAndUpload(multiple: false);
    if (urls.isNotEmpty) setState(() => _thumb = urls.first);
  }

  Future<void> _setBackground() async {
    final urls = await _pickAndUpload(multiple: false);
    if (urls.isNotEmpty) setState(() => _background = urls.first);
  }

  Future<void> _addPhotos() async {
    final urls = await _pickAndUpload(multiple: true);
    if (urls.isNotEmpty) setState(() => _photos.addAll(urls));
  }

  void _submit() {
    if (_isNotice && _thumb == null && _background != null) {
      setState(() => _error = '썸네일을 먼저 올려 주세요.');
      return;
    }
    Navigator.pop(
      context,
      _FormResult(
        title: _title.text,
        body: _body.text,
        // 날짜를 받지 않는 종류는 올린 시각을 쓴다 (수정할 때는 원래 날짜를 지킨다).
        date: _hasDate ? _date : (widget.initial?.date ?? DateTime.now()),
        imageUrls: _isNotice
            ? [?_thumb, if (_thumb != null) ?_background]
            : _isPhoto
            ? _photos
            : const [],
        videoUrl: _hasVideo ? _video.text : '',
        category: _hasCategory ? _area : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_kind.label} ${editing ? '수정' : '추가'}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        AppField.spacer,
        TextField(
          controller: _title,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(labelText: _titleLabel),
        ),
        if (_hasCategory && widget.categories.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('영역', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('영역 없음'),
                selected: _area.isEmpty,
                onSelected: (_) => setState(() => _area = ''),
              ),
              for (final c in {
                ...widget.categories,
                if (_area.isNotEmpty) _area,
              })
                ChoiceChip(
                  label: Text(c),
                  selected: _area == c,
                  onSelected: (_) => setState(() => _area = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_kind == ContentKind.devotion) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickVerse,
              icon: const Icon(AppIcons.bookOpen, size: 18),
              label: const Text('성경 구절 불러오기'),
            ),
          ),
        ],
        if (_hasDate) ...[
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(AppIcons.calendarBlank, size: 18),
            label: Text('$_dateLabel  ${fmtDate(_date)}'),
          ),
          const SizedBox(height: 16),
        ],
        if (_hasVideo) ...[
          TextField(
            controller: _video,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '유튜브 주소',
              hintText: 'https://www.youtube.com/watch?v=...',
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_isNotice) ...[
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ImageSlot(
                label: '썸네일 (4:3)',
                aspect: kThumbnailAspect,
                width: 160,
                url: _thumb,
                busy: _uploading,
                onPick: _setThumb,
                onClear: () => setState(() => _thumb = null),
              ),
              _ImageSlot(
                label: '캐러셀 배경 (가로, 선택)',
                aspect: 16 / 9,
                width: 220,
                url: _background,
                busy: _uploading,
                onPick: _setBackground,
                onClear: () => setState(() => _background = null),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_isPhoto) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _photos.length; i++)
                _PhotoThumb(
                  url: _photos[i],
                  onRemove: () => setState(() => _photos.removeAt(i)),
                ),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _addPhotos,
                icon: const Icon(AppIcons.imageSquare, size: 18),
                label: const Text('사진 올리기'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _body,
          minLines: 4,
          maxLines: 12,
          maxLength: 5000,
          decoration: InputDecoration(
            labelText: _bodyLabel,
            alignLabelWithHint: true,
          ),
        ),
        if (_uploading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              child: const Text('저장'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 이미지 한 장을 올리는 칸: 정해진 비율의 미리보기와 올리기·삭제 버튼.
class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.label,
    required this.aspect,
    required this.width,
    required this.url,
    required this.busy,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final double aspect;
  final double width;
  final String? url;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          AspectRatio(
            aspectRatio: aspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: ContentImage(url),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onPick,
                  child: Text(url == null ? '올리기' : '바꾸기'),
                ),
              ),
              if (url != null)
                IconButton(
                  tooltip: '삭제',
                  icon: const Icon(AppIcons.x, size: 18),
                  onPressed: busy ? null : onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 66,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: ContentImage(url),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: Icon(AppIcons.x, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
