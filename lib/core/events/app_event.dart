/// Sprint 3.1 Bloco 2 — raiz de todos os eventos do EventBus local.
///
/// Contratos:
/// - Eventos são **imutáveis**: todos os campos `final`, construtor `const`
///   sempre que possível.
/// - Cada evento captura um `timestamp` no momento da construção. Útil
///   pra debug/ordering em testes e futuro log.
/// - Subclasses devem redefinir [toString] retornando os campos relevantes
///   sem vazar dados sensíveis (o stream é consumido em debug / testes).
///
/// Não existem igualdade estrutural nem hashcode por padrão — dois eventos
/// com o mesmo payload são **instâncias diferentes**. Listeners devem
/// raciocinar por *ocorrência*, não por identidade.
abstract class AppEvent {
  final DateTime timestamp;

  AppEvent({DateTime? at}) : timestamp = at ?? DateTime.now();
}
