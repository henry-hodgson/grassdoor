# Grassdoor data platform

Grassdoor uses a deliberately small two-layer model.

## Operational layer

The website reads and writes the Supabase `public` schema:

- `public.dim_pitches` — pitch metadata and location.
- `public.fct_reviews` — player-submitted ratings and prices.

## Warehouse layer

The migration `supabase/2026-10-06_data_warehouse_foundation.sql` adds a read-oriented `warehouse` schema:

- `warehouse.dim_pitch` — cleaned pitch dimension.
- `warehouse.fct_review` — normalized review facts.
- `warehouse.mart_pitch_performance` — one row per pitch with ratings, price, review volume, recency and a composite Grassdoor score.
- `warehouse.mart_area_performance` — area-level benchmarks.
- `warehouse.mart_monthly_reviews` — review growth and quality trends.

This uses views rather than a separate database or ETL service. For the current product size that keeps the system cheap, understandable and always current.

## Example queries

Top pitches with enough evidence:

```sql
select *
from warehouse.mart_pitch_performance
where review_count >= 3
order by grassdoor_score desc, review_count desc;
```

Area value comparison:

```sql
select *
from warehouse.mart_area_performance
where review_count >= 5
order by avg_overall_experience desc, avg_price_per_team asc;
```

Growth:

```sql
select *
from warehouse.mart_monthly_reviews
order by month;
```

## Next data milestones

As usage grows, the highest-value additions are:

- authenticated reviewer IDs while keeping display names optional;
- separate `venues` and `pitches` entities so a venue can contain several surfaces;
- review moderation status and abuse controls;
- outbound booking-click or conversion events;
- source and ingestion metadata for imported pitch listings;
- materialized marts once query volume or row counts justify scheduled refreshes;
- a ranking model that uses review confidence as well as average score.
