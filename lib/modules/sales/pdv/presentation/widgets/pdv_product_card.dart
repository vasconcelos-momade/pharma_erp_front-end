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
    final hasStock = product.estoqueAtual > 0;
    final canInteract = canAdd && !isAdding && hasStock;
    final metadataLine =
        'PV ${pdvFormatMoney(product.precoVenda)} • Val. ${pdvFormatDate(product.dataValidade)} • Lote ${product.lote ?? '—'} • Stock ${product.estoqueAtual.toInt()}';

    return EnterpriseListCard(
      title: product.nomeComercial,
      subtitle: (product.nomeGenerico ?? '').isNotEmpty
          ? product.nomeGenerico
          : null,
      leading: Icons.medication_outlined,
      chip: product.requiresPsychotropicBook
          ? EnterpriseStatusChip(
              label: 'Psicotrópico',
              color: t.psychotropic,
            )
          : product.requiresPrescription
              ? EnterpriseStatusChip(
                  label: 'Receita',
                  color: t.posWarning,
                )
              : null,
      metadata: [
        EnterpriseListCardMeta(label: product.categoriaNome ?? '—'),
        EnterpriseListCardMeta(label: metadataLine),
      ],
      onTap: canInteract ? onAdd : null,
      actions: FilledButton.tonalIcon(
        onPressed: canInteract ? onAdd : null,
        icon: isAdding
            ? PharmaButtonLoader(color: t.brandBlue)
            : const Icon(Icons.add_shopping_cart_rounded),
        label: Text(compactAction ? 'Add' : 'Adicionar'),
      ),
    );
  }
}
