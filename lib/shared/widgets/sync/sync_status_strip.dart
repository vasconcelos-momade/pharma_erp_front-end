import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';

enum SyncVisualState { online, syncing, offline, conflict }

/// Indicador de sincronização / WebSocket — modo **compact** só ícone (mobile / topbar estreito).
class SyncStatusStrip extends StatelessWidget {
  const SyncStatusStrip({
    super.key,
    this.state = SyncVisualState.online,
    this.pendingCount = 0,
    this.wsConnected = true,
    this.onTap,
    this.compact = false,
  });

  final SyncVisualState state;
  final int pendingCount;
  final bool wsConnected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final (Color fg, Color bg, IconData icon, String title, String subtitle) = switch (state) {
      SyncVisualState.online => (
          t.brandGreen,
          t.brandGreen.withValues(alpha: 0.1),
          Icons.cloud_done_outlined,
          'Sincronizado',
          wsConnected ? 'Realtime activo' : 'Polling',
        ),
      SyncVisualState.syncing => (
          t.brandBlue,
          t.brandBlue.withValues(alpha: 0.12),
          Icons.sync,
          'A sincronizar',
          pendingCount > 0 ? '$pendingCount na fila' : 'Background',
        ),
      SyncVisualState.offline => (
          t.posWarning,
          t.posWarning.withValues(alpha: 0.12),
          Icons.cloud_off_outlined,
          'Offline',
          pendingCount > 0 ? '$pendingCount pendente(s)' : 'Cache local',
        ),
      SyncVisualState.conflict => (
          t.posDanger,
          t.posDanger.withValues(alpha: 0.12),
          Icons.merge_type,
          'Conflitos',
          'Resolver antes de fechar',
        ),
    };

    if (compact) {
      return Tooltip(
        message: '$title — $subtitle',
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: fg.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, size: 18, color: fg),
            ),
          ),
        ),
      );
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: fg.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: fg,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: t.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
