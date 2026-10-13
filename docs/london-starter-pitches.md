# London starter pitch dataset

The October 2026 starter migration adds a small, verified set of London football venues and separates bookable formats into individual pitch records.

## Sources

- GOALS Beckenham — official club page: https://www.goalsfootball.co.uk/our-clubs/south-east/beckenham
- GOALS Gillette Corner — official club page: https://www.goalsfootball.co.uk/our-clubs/south-east/gillette-corner/
- GOALS Wimbledon — official club page: https://www.goalsfootball.co.uk/our-clubs/south-east/wimbledon
- GOALS Ruislip — official club page: https://www.goalsfootball.co.uk/our-clubs/south-east/ruislip
- Market Road Football Pitches — Better: https://www.better.org.uk/leisure-centre/london/islington/marketroad

The seed migration adds 5-, 7-, 8- and 11-a-side options only where the source explicitly supports those formats.

## Day-of-week data

`dim_pitches.available_days` is a simple MVP field for the days a pitch is generally available. It is not real-time booking availability.

`fct_reviews.day_of_week` records the day a reviewer actually played. This makes it possible to compare experiences by weekday later, for example whether a venue feels busier or better value on Tuesdays versus weekends.

## Data quality rule

Do not invent coordinates, prices or detailed facilities. Leave fields blank until a trustworthy source or first-party venue data is available. The site already handles pitches without map coordinates.
