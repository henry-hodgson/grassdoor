-- Grassdoor analytics/data warehouse foundation
-- Run after public.dim_pitches and public.fct_reviews exist.
-- Views are used first so analytics stay current without another ETL service.

begin;

alter table public.fct_reviews
  add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_pitch_quality_check') then
    alter table public.fct_reviews add constraint fct_reviews_pitch_quality_check
      check (quality_of_pitch between 1 and 5);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_opposition_quality_check') then
    alter table public.fct_reviews add constraint fct_reviews_opposition_quality_check
      check (quality_of_opposition between 1 and 5);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_overall_experience_check') then
    alter table public.fct_reviews add constraint fct_reviews_overall_experience_check
      check (overall_experience between 1 and 5);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_price_check') then
    alter table public.fct_reviews add constraint fct_reviews_price_check
      check (price_per_team_per_game >= 0 and price_per_team_per_game <= 500);
  end if;
end $$;

create index if not exists idx_fct_reviews_pitch_id on public.fct_reviews (pitch_id);
create index if not exists idx_fct_reviews_created_at on public.fct_reviews (created_at desc);
create index if not exists idx_dim_pitches_area on public.dim_pitches (area);
create index if not exists idx_dim_pitches_game_format on public.dim_pitches (game_format);

create schema if not exists warehouse;

create or replace view warehouse.dim_pitch
with (security_invoker = true)
as
select
  p.id as pitch_key,
  p.name,
  p.area,
  p.nearest_station,
  p.game_format,
  p.length,
  p.width,
  case when p.length is not null and p.width is not null then p.length * p.width end as area_sqm,
  p.walls,
  p.overhead_net,
  p.showers,
  p.men,
  p.women,
  p.under_18,
  p.latitude,
  p.longitude,
  p.created_at as pitch_created_at
from public.dim_pitches p;

create or replace view warehouse.fct_review
with (security_invoker = true)
as
select
  r.pitch_id as pitch_key,
  r.created_at as reviewed_at,
  date_trunc('day', r.created_at)::date as review_date,
  r.quality_of_pitch::numeric as pitch_quality_score,
  r.quality_of_opposition::numeric as opposition_quality_score,
  r.overall_experience::numeric as overall_experience_score,
  r.price_per_team_per_game::numeric as price_per_team,
  nullif(trim(r.reviewer_name), '') as reviewer_name
from public.fct_reviews r;

create or replace view warehouse.mart_pitch_performance
with (security_invoker = true)
as
select
  p.pitch_key,
  p.name,
  p.area,
  p.nearest_station,
  p.game_format,
  count(r.pitch_key) as review_count,
  round(avg(r.pitch_quality_score), 2) as avg_pitch_quality,
  round(avg(r.opposition_quality_score), 2) as avg_opposition_quality,
  round(avg(r.overall_experience_score), 2) as avg_overall_experience,
  round(avg(r.price_per_team), 2) as avg_price_per_team,
  percentile_cont(0.5) within group (order by r.price_per_team) as median_price_per_team,
  max(r.reviewed_at) as last_reviewed_at,
  case when count(r.pitch_key) = 0 then null else
    round((
      avg(r.overall_experience_score) * 0.50 +
      avg(r.pitch_quality_score) * 0.35 +
      avg(r.opposition_quality_score) * 0.15
    )::numeric, 2)
  end as grassdoor_score
from warehouse.dim_pitch p
left join warehouse.fct_review r on r.pitch_key = p.pitch_key
group by p.pitch_key, p.name, p.area, p.nearest_station, p.game_format;

create or replace view warehouse.mart_area_performance
with (security_invoker = true)
as
select
  p.area,
  count(distinct p.pitch_key) as pitch_count,
  count(r.pitch_key) as review_count,
  round(avg(r.overall_experience_score), 2) as avg_overall_experience,
  round(avg(r.pitch_quality_score), 2) as avg_pitch_quality,
  round(avg(r.price_per_team), 2) as avg_price_per_team
from warehouse.dim_pitch p
left join warehouse.fct_review r on r.pitch_key = p.pitch_key
group by p.area;

create or replace view warehouse.mart_monthly_reviews
with (security_invoker = true)
as
select
  date_trunc('month', r.reviewed_at)::date as month,
  count(*) as reviews_submitted,
  count(distinct r.pitch_key) as pitches_reviewed,
  round(avg(r.overall_experience_score), 2) as avg_overall_experience,
  round(avg(r.price_per_team), 2) as avg_price_per_team
from warehouse.fct_review r
group by 1
order by 1;

comment on schema warehouse is 'Read-oriented analytics layer for Grassdoor.';
comment on view warehouse.mart_pitch_performance is 'Pitch-level review KPIs and composite Grassdoor score.';

commit;
