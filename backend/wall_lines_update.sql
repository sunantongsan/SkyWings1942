-- v37: atomic wall row construction, rotation and movement.
create or replace function xian_private.wall_run(bs jsonb, anchor int)
returns int[] language plpgsql immutable set search_path='' as $$
declare b jsonb:=bs->anchor; result int[]:=array[anchor]; axis int; horizontal bool; vertical bool;
 dx int;dy int;direction int;distance int;found int;
begin
 if anchor is null or anchor<0 or b is null or b->>'id'<>'wall' then raise exception 'เลือกกำแพงก่อน';end if;
 axis:=coalesce((b->>'rotation')::int,0)%2;
 select exists(select 1 from jsonb_array_elements(bs) v where v->>'id'='wall' and (v->>'y')::int=(b->>'y')::int and abs((v->>'x')::int-(b->>'x')::int)=1),
 exists(select 1 from jsonb_array_elements(bs) v where v->>'id'='wall' and (v->>'x')::int=(b->>'x')::int and abs((v->>'y')::int-(b->>'y')::int)=1) into horizontal,vertical;
 if vertical and not horizontal then axis:=1;elsif horizontal and not vertical then axis:=0;end if;
 dx:=case when axis=0 then 1 else 0 end;dy:=1-dx;
 foreach direction in array array[-1,1] loop
  for distance in 1..15 loop
   select i-1 into found from jsonb_array_elements(bs) with ordinality q(v,i)
   where v->>'id'='wall' and (v->>'x')::int=(b->>'x')::int+dx*direction*distance and (v->>'y')::int=(b->>'y')::int+dy*direction*distance;
   exit when found is null;result:=array_append(result,found);
  end loop;
 end loop;
 return result;
end $$;
revoke all on function xian_private.wall_run(jsonb,int) from public,anon,authenticated;

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
 cw int; cr int; cs int; count_type int; worker_max int; army jsonb; jobs jsonb:='[]'; job jsonb;
 board int[]; marked int[]; a int; z int; tmp int; score int; moves int; casc int; changed bool;
 match_state jsonb; day text:=to_char(now() at time zone 'Asia/Bangkok','YYYY-MM-DD');
 result jsonb; power numeric; defense numeric; ratio numeric; raid jsonb; opponent jsonb; defender uuid; ds jsonb; report jsonb; loot_w int; loot_r int; loot_s int;
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
    'army','[0,0,0]'::jsonb,'jobs','[]'::jsonb,'wins',0,'match_level',1,'shield',t+86400);
  insert into xian_private.players(user_id,state) values(uid,s);
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
   when 'tank' then wc:=wc+lev*2000;
   when 'granary' then rc:=rc+lev*2000;
   when 'crystal' then sc:=sc+lev*500;
   when 'well' then wr:=wr+lev;
   when 'kitchen' then rr:=rr+lev;
   when 'spring' then sr:=sr+lev*0.04;
   else null; end case;
  end if;
 end loop;
 -- Production is only granted for buildings that existed at the previous sync.
 for b in select value from jsonb_array_elements(s->'buildings') loop
  if (b->>'finish')::bigint>0 and (b->>'finish')::bigint<=t then
   case b->>'id' when 'well' then wr:=wr-greatest(0,least(elapsed,(b->>'finish')::bigint-old_t))::numeric/greatest(1,elapsed);
   when 'kitchen' then rr:=rr-greatest(0,least(elapsed,(b->>'finish')::bigint-old_t))::numeric/greatest(1,elapsed);
   when 'spring' then sr:=sr-0.04*greatest(0,least(elapsed,(b->>'finish')::bigint-old_t))::numeric/greatest(1,elapsed);
   else null; end case;
  end if;
 end loop;
 water:=least(wc,round((s->>'water')::numeric+elapsed*wr,4)); rice:=least(rc,round((s->>'rice')::numeric+elapsed*rr,4)); stone:=least(sc,round((s->>'stone')::numeric+elapsed*sr,4));
 army:=s->'army';
 for job in select value from jsonb_array_elements(s->'jobs') loop
  if (job->>'finish')::bigint<=t then
   idx:=(job->>'type')::int; army:=jsonb_set(army,array[idx::text],to_jsonb((army->>idx)::int+1));
  else jobs:=jobs||jsonb_build_array(job); end if;
 end loop;
 s:=s||jsonb_build_object('buildings',bs,'army',army,'jobs',jobs,'last_tick',t,'water',water,'rice',rice,'stone',stone);
 worker_max:=case when hall=1 then 2 when hall<=3 then 3 when hall<=5 then 4 when hall<=7 then 6 when hall<=9 then 8 else 10 end;
 if exists(select 1 from xian_private.receipts where user_id=uid and request_id=p_request) then p_action:='sync'; end if;
 if p_action='wall_line' then
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
  if p_action<>'move' then
   if (b->>'finish')::bigint>t then raise exception 'อาคารนี้กำลังก่อสร้าง'; end if;
   if lev>=10 or (typ<>'hall' and lev>=hall+1) then raise exception 'อัปเกรดสำนักหลักก่อน'; end if;
   if typ<>'wall' and busy>=workers then raise exception 'ศิษย์รับใช้ทำงานครบทุกคนแล้ว'; end if;
   cw:=(c->>'water')::int*power(2,lev); cr:=(c->>'rice')::int*power(2,lev); cs:=(c->>'stone')::int*power(2,lev);
   if water<cw or rice<cr or stone<cs then raise exception 'ทรัพยากรไม่พอ'; end if;
   duration:=least(28800,(c->>'seconds')::int*power(3,lev));
   b:=b||jsonb_build_object('finish',case when duration=0 then 0 else t+duration end,'level',case when duration=0 then lev+1 else lev end);
   s:=s||jsonb_build_object('water',water-cw,'rice',rice-cr,'stone',stone-cs);
  end if;
  if p_action='build' then bs:=bs||jsonb_build_array(b); else bs:=jsonb_set(bs,array[idx::text],b); end if;
  s:=jsonb_set(s,'{buildings}',bs);
 elsif p_action='train' then
  idx:=(p_args->>'type')::int;
  if idx is null or idx not between 0 and 2 then raise exception 'ไม่มีศิษย์ชนิดนี้'; end if;
  if not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='recruit' and (value->>'level')::int>0) then raise exception 'สร้างโรงรับศิษย์ก่อน'; end if;
  if not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='training' and (value->>'level')::int>0) then raise exception 'สร้างลานฝึกกระบี่ก่อน'; end if;
  if idx>0 and (hall<idx+1 or not exists(select 1 from jsonb_array_elements(bs) where value->>'id'='training' and (value->>'level')::int>=idx)) then raise exception 'ต้องมีสำนักและลานฝึกกระบี่ขั้นสูงขึ้น'; end if;
  select sum(value::int) into qty from jsonb_array_elements_text(army);
  if qty+jsonb_array_length(jobs)>=cap then raise exception 'ลานฝึกกระบี่เต็ม กรุณาอัปเกรดลานฝึก'; end if;
  cw:=20*(idx+1); cr:=30*(idx+1); cs:=case idx when 0 then 0 when 1 then 8 else 20 end;
  if water<cw or rice<cr or stone<cs then raise exception 'ทรัพยากรไม่พอ'; end if;
  select greatest(t,coalesce(max((value->>'finish')::bigint),t)) into old_t from jsonb_array_elements(jobs);
  s:=s||jsonb_build_object('water',water-cw,'rice',rice-cr,'stone',stone-cs,'jobs',jobs||jsonb_build_array(jsonb_build_object('type',idx,'finish',old_t+10*(idx+1))));
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
   defense:=80;
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    defense:=defense+case b->>'id' when 'tower' then 40 when 'ward' then 50 when 'wall' then 3 else 4 end*(b->>'level')::int;
   end loop;
   opponent:=jsonb_build_object('name',ds->>'name','player',defender,'level',ds->'buildings'->0->'level','water',floor((ds->>'water')::numeric*0.15),'rice',floor((ds->>'rice')::numeric*0.15),'stone',floor((ds->>'stone')::numeric*0.10),'defense',defense,'buildings',ds->'buildings');
  else
   n:=least(50,(s->>'wins')::int+1);
   opponent:=jsonb_build_object('name','สำนักเงาหมอก '||n::text,'level',n,'water',100+n*20,'rice',100+n*20,'stone',5+n,'defense',100+n*35);
  end if;
  s:=jsonb_set(s,'{scout}',opponent);
 elsif p_action='raid_start' then
  if s ? 'raid' then raise exception 'กำลังบุกอยู่';end if;
  if not s ? 'scout' then raise exception 'สำรวจฐานก่อน';end if;
  power:=(army->>0)::int*35+(army->>1)::int*90+(army->>2)::int*150;
  if power<=0 then raise exception 'ต้องฝึกศิษย์ก่อน';end if;
  opponent:=s->'scout';defense:=(opponent->>'defense')::numeric;
  if opponent ? 'player' then
   defender:=(opponent->>'player')::uuid;
   select state into ds from xian_private.players where user_id=defender for update;
   if ds is null or (ds->>'shield')::bigint>t or ds ? 'raid' then raise exception 'เป้าหมายไม่พร้อม กรุณาสำรวจใหม่';end if;
   defense:=80;
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    defense:=defense+case b->>'id' when 'tower' then 40 when 'ward' then 50 when 'wall' then 3 else 4 end*(b->>'level')::int;
   end loop;
   -- Flying swords bypass walls. Beasts focus defenses. Wards counter air.
   for b in select value from jsonb_array_elements(ds->'buildings') loop
    if b->>'id'='wall' and (army->>1)::int+(army->>2)::int>0 then defense:=defense-2*(b->>'level')::int;end if;
    if b->>'id'='ward' and (army->>1)::int>0 then defense:=defense+20*(b->>'level')::int;end if;
   end loop;
   opponent:=opponent||jsonb_build_object('defense',defense,'buildings',ds->'buildings','water',floor((ds->>'water')::numeric*0.15),'rice',floor((ds->>'rice')::numeric*0.15),'stone',floor((ds->>'stone')::numeric*0.10));
  end if;
  ratio:=least(1,power/greatest(1,defense));n:=case when ratio>=1 then 3 when ratio>=0.7 then 2 when ratio>=0.4 then 1 else 0 end;
  loot_w:=floor((opponent->>'water')::int*ratio);loot_r:=floor((opponent->>'rice')::int*ratio);loot_s:=floor((opponent->>'stone')::int*ratio);
  raid:=jsonb_build_object('start',t,'finish',t+25,'army',army,'enemy',opponent,'stars',n,'ratio',ratio,'water',loot_w,'rice',loot_r,'stone',loot_s);
  if defender is not null then
   report:=jsonb_build_object('attacker',s->>'name','time',t,'stars',n,'water',loot_w,'rice',loot_r,'stone',loot_s);
   ds:=ds||jsonb_build_object('water',(ds->>'water')::numeric-loot_w,'rice',(ds->>'rice')::numeric-loot_r,'stone',(ds->>'stone')::numeric-loot_s,'shield',t+14400,'last_defense',report);
   update xian_private.players set state=ds where user_id=defender;
  end if;
  s:=s||jsonb_build_object('raid',raid,'army','[0,0,0]'::jsonb,'shield',0);
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
 return jsonb_build_object('state',s,'catalog',xian_private.catalog(),'server_time',t,'capacity',jsonb_build_object('water',wc,'rice',rc,'stone',sc,'army',cap,'workers',workers,'busy',busy,'worker_max',worker_max));
end; $$;
revoke all on function xian_private.catalog() from public,anon,authenticated;
revoke all on function xian_private.act(text,jsonb,uuid) from public,anon;
grant execute on function xian_private.act(text,jsonb,uuid) to authenticated;
