-- Detroit Click Protocol: Supabase SQL setup
-- Paste all of this into Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Auth users are created by Supabase Auth; this creates their public profile automatically.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  clicks bigint not null default 0 check (clicks >= 0),
  last_click_at timestamptz
);

alter table public.profiles enable row level security;

-- Remove direct write access: the browser must never set its own score.
revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;

drop policy if exists "Signed-in users can read leaderboard" on public.profiles;
create policy "Signed-in users can read leaderboard"
on public.profiles for select to authenticated
using (true);

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_name text;
begin
  chosen_name := coalesce(new.raw_user_meta_data ->> 'username', '');
  if chosen_name !~ '^[[:alnum:]_-]{3,18}$' then
    raise exception 'INVALID_USERNAME';
  end if;

  insert into public.profiles (id, username, clicks)
  values (new.id, chosen_name, 0);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.create_profile_for_new_user();

-- Server-side click function: one click per call, per-account cooldown.
-- Client cannot provide an amount or directly update clicks.
create or replace function public.click_once()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid;
  current_clicks bigint;
  last_at timestamptz;
  now_at timestamptz := clock_timestamp();
begin
  caller_id := auth.uid();
  if caller_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  select p.clicks, p.last_click_at
    into current_clicks, last_at
    from public.profiles p
    where p.id = caller_id
    for update;

  if not found then
    raise exception 'PROFILE_NOT_FOUND';
  end if;

  if last_at is not null and now_at - last_at < interval '90 milliseconds' then
    raise exception 'CLICK_COOLDOWN';
  end if;

  update public.profiles
     set clicks = clicks + 1,
         last_click_at = now_at
   where id = caller_id
   returning clicks into current_clicks;

  return current_clicks;
end;
$$;

revoke all on function public.click_once() from public, anon;
grant execute on function public.click_once() to authenticated;
