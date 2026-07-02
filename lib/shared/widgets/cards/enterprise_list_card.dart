import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/typography.dart';

/// Cartão mobile padronizado para listagens enterprise.
class EnterpriseListCard extends StatelessWidget {
  const EnterpriseListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.chip,
    this.metadata = const [],
    this.onTap,
    this.actions,
    this.isBusy = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final Widget? chip;
  final List<EnterpriseListCardMeta> metadata;
  final VoidCallback? onTap;
  final Widget? actions;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(t.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Icon(leading, size: t.iconSm, color: t.textPrimary),
                    SizedBox(width: s.xs),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.erpCardTitle.copyWith(
                            color: t.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: s.xxs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.erpBodySecondary.copyWith(
                              color: t.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (chip != null) ...[SizedBox(width: s.xs), chip!],
                  if (isBusy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (actions != null)
                    actions!
                  else if (trailing != null)
                    trailing!,
                ],
              ),
              if (metadata.isNotEmpty) ...[
                SizedBox(height: s.xs),
                for (var i = 0; i < metadata.length; i++) ...[
                  if (i > 0) SizedBox(height: s.xxs),
                  _MetaRow(meta: metadata[i]),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EnterpriseListCardMeta {
  const EnterpriseListCardMeta({
    required this.label,
    this.color,
    this.alignEnd = false,
  });

  final String label;
  final Color? color;
  final bool alignEnd;
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.meta});

  final EnterpriseListCardMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Text(
      meta.label,
      textAlign: meta.alignEnd ? TextAlign.end : TextAlign.start,
      style: Theme.of(context).textTheme.erpCaption.copyWith(
            color: meta.color ?? t.textMuted,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Chip de estado para cartões mobile.
class EnterpriseStatusChip extends StatelessWidget {
  const EnterpriseStatusChip({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final resolved = color ?? t.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: resolved),
      ),
    );
  }
}
