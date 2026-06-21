import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';

class RequisicaoTopActionsBar extends StatelessWidget {
  const RequisicaoTopActionsBar({
    super.key,
    required this.selectedTipo,
    required this.isCreating,
    required this.onSelectTipo,
    required this.onCreate,
  });

  final String selectedTipo;
  final bool isCreating;
  final ValueChanged<String> onSelectTipo;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Wrap(
      spacing: s.sm,
      runSpacing: s.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RequisicaoTipoSelector(
          selectedTipo: selectedTipo,
          onSelectTipo: onSelectTipo,
        ),
        FilledButton.icon(
          onPressed: isCreating ? null : onCreate,
          icon: isCreating
              ? const PharmaButtonLoader()
              : const Icon(Icons.add_rounded),
          label: const Text('Criar Requisição'),
        ),
      ],
    );
  }
}

class RequisicaoTipoSelector extends StatelessWidget {
  const RequisicaoTipoSelector({
    super.key,
    required this.selectedTipo,
    required this.onSelectTipo,
  });

  final String selectedTipo;
  final ValueChanged<String> onSelectTipo;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);

    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.padded,
        side: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return BorderSide(color: isSelected ? t.brandBlue : t.border);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? t.brandBlue.withValues(alpha: 0.12)
              : t.card;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? t.textPrimary
              : t.textMuted;
        }),
        textStyle: WidgetStateProperty.all(
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
          ),
        ),
      ),
      segments: const [
        ButtonSegment<String>(value: 'compra', label: Text('Compra')),
        ButtonSegment<String>(value: 'entrada', label: Text('Entrada')),
        ButtonSegment<String>(value: 'saida', label: Text('Saída')),
      ],
      selected: {selectedTipo},
      onSelectionChanged: (selection) {
        final value = selection.isEmpty ? null : selection.first;
        if (value != null) {
          onSelectTipo(value);
        }
      },
      multiSelectionEnabled: false,
      emptySelectionAllowed: false,
    );
  }
}
