-- ============================================================================
-- Card Game — catalogo MINIMO no servidor (id/kind/raridade) p/ sorteio de
-- pacote server-authoritative. Leitura publica. Dados completos seguem no
-- client (assets JSON); aqui so o que o servidor precisa pra abrir pacotes.
-- ============================================================================
create table public.cards_catalog (
  id     text primary key,
  kind   text not null,   -- 'creature' | 'relic'
  rarity text not null    -- comum|rara|epica|lendaria|elite
);
alter table public.cards_catalog enable row level security;
create policy "cards_catalog_read" on public.cards_catalog for select using (true);

insert into public.cards_catalog (id, kind, rarity)
select id, 'creature', rarity from json_to_recordset('[
  {
    "id": "aglomerado_de_celulas_estagio_1",
    "nome": "Aglomerado de Células — Estágio 1",
    "concepts": [
      "chrysalis"
    ],
    "cost": 1,
    "atk": 1,
    "hp": 1,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "aglomerado_de_celulas_estagio_2",
    "nome": "Aglomerado de Células — Estágio 2",
    "concepts": [
      "chrysalis"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "aglomerado_de_celulas_estagio_3",
    "nome": "Aglomerado de Células — Estágio 3",
    "concepts": [
      "chrysalis"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 3,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "azuos",
    "nome": "Azuos Luar",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "cost": 7,
    "atk": 6,
    "hp": 7,
    "damage_type": "vitalismo",
    "rarity": "elite",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "bandidos",
    "nome": "Bandidos",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "cacador_uivante",
    "nome": "Caçador Uivante",
    "concepts": [
      "vitalismo"
    ],
    "cost": 6,
    "atk": 6,
    "hp": 6,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "cacadores_de_recompensas",
    "nome": "Caçadores de Recompensas",
    "concepts": [
      "corrompido"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 3,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "caes_esfumacados",
    "nome": "Cães Esfumaçados",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": [
      "Investida"
    ]
  },
  {
    "id": "cavaleiros_petrificados",
    "nome": "Cavaleiros Petrificados",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 2,
    "hp": 6,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": [
      "Provocar"
    ]
  },
  {
    "id": "cerverus",
    "nome": "Cerverus",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 7,
    "atk": 6,
    "hp": 6,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "cervo_chifre_de_cristal",
    "nome": "Cervo Chifre de Cristal",
    "concepts": [
      "celestial"
    ],
    "cost": 3,
    "atk": 1,
    "hp": 4,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Inspirar"
    ]
  },
  {
    "id": "chefao_das_aranhas_mutantes",
    "nome": "Chefão das Aranhas Mutantes",
    "concepts": [
      "corrompido"
    ],
    "cost": 5,
    "atk": 5,
    "hp": 6,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "couracados",
    "nome": "Couraçados",
    "concepts": [
      "chrysalis"
    ],
    "cost": 5,
    "atk": 4,
    "hp": 6,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "crawlers",
    "nome": "Crawlers",
    "concepts": [
      "chrysalis"
    ],
    "cost": 1,
    "atk": 2,
    "hp": 1,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "demonios_comuns",
    "nome": "Demônios Comuns",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "desastres",
    "nome": "Desastres",
    "concepts": [
      "chrysalis"
    ],
    "cost": 7,
    "atk": 6,
    "hp": 6,
    "damage_type": "corpo_a_corpo",
    "rarity": "lendaria",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "desolados",
    "nome": "Desolados",
    "concepts": [
      "chrysalis"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 3,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "devorador_de_almas",
    "nome": "Devorador de Almas",
    "concepts": [
      "corrompido"
    ],
    "cost": 5,
    "atk": 5,
    "hp": 5,
    "damage_type": "vitalismo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Roubo de PV"
    ]
  },
  {
    "id": "devoradores_cegos",
    "nome": "Devoradores Cegos",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "diabrete_curupira",
    "nome": "Diabrete Curupira",
    "concepts": [
      "vitalismo"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 2,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Provocar"
    ]
  },
  {
    "id": "diabrete_incandescente",
    "nome": "Diabrete Incandescente",
    "concepts": [
      "vitalismo"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 2,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Pisotear"
    ]
  },
  {
    "id": "diabrete_saci",
    "nome": "Diabrete Saci",
    "concepts": [
      "vitalismo"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 2,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Voo"
    ]
  },
  {
    "id": "dragao_anciao_da_montanha",
    "nome": "Dragão Ancião da Montanha",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 6,
    "atk": 7,
    "hp": 8,
    "damage_type": "corpo_a_corpo",
    "rarity": "lendaria",
    "relic_slots": 1,
    "abilities": [
      "Escudo"
    ]
  },
  {
    "id": "dragao_de_fogo",
    "nome": "Dragão de Fogo",
    "concepts": [
      "magico"
    ],
    "cost": 5,
    "atk": 6,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Pisotear"
    ]
  },
  {
    "id": "dragoes_corrompidos",
    "nome": "Dragões Corrompidos",
    "concepts": [
      "corrompido"
    ],
    "cost": 6,
    "atk": 6,
    "hp": 6,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "drakonianos",
    "nome": "Drakonianos",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 4,
    "atk": 4,
    "hp": 4,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "driades",
    "nome": "Dríades",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 2,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Provocar"
    ]
  },
  {
    "id": "elfos",
    "nome": "Elfos",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 3,
    "damage_type": "a_distancia",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Alcance"
    ]
  },
  {
    "id": "elfos_cacadores",
    "nome": "Elfos Caçadores",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 4,
    "hp": 2,
    "damage_type": "a_distancia",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "gnoll_do_vazio",
    "nome": "Gnoll do Vazio",
    "concepts": [
      "vitalismo"
    ],
    "cost": 4,
    "atk": 4,
    "hp": 4,
    "damage_type": "vitalismo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "goblin_arqueiro",
    "nome": "Goblin Arqueiro",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 1,
    "damage_type": "a_distancia",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "goblin_guerreiro",
    "nome": "Goblin Guerreiro",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "goblin_lanceiro",
    "nome": "Goblin Lanceiro",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": [
      "Alcance"
    ]
  },
  {
    "id": "goblin_xama",
    "nome": "Goblin Xamã",
    "concepts": [
      "corrompido",
      "magico"
    ],
    "cost": 3,
    "atk": 1,
    "hp": 3,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Inspirar"
    ]
  },
  {
    "id": "grifo_real",
    "nome": "Grifo Real",
    "concepts": [
      "celestial"
    ],
    "cost": 4,
    "atk": 5,
    "hp": 4,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Voo"
    ]
  },
  {
    "id": "harpias",
    "nome": "Harpias",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 2,
    "damage_type": "a_distancia",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Voo"
    ]
  },
  {
    "id": "hiena_de_cobre",
    "nome": "Hiena de Cobre",
    "concepts": [
      "magico"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 3,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": [
      "Escudo"
    ]
  },
  {
    "id": "hipogrifo",
    "nome": "Hipogrifo",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 3,
    "hp": 3,
    "damage_type": "a_distancia",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Voo"
    ]
  },
  {
    "id": "kagemitsu",
    "nome": "Kagemitsu",
    "concepts": [
      "corrompido",
      "magico"
    ],
    "cost": 6,
    "atk": 4,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "koda_feet",
    "nome": "Koda Feet",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "cost": 6,
    "atk": 5,
    "hp": 5,
    "damage_type": "corpo_a_corpo",
    "rarity": "elite",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "kyanne_laville",
    "nome": "Kyanne Laville",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 6,
    "atk": 4,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "marionetes_do_culto",
    "nome": "Marionetes do Culto",
    "concepts": [
      "corrompido"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 3,
    "damage_type": "magico",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "milena",
    "nome": "Milena (Vermillion)",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "cost": 6,
    "atk": 4,
    "hp": 4,
    "damage_type": "vitalismo",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "mimico",
    "nome": "Mímico",
    "concepts": [
      "corrompido",
      "magico"
    ],
    "cost": 3,
    "atk": 4,
    "hp": 3,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "mimico_de_adaga",
    "nome": "Mímico de Adaga",
    "concepts": [
      "magico"
    ],
    "cost": 2,
    "atk": 4,
    "hp": 1,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Ataque Duplo"
    ]
  },
  {
    "id": "mimico_de_corrente",
    "nome": "Mímico de Corrente",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 2,
    "hp": 3,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Provocar"
    ]
  },
  {
    "id": "mimico_de_escudo",
    "nome": "Mímico de Escudo",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 1,
    "hp": 5,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Provocar"
    ]
  },
  {
    "id": "mimico_de_espada",
    "nome": "Mímico de Espada",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 5,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "mimico_de_moedas",
    "nome": "Mímico de Moedas",
    "concepts": [
      "magico"
    ],
    "cost": 2,
    "atk": 1,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Cristal de Drenagem"
    ]
  },
  {
    "id": "mimico_de_pocao",
    "nome": "Mímico de Poção",
    "concepts": [
      "magico"
    ],
    "cost": 2,
    "atk": 1,
    "hp": 2,
    "damage_type": "cura",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "morto_vivo",
    "nome": "Morto-Vivo",
    "concepts": [
      "corrompido"
    ],
    "cost": 1,
    "atk": 2,
    "hp": 1,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "myroth",
    "nome": "Myroth",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 6,
    "atk": 7,
    "hp": 7,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "n6_desconhecido",
    "nome": "N6 — Desconhecido",
    "concepts": [
      "chrysalis"
    ],
    "cost": 8,
    "atk": 7,
    "hp": 7,
    "damage_type": "corpo_a_corpo",
    "rarity": "lendaria",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "nythor",
    "nome": "Nythor",
    "concepts": [
      "corrompido"
    ],
    "cost": 6,
    "atk": 6,
    "hp": 7,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "o_devorador",
    "nome": "O Devorador",
    "concepts": [
      "vitalismo"
    ],
    "cost": 5,
    "atk": 4,
    "hp": 6,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "oni_vagante",
    "nome": "Oni Vagante",
    "concepts": [
      "corrompido",
      "magico"
    ],
    "cost": 7,
    "atk": 7,
    "hp": 5,
    "damage_type": "corpo_a_corpo",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "parasitas_de_planta_e_fungo",
    "nome": "Parasitas de Planta e Fungo",
    "concepts": [
      "chrysalis"
    ],
    "cost": 3,
    "atk": 2,
    "hp": 4,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "patas_sombrias",
    "nome": "Patas Sombrias",
    "concepts": [
      "magico"
    ],
    "cost": 2,
    "atk": 4,
    "hp": 1,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Voo"
    ]
  },
  {
    "id": "predadores",
    "nome": "Predadores",
    "concepts": [
      "chrysalis"
    ],
    "cost": 5,
    "atk": 5,
    "hp": 4,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "presas_douradas",
    "nome": "Presas Douradas",
    "concepts": [
      "magico"
    ],
    "cost": 4,
    "atk": 4,
    "hp": 5,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Escudo"
    ]
  },
  {
    "id": "pulsantes",
    "nome": "Pulsantes",
    "concepts": [
      "chrysalis"
    ],
    "cost": 2,
    "atk": 3,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "ratos_profanos",
    "nome": "Ratos Profanos",
    "concepts": [
      "corrompido"
    ],
    "cost": 1,
    "atk": 2,
    "hp": 1,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "sado",
    "nome": "Sado Luar",
    "concepts": [
      "magico",
      "vitalismo"
    ],
    "cost": 5,
    "atk": 3,
    "hp": 4,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "sakura_anaoji",
    "nome": "Sakura Anaoji",
    "concepts": [
      "magico"
    ],
    "cost": 5,
    "atk": 5,
    "hp": 3,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "sentinela_da_areia_eterna",
    "nome": "Sentinela da Areia Eterna",
    "concepts": [
      "corrompido"
    ],
    "cost": 5,
    "atk": 4,
    "hp": 7,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Provocar",
      "Escudo"
    ]
  },
  {
    "id": "sereias",
    "nome": "Sereias",
    "concepts": [
      "celestial"
    ],
    "cost": 4,
    "atk": 3,
    "hp": 4,
    "damage_type": "magico",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": [
      "Silêncio"
    ]
  },
  {
    "id": "skinwalkers",
    "nome": "Skinwalkers",
    "concepts": [
      "vitalismo"
    ],
    "cost": 4,
    "atk": 3,
    "hp": 4,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "sombras_mendigas",
    "nome": "Sombras Mendigas",
    "concepts": [
      "vitalismo"
    ],
    "cost": 2,
    "atk": 2,
    "hp": 2,
    "damage_type": "magico",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": [
      "Furtividade"
    ]
  },
  {
    "id": "tecelao_sombrio",
    "nome": "Tecelão Sombrio",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "cost": 5,
    "atk": 4,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "tigre_dente_de_sabre",
    "nome": "Tigre Dente de Sabre",
    "concepts": [
      "magico"
    ],
    "cost": 3,
    "atk": 5,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "rara",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "tormento_sangrento",
    "nome": "Tormento Sangrento",
    "concepts": [
      "vitalismo"
    ],
    "cost": 6,
    "atk": 6,
    "hp": 5,
    "damage_type": "vitalismo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Ataque Duplo"
    ]
  },
  {
    "id": "trovoador",
    "nome": "Trovoador",
    "concepts": [
      "magico"
    ],
    "cost": 4,
    "atk": 3,
    "hp": 6,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": [
      "Escudo"
    ]
  },
  {
    "id": "tyrian",
    "nome": "Tyrian",
    "concepts": [
      "vitalismo"
    ],
    "cost": 8,
    "atk": 6,
    "hp": 6,
    "damage_type": "vitalismo",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "vagantes",
    "nome": "Vagantes",
    "concepts": [
      "chrysalis"
    ],
    "cost": 5,
    "atk": 5,
    "hp": 5,
    "damage_type": "corpo_a_corpo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "varaak",
    "nome": "Varaak",
    "concepts": [
      "celestial",
      "magico"
    ],
    "cost": 5,
    "atk": 5,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "vetrak_mancerion",
    "nome": "Vetrak Mancerion",
    "concepts": [
      "celestial",
      "vitalismo"
    ],
    "cost": 6,
    "atk": 3,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "voidrins",
    "nome": "Voidrins",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "cost": 4,
    "atk": 4,
    "hp": 4,
    "damage_type": "vitalismo",
    "rarity": "epica",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "ydros",
    "nome": "Ydros",
    "concepts": [
      "chrysalis"
    ],
    "cost": 4,
    "atk": 1,
    "hp": 6,
    "damage_type": "magico",
    "rarity": "lendaria",
    "relic_slots": 1,
    "abilities": []
  },
  {
    "id": "yuna_lannatary",
    "nome": "Yuna Lannatary",
    "concepts": [
      "neutro"
    ],
    "cost": 6,
    "atk": 4,
    "hp": 5,
    "damage_type": "magico",
    "rarity": "elite",
    "relic_slots": 2,
    "abilities": []
  },
  {
    "id": "zumbi_comum",
    "nome": "Zumbi Comum",
    "concepts": [
      "chrysalis"
    ],
    "cost": 1,
    "atk": 1,
    "hp": 2,
    "damage_type": "corpo_a_corpo",
    "rarity": "comum",
    "relic_slots": 1,
    "abilities": []
  }
]') as x(id text, rarity text)
union all
select id, 'relic', rarity from json_to_recordset('[
  {
    "id": "abraco_gelado_de_myroth",
    "nome": "Abraço Gelado de Myroth",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Dano mágico de gelo + chance de Silêncio (a refinar)",
      "abilities": [
        "Silencio"
      ]
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "adaga_enferrujada",
    "nome": "Adaga Enferrujada",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "adaga_enferrujada_celestial",
    "nome": "Adaga Enferrujada (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "adaga_enferrujada_chrysalis",
    "nome": "Adaga Enferrujada (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "adaga_enferrujada_corrompido",
    "nome": "Adaga Enferrujada (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "adaga_enferrujada_magico",
    "nome": "Adaga Enferrujada (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "adaga_enferrujada_vitalismo",
    "nome": "Adaga Enferrujada (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "alianca_do_salgueiro_sagrado",
    "nome": "Aliança do Salgueiro Sagrado",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Regen de PV (Cura) + Escudo Sagrado de última hora (a refinar)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "aljava_de_thorn",
    "nome": "Aljava de Thorn",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo (a refinar)",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "aljava_reforcada",
    "nome": "Aljava Reforçada",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "aljava_reforcada_celestial",
    "nome": "Aljava Reforçada (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "aljava_reforcada_chrysalis",
    "nome": "Aljava Reforçada (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "aljava_reforcada_corrompido",
    "nome": "Aljava Reforçada (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "aljava_reforcada_magico",
    "nome": "Aljava Reforçada (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "aljava_reforcada_vitalismo",
    "nome": "Aljava Reforçada (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "anel_da_gloria_do_rei_caido",
    "nome": "Anel da Glória do Rei Caído",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Armazenamento dimensional — utilitário (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "anel_de_ouro_antigo",
    "nome": "Anel de Ouro Antigo",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+sorte/ouro/XP — meta-economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "anel_de_ouro_antigo_celestial",
    "nome": "Anel de Ouro Antigo (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+sorte/ouro/XP — meta-economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "anel_de_ouro_antigo_chrysalis",
    "nome": "Anel de Ouro Antigo (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+sorte/ouro/XP — meta-economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "anel_de_ouro_antigo_corrompido",
    "nome": "Anel de Ouro Antigo (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+sorte/ouro/XP — meta-economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "anel_de_ouro_antigo_magico",
    "nome": "Anel de Ouro Antigo (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+sorte/ouro/XP — meta-economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "anel_de_ouro_antigo_vitalismo",
    "nome": "Anel de Ouro Antigo (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+sorte/ouro/XP — meta-economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "antidoto",
    "nome": "Antídoto",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Remove Silêncio/efeito negativo de 1 criatura (a refinar)",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "arca",
    "nome": "ARCA",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "IA tática — efeito lendário (a refinar)",
      "abilities": []
    },
    "rarity": "lendaria",
    "is_flash": false
  },
  {
    "id": "armadilha_de_corda",
    "nome": "Armadilha de Corda",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Imobiliza (Silêncio) 1 criatura (a refinar)",
      "abilities": [
        "Silencio"
      ]
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "bazuka",
    "nome": "Bazuca",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Explosão Mágica: dano alto em área (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "bomba_de_fumaca",
    "nome": "Bomba de Fumaça",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade a 1 criatura",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "bomba_de_fumaca_celestial",
    "nome": "Bomba de Fumaça (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade a 1 criatura",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "bomba_de_fumaca_chrysalis",
    "nome": "Bomba de Fumaça (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade a 1 criatura",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "bomba_de_fumaca_corrompido",
    "nome": "Bomba de Fumaça (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade a 1 criatura",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "bomba_de_fumaca_magico",
    "nome": "Bomba de Fumaça (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade a 1 criatura",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "bomba_de_fumaca_vitalismo",
    "nome": "Bomba de Fumaça (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade a 1 criatura",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "botina_de_couro",
    "nome": "Botina de Couro",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Investida",
      "abilities": [
        "Investida"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "botina_de_couro_celestial",
    "nome": "Botina de Couro (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Investida",
      "abilities": [
        "Investida"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "botina_de_couro_chrysalis",
    "nome": "Botina de Couro (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Investida",
      "abilities": [
        "Investida"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "botina_de_couro_corrompido",
    "nome": "Botina de Couro (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Investida",
      "abilities": [
        "Investida"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "botina_de_couro_magico",
    "nome": "Botina de Couro (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Investida",
      "abilities": [
        "Investida"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "botina_de_couro_vitalismo",
    "nome": "Botina de Couro (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Investida",
      "abilities": [
        "Investida"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "bracadeira_vitalista",
    "nome": "Braçadeira Vitalista",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Escudo Vitalista pequeno (bloqueia dano verdadeiro)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "brasao_feral",
    "nome": "Brasão Feral",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+todos os atributos, mas impede outra armadura (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "buque_de_sereia",
    "nome": "Buquê de Sereia",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Atributos balanceados + utilitário aquático (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "bussola_maldita",
    "nome": "Bússola Maldita",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Punição (ponto fraco) + cresce a cada morte (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "caco_de_cristal_de_mana",
    "nome": "Caco de Cristal de Mana",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+1 cristal neste turno",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "caixa_de_municao",
    "nome": "Caixa de Munição",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Concede Ataque Duplo a uma criatura à distância (a refinar)",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "cajado_rachado",
    "nome": "Cajado Rachado",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+1 de ataque mágico",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "calice_sangrento",
    "nome": "Cálice Sangrento",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Acumula sangue → invulnerabilidade temporária + crescimento permanente (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "capa_esfarrapada",
    "nome": "Capa Esfarrapada",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+1 PV",
      "hp_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "capa_esfarrapada_celestial",
    "nome": "Capa Esfarrapada (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+1 PV",
      "hp_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "capa_esfarrapada_chrysalis",
    "nome": "Capa Esfarrapada (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+1 PV",
      "hp_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "capa_esfarrapada_corrompido",
    "nome": "Capa Esfarrapada (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+1 PV",
      "hp_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "capa_esfarrapada_magico",
    "nome": "Capa Esfarrapada (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+1 PV",
      "hp_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "capa_esfarrapada_vitalismo",
    "nome": "Capa Esfarrapada (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+1 PV",
      "hp_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "colar_de_moedas_antigas",
    "nome": "Colar de Moedas Antigas",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+drop de moedas/sorte — economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "colar_de_moedas_antigas_celestial",
    "nome": "Colar de Moedas Antigas (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+drop de moedas/sorte — economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "colar_de_moedas_antigas_chrysalis",
    "nome": "Colar de Moedas Antigas (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+drop de moedas/sorte — economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "colar_de_moedas_antigas_corrompido",
    "nome": "Colar de Moedas Antigas (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+drop de moedas/sorte — economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "colar_de_moedas_antigas_magico",
    "nome": "Colar de Moedas Antigas (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+drop de moedas/sorte — economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "colar_de_moedas_antigas_vitalismo",
    "nome": "Colar de Moedas Antigas (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+drop de moedas/sorte — economia (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "coroa_do_rei_caido",
    "nome": "Coroa do Rei Caído",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Escudo Espelhado: reflete dano recebido (a refinar)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "cota_de_couro",
    "nome": "Cota de Couro",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "cota_de_couro_celestial",
    "nome": "Cota de Couro (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "cota_de_couro_chrysalis",
    "nome": "Cota de Couro (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "cota_de_couro_corrompido",
    "nome": "Cota de Couro (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "cota_de_couro_magico",
    "nome": "Cota de Couro (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "cota_de_couro_vitalismo",
    "nome": "Cota de Couro (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "crepusculo_do_berserker",
    "nome": "Crepúsculo do Berserker",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Roubo de PV + amplifica Cura + reduz Escudo inimigo (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "donzela_caida",
    "nome": "Donzela Caída",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Sangramento (roadmap) + perfura armadura (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "dragon_slayer",
    "nome": "Dragon Slayer",
    "concepts": [
      "corrompido",
      "magico"
    ],
    "grants": {
      "raw_effect": "+ATK alto + Punição",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "escudo_de_aegis",
    "nome": "Escudo de Aegis",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Escudo automático a 20% de PV + resistência adaptativa (a refinar)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "escudo_de_ferro",
    "nome": "Escudo de Ferro",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Escudo + 1 PV",
      "hp_bonus": 1,
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "escudo_de_ferro_celestial",
    "nome": "Escudo de Ferro (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Escudo + 1 PV",
      "hp_bonus": 1,
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "escudo_de_ferro_chrysalis",
    "nome": "Escudo de Ferro (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Escudo + 1 PV",
      "hp_bonus": 1,
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "escudo_de_ferro_corrompido",
    "nome": "Escudo de Ferro (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Escudo + 1 PV",
      "hp_bonus": 1,
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "escudo_de_ferro_magico",
    "nome": "Escudo de Ferro (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Escudo + 1 PV",
      "hp_bonus": 1,
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "escudo_de_ferro_vitalismo",
    "nome": "Escudo de Ferro (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Escudo + 1 PV",
      "hp_bonus": 1,
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "escudo_de_tabuas",
    "nome": "Escudo de Tábuas",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Escudo: bloqueia 1 dano físico",
      "armor": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "escudo_de_tabuas_celestial",
    "nome": "Escudo de Tábuas (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Escudo: bloqueia 1 dano físico",
      "armor": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "escudo_de_tabuas_chrysalis",
    "nome": "Escudo de Tábuas (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Escudo: bloqueia 1 dano físico",
      "armor": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "escudo_de_tabuas_corrompido",
    "nome": "Escudo de Tábuas (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Escudo: bloqueia 1 dano físico",
      "armor": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "escudo_de_tabuas_magico",
    "nome": "Escudo de Tábuas (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Escudo: bloqueia 1 dano físico",
      "armor": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "escudo_de_tabuas_vitalismo",
    "nome": "Escudo de Tábuas (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Escudo: bloqueia 1 dano físico",
      "armor": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espada_curta",
    "nome": "Espada Curta",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+2 de ataque (corpo a corpo)",
      "atk_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espada_curta_celestial",
    "nome": "Espada Curta (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+2 de ataque (corpo a corpo)",
      "atk_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espada_curta_chrysalis",
    "nome": "Espada Curta (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+2 de ataque (corpo a corpo)",
      "atk_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espada_curta_corrompido",
    "nome": "Espada Curta (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+2 de ataque (corpo a corpo)",
      "atk_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espada_curta_magico",
    "nome": "Espada Curta (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+2 de ataque (corpo a corpo)",
      "atk_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espada_curta_vitalismo",
    "nome": "Espada Curta (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+2 de ataque (corpo a corpo)",
      "atk_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "espelho_quebrado_dos_voss",
    "nome": "Espelho Quebrado dos Voss",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Cria ilusão + Furtividade temporária (a refinar)",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "estandarte_gasto",
    "nome": "Estandarte Gasto",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Inspirar (buff pequeno aos aliados)",
      "abilities": [
        "Inspirar"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "estandarte_gasto_celestial",
    "nome": "Estandarte Gasto (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Inspirar (buff pequeno aos aliados)",
      "abilities": [
        "Inspirar"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "estandarte_gasto_chrysalis",
    "nome": "Estandarte Gasto (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Inspirar (buff pequeno aos aliados)",
      "abilities": [
        "Inspirar"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "estandarte_gasto_corrompido",
    "nome": "Estandarte Gasto (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Inspirar (buff pequeno aos aliados)",
      "abilities": [
        "Inspirar"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "estandarte_gasto_magico",
    "nome": "Estandarte Gasto (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Inspirar (buff pequeno aos aliados)",
      "abilities": [
        "Inspirar"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "estandarte_gasto_vitalismo",
    "nome": "Estandarte Gasto (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Inspirar (buff pequeno aos aliados)",
      "abilities": [
        "Inspirar"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "faca_militar",
    "nome": "Faca Militar",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+1 de ataque (corpo a corpo)",
      "atk_bonus": 1,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "faixas",
    "nome": "Faixas",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "flor_de_lotus",
    "nome": "Flor de Lótus",
    "concepts": [
      "corrompido",
      "magico"
    ],
    "grants": {
      "raw_effect": "Sintetiza poções — Cura/utilitário (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "frasco_de_oleo",
    "nome": "Frasco de Óleo",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Pequeno dano de fogo a 1 criatura",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "frasco_de_oleo_celestial",
    "nome": "Frasco de Óleo (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Pequeno dano de fogo a 1 criatura",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "frasco_de_oleo_chrysalis",
    "nome": "Frasco de Óleo (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Pequeno dano de fogo a 1 criatura",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "frasco_de_oleo_corrompido",
    "nome": "Frasco de Óleo (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Pequeno dano de fogo a 1 criatura",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "frasco_de_oleo_magico",
    "nome": "Frasco de Óleo (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Pequeno dano de fogo a 1 criatura",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "frasco_de_oleo_vitalismo",
    "nome": "Frasco de Óleo (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Pequeno dano de fogo a 1 criatura",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "frasco_de_sangue_atormentado",
    "nome": "Frasco de Sangue Atormentado",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Imunidade a medo/controle — anti-Silêncio/Provocar (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "funda",
    "nome": "Funda",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "funda_celestial",
    "nome": "Funda (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "funda_chrysalis",
    "nome": "Funda (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "funda_corrompido",
    "nome": "Funda (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "funda_magico",
    "nome": "Funda (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "funda_vitalismo",
    "nome": "Funda (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "fuzil",
    "nome": "Fuzil",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "garra_de_lobo_de_fumaca",
    "nome": "Garra de Lobo de Fumaça",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "granada",
    "nome": "Granada",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Dano em área a criaturas inimigas (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "insignia_da_lua",
    "nome": "Insígnia da Lua",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Amplifica à noite + Furtividade reforçada (a refinar)",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "katana",
    "nome": "Katana",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+3 de ataque (corpo a corpo)",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "kit_de_sobrevivencia",
    "nome": "Kit de Sobrevivência",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+2 PV",
      "hp_bonus": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "kit_medico",
    "nome": "Kit Médico",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "laco_de_yggdrasil",
    "nome": "Laço de Yggdrasil",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Regen contínua (Cura) + Escudo (a refinar)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "lagrima_do_deus_caido",
    "nome": "Lágrima do Deus Caído",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Amplia potência de poções + sorte (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "lamento_do_salgueiro",
    "nome": "Lamento do Salgueiro",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+dano mágico, mas +custo (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_afiada",
    "nome": "Lâmina Afiada",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+3 de ataque",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_afiada_celestial",
    "nome": "Lâmina Afiada (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+3 de ataque",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_afiada_chrysalis",
    "nome": "Lâmina Afiada (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+3 de ataque",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_afiada_corrompido",
    "nome": "Lâmina Afiada (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+3 de ataque",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_afiada_magico",
    "nome": "Lâmina Afiada (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+3 de ataque",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_afiada_vitalismo",
    "nome": "Lâmina Afiada (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+3 de ataque",
      "atk_bonus": 3,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "lamina_das_cinzas",
    "nome": "Lâmina das Cinzas",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+ATK alto + Alcance + Roubo de PV + Sangramento (roadmap)",
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "lasca_de_manalium",
    "nome": "Lasca de Manalium",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Silêncio em 1 criatura",
      "abilities": [
        "Silencio"
      ]
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "leque_de_laminas_do_noryan",
    "nome": "Leque de Lâminas do Noryan",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Alcance + Ataque Duplo (a refinar)",
      "attack_type": "a_distancia",
      "abilities": [
        "AtaqueDuplo"
      ]
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "liturgia_abissal",
    "nome": "Liturgia Abissal",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Controle: transforma vítima em marionete; antídoto Manalium (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "manto_de_sombras",
    "nome": "Manto de Sombras",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "manto_de_sombras_celestial",
    "nome": "Manto de Sombras (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "manto_de_sombras_chrysalis",
    "nome": "Manto de Sombras (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "manto_de_sombras_corrompido",
    "nome": "Manto de Sombras (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "manto_de_sombras_magico",
    "nome": "Manto de Sombras (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "manto_de_sombras_vitalismo",
    "nome": "Manto de Sombras (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "mascara_do_demonio",
    "nome": "Máscara do Demônio",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Durabilidade/longevidade — mantém vivo (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "medalhao_solar",
    "nome": "Medalhão Solar",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+intelecto + conjuração mais barata + magia grátis (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "molotov",
    "nome": "Molotov",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Dano de fogo + chamas persistentes a 1 criatura (a refinar)",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "orbe_da_eternidade",
    "nome": "Orbe da Eternidade",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+atk/def sustentado + progresso (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "orbe_do_caos",
    "nome": "Orbe do Caos",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Explosão Mágica: incineração em área + chamas persistentes (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "orbe_drakkai",
    "nome": "Orbe Drakkai",
    "concepts": [
      "corrompido",
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Corrupção Drakkai progressiva ao contato (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "pedra_de_amolar",
    "nome": "Pedra de Amolar",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "+ataque numa criatura neste turno",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pedra_de_amolar_celestial",
    "nome": "Pedra de Amolar (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "+ataque numa criatura neste turno",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pedra_de_amolar_chrysalis",
    "nome": "Pedra de Amolar (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "+ataque numa criatura neste turno",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pedra_de_amolar_corrompido",
    "nome": "Pedra de Amolar (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "+ataque numa criatura neste turno",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pedra_de_amolar_magico",
    "nome": "Pedra de Amolar (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "+ataque numa criatura neste turno",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pedra_de_amolar_vitalismo",
    "nome": "Pedra de Amolar (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "+ataque numa criatura neste turno",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pedra_do_regresso",
    "nome": "Pedra do Regresso",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Escape/teleporte — utilitário (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pistola",
    "nome": "Pistola",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Alcance: +1 de ataque à distância",
      "atk_bonus": 1,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "pocao_de_cura",
    "nome": "Poção de Cura",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pocao_de_cura_celestial",
    "nome": "Poção de Cura (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pocao_de_cura_chrysalis",
    "nome": "Poção de Cura (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pocao_de_cura_corrompido",
    "nome": "Poção de Cura (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pocao_de_cura_magico",
    "nome": "Poção de Cura (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pocao_de_cura_vitalismo",
    "nome": "Poção de Cura (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Cura média",
      "heal": 4,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": true
  },
  {
    "id": "pocao_menor",
    "nome": "Poção Menor",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "pocao_menor_celestial",
    "nome": "Poção Menor (Celestial)",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "pocao_menor_chrysalis",
    "nome": "Poção Menor (Chrysalis)",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "pocao_menor_corrompido",
    "nome": "Poção Menor (Corrompido)",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "pocao_menor_magico",
    "nome": "Poção Menor (Mágico)",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "pocao_menor_vitalismo",
    "nome": "Poção Menor (Vitalismo)",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Cura pequena",
      "heal": 2,
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "presa_de_varaak",
    "nome": "Presa de Varaak",
    "concepts": [
      "celestial",
      "magico"
    ],
    "grants": {
      "raw_effect": "+ATK alto (3x atributos físicos) (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "ramo_de_yggdrasil",
    "nome": "Ramo de Yggdrasil",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Teletransporte + regen acelerada (Cura) (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "rancor_da_sereia",
    "nome": "Rancor da Sereia",
    "concepts": [
      "celestial",
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Maldição: penaliza o portador (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "reliquia_de_mythrium",
    "nome": "Relíquia de Mythrium",
    "concepts": [
      "celestial"
    ],
    "grants": {
      "raw_effect": "Ressuscita um vitalista (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "revolver",
    "nome": "Revólver",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Alcance: +2 de ataque à distância",
      "atk_bonus": 2,
      "attack_type": "a_distancia",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "runa_ancestral",
    "nome": "Runa Ancestral",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Escudo Espelhado (+defesa mágica) + bênção (a refinar)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "sarcofago_de_ouro",
    "nome": "Sarcófago de Ouro",
    "concepts": [
      "neutro"
    ],
    "grants": {
      "raw_effect": "Aprisiona inimigo (Silêncio/remove temporário) (a refinar)",
      "abilities": [
        "Silencio"
      ]
    },
    "rarity": "epica",
    "is_flash": true
  },
  {
    "id": "seiva_impura",
    "nome": "Seiva Impura",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Buff temporário de ataque com risco de corrupção (a refinar)",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": true
  },
  {
    "id": "selo_de_yato",
    "nome": "Selo de Yato",
    "concepts": [
      "vitalismo"
    ],
    "grants": {
      "raw_effect": "Mantém Yato em corpo mortal-imortal (a refinar)",
      "abilities": []
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "silenciador",
    "nome": "Silenciador",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Concede Furtividade",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "smartphone",
    "nome": "Smartphone",
    "concepts": [
      "chrysalis"
    ],
    "grants": {
      "raw_effect": "Utilitário: revela/coordena (a refinar)",
      "abilities": []
    },
    "rarity": "comum",
    "is_flash": false
  },
  {
    "id": "talisma_do_escudo_mal_amado",
    "nome": "Talismã do Escudo Mal Amado",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Escudo Sagrado: +def + chance de anular ataque letal (a refinar)",
      "armor": 1,
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  },
  {
    "id": "veu_da_noite",
    "nome": "Véu da Noite",
    "concepts": [
      "corrompido"
    ],
    "grants": {
      "raw_effect": "Disfarce/ilusão — Furtividade (a refinar)",
      "abilities": [
        "Furtividade"
      ]
    },
    "rarity": "epica",
    "is_flash": false
  },
  {
    "id": "zepelim_dourado",
    "nome": "Zepelim Dourado",
    "concepts": [
      "magico"
    ],
    "grants": {
      "raw_effect": "Aeronave — utilitário (a refinar)",
      "abilities": []
    },
    "rarity": "rara",
    "is_flash": false
  }
]') as x(id text, rarity text)
on conflict (id) do nothing;