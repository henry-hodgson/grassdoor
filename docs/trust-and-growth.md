# Trust, moderation and growth data

This migration adds the next product foundation without forcing a full account system into the MVP.

## Venues and pitches

`public.venues` represents the real-world facility. `public.dim_pitches` keeps representing an individual playing surface or bookable pitch and now has an optional `venue_id`.

The migration backfills one venue for every existing pitch. That is intentionally conservative: later, duplicate venue rows can be merged when several pitches are known to share the same facility.

New pitch attributes:

- `surface_type`
- `indoor`
- `changing_rooms`
- `parking`

Venue-level booking and website URLs live on `public.venues`.

## Review moderation

New reviews default to `pending`. Existing reviews are promoted to `approved` by the migration.

Statuses:

- `pending` — awaiting moderation
- `approved` — safe to display publicly
- `rejected` — hidden from the public product

Reviews can also carry:

- optional `review_text`
- optional `would_book_again`
- optional `played_at`
- optional `reviewer_user_id` linked to Supabase Auth in future

The website should only render approved reviews.

## Product events

`public.product_events` captures a deliberately small event vocabulary:

- `pitch_view`
- `booking_click`
- `review_started`
- `review_submitted`
- `directory_search`

The browser may insert events, but cannot read the event table. Do not put names, emails, IP addresses, free-form review text or other direct identifiers in event metadata.

## Useful marts

- `warehouse.mart_review_moderation` — moderation queue health
- `warehouse.mart_product_funnel` — daily product funnel
- `warehouse.mart_pitch_conversion` — pitch-level views, booking clicks and review activity

## Accounts

The schema is account-ready via `reviewer_user_id`, but the UI intentionally remains anonymous-first until the Supabase Auth provider, redirect URLs and email templates are configured. This avoids shipping a half-working sign-in flow.
