# Etapa 1.1 — Modalidade FÍSICO

**Cor canônica:** vermelho (#A32D2D / c-red 600)
**Conceito:** Forjar o corpo. Treino, recuperação, nutrição, descanso.

---

## Sub-categorias (4)

1. **Treino** — exercícios físicos ativos
2. **Recuperação** — descanso, alongamento, sono
3. **Nutrição** — hidratação, proteína, evitar processados
4. **Descanso** — pausas, off-screen, contemplação

---

## SUB-TAREFAS — TREINO (15)

| key | nome_visivel | unidade | escala E/D/C/B/A/S |
|-----|--------------|---------|---------------------|
| flexoes | Flexões | x | 10 / 25 / 50 / 90 / 150 / 300 |
| polichinelos | Polichinelos | x | 30 / 60 / 100 / 170 / 280 / 500 |
| abdominais | Abdominais | x | 15 / 35 / 60 / 100 / 160 / 280 |
| barra_fixa | Barra fixa | x | 3 / 8 / 18 / 35 / 60 / 100 |
| agachamentos | Agachamentos | x | 20 / 40 / 70 / 120 / 200 / 350 |
| prancha | Prancha (segurar) | s | 30 / 60 / 120 / 240 / 420 / 900 |
| burpees | Burpees | x | 5 / 12 / 25 / 45 / 75 / 130 |
| corrida_distancia | Corrida (distância) | km | 1 / 3 / 6 / 12 / 20 / 42 |
| caminhada | Caminhada | km | 2 / 4 / 7 / 12 / 20 / 35 |
| escada | Subir escadas (lances) | x | 5 / 15 / 30 / 60 / 100 / 200 |
| pular_corda | Pular corda | x | 50 / 150 / 350 / 700 / 1200 / 2500 |
| afundo | Afundo (cada perna) | x | 10 / 25 / 50 / 90 / 150 / 280 |
| levantamento_terra | Levantamento (livre) | x | 5 / 12 / 25 / 50 / 100 / 200 |
| ponte | Ponte (segurar) | s | 20 / 45 / 90 / 180 / 300 / 600 |
| treino_funcional | Treino funcional | min | 15 / 30 / 60 / 90 / 120 / 180 |

---

## SUB-TAREFAS — RECUPERAÇÃO (15)

| key | nome_visivel | unidade | escala E/D/C/B/A/S |
|-----|--------------|---------|---------------------|
| sono_horas | Dormir | h | 7 / 7 / 8 / 8 / 8 / 8 |
| alongamento | Alongamento | min | 5 / 10 / 20 / 30 / 45 / 60 |
| automassagem | Automassagem | min | 5 / 10 / 15 / 25 / 40 / 60 |
| banho_frio | Banho frio | min | 1 / 2 / 4 / 7 / 10 / 15 |
| respiracao_box | Respiração box (4-4-4-4) | min | 3 / 5 / 10 / 15 / 25 / 40 |
| caminhada_leve | Caminhada leve recuperativa | min | 10 / 15 / 25 / 35 / 50 / 70 |
| postura_correcao | Correção postural consciente | min | 5 / 10 / 15 / 25 / 40 / 60 |
| descanso_total | Descanso total (sem tela) | min | 15 / 30 / 60 / 90 / 120 / 180 |
| sauna | Sauna ou banho quente | min | 5 / 10 / 15 / 20 / 30 / 45 |
| mobilidade_articular | Mobilidade articular | min | 5 / 10 / 15 / 25 / 40 / 60 |
| siesta | Soneca diurna (até 30min) | min | 10 / 15 / 20 / 25 / 30 / 30 |
| sem_estimulante_tarde | Sem cafeína após 14h | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| dormir_horario | Deitar antes de meia-noite | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| respiracao_diafragma | Respiração diafragmática | min | 3 / 5 / 10 / 15 / 25 / 40 |
| relaxamento_progressivo | Relaxamento muscular progressivo | min | 5 / 10 / 15 / 25 / 35 / 50 |

**Nota:** sub-tarefas tipo `bool` valem 1 quando feito (X/1). Soneca e sono têm cap (não fazem sentido escalar pra rank S além do biológico).

---

## SUB-TAREFAS — NUTRIÇÃO (15)

| key | nome_visivel | unidade | escala E/D/C/B/A/S |
|-----|--------------|---------|---------------------|
| agua_diaria | Beber água | ml | IMC*35 (todos ranks) |
| proteina_diaria | Consumir proteína | g | IMC*1.6 (todos ranks) |
| sem_processados | Evitar gordura processada hoje | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| sem_acucar_adicionado | Evitar açúcar adicionado | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| frutas_dia | Comer frutas | porção | 1 / 2 / 3 / 4 / 5 / 6 |
| vegetais_dia | Comer vegetais | porção | 2 / 3 / 4 / 5 / 6 / 8 |
| refeicao_caseira | Refeição feita em casa | x | 1 / 2 / 2 / 3 / 3 / 3 |
| sem_refrigerante | Sem refrigerante hoje | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| sem_alcool | Sem álcool hoje | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| jejum_intermitente | Jejum intermitente | h | 12 / 14 / 16 / 18 / 20 / 24 |
| mastigar_devagar | Refeição mastigada conscientemente | x | 1 / 2 / 2 / 3 / 3 / 3 |
| chá_ou_infusao | Chá ou infusão sem açúcar | xícara | 1 / 2 / 3 / 4 / 5 / 6 |
| evitar_industrializado | Evitar industrializado hoje | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| omega_3 | Consumir ômega-3 (peixe/oleaginosa) | porção | 1 / 1 / 2 / 2 / 3 / 4 |
| comer_devagar | Refeição sem celular/tela | x | 1 / 1 / 2 / 2 / 3 / 3 |

**Nota:** água e proteína usam IMC do `BodyMetricsService` (Etapa 1.0). Se jogador não preencheu, usa default (2000ml / 80g).

---

## SUB-TAREFAS — DESCANSO (15)

| key | nome_visivel | unidade | escala E/D/C/B/A/S |
|-----|--------------|---------|---------------------|
| sem_celular | Sem celular | min | 30 / 60 / 120 / 180 / 240 / 360 |
| sem_redes_sociais | Sem redes sociais | h | 1 / 2 / 4 / 6 / 8 / 12 |
| pausa_visual | Olhar pra longe (regra 20-20-20) | x | 3 / 5 / 8 / 12 / 16 / 24 |
| caminhar_natureza | Tempo na natureza | min | 15 / 30 / 60 / 90 / 120 / 180 |
| sentar_silencio | Sentar em silêncio | min | 5 / 10 / 20 / 30 / 45 / 60 |
| deitar_olhos_fechados | Deitar de olhos fechados | min | 5 / 10 / 15 / 20 / 30 / 45 |
| pausa_trabalho | Pausa de 5min entre tarefas | x | 3 / 5 / 8 / 12 / 16 / 24 |
| sem_noticias | Sem notícias hoje | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| ficar_sem_fazer_nada | Ficar sem fazer nada | min | 10 / 20 / 30 / 45 / 60 / 90 |
| banho_consciente | Banho lento e consciente | min | 5 / 8 / 12 / 15 / 20 / 30 |
| comer_silencio | Refeição em silêncio | x | 1 / 1 / 2 / 2 / 3 / 3 |
| dormir_cedo | Cama antes das 22h | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| acordar_sem_alarme | Acordar sem alarme | bool | 1 / 1 / 1 / 1 / 1 / 1 |
| respirar_ar_livre | Respirar ar livre | min | 10 / 15 / 25 / 35 / 50 / 75 |
| folga_total | Folga total (dia inteiro descanso) | bool | 0 / 0 / 1 / 1 / 1 / 1 |

---

## TÍTULOS NARRATIVOS — TREINO (8)

1. **Forja do Caçador** — preparo pra caçar criaturas das ruínas
2. **Disciplina das Lâminas Caídas** — referência ao Clã da Lua memorial
3. **O Peso da Sobrevivência** — Caelum não perdoa fracos
4. **Treino sob a Cúpula** — última cidade de pé
5. **Eco da Arena Esquecida** — onde Vitalistas treinavam
6. **Caminho do Vitalista** — quem cruza o limite vira motor mágico
7. **Respiração antes da Caça** — preparo silencioso, técnica do Clã da Lua
8. **Pés na Cinza** — caminhada sobre o que sobrou

## TÍTULOS NARRATIVOS — RECUPERAÇÃO (8)

1. **Descanso do Aventureiro** — Guilda exige corpo inteiro
2. **Silêncio entre Combates** — pausa antes da próxima caça
3. **Sob a Cúpula de Lunaris** — único lugar onde se dorme em paz
4. **A Pausa que o Vazio Permite** — não há descanso fora da cidade
5. **Recuperando o que Caelum Tomou** — corpo cobra o preço
6. **Cura sem Lumen** — quando não há mago disponível
7. **Brasas Antes do Sono** — ritual de fim de dia
8. **Manhã sob as Cinzas** — despertar consciente

## TÍTULOS NARRATIVOS — NUTRIÇÃO (8)

1. **Provisões do Aventureiro** — comida de quem sobrevive
2. **Reservas pra Próxima Jornada** — Guilda alimenta os ranks
3. **Água da Cúpula** — preciosa, dosada, vital
4. **A Mesa do Sobrevivente** — comer é privilégio em Caelum
5. **Forja Interna** — alimentar o motor do Vitalista
6. **Pão sem Veneno** — evitar o que Aeon deixou apodrecer
7. **Disciplina de Mesa** — comer como quem treina
8. **Antes da Caça** — alimentação que sustenta o ritual

## TÍTULOS NARRATIVOS — DESCANSO (8)

1. **Olhos Longe da Cúpula** — repousar é resistir
2. **A Vigília Branda** — pausa que não deixa o Vazio entrar
3. **Tempo Fora do Tempo** — relógios rúnicos não medem isso
4. **Folga sob as Cinzas** — descanso é raro, é sagrado
5. **Sem Notícia, sem Voidrins** — desligar pra existir
6. **Caminho Lento** — quem corre não chega vivo
7. **Respiro entre Eras** — pausa antes do próximo ato
8. **A Cúpula Vê Tudo, Mas Permite o Sono** — descanso vigiado

---

## POOL DE QUOTES — FÍSICO (20)

1. *"O corpo cobra o preço de quem ousa atravessar Caelum."*
2. *"Vitalistas nascem. Sobreviventes treinam."*
3. *"O Voidrin não sente cansaço. Tu também não pode."*
4. *"Caelum não premia esforço. Castiga negligência."*
5. *"A Floresta Negra come quem chega lento."*
6. *"O dragão não pede licença. Estar pronto é dever."*
7. *"Cada dia sem treino é um passo do Vazio."*
8. *"O peso que carregas hoje é a vida que defenderás amanhã."*
9. *"Aeon caiu. Kaleidos caiu. Quem treina ainda respira."*
10. *"O Clã das Feras se foi. O instinto, ninguém matou."*
11. *"Forja teu corpo como quem forja Umbra: com peso, não com brilho."*
12. *"O Bom Dragão observa. Mostra que vales o que vê."*
13. *"Treine como se a próxima respiração dependesse disso. Porque depende."*
14. *"Quem para de treinar, vira história. E histórias morrem."*
15. *"Caelum tem dois tipos: os que sobrevivem e os que viram cinza."*
16. *"O corpo é a primeira muralha. Não deixe ela cair."*
17. *"Disciplina é o que separa Inerte de Vitalista."*
18. *"O Oni Vagante não treinou. Ele lutou. Mas tu não és o Oni."*
19. *"Lumen cura. Mas só quem sobrevive até a cura."*
20. *"Cada gota de suor é uma promessa contra o Vazio."*

---

## REGRAS DE COMBINAÇÃO — geração dinâmica

Quando o sistema gera 1 missão Físico:

1. Sorteia **sub-categoria** do Físico (treino / recuperação / nutrição / descanso)
   - Pesos sugeridos: treino 35% / recuperação 25% / nutrição 25% / descanso 15%
2. Sorteia **3 sub-tarefas dentro da sub-categoria** (ou 2 da mesma + 1 de sub-categoria adjacente, se quiser variação)
3. Aplica escala por rank do jogador
4. Sorteia **1 título** do pool da sub-categoria
5. Sorteia **1 quote** do pool do pilar Físico

Cada missão diária do dia tem combinação **única** (não repete sub-tarefas dentro do mesmo dia).

Exemplo de geração:
- Sub-categoria sorteada: **Treino**
- Sub-tarefas sorteadas: flexões + polichinelos + barra_fixa
- Rank do jogador: D
- Resultado: **"Forja do Caçador"** com Flexões 25 + Polichinelos 60 + Barra fixa 8
- Quote: *"O corpo cobra o preço de quem ousa atravessar Caelum."*

---

## CHECKLIST DE VALIDAÇÃO CEO

Pra cada bloco abaixo, marca **OK** ou **AJUSTAR (motivo)**:

- [ ] Sub-categorias 4 (treino/recuperação/nutrição/descanso) — alguma faltando? alguma sobrando?
- [ ] Sub-tarefas TREINO (15) — alguma exótica/ridícula? alguma essencial faltando?
- [ ] Sub-tarefas RECUPERAÇÃO (15)
- [ ] Sub-tarefas NUTRIÇÃO (15)
- [ ] Sub-tarefas DESCANSO (15)
- [ ] Escalas por rank — curva soulslike OK? algum valor absurdo?
- [ ] Títulos narrativos TREINO (8) — tom OK?
- [ ] Títulos narrativos RECUPERAÇÃO (8)
- [ ] Títulos narrativos NUTRIÇÃO (8)
- [ ] Títulos narrativos DESCANSO (8)
- [ ] Pool de quotes (20) — todas dentro do tom soulslike sem clichê?
- [ ] Pesos de sub-categoria (treino 35% / recup 25% / nutri 25% / desc 15%) — ajusta?
