begin;
insert into auth.users(id,aud,role,email,created_at,updated_at) values
('ef450000-0000-4000-8000-000000000001','authenticated','authenticated','v45-fixture@example.invalid',now(),now());
select set_config('request.jwt.claim.sub','ef450000-0000-4000-8000-000000000001',true);
select public.xian_action('create','{"name":"ทดสอบสิบขั้น","map":"bamboo"}',gen_random_uuid());
update xian_private.players set state=state||jsonb_build_object('water',15000000,'rice',15000000,'stone',15000000,'army','[1,2,3]'::jsonb,'buildings','[
{"id":"hall","x":7,"y":7,"level":10,"finish":0},
{"id":"servant","x":5,"y":7,"level":1,"finish":0},
{"id":"tank","x":1,"y":1,"level":10,"finish":0},
{"id":"granary","x":2,"y":1,"level":10,"finish":0},
{"id":"crystal","x":3,"y":1,"level":10,"finish":0},
{"id":"training","x":10,"y":10,"size":2,"level":10,"finish":0},
{"id":"barracks","x":4,"y":1,"level":9,"finish":0},
{"id":"wall","x":2,"y":3,"level":1,"finish":0},
{"id":"wall","x":3,"y":3,"level":2,"finish":0},
{"id":"wall","x":4,"y":3,"level":10,"finish":0},
{"id":"wall","x":8,"y":3,"level":1,"finish":0}
]'::jsonb) where user_id=auth.uid();
do $$ declare r jsonb;s jsonb;sig text;req uuid;bad bool;kind int;begin
 assert xian_private.barracks_price(10)=10000000;
 assert xian_private.storage_capacity('crystal',9)>=10000000;
 assert xian_private.garrison('{"army":[3,3,3,3,3,3,3,3,3,3],"jobs":[{"type":9,"finish":1}]}',2)='[1,1,1,1,1,1,1,1,1,2]'::jsonb;
 r:=public.xian_action('sync','{}',gen_random_uuid());assert r->'state'->'army'='[1,2,3,0,0,0,0,0,0,0]'::jsonb;
 bad:=false;begin perform public.xian_action('train','{"type":9}',gen_random_uuid());exception when others then bad:=true;end;assert bad,'Level ten unit unlocked early';
 r:=public.xian_action('upgrade','{"index":6}',gen_random_uuid());
 assert (r->'state'->>'water')::numeric=5000000 and (r->'state'->>'rice')::numeric=5000000 and (r->'state'->>'stone')::numeric=5000000,'Upgrade must cost 10M EACH';
 update xian_private.players set state=jsonb_set(state,'{buildings,6,finish}',to_jsonb(floor(extract(epoch from now()))::bigint-1)) where user_id=auth.uid();
 r:=public.xian_action('sync','{}',gen_random_uuid());assert r->'state'->'buildings'->6->>'level'='10';
 for kind in 0..9 loop r:=public.xian_action('train',jsonb_build_object('type',kind),gen_random_uuid());end loop;
 assert jsonb_array_length(r->'state'->'jobs')=10;
 sig:='7:2:3:1,8:3:3:2,9:4:3:10,10:8:3:1';req:=gen_random_uuid();s:=r->'state';
 r:=public.xian_action('wall_manage',jsonb_build_object('index',7,'scope','row','operation','upgrade','signature',sig),req);
 assert (s->>'water')::numeric-(r->'state'->>'water')::numeric=30;
 assert r->'state'->'buildings'->7->>'level'='2' and r->'state'->'buildings'->8->>'level'='3' and r->'state'->'buildings'->9->>'level'='10' and r->'state'->'buildings'->10->>'level'='1';s:=r->'state';
 r:=public.xian_action('wall_manage',jsonb_build_object('index',7,'scope','row','operation','upgrade','signature',sig),req);assert r->'state'=s,'Duplicate charges';
 bad:=false;begin perform public.xian_action('wall_manage',jsonb_build_object('index',7,'scope','all','operation','delete','signature',sig),gen_random_uuid());exception when others then bad:=true;end;assert bad,'Stale deletion accepted';
 sig:='7:2:3:2,8:3:3:3,9:4:3:10,10:8:3:1';
 r:=public.xian_action('wall_manage',jsonb_build_object('index',10,'scope','one','operation','delete','signature',sig),gen_random_uuid());assert jsonb_array_length(r->'state'->'buildings')=10;
 sig:='7:2:3:2,8:3:3:3,9:4:3:10';
 r:=public.xian_action('wall_manage',jsonb_build_object('index',7,'scope','all','operation','delete','signature',sig),gen_random_uuid());assert jsonb_array_length(r->'state'->'buildings')=7;assert r->'state'->'buildings'->0->>'id'='hall';
end $$;
select 'XIAN_TEN_TROOPS_WALLS_PASSED' as result;
rollback;
