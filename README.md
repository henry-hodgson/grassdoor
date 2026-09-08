# Grassdoor

Grassdoor is a mobile-friendly London football pitch review MVP.

## What is included

- Grassdoor branding and responsive UI
- Pitch directory with search and filters for area, format, facilities and suitability
- Interactive London map using Leaflet + OpenStreetMap
- Pitch markers sourced from nullable Supabase latitude/longitude fields
- Individual pitch profile pages via `pitch.html?id=<id>` with a location map when coordinates exist
- Review averages and individual review summaries loaded from Supabase `fct_reviews`
- Review form with pitch selection and deep-link support via `review.html?pitch=<id>`
- Pitch metadata loaded from Supabase `dim_pitches`
- Fallback starter data so the UI does not break if Supabase is temporarily unavailable

## Supabase pitch schema

The frontend expects `public.dim_pitches` to contain:

- `id`
- `created_at`
- `name`
- `area`
- `nearest_station`
- `game_format`
- `length`
- `width`
- `walls`
- `overhead_net`
- `men`
- `women`
- `under_18`
- `showers`
- `latitude` (nullable double precision)
- `longitude` (nullable double precision)

Run `supabase/2026-09-08_add_pitch_coordinates.sql` in the Supabase SQL editor to add the two coordinate columns and range checks.

Pitches without coordinates still appear in the directory and review flow; they simply do not receive a map marker until latitude and longitude are populated.

Example coordinate update:

```sql
update public.dim_pitches
set latitude = 51.5283,
    longitude = -0.0862
where name = 'Powerleague Shoreditch';
```

Use decimal-degree WGS84 coordinates: positive latitude is north, negative longitude is west.

## Reviews

Reviews use `public.fct_reviews` and the existing fields:

- `reviewer_name`
- `pitch_id`
- `quality_of_opposition`
- `quality_of_pitch`
- `price_per_team_per_game`
- `overall_experience`

The relationship should be:

```text
fct_reviews.pitch_id -> dim_pitches.id
```

Average team price displayed on Grassdoor is calculated from `fct_reviews.price_per_team_per_game`.

## RLS

Recommended MVP permissions:

- `dim_pitches`: public SELECT only
- `fct_reviews`: public SELECT + INSERT only
- no public UPDATE or DELETE policies

Adding latitude and longitude does not require a new RLS policy; the existing public SELECT policy on `dim_pitches` covers those fields.

## Map

The frontend uses Leaflet with OpenStreetMap tiles, so there is no map API key or map secret to configure.

The directory map automatically follows the active search and filters. Pitch detail pages show a dedicated map when that pitch has valid coordinates.

## Run locally

Because this is a static frontend, serve the directory with any local web server, for example:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000`.
