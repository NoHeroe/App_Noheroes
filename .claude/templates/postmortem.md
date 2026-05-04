<!-- Template — arquivo YYYY-MM-DD-titulo-kebab.md -->
<!-- Criar em .vault/App/docs/postmortems/. -->

# Postmortem — {{TITULO}} ({{YYYY-MM-DD}})

**Severidade:** {{P0|P1|P2}} ({{DESCRICAO_BREVE}})
**Sprint de origem:** {{SPRINT_E_ETAPA_QUE_INTRODUZIU_O_BUG}}
**Sprint de detecção:** {{SPRINT_E_ETAPA_QUE_DETECTOU}}
**Tempo entre origem e detecção:** {{DURACAO}}
**Tempo entre detecção e fix:** {{DURACAO}}

---

## Sintoma observado

{{LOGS_OU_DESCRICAO}}

---

## Causa raiz

{{ANALISE_TECNICA_RESUMIDA}}

(Detalhe completo em [[ADR-XXXX-titulo|ADR-XXXX]] se aplicável.)

---

## Impacto runtime

{{DESCRICAO_DO_QUE_QUEBROU_OU_QUASE_QUEBROU}}

---

## Por que não foi detectado em testes

{{ANALISE_DO_GAP_DE_COBERTURA}}

---

## Fix aplicado

{{DESCRICAO_DA_CORRECAO}}

---

## Lições

### Process

- {{LICOES_DE_PROCESSO}}

### Technical

- {{LICOES_TECNICAS}}

---

## Prevenção futura

{{PATTERN_PREVENTIVO_OU_LINK_PRA_ADR}}

---

## Referências

- {{LINK_ADR_RELACIONADO}}
- {{LINK_COMMIT_FIX}}
- {{LINK_TESTE_QUE_COBRE_FIX}}
