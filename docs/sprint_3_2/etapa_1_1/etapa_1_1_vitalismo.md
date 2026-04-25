# Etapa 1.1 — Modalidade VITALISMO

**Cor canônica:** roxo (#534AB7 / c-purple 600)
**Conceito:** Forjar o todo. Disciplina que une os 3 pilares. Equilíbrio e presença.

---

## Diferença fundamental

**Vitalismo NÃO tem pool próprio de sub-tarefas.**

Quando o sistema gera 1 missão Vitalismo:
- Sorteia **1 sub-tarefa do Físico**
- Sorteia **1 sub-tarefa do Mental**
- Sorteia **1 sub-tarefa do Espiritual**
- Aplica escala por rank em cada uma
- Monta a missão com título e quote do pool **próprio do Vitalismo** (abaixo)

É a missão mais **completa** e mais **rara**. Treina os 3 pilares de uma vez.

---

## Restrições de seleção

Pra evitar combinações absurdas:

1. **Não sorteia sub-tarefas com escala 0 no rank do jogador**
2. **Sub-categorias balanceadas:** evita 3 sub-tarefas de "ritual+silêncio+meditação" (espiritual triplo) — sorteia 1 de cada pilar
3. **Sub-categoria preferida** dentro de cada pilar pesa o sorteio:
   - Físico: prefere treino (40%) > recuperação (30%) > nutrição (20%) > descanso (10%)
   - Mental: prefere foco (35%) > estudo (30%) > organização (20%) > criatividade (15%)
   - Espiritual: prefere propósito (35%) > silêncio (30%) > ritual (20%) > conexão (15%)
4. **Não duplica** se a sub-tarefa já apareceu nas outras 2 missões diárias do dia

---

## TÍTULOS NARRATIVOS — VITALISMO (12)

Vitalismo merece títulos próprios mais fortes (é a missão "completa"):

1. **Caminho do Vitalista** — quem une os 3, atravessa Caelum
2. **Forja dos Três** — corpo, mente, alma — todos no mesmo dia
3. **Vita Plena** — equilíbrio é a magia mais difícil
4. **Pacto do Equilíbrio** — Vitalistas raros sobrevivem porque escolhem todos
5. **A Disciplina dos Vitalistas** — não há atalho
6. **O Caminho que o Bom Dragão Aprova** — quem une, é visto
7. **Treino dos Convocados** — Guilda exige os 3 antes de subir rank
8. **A Forja Tripla** — corpo, mente e alma martelados juntos
9. **Sobreviver é Equilibrar** — Caelum não tolera assimetria
10. **O Pulso do Vitalismo** — três batidas, um corpo, um motor
11. **Antes da Caça, os Três** — Vitalistas não saem incompletos
12. **Lumen Sustentada** — luz só dura quando os 3 pilares ardem juntos

---

## POOL DE QUOTES — VITALISMO (20)

1. *"O Vitalista mais forte de Caelum não treina apenas. Pensa, medita, treina."*
2. *"Inerte tem 1. Mago tem 2. Vitalista tem os 3."*
3. *"O corpo cansa. A mente cede. A alma fraqueja. Vitalistas equilibram os três."*
4. *"Quem treina só corpo, vira músculo sem rumo."*
5. *"Quem só estuda, vira mago sem corpo. Voidrins comem magos sem corpo."*
6. *"Quem só medita, vira monge sem caminho. Caelum não tem espaço pra contemplação inerte."*
7. *"Os Três Pilares não são opção. São sobrevivência."*
8. *"O Bom Dragão observa o desequilíbrio. Ataca onde tu falhas."*
9. *"Vitalismo não é talento. É escolha diária pelos três."*
10. *"Sair pra caçar Voidrin sem os 3 prontos é morte certa."*
11. *"A Vita acende quando corpo, mente e alma estão alinhados. Só então."*
12. *"O Clã das Feras tinha corpo. O Clã do Sol tinha mente. Os dois caíram. Quem une os dois, talvez sobreviva."*
13. *"Equilibrar é mais difícil que excelência num pilar. Por isso vale mais."*
14. *"Aeon dogmatizou alma. Kaleidos dogmatizou mente. Caelum agora exige os três."*
15. *"Vitalistas verdadeiros são raros. Os falsos morrem cedo."*
16. *"Hoje, treina os três. Amanhã, os três te treinam de volta."*
17. *"O motor mágico do Vitalista só funciona com os 3 cilindros vivos."*
18. *"Quem prioriza um pilar, sacrifica os outros. Quem sacrifica, paga."*
19. *"O Vitalismo não é meta. É manutenção. Nunca para."*
20. *"Os Anciãos têm os três. Por isso voam. Tu também terás. Por isso treinas."*

---

## REGRAS DE GERAÇÃO COMPLETA

```
funcao gerar_missao_vitalismo(rank_jogador, sub_tarefas_ja_sorteadas_no_dia):
    sub_tarefa_fisico = sorteia_de(pool_fisico, evita=sub_tarefas_ja_sorteadas, peso_subcat={treino:40,recup:30,nutri:20,desc:10})
    sub_tarefa_mental = sorteia_de(pool_mental, evita=sub_tarefas_ja_sorteadas, peso_subcat={foco:35,estudo:30,org:20,cria:15})
    sub_tarefa_espiritual = sorteia_de(pool_espiritual, evita=sub_tarefas_ja_sorteadas, peso_subcat={prop:35,sil:30,rit:20,con:15})

    aplicar_escala(sub_tarefa_fisico, rank_jogador)
    aplicar_escala(sub_tarefa_mental, rank_jogador)
    aplicar_escala(sub_tarefa_espiritual, rank_jogador)

    titulo = sorteia_de(pool_titulos_vitalismo)
    quote = sorteia_de(pool_quotes_vitalismo)

    cor_card = roxo (cor canônica do Vitalismo)
    icone_pilar_de_cada_subtarefa = exibe icones individuais (vermelho/azul/dourado nas barras)

    return MissaoDiaria(titulo, quote, [sub_tarefa_fisico, sub_tarefa_mental, sub_tarefa_espiritual], cor=roxo)
```

**Visual sugerido:**
- Card do Vitalismo é roxo (cor canônica do pilar)
- Mas as 3 barras de progresso internas usam as cores dos pilares respectivos:
  - Sub-tarefa física → barra vermelha
  - Sub-tarefa mental → barra azul
  - Sub-tarefa espiritual → barra dourada
- Cada sub-tarefa pode ter ícone do pilar de origem (símbolo discreto)

Isso reforça visualmente que o Vitalismo "une" os 3 — o card é roxo (síntese) mas cada pedaço mostra sua origem.

---

## Distribuição geral nas 3 missões diárias

Sistema deve **garantir variedade** nas 3 missões do dia:

```
Cenário ideal (jogador com primaryFocus = físico):
- Missão 1: Físico (60% chance)
- Missão 2: outro pilar (Mental/Espiritual/Vitalismo)
- Missão 3: outro pilar diferente

Distribuição sugerida (peso por modalidade considerando primaryFocus):
- primaryFocus: 50% das missões diárias
- Outros 2 pilares: 20% cada
- Vitalismo: 10%
```

**Vitalismo é raro propositalmente.** Quando aparece, é especial. Tipo "boss day" do dia.

---

## CHECKLIST DE VALIDAÇÃO CEO

- [ ] Conceito do Vitalismo (sem pool próprio, pega 1 de cada pilar) — OK?
- [ ] Restrições de seleção (evita sub-cat duplicada, escala 0, repetição no dia) — OK?
- [ ] Pesos de sub-categoria por pilar (Físico prefere treino, Mental prefere foco, Espiritual prefere propósito) — OK?
- [ ] Títulos narrativos VITALISMO (12)
- [ ] Pool de quotes VITALISMO (20)
- [ ] Visual proposto (card roxo + 3 barras com cor do pilar de origem) — OK?
- [ ] Distribuição "Vitalismo raro 10%" — OK ou ajusta?

---

## RESUMO GLOBAL — ETAPA 1.1 COMPLETA

Quando os 4 arquivos estiverem aprovados (Físico + Mental + Espiritual + Vitalismo):

| Modalidade | Sub-tarefas | Títulos | Quotes |
|---|---|---|---|
| Físico | 60 | 32 | 20 |
| Mental | 60 | 32 | 20 |
| Espiritual | 60 | 32 | 20 |
| Vitalismo | 0 (usa outras) | 12 | 20 |
| **TOTAL** | **180 sub-tarefas** | **108 títulos** | **80 quotes** |

Isso vira o JSON canônico que alimenta a geração diária.

Próximo passo após aprovação: Claude Code transforma esses 4 .md em estrutura JSON real do app + implementa a mecânica de geração (Etapa 1.2).
