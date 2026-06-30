import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/requisicao.dart';

String formatRequisicaoRouteLabel(String? origem, String? destino) {
  final from = (origem == null || origem.trim().isEmpty)
      ? 'Sem origem'
      : origem.trim();
  final to = (destino == null || destino.trim().isEmpty)
      ? 'Sem destino'
      : destino.trim();
  return '$from -> $to';
}

String _formatRequisicaoDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _requisicaoSecondaryLine(RequisicaoResumo requisicao) {
  if (requisicao.tipo == RequisicaoTipo.compra) {
    return 'Fornecedor: ${requisicao.fornecedorNome ?? 'N/A'}';
  }
  return formatRequisicaoRouteLabel(requisicao.origem, requisicao.destino);
}

Color _statusAccentColor(RequisicaoStatus status, PharmaTokens tokens) {
  if (status.isEditable) {
    return tokens.posWarning;
  }
  if (status.isPositive) {
    return tokens.brandGreen;
  }
  if (status == RequisicaoStatus.rejeitada ||
      status == RequisicaoStatus.cancelada) {
    return tokens.posDanger;
  }
  return tokens.brandBlue;
}

class RequisicaoResumoCard extends StatelessWidget {
  const RequisicaoResumoCard({
    super.key,
    required this.requisicao,
    required this.selected,
    required this.onTap,
  });

  final RequisicaoResumo requisicao;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isFinalized = requisicao.status == RequisicaoStatus.concluida;
    final accent = _statusAccentColor(requisicao.status, t);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Container(
        padding: EdgeInsets.all(s.md),
        decoration: BoxDecoration(
          color: selected ? t.brandBlue.withValues(alpha: 0.08) : t.bgPrimary,
          borderRadius: BorderRadius.circular(t.radiusMd),
          border: Border.all(
            color: selected ? t.brandBlue.withValues(alpha: 0.4) : t.border,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;

            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requisicao.numeroDocumento.isNotEmpty
                      ? 'Doc. ${requisicao.numeroDocumento}'
                      : 'Requisição ${requisicao.id}',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _requisicaoSecondaryLine(requisicao),
                  style: TextStyle(color: t.textMuted),
                ),
                if (requisicao.numeroDocumento.isNotEmpty)
                  Text(
                    'ID interno: ${requisicao.id}',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
              ],
            );

            final actionButtons = isFinalized
                ? IconButton(
                    icon: Icon(Icons.visibility_outlined, size: t.iconSm),
                    onPressed: onTap,
                    tooltip: 'Ver detalhes',
                  )
                : const SizedBox.shrink();

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  SizedBox(height: s.sm),
                  _RequisicaoInfoTag(
                    label: requisicao.status.label,
                    color: accent,
                  ),
                  SizedBox(height: s.sm),
                  Text(
                    'Data: ${_formatRequisicaoDate(requisicao.createdAt)}',
                    style: TextStyle(color: t.textMuted),
                  ),
                  Text(
                    'Itens: ${requisicao.totalItens}',
                    style: TextStyle(color: t.textMuted),
                  ),
                  if (isFinalized) ...[SizedBox(height: s.sm), actionButtons],
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: header),
                    _RequisicaoInfoTag(
                      label: requisicao.status.label,
                      color: accent,
                    ),
                  ],
                ),
                SizedBox(height: s.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data: ${_formatRequisicaoDate(requisicao.createdAt)}',
                          style: TextStyle(color: t.textMuted),
                        ),
                        Text(
                          'Itens: ${requisicao.totalItens}',
                          style: TextStyle(color: t.textMuted),
                        ),
                      ],
                    ),
                    if (isFinalized) actionButtons,
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RequisicaoResumoListTab extends StatelessWidget {
  const RequisicaoResumoListTab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.requisicoes,
    required this.activeRequisicaoId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onSelect,
    required this.emptyIcon,
  });

  final String title;
  final String subtitle;
  final bool isLoading;
  final List<RequisicaoResumo> requisicoes;
  final String? activeRequisicaoId;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<String> onSelect;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        SizedBox(height: s.xs),
        Text(subtitle, style: TextStyle(color: t.textMuted)),
        SizedBox(height: s.sm),
        if (isLoading) const LinearProgressIndicator(),
        SizedBox(height: s.sm),
        Expanded(
          child: requisicoes.isEmpty
              ? RequisicaoResumoEmptyPane(
                  icon: emptyIcon,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                )
              : ListView.separated(
                  itemCount: requisicoes.length,
                  separatorBuilder: (_, _) => SizedBox(height: s.sm),
                  itemBuilder: (context, index) {
                    final requisicao = requisicoes[index];
                    return RequisicaoResumoCard(
                      requisicao: requisicao,
                      selected: requisicao.id == activeRequisicaoId,
                      onTap: () => onSelect(requisicao.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class RequisicaoResumoEmptyPane extends StatelessWidget {
  const RequisicaoResumoEmptyPane({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: t.textMuted),
            SizedBox(height: s.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequisicaoInfoTag extends StatelessWidget {
  const _RequisicaoInfoTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Text(
        label,
        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
