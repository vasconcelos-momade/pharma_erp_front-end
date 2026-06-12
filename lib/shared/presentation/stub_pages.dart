import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/spacing.dart';
import '../widgets/cards/enterprise_stat_card.dart';
import '../widgets/inputs/searchable_dropdown_field.dart';
import '../widgets/layout/enterprise_module_hub.dart';
import '../widgets/tables/enterprise_data_table.dart';

List<DataColumn> _cols(PharmaTokens t, List<String> labels) => labels
    .map(
      (e) => DataColumn(
        label: Text(
          e.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: t.textMuted),
        ),
      ),
    )
    .toList();

// ——— Farmácia ———

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Categorias & classificação',
      subtitle: 'ATC, NCM, grupo terapêutico e regras de venda.',
      tag: 'Farmácia',
      actions: [
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Nova categoria')),
      ],
      kpis: const [
        EnterpriseStatCard(title: 'Categorias activas', value: '128', icon: Icons.category_outlined, accent: StatCardAccent.info),
        EnterpriseStatCard(title: 'Pendente revisão', value: '4', icon: Icons.pending_actions, accent: StatCardAccent.warning),
      ],
      child: EnterpriseDataTable(
        columns: _cols(t, ['Código', 'Descrição', 'SKU ligados']),
        rowCount: 6,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('CAT-${100 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text('Grupo ${i + 1}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${42 + i * 3}', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

class LotsPage extends StatelessWidget {
  const LotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Lotes & rastreabilidade',
      subtitle: 'Entrada, fornecedor, custo médio e bloqueios sanitários.',
      tag: 'Farmácia',
      kpis: const [
        EnterpriseStatCard(title: 'Lotes abertos', value: '312', icon: Icons.layers_outlined, accent: StatCardAccent.info),
        EnterpriseStatCard(title: 'Quarentena', value: '2', icon: Icons.shield_outlined, accent: StatCardAccent.warning),
      ],
      child: EnterpriseDataTable(
        columns: _cols(t, ['Lote', 'SKU', 'Qtd', 'Estado']),
        rowCount: 5,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('LT-2026-${120 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text('SKU-${4000 + i}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${240 - i * 10}', style: TextStyle(color: t.textPrimary))),
            DataCell(
              Chip(
                label: Text(i == 1 ? 'Quarentena' : 'Libertado', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                backgroundColor: i == 1 ? t.posWarning.withValues(alpha: 0.2) : t.brandGreen.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpiryPage extends StatelessWidget {
  const ExpiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Validades & alertas',
      subtitle: 'Curva ABC de vencimento, bloqueio automático e campanhas de saída.',
      tag: 'Farmácia',
      kpis: const [
        EnterpriseStatCard(title: 'Vence 30d', value: '18', icon: Icons.event_busy, accent: StatCardAccent.warning),
        EnterpriseStatCard(title: 'Vencidos', value: '0', icon: Icons.block, accent: StatCardAccent.positive),
      ],
      child: EnterpriseDataTable(
        columns: _cols(t, ['Produto', 'Lote', 'Validade', 'Dias']),
        rowCount: 4,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('Medicamento ${i + 1}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600))),
            DataCell(Text('LT-X$i', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('2026-0${6 + i}-30', style: TextStyle(color: t.textPrimary))),
            DataCell(Text('${45 - i * 5} d', style: TextStyle(color: t.posWarning, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

class FefoPage extends StatelessWidget {
  const FefoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Motor FEFO',
      subtitle: 'Prioridade automática por validade — integrado ao PDV e picking.',
      tag: 'Farmácia',
      kpis: const [
        EnterpriseStatCard(title: 'Filas activas', value: '3', icon: Icons.account_tree, accent: StatCardAccent.info),
        EnterpriseStatCard(title: 'Excepções hoje', value: '1', icon: Icons.warning_amber, accent: StatCardAccent.warning),
      ],
      child: EnterpriseDataTable(
        columns: _cols(t, ['SKU', 'Lote sugerido', 'Validade', 'Prioridade']),
        rowCount: 3,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('SKU-${500 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text('LT-FEFO-$i', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('2026-08-${10 + i}', style: TextStyle(color: t.textPrimary))),
            DataCell(Text('P${i + 1}', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }
}

// ——— Finanças ———

class CashflowPage extends StatelessWidget {
  const CashflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Fluxo de caixa',
      subtitle: 'Tesouraria multi-caixa, conciliação e projeção 13 semanas.',
      tag: 'Finanças',
      kpis: const [
        EnterpriseStatCard(title: 'Saldo hoje', value: '412 000 MT', icon: Icons.account_balance_wallet, accent: StatCardAccent.positive),
        EnterpriseStatCard(title: 'A conciliar', value: '6', icon: Icons.receipt_long, accent: StatCardAccent.warning),
      ],
      child: EnterpriseDataTable(
        columns: _cols(t, ['Data', 'Descrição', 'Entrada', 'Saída']),
        rowCount: 5,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('2026-05-${10 + i}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('Movimento ${i + 1}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600))),
            DataCell(Text(i.isEven ? '+ ${12000 + i * 500} MT' : '—', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w700))),
            DataCell(Text(i.isOdd ? '- ${3000 + i * 200} MT' : '—', style: TextStyle(color: t.posDanger, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Despesas & centros de custo',
      subtitle: 'Aprovação, anexos e integração com tesouraria.',
      tag: 'Finanças',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Ref.', 'Centro', 'Valor', 'Estado']),
        rowCount: 4,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('DESP-2026-$i', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text(i == 0 ? 'Operações' : 'Administrativo', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${8000 + i * 1200} MT', style: TextStyle(color: t.textPrimary))),
            DataCell(Text(i == 2 ? 'Pendente' : 'Aprovado', style: TextStyle(color: i == 2 ? t.posWarning : t.brandGreen, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

// ——— Auditoria ———

class AuditTimelinePage extends StatelessWidget {
  const AuditTimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Cronologia de eventos',
      subtitle: 'Imutável, assinado e correlacionado a utilizador/terminal.',
      tag: 'Auditoria',
      child: ListView.separated(
        itemCount: 8,
        separatorBuilder: (_, _) => Divider(color: t.border.withValues(alpha: 0.35)),
        itemBuilder: (c, i) => ListTile(
          leading: Icon(Icons.bolt, color: t.brandBlue),
          title: Text('Evento de domínio #${900 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
          subtitle: Text('Operador OP • Terminal MAP-01 • 2026-05-14 08:${10 + i}', style: TextStyle(color: t.textMuted, fontSize: 12)),
        ),
      ),
    );
  }
}

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Logs técnicos',
      subtitle: 'Nível DEBUG/INFO/WARN — exportação CSV e retenção legal.',
      tag: 'Auditoria',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Nível', 'Origem', 'Mensagem']),
        rowCount: 6,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text(['INFO', 'WARN', 'ERROR'][i % 3], style: TextStyle(color: [t.brandBlue, t.posWarning, t.posDanger][i % 3], fontWeight: FontWeight.w900))),
            DataCell(Text('sync_worker', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('Checkpoint $i concluído', style: TextStyle(color: t.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class AuditPsychPage extends StatelessWidget {
  const AuditPsychPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Auditoria psicotrópicos',
      subtitle: 'Livro B, receitas, retenção e cruzamento com ANARME.',
      tag: 'Auditoria',
      kpis: const [
        EnterpriseStatCard(title: 'Mov. hoje', value: '14', icon: Icons.verified_user_outlined, accent: StatCardAccent.info),
        EnterpriseStatCard(title: 'Pendências', value: '0', icon: Icons.task_alt, accent: StatCardAccent.positive),
      ],
      child: EnterpriseDataTable(
        columns: _cols(t, ['Receita', 'SKU', 'Qtd', 'Assinatura']),
        rowCount: 3,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('RX-PSI-${2400 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text('Diazepam 10mg', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${1 + i}', style: TextStyle(color: t.textPrimary))),
            DataCell(Icon(Icons.check_circle, color: t.brandGreen, size: 20)),
          ],
        ),
      ),
    );
  }
}

// ——— Stock ———

class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Movimentos de stock',
      subtitle: 'Entradas, saídas, perdas e ajustes com trilho de auditoria.',
      tag: 'Stock',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Tipo', 'SKU', 'Qtd', 'Documento']),
        rowCount: 5,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text(['IN', 'OUT', 'AJ'][i % 3], style: TextStyle(fontWeight: FontWeight.w900, color: t.brandBlue))),
            DataCell(Text('SKU-${800 + i}', style: TextStyle(color: t.textPrimary))),
            DataCell(Text('${10 + i}', style: TextStyle(color: t.textPrimary))),
            DataCell(Text('DOC-${5000 + i}', style: TextStyle(color: t.textMuted))),
          ],
        ),
      ),
    );
  }
}

class StockRequisitionsPage extends StatelessWidget {
  const StockRequisitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Requisições de stock',
      subtitle: 'Rascunhos, confirmação documental e movimentos entre armazéns.',
      tag: 'Stock',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Ref.', 'Origem', 'Destino', 'Estado']),
        rowCount: 3,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('REQ-2026-$i', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('Arm. A', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('Arm. B', style: TextStyle(color: t.textSecondary))),
            DataCell(Text(i == 1 ? 'Em trânsito' : 'Concluído', style: TextStyle(color: i == 1 ? t.posWarning : t.brandGreen, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

@Deprecated('Use StockRequisitionsPage')
typedef StockTransfersPage = StockRequisitionsPage;

class StockAdjustmentsPage extends StatelessWidget {
  const StockAdjustmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Ajustes de inventário',
      subtitle: 'Motivo obrigatório, dupla confirmação e assinatura digital.',
      tag: 'Stock',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Ref.', 'SKU', 'Delta', 'Motivo']),
        rowCount: 2,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('AJ-${88 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('SKU-${1200 + i}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text(i == 0 ? '-2' : '+1', style: TextStyle(color: i == 0 ? t.posDanger : t.brandGreen, fontWeight: FontWeight.w900))),
            DataCell(Text('Contagem cíclica', style: TextStyle(color: t.textMuted))),
          ],
        ),
      ),
    );
  }
}

class StockInventoryPage extends StatelessWidget {
  const StockInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Inventário físico',
      subtitle: 'Contagens cíclicas, divergências e reconciliação automática.',
      tag: 'Stock',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Sessão', 'Responsável', 'Progresso']),
        rowCount: 3,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('INV-2026-${4 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('Farm. ${i + 1}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${60 + i * 10}%', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }
}

// ——— Vendas ———

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Clientes & convénios',
      subtitle: 'CRM operacional, limites de crédito e convénios hospitalares.',
      tag: 'Vendas',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Cliente', 'NUIT', 'Convénio', 'Estado']),
        rowCount: 4,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('Cliente ${i + 1}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text('400${289102 + i}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text(i.isEven ? 'SNS' : 'Particular', style: TextStyle(color: t.textMuted))),
            DataCell(Icon(Icons.verified, color: t.brandGreen, size: 20)),
          ],
        ),
      ),
    );
  }
}

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Faturação',
      subtitle: 'Series, IVA, recibos e ligação ao PDV.',
      tag: 'Vendas',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Fatura', 'Cliente', 'Total', 'Estado']),
        rowCount: 4,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('FT 2026/${120 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('Cliente ${i + 1}', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${1200 + i * 340} MT', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w800))),
            DataCell(Text('Emitida', style: TextStyle(color: t.textMuted))),
          ],
        ),
      ),
    );
  }
}

class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Histórico de vendas',
      subtitle: 'Drill-down por terminal, operador e linha de receita.',
      tag: 'Vendas',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Recibo', 'Terminal', 'Total', 'Hora']),
        rowCount: 6,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('RC-${8800 + i}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('MAP-01', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${450 + i * 120} MT', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w800))),
            DataCell(Text('09:${10 + i}', style: TextStyle(color: t.textMuted))),
          ],
        ),
      ),
    );
  }
}

// ——— Utilizadores ———

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Utilizadores',
      subtitle: 'RBAC, multi-inquilino e políticas de sessão.',
      tag: 'Administração',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Nome', 'Perfil', 'Último acesso']),
        rowCount: 4,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('Operador ${i + 1}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text(['Farmacêutico', 'Caixa', 'Gestor'][i % 3], style: TextStyle(color: t.textSecondary))),
            DataCell(Text('2026-05-14 0${7 + i}:42', style: TextStyle(color: t.textMuted, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class UserProfilesPage extends StatelessWidget {
  const UserProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Perfis de acesso',
      subtitle: 'Conjuntos de permissões reutilizáveis por unidade.',
      tag: 'Administração',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Perfil', 'Permissões', 'Utilizadores']),
        rowCount: 3,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text(['Gestor', 'Farmacêutico', 'Caixa PDV'][i], style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('${24 + i * 4} permissões', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('${3 + i}', style: TextStyle(color: t.brandBlue, fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }
}

class UserPermissionsPage extends StatelessWidget {
  const UserPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scopes = ['pdv.sell', 'stock.adjust', 'finance.read', 'audit.export'];
    return EnterpriseModuleHub(
      title: 'Matriz de permissões',
      subtitle: 'Granularidade por módulo e acção.',
      tag: 'Administração',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchableDropdownField<String>(
            label: 'Filtrar permissão',
            items: scopes,
            display: (e) => e,
            onChanged: (_) {},
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'RBAC multi-inquilino: ${scopes.length} permissões de exemplo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

// ——— Definições ———

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Definições gerais',
      subtitle: 'Entidade, idioma, moeda e políticas de sessão.',
      tag: 'Sistema',
      child: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.business, color: t.brandBlue),
            title: Text('Unidade activa', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('Farmácia Central de Maputo', style: TextStyle(color: t.textMuted)),
            trailing: TextButton(onPressed: () => context.go(AppRoutePaths.authTenant), child: const Text('Alterar')),
          ),
          Divider(color: t.border.withValues(alpha: 0.35)),
          ListTile(
            leading: Icon(Icons.sync, color: t.brandGreen),
            title: Text('Sincronização', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('Intervalo, fila offline e resolução de conflitos', style: TextStyle(color: t.textMuted)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutePaths.settingsSync),
          ),
        ],
      ),
    );
  }
}

class PrintersPage extends StatelessWidget {
  const PrintersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Impressoras térmicas',
      subtitle: 'ESC/POS, largura 58/80mm, cópias e vias.',
      tag: 'Sistema',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Nome', 'Driver', 'Estado']),
        rowCount: 2,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text(i == 0 ? 'Balcão A' : 'Armazém', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('ESC/POS USB', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('Activo', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

class TerminalsPage extends StatelessWidget {
  const TerminalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Terminais & PDV',
      subtitle: 'Registo de dispositivos, licenças e heartbeat.',
      tag: 'Sistema',
      child: EnterpriseDataTable(
        columns: _cols(t, ['Terminal', 'Versão', 'Último ping']),
        rowCount: 3,
        rowBuilder: (c, i) => DataRow(
          cells: [
            DataCell(Text('MAP-0${i + 1}', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800))),
            DataCell(Text('1.0.0', style: TextStyle(color: t.textSecondary))),
            DataCell(Text('há ${i + 1} min', style: TextStyle(color: t.brandGreen, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

class SyncSettingsPage extends StatelessWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Sincronização híbrida',
      subtitle: 'Backoff, batch size, WebSocket e política de conflitos.',
      tag: 'Sistema',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text('Sincronização em background', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('Prioriza operação de balcão', style: TextStyle(color: t.textMuted)),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: Text('Nova tentativa automática', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: Text('Política exponencial', style: TextStyle(color: t.textMuted)),
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}
