-- Guard deployed dispatcher/catalog so unrelated updates cannot be overwritten.
DO $$ BEGIN
 IF md5(pg_get_functiondef('xian_private.act(text,jsonb,uuid)'::regprocedure)) <> 'fa1f0a726ee33d806d69f6f555351491'
 OR md5(pg_get_functiondef('xian_private.catalog()'::regprocedure)) <> '8289914340c78f04a296d3571c202ee9'
 THEN RAISE EXCEPTION 'Live functions changed: review before applying';END IF;
END $$;
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
CREATE OR REPLACE FUNCTION xian_private.catalog()
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
select '[
{"id":"hall","name":"สำนักหลัก","water":100,"rice":100,"stone":10,"seconds":30,"limit":1},
{"id":"well","name":"บ่อน้ำ","water":0,"rice":80,"stone":0,"seconds":10,"limit":3},
{"id":"kitchen","name":"โรงเตี๊ยม","water":80,"rice":0,"stone":0,"seconds":10,"limit":3},
{"id":"tank","name":"ถังเก็บน้ำ","water":40,"rice":60,"stone":0,"seconds":15,"limit":3},
{"id":"granary","name":"ปิ่นโตข้าว","water":60,"rice":40,"stone":0,"seconds":15,"limit":3},
{"id":"spring","name":"เตาหลอมโอสถ","water":100,"rice":100,"stone":0,"seconds":30,"limit":2},
{"id":"crystal","name":"ถุงโอสถเซียน","water":80,"rice":80,"stone":5,"seconds":20,"limit":2},
{"id":"servant","name":"เพิงช่าง","water":0,"rice":0,"stone":0,"seconds":0,"limit":7,"jade_prices":[0,250,500,1000,2000,3500,5000],"upgradable":false},

{"id":"barracks","name":"หอฝึกนักสู้","water":120,"rice":140,"stone":10,"seconds":30,"limit":5,"unlock_levels":[1,3,5,7,9]},
{"id":"training","name":"ลานฝึกกระบี่","water":100,"rice":100,"stone":10,"seconds":30,"limit":1},
{"id":"tower","name":"หอคอยธนู","water":80,"rice":80,"stone":10,"seconds":20,"limit":8},
{"id":"ward","name":"หอค่ายกล","water":150,"rice":150,"stone":30,"seconds":60,"limit":4},
{"id":"trap_storm","name":"ค่ายกลพายุ","water":200,"rice":160,"stone":30,"seconds":45,"limit":3,"hall_required":2},
{"id":"trap_sword","name":"ค่ายกลกระบี่","water":240,"rice":200,"stone":40,"seconds":60,"limit":3,"hall_required":3},
{"id":"trap_fire","name":"ค่ายกลไฟ","water":280,"rice":240,"stone":50,"seconds":75,"limit":3,"hall_required":4},
{"id":"lightning","name":"ป้อมสายฟ้า","water":500,"rice":400,"stone":100,"seconds":120,"limit":4,"hall_required":4},
{"id":"wall","name":"กำแพง","water":5,"rice":5,"stone":0,"seconds":0,"limit":80}
]'::jsonb $function$;
CREATE OR REPLACE FUNCTION xian_private.act(p_action text, p_args jsonb, p_request uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 producer text; first_producer text; producer_level int; producer_paused bool; queue_jobs jsonb; queue_new jsonb; queue_tail bigint; queue_skip bigint; refund jsonb; battle_effects jsonb; reward_jade int; uid uuid:=auth.uid(); s jsonb; b jsonb; bs jsonb; c jsonb; item jsonb;
 t bigint:=floor(extract(epoch from now())); old_t bigint; elapsed bigint;
 water numeric; rice numeric; stone numeric; wc int:=1000; rc int:=1000; sc int:=100;
 wr numeric:=0; rr numeric:=0; sr numeric:=0; hall int:=1; workers int:=0; busy int:=0; cap int:=10;
 wall_indices int[]; other_bs jsonb; endx int; endy int; nx int; ny int; axis int; ox int; oy int; op text; width int; candidate record; idx int; j int; k int; n int; lev int; duration int; qty int; typ text; posx int; posy int;
 cw int; cr int; cs int; count_type int; worker_max int; jade_cost int; army jsonb; jobs jsonb:='[]'; job jsonb;
 board int[]; marked int[]; a int; z int; tmp int; score int; moves int; casc int; changed bool;
 match_state jsonb; day text:=to_char(now() at time zone 'Asia/Bangkok','YYYY-MM-DD');
 result jsonb; power numeric; defense numeric; ratio numeric; raid jsonb; opponent jsonb; defender uuid; ds jsonb; report jsonb; guards jsonb; loot_w int; loot_r int; loot_s int;
begin
 if uid is null then raise exception 'กรุณาเข้าสู่ระบบ'; end if;
 if p_action is null or p_args is null or p_request is null then raise exception 'คำขอไม่ครบ'; end if;
 if octet_length(p_args::text)>4096 then raise exception 'คำขอใหญ่เกินไป'; end if;
 perform pg_advisory_xact_lock(hashtextextended(uid::text,741));
 select state into s from xian_private.players where user_id=uid for update;
 if s is null then
  if p_action<>'create' then return jsonb_build_object('needs_create',true,'catalog',xian_private.catalog(),'server_time',t); end if;
  if p_args->>'name' is null or p_args->>'map' is null or length(trim(p_args->>'name')) not between 2 and 24 or p_args->>'map' not in ('bamboo','mountain') then raise exception 'ตั้งชื่อ 2–24 ตัวอักษรและเลือกทำเล'; end if;
  s:=jsonb_build_object('name',trim(p_args->>'name'),'map',p_args->>'map','water',650,'rice',650,'stone',60,'jade',20,
    'last_tick',t,'buildings',jsonb_build_array(
    jsonb_build_object('id','hall','x',7,'y',7,'level',1,'finish',0),
    jsonb_build_object('id','servant','x',5,'y',7,'level',1,'finish',0)),
    'army','[0,0,0,0,0,0,0,0,0,0]'::jsonb,'jobs','[]'::jsonb,'wins',0,'match_level',1,'shield',t+86400);
  insert into xian_private.players(user_id,state) values(uid,s);
 end if;

 -- Stable producer IDs survive moves, wall deletion and legacy layout normalization.
 bs:='[]'::jsonb;
 for b in select value from jsonb_array_elements(s->'buildings') loop
  if b->>'id'='barracks' and not b ? 'uid' then b:=b||jsonb_build_object('uid',gen_random_uuid());end if;
  if b->>'id'='barracks' and first_producer is null then first_producer:=b->>'uid';end if;
  bs:=bs||jsonb_build_array(b);
 end loop;
 s:=jsonb_set(s,'{buildings}',bs);queue_jobs:='[]'::jsonb;
 for job in select value from jsonb_array_elements(s->'jobs') loop
  if not job ? 'id' then job:=job||jsonb_build_object('id',gen_random_uuid());end if;
  if not job ? 'producer' then job:=job||jsonb_build_object('producer',first_producer);end if;
  queue_jobs:=queue_jobs||jsonb_build_array(job);
 end loop;
 s:=jsonb_set(s,'{jobs}',queue_jobs);
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

 -- Existing builders are grandfathered (no paid buildings are deleted); new cap is seven.
 if not coalesce((s->>'builders_v41')::boolean,false) then
  if p_action in ('upgrade','move','boost','wall_edit') and exists(select 1 from jsonb_array_elements(s->'buildings') v where v->>'id'='dorm') then
   raise exception 'ฐานมีการปรับปรุง กรุณาอัปเดตข้อมูลแล้วเลือกอาคารใหม่';
  end if;
  select coalesce(jsonb_agg(v),'[]'::jsonb) into other_bs from jsonb_array_elements(s->'buildings') v where v->>'id'='dorm';
  select coalesce(jsonb_agg(case when v->>'id'='servant' then v||'{"level":1,"finish":0}'::jsonb else v end order by i),'[]'::jsonb)
   into bs from jsonb_array_elements(s->'buildings') with ordinality q(v,i) where v->>'id'<>'dorm';
  s:=s||jsonb_build_object('buildings',bs,'retired_dorms',other_bs,'builders_v41',true);
 end if;
 -- Expand legacy training yards atomically under the player lock.
 bs:=s->'buildings';
 for idx in 0..jsonb_array_length(bs)-1 loop
  b:=bs->idx;
  if b->>'id'='training' and coalesce((b->>'size')::int,1)<2 then
   b:=b||'{"size":1}'::jsonb;
   for candidate in select x,y from generate_series(0,14) x cross join generate_series(0,14) y
      order by abs(x-(b->>'x')::int)+abs(y-(b->>'y')::int),x,y loop
    if xian_private.free_plot(bs,candidate.x,candidate.y,2,idx) then
     b:=b||jsonb_build_object('x',candidate.x,'y',candidate.y,'size',2);exit;
    end if;
   end loop;
   bs:=jsonb_set(bs,array[idx::text],b);
  end if;
 end loop;
 s:=jsonb_set(s,'{buildings}',bs);
 -- Settle completions first. New producers only accrue after their finish timestamp.
 old_t:=(s->>'last_tick')::bigint; elapsed:=greatest(0,least(28800,t-old_t));
 bs:='[]';
 for b in select value from jsonb_array_elements(s->'buildings') loop
  lev:=(b->>'level')::int;
  if coalesce((b->>'finish')::bigint,0)>0 and (b->>'finish')::bigint<=t then
   lev:=lev+1; b:=b||jsonb_build_object('level',lev,'finish',0);
  end if;
  bs:=bs||jsonb_build_array(b);
  if (b->>'finish')::bigint>t and b->>'id'<>'wall' then busy:=busy+1; end if;
  if lev>0 then
   case b->>'id'
   when 'hall' then hall:=lev;
   when 'servant' then workers:=workers+1;
   when 'training' then cap:=lev*20;
   when 'tank' then wc:=wc+xian_private.storage_capacity('tank',lev);
   when 'granary' then rc:=rc+xian_private.storage_capacity('granary',lev);
   when 'crystal' then sc:=sc+xian_private.storage_capacity('crystal',lev);
   when 'well' then wr:=wr+xian_private.production_rate('well',lev);
   when 'kitchen' then rr:=rr+xian_private.production_rate('kitchen',lev);
   when 'spring' then sr:=sr+xian_private.production_rate('spring',lev);
   else null; end case;
  end if;
 end loop;
 -- Production is only granted for buildings that existed at the previous sync.
 for b in select value from jsonb_array_elements(s->'buildings') loop
  if (b->>'finish')::bigint>0 and (b->>'finish')::bigint<=t then
   case b->>'id' when 'well' then wr:=wr-(xian_private.production_rate('well',(b->>'level')::int+1)-xian_private.production_rate('well',(b->>'level')::int))*greatest(0,least(elapsed,(b->>'finish')::bigint-old_t))::numeric/greatest(1,elapsed);
   when 'kitchen' then rr:=rr-(xian_private.production_rate('kitchen',(b->>'level')::int+1)-xian_private.production_rate('kitchen',(b->>'level')::int))*greatest(0,least(elapsed,(b->>'finish')::bigint-old_t))::numeric/greatest(1,elapsed);
   when 'spring' then sr:=sr-(xian_private.production_rate('spring',(b->>'level')::int+1)-xian_private.production_rate('spring',(b->>'level')::int))*greatest(0,least(elapsed,(b->>'finish')::bigint-old_t))::numeric/greatest(1,elapsed);
   else null; end case;
  end if;
 end loop;
 water:=least(wc,round((s->>'water')::numeric+elapsed*wr,4)); rice:=least(rc,round((s->>'rice')::numeric+elapsed*rr,4)); stone:=least(sc,round((s->>'stone')::numeric+elapsed*sr,4));
 army:=s->'army';
 for idx in 0..9 loop
  if army->idx is null then army:=army||'0'::jsonb;end if;
 end loop;
 for job in select value from jsonb_array_elements(s->'jobs') loop
  if not coalesce((job->>'paused')::boolean,false) and (job->>'finish')::bigint<=t then
   idx:=(job->>'type')::int; army:=jsonb_set(army,array[idx::text],to_jsonb((army->>idx)::int+1));
  else jobs:=jobs||jsonb_build_array(job); end if;
 end loop;
 s:=s||jsonb_build_object('buildings',bs,'army',army,'jobs',jobs,'last_tick',t,'water',water,'rice',rice,'stone',stone);

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
 -- Canceled production refunds remain in reserve if storage is full.
 foreach typ in array array['water','rice','stone'] loop
  n:=case typ when 'water' then wc when 'rice' then rc else sc end;
  qty:=least(greatest(0,n-floor((s->>typ)::numeric)::int),coalesce((s->'train_refund'->>typ)::int,0));
  if qty>0 then
   s:=jsonb_set(s,array[typ],to_jsonb((s->>typ)::numeric+qty));
   s:=jsonb_set(s,array['train_refund',typ],to_jsonb((s->'train_refund'->>typ)::int-qty));
  end if;
 end loop;
 water:=(s->>'water')::numeric;rice:=(s->>'rice')::numeric;stone:=(s->>'stone')::numeric;
 worker_max:=7;

 if exists(select 1 from xian_private.receipts where user_id=uid and request_id=p_request) then p_action:='sync'; end if;
 reward_jade:=xian_private.match_reward_amount();
 s:=s||jsonb_build_object('match_reward_jade',reward_jade);
 -- Only the owner's request starts the single shared repair clock, after combat finishes.
 if coalesce((s->>'repair_pending')::boolean,false) and coalesce((s->'last_defense'->>'finish')::bigint,0)<=t then
  if not s ? 'repair_until' then s:=s||jsonb_build_object('repair_until',t+20);end if;
  if (s->>'repair_until')::bigint<=t then s:=s-'repair_pending'-'repair_until';end if;
 end if;
 if coalesce((s->>'repair_pending')::boolean,false) and p_action in ('build','upgrade','move','boost','wall_edit','wall_manage','wall_line','raid_start') then
  raise exception 'สำนักกำลังถูกบุกหรือซ่อมแซม กรุณารอสักครู่';
 end if;
 if p_action='wall_manage' then
  if s ? 'raid' then raise exception 'จบการบุกก่อนจัดฐาน';end if;
  idx:=(p_args->>'index')::int;op:=p_args->>'operation';typ:=p_args->>'scope';
  if idx is null or idx<0 or idx>=jsonb_array_length(bs) or bs->idx->>'id'<>'wall' then raise exception 'เลือกกำแพงก่อน';end if;
  if op is null or op not in ('delete','upgrade') or typ is null or typ not in ('one','row','all') then raise exception 'คำสั่งกำแพงไม่ถูกต้อง';end if;
  if p_args->>'signature' is distinct from (select string_agg((i-1)::text||':'||(v->>'x')||':'||(v->>'y')||':'||(v->>'level'),',' order by i) from jsonb_array_elements(bs) with ordinality q(v,i) where v->>'id'='wall') then raise exception 'ฐานเปลี่ยนแล้ว กรุณาเลือกกำแพงใหม่';end if;
  if typ='one' then wall_indices:=array[idx];
  elsif typ='row' then wall_indices:=xian_private.wall_run(bs,idx);
  else select array_agg((i-1)::int) into wall_indices from jsonb_array_elements(bs) with ordinality q(v,i) where v->>'id'='wall';end if;
  if op='delete' then
   select coalesce(jsonb_agg(v order by i),'[]'::jsonb) into bs from jsonb_array_elements(bs) with ordinality q(v,i) where not ((i-1)::int=any(wall_indices));
  else
   cw:=0;qty:=0;
   foreach j in array wall_indices loop
    lev:=(bs->j->>'level')::int;
    if lev<10 and lev<hall+1 then cw:=cw+5*power(2,lev)::int;qty:=qty+1;end if;
   end loop;
   if qty=0 then raise exception 'กำแพงที่เลือกถึงระดับสูงสุดแล้ว';end if;
   if water<cw or rice<cw then raise exception 'ทรัพยากรไม่พอสำหรับกำแพงที่เลือก';end if;
   foreach j in array wall_indices loop
    lev:=(bs->j->>'level')::int;
    if lev<10 and lev<hall+1 then bs:=jsonb_set(bs,array[j::text,'level'],to_jsonb(lev+1));end if;
   end loop;
   s:=s||jsonb_build_object('water',water-cw,'rice',rice-cw);
  end if;
  s:=jsonb_set(s,'{buildings}',bs);
 elsif p_action='wall_line' then
  if s ? 'raid' then raise exception 'จบการบุกก่อนจัดฐาน';end if;
  posx:=(p_args->>'x')::int;posy:=(p_args->>'y')::int;endx:=(p_args->>'end_x')::int;endy:=(p_args->>'end_y')::int;
  if posx is null or posy is null or endx is null or endy is null or least(posx,posy,endx,endy)<0 or greatest(posx,posy,endx,endy)>15 then raise exception 'อยู่นอกพื้นที่สร้าง';end if;
  if posx<>endx and posy<>endy then raise exception 'ลากกำแพงเป็นแนวตรง';end if;
  qty:=greatest(abs(endx-posx),abs(endy-posy))+1;
  axis:=case when posy<>endy then 1 when posx<>endx then 0 else coalesce((p_args->>'rotation')::int,0) end;
  if axis not in (0,1) then raise exception 'แนวกำแพงไม่ถูกต้อง';end if;
  select count(*) into count_type from jsonb_array_elements(bs) where value->>'id'='wall';
  if count_type+qty>80 then raise exception 'สร้างกำแพงได้ไม่เกิน 80 ช่อง';end if;
  if water<qty*5 or rice<qty*5 then raise exception 'ทรัพยากรไม่พอสำหรับทั้งแนว';end if;
  for j in 0..qty-1 loop
   nx:=posx+sign(endx-posx)::int*j;ny:=posy+sign(endy-posy)::int*j;
   if not xian_private.free_plot(bs,nx,ny,1,-1) then raise exception 'แนวกำแพงชนอาคาร กรุณาเลือกพื้นที่ว่าง';end if;
   bs:=bs||jsonb_build_array(jsonb_build_object('id','wall','x',nx,'y',ny,'rotation',axis,'size',1,'level',1,'finish',0));
  end loop;
  s:=s||jsonb_build_object('buildings',bs,'water',water-qty*5,'rice',rice-qty*5);
 elsif p_action='wall_edit' then
  if s ? 'raid' then raise exception 'จบการบุกก่อนจัดฐาน';end if;
  idx:=(p_args->>'index')::int;op:=p_args->>'operation';
  if op is null or op not in ('rotate','move') then raise exception 'คำสั่งกำแพงไม่ถูกต้อง';end if;
  wall_indices:=xian_private.wall_run(bs,idx);b:=bs->idx;ox:=(b->>'x')::int;oy:=(b->>'y')::int;
  posx:=(p_args->>'x')::int;posy:=(p_args->>'y')::int;
  if op='move' and (posx is null or posy is null) then raise exception 'เลือกตำแหน่งใหม่';end if;
  axis:=coalesce((b->>'rotation')::int,0)%2;
  if cardinality(wall_indices)>1 then axis:=case when (bs->wall_indices[2]->>'x')::int=ox then 1 else 0 end;end if;
  select coalesce(jsonb_agg(v order by i),'[]'::jsonb) into other_bs from jsonb_array_elements(bs) with ordinality q(v,i) where not (i-1=any(wall_indices));
  foreach j in array wall_indices loop
   b:=bs->j;
   if op='rotate' then nx:=ox-((b->>'y')::int-oy);ny:=oy+((b->>'x')::int-ox);
   else nx:=(b->>'x')::int+posx-ox;ny:=(b->>'y')::int+posy-oy;end if;
   if not xian_private.free_plot(other_bs,nx,ny,1,-1) then raise exception 'หมุนหรือย้ายไม่ได้: แนวกำแพงชนอาคารหรือขอบพื้นที่';end if;
   b:=b||jsonb_build_object('x',nx,'y',ny);
   if op='rotate' then b:=b||jsonb_build_object('rotation',1-axis);end if;
   bs:=jsonb_set(bs,array[j::text],b);
  end loop;
  s:=jsonb_set(s,'{buildings}',bs);
 elsif p_action in ('build','upgrade','move') then
  if s ? 'raid' then raise exception 'จบการบุกก่อนจัดฐาน'; end if;
  if p_action='build' then
   typ:=p_args->>'type'; lev:=0;
   select value into c from jsonb_array_elements(xian_private.catalog()) where value->>'id'=typ;
   if c is null then raise exception 'ไม่มีอาคารนี้'; end if;
   if hall<coalesce((c->>'hall_required')::int,1) then raise exception 'ระดับสำนักหลักยังไม่ถึงที่กำหนด';end if;
   select count(*) into count_type from jsonb_array_elements(bs) where value->>'id'=typ;
   if count_type >= (case when typ='servant' then worker_max when typ='barracks' then least(5,(hall+1)/2) else (c->>'limit')::int end) then raise exception 'จำนวนอาคารถึงขีดจำกัดของสำนักแล้ว'; end if;
   idx:=jsonb_array_length(bs); b:=jsonb_build_object('id',typ,'level',0,'finish',0,'uid',gen_random_uuid());
  else
   idx:=(p_args->>'index')::int;
   if idx is null or idx<0 or idx>=jsonb_array_length(bs) then raise exception 'ไม่พบอาคาร'; end if;
   b:=bs->idx; typ:=b->>'id'; lev:=(b->>'level')::int;
   select value into c from jsonb_array_elements(xian_private.catalog()) where value->>'id'=typ;
  end if;
  if p_action in ('build','move') then
   posx:=(p_args->>'x')::int; posy:=(p_args->>'y')::int;
   width:=case when typ='training' then 2 else 1 end;
   if posx is null or posy is null or posx<0 or posy<0 or posx+width>16 or posy+width>16 then raise exception 'อยู่นอกพื้นที่สร้าง'; end if;
   if not xian_private.free_plot(bs,posx,posy,width,idx) then raise exception 'พื้นที่นี้มีอาคารแล้ว ต้องเว้นลานฝึก 2×2 ช่อง'; end if;
   b:=b||jsonb_build_object('x',posx,'y',posy,'size',width);
  end if;
  if typ='servant' and p_action='upgrade' then raise exception 'เพิงช่างอัปเกรดไม่ได้ สร้างเพิ่มด้วยหยกได้สูงสุด 7 หลัง';end if;
  if typ='servant' and p_action='build' then
   jade_cost:=(c->'jade_prices'->>count_type)::int;
   if (s->>'jade')::int<jade_cost then raise exception 'หยกไม่พอ ต้องใช้ % หยก',jade_cost;end if;
   b:=b||'{"level":1,"finish":0}'::jsonb;
   s:=jsonb_set(s,'{jade}',to_jsonb((s->>'jade')::int-jade_cost));workers:=workers+1;
  elsif p_action<>'move' then
   if (b->>'finish')::bigint>t then raise exception 'อาคารนี้กำลังก่อสร้าง'; end if;
   if lev>=10 or (typ<>'hall' and lev>=hall+1) then raise exception 'อัปเกรดสำนักหลักก่อน'; end if;
   if typ<>'wall' and busy>=workers then raise exception 'ช่างทำงานครบทุกคนแล้ว'; end if;
   cw:=(c->>'water')::int*power(2,lev); cr:=(c->>'rice')::int*power(2,lev); cs:=(c->>'stone')::int*power(2,lev);
   if typ='barracks' and lev>0 then cw:=xian_private.barracks_price(lev+1);cr:=cw;cs:=cw;end if;
   if water<cw or rice<cr or stone<cs then raise exception 'ทรัพยากรไม่พอ'; end if;
   duration:=least(28800,(c->>'seconds')::int*power(3,lev));
   b:=b||jsonb_build_object('finish',case when duration=0 then 0 else t+duration end,'level',case when duration=0 then lev+1 else lev end);
   s:=s||jsonb_build_object('water',water-cw,'rice',rice-cr,'stone',stone-cs);
  end if;
  if p_action='build' then bs:=bs||jsonb_build_array(b); else bs:=jsonb_set(bs,array[idx::text],b); end if;
  s:=jsonb_set(s,'{buildings}',bs);
 elsif p_action in ('train','train_pause','train_resume','train_cancel','boost_train') then
  producer:=coalesce(p_args->>'producer',first_producer);
  select value into b from jsonb_array_elements(bs) where value->>'id'='barracks' and value->>'uid'=producer;
  if b is null or (b->>'level')::int<1 then raise exception 'เลือกหอฝึกที่สร้างเสร็จแล้ว';end if;
  producer_level:=(b->>'level')::int;producer_paused:=coalesce((b->>'training_paused')::boolean,false);
  select coalesce(jsonb_agg(value),'[]'::jsonb) into queue_jobs from jsonb_array_elements(jobs) where value->>'producer'=producer;
  queue_new:='[]'::jsonb;queue_skip:=0;
  if p_action='train' then
   idx:=(p_args->>'type')::int;qty:=coalesce((p_args->>'quantity')::int,1);
   if idx is null or idx not between 0 and 9 or qty not between 1 and 20 then raise exception 'ชนิดหรือจำนวนทหารไม่ถูกต้อง';end if;
   if producer_level<idx+1 then raise exception 'หอฝึกหลังนี้ต้องมีระดับสูงขึ้น';end if;
   if not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='training' and (value->>'level')::int>0) then raise exception 'สร้างลานฝึกกระบี่ก่อน';end if;
   select sum(value::int) into n from jsonb_array_elements_text(army);
   if n+jsonb_array_length(jobs)+qty>cap then raise exception 'ลานฝึกกระบี่เต็ม กรุณาอัปเกรด';end if;
   cw:=(array[20,40,60,100,200,500,1000,2500,6000,15000])[idx+1];cr:=(array[30,60,90,150,300,750,1500,3750,9000,22500])[idx+1];cs:=(array[0,8,20,40,80,200,400,1000,2400,6000])[idx+1];
   if water<cw*qty or rice<cr*qty or stone<cs*qty then raise exception 'ทรัพยากรไม่พอ';end if;
   select greatest(t,coalesce(max((value->>'finish')::bigint),t)) into queue_tail from jsonb_array_elements(queue_jobs);
   for j in 1..qty loop
    duration:=10*(idx+1);queue_tail:=queue_tail+duration;
    jobs:=jobs||jsonb_build_array(jsonb_build_object('id',gen_random_uuid(),'type',idx,'producer',producer,'duration',duration,'paid',jsonb_build_object('water',cw,'rice',cr,'stone',cs),
     'finish',case when producer_paused then 0 else queue_tail end,'paused',producer_paused,'remaining',duration));
   end loop;
   s:=s||jsonb_build_object('water',water-cw*qty,'rice',rice-cr*qty,'stone',stone-cs*qty,'jobs',jobs);
  elsif p_action in ('train_pause','train_resume') then
   if (p_action='train_pause')=producer_paused then null;
   else
    queue_tail:=t;
    for job in select value from jsonb_array_elements(jobs) loop
     if job->>'producer'=producer then
      if p_action='train_pause' then
       duration:=greatest(1,(job->>'finish')::bigint-queue_tail);queue_tail:=(job->>'finish')::bigint;
       job:=job||jsonb_build_object('remaining',duration,'paused',true);
      else
       queue_tail:=queue_tail+greatest(1,(job->>'remaining')::int);
       job:=job||jsonb_build_object('finish',queue_tail,'paused',false);
      end if;
     end if;
     queue_new:=queue_new||jsonb_build_array(job);
    end loop;
    for j in 0..jsonb_array_length(bs)-1 loop
     if bs->j->>'uid'=producer then bs:=jsonb_set(bs,array[j::text,'training_paused'],to_jsonb(p_action='train_pause'));end if;
    end loop;
    s:=s||jsonb_build_object('buildings',bs,'jobs',queue_new);
   end if;
  else
   if jsonb_array_length(queue_jobs)=0 then raise exception 'ไม่มีคิวผลิตในหอฝึกนี้';end if;
   if p_action='train_cancel' then
    select value into item from jsonb_array_elements(queue_jobs) where value->>'id'=p_args->>'job';
    if item is null then raise exception 'ไม่พบคิวผลิตนี้';end if;
    idx:=(item->>'type')::int;
    refund:=coalesce(item->'paid',jsonb_build_object('water',(array[20,40,60,100,200,500,1000,2500,6000,15000])[idx+1],'rice',(array[30,60,90,150,300,750,1500,3750,9000,22500])[idx+1],'stone',(array[0,8,20,40,80,200,400,1000,2400,6000])[idx+1]));
    s:=jsonb_set(s,'{train_refund}',jsonb_build_object('water',coalesce((s->'train_refund'->>'water')::int,0)+(refund->>'water')::int,'rice',coalesce((s->'train_refund'->>'rice')::int,0)+(refund->>'rice')::int,'stone',coalesce((s->'train_refund'->>'stone')::int,0)+(refund->>'stone')::int));
    queue_tail:=t;
    for job in select value from jsonb_array_elements(jobs) loop
     if job->>'producer'=producer then
      if job->>'id'=item->>'id' then
       queue_skip:=greatest(1,(job->>'finish')::bigint-queue_tail);continue;
      end if;
      queue_tail:=(job->>'finish')::bigint;
      if not producer_paused then job:=jsonb_set(job,'{finish}',to_jsonb(greatest(t,queue_tail-queue_skip)));end if;
     end if;
     queue_new:=queue_new||jsonb_build_array(job);
    end loop;
    s:=jsonb_set(s,'{jobs}',queue_new);
   else
    qty:=case when p_args->>'scope'='all' then jsonb_array_length(queue_jobs) else 1 end;
    if producer_paused then
     select sum((v->>'remaining')::int) into duration from jsonb_array_elements(queue_jobs) with ordinality q(v,i) where i<=qty;
    else duration:=greatest(1,(queue_jobs->(qty-1)->>'finish')::bigint-t);end if;
    jade_cost:=greatest(1,ceil(duration/300.0));
    if (s->>'jade')::int<jade_cost then raise exception 'หยกไม่พอ ต้องใช้ % หยก',jade_cost;end if;
    n:=0;
    for job in select value from jsonb_array_elements(jobs) loop
     if job->>'producer'=producer then
      n:=n+1;
      if n<=qty then idx:=(job->>'type')::int;army:=jsonb_set(army,array[idx::text],to_jsonb((army->>idx)::int+1));continue;end if;
      if not producer_paused then job:=jsonb_set(job,'{finish}',to_jsonb((job->>'finish')::bigint-duration));end if;
     end if;
     queue_new:=queue_new||jsonb_build_array(job);
    end loop;
    s:=s||jsonb_build_object('army',army,'jobs',queue_new,'jade',(s->>'jade')::int-jade_cost);
   end if;
  end if;
 elsif p_action='boost_repair' then
  duration:=coalesce((s->>'repair_until')::bigint,0)-t;
  if duration<=0 then raise exception 'ไม่มีงานซ่อมที่กำลังรอ';end if;
  jade_cost:=greatest(1,ceil(duration/300.0));
  if (s->>'jade')::int<jade_cost then raise exception 'หยกไม่พอ';end if;
  s:=(s-'repair_until'-'repair_pending')||jsonb_build_object('jade',(s->>'jade')::int-jade_cost);
 elsif p_action='boost_raid' then
  raid:=s->'raid';duration:=coalesce((raid->>'finish')::bigint,0)-t;
  if duration<=0 then raise exception 'การบุกจบแล้ว';end if;
  jade_cost:=greatest(1,ceil(duration/300.0));
  if (s->>'jade')::int<jade_cost then raise exception 'หยกไม่พอ';end if;
  s:=s||jsonb_build_object('jade',(s->>'jade')::int-jade_cost,'raid',raid||jsonb_build_object('finish',t));
  if raid->'enemy' ? 'player' then
   defender:=(raid->'enemy'->>'player')::uuid;
   select state into ds from xian_private.players where user_id=defender for update nowait;
   if ds->'last_defense'->>'id'=raid->>'id' then
    ds:=jsonb_set(ds,'{last_defense,finish}',to_jsonb(t));
    update xian_private.players set state=ds where user_id=defender;
   end if;
  end if;
 elsif p_action='ghost_begin' then
  lev:=(p_args->>'level')::int;
  if lev is null or lev not between 1 and 120 then raise exception 'ด่านไม่ถูกต้อง';end if;
  s:=jsonb_set(s,'{ghost_ticket}',jsonb_build_object('id',p_request,'level',lev,'start',t,'used',false));
 elsif p_action='ghost_win' then
  item:=s->'ghost_ticket';
  if item is null or p_args->>'ticket' is null or item->>'id'<>p_args->>'ticket'
     or (item->>'level')::int is distinct from (p_args->>'level')::int then raise exception 'ไม่พบรอบเกมจับคู่นี้';end if;
  if (item->>'used')::boolean then null;
  else
   if t-(item->>'start')::bigint<3 then raise exception 'รอบเกมสั้นเกินไป';end if;
   -- One authenticated ticket pays a fixed amount once; no balance supplied by clients.
   -- Native victory detection is client-side; this is replay protection, not anti-cheat attestation.
   s:=s||jsonb_build_object('jade',(s->>'jade')::int+reward_jade,'ghost_wins',coalesce((s->>'ghost_wins')::int,0)+1,
     'ghost_ticket',item||jsonb_build_object('used',true,'reward_jade',reward_jade));
  end if;
 elsif p_action='checkin' then
  if s->>'checkin'=day then raise exception 'รับรางวัลวันนี้แล้ว'; end if;
  n:=coalesce((s->>'checkin_count')::int,0)+1;
  s:=s||jsonb_build_object('checkin',day,'checkin_count',n,'jade',(s->>'jade')::int+case when n%7=0 then 20 else 5 end);
 elsif p_action='exchange' then
  typ:=p_args->>'resource';
  if typ not in ('water','rice','stone') or typ is null then raise exception 'ทรัพยากรไม่ถูกต้อง'; end if;
  if (s->>'jade')::int<5 then raise exception 'ต้องใช้หยกเซียน 5 เม็ด'; end if;
  qty:=case when typ='stone' then 25 else 250 end; n:=case typ when 'stone' then sc when 'water' then wc else rc end;
  if (s->>typ)::numeric+qty>n then raise exception 'โกดังไม่พอ กรุณาอัปเกรด'; end if;
  s:=jsonb_set(s,array[typ],to_jsonb((s->>typ)::numeric+qty)); s:=jsonb_set(s,'{jade}',to_jsonb((s->>'jade')::int-5));
 elsif p_action='boost' then
  idx:=(p_args->>'index')::int; b:=bs->idx;
  if b is null or idx<0 or (b->>'finish')::bigint<=t then raise exception 'ไม่มีงานที่กำลังสร้าง'; end if;
  qty:=ceil(((b->>'finish')::bigint-t)/300.0);
  if (s->>'jade')::int<qty then raise exception 'หยกเซียนไม่พอ'; end if;
  b:=b||jsonb_build_object('finish',t); s:=s||jsonb_build_object('jade',(s->>'jade')::int-qty,'buildings',jsonb_set(bs,array[idx::text],b));
 elsif p_action in ('match_start','match_shuffle') then
  if p_action='match_shuffle' and (not s ? 'match' or (s->'match'->>'moves')::int<=0) then raise exception 'เริ่มด่านใหม่ก่อน'; end if;
  if p_action='match_start' and s ? 'match' and (s->'match'->>'moves')::int>0 then null;
  else
   board:=array_fill(0,array[64]);
   for j in 1..64 loop
    loop
     n:=floor(random()*5)::int;
     exit when not ((j%8 not in (1,2) and board[j-1]=n and board[j-2]=n) or (j>16 and board[j-8]=n and board[j-16]=n));
    end loop; board[j]:=n;
   end loop;
   s:=jsonb_set(s,'{match}',jsonb_build_object('board',to_jsonb(board),'score',case when p_action='match_shuffle' then (s->'match'->>'score')::int else 0 end,'moves',case when p_action='match_shuffle' then (s->'match'->>'moves')::int-1 else 20 end,'goal',300,'rewarded',false));
  end if;
 elsif p_action='match_swap' then
  match_state:=s->'match';
  if match_state is null or (match_state->>'moves')::int<=0 or (match_state->>'rewarded')::boolean then raise exception 'เริ่มด่านใหม่ก่อน'; end if;
  a:=(p_args->>'a')::int+1; z:=(p_args->>'b')::int+1;
  if a is null or z is null or a not between 1 and 64 or z not between 1 and 64 or not (abs(a-z)=8 or (abs(a-z)=1 and (a-1)/8=(z-1)/8)) then raise exception 'เลือกช่องที่ติดกัน'; end if;
  select array_agg(value::int order by ord) into board from jsonb_array_elements_text(match_state->'board') with ordinality q(value,ord);
  tmp:=board[a];board[a]:=board[z];board[z]:=tmp; score:=(match_state->>'score')::int;
  for casc in 1..30 loop
   marked:='{}';
   for j in 1..64 loop
    if (j-1)%8<=5 and board[j]=board[j+1] and board[j]=board[j+2] then marked:=marked||array[j,j+1,j+2];end if;
    if j<=48 and board[j]=board[j+8] and board[j]=board[j+16] then marked:=marked||array[j,j+8,j+16];end if;
   end loop;
   if cardinality(marked)=0 then
    if casc=1 then raise exception 'ต้องเรียงให้ครบ 3 ชิ้น';end if; exit;
   end if;
   select array_agg(distinct x) into marked from unnest(marked) x;
   score:=score+cardinality(marked)*10;
   foreach j in array marked loop board[j]:=-1;end loop;
   for j in 1..8 loop
    k:=j+56;
    for n in reverse 7..0 loop
     if board[j+n*8]>=0 then board[k]:=board[j+n*8];k:=k-8;end if;
    end loop;
    while k>=j loop board[k]:=floor(random()*5)::int;k:=k-8;end loop;
   end loop;
  end loop;
  moves:=(match_state->>'moves')::int-1;
  match_state:=match_state||jsonb_build_object('board',to_jsonb(board),'score',score,'moves',moves);
  if score>=300 then
   n:=case when s->>'match_day'=day then coalesce((s->>'match_rewards')::int,0) else 0 end;
   match_state:=match_state||jsonb_build_object('rewarded',true,'moves',0,'paid',n<10,'reward_jade',case when n<10 then reward_jade else 0 end);
   if n<10 then s:=s||jsonb_build_object('water',least(wc,water+100),'rice',least(rc,rice+100),'jade',(s->>'jade')::int+reward_jade,'match_rewards',n+1,'match_day',day);end if;
   s:=jsonb_set(s,'{match_level}',to_jsonb((s->>'match_level')::int+1));
  end if;
  s:=jsonb_set(s,'{match}',match_state);
 elsif p_action='scout' then
  if s ? 'raid' then raise exception 'จบการบุกก่อน'; end if;
  if coalesce(p_args->>'mode','player')<>'bot' then
   select user_id,state into defender,ds from xian_private.players
    where user_id<>uid and not state ? 'raid' and coalesce((state->>'shield')::bigint,0)<=t
    and coalesce((state->>'repair_until')::bigint,0)<=t
    and (p_args->>'revenge' is null or exists (
      select 1 from jsonb_array_elements(coalesce(s->'defense_history','[]'::jsonb)) h
      where h->>'id'=p_args->>'revenge' and h->>'attacker_id'=user_id::text))
    and (p_args->>'revenge' is not null or abs((state->'buildings'->0->>'level')::int-hall)<=2)
    order by (user_id::text=coalesce(s->'scout'->>'player','')),random() limit 1;
   if defender is null then
    s:=s-'scout';
    update xian_private.players set state=s,updated_at=now() where user_id=uid;
    return jsonb_build_object('state',s,'catalog',xian_private.catalog(),'server_time',t,
     'capacity',jsonb_build_object('water',wc,'rice',rc,'stone',sc,'army',cap,'workers',workers,'busy',busy,'worker_max',worker_max),
     'checkin_available',coalesce(s->>'checkin','')<>day,'notice',case when p_args->>'revenge' is not null then 'ยังเอาคืนไม่ได้ เป้าหมายติดโล่หรือกำลังต่อสู้/ซ่อมฐาน' else 'ยังไม่มีผู้เล่นที่บุกได้ ลองค้นหาใหม่ภายหลัง' end);
   end if;
   guards:=xian_private.garrison(ds,t);
   defense:=80+xian_private.army_power(guards);
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    defense:=defense+case b->>'id' when 'tower' then 40 when 'ward' then 50 when 'wall' then 3 else 4 end*(b->>'level')::int;
   end loop;
   opponent:=jsonb_build_object('name',ds->>'name','player',defender,'level',ds->'buildings'->0->'level','water',floor((ds->>'water')::numeric*0.60),'rice',floor((ds->>'rice')::numeric*0.60),'stone',floor((ds->>'stone')::numeric*0.60),'defense',defense,'garrison',guards,'garrison_power',xian_private.army_power(guards),'buildings',ds->'buildings','pill_fill',xian_private.pill_fill(ds));
  else
   n:=least(50,(s->>'wins')::int+1);
   opponent:=jsonb_build_object('name','สำนักเงาหมอก '||n::text,'level',n,'water',100+n*20,'rice',100+n*20,'stone',5+n,'defense',100+n*35);
  end if;
  s:=jsonb_set(s,'{scout}',opponent);
 elsif p_action='raid_start' then
  if s ? 'raid' then raise exception 'กำลังบุกอยู่';end if;
  if not s ? 'scout' then raise exception 'สำรวจฐานก่อน';end if;
  power:=xian_private.army_power(army);
  if power<=0 then raise exception 'ต้องฝึกศิษย์ก่อน';end if;
  opponent:=s->'scout';defense:=(opponent->>'defense')::numeric;
  if opponent ? 'player' then
   defender:=(opponent->>'player')::uuid;
   select state into ds from xian_private.players where user_id=defender for update nowait;
   if ds is null or (ds->>'shield')::bigint>t or ds ? 'raid' or coalesce((ds->>'repair_until')::bigint,0)>t or defender=uid then raise exception 'เป้าหมายไม่พร้อม กรุณาสำรวจใหม่';end if;
   guards:=xian_private.garrison(ds,t);
   defense:=80+xian_private.army_power(guards);
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    defense:=defense+case b->>'id' when 'tower' then 40 when 'ward' then 50 when 'wall' then 3 else 4 end*(b->>'level')::int;
   end loop;
   -- Flying swords bypass walls. Beasts focus defenses. Wards counter air.
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    if b->>'id'='wall' and (army->>1)::int+(army->>2)::int>0 then defense:=defense-2*(b->>'level')::int;end if;
    if b->>'id'='ward' and (army->>1)::int>0 then defense:=defense+20*(b->>'level')::int;end if;
   end loop;
   opponent:=opponent||jsonb_build_object('defense',defense,'garrison',guards,'garrison_power',xian_private.army_power(guards),'buildings',ds->'buildings','pill_fill',xian_private.pill_fill(ds),'water',floor((ds->>'water')::numeric*0.60),'rice',floor((ds->>'rice')::numeric*0.60),'stone',floor((ds->>'stone')::numeric*0.60));
  end if;
  battle_effects:=xian_private.formation_battle(opponent->'buildings',army);
  power:=greatest(0,power-(battle_effects->>'power_lost')::numeric);
  ratio:=least(1,power/greatest(1,defense));n:=case when ratio>=1 then 3 when ratio>=0.7 then 2 when ratio>=0.4 then 1 else 0 end;
  loot_w:=floor((opponent->>'water')::int*ratio);loot_r:=floor((opponent->>'rice')::int*ratio);loot_s:=floor((opponent->>'stone')::int*ratio);
  -- Player resources lose exactly 60% (whole units rounded down), independent of cosmetic damage.
  if defender is not null then
   loot_w:=(opponent->>'water')::int;loot_r:=(opponent->>'rice')::int;loot_s:=(opponent->>'stone')::int;
  end if;
  raid:=jsonb_build_object('id',p_request,'defense_fx',battle_effects->'events','start',t,'finish',t+25,'army',army,'enemy',opponent,'stars',n,'ratio',ratio,'water',loot_w,'rice',loot_r,'stone',loot_s);
  if defender is not null then
   -- Materialize finished jobs exactly once; defenders stay in the roster after battle.
   ds:=ds||jsonb_build_object('army',xian_private.ready_army(ds,t),'jobs',
    coalesce((select jsonb_agg(value) from jsonb_array_elements(ds->'jobs') where (value->>'finish')::bigint>t or coalesce((value->>'paused')::boolean,false)),'[]'::jsonb));
   report:=jsonb_build_object('defense_fx',battle_effects->'events','id',p_request,'attacker_id',uid,'attacker',s->>'name','time',t,'finish',t+25,'army',army,'garrison',guards,'garrison_power',xian_private.army_power(guards),'ratio',ratio,'stars',n,'water',loot_w,'rice',loot_r,'stone',loot_s);
   ds:=ds||jsonb_build_object('water',(ds->>'water')::numeric-loot_w,'rice',(ds->>'rice')::numeric-loot_r,'stone',(ds->>'stone')::numeric-loot_s,'shield',t+14400,'last_defense',report);
   select coalesce(jsonb_agg(v order by i),'[]'::jsonb) into other_bs
    from jsonb_array_elements(jsonb_build_array(report)||coalesce(ds->'defense_history','[]'::jsonb)) with ordinality q(v,i) where i<=20;
   ds:=(ds-'repair_until')||jsonb_build_object('defense_history',other_bs,'repair_pending',true);
   update xian_private.players set state=ds where user_id=defender;
  end if;
  s:=s||jsonb_build_object('raid',raid,'army','[0,0,0,0,0,0,0,0,0,0]'::jsonb,'shield',0);
 elsif p_action='raid_claim' then
  raid:=s->'raid';
  if raid is null or (raid->>'finish')::bigint>t then raise exception 'การบุกยังไม่จบ';end if;
  n:=(raid->>'stars')::int;
  s:=s||jsonb_build_object('water',least(wc,water+(raid->>'water')::int),'rice',least(rc,rice+(raid->>'rice')::int),'stone',least(sc,stone+(raid->>'stone')::int), 'wins',(s->>'wins')::int+case when n>0 then 1 else 0 end,'last_raid',raid);
  s:=s-'raid'-'scout';
 elsif p_action not in ('sync','create') then raise exception 'คำสั่งไม่รองรับ';
 end if;
 if p_action<>'sync' then insert into xian_private.receipts(user_id,request_id) values(uid,p_request) on conflict do nothing; end if;
 update xian_private.players set state=s,updated_at=now() where user_id=uid;
 return jsonb_build_object('state',s,'catalog',xian_private.catalog(),'server_time',t,'server_day',day,'checkin_available',coalesce(s->>'checkin','')<>day,'capacity',jsonb_build_object('water',wc,'rice',rc,'stone',sc,'army',cap,'workers',workers,'busy',busy,'worker_max',worker_max));
end; $function$;
