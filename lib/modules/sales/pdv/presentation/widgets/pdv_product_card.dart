import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_catalog_utils.dart';

class PdvProductCard extends StatelessWidget {
  const PdvProductCard({
    super.key,
    required this.product,
    required this.canAdd,
    required this.isAdding,
    required this.onAdd,
    this.compactAction = false,
  });

  final Product product;
  final bool canAdd;
  final bool isAdding;
  final VoidCallback onAdd;
  final bool compactAction;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final stockIndisponivel = product.estoqueAtual <= 0;
    final stockColor = stockIndisponivel ? t.posDanger : t.textMuted;
    final canInteract = canAdd && !isAdding;
    final metadataLine =
        'PV ${pdvFormatMoney(product.precoVenda)} • Val. ${pdvFormatDate(product.dataValidade)} • Lote ${product.lote ?? '—'} • Stock ${product.estoqueAtual.toInt()}';

    return EnterpriseListCard(
      title: product.nomeComercial,
      subtitle: (product.nomeGenerico ?? '').isNotEmpty
          ? product.nomeGenerico
          : null,
      leading: Icons.medication_outlined,
      chip: stockIndisponivel
          ? EnterpriseStatusChip(
              label: 'Stock indisponível',
              color: t.posDanger,
            )
          : product.requiresPsychotropicBook
              ? EnterpriseStatusChip(
                  label: 'Psicotrópico',
                  color: t.psychotropic,
                )
              : null,
      metadata: [
        EnterpriseListCardMeta(label: product.categoriaNome ?? '—'),
        EnterpriseListCardMeta(label: metadataLine, color: stockColor),
      ],
      onTap: canInteract ? onAdd : null,
      actions: FilledButton(
        onPressed: canInteract ? onAdd : null,
        child: isAdding
            ? PharmaButtonLoader(color: t.bgPrimary)
            : Text(compactAction ? '+' : 'Add'),
      ),
    );
  }
}
