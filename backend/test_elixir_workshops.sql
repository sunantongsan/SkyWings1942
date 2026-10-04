begin;
insert into auth.users(id,aud,role,email,created_at,updated_at) values
('ef110000-0000-4000-8000-000000000039','authenticated','authenticated','xian-workshops@example.invalid',now(),now());
select set_config('request.jwt.claim.sub','ef110000-0000-4000-8000-000000000039',true);
select public.xian_action('create','{"name":"ทดสอบโอสถ","map":"bamboo"}',gen_random_uuid());
update xian_private.players set state=state||jsonb_build_object('buildings','[
{"id":"hall","x":7,"y":7,"level":3,"finish":0},
{"id":"servant","x":5,"y":7,"level":1,"finish":0},
{"id":"training","x":1,"y":1,"size":2,"level":1,"finish":0},
{"id":"recruit","x":5,"y":5,"level":1,"finish":0},
{"id":"spring","x":4,"y":4,"level":2,"finish":0},
{"id":"crystal","x":6,"y":4,"level":2,"finish":0}
]'::jsonb,'army','[2,1,0]'::jsonb,'jobs',jsonb_build_array(jsonb_build_object('type',0,'finish',floor(extract(epoch from now()))+100)),'stone',100,'water',1000,'rice',1000,'last_tick',floor(extract(epoch from now()))-100)
where user_id=auth.uid();
set local role authenticated;
do $$ declare r jsonb;failed bool:=false;begin
 r:=public.xian_action('sync','{}',gen_random_uuid());
 assert r->'state'->'army'='[2,1,0]'::jsonb,'Existing troops changed';
 assert jsonb_array_length(r->'state'->'jobs')=1,'Existing queue lost';
 assert (r->'state'->>'stone')::numeric=108,'Furnace production changed';
 assert (r->'capacity'->>'stone')::int=1100,'Pouch capacity changed';
 assert (r->'capacity'->>'army')::int=20,'Courtyard capacity changed';
 begin perform public.xian_action('train','{"type":0}',gen_random_uuid());exception when others then failed:=sqlerrm='สร้างหอฝึกนักสู้ก่อน';end;
 assert failed,'Old gate/yard must not produce troops';
 r:=public.xian_action('build','{"type":"barracks","x":10,"y":10}',gen_random_uuid());
 assert r->'state'->'buildings'->6->>'id'='barracks';
 failed:=false;
 begin perform public.xian_action('train','{"type":0}',gen_random_uuid());exception when others then failed:=true;end;
 assert failed,'Unfinished barracks may not produce';
end $$;
reset role;
update xian_private.players set state=jsonb_set(jsonb_set(state,'{buildings,6,level}','1'),'{buildings,6,finish}','0') where user_id=auth.uid();
set local role authenticated;
do $$ declare r jsonb;failed bool:=false;req uuid:=gen_random_uuid();begin
 r:=public.xian_action('train','{"type":0}',req);assert jsonb_array_length(r->'state'->'jobs')=2;
 r:=public.xian_action('train','{"type":0}',req);assert jsonb_array_length(r->'state'->'jobs')=2,'Retry duplicates production';
 begin perform public.xian_action('train','{"type":1}',gen_random_uuid());exception when others then failed:=true;end;
 assert failed,'Barracks level 1 unlocked advanced troop';
end $$;
reset role;
update xian_private.players set state=jsonb_set(state,'{buildings,6,level}','3') where user_id=auth.uid();
set local role authenticated;
do $$ declare r jsonb;begin
 r:=public.xian_action('train','{"type":1}',gen_random_uuid());
 r:=public.xian_action('train','{"type":2}',gen_random_uuid());
 assert jsonb_array_length(r->'state'->'jobs')=4,'Barracks level unlock failed';
 assert (r->'capacity'->>'army')::int=20,'Barracks incorrectly adds capacity';
end $$;
reset role;
do $$ begin
 assert xian_private.pill_fill('{"stone":300,"buildings":[{"id":"crystal","level":1}]}'::jsonb)=0.5;
 assert xian_private.pill_fill('{"stone":0,"buildings":[]}'::jsonb)=0;
 assert xian_private.pill_fill('{"stone":1000,"buildings":[]}'::jsonb)=1;
end $$;
select 'XIAN_ELIXIR_WORKSHOPS_PASSED' as result;
rollback;
