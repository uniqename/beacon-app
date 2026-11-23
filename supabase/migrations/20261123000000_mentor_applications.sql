-- SheBelongs mentor applications.
-- Sources: 'website' (online form), 'app' (in-app form), 'paper' (admin typed from a photo).
-- Public (anon) users can only INSERT a complete website application.
-- Only admins listed in admin_emails can read, update or add records.

create table if not exists public.admin_emails (
  email text primary key
);
alter table public.admin_emails enable row level security;

create or replace function public.is_mentor_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_emails a
    where lower(a.email) = lower(auth.jwt() ->> 'email')
  );
$$;
revoke all on function public.is_mentor_admin() from public;
grant execute on function public.is_mentor_admin() to authenticated;

create table if not exists public.mentor_applications (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  source text not null check (source in ('website', 'app', 'paper')),
  status text not null default 'submitted'
    check (status in ('submitted', 'in_review', 'interview', 'approved', 'declined', 'withdrawn')),
  full_name text not null check (char_length(full_name) between 2 and 200),
  email text not null check (char_length(email) between 5 and 320),
  phone text,
  city text,
  county text,
  age_21_plus boolean not null default false,
  availability text,
  can_commit_one_year boolean not null default false,
  experience text,
  motivation text,
  reference_name text,
  reference_contact text,
  agreed_background_check boolean not null default false,
  agreed_code_of_conduct boolean not null default false,
  paper_image_path text,
  admin_notes text,
  reviewed_at timestamptz,
  reviewed_by text
);

alter table public.mentor_applications enable row level security;

-- Anyone can submit a complete website application. Nothing else is public.
create policy "public submits website applications"
  on public.mentor_applications
  for insert
  to anon, authenticated
  with check (
    source = 'website'
    and status = 'submitted'
    and age_21_plus
    and agreed_background_check
    and agreed_code_of_conduct
  );

create policy "admins read applications"
  on public.mentor_applications
  for select
  to authenticated
  using (public.is_mentor_admin());

create policy "admins add applications"
  on public.mentor_applications
  for insert
  to authenticated
  with check (public.is_mentor_admin());

create policy "admins update applications"
  on public.mentor_applications
  for update
  to authenticated
  using (public.is_mentor_admin())
  with check (public.is_mentor_admin());

-- Private bucket for photos of paper forms.
insert into storage.buckets (id, name, public)
values ('mentor-paper-forms', 'mentor-paper-forms', false)
on conflict (id) do nothing;

create policy "admins upload paper forms"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'mentor-paper-forms' and public.is_mentor_admin());

create policy "admins read paper forms"
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'mentor-paper-forms' and public.is_mentor_admin());

-- Initial admin. Add more emails here as needed.
insert into public.admin_emails (email)
values ('consulting.enam@gmail.com')
on conflict (email) do nothing;
