-- All fixture users and balances roll back inside an exception subtransaction.
-- Any assertion failure escapes and aborts the migration/test transaction.
DO $test$
DECLARE
 a uuid:=gen_random_uuid(); d uuid:=gen_random_uuid(); req uuid:=gen_random_uuid();
 r jsonb; v jsonb; saved jsonb; report_id text; deadline bigint; t bigint:=floor(extract(epoch from now()));
BEGIN
 BEGIN
  insert into auth.users(id,aud,role,email,created_at,updated_at) values
   (a,'authenticated','authenticated',a::text||'@example.invalid',now(),now()),
   (d,'authenticated','authenticated',d::text||'@example.invalid',now(),now());
  perform set_config('request.jwt.claim.sub',a::text,true);
  perform public.xian_action('create','{"name":"Raid fixture","map":"bamboo"}',gen_random_uuid());
  perform set_config('request.jwt.claim.sub',d::text,true);
  perform public.xian_action('create','{"name":"Offline fixture","map":"bamboo"}',gen_random_uuid());
  -- Unique test-only hall tier prevents scouting any real account.
  update xian_private.players set state=jsonb_set(state,'{buildings,0,level}','10000')||
   '{"shield":0,"water":1000,"rice":800,"stone":100,"jade":77,"army":[100,0,0,0,0,0,0,0,0,0]}'::jsonb
   where user_id in (a,d);
  perform set_config('request.jwt.claim.sub',a::text,true);
  r:=public.xian_action('scout','{}',gen_random_uuid());
  assert r->'state'->'scout'->>'player'=d::text,'Default scout must find offline player';
  assert r->'state'->'scout'->>'water'='600','Preview must be 60 percent';
  r:=public.xian_action('raid_start','{}',req);saved:=r->'state'->'raid';
  r:=public.xian_action('raid_start','{}',req);
  assert r->'state'->'raid'=saved,'Replay must not repeat raid';
  select state into v from xian_private.players where user_id=d;
  assert v->>'water'='400' and v->>'rice'='320' and v->>'stone'='40','Exactly 60 percent loss';
  assert v->>'jade'='77','Jade must never be looted';
  assert v->>'repair_pending'='true' and not v ? 'repair_until','Offline repair must await owner';
  assert jsonb_array_length(v->'defense_history')=1,'Replay duplicated history';
  assert v->'last_defense'->>'attacker_id'=a::text,'Revenge must identify real attacker';
  report_id:=v->'last_defense'->>'id';
  perform set_config('request.jwt.claim.sub',d::text,true);
  r:=public.xian_action('sync','{}',gen_random_uuid());
  assert not r->'state' ? 'repair_until','Must wait until attack finishes';
  update xian_private.players set state=jsonb_set(state,'{last_defense,finish}',to_jsonb(t-1)) where user_id=d;
  r:=public.xian_action('sync','{}',gen_random_uuid());deadline:=(r->'state'->>'repair_until')::bigint;
  assert deadline=t+20,'Repair must last exactly 20 seconds';
  r:=public.xian_action('sync','{}',gen_random_uuid());
  assert (r->'state'->>'repair_until')::bigint=deadline,'Sync must not restart repair';
  update xian_private.players set state=jsonb_set(state,'{repair_until}',to_jsonb(t-1)) where user_id=d;
  r:=public.xian_action('sync','{}',gen_random_uuid());
  assert not r->'state' ? 'repair_pending' and not r->'state' ? 'repair_until','Repair must finish';
  assert r->'state'->>'jade'='77' and (r->'state'->>'water')::numeric=400,'Repair must be free';
  update xian_private.players set state=(state-'raid')||'{"shield":0}'::jsonb where user_id=a;
  r:=public.xian_action('scout',jsonb_build_object('revenge',report_id),gen_random_uuid());
  assert r->'state'->'scout'->>'player'=a::text,'Revenge must target original attacker';
  r:=public.xian_action('scout',jsonb_build_object('revenge',gen_random_uuid()),gen_random_uuid());
  assert not r->'state' ? 'scout','Unknown report must not authorize revenge';
  assert r ? 'notice' and r ? 'capacity','No target needs usable empty state';
  update xian_private.players set state=state||jsonb_build_object('shield',t+3600) where user_id=a;
  r:=public.xian_action('scout',jsonb_build_object('revenge',report_id),gen_random_uuid());
  assert not r->'state' ? 'scout','Revenge must respect shield';
  raise exception sqlstate 'ZX052' using message='fixture rollback';
 EXCEPTION WHEN SQLSTATE 'ZX052' THEN
  raise notice 'XIAN_PLAYER_RAIDS_PASSED';
 END;
END $test$;
