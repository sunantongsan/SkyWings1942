-- Private deterministic auto-battle additions. Units approach along ten lanes.
-- Coordinates are grid cells; the client replays these authoritative events.
create or replace function xian_private.formation_battle(bs jsonb,a jsonb) returns jsonb
language plpgsql immutable security invoker set search_path='' as $$
declare
 health numeric[]:=array_fill(0::numeric,array[10]); initial numeric[]:=array_fill(0::numeric,array[10]);
 hitpoints int[]:=array[190,140,700,220,1700,650,850,2200,2200,3600];
 armor numeric[]:=array[0.05,0.08,0.18,0.05,0.55,0.30,0.20,0.60,0.15,0.72];
 weights int[]:=array[35,90,150,190,280,380,500,700,950,1300];
 fired jsonb:='{}'; events jsonb:='[]'; b jsonb; tick int; i int; bi int; target int; lev int; activation int;
 x numeric; y numeric; distance numeric; nearest numeric; radius numeric; damage numeric; loss numeric:=0;kind text; affected bool;
begin
 for i in 1..10 loop health[i]:=greatest(0,coalesce((a->>(i-1))::int,0))*hitpoints[i];initial[i]:=health[i];end loop;
 for tick in 0..24 loop
  bi:=0;
  for b in select value from jsonb_array_elements(coalesce(bs,'[]'::jsonb)) loop
   bi:=bi+1;kind:=b->>'id';lev:=least(10,coalesce((b->>'level')::int,0));
   if lev<=0 or kind not in ('trap_storm','trap_sword','trap_fire','lightning') then continue;end if;
   radius:=case kind when 'lightning' then 5.2 when 'trap_storm' then 3.2 when 'trap_sword' then 2.8 else 2.6 end;
   target:=0;nearest:=radius;
   for i in 1..10 loop
    if health[i]<=0 then continue;end if;
    x:=4+(i-1)*0.7;y:=14-least(1,tick/8.0)*5.5;
    distance:=sqrt(power(x-(b->>'x')::numeric,2)+power(y-(b->>'y')::numeric,2));
    if distance<=nearest then nearest:=distance;target:=i;end if;
   end loop;
   if target=0 then continue;end if;
   if kind='lightning' then
    if tick%2<>0 then continue;end if;
    damage:=(70+20*lev)*(1-armor[target]);health[target]:=greatest(0,health[target]-damage);
    events:=events||jsonb_build_array(jsonb_build_object('time',tick,'kind',kind,'x',b->'x','y',b->'y','tx',4+(target-1)*0.7,'ty',14-least(1,tick/8.0)*5.5,'target',target-1));
   else
    activation:=coalesce((fired->>bi::text)::int,-1);
    if activation<0 then
     activation:=tick;fired:=fired||jsonb_build_object(bi::text,tick);
     events:=events||jsonb_build_array(jsonb_build_object('time',tick,'kind',kind,'x',b->'x','y',b->'y','tx',b->'x','ty',b->'y'));
    end if;
    if tick-activation>=4 then continue;end if;
    for i in 1..10 loop
     x:=4+(i-1)*0.7;y:=14-least(1,tick/8.0)*5.5;
     if health[i]>0 and sqrt(power(x-(b->>'x')::numeric,2)+power(y-(b->>'y')::numeric,2))<=radius then
      damage:=(case kind when 'trap_sword' then 38 when 'trap_fire' then 32 else 26 end+8*lev)*(1-armor[i])*least(3,ceil(health[i]/hitpoints[i]));
      health[i]:=greatest(0,health[i]-damage);
     end if;
    end loop;
   end if;
  end loop;
 end loop;
 for i in 1..10 loop loss:=loss+(initial[i]-health[i])/hitpoints[i]*weights[i];end loop;
 return jsonb_build_object('events',events,'power_lost',loss);
end $$;
revoke all on function xian_private.formation_battle(jsonb,jsonb) from public,anon,authenticated;

create or replace function xian_private.ready_army(s jsonb,t bigint) returns jsonb
language sql immutable security invoker set search_path='' as $$
 select jsonb_agg(greatest(0,coalesce((s->'army'->>i)::int,0))+
  (select count(*) from jsonb_array_elements(coalesce(s->'jobs','[]'::jsonb)) j
   where (j->>'type')::int=i and not coalesce((j->>'paused')::boolean,false) and (j->>'finish')::bigint<=t) order by i)
 from generate_series(0,9) i;
$$;
revoke all on function xian_private.ready_army(jsonb,bigint) from public,anon,authenticated;
