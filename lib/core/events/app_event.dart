/// Sprint 3.1 Bloco 2 — raiz de todos os eventos do EventBus local.
///
/// Contratos:
/// - Eventos são **imutáveis**: todos os campos `final`, construtor `const`
///   sempre que possível.
/// - Cada evento captura um `timestamp` no momento da construção. Útil
///   pra debug/ordering em testes e futuro log.
/// - Subclasses devem redefinir [toString] retornando os campos relevantes
///   sem vazar dados sensíveis (o stream é consumido em debug / testes).
/// - **[playerId] abstrato (Bloco 7 pré-clean)**: todo evento concreto
///   expõe `playerId` via getter herdado. Nas subclasses basta declarar
///   `final int playerId` como campo — Dart satisfaz o getter abstrato
///   automaticamente. Usado pelo `MissionProgressService` pra filtrar
///   eventos do jogador correto sem hacks com `as dynamic`.
///
/// Não existem igualdade estrutural nem hashcode por padrão — dois eventos
/// com o mesmo payload são **instâncias diferentes**. Listeners devem
/// raciocinar por *ocorrência*, não por identidade.
abstract class AppEvent {
  final DateTime timestamp;

  AppEvent({DateTime? at}) : timestamp = at ?? DateTime.now();

  /// Identificador do jogador associado ao evento. Nullable pra permitir
  /// eventos de sistema/global no futuro; todos os 18 eventos do Bloco 2
  /// implementam concretamente com `int playerId` (non-null).
  int? get playerId;
}
