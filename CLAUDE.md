# CLAUDE.md — Manual operacional do Claude Code no projeto NoHeroes

> Este arquivo é lido automaticamente pelo Claude Code em cada sessão.
> Define convenções, gatilhos de documentação e workflow de commits do projeto.
> **Quando estas regras conflitarem com o pedido pontual do CEO, o pedido vence — mas reportar a divergência explicitamente.**

---

## Estrutura de repositórios

Este projeto convive com **dois repositórios git separados**:

| Repo | Path | Conteúdo | Quando commita |
|---|---|---|---|
| `App_Noheroes` (principal) | `C:\Dev\Projetos\App_Noheroes\` | Código Flutter/Dart + testes + assets | Mudanças de produto |
| Vault Obsidian | `.vault/` (junção/symlink, repo próprio) | Documentação canônica do projeto (ADRs, sprints, postmortems, journal, MOC) | Mudanças de docs |

O vault está listado em `.gitignore` do projeto principal — não é submódulo, não é tracked. O CEO faz `git push` independente em cada repo.

---

## Vault — onde documentar

| Caminho | Propósito |
|---|---|
| `.vault/App/00_Index/ESTADO_ATUAL.md` | Snapshot do projeto: versão em produção, schema atual, sprint ativa, fases. **Manter atualizado** sempre que mudar versão/schema/sprint. |
| `.vault/App/00_Index/MOC.md` | Map of Content (Obsidian) — índice navegável. |
| `.vault/App/00_Index/REGRAS_ENGENHARIA.md` | 10 leis do projeto. Consultar antes de qualquer mudança não-trivial. |
| `.vault/App/02_ADRs/ADR-XXXX-titulo-kebab.md` | Decisões arquiteturais. **Numeração sequencial 4 dígitos.** Próximo número = descobrir dinamicamente (ver `.claude/workflow.md`). |
| `.vault/App/03_Sprints/Fase_X_Y/Sprint_Z.W.md` | Sprint planejada/em andamento. |
| `.vault/App/03_Sprints/Sprint_Z.W_close.md` | Sprint fechada — escrita ao publicar release. |
| `.vault/App/03_Sprints/ROADMAP.md` | Plano macro 5 fases + épocas do projeto. |
| `.vault/App/docs/postmortems/YYYY-MM-DD-titulo-kebab.md` | Bugs P0/P1 detectados em produção. |
| `.vault/App/docs/sprints/journal.txt` | Log cronológico de sprints e hotfixes. **Append-only.** |
| `.vault/App/docs/lessons/YYYY-MM-DD-titulo-kebab.md` | Lições técnicas standalone (sem postmortem específico). Pasta criada lazy na 1ª lição. |

---

## Gatilhos de documentação automática

Resumo dos eventos que disparam atualização no vault:

| Evento | Ação |
|---|---|
| Etapa fechada (commit `feat`/`fix` em sprint ativa) | Atualiza `Sprint_X.Y.md` + `journal.txt` |
| Sprint fechada (tag publicada) | Cria `Sprint_X.Y_close.md` + atualiza `ESTADO_ATUAL` + `ROADMAP` + `journal` |
| Decisão arquitetural significativa | Cria `ADR-XXXX-titulo-kebab.md` + atualiza `ESTADO_ATUAL` com link |
| Bug em produção (P0/P1) | Cria `postmortem` + appende `journal` + (se houver pattern preventivo) cria ADR |
| Lição técnica standalone | Cria `docs/lessons/...md` |

Quando **não** documentar:
- Refactors triviais (cosmetic, naming)
- Hotfixes pequenos sem impacto arquitetural
- Bumps de dependência sem refactor
- Mudanças de UI sem mudança de comportamento

### Workflow detalhado

Ver [`.claude/workflow.md`](.claude/workflow.md) pra gatilhos específicos, comandos de descoberta dinâmica de números (próximo ADR, sprint ativa) e checklist de commit.

---

## Convenções de naming

| Tipo | Padrão | Exemplo |
|---|---|---|
| ADR | `ADR-XXXX-titulo-kebab.md` (4 dígitos) | `ADR-0019-drift-migration-dataclass-pitfall.md` |
| Postmortem | `YYYY-MM-DD-titulo-kebab.md` | `2026-04-30-migration-27-28-falhou-silencioso.md` |
| Lição standalone | `YYYY-MM-DD-titulo-kebab.md` | `2026-05-15-flutter-run-em-device-real.md` |
| Sprint planejada | `Sprint_X.Y.md` | `Sprint_3.3.md` |
| Sprint fechada | `Sprint_X.Y_close.md` | `Sprint_2.3_close.md` |
| Templates | `.claude/templates/<tipo>.md` | `.claude/templates/adr.md` |

**Sempre kebab-case** em títulos de arquivo (lowercase + hifens). Sem acentos.

---

## Como referenciar entre docs (Obsidian)

Wikilinks: `[[arquivo]]` ou `[[arquivo|texto-de-display]]`

Exemplos:
- `[[ROADMAP]]` — link pra `ROADMAP.md`
- `[[ADR-0019-drift-migration-dataclass-pitfall|ADR-0019]]` — link com texto custom
- `[[Sprint_3.3]]` — sprint ativa

Wikilinks só funcionam dentro do vault. Em arquivos do projeto (este `CLAUDE.md`, etc), usar markdown link normal: `[texto](path)`.

---

## Workflow de commits — ⚠️ CRÍTICO

**Projeto e vault são repos SEPARADOS.** Nunca misturar arquivos dos dois num único commit.

### Sequência típica após mudança que requer documentação

1. **Commit no projeto** (App_Noheroes):
   ```bash
   git add <files de código>
   git commit -m "feat(sprint-X.Y-etapa-N): <título>"
   ```

2. **Commit no vault** (`.vault/`):
   ```bash
   cd .vault
   git add <files de docs>
   git commit -m "docs(vault): <título>"
   cd ..
   ```

3. **Reportar 2 SHAs ao CEO** ao final.

**Push é manual.** Nunca executar `git push` automaticamente em qualquer dos repos. Workflow é: *"Claude commita, CEO push."*

### Convenções de mensagem

| Prefixo | Quando usar | Repo |
|---|---|---|
| `feat(...)` | Feature nova de produto | Projeto |
| `fix(...)` | Bug fix em produto | Projeto |
| `chore(...)` | Ferramentaria de processo (workflow, CI, scripts) | Projeto |
| `refactor(...)` | Refactor sem mudança de comportamento | Projeto |
| `test(...)` | Adição/ajuste de testes isolados | Projeto |
| `docs(vault): ...` | Qualquer mudança em `.vault/` | Vault |

Subprefixos comuns no projeto: `sprint-X.Y-etapa-N`, `sprint-X.Y-hotfix`, `sprint-X.Y-close`.

---

## Estilo de escrita das docs

- **Tom direto.** Sem floreio, sem auto-elogio. Frases curtas.
- **Inclui logs reais** quando relevante (saída de comando, console, exception).
- **Documenta DECISÕES, não só fatos** — sempre explicar *por quê* algo foi feito assim.
- **Linka entre docs** — ADR linka pra postmortem que motivou; postmortem linka pra ADR que estabeleceu pattern preventivo.
- **Sem emojis em excesso.** O vault usa alguns (✅ ⏸️ 🏃) pra status de sprint — manter consistente. Em texto corrido, evitar.
- **Seções opcionais podem ser omitidas.** Templates marcam `(opcional)` onde aplicável.

---

## Regras de ouro

1. **Antes de criar ADR/postmortem novo, descobrir números atualizados dinamicamente** (`ls .vault/App/02_ADRs/ | grep -oE 'ADR-[0-9]{4}' | sort -V | tail -1`). Nunca hard-codar.
2. **Antes de mudar `ESTADO_ATUAL` ou `ROADMAP`, ler primeiro** — esses arquivos têm histórico, não apagar conteúdo sem motivo.
3. **Wikilinks devem apontar pra arquivo existente.** Verificar antes de incluir num doc novo.
4. **Templates são guia, não camisa-de-força** — campos opcionais podem ser omitidos quando não fazem sentido.
5. **Push é sempre manual.** Claude commita, reporta SHAs, CEO push.
6. **Quando em dúvida, perguntar** ao CEO antes de criar/modificar docs no vault. Vault é fonte canônica — erros têm custo alto.

---

## Links rápidos

- [`.claude/workflow.md`](.claude/workflow.md) — gatilhos detalhados + comandos de descoberta
- [`.claude/templates/`](.claude/templates/) — 5 templates pra docs novas
- `.vault/App/00_Index/ESTADO_ATUAL.md` — snapshot atual do projeto
- `.vault/App/00_Index/REGRAS_ENGENHARIA.md` — 10 leis do projeto
- `.vault/App/03_Sprints/ROADMAP.md` — plano macro
