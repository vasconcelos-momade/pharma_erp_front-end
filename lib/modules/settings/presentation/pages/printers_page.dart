import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../platform/printing/thermal/printer_discovery.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';

class PrintersPage extends ConsumerStatefulWidget {
  const PrintersPage({super.key});

  @override
  ConsumerState<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends ConsumerState<PrintersPage> {
  PrinterConnection? _defaultPrinter;
  List<PrinterConnection> _discovered = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.readThermalPrinterDefault();
      PrinterConnection? configured;
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          configured = PrinterConnection.fromStorageValue(raw);
        } catch (_) {
          configured = null;
        }
      }

      final discovered =
          await ref.read(printerDiscoveryProvider).listBluetoothPrinters();
      if (!mounted) return;
      setState(() {
        _defaultPrinter = configured;
        _discovered = discovered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiFailure ? e.message : e.toString();
      });
    }
  }

  List<PrinterConnection> get _rows => [
        ...?_defaultPrinter == null ? null : [_defaultPrinter!],
        ..._discovered.where((printer) => printer.id != _defaultPrinter?.id),
      ];

  @override
  Widget build(BuildContext context) {
    return EnterpriseModuleHub(
      title: 'Impressoras térmicas',
      subtitle: 'ESC/POS, largura 58/80mm, cópias e vias.',
      tag: 'Sistema',
      actions: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      child: ResponsiveBuilder(
        builder: (context, constraints) =>
            _buildBody(context, context.pharmaTokens, !constraints.isTabletOrWider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PharmaTokens t, bool isMobile) {
    if (_loading) return const ModuleLoadingState();
    if (_error != null) {
      return ModuleErrorState(
        title: 'Falha ao carregar impressoras',
        message: _error!,
        onRetry: _load,
        icon: Icons.print_outlined,
      );
    }

    if (_rows.isEmpty) {
      return const ModuleEmptyState(
        title: 'Nenhuma impressora configurada',
        subtitle: 'Configure uma impressora térmica no fluxo de impressão de faturas.',
      );
    }

    if (isMobile) {
      final s = context.spacing;
      return EnterpriseMobileScrollList(
        stickyHeader: ColoredBox(
          color: t.bgPrimary,
          child: Padding(
            padding: EdgeInsets.fromLTRB(s.md, s.sm, s.md, s.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Impressoras disponíveis',
                    style: Theme.of(context).textTheme.erpSectionTitle.copyWith(
                          color: t.textPrimary,
                        ),
                  ),
                ),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
        ),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final printer = _rows[index];
          final isDefault = printer.id == _defaultPrinter?.id;
          return EnterpriseListCard(
            leading: Icons.print_outlined,
            title: printer.label,
            subtitle: printer.summary,
            chip: EnterpriseStatusChip(
              label: isDefault ? 'Predefinida' : 'Disponível',
              color: isDefault ? t.brandGreen : t.textMuted,
            ),
          );
        },
        hasMore: false,
        isLoading: false,
        emptyMessage: 'Nenhuma impressora configurada',
      );
    }

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: [
        for (final label in ['Nome', 'Ligação', 'Estado'])
          DataColumn(
            label: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: _rows.length,
      rowBuilder: (context, index) {
        final printer = _rows[index];
        final isDefault = printer.id == _defaultPrinter?.id;
        return DataRow(
          cells: [
            DataCell(Text(
              printer.label,
              style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
            )),
            DataCell(Text(
              printer.summary,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
            )),
            DataCell(Text(
              isDefault ? 'Predefinida' : 'Disponível',
              style: Theme.of(context).textTheme.erpLabel.copyWith(
                    color: isDefault ? t.brandGreen : t.textMuted,
                  ),
            )),
          ],
        );
      },
    );
  }
}
