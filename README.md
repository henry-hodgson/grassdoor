# Grassdoor

Grassdoor is a mobile-friendly London football pitch review product.

## What it does

- Search and filter London football pitches
- Compare format, facilities, dimensions, location and player ratings
- See typical price paid per team
- Browse pitch locations on an interactive Leaflet/OpenStreetMap map
- Read pitch-specific player reviews
- Submit structured reviews directly to Supabase
- Moderate new reviews before publishing them
- Track pitch views and outbound booking intent
- Support venue-level booking URLs and richer pitch facilities
- Continue rendering fallback pitch data if Supabase is temporarily unavailable

## Data architecture

The operational app uses:

- `public.dim_pitches` for pitch metadata
- `public.fct_reviews` for player reviews

Run the SQL files in `supabase/` in date order. The October 2026 migration adds data-quality constraints, indexes and a `warehouse` analytics schema with pitch, area and monthly marts.

See `docs/data-platform.md` for the warehouse model and `docs/trust-and-growth.md` for venues, moderation, product analytics and the account-ready schema.

## Security

Recommended MVP permissions:

- `dim_pitches`: public SELECT only
- `fct_reviews`: public SELECT + INSERT only
- no public UPDATE or DELETE
- warehouse/admin access restricted to trusted roles

The browser contains only the Supabase publishable key. Never put a Supabase service-role key in frontend code.

## Map

The frontend uses Leaflet with OpenStreetMap tiles. Pitches with valid latitude and longitude appear automatically, so no map API secret is required.

## Run locally

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000`.
