begin;
insert into auth.users(id,aud,role,email,created_at,updated_at) values
('ef110000-0000-4000-8000-000000000036','authenticated','authenticated','xian-courtyard@example.invalid',now(),now());
select set_config('request.jwt.claim.sub','ef110000-0000-4000-8000-000000000036',true);
select public.xian_action('create','{"name":"ทดสอบลานฝึก","map":"bamboo"}',gen_random_uuid())->'capacity';
-- Legacy courtyard at the edge, with a neighboring building. Preserve both.
update xian_private.players set state=state||jsonb_build_object('buildings',state->'buildings'||'[
{"id":"training","x":15,"y":15,"level":1,"finish":0},
{"id":"recruit","x":14,"y":15,"level":1,"finish":0},
{"id":"dorm","x":13,"y":15,"level":10,"finish":0},
{"id":"barracks","x":12,"y":15,"level":1,"finish":0}
]'::jsonb,'army','[21,0,0]'::jsonb) where user_id=auth.uid();
set local role authenticated;
do $$ declare r jsonb; b jsonb; failed bool:=false; begin
 r:=public.xian_action('sync','{}',gen_random_uuid());b:=r->'state'->'buildings'->2;
 assert (b->>'size')::int=2 and (b->>'x')::int<=14 and (b->>'y')::int<=14,'Legacy footprint not migrated';
 assert (r->'state'->'buildings'->3->>'x')::int=14,'Neighbor moved';
 assert (r->'capacity'->>'army')::int=20,'Courtyard capacity incorrect';
 assert r->'state'->'army'='[21,0,0]'::jsonb,'Existing troops lost';
 begin perform public.xian_action('train','{"type":0}',gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'Over-cap training allowed';
 failed:=false;
 begin perform public.xian_action('move',jsonb_build_object('index',3,'x',(b->>'x')::int+1,'y',(b->>'y')::int+1),gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'Second courtyard cell not protected';
 failed:=false;
 begin perform public.xian_action('move','{"index":2,"x":15,"y":0}',gen_random_uuid()); exception when others then failed:=true;end;
 assert failed,'Courtyard can cross boundary';
 r:=public.xian_action('move','{"index":2,"x":0,"y":0}',gen_random_uuid());
 assert r->'state'->'buildings'->2->>'x'='0';
end $$;
reset role;
update xian_private.players set state=jsonb_set(state,'{buildings,2,level}','2') where user_id=auth.uid();
set local role authenticated;
do $$ declare r jsonb; begin
 r:=public.xian_action('sync','{}',gen_random_uuid());assert (r->'capacity'->>'army')::int=40;
 r:=public.xian_action('train','{"type":0}',gen_random_uuid());assert jsonb_array_length(r->'state'->'jobs')=1;
end $$;
reset role;
-- An entirely full old board must remain intact rather than deleting neighbors.
do $$ declare bs jsonb:='[]';x int;y int;r jsonb; begin
 for x in 0..15 loop for y in 0..15 loop
 bs:=bs||jsonb_build_array(jsonb_build_object('id',case when x=0 and y=0 then 'training' else 'wall' end,'x',x,'y',y,'level',1,'finish',0));
 end loop;end loop;
 update xian_private.players set state=jsonb_set(state,'{buildings}',bs) where user_id=auth.uid();
 r:=public.xian_action('sync','{}',gen_random_uuid());
 assert jsonb_array_length(r->'state'->'buildings')=256;
 assert r->'state'->'buildings'->0->>'size'='1','Packed-base fallback failed';
end $$;
select 'XIAN_COURTYARD_TESTS_PASSED' as result;
rollback;
