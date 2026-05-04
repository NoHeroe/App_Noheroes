# Workflow de Documentação — NoHeroes

> Este arquivo é lido pelo Claude Code em cada sessão. Define **quando** e **como** criar/atualizar docs no vault Obsidian (`.vault/`).
>
> **Manual completo:** ver [`CLAUDE.md`](../CLAUDE.md) na raiz do projeto pra contexto geral, convenções de naming, estrutura de repos e regras de commit.

---

## Tabela de gatilhos

| Evento | Ação no vault | Template | Mensagem do commit (vault) |
|---|---|---|---|
| **Etapa fechada** (commit `feat`/`fix` em sprint ativa) | Atualiza `.vault/App/03_Sprints/Fase_X/Sprint_Y.Z.md` adicionando seção da etapa + appende `journal.txt` | `etapa.md` | `docs(vault): registra Etapa X.Y` |
| **Sprint fechada** (tag publicada) | Cria `.vault/App/03_Sprints/Sprint_X.Y_close.md` + atualiza `ESTADO_ATUAL` + `ROADMAP` + `journal` | `sprint-close.md` | `docs(vault): fecha Sprint X.Y (vX.Y.Z)` |
| **Decisão arquitetural significativa** | Cria `.vault/App/02_ADRs/ADR-XXXX-titulo-kebab.md` (consultar pasta pro próximo número) + atualiza `ESTADO_ATUAL` com link | `adr.md` | `docs(vault): ADR-XXXX <título>` |
| **Bug em produção (P0/P1)** | Cria `.vault/App/docs/postmortems/YYYY-MM-DD-titulo-kebab.md` + appende `journal` + (se houver pattern preventivo) cria ADR | `postmortem.md` | `docs(vault): postmortem <título>` |
| **Lição técnica standalone** | Cria `.vault/App/docs/lessons/YYYY-MM-DD-titulo-kebab.md` (criar pasta se não existe) | `licao.md` | `docs(vault): lição <título>` |

---

## Quando NÃO documentar automaticamente

- Refactors triviais (cosmetic, naming, prefer_const)
- Hotfixes pequenos sem impacto arquitetural (ex: typo num label)
- Mudanças de UI sem mudança de comportamento (ex: cor de botão)
- Bumps de dependência (`pubspec.yaml`) sem refactor

Pra esses casos, só commit normal no projeto. **Não polui o vault.**

---

## Workflow do commit duplo

Após mudança que requer documentação:

### 1. Commit no projeto

```bash
git add <files do código>
git commit -m "feat(sprint-X.Y-etapa-N): <título>"
```

(Use `fix`, `chore`, `refactor`, `test` conforme apropriado — ver `CLAUDE.md` pra convenções completas.)

### 2. Commit no vault

```bash
cd .vault
git add <files de docs>
git commit -m "docs(vault): <título>"
cd ..
```

### 3. Reportar 2 SHAs ao CEO

Sempre listar os 2 SHAs no relatório final pra o CEO ter rastreabilidade.

**Push é manual.** Nunca executar `git push` automaticamente.

---

## Como descobrir estado atualizado

Antes de criar ADR/postmortem/sprint close, descobrir números **dinamicamente** — nunca hard-codar.

### Próximo ADR

Listar pasta e pegar o último número:

```bash
ls .vault/App/02_ADRs/ | grep -oE 'ADR-[0-9]{4}' | sort -V | tail -1
```

Próximo = último + 1, formato 4 dígitos (`0019` → `0020`).

### Sprint ativa

Ler `.vault/App/00_Index/ESTADO_ATUAL.md` seção **"Sprint ativo"**.

### Última versão publicada

Ler `.vault/App/00_Index/ESTADO_ATUAL.md` seção **"Versão em produção"**.

### Próximo número de Sprint close

Listar `.vault/App/03_Sprints/` e ver qual sprint está ativa em `ESTADO_ATUAL`. O `_close` herda o número da sprint ativa.

### Sprints já fechadas

```bash
ls .vault/App/03_Sprints/ | grep '_close.md$'
```

**NUNCA hard-codar números.** Sempre descobrir antes de criar arquivo novo.

---

## Verificação antes de commitar no vault

Sempre antes de `git add` no vault, conferir:

- [ ] Nome do arquivo segue convenção (kebab-case, ADR-XXXX numerado, data ISO em postmortem)
- [ ] Arquivo usa template apropriado de `.claude/templates/`
- [ ] Wikilinks `[[arquivo]]` válidos (arquivo referenciado existe no vault)
- [ ] `ESTADO_ATUAL.md` atualizado se houve mudança de versão/schema/sprint
- [ ] `ROADMAP.md` atualizado se sprint mudou de status
- [ ] `journal.txt` recebeu entry novo

---

## Templates disponíveis

| Template | Para que serve |
|---|---|
| `.claude/templates/etapa.md` | Seção dentro de `Sprint_X.Y.md` quando etapa fecha |
| `.claude/templates/sprint-close.md` | Arquivo `Sprint_X.Y_close.md` |
| `.claude/templates/adr.md` | Arquivo `ADR-XXXX-titulo-kebab.md` |
| `.claude/templates/postmortem.md` | Arquivo `YYYY-MM-DD-titulo-kebab.md` em `docs/postmortems/` |
| `.claude/templates/licao.md` | Arquivo `YYYY-MM-DD-titulo-kebab.md` em `docs/lessons/` |

Templates usam placeholders `{{NOME}}` pra Claude preencher. Campos marcados `(opcional)` podem ser omitidos quando não fazem sentido.

---

## Regras de ouro (resumo)

1. Descobrir números **dinamicamente** antes de criar arquivos numerados.
2. Wikilinks devem apontar pra arquivo **existente**.
3. Templates são **guia, não camisa-de-força**.
4. Push é **sempre manual**. Claude commita, CEO push.
5. Em dúvida, **perguntar** ao CEO antes de modificar docs canônicas (ESTADO_ATUAL, ROADMAP, MOC).

Ver [`CLAUDE.md`](../CLAUDE.md) seção "Regras de ouro" pro contexto completo.
