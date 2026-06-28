import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../platform/printing/thermal/printer_connection.dart';
import '../../../../platform/printing/thermal/printer_discovery.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

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
      child: _buildBody(t),
    );
  }

  Widget _buildBody(PharmaTokens t) {
    if (_loading) return const ModuleLoadingState();
    if (_error != null) {
      return ModuleErrorState(
        title: 'Falha ao carregar impressoras',
        message: _error!,
        onRetry: _load,
        icon: Icons.print_outlined,
      );
    }

    final rows = <PrinterConnection>[
      ...?_defaultPrinter == null ? null : [_defaultPrinter!],
      ..._discovered.where(
        (printer) => printer.id != _defaultPrinter?.id,
      ),
    ];

    if (rows.isEmpty) {
      return const ModuleEmptyState(
        title: 'Nenhuma impressora configurada',
        subtitle: 'Configure uma impressora térmica no fluxo de impressão de faturas.',
      );
    }

    return EnterpriseDataTable(
      columns: [
        for (final label in ['Nome', 'Ligação', 'Estado'])
          DataColumn(
            label: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: t.textMuted,
              ),
            ),
          ),
      ],
      rowCount: rows.length,
      rowBuilder: (context, index) {
        final printer = rows[index];
        final isDefault = printer.id == _defaultPrinter?.id;
        return DataRow(
          cells: [
            DataCell(Text(
              printer.label,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            )),
            DataCell(Text(
              printer.summary,
              style: TextStyle(color: t.textSecondary),
            )),
            DataCell(Text(
              isDefault ? 'Predefinida' : 'Disponível',
              style: TextStyle(
                color: isDefault ? t.brandGreen : t.textMuted,
                fontWeight: FontWeight.w800,
              ),
            )),
          ],
        );
      },
    );
  }
}
