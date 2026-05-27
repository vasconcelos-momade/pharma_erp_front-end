import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/layout/module_page_frame.dart';

class FinancialPage extends StatelessWidget {
  const FinancialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return ModulePageFrame(
      title: 'FINANCEIRO',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: const [
              EnterpriseStatCard(title: 'Caixa hoje', value: '18 200 MT', icon: Icons.payments_outlined, accent: StatCardAccent.positive),
              EnterpriseStatCard(title: 'A pagar', value: '4 100 MT', icon: Icons.schedule_outlined, accent: StatCardAccent.warning),
            ],
          ),
          const SizedBox(height: 20),
          Text('Movimentos recentes', style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          for (var i = 0; i < 6; i++)
            Material(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radiusMd),
              child: ListTile(
                title: Text(i.isEven ? 'Entrada — vendas' : 'Saída — fornecedor', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                trailing: Text(i.isEven ? '+ 2 400 MT' : '- 900 MT', style: TextStyle(color: i.isEven ? t.brandGreen : t.posDanger, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
