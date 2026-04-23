/// Sprint 3.1 Bloco 13b — matrix de alianças/rivalidades entre facções.
///
/// DESIGN_DOC §Admissão (linha 498-500) estabelece o **princípio** —
/// "Facções têm relações de aliança e rivalidade; reputação numa afeta
/// aliadas (positivo) e rivais (negativo)" — mas **NÃO especifica quais
/// facções são aliadas/rivais de quais**.
///
/// Na ausência de decisão de produto sobre as identidades/relações, esta
/// matrix fica em **estado NEUTRO**: todas as 7 entradas existem pra não
/// quebrar o `FactionReputationService.adjustReputation`, mas sem
/// propagação (mapa interno vazio). O service chama `forEach` sobre as
/// aliadas — sem entries, zero efeito cascata.
///
/// Código de propagação fica pronto; dados ficam placeholder. Raul
/// preenche em sprint visual futura com identidades definitivas.
///
/// ## Formato quando preenchida
///
/// ```dart
/// const kFactionAlliances = {
///   'guild': {
///     'new_order': 0.3,   // reputação na Guild sobe 30% do delta em New Order
///     'black_legion': -0.5, // cai 50% do delta em Black Legion (rival)
///   },
///   // ...
/// };
/// ```
///
/// Valores no intervalo `[-1.0, 1.0]` (signo indica aliada vs rival,
/// magnitude indica força da relação).
const Map<String, Map<String, double>> kFactionAlliances = {
  // Versão NEUTRA — zero propagação. Raul preenche em sprint visual.
  'guild': {},
  'moon_clan': {},
  'sun_clan': {},
  'black_legion': {},
  'new_order': {},
  'trinity': {},
  'renegades': {},
};

/// Lista canônica de faction keys suportadas. Usada pelo
/// `WeeklyResetService` pra validar `players.faction_type` contra enum
/// conhecido (valores `null`, `none`, `pending:X` ou strings não-listadas
/// viram skip silencioso + log warning).
const Set<String> kKnownFactions = {
  'guild',
  'moon_clan',
  'sun_clan',
  'black_legion',
  'new_order',
  'trinity',
  'renegades',
};
