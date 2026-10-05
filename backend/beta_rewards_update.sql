-- Test reward ends permanently at 100 created Xian game accounts.
-- Unrelated applications sharing auth.users do not count.
lock table xian_private.players in share row exclusive mode;
create table if not exists xian_private.match_reward_campaign (
 id boolean primary key default true check (id),
 registrations bigint not null check (registrations>=0)
);
alter table xian_private.match_reward_campaign enable row level security;
revoke all on xian_private.match_reward_campaign from public,anon,authenticated;
insert into xian_private.match_reward_campaign(id,registrations)
 select true,count(*) from xian_private.players on conflict(id) do nothing;
create or replace function xian_private.count_game_registration() returns trigger
language plpgsql security invoker set search_path='' as $$
begin
 update xian_private.match_reward_campaign set registrations=registrations+1 where id;
 return new;
end; $$;
revoke all on function xian_private.count_game_registration() from public,anon,authenticated;
drop trigger if exists xian_count_registration on xian_private.players;
create trigger xian_count_registration after insert on xian_private.players
 for each row execute function xian_private.count_game_registration();
create or replace function xian_private.match_reward_amount() returns integer
language sql stable security invoker set search_path='' as $$
 select case when registrations<100 then 50 else 2 end
 from xian_private.match_reward_campaign where id;
$$;
revoke all on function xian_private.match_reward_amount() from public,anon,authenticated;
-- Patch only the current action implementation, preserving all other live rules.
do $patch$
declare source text; updated text;
begin
 source:=pg_get_functiondef('xian_private.act(text,jsonb,uuid)'::regprocedure);
 if position('xian_private.match_reward_amount()' in source)>0 then return;end if;
 if position(' uid uuid:=auth.uid(); s jsonb;' in source)=0
 or position(' if p_action=''wall_manage'' then' in source)=0
 or position('''ghost_ticket'',item||''{"used":true}''::jsonb' in source)=0
 or (length(source)-length(replace(source,'''jade'',(s->>''jade'')::int+2','')))/length('''jade'',(s->>''jade'')::int+2')<>2
 then raise exception 'Unexpected action definition; campaign was not installed';end if;
 updated:=replace(source,' uid uuid:=auth.uid(); s jsonb;',' reward_jade int; uid uuid:=auth.uid(); s jsonb;');
 updated:=replace(updated,' if p_action=''wall_manage'' then', E' reward_jade:=xian_private.match_reward_amount();\n s:=s||jsonb_build_object(''match_reward_jade'',reward_jade);\n if p_action=''wall_manage'' then');
 updated:=replace(updated,'''jade'',(s->>''jade'')::int+2','''jade'',(s->>''jade'')::int+reward_jade');
 updated:=replace(updated,'''ghost_ticket'',item||''{"used":true}''::jsonb','''ghost_ticket'',item||jsonb_build_object(''used'',true,''reward_jade'',reward_jade)');
 updated:=replace(updated,'''paid'',n<10)','''paid'',n<10,''reward_jade'',case when n<10 then reward_jade else 0 end)');
 execute updated;
end; $patch$;
