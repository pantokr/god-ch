import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import 'back_navigation.dart';
import 'layout/app_dialog.dart';
import 'widgets/exit_ad_slot.dart';

/// 뒤로 가기 처리. 화면 위에 쌓인 화면에서는 평소처럼 이전 화면으로 돌아간다.
/// 탭 · 메뉴 사이를 오갈 때는 화면이 쌓이지 않고 바뀌기만 해서(go) 바로 앱이 끝나 버리므로,
/// [location]으로 방문한 화면을 기억해 두었다가 뒤로 가기를 누르면 직전에 보던 화면으로 돌아간다.
/// 더 돌아갈 화면이 없을 때(첫 화면)와 기본 페이지(모임 일정 · 중보기도 · 말씀묵상 · 내 활동)에서는 앱을 종료할지 묻는다.
/// 묻는 창에는 크기가 고정된 광고 자리가 있다 ([ExitAdSlot]).
/// 웹에서는 브라우저가 알아서 하므로 아무것도 하지 않는다.
class ExitGuard extends StatefulWidget {
  const ExitGuard({super.key, required this.child, this.location});

  final Widget child;

  /// 지금 보는 화면의 주소. 주면 방문 기록을 남겨 뒤로 가기가 직전 화면으로 돌아간다.
  final String? location;

  /// 직전에 보던 화면으로 돌아간다. 기록이 없으면 [fallback]으로 간다 (위쪽 바의 뒤로 버튼용).
  static void back(BuildContext context, String fallback) {
    final state = context.findAncestorStateOfType<_ExitGuardState>();
    if (state != null && state._goBack(context)) return;
    context.goBack(fallback);
  }

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  /// 방문한 화면들 (맨 뒤가 지금 화면).
  final List<String> _history = [];
  static const _maxHistory = 30;

  @override
  void initState() {
    super.initState();
    _visit(widget.location);
  }

  @override
  void didUpdateWidget(ExitGuard old) {
    super.didUpdateWidget(old);
    _visit(widget.location);
  }

  void _visit(String? location) {
    if (location == null || _history.isNotEmpty && _history.last == location) {
      return;
    }
    // 이미 지나온 화면으로 돌아온 것이면 그 뒤의 기록을 접는다 (뒤로 가기 반복을 막는다).
    final at = _history.lastIndexOf(location);
    if (at >= 0) {
      _history.removeRange(at + 1, _history.length);
      return;
    }
    _history.add(location);
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// 지금 화면이 기본 페이지(모임 일정 · 중보기도 · 말씀묵상 · 내 활동)인가.
  /// 기본 페이지에서 뒤로 가기를 누르면 직전 화면으로 가지 않고 곧바로 종료 확인 창이 뜬다.
  bool get _onBasePage {
    final current = _history.isEmpty ? widget.location : _history.last;
    if (current == null) return false;
    final segments = Uri.parse(current).pathSegments;
    // /churches/{교회}/{메뉴}
    return segments.length == 3 &&
        segments[0] == 'churches' &&
        const {'meetings', 'prayer', 'bible', 'mine'}.contains(segments[2]);
  }

  /// 직전 화면으로 이동한다. 갈 곳이 없으면 false.
  bool _goBack(BuildContext context) {
    if (_history.length < 2) return false;
    _history.removeLast();
    context.go(_history.last);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;
    // 이 화면이 스택의 맨 아래이면 뒤로 가기는 앱 종료를 뜻한다.
    final atRoot = ModalRoute.of(context)?.isFirst ?? false;
    return PopScope(
      canPop: !atRoot,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // 기본 페이지가 아니면 먼저 직전에 보던 화면으로 돌아간다.
        if (!_onBasePage && _goBack(context)) return;
        final exit = await showAppDialog<bool>(
          context,
          maxWidth: 360,
          child: const _ExitDialog(),
        );
        if (exit == true) await SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}

/// 앱 종료 확인 창: 제목, 크기가 고정된 광고 자리, 취소 · 종료 버튼 (다른 대화상자와 같은 틀).
/// 광고 자리가 고정이라 광고가 늦게 오거나 오지 않아도 창이 커지거나 줄어들지 않는다.
class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DialogTitle('앱 종료'),
        const Center(child: ExitAdSlot()),
        DialogActions(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('종료'),
            ),
          ],
        ),
      ],
    );
  }
}
