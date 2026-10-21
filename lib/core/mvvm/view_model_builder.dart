import 'package:flutter/widgets.dart';

/// ViewModel을 만들고 위젯이 사라질 때 정리하며, 변경될 때마다 화면을 다시 그린다.
class ViewModelBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelBuilder({
    super.key,
    required this.create,
    required this.builder,
  });

  /// 처음 한 번만 호출된다. 저장소는 `AppScope.read(context)`로 가져온다.
  final T Function(BuildContext context) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends ChangeNotifier>
    extends State<ViewModelBuilder<T>> {
  late final T _viewModel = widget.create(context);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => widget.builder(context, _viewModel),
  );
}
