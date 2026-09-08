# Grassdoor

Grassdoor is a mobile-friendly London football pitch review MVP.

## What is included

- Grassdoor branding and responsive UI
- Pitch directory with search and filters for area, format, surface and price
- Interactive Leaflet/OpenStreetMap pitch map
- Individual pitch profile pages via `pitch.html?id=<pitch_id>`
- Review averages and individual review summaries loaded from Supabase `fct_reviews`
- Review form with pitch selection and deep-link support via `review.html?pitch=<pitch_id>`
- Dynamic pitch metadata loading from Supabase when a public `dim_pitches` or `pitches` table exists
- Curated London fallback pitch data so the site remains usable before the pitch table is configured

## Supabase

The existing public Supabase client configuration remains in `script.js`.

Reviews use the existing `fct_reviews` fields:

- `reviewer_name`
- `pitch_id`
- `quality_of_opposition`
- `quality_of_pitch`
- `price_per_team_per_game`
- `overall_experience`

For pitch metadata, the frontend first tries `dim_pitches`, then `pitches`. It normalizes common column names such as `pitch_id` / `id`, `pitch_name` / `name`, `latitude` / `lat`, and `longitude` / `lng`.

## Run locally

Because this is a static frontend, serve the directory with any local web server, for example:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000`.
