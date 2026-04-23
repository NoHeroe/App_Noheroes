import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/balance/individual_delete_cost.dart';
import '../../../domain/models/mission_progress.dart';
import 'mission_card_base.dart';

/// Sprint 3.1 Bloco 10a.2 — card da família **individual**.
///
/// Usuário cria e marca manualmente. Estrutura herda de RealTaskCard
/// (botões ±) + adiciona botão **delete** com confirm dialog. Delete
/// apaga a missão via `IndividualDeleteService` mediante pagamento em
/// gold+gems (ver `IndividualDeleteCost` — valores placeholder, Bloco 11
/// refina).
///
/// Race condition (Regra 4): pop do dialog é a última ação — sem
/// navegação entre rotas, sem `ref.invalidate` manual. O
/// `QuestsScreenNotifier` (Bloco 10a.1) já escuta `MissionFailed` no
/// bus e reinvalida sozinho.
///
/// Criação de missões individuais (form + MissionBalancerService) fica
/// no **Bloco 11**. Aqui assumimos que a row já existe.
class IndividualMissionCard extends ConsumerWidget {
  final MissionProgress mission;

  const IndividualMissionCard({super.key, required this.mission});

  Future<void> _applyDelta(WidgetRef ref, int delta) async {
    final service = ref.read(missionProgressServiceProvider);
    await service.onUserAction(mission.id, delta);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final cost = IndividualDeleteCost.forRank(mission.rank);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar missão individual?'),
        content: Text(
          'Custa ${cost.gold} ouro e ${cost.gems} gemas. A missão '
          'vai pro histórico como "apagada" — não afeta sombra.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('individual-delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('individual-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(individualDeleteServiceProvider).deleteIndividual(
            playerId: mission.playerId,
            missionProgressId: mission.id,
          );
      // Bus → QuestsScreenNotifier.listener → invalidateSelf cuida do refresh.
      // Sem ref.invalidate manual aqui (Regra 4 N/A — não navega entre rotas).
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao apagar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = mission.targetValue == 0
        ? 0.0
        : (mission.currentValue / mission.targetValue).clamp(0.0, 1.0);
    final locked = mission.completedAt != null || mission.failedAt != null;
    return MissionCardBase(
      mission: mission,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: pct),
          const SizedBox(height: 6),
          Text('${mission.currentValue} / ${mission.targetValue}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (!locked) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final delta in const [-25, -10, -1, 1, 10, 25])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        key: ValueKey(
                            'individual-delta-${mission.id}-$delta'),
                        onPressed: () => _applyDelta(ref, delta),
                        child: Text(delta > 0 ? '+$delta' : '$delta'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: ValueKey('individual-delete-${mission.id}'),
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Apagar missão'),
            ),
          ],
        ],
      ),
    );
  }
}
