import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/mvvm/view_model_builder.dart';
import '../../../core/theme.dart';
import '../../../data/models/reaction.dart';
import '../view_model/reaction_bar_view_model.dart';

/// 이모티콘별 개수만 보여주고, 누가 눌렀는지는 노출하지 않는다.
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.churchId,
    required this.prayerId,
  });

  final String churchId;
  final String prayerId;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ReactionBarViewModel>(
      create: (context) => ReactionBarViewModel(
        AppScope.read(context).prayers,
        churchId,
        prayerId,
      ),
      builder: (context, vm) => StreamBuilder<ReactionSummary>(
        stream: vm.summary,
        builder: (context, snap) {
          final summary = snap.data ?? ReactionSummary.empty;
          return Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in reactionTypes)
                      _ReactionPill(
                        type: r,
                        count: summary.counts[r.id] ?? 0,
                        selected: summary.mine.contains(r.id),
                        onTap: snap.hasData
                            ? () => vm.toggle(
                                r.id,
                                currentlyOn: summary.mine.contains(r.id),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              Text(
                '응원 ${summary.total}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.type,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final ReactionType type;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: type.label,
      child: Material(
        color: selected
            ? AppColors.brand.withValues(alpha: 0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(
            color: selected ? AppColors.brand : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              '${type.emoji} $count',
              style: TextStyle(
                color: selected ? AppColors.brand : AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
