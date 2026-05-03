/// Sprint 3.1 Bloco 13b — matrix de alianças/rivalidades entre facções.
/// Sprint 3.4 Etapa A — populada com identidades validadas pelo CEO (Q13).
///
/// `FactionReputationService.adjustReputation` itera as entries de
/// `kFactionAlliances[factionId]` e aplica `delta × multiplier` em
/// cada facção relacionada (aliada ou rival).
///
/// ## Formato
///
/// `Map<sourceFaction, Map<otherFaction, multiplier>>`. Valores no
/// intervalo `[-1.0, 1.0]`:
///   - **+** = aliada (delta positivo na source amplifica positivamente)
///   - **-** = rival (delta positivo na source amplifica negativamente)
///   - magnitude indica força da relação
///
/// ## Decisões CEO (Q13 — Sprint 3.4 plan-first)
///
/// - `moon_clan ↔ error` (aliados ocultos — blueprint factions.md §14)
/// - `black_legion ↔ new_order` (rivais — Nova Ordem = remanescentes que
///   recusaram a Legião)
/// - `trinity ↔ renegades` (rivais — sagrado vs mercenário)
/// - `sun_clan ↔ moon_clan` (rivais cósmicos óbvios)
/// - `guild` aliada **fraco com TODAS** (filosofia "ajudar é nossa
///   natureza", blueprint factions.md §15)
/// - Demais pares: neutro (sem entry)
///
/// Magnitudes calibradas pra ser perceptíveis sem virar cascata
/// explosiva: rivais cósmicos (sun↔moon) o mais forte (-0.5);
/// aliados ocultos (moon↔error) +0.4; rivalidades narrativas
/// (black↔new_order, trinity↔renegades) -0.3 a -0.4; guild
/// universal +0.1.
const Map<String, Map<String, double>> kFactionAlliances = {
  'moon_clan': {
    'error': 0.4,
    'sun_clan': -0.5,
    'guild': 0.1,
  },
  'sun_clan': {
    'moon_clan': -0.5,
    'guild': 0.1,
  },
  'error': {
    'moon_clan': 0.4,
    'guild': 0.1,
  },
  'black_legion': {
    'new_order': -0.4,
    'guild': 0.1,
  },
  'new_order': {
    'black_legion': -0.4,
    'guild': 0.1,
  },
  'trinity': {
    'renegades': -0.3,
    'guild': 0.1,
  },
  'renegades': {
    'trinity': -0.3,
    'guild': 0.1,
  },
  'guild': {
    'moon_clan': 0.1,
    'sun_clan': 0.1,
    'black_legion': 0.1,
    'new_order': 0.1,
    'trinity': 0.1,
    'renegades': 0.1,
    'error': 0.1,
  },
};

/// Lista canônica de faction keys suportadas. Usada pelo
/// `WeeklyResetService` pra validar `players.faction_type` contra enum
/// conhecido (valores `null`, `none`, `pending:X` ou strings não-listadas
/// viram skip silencioso + log warning).
///
/// Sprint 3.4 — `error` adicionada ao set canônico. Antes ficava de fora
/// porque era "facção secreta" (não selecionável até unlock), mas isso
/// fazia o `WeeklyResetService._validFactionId` rejeitar players que
/// efetivamente entraram na ERROR via SECRET_LOBO_SOLITARIO unlock.
const Set<String> kKnownFactions = {
  'guild',
  'moon_clan',
  'sun_clan',
  'black_legion',
  'new_order',
  'trinity',
  'renegades',
  'error',
};

/// Sprint 3.4 hotfix P2 — gate de visibilidade pra facções secretas
/// (`isSecret=true` em factions.json).
///
/// `FactionSelectionScreen._loadFactions` consulta este mapa pra
/// decidir se uma facção secreta deve aparecer na lista de seleção. O
/// player só vê uma facção secreta na lista após **desbloquear a
/// conquista mapeada** aqui.
///
/// ## Default conservador
///
/// Facções com `isSecret=true` que **não têm entry** neste mapa ficam
/// **escondidas pra todo mundo**. Pra liberar uma secreta nova, é
/// obrigatório adicionar entry aqui — caso contrário ninguém vê.
///
/// ## Estado atual (Sprint 3.4 hotfix P2)
///
/// - `error` → `SECRET_LOBO_SOLITARIO`. Conquista está hoje com
///   `disabled=true` no catálogo (shell — trigger real "atinge lvl 7
///   sem facção" é ativado na Etapa F). Resultado pré-Etapa F:
///   `error` invisível pra todos os players via flow normal — fecha
///   leak de mistério reportado pelo CEO. Dev panel oferece
///   "Forçar unlock SECRET_LOBO_SOLITARIO" pra teste manual.
///
/// ## Histórico do débito
///
/// `FactionSelectionScreen._loadFactions` mostrava TODAS as facções
/// (incluindo `error`) desde Sprint 3.1. Comentário existente no
/// código já reconhecia o gap: "FactionsService (com filtro de
/// secretas por achievement) não é reimplementado no Bloco 7".
/// Bloco 7 não foi feito; débito atravessou Sprints 3.1, 3.2, 3.3 e
/// foi pego em validação manual de gameplay na Sprint 3.4 hotfix P2.
const Map<String, String> kSecretFactionUnlockKey = {
  'error': 'SECRET_LOBO_SOLITARIO',
};
