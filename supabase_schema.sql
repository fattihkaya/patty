-- PetAI Supabase schema (core tables used by app)
-- Run in Supabase SQL Editor.

-- Extensions
create extension if not exists pgcrypto;

-- Utility: updated_at trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =========================
-- subscription_plans
-- =========================
create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  display_name text not null,
  description text,
  price_monthly numeric(10,2) not null default 0,
  price_yearly numeric(10,2) not null default 0,
  features jsonb not null default '{}'::jsonb,
  trial_days int not null default 0,
  is_active boolean not null default true,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_subscription_plans_updated_at on public.subscription_plans;
create trigger trg_subscription_plans_updated_at
before update on public.subscription_plans
for each row execute function public.set_updated_at();

alter table public.subscription_plans enable row level security;

-- Anyone can read active plans (used for paywall UI)
drop policy if exists "subscription_plans_select" on public.subscription_plans;
create policy "subscription_plans_select"
on public.subscription_plans
for select
using (is_active = true);

-- (Optional) restrict inserts/updates to service role only.

-- =========================
-- user_subscriptions
-- =========================
create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id),
  status text not null check (status in ('active','canceled','expired','trial','grace_period')),
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  canceled_at timestamptz,
  original_transaction_id text,
  revenuecat_customer_id text,
  revenuecat_entitlements jsonb,
  platform text check (platform in ('ios','android')),
  billing_period text check (billing_period in ('monthly','yearly')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_subscriptions_user_id on public.user_subscriptions(user_id);
create index if not exists idx_user_subscriptions_plan_id on public.user_subscriptions(plan_id);

drop trigger if exists trg_user_subscriptions_updated_at on public.user_subscriptions;
create trigger trg_user_subscriptions_updated_at
before update on public.user_subscriptions
for each row execute function public.set_updated_at();

alter table public.user_subscriptions enable row level security;

drop policy if exists "user_subscriptions_select_own" on public.user_subscriptions;
create policy "user_subscriptions_select_own"
on public.user_subscriptions
for select
using (auth.uid() = user_id);

drop policy if exists "user_subscriptions_insert_own" on public.user_subscriptions;
create policy "user_subscriptions_insert_own"
on public.user_subscriptions
for insert
with check (auth.uid() = user_id);

drop policy if exists "user_subscriptions_update_own" on public.user_subscriptions;
create policy "user_subscriptions_update_own"
on public.user_subscriptions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- =========================
-- usage_tracking
-- =========================
create table if not exists public.usage_tracking (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  feature_type text not null,
  usage_date date not null,
  usage_count int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, feature_type, usage_date)
);

create index if not exists idx_usage_tracking_user_month on public.usage_tracking(user_id, usage_date);

drop trigger if exists trg_usage_tracking_updated_at on public.usage_tracking;
create trigger trg_usage_tracking_updated_at
before update on public.usage_tracking
for each row execute function public.set_updated_at();

alter table public.usage_tracking enable row level security;

drop policy if exists "usage_tracking_select_own" on public.usage_tracking;
create policy "usage_tracking_select_own"
on public.usage_tracking
for select
using (auth.uid() = user_id);

drop policy if exists "usage_tracking_insert_own" on public.usage_tracking;
create policy "usage_tracking_insert_own"
on public.usage_tracking
for insert
with check (auth.uid() = user_id);

drop policy if exists "usage_tracking_update_own" on public.usage_tracking;
create policy "usage_tracking_update_own"
on public.usage_tracking
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- =========================
-- pet_stories
-- =========================
create table if not exists public.pet_stories (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  image_url text not null,
  caption text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  view_count int not null default 0,
  is_active boolean not null default true
);

create index if not exists idx_pet_stories_pet_id on public.pet_stories(pet_id);
create index if not exists idx_pet_stories_user_id on public.pet_stories(user_id);
create index if not exists idx_pet_stories_active_expires on public.pet_stories(is_active, expires_at);

alter table public.pet_stories enable row level security;

drop policy if exists "pet_stories_select_own" on public.pet_stories;
create policy "pet_stories_select_own"
on public.pet_stories
for select
using (auth.uid() = user_id);

drop policy if exists "pet_stories_insert_own" on public.pet_stories;
create policy "pet_stories_insert_own"
on public.pet_stories
for insert
with check (auth.uid() = user_id);

drop policy if exists "pet_stories_update_own" on public.pet_stories;
create policy "pet_stories_update_own"
on public.pet_stories
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "pet_stories_delete_own" on public.pet_stories;
create policy "pet_stories_delete_own"
on public.pet_stories
for delete
using (auth.uid() = user_id);
