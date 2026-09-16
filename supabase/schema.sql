-- AIEI LMS — Supabase schema (v2 — full coverage)
--
-- Safe to re-run: drops and recreates every table below. Run this in the
-- Supabase SQL Editor, then run seed.sql right after.
--
-- ⚠️ DEMO-ONLY SECURITY MODEL: the app has no real Supabase Auth session yet
-- (Login screen is a role-picker, not a password check). RLS is enabled on
-- every table, but the policies below grant the `anon` role full read AND
-- write access everywhere, since the demo UI (grading, allocation, roster
-- edits) mutates data without a real user session. Do not carry this policy
-- set into a real production deployment with real user data.

drop table if exists
  enrollment_monthly_stats, enrollment_candidates, course_sections,
  student_certifications, student_materials, student_courses,
  lecturer_courses, module_certs, certifications,
  course_tags, tags, module_materials, course_modules, courses,
  admins, students, lecturers
cascade;

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
  program_track text not null default 'General Enterprise Track',
  cohort text not null default '2025-Q1',
  gpa numeric(3, 2) not null default 3.50,
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
  course_code text not null unique,
  course_title text not null,
  course_description text not null,
  category text not null default 'techData',
  image_url text,
  schedule_text text not null default 'Self-paced',
  capacity int not null default 40,
  created_at timestamptz not null default now()
);

create table course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  module_name text not null,
  module_description text not null default '',
  module_sorting int not null default 0,
  is_published boolean not null default true,
  unlock_at date,
  created_at timestamptz not null default now()
);

create table module_materials (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references course_modules(id) on delete cascade,
  material_name text not null,
  material_type text not null check (material_type in ('lesson', 'quiz', 'assignment', 'video', 'file')),
  material_content jsonb not null default '{}'::jsonb,
  material_sorting int not null default 0,
  is_published boolean not null default true,
  due_at timestamptz,
  attached_files jsonb not null default '[]'::jsonb,
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
  description text not null default '',
  badge_icon text,
  competencies text[] not null default '{}',
  hash text,
  narrative text not null default '',
  accrediting_bodies text[] not null default '{}',
  metrics jsonb not null default '{}'::jsonb
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
  grade text,
  overall_score numeric(5, 2),
  attendance_percentage int not null default 100,
  risk_status text not null default 'on_track' check (risk_status in ('on_track', 'at_risk', 'critical')),
  sponsorship text not null default 'Self-Enrolled',
  last_activity_at timestamptz not null default now(),
  is_online_now boolean not null default false,
  enrolled_at timestamptz not null default now(),
  primary key (student_id, course_id)
);

create table student_materials (
  student_id uuid not null references students(id) on delete cascade,
  material_id uuid not null references module_materials(id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started', 'in_progress', 'completed')),
  score int,
  attempts int not null default 0,
  submission_content jsonb not null default '{}'::jsonb,
  feedback text,
  graded_by uuid references lecturers(id),
  graded_at timestamptz,
  completed_at timestamptz,
  primary key (student_id, material_id)
);

create table student_certifications (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  cert_id uuid not null references certifications(id) on delete cascade,
  status text not null default 'in_progress' check (status in ('earned', 'in_progress', 'revoked')),
  progress_percentage int not null default 0,
  issued_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz,
  revocation_reason text,
  case_ref text,
  inspecting_officer text,
  cohort_label text,
  created_at timestamptz not null default now()
);

create table course_sections (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  section_code text not null,
  role_label text not null default 'Primary Instructor',
  term text not null default 'Fall 2025',
  schedule_text text not null default 'TBD',
  lecturer_id uuid references lecturers(id),
  capacity int not null default 30,
  enrolled_count int not null default 0,
  start_date date,
  status text not null default 'scheduled' check (status in ('scheduled', 'in_progress', 'completed', 'cancelled'))
);

create table enrollment_candidates (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  student_employee_id text,
  student_email text not null,
  department text not null default '',
  cohort text not null default '',
  target_course_id uuid not null references courses(id) on delete cascade,
  prerequisite_status text not null default 'met' check (prerequisite_status in ('met', 'pending', 'not_met')),
  prerequisite_detail text not null default '',
  standing_detail text not null default 'Academic Good Standing',
  sponsorship text not null default 'Self-Enrolled',
  queue_tag text,
  needs_review boolean not null default false,
  requested_at timestamptz not null default now()
);

create table enrollment_monthly_stats (
  id uuid primary key default gen_random_uuid(),
  month_label text not null,
  new_enrollments int not null,
  sort_order int not null default 0
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
alter table student_certifications enable row level security;
alter table course_sections enable row level security;
alter table enrollment_candidates enable row level security;
alter table enrollment_monthly_stats enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array[
    'lecturers', 'students', 'admins', 'courses', 'course_modules',
    'module_materials', 'tags', 'course_tags', 'certifications', 'module_certs',
    'lecturer_courses', 'student_courses', 'student_materials',
    'student_certifications', 'course_sections', 'enrollment_candidates',
    'enrollment_monthly_stats'
  ]
  loop
    execute format('create policy "anon read" on %I for select using (true)', t);
    execute format('create policy "anon write" on %I for insert with check (true)', t);
    execute format('create policy "anon update" on %I for update using (true)', t);
    execute format('create policy "anon delete" on %I for delete using (true)', t);
  end loop;
end $$;
