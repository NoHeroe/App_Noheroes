-- =============================================================================
-- RPC domain: Heal
-- Porta fielmente PlayerHealService.applyHpHealWithVitalismRegen +
-- computeHealResult (lib/data/datasources/local/player_heal_service.dart)
-- e VitalismCalculator.calculateMaxVitalism (lib/core/utils/vitalism_calculator.dart).
-- Ponto unico de cura de HP com regen proporcional de vitalismo (ADR 0002).
-- =============================================================================

-- Origem Dart: PlayerHealService.applyHpHealWithVitalismRegen + computeHealResult
--              + VitalismCalculator.calculateMaxVitalism (inlined).
-- Le hp/max_hp/current_vitalism/class_type/level do proprio jogador (auth.uid()),
-- calcula vitalismMax + regen proporcional, escreve hp+current_vitalism clamped.
-- Operacao void (o codigo Dart nao retorna nada).
create or replace function public.apply_hp_heal(
  p_player uuid,
  p_hp_gained int
) returns void
language plpgsql
security invoker
as $$
declare
  v_hp                int;
  v_max_hp            int;
  v_current_vitalism  int;
  v_class_type        text;
  v_level             int;

  v_base              numeric;       -- _baseByClass[classType]; null => sem vitalismo
  v_percentual        numeric;
  v_vitalism_max      int;

  v_new_hp            int;
  v_hp_gained_real    int;
  v_perc_ganho        numeric;
  v_vitalismo_ganho   int;
  v_new_vitalism      int;
begin
  -- if (hpGained <= 0) return;  (porte direto do early-return Dart)
  if p_hp_gained is null or p_hp_gained <= 0 then
    return;
  end if;

  -- _dao.findById(playerId); if (player == null) return;
  select hp, max_hp, current_vitalism, class_type, level
    into v_hp, v_max_hp, v_current_vitalism, v_class_type, v_level
  from public.players
  where id = p_player;

  if not found then
    return;
  end if;

  -- --- VitalismCalculator.calculateMaxVitalism (inline) ----------------------
  -- _baseByClass: somente 5 classes tem base; demais (parse null OU classe sem
  -- entrada no mapa) => base null => return 0. ClassType.values.asNameMap()
  -- usa os NOMES do enum (camelCase): 'shadowWeaver' etc.
  v_base := case v_class_type
              when 'hunter'       then 1.90
              when 'rogue'        then 2.10
              when 'warrior'      then 2.20
              when 'colossus'     then 2.80
              when 'shadowWeaver' then 3.00
              else null
            end;

  if v_base is null then
    v_vitalism_max := 0;
  else
    -- percentual = base + (level > 5 ? (level - 5) * 0.02 : 0.0)
    v_percentual := v_base + case when v_level > 5
                                  then (v_level - 5) * 0.02
                                  else 0.0
                             end;
    -- (hp * percentual * multiplier).round(); multiplier=1.0 (default).
    -- Dart round() = round-half-away-from-zero; valores positivos => round-half-up.
    -- Postgres round(numeric) tambem e half-away-from-zero (casamos o comportamento).
    v_vitalism_max := round(v_max_hp::numeric * v_percentual)::int;
  end if;

  -- --- computeHealResult ------------------------------------------------------
  -- newHp = (currentHp + hpGained).clamp(0, hpMax)
  v_new_hp := least(greatest(v_hp + p_hp_gained, 0), v_max_hp);
  -- hpGainedReal = newHp - currentHp
  v_hp_gained_real := v_new_hp - v_hp;

  -- if (vitalismMax <= 0 || hpMax <= 0 || hpGainedReal <= 0) -> so HP muda.
  if v_vitalism_max <= 0 or v_max_hp <= 0 or v_hp_gained_real <= 0 then
    v_new_vitalism := v_current_vitalism;
  else
    -- percGanho = hpGainedReal / hpMax
    v_perc_ganho := v_hp_gained_real::numeric / v_max_hp::numeric;
    -- vitalismoGanho = (vitalismMax * percGanho).round()
    v_vitalismo_ganho := round(v_vitalism_max::numeric * v_perc_ganho)::int;
    -- newCurrentVitalism = (currentVitalism + vitalismoGanho).clamp(0, vitalismMax)
    v_new_vitalism := least(greatest(v_current_vitalism + v_vitalismo_ganho, 0), v_vitalism_max);
  end if;

  -- Escrita unica (PlayersTableCompanion: hp + currentVitalism).
  update public.players
     set hp               = v_new_hp,
         current_vitalism = v_new_vitalism
   where id = p_player;
end;
$$;
