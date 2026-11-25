-- Weazel News : à coller dans Supabase > SQL Editor > Run
create extension if not exists pgcrypto with schema extensions;
create table staff(id text primary key,role text not null default 'journalist',hash text not null,must boolean not null default true,fails int not null default 0,locked_until timestamptz,last timestamptz,grade text not null default '',nom text not null default '',prenom text not null default '',tel text not null default '');
create unique index staff_lower on staff(lower(id));
create table sessions(token text primary key,uid text not null,exp timestamptz not null);
create table posts(id text primary key,type text not null,by_id text,date timestamptz not null default now(),edited timestamptz,kicker text,title text,sub text,author text,thumb text,edition text,dtxt text,slogan text,foot text,pages jsonb not null default '[]');
create table readers(id text primary key,name text,avatar text,last timestamptz default now(),banned boolean not null default false);
create table likes(post text references posts(id) on delete cascade,reader text,primary key(post,reader));
create table comments(id text primary key,post text references posts(id) on delete cascade,uid text,uname text,avatar text,text text,date timestamptz not null default now());
create table reqs(id text primary key,st text not null default 'nouveau',type text,name text,contact text,message text,date timestamptz not null default now());
create table settings(key text primary key,value jsonb);
create table gallery(id text primary key,url text not null,cap text default '',date timestamptz not null default now());
-- sécurité : personne n'accède aux tables sans passer par le Worker
do $$ declare t text; begin for t in select tablename from pg_tables where schemaname='public' loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
-- comptes journalistes : mots de passe hachés (bcrypt) dans Postgres
create function staff_login(p_id text,p_pass text) returns json language plpgsql security definer set search_path=public,extensions as $$
declare s staff%rowtype;
begin select * into s from staff where lower(id)=lower(p_id);
 if not found then return json_build_object('ok',false); end if;
 if s.locked_until is not null and s.locked_until>now() then return json_build_object('ok',false,'locked',true); end if;
 if s.hash=crypt(p_pass,s.hash) then update staff set fails=0,last=now() where id=s.id; return json_build_object('ok',true,'id',s.id,'role',s.role,'must',s.must);
 else update staff set fails=case when fails+1>=8 then 0 else fails+1 end,locked_until=case when fails+1>=8 then now()+interval '10 minutes' else null end where id=s.id; return json_build_object('ok',false); end if; end $$;
create function staff_create(p_id text,p_code text,p_grade text) returns boolean language plpgsql security definer set search_path=public,extensions as $$
begin insert into staff(id,hash,grade) values(p_id,crypt(p_code,gen_salt('bf')),coalesce(p_grade,'')); return true; exception when unique_violation then return false; end $$;
create function staff_set_pass(p_id text,p_pass text,p_must boolean) returns void language sql security definer set search_path=public,extensions as $$
update staff set hash=crypt(p_pass,gen_salt('bf')),must=p_must,fails=0,locked_until=null where id=p_id $$;
revoke all on function staff_login(text,text),staff_create(text,text,text),staff_set_pass(text,text,boolean) from public,anon,authenticated;
grant execute on function staff_login(text,text),staff_create(text,text,text),staff_set_pass(text,text,boolean) to service_role;
insert into settings values('rates','[{"label":"Annonce simple","price":"à définir"},{"label":"Publicité en journal","price":"à définir"}]');
-- compte patron : identifiant G.morel, mot de passe provisoire 12345 (à changer à la 1re connexion)
select staff_create('G.morel','12345','');
update staff set role='boss' where id='G.morel';
