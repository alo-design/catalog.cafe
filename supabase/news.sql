-- News on catalog.cafe: short, sourced posts about new coffee gear.
-- Drafts are filed into `proposals` with collection = 'news' and wait for the owner.
-- Approving a draft publishes it here; only published posts are public.

create table if not exists public.news (
  id           text primary key,                       -- the post's slug, used in the URL (#news/<id>)
  doc          jsonb not null default '{}'::jsonb,     -- title, dek, summary, product, sections, compare, verdict, sources
  published_at timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists news_published_idx on public.news (published_at desc);

alter table public.news enable row level security;
drop policy if exists "news read"  on public.news;
drop policy if exists "news write" on public.news;
create policy "news read"  on public.news for select to anon, authenticated using (true);
create policy "news write" on public.news for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- Approve a proposal: applies the change and marks it approved, in one transaction.
-- collection 'news': kind 'add' or 'update' publishes the post, kind 'discontinue' unpublishes it.
create or replace function public.apply_proposal(pid text) returns void
language plpgsql security definer set search_path = public as $$
declare p record; d jsonb; tbl text; stamp jsonb; o jsonb;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  select * into p from public.proposals where id = pid and status = 'pending' for update;
  if not found then raise exception 'proposal not pending'; end if;
  d := p.doc;

  if d->>'collection' = 'news' then
    if d->>'kind' = 'discontinue' then
      delete from public.news where id = d->>'doc_id';
    else
      insert into public.news (id, doc, published_at, updated_at)
      values (d->>'doc_id', coalesce(d->'data','{}'::jsonb) || jsonb_build_object('sources', coalesce(d->'sources','[]'::jsonb)), now(), now())
      on conflict (id) do update set doc = excluded.doc, updated_at = now();
    end if;

  elsif d->>'collection' = 'offers' then
    if d->>'kind' = 'discontinue' then
      delete from public.offers where id = d->>'doc_id';
    else
      o := coalesce(d->'data', d->'changes', '{}'::jsonb);
      insert into public.offers (id, gear_id, retailer, retailer_slug, country, price, currency, in_stock, url, affiliate_url, checked_at, sources, updated_at)
      values (d->>'doc_id', o->>'gear_id', o->>'retailer', o->>'retailer_slug', o->>'country',
              (o->>'price')::numeric, o->>'currency', (o->>'in_stock')::boolean, o->>'url', o->>'affiliate_url',
              coalesce((o->>'checked_at')::timestamptz, now()), coalesce(d->'sources','[]'::jsonb), now())
      on conflict (id) do update set
        price = coalesce(excluded.price, offers.price), in_stock = coalesce(excluded.in_stock, offers.in_stock),
        url = excluded.url, affiliate_url = coalesce(excluded.affiliate_url, offers.affiliate_url),
        retailer = excluded.retailer, checked_at = excluded.checked_at, sources = excluded.sources, updated_at = now();
    end if;

  else
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
  end if;

  update public.proposals set status = 'approved', decided_at = now() where id = pid;
end $$;

revoke all on function public.apply_proposal(text) from public, anon;
grant execute on function public.apply_proposal(text) to authenticated;
