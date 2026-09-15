-- AIEI LMS — Supabase schema
--
-- Run this once in the Supabase SQL Editor (Project → SQL Editor → New query),
-- then run seed.sql right after.
--
-- ⚠️ DEMO-ONLY SECURITY MODEL: the app has no real Supabase Auth session yet
-- (Login screen is a role-picker, not a password check). RLS is enabled on
-- every table, but the policies below grant the `anon` role full read access
-- everywhere and write access on the tables the demo UI actually mutates
-- (progress/grading/allocation). Do not ship this policy set to a real
-- production deployment with real user data — tighten it once real Supabase
-- Auth + per-role policies are added.

create extension if not exists pgcrypto;

-- ── People ──────────────────────────────────────────────────────────────

create table lecturers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  title text not null,
  employee_id text not null unique,
  email text not null,
  department text not null,
  specialization text not null,
  credits_used int not null default 0,
  credits_max int not null default 15,
  status text not null default 'Active',
  accredited boolean not null default false,
  manageable boolean not null default true,
  created_at timestamptz not null default now()
);

create table students (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  student_id text not null unique,
  email text not null,
  department text not null,
  title text,
  created_at timestamptz not null default now()
);

create table admins (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  title text not null,
  email text not null,
  created_at timestamptz not null default now()
);

-- ── Courses / Modules / Materials ──────────────────────────────────────

create table courses (
  id uuid primary key default gen_random_uuid(),
  course_title text not null,
  course_description text not null,
  category text not null default 'techData',
  image_url text,
  created_at timestamptz not null default now()
);

create table course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  module_name text not null,
  module_description text not null default '',
  module_sorting int not null default 0,
  created_at timestamptz not null default now()
);

create table module_materials (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references course_modules(id) on delete cascade,
  material_name text not null,
  material_type text not null check (material_type in ('lesson', 'quiz', 'assignment', 'video')),
  material_content jsonb not null default '{}'::jsonb,
  material_sorting int not null default 0,
  created_at timestamptz not null default now()
);

-- ── Tags & Certifications ──────────────────────────────────────────────

create table tags (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  color_hex text not null default '#1D63ED',
  icon_name text
);

create table course_tags (
  course_id uuid not null references courses(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  primary key (course_id, tag_id)
);

create table certifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  issuing_body text not null,
  badge_icon text
);

create table module_certs (
  module_id uuid not null references course_modules(id) on delete cascade,
  cert_id uuid not null references certifications(id) on delete cascade,
  primary key (module_id, cert_id)
);

-- ── Mapping / progress tables ───────────────────────────────────────────

create table lecturer_courses (
  lecturer_id uuid not null references lecturers(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  primary key (lecturer_id, course_id)
);

create table student_courses (
  student_id uuid not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  progress_percentage int not null default 0,
  enrolled_at timestamptz not null default now(),
  primary key (student_id, course_id)
);

create table student_materials (
  student_id uuid not null references students(id) on delete cascade,
  material_id uuid not null references module_materials(id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started', 'in_progress', 'completed')),
  score int,
  attempts int not null default 0,
  completed_at timestamptz,
  primary key (student_id, material_id)
);

-- ── RLS (demo-only, see warning above) ──────────────────────────────────

alter table lecturers enable row level security;
alter table students enable row level security;
alter table admins enable row level security;
alter table courses enable row level security;
alter table course_modules enable row level security;
alter table module_materials enable row level security;
alter table tags enable row level security;
alter table course_tags enable row level security;
alter table certifications enable row level security;
alter table module_certs enable row level security;
alter table lecturer_courses enable row level security;
alter table student_courses enable row level security;
alter table student_materials enable row level security;

create policy "anon read" on lecturers for select using (true);
create policy "anon read" on students for select using (true);
create policy "anon read" on admins for select using (true);
create policy "anon read" on courses for select using (true);
create policy "anon read" on course_modules for select using (true);
create policy "anon read" on module_materials for select using (true);
create policy "anon read" on tags for select using (true);
create policy "anon read" on course_tags for select using (true);
create policy "anon read" on certifications for select using (true);
create policy "anon read" on module_certs for select using (true);
create policy "anon read" on lecturer_courses for select using (true);
create policy "anon read" on student_courses for select using (true);
create policy "anon read" on student_materials for select using (true);

-- Demo write access — the UI lets a "logged in" admin/faculty user mutate
-- these without a real auth session, so anon needs insert/update here too.
create policy "anon write" on student_materials for insert with check (true);
create policy "anon update" on student_materials for update using (true);
create policy "anon write" on student_courses for insert with check (true);
create policy "anon update" on student_courses for update using (true);
create policy "anon write" on lecturer_courses for insert with check (true);
create policy "anon delete" on lecturer_courses for delete using (true);
