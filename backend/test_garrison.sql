begin;
do $$ begin
 assert xian_private.garrison('{"army":[0,1,3],"jobs":[]}',100)='[0,0,1]'::jsonb;
 assert xian_private.garrison('{"army":[10,4,2],"jobs":[{"type":0,"finish":100},{"type":1,"finish":100},{"type":2,"finish":100},{"type":2,"finish":101}]}',100)='[5,2,1]'::jsonb;
 assert xian_private.army_power('[5,2,1]')=505;
 assert not has_function_privilege('authenticated','xian_private.ready_army(jsonb,bigint)','EXECUTE');
end $$;
insert into auth.users(id,aud,role,email,created_at,updated_at) values
('ef440000-0000-4000-8000-000000000001','authenticated','authenticated','garrison-one@example.invalid',now(),now()),
('ef440000-0000-4000-8000-000000000002','authenticated','authenticated','garrison-two@example.invalid',now(),now());
select set_config('request.jwt.claim.sub','ef440000-0000-4000-8000-000000000002',true);
select public.xian_action('create','{"name":"Defender","map":"bamboo"}',gen_random_uuid())->'state'->>'name';
update xian_private.players set state=state||jsonb_build_object('shield',0,'army','[10,4,2]'::jsonb,'jobs',jsonb_build_array(
 jsonb_build_object('type',0,'finish',0),jsonb_build_object('type',1,'finish',0),jsonb_build_object('type',2,'finish',0))) where user_id='ef440000-0000-4000-8000-000000000002';
select set_config('request.jwt.claim.sub','ef440000-0000-4000-8000-000000000001',true);
select public.xian_action('create','{"name":"Attacker","map":"bamboo"}',gen_random_uuid())->'state'->>'name';
-- Deliberately stale scouting data cannot override the authoritative garrison.
update xian_private.players set state=state||'{"army":[2,0,0],"scout":{"name":"Defender","player":"ef440000-0000-4000-8000-000000000002","defense":1,"water":999999,"rice":999999,"stone":999999}}'::jsonb where user_id='ef440000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ declare r jsonb; req uuid:=gen_random_uuid(); saved jsonb; begin
 r:=public.xian_action('raid_start','{}',req);
 assert r->'state'->'raid'->'enemy'->'garrison'='[5,2,1]'::jsonb;
 assert (r->'state'->'raid'->'enemy'->>'garrison_power')::int=505;
 assert (r->'state'->'raid'->>'ratio')::numeric<0.2,'Defenders did not affect combat';
 saved:=r->'state'->'raid';r:=public.xian_action('raid_start','{}',req);
 assert r->'state'->'raid'=saved,'Duplicate raid changed combat';
end $$;
reset role;
do $$ declare s jsonb; begin
 select state into s from xian_private.players where user_id='ef440000-0000-4000-8000-000000000002';
 assert s->'army'='[11,5,3]'::jsonb,'Defending units must remain in roster';
 assert s->'jobs'='[]'::jsonb,'Completed jobs must be removed once';
 assert s->'last_defense'->'garrison'='[5,2,1]'::jsonb;
 assert s->'last_defense'->'army'='[2,0,0]'::jsonb;
 assert (s->'last_defense'->>'finish')::bigint-(s->'last_defense'->>'time')::bigint=25;
end $$;
select set_config('request.jwt.claim.sub','ef440000-0000-4000-8000-000000000002',true);
set local role authenticated;
do $$ declare r jsonb; begin
 r:=public.xian_action('sync','{}',gen_random_uuid());
 assert r->'state'->'army'='[11,5,3]'::jsonb,'Jobs counted twice';
end $$;
reset role;
select 'XIAN_GARRISON_PASSED' as result;
rollback;
