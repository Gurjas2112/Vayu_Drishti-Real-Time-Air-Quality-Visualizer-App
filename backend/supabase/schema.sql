-- Vayu Drishti Supabase Schema
-- Run this in Supabase SQL editor

-- Extensions
create extension if not exists pgcrypto; -- for gen_random_uuid
create extension if not exists cube;
create extension if not exists earthdistance;

-- Stations master data
create table if not exists public.stations (
	id uuid primary key default gen_random_uuid(),
	name text not null,
	state text,
	lat double precision not null,
	lon double precision not null,
	created_at timestamptz not null default now(),
	unique (name, lat, lon)
);

-- AQI readings (from CPCB and similar)
create table if not exists public.aqi_readings (
	id bigserial primary key,
	station_id uuid not null references public.stations(id) on delete cascade,
	timestamp timestamptz not null,
	aqi double precision not null,
	pollutants jsonb default '[]'::jsonb,
	created_at timestamptz not null default now(),
	unique (station_id, timestamp)
);

-- ISRO satellite readings (tile-based)
create table if not exists public.isro_satellite_readings (
	id bigserial primary key,
	tile_id text not null,
	lat double precision not null,
	lon double precision not null,
	timestamp timestamptz not null,
	aqi double precision not null,
	pollutants jsonb default '[]'::jsonb,
	created_at timestamptz not null default now(),
	unique (tile_id, timestamp)
);

-- FCM tokens for push notifications
create table if not exists public.fcm_tokens (
	token text primary key,
	user_id uuid references auth.users(id) on delete cascade,
	platform text check (platform in ('android','ios','web')),
	created_at timestamptz not null default now()
);

-- Latest AQI per station view
create or replace view public.latest_aqi as
select distinct on (r.station_id)
	r.station_id as station_id,
	s.name as station_name,
	s.lat as lat,
	s.lon as lon,
	r.aqi as aqi,
	r.pollutants as pollutants,
	r.timestamp as timestamp
from public.aqi_readings r
join public.stations s on s.id = r.station_id
order by r.station_id, r.timestamp desc;

-- Indexes
create index if not exists idx_aqi_readings_station_time on public.aqi_readings (station_id, timestamp desc);
create index if not exists idx_isro_readings_tile_time on public.isro_satellite_readings (tile_id, timestamp desc);
create index if not exists idx_stations_lat_lon on public.stations (lat, lon);

-- RLS
alter table public.stations enable row level security;
alter table public.aqi_readings enable row level security;
alter table public.isro_satellite_readings enable row level security;
alter table public.fcm_tokens enable row level security;

-- Policies: read-only for anon/authenticated, writes restricted
-- Stations
create policy if not exists stations_select_public on public.stations
	for select
	to anon, authenticated
	using (true);

-- AQI readings (select-only for anon/authenticated)
create policy if not exists aqi_readings_select_public on public.aqi_readings
	for select
	to anon, authenticated
	using (true);

-- ISRO readings (select-only for anon/authenticated)
create policy if not exists isro_readings_select_public on public.isro_satellite_readings
	for select
	to anon, authenticated
	using (true);

-- FCM tokens: user can manage own tokens; service role bypasses RLS
create policy if not exists fcm_tokens_select_own on public.fcm_tokens
	for select
	to authenticated
	using (auth.uid() = user_id);

create policy if not exists fcm_tokens_insert_own on public.fcm_tokens
	for insert
	to authenticated
	with check (auth.uid() = user_id);

create policy if not exists fcm_tokens_delete_own on public.fcm_tokens
	for delete
	to authenticated
	using (auth.uid() = user_id);

-- Note: Inserts/updates to aqi tables performed by backend using service role key (bypasses RLS)

-- Grants (optional, Supabase manages defaults)
grant usage on schema public to anon, authenticated;
