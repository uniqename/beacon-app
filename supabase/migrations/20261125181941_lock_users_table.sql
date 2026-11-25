-- Lock the users table. The app's public (anon) key is inside every shipped build,
-- so the public must not be able to read or change account rows.
-- Server-side code (service role) bypasses RLS and is unaffected.
alter table if exists public.users enable row level security;
-- No policies are created for anon or authenticated on purpose.
revoke all on table public.users from anon;
revoke all on table public.users from authenticated;
