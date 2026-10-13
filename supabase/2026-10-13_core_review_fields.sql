-- Align Grassdoor with the core review and pitch discovery fields.
begin;

-- Pitch discovery fields.
alter table public.dim_pitches
  add column if not exists balls_provided boolean,
  add column if not exists referee_available boolean,
  add column if not exists supported_game_types text[] not null default '{}'::text[];

update public.dim_pitches
set supported_game_types = array_remove(array[
  case when men is true then 'Men' end,
  case when women is true then 'Women' end
], null)
where coalesce(array_length(supported_game_types, 1), 0) = 0;

-- Review fields.
alter table public.fct_reviews
  add column if not exists facility_balls boolean,
  add column if not exists facility_referee boolean,
  add column if not exists facility_showers boolean,
  add column if not exists game_format text,
  add column if not exists game_type text;

-- Overall experience is legacy: keep the column for history, stop requiring it.
alter table public.fct_reviews
  alter column overall_experience drop not null;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_game_format_check') then
    alter table public.fct_reviews
      add constraint fct_reviews_game_format_check
      check (game_format is null or game_format in ('5-a-side','7-a-side','11-a-side'));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_game_type_check') then
    alter table public.fct_reviews
      add constraint fct_reviews_game_type_check
      check (game_type is null or game_type in ('Men','Women','Mixed','Walking','Vets','Other'));
  end if;
end $$;

-- Remove only the 8-a-side starter rows we seeded in the previous migration.
delete from public.dim_pitches
where game_format = '8-a-side'
  and name in (
    'GOALS Beckenham — 8-a-side',
    'GOALS Gillette Corner — 8-a-side',
    'GOALS Dagenham — 8-a-side'
  )
  and not exists (
    select 1 from public.fct_reviews r where r.pitch_id = dim_pitches.id
  );

-- Replace public submit policy with the new required field set.
drop policy if exists "public can submit reviews" on public.fct_reviews;
create policy "public can submit reviews"
on public.fct_reviews
for insert
to anon, authenticated
with check (
  quality_of_opposition between 1 and 5
  and quality_of_pitch between 1 and 5
  and price_per_team_per_game between 0 and 500
  and day_of_week in ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
  and game_format in ('5-a-side','7-a-side','11-a-side')
  and game_type in ('Men','Women','Mixed','Walking','Vets','Other')
  and moderation_status = 'pending'
);

create index if not exists idx_dim_pitches_supported_game_types
  on public.dim_pitches using gin (supported_game_types);
create index if not exists idx_fct_reviews_game_type
  on public.fct_reviews (game_type);
create index if not exists idx_fct_reviews_game_format
  on public.fct_reviews (game_format);

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
  nullif(trim(r.reviewer_name), '') as reviewer_name,
  r.day_of_week,
  r.game_format,
  r.game_type,
  r.facility_balls,
  r.facility_referee,
  r.facility_showers
from public.fct_reviews r
where r.moderation_status = 'approved';

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
  round(avg(r.pitch_quality_score), 2) as grassdoor_score
from warehouse.dim_pitch p
left join warehouse.fct_review r on r.pitch_key = p.pitch_key
group by p.pitch_key, p.name, p.area, p.nearest_station, p.game_format;

commit;
