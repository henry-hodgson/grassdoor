-- London starter pitches + day-of-week support
-- Sources checked October 2026. Booking availability still varies by date/time.

begin;

alter table public.venues
  add column if not exists address text,
  add column if not exists source_url text;

alter table public.dim_pitches
  add column if not exists available_days text[] not null
    default array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']::text[];

alter table public.fct_reviews
  add column if not exists day_of_week text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'fct_reviews_day_of_week_check') then
    alter table public.fct_reviews
      add constraint fct_reviews_day_of_week_check
      check (
        day_of_week is null or day_of_week in
        ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
      );
  end if;
end $$;

-- Verified starter venues.
insert into public.venues
  (name, area, nearest_station, address, booking_url, website_url, source_url)
select *
from (
  values
    (
      'GOALS Beckenham',
      'South London',
      'Elmers End',
      'Elmers End Road, Beckenham, BR3 4EJ',
      'https://www.goalsfootball.co.uk/play/football/one/',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/beckenham',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/beckenham'
    ),
    (
      'GOALS Gillette Corner',
      'West London',
      'Syon Lane',
      'MacFarlane Lane, Isleworth, TW7 5DB',
      'https://www.goalsfootball.co.uk/play/football/one/',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/gillette-corner/',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/gillette-corner/'
    ),
    (
      'GOALS Wimbledon',
      'South West London',
      'New Malden',
      'Beverley Way, London, KT3 4PH',
      'https://www.goalsfootball.co.uk/play/football/one/',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/wimbledon',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/wimbledon'
    ),
    (
      'GOALS Ruislip',
      'West London',
      'Ruislip Gardens',
      'Victoria Road, Ruislip, HA4 0LN',
      'https://www.goalsfootball.co.uk/play/football/one/',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/ruislip',
      'https://www.goalsfootball.co.uk/our-clubs/south-east/ruislip'
    ),
    (
      'Market Road Football Pitches',
      'North London',
      'Caledonian Road',
      'Market Road, Islington, London, N7 9PL',
      null,
      'https://www.better.org.uk/leisure-centre/london/islington/marketroad',
      'https://www.better.org.uk/leisure-centre/london/islington/marketroad'
    )
) as seed(name, area, nearest_station, address, booking_url, website_url, source_url)
where not exists (
  select 1
  from public.venues v
  where lower(v.name) = lower(seed.name)
);

-- Keep source metadata fresh for venues that may already exist from the previous backfill.
update public.venues
set
  address = coalesce(address, 'Market Road, Islington, London, N7 9PL'),
  website_url = coalesce(website_url, 'https://www.better.org.uk/leisure-centre/london/islington/marketroad'),
  source_url = coalesce(source_url, 'https://www.better.org.uk/leisure-centre/london/islington/marketroad')
where lower(name) = lower('Market Road Football Pitches');

-- Starter pitch products. One row represents a bookable format at a venue.
insert into public.dim_pitches
  (name, area, nearest_station, game_format, walls, overhead_net, men, women, under_18,
   showers, venue_id, surface_type, indoor, changing_rooms, parking, available_days)
select
  seed.pitch_name,
  seed.area,
  seed.station,
  seed.game_format,
  seed.walls,
  seed.overhead_net,
  true,
  true,
  true,
  seed.showers,
  v.id,
  seed.surface_type,
  false,
  seed.changing_rooms,
  seed.parking,
  array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']::text[]
from (
  values
    ('GOALS Beckenham — 5-a-side', 'GOALS Beckenham', 'South London', 'Elmers End', '5-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Beckenham — 8-a-side', 'GOALS Beckenham', 'South London', 'Elmers End', '8-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Gillette Corner — 5-a-side', 'GOALS Gillette Corner', 'West London', 'Syon Lane', '5-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Gillette Corner — 8-a-side', 'GOALS Gillette Corner', 'West London', 'Syon Lane', '8-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Wimbledon — 5-a-side', 'GOALS Wimbledon', 'South West London', 'New Malden', '5-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Wimbledon — 7-a-side', 'GOALS Wimbledon', 'South West London', 'New Malden', '7-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Ruislip — 5-a-side', 'GOALS Ruislip', 'West London', 'Ruislip Gardens', '5-a-side', true, false, true, 'ProTurf', true, true),
    ('GOALS Ruislip — 7-a-side', 'GOALS Ruislip', 'West London', 'Ruislip Gardens', '7-a-side', true, false, true, 'ProTurf', true, true),
    ('Market Road — 5-a-side', 'Market Road Football Pitches', 'North London', 'Caledonian Road', '5-a-side', false, false, false, '3G', true, false),
    ('Market Road — 11-a-side', 'Market Road Football Pitches', 'North London', 'Caledonian Road', '11-a-side', false, false, false, '3G', true, false)
) as seed(
  pitch_name, venue_name, area, station, game_format, walls, overhead_net,
  showers, surface_type, changing_rooms, parking
)
join public.venues v on lower(v.name) = lower(seed.venue_name)
where not exists (
  select 1 from public.dim_pitches p where lower(p.name) = lower(seed.pitch_name)
);

create index if not exists idx_dim_pitches_available_days
  on public.dim_pitches using gin (available_days);
create index if not exists idx_fct_reviews_day_of_week
  on public.fct_reviews (day_of_week);

commit;
