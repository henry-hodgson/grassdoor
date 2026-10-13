-- Add East London coverage to the starter dataset.
begin;

insert into public.venues
  (name, area, nearest_station, address, booking_url, website_url, source_url)
select
  'GOALS Dagenham',
  'East London',
  'Dagenham Dock',
  'Dagenham Leisure Park, Dagenham, RM9 6XW',
  'https://www.goalsfootball.co.uk/play/football/one/',
  'https://www.goalsfootball.co.uk/our-clubs/south-east/dagenham/',
  'https://www.goalsfootball.co.uk/our-clubs/south-east/dagenham/'
where not exists (
  select 1 from public.venues where lower(name) = lower('GOALS Dagenham')
);

insert into public.dim_pitches
  (name, area, nearest_station, game_format, walls, overhead_net, men, women, under_18,
   showers, venue_id, surface_type, indoor, changing_rooms, parking, available_days)
select
  seed.pitch_name,
  'East London',
  'Dagenham Dock',
  seed.game_format,
  true,
  false,
  true,
  true,
  true,
  true,
  v.id,
  'ProTurf',
  false,
  true,
  true,
  array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']::text[]
from (
  values
    ('GOALS Dagenham — 5-a-side', '5-a-side'),
    ('GOALS Dagenham — 7-a-side', '7-a-side'),
    ('GOALS Dagenham — 8-a-side', '8-a-side')
) as seed(pitch_name, game_format)
join public.venues v on lower(v.name) = lower('GOALS Dagenham')
where not exists (
  select 1 from public.dim_pitches p where lower(p.name) = lower(seed.pitch_name)
);

commit;
