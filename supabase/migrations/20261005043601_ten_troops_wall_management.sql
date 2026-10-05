create or replace function xian_private.storage_capacity(kind text,lv int) returns int
language sql immutable set search_path='' as $$
 select case when lv<=3 then greatest(0,lv)*case when kind='crystal' then 500 else 2000 end
 else (array[0,2000,4000,6000,20000,80000,300000,1000000,3000000,10000000,15000000])[least(10,lv)+1] end;
$$;
create or replace function xian_private.production_rate(kind text,lv int) returns numeric
language sql immutable set search_path='' as $$
 select case when lv<=3 then greatest(0,lv)*case when kind='spring' then 0.04 else 1 end
 else (array[0,0,0,0,5,15,40,100,250,600,1200]::numeric[])[least(10,lv)+1]*case when kind='spring' then 0.5 else 1 end end;
$$;
create or replace function xian_private.barracks_price(target_level int) returns int
language sql immutable set search_path='' as $$
 select (array[0,0,1000,5000,20000,75000,250000,750000,2000000,5000000,10000000])[target_level+1];
$$;
revoke all on function xian_private.storage_capacity(text,int),xian_private.production_rate(text,int),xian_private.barracks_price(int) from public,anon,authenticated;

-- Visual fullness of the shared pill store; stable stone key preserves saves/old clients.
create or replace function xian_private.pill_fill(s jsonb) returns numeric
language sql immutable set search_path='' as $$
 select least(1::numeric,greatest(0::numeric,coalesce((s->>'stone')::numeric,0)) /
 greatest(1::numeric,100+coalesce((select sum(xian_private.storage_capacity('crystal',(b->>'level')::int)) from jsonb_array_elements(s->'buildings') b where b->>'id'='crystal'),0)))
$$;
revoke all on function xian_private.pill_fill(jsonb) from public,anon,authenticated;

create or replace function xian_private.ready_army(s jsonb,t bigint) returns jsonb
language sql immutable security invoker set search_path='' as $$
 select jsonb_agg(greatest(0,coalesce((s->'army'->>i)::int,0))+
  (select count(*) from jsonb_array_elements(coalesce(s->'jobs','[]'::jsonb)) j
   where (j->>'type')::int=i and (j->>'finish')::bigint<=t) order by i)
 from generate_series(0,9) i;
$$;
create or replace function xian_private.garrison(s jsonb,t bigint) returns jsonb
language sql immutable security invoker set search_path='' as $$
 select jsonb_agg((value::text::int/2) order by ordinality)
 from jsonb_array_elements(xian_private.ready_army(s,t)) with ordinality;
$$;
create or replace function xian_private.army_power(a jsonb) returns numeric
language sql immutable security invoker set search_path='' as $$
 select sum(coalesce((a->>i)::numeric,0)*(array[35,90,150,190,280,380,500,700,950,1300])[i+1]) from generate_series(0,9) i;
$$;
revoke all on function xian_private.ready_army(jsonb,bigint),xian_private.garrison(jsonb,bigint),xian_private.army_power(jsonb) from public,anon,authenticated;

-- The privileged dispatcher is in a non-exposed schema, authenticates ownership,
-- serializes each player's actions and never accepts balances or victory from clients.
create or replace function xian_private.act(p_action text,p_args jsonb,p_request uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 uid uuid:=auth.uid(); s jsonb; b jsonb; bs jsonb; c jsonb; item jsonb;
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
  if (job->>'finish')::bigint<=t then
   idx:=(job->>'type')::int; army:=jsonb_set(army,array[idx::text],to_jsonb((army->>idx)::int+1));
  else jobs:=jobs||jsonb_build_array(job); end if;
 end loop;
 s:=s||jsonb_build_object('buildings',bs,'army',army,'jobs',jobs,'last_tick',t,'water',water,'rice',rice,'stone',stone);
 worker_max:=7;
 if exists(select 1 from xian_private.receipts where user_id=uid and request_id=p_request) then p_action:='sync'; end if;
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
   select count(*) into count_type from jsonb_array_elements(bs) where value->>'id'=typ;
   if count_type >= (case when typ='servant' then worker_max else (c->>'limit')::int end) then raise exception 'จำนวนอาคารถึงขีดจำกัดของสำนักแล้ว'; end if;
   idx:=jsonb_array_length(bs); b:=jsonb_build_object('id',typ,'level',0,'finish',0);
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
 elsif p_action='train' then
  idx:=(p_args->>'type')::int;
  if idx is null or idx not between 0 and 9 then raise exception 'ไม่มีศิษย์ชนิดนี้'; end if;
  if not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='barracks' and (value->>'level')::int>0) then raise exception 'สร้างหอฝึกนักสู้ก่อน'; end if;
  if not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='training' and (value->>'level')::int>0) then raise exception 'สร้างลานฝึกกระบี่ก่อน'; end if;
  if idx>0 and (not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='barracks' and (value->>'level')::int>=idx+1)) then raise exception 'ต้องมีหอฝึกนักสู้ขั้นสูงขึ้น'; end if;
  select sum(value::int) into qty from jsonb_array_elements_text(army);
  if qty+jsonb_array_length(jobs)>=cap then raise exception 'ลานฝึกกระบี่เต็ม กรุณาอัปเกรดลานฝึก'; end if;
  cw:=(array[20,40,60,100,200,500,1000,2500,6000,15000])[idx+1];cr:=(array[30,60,90,150,300,750,1500,3750,9000,22500])[idx+1];cs:=(array[0,8,20,40,80,200,400,1000,2400,6000])[idx+1];
  if water<cw or rice<cr or stone<cs then raise exception 'ทรัพยากรไม่พอ'; end if;
  select greatest(t,coalesce(max((value->>'finish')::bigint),t)) into old_t from jsonb_array_elements(jobs);
  s:=s||jsonb_build_object('water',water-cw,'rice',rice-cr,'stone',stone-cs,'jobs',jobs||jsonb_build_array(jsonb_build_object('type',idx,'finish',old_t+10*(idx+1))));
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
   s:=s||jsonb_build_object('jade',(s->>'jade')::int+2,'ghost_wins',coalesce((s->>'ghost_wins')::int,0)+1,
     'ghost_ticket',item||'{"used":true}'::jsonb);
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
   match_state:=match_state||jsonb_build_object('rewarded',true,'moves',0,'paid',n<10);
   if n<10 then s:=s||jsonb_build_object('water',least(wc,water+100),'rice',least(rc,rice+100),'jade',(s->>'jade')::int+2,'match_rewards',n+1,'match_day',day);end if;
   s:=jsonb_set(s,'{match_level}',to_jsonb((s->>'match_level')::int+1));
  end if;
  s:=jsonb_set(s,'{match}',match_state);
 elsif p_action='scout' then
  if s ? 'raid' then raise exception 'จบการบุกก่อน'; end if;
  if p_args->>'mode'='player' then
   select user_id,state into defender,ds from xian_private.players
    where user_id<>uid and not state ? 'raid' and coalesce((state->>'shield')::bigint,0)<=t
    and abs((state->'buildings'->0->>'level')::int-hall)<=2
    order by updated_at desc limit 1;
   if defender is null then raise exception 'ยังไม่มีสำนักผู้เล่นที่พ้นโล่คุ้มครอง ลองบุกบอทก่อน';end if;
   guards:=xian_private.garrison(ds,t);
   defense:=80+xian_private.army_power(guards);
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    defense:=defense+case b->>'id' when 'tower' then 40 when 'ward' then 50 when 'wall' then 3 else 4 end*(b->>'level')::int;
   end loop;
   opponent:=jsonb_build_object('name',ds->>'name','player',defender,'level',ds->'buildings'->0->'level','water',floor((ds->>'water')::numeric*0.15),'rice',floor((ds->>'rice')::numeric*0.15),'stone',floor((ds->>'stone')::numeric*0.10),'defense',defense,'garrison',guards,'garrison_power',xian_private.army_power(guards),'buildings',ds->'buildings','pill_fill',xian_private.pill_fill(ds));
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
   select state into ds from xian_private.players where user_id=defender for update;
   if ds is null or (ds->>'shield')::bigint>t or ds ? 'raid' then raise exception 'เป้าหมายไม่พร้อม กรุณาสำรวจใหม่';end if;
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
   opponent:=opponent||jsonb_build_object('defense',defense,'garrison',guards,'garrison_power',xian_private.army_power(guards),'buildings',ds->'buildings','pill_fill',xian_private.pill_fill(ds),'water',floor((ds->>'water')::numeric*0.15),'rice',floor((ds->>'rice')::numeric*0.15),'stone',floor((ds->>'stone')::numeric*0.10));
  end if;
  ratio:=least(1,power/greatest(1,defense));n:=case when ratio>=1 then 3 when ratio>=0.7 then 2 when ratio>=0.4 then 1 else 0 end;
  loot_w:=floor((opponent->>'water')::int*ratio);loot_r:=floor((opponent->>'rice')::int*ratio);loot_s:=floor((opponent->>'stone')::int*ratio);
  raid:=jsonb_build_object('start',t,'finish',t+25,'army',army,'enemy',opponent,'stars',n,'ratio',ratio,'water',loot_w,'rice',loot_r,'stone',loot_s);
  if defender is not null then
   -- Materialize finished jobs exactly once; defenders stay in the roster after battle.
   ds:=ds||jsonb_build_object('army',xian_private.ready_army(ds,t),'jobs',
    coalesce((select jsonb_agg(value) from jsonb_array_elements(ds->'jobs') where (value->>'finish')::bigint>t),'[]'::jsonb));
   report:=jsonb_build_object('attacker',s->>'name','time',t,'finish',t+25,'army',army,'garrison',guards,'garrison_power',xian_private.army_power(guards),'ratio',ratio,'stars',n,'water',loot_w,'rice',loot_r,'stone',loot_s);
   ds:=ds||jsonb_build_object('water',(ds->>'water')::numeric-loot_w,'rice',(ds->>'rice')::numeric-loot_r,'stone',(ds->>'stone')::numeric-loot_s,'shield',t+14400,'last_defense',report);
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
end; $$;
