begin;
insert into auth.users(id,aud,role,email,created_at,updated_at) values
('ef410000-0000-4000-8000-000000000001','authenticated','authenticated','xian-v41@example.invalid',now(),now());
select set_config('request.jwt.claim.sub','ef410000-0000-4000-8000-000000000001',true);
select public.xian_action('create','{"name":"ช่างทดสอบ","map":"bamboo"}',gen_random_uuid());
update xian_private.players set state=state||jsonb_build_object('jade',20000,'builders_v41',false,'buildings',(state->'buildings')||'[{"id":"dorm","level":3,"finish":0,"x":2,"y":2}]'::jsonb) where user_id='ef410000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ declare r jsonb; j int; before_j int:=20000; prices int[]:=array[250,500,1000,2000,3500,5000]; failed boolean; request uuid; begin
 r:=public.xian_action('sync','{}',gen_random_uuid());
 assert jsonb_array_length(r->'state'->'retired_dorms')=1;
 assert jsonb_array_length(r->'state'->'buildings')=2;
 assert not exists(select 1 from jsonb_array_elements(r->'catalog') c where c->>'id'='dorm');
 assert (r->'capacity'->>'workers')::int=1;
 for j in 1..6 loop
  request:=gen_random_uuid();
  r:=public.xian_action('build',jsonb_build_object('type','servant','x',j,'y',0),request);
  before_j:=before_j-prices[j];
  assert (r->'state'->>'jade')::int=before_j;
  assert (r->'capacity'->>'workers')::int=j+1;
  assert (r->'state'->>'water')::numeric=650 and (r->'state'->>'rice')::numeric=650;
  r:=public.xian_action('build',jsonb_build_object('type','servant','x',j,'y',0),request);
  assert (r->'state'->>'jade')::int=before_j;
 end loop;
 failed:=false;begin perform public.xian_action('build','{"type":"servant","x":0,"y":0}',gen_random_uuid());exception when others then failed:=true;end;assert failed,'Eighth shed accepted';
 failed:=false;begin perform public.xian_action('upgrade','{"index":1}',gen_random_uuid());exception when others then failed:=true;end;assert failed,'Builder upgraded';
 failed:=false;begin perform public.xian_action('build','{"type":"dorm","x":0,"y":1}',gen_random_uuid());exception when others then failed:=true;end;assert failed,'Dorm accepted';
 r:=public.xian_action('ghost_begin','{"level":1}',gen_random_uuid());
 failed:=false;begin perform public.xian_action('ghost_win',jsonb_build_object('level',1,'ticket',r->'state'->'ghost_ticket'->>'id'),gen_random_uuid());exception when others then failed:=true;end;assert failed,'Instant victory accepted';
 failed:=false;begin perform public.xian_action('ghost_win',jsonb_build_object('level',1,'ticket',gen_random_uuid()),gen_random_uuid());exception when others then failed:=true;end;assert failed,'Wrong ticket accepted';
end $$;
reset role;
update xian_private.players set state=jsonb_set(state,'{ghost_ticket,start}',to_jsonb(floor(extract(epoch from now()))::bigint-30)) where user_id='ef410000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ declare r jsonb; ticket text; before_j int; req uuid:=gen_random_uuid(); begin
 r:=public.xian_action('sync','{}',gen_random_uuid());ticket:=r->'state'->'ghost_ticket'->>'id';before_j:=(r->'state'->>'jade')::int;
 r:=public.xian_action('ghost_win',jsonb_build_object('level',1,'ticket',ticket),req);
 assert (r->'state'->>'jade')::int=before_j+2 and (r->'state'->>'ghost_wins')::int=1;
 r:=public.xian_action('ghost_win',jsonb_build_object('level',1,'ticket',ticket),req);
 r:=public.xian_action('ghost_win',jsonb_build_object('level',1,'ticket',ticket),gen_random_uuid());
 assert (r->'state'->>'jade')::int=before_j+2,'Duplicate native reward';
 assert (r->>'checkin_available')::boolean;
 r:=public.xian_action('checkin','{}',gen_random_uuid());
 assert not (r->>'checkin_available')::boolean;
 assert (r->'state'->>'jade')::int=before_j+7;
end $$;
reset role;
select 'XIAN_BUILDERS_GIFTS_PASSED' as result;
rollback;
