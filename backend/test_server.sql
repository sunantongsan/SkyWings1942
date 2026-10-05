begin;
insert into auth.users(id,aud,role,email,created_at,updated_at) values
('ef110000-0000-4000-8000-000000000001','authenticated','authenticated','xian-test-one@example.invalid',now(),now()),
('ef110000-0000-4000-8000-000000000002','authenticated','authenticated','xian-test-two@example.invalid',now(),now());
select set_config('request.jwt.claim.sub','ef110000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$
declare r jsonb; before_j int; req uuid:=gen_random_uuid(); failed bool:=false;
begin
 r:=public.xian_action('create','{"name":"สำนักทดสอบ","map":"bamboo"}',gen_random_uuid());
 assert r->'state'->>'name'='สำนักทดสอบ';
 r:=public.xian_action('build','{"type":"well","x":1,"y":1}',gen_random_uuid());
 assert jsonb_array_length(r->'state'->'buildings')=3;
 begin perform public.xian_action('build','{"type":"kitchen","x":2,"y":1}',gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'Builder limit not enforced';
 before_j:=(r->'state'->>'jade')::int;
 r:=public.xian_action('checkin','{}',req);
 r:=public.xian_action('checkin','{}',req);
 assert (r->'state'->>'jade')::int=before_j+5,'Duplicate reward';
 failed:=false;
 begin perform public.xian_action('checkin','{}',gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'Daily checkin repeated';
 r:=public.xian_action('exchange','{"resource":"stone"}',gen_random_uuid());
 assert (r->'state'->>'jade')::int=before_j;
 r:=public.xian_action('match_start','{}',gen_random_uuid());
 assert jsonb_array_length(r->'state'->'match'->'board')=64;
 failed:=false;
 begin perform public.xian_action('match_swap','{"a":-1,"b":0}',gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'Invalid swap accepted';
 failed:=false;
 begin perform public.xian_action('raid_claim','{}',gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'No raid rewarded';
 failed:=false;
 begin execute 'select * from xian_private.players'; exception when insufficient_privilege then failed:=true;end;
 assert failed,'Player can access private states';
end $$;
reset role;
-- Accelerate only test fixtures inside this rolled-back transaction.
update xian_private.players set state=jsonb_set(jsonb_set(state,'{buildings,2,finish}',to_jsonb(floor(extract(epoch from now()))::bigint-60)),'{last_tick}',to_jsonb(floor(extract(epoch from now()))::bigint-90)) where user_id='ef110000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ declare r jsonb; begin
 r:=public.xian_action('sync','{}',gen_random_uuid());
 assert (r->'state'->'buildings'->2->>'level')::int=1;
 assert (r->'state'->>'water')::numeric=710,'Production before completion counted';
end $$;
reset role;
select set_config('request.jwt.claim.sub','ef110000-0000-4000-8000-000000000002',true);
select public.xian_action('create','{"name":"สำนักเป้าหมาย","map":"mountain"}',gen_random_uuid())->'state'->>'name' as defender;
update xian_private.players set state=jsonb_set(state,'{shield}','0') where user_id='ef110000-0000-4000-8000-000000000002';
update xian_private.players set state=jsonb_set(state,'{army}','[10,2,1]') where user_id='ef110000-0000-4000-8000-000000000001';
select set_config('request.jwt.claim.sub','ef110000-0000-4000-8000-000000000001',true);
set local role authenticated;
do $$ declare r jsonb; failed bool:=false; begin
 r:=public.xian_action('scout','{"mode":"player"}',gen_random_uuid());
 assert r->'state'->'scout'->>'player'='ef110000-0000-4000-8000-000000000002';
 r:=public.xian_action('raid_start','{}',gen_random_uuid());
 assert r->'state'->'army'='[0,0,0,0,0,0,0,0,0,0]'::jsonb;
 begin perform public.xian_action('raid_claim','{}',gen_random_uuid());exception when others then failed:=true;end;
 assert failed,'Early raid payout';
end $$;
reset role;
do $$ declare s jsonb; begin
 select state into s from xian_private.players where user_id='ef110000-0000-4000-8000-000000000002';
 assert (s->>'water')::numeric=553;
 assert (s->>'jade')::int=20,'Jade was stolen';
 assert s ? 'last_defense';
end $$;
update xian_private.players set state=jsonb_set(state,'{raid,finish}','0') where user_id='ef110000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ declare r jsonb; req uuid:=gen_random_uuid(); w numeric; begin
 r:=public.xian_action('raid_claim','{}',req); w:=(r->'state'->>'water')::numeric;
 r:=public.xian_action('raid_claim','{}',req);
 assert (r->'state'->>'water')::numeric=w;
 assert not r->'state' ? 'raid';
end $$;
reset role;

-- Deterministic swap / payout / daily limit fixtures, never persisted.
update xian_private.players set state=state||jsonb_build_object(
 'match',jsonb_build_object('board',(select jsonb_agg(case when i in (0,1,10) then 1 when i=2 then 2 else (i/8+i%8)%5 end order by i) from generate_series(0,63) i),'moves',20,'score',270,'goal',300,'rewarded',false),
 'match_day',to_char(now() at time zone 'Asia/Bangkok','YYYY-MM-DD'),'match_rewards',0
) where user_id='ef110000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ declare r jsonb; req uuid:=gen_random_uuid(); j int; begin
 r:=public.xian_action('sync','{}',gen_random_uuid());j:=(r->'state'->>'jade')::int;
 r:=public.xian_action('match_swap','{"a":2,"b":10}',req);
 assert (r->'state'->'match'->>'score')::int>=300;
 assert (r->'state'->'match'->>'paid')::boolean;
 assert (r->'state'->>'jade')::int=j+(r->'state'->>'match_reward_jade')::int;
 r:=public.xian_action('match_swap','{"a":2,"b":10}',req);
 assert (r->'state'->>'jade')::int=j+(r->'state'->>'match_reward_jade')::int;
 r:=public.xian_action('match_start','{}',gen_random_uuid());
 r:=public.xian_action('match_shuffle','{}',gen_random_uuid());
 assert (r->'state'->'match'->>'moves')::int=19;
end $$;
reset role;
select 'XIAN_SERVER_TESTS_PASSED' as result;
rollback;
