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
  enrollment_candidates, course_sections,
  badge_awards, student_certifications, student_materials, student_courses,
  specialization_courses, track_courses, department_courses, role_courses, lecturer_courses, module_certs, certifications,
  course_tags, tags,
  template_content_blocks, template_sessions, template_modules, syllabus_templates,
  exam_question_options, exam_questions, exam_sections,
  content_blocks, sessions, module_materials, course_modules, courses,
  admins, students, lecturers,
  departments, program_tracks, cohorts,
  lecturer_departments, specializations, roles
cascade;

create extension if not exists pgcrypto;

-- ── Master data (admin-managed lookup lists backing the student registry
-- dropdowns — see Manage Departments / Manage Program Tracks / Manage
-- Cohorts screens) ─────────────────────────────────────────────────────

-- Every master-data / people / catalogue row below carries a `code` that's
-- unique per tenant. There's no `tenant_id` column yet (see AppSession /
-- migration plan) — for now the app enforces this by prepending the
-- tenant id to the code itself at write time (e.g. `TN01-DEPT-OPS`).
--
-- Uniqueness on every `code` and `name` is case-insensitive: the app
-- upper-cases `code` before writing it (so its plain `unique` constraint,
-- auto-named `<table>_..._key` by Postgres, is already case-insensitive in
-- effect). `name` keeps its own plain `unique` constraint too — Postgres
-- foreign keys (e.g. `lecturers.department references
-- lecturer_departments(name)`) can only reference a column backed by a real
-- unique constraint, not an expression index — and additionally gets a
-- `unique index on (lower(name))` named `<table>_name_ci_idx` to catch
-- case-variant duplicates ("Operations" vs "operations") that the
-- case-sensitive constraint alone would miss. The app inspects the failing
-- constraint/index name for `_code_` vs `_name_` to turn a raw Postgres
-- unique-violation into a friendly "already exists" message — see
-- lib/core/utils/error_messages.dart.

create table departments (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  remarks text not null default '',
  created_at timestamptz not null default now()
);
create unique index departments_name_ci_idx on departments (lower(name));

create table program_tracks (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  remarks text not null default '',
  created_at timestamptz not null default now()
);
create unique index program_tracks_name_ci_idx on program_tracks (lower(name));

create table cohorts (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  year int not null default extract(year from now())::int,
  remarks text not null default '',
  created_at timestamptz not null default now()
);
create unique index cohorts_name_ci_idx on cohorts (lower(name));

create table lecturer_departments (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  remarks text not null default '',
  created_at timestamptz not null default now()
);
create unique index lecturer_departments_name_ci_idx on lecturer_departments (lower(name));

create table specializations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  remarks text not null default '',
  created_at timestamptz not null default now()
);
create unique index specializations_name_ci_idx on specializations (lower(name));

-- Job roles (e.g. "IT Support Specialist", "HVAC / Aircon Installer") — what
-- a student does for work, distinct from their academic program_track. Used
-- to drive the Role → Course Mapping screen (which courses fit which job).
create table roles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null unique,
  remarks text not null default '',
  created_at timestamptz not null default now()
);
create unique index roles_name_ci_idx on roles (lower(name));

-- ── People ──────────────────────────────────────────────────────────────

create table lecturers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  title text not null,
  lecturer_code text not null unique,
  email text not null,
  department text not null references lecturer_departments(name) on update cascade,
  specialization text not null references specializations(name) on update cascade,
  credits_used int not null default 0,
  credits_max int not null default 15,
  status text not null default 'Active',
  accredited boolean not null default false,
  manageable boolean not null default true,
  join_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table students (
  id bigint generated by default as identity primary key,
  name text not null,
  student_code text not null unique,
  email text not null,
  department text not null references departments(name) on update cascade,
  title text,
  program_track text not null references program_tracks(name) on update cascade,
  cohort text not null references cohorts(name) on update cascade,
  role text not null references roles(name) on update cascade,
  gpa numeric(3, 2) not null default 0,
  registration_date date not null default current_date,
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

-- Time (schedule) and capacity are class-level concerns, not course-level —
-- see `course_sections.schedule_text` / `course_sections.capacity` below.
create table courses (
  id uuid primary key default gen_random_uuid(),
  course_code text not null unique,
  course_title text not null,
  course_description text not null,
  category text not null default 'techData',
  image_url text,
  credits int not null default 3,
  created_at timestamptz not null default now()
);

-- `enrolled_count` is intentionally not a column here — the app always
-- derives it by counting `student_courses` rows for a section, so it can
-- never drift out of sync with actual enrollments.
create table course_sections (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  section_code text not null unique,
  role_label text not null default 'Primary Instructor',
  term text not null default 'Fall 2025',
  schedule_text text not null default 'TBD',
  day_of_week text check (day_of_week in ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
  start_time time,
  end_time time,
  location text,
  lecturer_id uuid references lecturers(id),
  capacity int not null default 30,
  delivery_mode text not null default 'physical' check (delivery_mode in ('online', 'physical')),
  cohort_id uuid references cohorts(id) on update cascade,
  start_date date,
  status text not null default 'scheduled' check (status in ('scheduled', 'in_progress', 'completed', 'cancelled'))
);

-- A module list (and the graded materials / syllabus content hanging off
-- it) belongs to a specific class — a `course_sections` row, with its own
-- lecturer/term/schedule — not to the course in the abstract: two different
-- classes of the same course can teach different content on a different
-- timeline, so this is keyed on `section_id`, not `course_id`.
create table course_modules (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references course_sections(id) on delete cascade,
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

-- ── Syllabus authoring (lecturer-built module → session → content-block
-- timeline, reached via the "Syllabus" button on My Assigned Courses) — a
-- separate tree from course_modules/module_materials above, which remains
-- the existing graded lesson/quiz/assignment system students progress
-- through. `sessions` hangs off the same `course_modules` table so a
-- lecturer's syllabus modules and their graded content share one module
-- list; `content_blocks` lets one session mix several pieces of content
-- (some text, an embedded video, a file) instead of one type per row. ────

create table sessions (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references course_modules(id) on delete cascade,
  session_name text not null,
  session_description text not null default '',
  session_sorting int not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create table content_blocks (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references sessions(id) on delete cascade,
  block_type text not null check (block_type in ('text', 'video', 'image', 'link', 'file', 'exam', 'assignment')),
  block_content jsonb not null default '{}'::jsonb,
  block_sorting int not null default 0,
  created_at timestamptz not null default now()
);

-- A saved, reusable copy of a module → session → content-block tree ("Save
-- as Template" / "Copy from Template" on the Syllabus screen), independent
-- of any one class — mirrors course_modules/sessions/content_blocks above
-- but with no section_id, so it can be copied into any class's syllabus.
create table syllabus_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table template_modules (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references syllabus_templates(id) on delete cascade,
  module_name text not null,
  module_description text not null default '',
  module_sorting int not null default 0,
  is_published boolean not null default true,
  unlock_at date
);

create table template_sessions (
  id uuid primary key default gen_random_uuid(),
  template_module_id uuid not null references template_modules(id) on delete cascade,
  session_name text not null,
  session_description text not null default '',
  session_sorting int not null default 0,
  is_published boolean not null default true
);

create table template_content_blocks (
  id uuid primary key default gen_random_uuid(),
  template_session_id uuid not null references template_sessions(id) on delete cascade,
  block_type text not null check (block_type in ('text', 'video', 'image', 'link', 'file', 'exam', 'assignment')),
  block_content jsonb not null default '{}'::jsonb,
  block_sorting int not null default 0
);

-- The "Edit Exam" authoring tree for an `exam` content block — sections,
-- each holding any number of questions, each optionally holding its answer
-- choices (single/multi-choice and true/false questions; a free-text
-- question has no options row at all — it's graded manually).
create table exam_sections (
  id uuid primary key default gen_random_uuid(),
  content_block_id uuid not null references content_blocks(id) on delete cascade,
  section_name text not null,
  section_sorting int not null default 0,
  created_at timestamptz not null default now()
);

create table exam_questions (
  id uuid primary key default gen_random_uuid(),
  exam_section_id uuid not null references exam_sections(id) on delete cascade,
  question_text text not null default '',
  question_type text not null check (question_type in ('single_choice', 'multi_choice', 'boolean', 'text')),
  question_sorting int not null default 0,
  created_at timestamptz not null default now()
);

create table exam_question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references exam_questions(id) on delete cascade,
  option_text text not null default '',
  is_correct boolean not null default false,
  option_sorting int not null default 0
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
  code text not null unique,
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

-- Which courses are relevant to which job role — drives the Role ↔ Course
-- Mapping screen (e.g. "IT Support Specialist can study PY-402, DATA-501...").
create table role_courses (
  role_id uuid not null references roles(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  primary key (role_id, course_id)
);

-- Which courses are relevant to which department — drives the Department ↔
-- Course Mapping screen.
create table department_courses (
  department_id uuid not null references departments(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  primary key (department_id, course_id)
);

-- Which courses are relevant to which program track — drives the Track ↔
-- Course Mapping screen.
create table track_courses (
  track_id uuid not null references program_tracks(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  primary key (track_id, course_id)
);

-- Which courses are relevant to which lecturer specialization — drives the
-- Specialization ↔ Course Mapping screen, and the "not related to lecturer's
-- specialization" warning tag on the Manage Assigned Courses screen.
create table specialization_courses (
  specialization_id uuid not null references specializations(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  primary key (specialization_id, course_id)
);

-- `lecturers.credits_used` is derived, not app-maintained: it's recomputed
-- from `lecturer_courses` (the assignation table) joined against
-- `courses.credits` any time a row is added to or removed from it.
create or replace function recalc_lecturer_credits_used() returns trigger as $$
declare
  affected_lecturer_id uuid := coalesce(new.lecturer_id, old.lecturer_id);
begin
  update lecturers
  set credits_used = coalesce((
    select sum(c.credits)
    from lecturer_courses lc
    join courses c on c.id = lc.course_id
    where lc.lecturer_id = affected_lecturer_id
  ), 0)
  where id = affected_lecturer_id;
  return null;
end;
$$ language plpgsql;

create trigger lecturer_courses_recalc_credits
  after insert or delete on lecturer_courses
  for each row execute function recalc_lecturer_credits_used();

create table student_courses (
  student_id bigint not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  section_id uuid references course_sections(id) on delete set null,
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
  student_id bigint not null references students(id) on delete cascade,
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
  student_id bigint not null references students(id) on delete cascade,
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

-- Manage Badges: a simpler per-course badge award, distinct from the
-- broader student_certifications ledger above (which has no course_id).
create table badge_awards (
  id uuid primary key default gen_random_uuid(),
  student_id bigint not null references students(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  badge_id uuid not null references certifications(id) on delete cascade,
  issue_date date not null default current_date,
  is_revoked boolean not null default false,
  created_at timestamptz not null default now()
);

create table enrollment_candidates (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  student_employee_id text,
  student_email text not null,
  department text not null default '',
  cohort text not null default '',
  role text references roles(name) on update cascade,
  target_course_id uuid not null references courses(id) on delete cascade,
  prerequisite_status text not null default 'met' check (prerequisite_status in ('met', 'pending', 'not_met')),
  prerequisite_detail text not null default '',
  standing_detail text not null default 'Academic Good Standing',
  sponsorship text not null default 'Self-Enrolled',
  queue_tag text,
  needs_review boolean not null default false,
  requested_at timestamptz not null default now()
);

-- ── RLS (demo-only, see warning above) ──────────────────────────────────

alter table departments enable row level security;
alter table program_tracks enable row level security;
alter table cohorts enable row level security;
alter table lecturer_departments enable row level security;
alter table specializations enable row level security;
alter table roles enable row level security;
alter table role_courses enable row level security;
alter table department_courses enable row level security;
alter table track_courses enable row level security;
alter table specialization_courses enable row level security;
alter table lecturers enable row level security;
alter table students enable row level security;
alter table admins enable row level security;
alter table courses enable row level security;
alter table course_modules enable row level security;
alter table module_materials enable row level security;
alter table sessions enable row level security;
alter table content_blocks enable row level security;
alter table syllabus_templates enable row level security;
alter table template_modules enable row level security;
alter table template_sessions enable row level security;
alter table template_content_blocks enable row level security;
alter table exam_sections enable row level security;
alter table exam_questions enable row level security;
alter table exam_question_options enable row level security;
alter table tags enable row level security;
alter table course_tags enable row level security;
alter table certifications enable row level security;
alter table module_certs enable row level security;
alter table lecturer_courses enable row level security;
alter table student_courses enable row level security;
alter table student_materials enable row level security;
alter table student_certifications enable row level security;
alter table badge_awards enable row level security;
alter table course_sections enable row level security;
alter table enrollment_candidates enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array[
    'departments', 'program_tracks', 'cohorts',
    'lecturer_departments', 'specializations', 'roles',
    'lecturers', 'students', 'admins', 'courses', 'course_modules',
    'module_materials', 'sessions', 'content_blocks',
    'syllabus_templates', 'template_modules', 'template_sessions', 'template_content_blocks',
    'exam_sections', 'exam_questions', 'exam_question_options',
    'tags', 'course_tags', 'certifications', 'module_certs',
    'lecturer_courses', 'role_courses', 'department_courses', 'track_courses', 'specialization_courses', 'student_courses', 'student_materials',
    'student_certifications', 'badge_awards', 'course_sections', 'enrollment_candidates'
  ]
  loop
    execute format('create policy "anon read" on %I for select using (true)', t);
    execute format('create policy "anon write" on %I for insert with check (true)', t);
    execute format('create policy "anon update" on %I for update using (true)', t);
    execute format('create policy "anon delete" on %I for delete using (true)', t);
  end loop;
end $$;

-- ── Storage (session content uploads — video/image/file blocks) ────────
-- `storage.buckets`/`storage.objects` are managed by Supabase, not part of
-- the drop-table list above, so this is written to be safe to re-run:
-- `on conflict do nothing` for the bucket, `drop policy if exists` for each
-- policy before recreating it.

insert into storage.buckets (id, name, public)
values ('course-content', 'course-content', true)
on conflict (id) do nothing;

drop policy if exists "course-content anon read" on storage.objects;
drop policy if exists "course-content anon write" on storage.objects;
drop policy if exists "course-content anon update" on storage.objects;
drop policy if exists "course-content anon delete" on storage.objects;

create policy "course-content anon read" on storage.objects for select to anon using (bucket_id = 'course-content');
create policy "course-content anon write" on storage.objects for insert to anon with check (bucket_id = 'course-content');
create policy "course-content anon update" on storage.objects for update to anon using (bucket_id = 'course-content');
create policy "course-content anon delete" on storage.objects for delete to anon using (bucket_id = 'course-content');
