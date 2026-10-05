create or replace function xian_private.retire_recruit(s jsonb) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare b jsonb; kept jsonb:='[]'; archived jsonb:='[]'; units bigint:=0; purchases bigint; credit jsonb;
begin
 if coalesce((s->>'recruit_retired_v48')::boolean,false) then return s;end if;
 for b in select value from jsonb_array_elements(s->'buildings') loop
  if b->>'id'='recruit' then
   purchases:=(power(2,greatest(0,least(10,(b->>'level')::int)))-1)::bigint;
   if coalesce((b->>'finish')::bigint,0)>0 then purchases:=purchases+power(2,greatest(0,least(10,(b->>'level')::int)))::bigint;end if;
   units:=units+purchases;archived:=archived||jsonb_build_array(b);
  else kept:=kept||jsonb_build_array(b);end if;
 end loop;
 credit:=jsonb_build_object('water',units*80,'rice',units*100,'stone',units*5);
 return s||jsonb_build_object('buildings',kept,'retired_recruit',archived,'recruit_refund',credit,'recruit_retired_v48',true);
end $$;
revoke all on function xian_private.retire_recruit(jsonb) from public,anon,authenticated;
do $patch$
declare src text; marker text;
begin
 src:=pg_get_functiondef('xian_private.catalog()'::regprocedure);
 marker:='{"id":"recruit","name":"โรงรับศิษย์","water":80,"rice":100,"stone":5,"seconds":20,"limit":2},';
 if position(marker in src)>0 then execute replace(src,marker,'');
 elsif position('"id":"recruit"' in src)>0 then raise exception 'Unknown recruit catalog definition';end if;
 src:=pg_get_functiondef('xian_private.act(text,jsonb,uuid)'::regprocedure);
 if position('xian_private.retire_recruit(s)' in src)>0 then return;end if;
 marker:=' -- Normalize only once under the account lock; archive removed dorms for recovery.';
 if position(marker in src)=0 then raise exception 'Unexpected action body';end if;
 src:=replace(src,marker,$body$
 -- Index-based actions require a matching layout on accounts whose recruit was removed.
 if p_action in ('upgrade','move','boost','wall_edit','wall_manage') then
  if exists(select 1 from jsonb_array_elements(s->'buildings') v where v->>'id'='recruit') then raise exception 'กรุณาอัปเดตข้อมูลสำนักก่อน มีการถอดฐานรับศิษย์';end if;
  if jsonb_array_length(coalesce(s->'retired_recruit','[]'))>0 and p_args->>'layout' is distinct from
   (select string_agg((v->>'id')||':'||(v->>'x')||':'||(v->>'y'),',' order by i) from jsonb_array_elements(s->'buildings') with ordinality q(v,i)) then
   raise exception 'ผังฐานเปลี่ยนแล้ว กรุณาใช้เกมรุ่นใหม่และเลือกอาคารอีกครั้ง';
  end if;
 end if;
 s:=xian_private.retire_recruit(s);
 -- Normalize only once under the account lock; archive removed dorms for recovery.
$body$);
 marker:=' worker_max:=7;';
 if position(marker in src)=0 then raise exception 'Missing settlement marker';end if;
 src:=replace(src,marker,$body$
 -- Refund overflow stays in the account; never discard it at the storage cap.
 foreach typ in array array['water','rice','stone'] loop
  n:=case typ when 'water' then wc when 'rice' then rc else sc end;
  qty:=least(greatest(0,n-floor((s->>typ)::numeric)::int),coalesce((s->'recruit_refund'->>typ)::int,0));
  if qty>0 then
   s:=jsonb_set(s,array[typ],to_jsonb((s->>typ)::numeric+qty));
   s:=jsonb_set(s,array['recruit_refund',typ],to_jsonb((s->'recruit_refund'->>typ)::int-qty));
  end if;
 end loop;
 water:=(s->>'water')::numeric;rice:=(s->>'rice')::numeric;stone:=(s->>'stone')::numeric;
 worker_max:=7;
$body$);
 execute src;
end $patch$;
