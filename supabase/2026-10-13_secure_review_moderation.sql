-- Ensure pending/rejected reviews are not exposed through the public Data API.
begin;

drop policy if exists "public can read reviews" on public.fct_reviews;

create policy "public can read approved reviews"
on public.fct_reviews
for select
to anon, authenticated
using (moderation_status = 'approved');

commit;
