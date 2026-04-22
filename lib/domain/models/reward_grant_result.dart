import 'reward_resolved.dart';

/// Sprint 3.1 Bloco 5 — resultado de um `RewardGrantService.grant`
/// bem-sucedido. Carrega a reward que foi persistida (útil pro caller
/// exibir no RewardToast / popup do Bloco 10).
///
/// Quando `grant` lança (idempotência violada, missão inexistente, ou
/// falha de DB), não retorna este objeto — exceção cobre o caminho de
/// erro. Ver `lib/domain/exceptions/reward_exceptions.dart`.
class RewardGrantResult {
  final RewardResolved resolved;

  const RewardGrantResult({required this.resolved});
}
