# assets/data/_legacy/

Arquivos **DROPPED** preservados como referência histórica. NÃO são incluídos em `pubspec.yaml` e NÃO são lidos em runtime.

## achievements_legacy.json

Schema flat legacy (pré-Sprint 3.1):

```json
{"key":"...", "title":"...", "xp":50, "gold":25, "gems":0, "secret":false, "title_reward":"..."}
```

**DROPPED no Sprint 3.1 Bloco 1** (schema 24, reset brutal — tabela `achievements` + `player_achievements` foram substituídas por `player_achievements_completed` com PK composta).

**Schema novo** (Sprint 3.1 Bloco 8) vive em `assets/data/achievements.json` com `trigger: {type, event, count}` declarativo, `reward: {xp, gold, items[], achievements_to_check[]}`, `is_secret`.

**Por que preservado aqui**: Bloco 14 (Sprint 3.1) repopula o catálogo novo com as 97 conquistas mapeadas pra schema declarativo. Este arquivo é o **ponto de partida pra conversão** — sem ele, o tradutor do Bloco 14 perde descoberta.

Não apagar até Bloco 14 fechar.
