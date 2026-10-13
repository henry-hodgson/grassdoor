-- Consolidate legacy review policies and enforce moderation at the database boundary.
begin;

drop policy if exists "Allow anonymous inserts into fct_reviews" on public.fct_reviews;
drop policy if exists "Public can submit reviews" on public.fct_reviews;
drop policy if exists "Allow public read of fct_reviews" on public.fct_reviews;
drop policy if exists "Public can view reviews" on public.fct_reviews;
drop policy if exists "public can read approved reviews" on public.fct_reviews;

create policy "public can read approved reviews"
on public.fct_reviews
for select
to anon, authenticated
using (moderation_status = 'approved');

create policy "public can submit reviews"
on public.fct_reviews
for insert
to anon, authenticated
with check (
  quality_of_opposition between 1 and 5
  and quality_of_pitch between 1 and 5
  and overall_experience between 1 and 5
  and price_per_team_per_game between 0 and 500
  and (reviewer_name is null or char_length(reviewer_name::text) <= 80)
  and moderation_status = 'pending'
);

commit;
