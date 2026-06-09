-- ============================================================================
-- Card Game — fonte de pacote: subir de nível concede 1 pacote/nível ganho
-- (obtencao_de_cartas.md). Estende add_xp (create or replace) adicionando o
-- grant_pack server-side ao fim do level-up. Reproduz o corpo de
-- 20260609140001_rpc_player.sql + a linha nova. grant_pack ja existe (200000).
-- ============================================================================
create or replace function public.add_xp(p_player uuid, p_amount int)
  returns json
  language plpgsql
  security invoker
as $$
declare
  v_xp            int;
  v_level         int;
  v_xp_to_next    int;
  v_attr_points   int;
  v_constitution  int;
  v_spirit        int;
  v_class_type    text;
  v_peak_level    int;
  v_old_level     int;
  v_marco         int;
  v_marcos        int[] := array[10,15,20,25,30,40,50,60,70,80,99];
begin
  select xp, level, xp_to_next, attribute_points,
         constitution, spirit, class_type, peak_level
    into v_xp, v_level, v_xp_to_next, v_attr_points,
         v_constitution, v_spirit, v_class_type, v_peak_level
    from public.players
   where id = p_player;

  if not found then
    return null;
  end if;

  v_old_level := v_level;
  v_xp        := v_xp + p_amount;

  while v_xp >= v_xp_to_next loop
    v_xp          := v_xp - v_xp_to_next;
    v_level       := v_level + 1;
    v_attr_points := v_attr_points + 1;
    v_xp_to_next  := public._xp_to_next_level(v_level);
  end loop;

  foreach v_marco in array v_marcos loop
    if v_old_level < v_marco and v_level >= v_marco then
      v_attr_points := v_attr_points
        + public._scaling_bonus_points(v_class_type, v_marco);
    end if;
  end loop;

  if v_level > v_peak_level then
    v_peak_level := v_level;
  end if;

  update public.players
     set xp               = v_xp,
         level            = v_level,
         xp_to_next       = v_xp_to_next,
         attribute_points = v_attr_points,
         max_hp           = public._calc_max_hp(v_constitution, v_level),
         max_mp           = public._calc_max_mp(v_spirit, v_constitution, v_level),
         peak_level       = v_peak_level
   where id = p_player;

  -- Card Game (NOVO): subir de nível concede 1 pacote por nível ganho.
  if v_level > v_old_level then
    perform public.grant_pack(p_player, v_level - v_old_level, 'padrao');
  end if;

  return json_build_object(
    'previous_level', v_old_level,
    'new_level',      v_level
  );
end;
$$;
