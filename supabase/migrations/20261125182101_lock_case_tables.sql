-- Case records (client intakes, plans, programs, notes, referrals) are sensitive.
-- The app's public key is inside every build, so the public must have no access.
-- Writes now go through the case-sync Edge Function, which checks the caller is staff.
-- Admins signed in with a staff account can still read and change these tables directly.

drop policy if exists staff_all_client_intakes on public.client_intakes;
drop policy if exists staff_all_case_plans on public.case_plans;
drop policy if exists staff_all_case_programs on public.case_programs;
drop policy if exists staff_all_case_notes on public.case_notes;
drop policy if exists staff_all_case_referrals on public.case_referrals;

revoke all on table public.client_intakes from anon;
revoke all on table public.case_plans from anon;
revoke all on table public.case_programs from anon;
revoke all on table public.case_notes from anon;
revoke all on table public.case_referrals from anon;

create policy "admins manage client intakes" on public.client_intakes
  for all to authenticated using (public.is_mentor_admin()) with check (public.is_mentor_admin());
create policy "admins manage case plans" on public.case_plans
  for all to authenticated using (public.is_mentor_admin()) with check (public.is_mentor_admin());
create policy "admins manage case programs" on public.case_programs
  for all to authenticated using (public.is_mentor_admin()) with check (public.is_mentor_admin());
create policy "admins manage case notes" on public.case_notes
  for all to authenticated using (public.is_mentor_admin()) with check (public.is_mentor_admin());
create policy "admins manage case referrals" on public.case_referrals
  for all to authenticated using (public.is_mentor_admin()) with check (public.is_mentor_admin());
