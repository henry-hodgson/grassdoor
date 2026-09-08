-- Add map coordinates to Grassdoor pitches.
-- Nullable so existing pitch records continue to work until coordinates are populated.

alter table public.dim_pitches
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.dim_pitches
  drop constraint if exists dim_pitches_latitude_check,
  drop constraint if exists dim_pitches_longitude_check;

alter table public.dim_pitches
  add constraint dim_pitches_latitude_check
    check (latitude is null or latitude between -90 and 90),
  add constraint dim_pitches_longitude_check
    check (longitude is null or longitude between -180 and 180);

comment on column public.dim_pitches.latitude is 'Pitch latitude in decimal degrees (WGS84).';
comment on column public.dim_pitches.longitude is 'Pitch longitude in decimal degrees (WGS84).';
