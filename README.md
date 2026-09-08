# Grassdoor

Grassdoor is a mobile-friendly London football pitch review MVP.

## What is included

- Grassdoor branding and responsive UI
- Pitch directory with search and filters for area, format, facilities and suitability
- Individual pitch profile pages via `pitch.html?id=<id>`
- Review averages and individual review summaries loaded from Supabase `fct_reviews`
- Review form with pitch selection and deep-link support via `review.html?pitch=<id>`
- Pitch metadata loaded from Supabase `dim_pitches`
- Fallback starter data matching the same schema so the UI does not break if Supabase is temporarily unavailable

## Exact Supabase pitch schema

The frontend now expects `public.dim_pitches` to contain exactly these fields:

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

The frontend does not assume that pitch records contain surface, latitude/longitude, borough, description, booking URL or pitch-level price fields.

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

## Run locally

Because this is a static frontend, serve the directory with any local web server, for example:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000`.
