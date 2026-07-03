import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';

class RequisicaoEmptyPane extends StatelessWidget {
  const RequisicaoEmptyPane({
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
    return ModuleEmptyState(title: title, subtitle: subtitle);
  }
}

class RequisicaoInfoTag extends StatelessWidget {
  const RequisicaoInfoTag({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return EnterpriseStatusChip(label: label, color: color);
  }
}
