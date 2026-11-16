-- Brewfinder on catalog.cafe: catalog, review queue and owner-only admin.
-- Each record keeps the same JSON shape the site and research agent already use, in a `doc` column.

create table if not exists public.gear      (id text primary key, doc jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table if not exists public.beans     (id text primary key, doc jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table if not exists public.meta      (id text primary key, doc jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table if not exists public.proposals (id text primary key, status text not null default 'pending' check (status in ('pending','approved','rejected')),
                                             doc jsonb not null, created_at timestamptz not null default now(), decided_at timestamptz);
create table if not exists public.runs      (id text primary key, doc jsonb not null, created_at timestamptz not null default now());
create table if not exists public.admin_emails (email text primary key);  -- owner emails; add yours here

create index if not exists proposals_status_idx on public.proposals (status, created_at);

-- Who counts as the owner
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.admin_emails a
    join auth.users u on lower(u.email) = lower(a.email)
    where u.id = auth.uid() and u.email_confirmed_at is not null
  );
$$;

alter table public.gear      enable row level security;
alter table public.beans     enable row level security;
alter table public.meta      enable row level security;
alter table public.proposals enable row level security;
alter table public.runs      enable row level security;
alter table public.admin_emails enable row level security;  -- no policies: not readable through the API

-- Anyone can read the public catalog; only the owner can change it
create policy "catalog read"  on public.gear  for select to anon, authenticated using (true);
create policy "catalog write" on public.gear  for all    to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "beans read"    on public.beans for select to anon, authenticated using (true);
create policy "beans write"   on public.beans for all    to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "meta read"     on public.meta  for select to anon, authenticated using (true);
create policy "meta write"    on public.meta  for all    to authenticated using (public.is_admin()) with check (public.is_admin());
-- The review queue and run log are owner-only
create policy "proposals owner" on public.proposals for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "runs owner"      on public.runs      for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Approve a proposal: applies the change and marks it approved, in one transaction
create or replace function public.apply_proposal(pid text) returns void
language plpgsql security definer set search_path = public as $$
declare p record; d jsonb; tbl text; stamp jsonb;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  select * into p from public.proposals where id = pid and status = 'pending' for update;
  if not found then raise exception 'proposal not pending'; end if;
  d := p.doc;
  tbl := case when d->>'collection' = 'beans' then 'beans' else 'gear' end;
  stamp := jsonb_build_object('updated_at', to_char(now() at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"'), 'sources', coalesce(d->'sources','[]'::jsonb));
  if d->>'kind' = 'add' then
    execute format('insert into public.%I (id, doc) values ($1, $2) on conflict (id) do update set doc = excluded.doc, updated_at = now()', tbl)
      using d->>'doc_id', coalesce(d->'data','{}'::jsonb) || jsonb_build_object('status','active') || stamp;
  elsif d->>'kind' = 'update' then
    execute format('update public.%I set doc = doc || $2, updated_at = now() where id = $1', tbl)
      using d->>'doc_id', coalesce(d->'changes','{}'::jsonb) || stamp;
  elsif d->>'kind' = 'discontinue' then
    execute format('update public.%I set doc = doc || $2, updated_at = now() where id = $1', tbl)
      using d->>'doc_id', jsonb_build_object('status','discontinued') || stamp;
  end if;
  update public.proposals set status = 'approved', decided_at = now() where id = pid;
end $$;

create or replace function public.reject_proposal(pid text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  update public.proposals set status = 'rejected', decided_at = now() where id = pid and status = 'pending';
end $$;

revoke all on function public.apply_proposal(text)  from public, anon;
revoke all on function public.reject_proposal(text) from public, anon;
grant execute on function public.apply_proposal(text)  to authenticated;
grant execute on function public.reject_proposal(text) to authenticated;
grant execute on function public.is_admin()             to anon, authenticated;
