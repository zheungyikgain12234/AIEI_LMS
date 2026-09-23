-- AIEI LMS — demo seed data (v2 — full coverage). Run once, right after
-- schema.sql, in the Supabase SQL Editor. Re-usable/idempotent: truncates
-- and re-inserts every row below.
--
-- Demo identity used throughout the app (see lib/core/config/demo_identity.dart):
--   student = David Kim  (id 5 — students.id is a bigint identity column)
--   lecturer = Dr. Emmett Brown (11111111-1111-1111-1111-111111111106)
--   admin = Marcus Vance (33333333-3333-3333-3333-333333333301)
--
-- Singapore-based institute — cohorts/terms use intake naming (e.g.
-- "January 2025 Intake", "AY2025 Term 2"), not US semester names.

truncate table
  enrollment_candidates, course_sections,
  badge_awards, student_certifications, student_materials, student_courses,
  role_courses, lecturer_courses, module_certs, course_tags,
  module_materials, course_modules, courses,
  certifications, tags,
  lecturers, students, admins,
  departments, program_tracks, cohorts,
  lecturer_departments, specializations, roles
restart identity cascade;

-- ── Master data (student registry dropdowns) ────────────────────────────

-- Every code below is tenant-prefixed (`TN01-...`) per the app's
-- multi-tenant code convention — see AppSession / core/session/app_session.dart.

insert into departments (code, name) values
  ('TN01-DEPT-OPS', 'Operations'), ('TN01-DEPT-BI', 'Business Intelligence'), ('TN01-DEPT-TT', 'Treasury Tech'), ('TN01-DEPT-GR', 'Global Risk'),
  ('TN01-DEPT-AP', 'Analytics Platform'), ('TN01-DEPT-SC', 'Supply Chain'), ('TN01-DEPT-WS', 'Workplace Safety'),
  ('TN01-DEPT-CE', 'Cloud Engineering'), ('TN01-DEPT-DA', 'Data Architecture');

insert into program_tracks (code, name) values
  ('TN01-TRK-DAS', 'Data Architecture Specialist'), ('TN01-TRK-AIE', 'AI Engineering Track'), ('TN01-TRK-EXO', 'Executive Operations'),
  ('TN01-TRK-WST', 'Workplace Safety Track'), ('TN01-TRK-CDS', 'Cloud & Distributed Systems'), ('TN01-TRK-AIML', 'AI & Machine Learning'),
  ('TN01-TRK-CDC', 'Cloud & Distributed Computing'), ('TN01-TRK-DAA', 'Data Architecture & Analytics'),
  ('TN01-TRK-GEN', 'General Enterprise Track');

-- Singapore-style intake naming (no US-semester "Fall"/"Spring"/"Summer" terms).
insert into cohorts (code, name, year) values
  ('TN01-COH-JAN25', 'January 2025 Intake', 2025), ('TN01-COH-EXEC25', 'Executive Cohort 2025', 2025), ('TN01-COH-MAY25', 'May 2025 Intake', 2025), ('TN01-COH-SEP25', 'September 2025 Intake', 2025);

-- Job roles (Role → Course Mapping screen: which courses fit which job).
insert into roles (id, code, name) values
  ('99999999-9999-9999-9999-999999999901', 'TN01-ROLE-ITSPEC', 'IT Support Specialist'),
  ('99999999-9999-9999-9999-999999999902', 'TN01-ROLE-HVAC', 'HVAC / Aircon Installer'),
  ('99999999-9999-9999-9999-999999999903', 'TN01-ROLE-DA', 'Data Analyst'),
  ('99999999-9999-9999-9999-999999999904', 'TN01-ROLE-CE', 'Cloud Engineer'),
  ('99999999-9999-9999-9999-999999999905', 'TN01-ROLE-FA', 'Financial Analyst'),
  ('99999999-9999-9999-9999-999999999906', 'TN01-ROLE-CO', 'Compliance Officer'),
  ('99999999-9999-9999-9999-999999999907', 'TN01-ROLE-SO', 'Safety Officer'),
  ('99999999-9999-9999-9999-999999999908', 'TN01-ROLE-EM', 'Executive Manager');

-- ── Master data (lecturer registry dropdowns) ───────────────────────────

insert into lecturer_departments (code, name) values
  ('TN01-LDEPT-CSD', 'Computer Science & Data'), ('TN01-LDEPT-WSE', 'Workplace Safety & EHS'), ('TN01-LDEPT-DSAI', 'Data Science & AI'),
  ('TN01-LDEPT-EL', 'Executive Leadership');

insert into specializations (code, name) values
  ('TN01-SPEC-ETL', 'Distributed ETL & Python'), ('TN01-SPEC-OSHA', 'OSHA Protocol & Site Risk Analysis'),
  ('TN01-SPEC-DNA', 'Deep Neural Architectures'), ('TN01-SPEC-ODC', 'Org Dynamics & Crisis Management'),
  ('TN01-SPEC-DCG', 'Distributed Cloud Governance');

-- ── People ──────────────────────────────────────────────────────────────

-- credits_used is not seeded explicitly — it's recomputed by the
-- `lecturer_courses_recalc_credits` trigger once the lecturer_courses rows
-- below are inserted (see schema.sql).
insert into lecturers (id, name, title, lecturer_code, email, department, specialization, credits_max, status, accredited, manageable, join_date) values
  ('11111111-1111-1111-1111-111111111101', 'Dr. Sarah Lin', 'Lead Data Architect', 'TN01-EMP-7721', 'sarah.lin@aiei.edu', 'Computer Science & Data', 'Distributed ETL & Python', 15, 'Active', true, true, '2021-08-16'),
  ('11111111-1111-1111-1111-111111111102', 'Prof. David Miller', 'Senior EHS Director', 'TN01-EMP-5402', 'd.miller@aiei.edu', 'Workplace Safety & EHS', 'OSHA Protocol & Site Risk Analysis', 15, 'Active', true, true, '2019-01-06'),
  ('11111111-1111-1111-1111-111111111103', 'Dr. Aris Thorne', 'Head of AI & Machine Learning', 'TN01-EMP-8910', 'a.thorne@aiei.edu', 'Data Science & AI', 'Deep Neural Architectures', 15, 'Active', true, true, '2022-09-01'),
  ('11111111-1111-1111-1111-111111111104', 'Elena Rostova', 'VP Leadership Development', 'TN01-EMP-3211', 'e.rostova@aiei.edu', 'Executive Leadership', 'Org Dynamics & Crisis Management', 12, 'Active', true, true, '2020-03-23'),
  ('11111111-1111-1111-1111-111111111105', 'Prof. Kenneth Wu', 'Enterprise Systems Fellow', 'TN01-EMP-6129', 'k.wu@aiei.edu', 'Computer Science & Data', 'Distributed Cloud Governance', 15, 'Sabbatical', false, false, '2017-11-13'),
  -- Dr. Emmett Brown is this demo's active Lecturer Portal identity — see
  -- lib/core/config/demo_identity.dart's DemoIdentity.lecturerId.
  ('11111111-1111-1111-1111-111111111106', 'Dr. Emmett Brown', 'Distinguished Research Fellow', 'TN01-EMP-1985', 'e.brown@aiei.edu', 'Data Science & AI', 'Deep Neural Architectures', 15, 'Active', true, true, '2023-02-11');

insert into students (id, name, student_code, email, department, title, program_track, cohort, role, gpa, registration_date) overriding system value values
  (1, 'Alex Chen', 'TN01-EMP-88219', 'alex.chen@enterprise.com', 'Operations', 'Product Analyst • Operations', 'Data Architecture Specialist', 'January 2025 Intake', 'Data Analyst', 3.76, '2025-08-18'),
  (2, 'Maya Patel', 'TN01-EMP-74102', 'maya.patel@enterprise.com', 'Business Intelligence', 'Business Intelligence Analyst • BI Group', 'AI Engineering Track', 'January 2025 Intake', 'Data Analyst', 3.92, '2025-08-19'),
  (3, 'Marcus Reed', 'TN01-EMP-91024', 'marcus.reed@enterprise.com', 'Treasury Tech', 'Financial Systems Lead • Treasury Tech', 'Executive Operations', 'Executive Cohort 2025', 'Financial Analyst', 2.90, '2025-05-02'),
  (4, 'Elena Rostova Jr.', 'TN01-EMP-60211', 'e.rostovajr@enterprise.com', 'Global Risk', 'Compliance Engineer • Global Risk', 'Workplace Safety Track', 'May 2025 Intake', 'Compliance Officer', 3.40, '2025-01-13'),
  (5, 'David Kim', 'TN01-EMP-43890', 'david.kim@enterprise.com', 'Analytics Platform', 'Data Ops Associate • Analytics Platform', 'Cloud & Distributed Systems', 'January 2025 Intake', 'Data Analyst', 3.55, '2025-08-20'),
  (6, 'Sophia Loren', 'TN01-EMP-55198', 's.loren@enterprise.com', 'Supply Chain', 'Logistics Analyst • Supply Chain Intelligence', 'AI & Machine Learning', 'January 2025 Intake', 'Data Analyst', 3.10, '2025-08-21'),
  (7, 'Jordan Taylor', 'TN01-EMP-99214', 'jordan.taylor@enterprise.com', 'Workplace Safety', 'Safety Compliance Associate', 'Workplace Safety Track', 'May 2025 Intake', 'Safety Officer', 2.60, '2025-01-14'),
  (8, 'Sarah Jenkins', 'TN01-EMP-33109', 'sarah.jenkins@enterprise.com', 'Cloud Engineering', 'Cloud Platform Engineer', 'Cloud & Distributed Computing', 'January 2025 Intake', 'Cloud Engineer', 3.70, '2025-08-22'),
  (9, 'Liam Nguyen', 'TN01-EMP-66381', 'liam.nguyen@enterprise.com', 'Data Architecture', 'Data Architecture Associate', 'Data Architecture & Analytics', 'January 2025 Intake', 'IT Support Specialist', 3.30, '2025-08-23'),
  (10, 'Chloe Bennett', 'TN01-EMP-44820', 'chloe.bennett@enterprise.com', 'Data Architecture', 'Junior Data Analyst', 'Data Architecture & Analytics', 'January 2025 Intake', 'Data Analyst', 3.35, '2025-08-24');

-- Keep the identity sequence ahead of the explicit ids inserted above, so
-- the next `insert into students (name, ...)` (no id given — e.g. Register
-- New Student) auto-assigns 11, not 1.
select setval(pg_get_serial_sequence('students', 'id'), 10, true);

insert into admins (id, name, title, email) values
  ('33333333-3333-3333-3333-333333333301', 'Marcus Vance', 'Chief Academic Administrator', 'marcus.vance@aiei.edu');

-- ── Courses (catalogue courses Alex Chen is enrolled in, codes 1-6; plus
-- additional courses used by the Faculty/Admin allocation views, 7-17) ──

insert into courses (id, course_code, course_title, course_description, category, image_url) values
  ('44444444-4444-4444-4444-444444444401', 'TN01-PY-402', 'Python for Enterprise Data Analysis & Automation', 'Data pipeline orchestration, API integration, and automated ETL workflows for enterprise analytics teams.', 'techData', 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaSQDBQPtWkABa_7PiXVJsRQkHv4xgrG3XiijLhyOTArutGaZK0X05nOVBtjVuJfyRPlFsX9CH0dAMh-kx6LJBba5UjVvkgHx5DOI9Jq8mn98t5FTMg3L8kc9RCcKIG7CvAj6jJG6F1WcCNuMwb1VZ8bFd3wBHxt2crG1xV0Yn7d8UFxNqLPsaE7O7-5zfbPXeU7V1GlQc8GTHdFWmJWqy8fK7RQkfMAqZPyOXl0HpxOWd1hm7qGgiA'),
  ('44444444-4444-4444-4444-444444444402', 'TN01-OSHE-101', 'OSHE Workplace Safety & Compliance 2025', 'Comprehensive occupational health and hazardous-material incident management, site command protocol, and emergency mitigation.', 'compliance', 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2OyYsvS_sX1hJ5qFZkMotA7KvbsvzTYWCF8WfETZtN0WSlfNQVhkrHsE2TUvzXjLriYi6LpI1QlVqk-bwOrvw91ojbYoLwM_Zr1ruloQ8yjzkvpR7-HcehL4qrnDrVs_4iMRN5WxJy9eG3JC6tjt3dVRM0B2lNuBugzLz-hsSE78-Mtrn1GPEA4LaZQxrCS24MIdweDmd2qWKW32UpGdY9ti9Vl7Dt6P7vfqp7Sdl2_U4kIgeIc1PhQ'),
  ('44444444-4444-4444-4444-444444444403', 'TN01-AI-330', 'ChatGPT & Generative AI Prompt Engineering', 'LLM prompt chains, context retrieval architectures, and agentic workflows for enterprise use cases.', 'aiTools', 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4mqWaPlwERSIsIsGlYTZJKCU-zBC91ZVEnzlYmMkcczWZma3JM6Xd_Bxldqi1F87AM_47pV1nWrNbB8_vSI4EgHd-tc9HZTk6oa-8f_DZaUcTrY0U4_TjYRMT3wj1UfvWbLv9Nqo1l7eMPy0V9-fXJakk4e2YAd6AmDfbAMjOTkGMm2YK-zWpw8XIKcFMOPC2lGhe2TLfHCk_j_677br9FSzmugZx2bQc1dk61ey-EtLnrgvHPojdLw'),
  ('44444444-4444-4444-4444-444444444404', 'TN01-FIN-410', 'Advanced Financial Modeling in Microsoft Excel', 'Forecasting methodologies, capital expenditure modeling, and budget variance analysis for FP&A teams.', 'techData', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAR1qa-PQ_EQITTA9fg1r6hu8Tvtdvs1ekcbF5AZPoioMdMTY50_5YruGcysD0SJ6-8HZaOLG_Qi1RpOlkHkhFcFym36_cBZbIzw4jDEtFbKK7ESumokNXWXZQa9jPJ2O4ZxIX8U6iLHNgQlhgiLKciKZmlz6PPi5p7ZCw7-f3gXnx9lREsaOhXDu8f5Q4C42QheRdnHGkL1PjQ_kaMlv2_fAxXfViXwLZTcxB1OlLDwfONXI1h56Jmag'),
  ('44444444-4444-4444-4444-444444444405', 'TN01-SEC-410', 'Corporate Cybersecurity & Phishing Defense', 'Phishing vectors, social engineering prevention, and live incident-response drills.', 'compliance', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXYkMiYXMEX1qK60nUL9gN1pOR3niSrz2k0TccpqxYLosexsrNqafST6KNh4sd_FbxmX-hH9xnHXbRHt13RwK13JgerDi7uZodQ2pDceEI7qvo_-wfHo8dt9ziLjMaEqyFqDr5fKmWhqtY_6q0VBYW0l9fHm_k4wGuXId41QByjT4bpKuozhC1gCtNDrGxyK-cVfV2b8RrGZDXA6ClJmu73mcMOwNQSF_OxxRkT6Lq8q4OOYKGNJkLKg'),
  ('44444444-4444-4444-4444-444444444406', 'TN01-LEAD-400', 'Effective Executive Communication & Stakeholder Alignment', 'High-stakes boardroom presentation, cross-functional influence, investor messaging, and conflict mediation.', 'productivity', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAcMjKgfoHEa8G_VzTvz5W-lpWL88zl5gWlksr1wM5y1Xty2v2vyzFbfxeqrX4zS0yP5kTUyqnf8-SakPJEFx-Kzlrnm-6JxqKczG3nftxgNbS2pjH7BNOSUt0j7QnD8hzJE_KcL2EXk87-27cu8uHdG1igavFS1cWXoTyByUiEHo8KL9bipIN0eO8qitDVg30oxij7-vnE9uEDXLEdnUbJU07Uvz2EBfaV3x7C4mGS2oySo_Ai59eOyQ'),
  ('44444444-4444-4444-4444-444444444407', 'TN01-DATA-501', 'Automated ETL & Enterprise Data Pipelines', 'Airflow orchestration, real-time Kafka event streams, schema validation, and SQL warehouse data transformations.', 'techData', null),
  ('44444444-4444-4444-4444-444444444408', 'TN01-AI-301', 'Applied Machine Learning in Enterprise', 'Supervised models, gradient boosted trees, scikit-learn optimization, and enterprise model governance.', 'aiTools', null),
  ('44444444-4444-4444-4444-444444444409', 'TN01-SAF-204', 'Industrial Hazard Mitigation', 'Chemical handling, SDS documentation, and industrial hazard mitigation for EHS specialists.', 'compliance', null),
  ('44444444-4444-4444-4444-444444444410', 'TN01-ML-800', 'Deep Neural Architectures', 'Graduate-level deep learning architectures, transformer models, and distributed training.', 'aiTools', null),
  ('44444444-4444-4444-4444-444444444411', 'TN01-DL-901', 'Generative Enterprise Systems', 'Doctoral seminar on generative model deployment in enterprise production systems.', 'aiTools', null),
  ('44444444-4444-4444-4444-444444444412', 'TN01-RL-705', 'Reinforcement Learning in Robotics', 'Advanced lab on reinforcement learning applied to robotics and autonomous systems.', 'aiTools', null),
  ('44444444-4444-4444-4444-444444444413', 'TN01-NLP-620', 'Applied NLP Systems', 'Enterprise natural-language processing systems: entity extraction, summarization, and retrieval.', 'aiTools', null),
  ('44444444-4444-4444-4444-444444444414', 'TN01-COMM-102', 'Strategic Corporate Communication', 'Investor messaging, crisis communications, and cross-functional stakeholder alignment.', 'productivity', null),
  ('44444444-4444-4444-4444-444444444415', 'TN01-CYBER-202', 'Zero Trust Architecture', 'Zero-trust network design, identity-aware proxies, and continuous verification models.', 'compliance', null),
  ('44444444-4444-4444-4444-444444444416', 'TN01-CLOUD-410', 'Kubernetes Infrastructure', 'Production Kubernetes cluster design, autoscaling, and DevOps deployment pipelines.', 'techData', null),
  ('44444444-4444-4444-4444-444444444417', 'TN01-AI-512', 'Multi-Agent Autonomy Lab', 'Multi-agent coordination, autonomy stacks, and agentic system research.', 'aiTools', null);

-- ── Course → Lecturer mapping (drives Manage Lecturers course-count chips) ──

insert into lecturer_courses (lecturer_id, course_id) values
  ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444401'), -- Sarah Lin: PY-402
  ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444407'), -- Sarah Lin: DATA-501
  ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444408'), -- Sarah Lin: AI-301
  ('11111111-1111-1111-1111-111111111102', '44444444-4444-4444-4444-444444444402'), -- David Miller: OSHE-101
  ('11111111-1111-1111-1111-111111111102', '44444444-4444-4444-4444-444444444409'), -- David Miller: SAF-204
  ('11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444410'), -- Aris Thorne: ML-800
  ('11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444411'), -- Aris Thorne: DL-901
  ('11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444412'), -- Aris Thorne: RL-705
  ('11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444413'), -- Aris Thorne: NLP-620 (+1 more)
  ('11111111-1111-1111-1111-111111111104', '44444444-4444-4444-4444-444444444406'), -- Elena Rostova: LEAD-400
  ('11111111-1111-1111-1111-111111111104', '44444444-4444-4444-4444-444444444414'), -- Elena Rostova: COMM-102
  ('11111111-1111-1111-1111-111111111106', '44444444-4444-4444-4444-444444444413'), -- Emmett Brown: NLP-620
  ('11111111-1111-1111-1111-111111111106', '44444444-4444-4444-4444-444444444417'), -- Emmett Brown: AI-512
  ('11111111-1111-1111-1111-111111111106', '44444444-4444-4444-4444-444444444403'); -- Emmett Brown: AI-330

-- ── Role → Course mapping (which job roles can study which courses) ─────

-- Broad enough that only Alex Chen (id 1, Data Analyst enrolled in OSHE-101 /
-- SEC-410 / LEAD-400) and Marcus Reed (id 3, Financial Analyst enrolled in
-- PY-402) end up flagged as role/course mismatches on the Manage Students
-- screen — every other seeded student's enrollments fit their role.
insert into role_courses (role_id, course_id) values
  -- IT Support Specialist: PY-402, DATA-501, SEC-410, CYBER-202, CLOUD-410
  ('99999999-9999-9999-9999-999999999901', '44444444-4444-4444-4444-444444444401'),
  ('99999999-9999-9999-9999-999999999901', '44444444-4444-4444-4444-444444444407'),
  ('99999999-9999-9999-9999-999999999901', '44444444-4444-4444-4444-444444444405'),
  ('99999999-9999-9999-9999-999999999901', '44444444-4444-4444-4444-444444444415'),
  ('99999999-9999-9999-9999-999999999901', '44444444-4444-4444-4444-444444444416'),
  -- HVAC / Aircon Installer: OSHE-101, SAF-204
  ('99999999-9999-9999-9999-999999999902', '44444444-4444-4444-4444-444444444402'),
  ('99999999-9999-9999-9999-999999999902', '44444444-4444-4444-4444-444444444409'),
  -- Data Analyst: PY-402, DATA-501, FIN-410, AI-330, SEC-410
  ('99999999-9999-9999-9999-999999999903', '44444444-4444-4444-4444-444444444401'),
  ('99999999-9999-9999-9999-999999999903', '44444444-4444-4444-4444-444444444407'),
  ('99999999-9999-9999-9999-999999999903', '44444444-4444-4444-4444-444444444404'),
  ('99999999-9999-9999-9999-999999999903', '44444444-4444-4444-4444-444444444403'),
  ('99999999-9999-9999-9999-999999999903', '44444444-4444-4444-4444-444444444405'),
  -- Cloud Engineer: CLOUD-410, DATA-501, CYBER-202, AI-301 (deliberately
  -- excludes PY-402 — keeps the Ravi Kumar mismatch demo on Enroll Students).
  ('99999999-9999-9999-9999-999999999904', '44444444-4444-4444-4444-444444444416'),
  ('99999999-9999-9999-9999-999999999904', '44444444-4444-4444-4444-444444444407'),
  ('99999999-9999-9999-9999-999999999904', '44444444-4444-4444-4444-444444444415'),
  ('99999999-9999-9999-9999-999999999904', '44444444-4444-4444-4444-444444444408'),
  -- Financial Analyst: FIN-410, COMM-102
  ('99999999-9999-9999-9999-999999999905', '44444444-4444-4444-4444-444444444404'),
  ('99999999-9999-9999-9999-999999999905', '44444444-4444-4444-4444-444444444414'),
  -- Compliance Officer: OSHE-101, SEC-410, CYBER-202, PY-402
  ('99999999-9999-9999-9999-999999999906', '44444444-4444-4444-4444-444444444402'),
  ('99999999-9999-9999-9999-999999999906', '44444444-4444-4444-4444-444444444405'),
  ('99999999-9999-9999-9999-999999999906', '44444444-4444-4444-4444-444444444415'),
  ('99999999-9999-9999-9999-999999999906', '44444444-4444-4444-4444-444444444401'),
  -- Safety Officer: OSHE-101, SAF-204, SEC-410
  ('99999999-9999-9999-9999-999999999907', '44444444-4444-4444-4444-444444444402'),
  ('99999999-9999-9999-9999-999999999907', '44444444-4444-4444-4444-444444444409'),
  ('99999999-9999-9999-9999-999999999907', '44444444-4444-4444-4444-444444444405'),
  -- Executive Manager: LEAD-400, COMM-102
  ('99999999-9999-9999-9999-999999999908', '44444444-4444-4444-4444-444444444406'),
  ('99999999-9999-9999-9999-999999999908', '44444444-4444-4444-4444-444444444414');

-- ── Specialization → Course mapping (which courses fit which lecturer
-- specialization — drives the Specialization ↔ Course Mapping screen and
-- the "not related to lecturer's specialization" warning on Manage Assigned
-- Courses). Sarah Lin's AI-301 assignment above is deliberately left out of
-- her specialization (Distributed ETL & Python) — it falls under Deep
-- Neural Architectures instead — to demonstrate the mismatch warning. ───
insert into specialization_courses (specialization_id, course_id) values
  ((select id from specializations where name = 'Distributed ETL & Python'), '44444444-4444-4444-4444-444444444401'),
  ((select id from specializations where name = 'Distributed ETL & Python'), '44444444-4444-4444-4444-444444444407'),
  ((select id from specializations where name = 'OSHA Protocol & Site Risk Analysis'), '44444444-4444-4444-4444-444444444402'),
  ((select id from specializations where name = 'OSHA Protocol & Site Risk Analysis'), '44444444-4444-4444-4444-444444444409'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444408'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444410'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444411'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444412'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444413'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444417'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444403'),
  ((select id from specializations where name = 'Org Dynamics & Crisis Management'), '44444444-4444-4444-4444-444444444406'),
  ((select id from specializations where name = 'Org Dynamics & Crisis Management'), '44444444-4444-4444-4444-444444444414'),
  ((select id from specializations where name = 'Distributed Cloud Governance'), '44444444-4444-4444-4444-444444444416'),
  ((select id from specializations where name = 'Distributed Cloud Governance'), '44444444-4444-4444-4444-444444444415');

-- ── Course sections (lecturer_allocation screen: assigned + unassigned) ──

-- section_code is the "class code" — manually entered by the admin through
-- the Manage Assigned Courses screen (lecturer_course_assignment_screen.dart)
-- rather than auto-generated, and tenant-prefixed like every other code.
insert into course_sections (course_id, section_code, role_label, term, schedule_text, day_of_week, start_time, end_time, location, lecturer_id, capacity, delivery_mode, cohort_id, start_date, end_date, status) values
  ('44444444-4444-4444-4444-444444444401', 'TN01-CLS-PY402-A01', 'Primary Instructor', 'AY2025 Term 2', 'Monday 09:00–10:30 • Innovation Hall 204', 'Monday', '09:00', '10:30', 'Innovation Hall 204', '11111111-1111-1111-1111-111111111101', 50, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444407', 'TN01-CLS-DATA501-B02', 'Primary Instructor', 'AY2025 Term 2', 'Tuesday 13:00–14:45 • Data Lab 3B', 'Tuesday', '13:00', '14:45', 'Data Lab 3B', '11111111-1111-1111-1111-111111111101', 45, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444408', 'TN01-CLS-AI301-C01', 'Co-Lecturer', 'AY2025 Term 2', 'Friday 14:00–17:00 • AI Research Lab 1', 'Friday', '14:00', '17:00', 'AI Research Lab 1', '11111111-1111-1111-1111-111111111101', 35, 'online', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2025-06-20', 'completed'),
  ('44444444-4444-4444-4444-444444444402', 'TN01-CLS-OSHE101-A1', 'Lead Instructor', 'AY2025 Term 2', 'Monday 11:00–12:30 • Safety Training Center', 'Monday', '11:00', '12:30', 'Safety Training Center', '11111111-1111-1111-1111-111111111102', 56, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444409', 'TN01-CLS-SAF204-H03', 'Lead Instructor', 'AY2025 Term 2', 'Thursday 14:00–17:30 • Hazmat Simulation Hall', 'Thursday', '14:00', '17:30', 'Hazmat Simulation Hall', '11111111-1111-1111-1111-111111111102', 34, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444410', 'TN01-CLS-ML800-GRAD', 'Graduate', 'AY2025 Term 2', 'Monday 14:00–18:00 • Grad Seminar Room 5', 'Monday', '14:00', '18:00', 'Grad Seminar Room 5', '11111111-1111-1111-1111-111111111103', 50, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444411', 'TN01-CLS-DL901-DOC', 'Doctoral Seminar', 'AY2025 Term 2', 'Wednesday 14:00–18:00 • Doctoral Seminar Hall', 'Wednesday', '14:00', '18:00', 'Doctoral Seminar Hall', '11111111-1111-1111-1111-111111111103', 45, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444412', 'TN01-CLS-RL705-ADV', 'Advanced Lab', 'AY2025 Term 2', 'Friday 08:30–12:30 • Robotics Lab 2', 'Friday', '08:30', '12:30', 'Robotics Lab 2', '11111111-1111-1111-1111-111111111103', 30, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444406', 'TN01-CLS-LEAD400-E1', 'Section E1', 'AY2025 Term 2', 'Tuesday 18:00–21:00 • Executive Boardroom', 'Tuesday', '18:00', '21:00', 'Executive Boardroom', '11111111-1111-1111-1111-111111111104', 28, 'physical', (select id from cohorts where name = 'Executive Cohort 2025'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444414', 'TN01-CLS-COMM102-C3', 'Section C3', 'AY2025 Term 2', 'Thursday 16:00–19:00 • Communication Studio C', 'Thursday', '16:00', '19:00', 'Communication Studio C', '11111111-1111-1111-1111-111111111104', 40, 'physical', (select id from cohorts where name = 'Executive Cohort 2025'), '2025-01-13', '2026-12-18', 'in_progress'),
  -- Dr. Emmett Brown's classes (Lecturer Portal demo identity):
  ('44444444-4444-4444-4444-444444444413', 'TN01-CLS-NLP620-A01', 'Primary Instructor', 'AY2025 Term 2', 'Wednesday 10:00–12:00 • Language Systems Lab', 'Wednesday', '10:00', '12:00', 'Language Systems Lab', '11111111-1111-1111-1111-111111111106', 30, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444417', 'TN01-CLS-AI512-01', 'Primary Instructor', 'AY2025 Term 2', 'Thursday 13:00–16:00 • Autonomy Systems Lab', 'Thursday', '13:00', '16:00', 'Autonomy Systems Lab', '11111111-1111-1111-1111-111111111106', 22, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2026-12-18', 'in_progress'),
  ('44444444-4444-4444-4444-444444444403', 'TN01-CLS-AI330-A01', 'Primary Instructor', 'AY2025 Term 2', 'Tuesday 10:00–12:00 • AI Studio 2', 'Tuesday', '10:00', '12:00', 'AI Studio 2', '11111111-1111-1111-1111-111111111106', 25, 'physical', (select id from cohorts where name = 'January 2025 Intake'), '2025-01-13', '2025-05-16', 'completed'),
  -- Unassigned sections needing lecturer allocation:
  ('44444444-4444-4444-4444-444444444415', 'TN01-CLS-CYBER202-02', 'Unassigned', 'AY2025 Term 2', 'TBD', null, null, null, null, null, 34, 'physical', (select id from cohorts where name = 'January 2025 Intake'), null, null, 'scheduled'),
  ('44444444-4444-4444-4444-444444444416', 'TN01-CLS-CLOUD410-01', 'Unassigned', 'AY2025 Term 2', 'TBD', null, null, null, null, null, 50, 'online', (select id from cohorts where name = 'January 2025 Intake'), null, null, 'scheduled');

-- ── Modules + Materials ─────────────────────────────────────────────────
-- Python course (PY-402) — full 10-lesson curriculum matching course_info_screen.dart

insert into course_modules (id, section_id, module_name, module_description, module_sorting, is_published) values
  ('55555555-5555-5555-5555-555555555501', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 'Foundations of Enterprise Python', 'Core syntax, environments, and enterprise tooling.', 0, true),
  ('55555555-5555-5555-5555-555555555502', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 'Data Wrangling with Pandas', 'DataFrames, joins, and cleaning pipelines.', 1, true),
  ('55555555-5555-5555-5555-555555555503', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 'Building Automated Data Pipelines', 'Scheduling, orchestration, and monitoring ETL jobs.', 2, true),
  ('55555555-5555-5555-5555-555555555504', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 'Enterprise Database Connectors & Async Tasks', 'Advanced topics in SQLAlchemy 2.0 async sessions, connection pooling under concurrency, and Celery asynchronous task queues.', 3, false);

update course_modules set unlock_at = '2025-11-20' where id = '55555555-5555-5555-5555-555555555504';

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting, is_published) values
  ('66666666-6666-6666-6666-666666666628', '55555555-5555-5555-5555-555555555504', 'Lesson: Asyncpg & Connection Pool Optimization', 'video',
    '{"durationMinutes": 28, "transcript": "Draft — processing transcription."}'::jsonb, 0, false),
  ('66666666-6666-6666-6666-666666666629', '55555555-5555-5555-5555-555555555504', 'Lesson: Redis Queue Integration for Batch Pipelines', 'lesson',
    '{"transcript": "Draft — interactive sandbox environment not yet published."}'::jsonb, 1, false);

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting) values
  ('66666666-6666-6666-6666-666666666601', '55555555-5555-5555-5555-555555555501', '01: Enterprise Python Environment Setup', 'video',
    '{"durationMinutes": 25, "transcript": "Enterprise Python environment setup, virtual environments, dependency pinning, and enterprise proxies."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666602', '55555555-5555-5555-5555-555555555501', 'Lesson 01 Knowledge Check', 'quiz',
    '{"quizLength": 5, "attemptsPermitted": 3, "timeAllocatedMinutes": 15, "passingScore": 80, "questions": [{"question": "What command creates a virtual environment?", "mcq": true, "items": ["A. pip venv", "B. python -m venv env", "C. python create env", "D. venv install"], "expectedAns": "B"}]}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666603', '55555555-5555-5555-5555-555555555502', '02: Pandas Series & DataFrame Mechanics', 'video',
    '{"durationMinutes": 38, "transcript": "Series and DataFrame mechanics, indexing, and vectorized selection."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666604', '55555555-5555-5555-5555-555555555502', '03: Data Cleansing, Deduplication & Imputation', 'video',
    '{"durationMinutes": 42, "transcript": "Cleansing strategies, deduplication, and missing-value imputation."}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666605', '55555555-5555-5555-5555-555555555502', '04: Merging, Joining & Aggregating Datasets', 'video',
    '{"durationMinutes": 35, "transcript": "Merge/join strategies and groupby aggregation pipelines."}'::jsonb, 2),
  ('66666666-6666-6666-6666-666666666606', '55555555-5555-5555-5555-555555555502', '05: Vectorized Operations & Performance', 'video',
    '{"durationMinutes": 30, "transcript": "Vectorization vs. apply, and profiling pandas performance."}'::jsonb, 3),
  ('66666666-6666-6666-6666-666666666607', '55555555-5555-5555-5555-555555555502', '06: Working with OpenPyXL & Multi-Tab Books', 'video',
    '{"durationMinutes": 40, "transcript": "Reading/writing multi-tab Excel workbooks with OpenPyXL."}'::jsonb, 4),
  ('66666666-6666-6666-6666-666666666618', '55555555-5555-5555-5555-555555555502', 'Pandas Fundamentals Quiz', 'quiz',
    '{
      "quizLength": 5,
      "attemptsPermitted": 3,
      "timeAllocatedMinutes": 15,
      "passingScore": 80,
      "questions": [
        {"question": "Which method removes duplicate rows from a DataFrame?", "mcq": true, "items": ["A. drop_na()", "B. drop_duplicates()", "C. dedupe()", "D. unique()"], "expectedAns": "B"},
        {"question": "What does df.merge() perform by default?", "mcq": true, "items": ["A. Outer join", "B. Left join", "C. Inner join", "D. Cross join"], "expectedAns": "C"}
      ]
    }'::jsonb, 5),
  ('66666666-6666-6666-6666-666666666608', '55555555-5555-5555-5555-555555555503', '07: Building Automated Data Pipelines', 'video',
    '{"durationMinutes": 45, "transcript": "End-to-end automated pipeline design principles."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666609', '55555555-5555-5555-5555-555555555503', '08: Scheduled Automated Cron & Windows Tasks', 'video',
    '{"durationMinutes": 32, "transcript": "Scheduling recurring jobs via cron and Windows Task Scheduler."}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666610', '55555555-5555-5555-5555-555555555503', '09: Automated Email Alerts & PDF Report Delivery', 'video',
    '{"durationMinutes": 36, "transcript": "Automated alerting and PDF report generation/delivery."}'::jsonb, 2),
  ('66666666-6666-6666-6666-666666666619', '55555555-5555-5555-5555-555555555503', 'Capstone: Distributed Web Scraping', 'assignment',
    '{
      "instruction": "Design and submit an automated pipeline that scrapes, cleans, and loads a public dataset into a warehouse table on a daily schedule.",
      "references": ["https://docs.python.org/3/library/asyncio.html", "https://docs.pydantic.dev"],
      "notes": "Submit source repo link plus a 1-page architecture summary."
    }'::jsonb, 3);

-- Assignment 02 — the "Building Automated Data Pipelines with Pandas & Excel"
-- capstone graded in grade_assignment_screen.dart / assignment_submission_screen.dart.
insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting, due_at, attached_files) values
  ('66666666-6666-6666-6666-666666666611', '55555555-5555-5555-5555-555555555503', 'Assignment 02: Building Automated Data Pipelines with Pandas & Excel', 'assignment',
    '{
      "instruction": "Develop an end-to-end Python script to validate, cleanse, and automate enterprise Excel sales reports into clean database-ready format with quarantine auditing.",
      "references": ["https://openpyxl.readthedocs.io", "https://pandas.pydata.org/docs"],
      "notes": "Due Nov 15, 2025 • 11:59 PM EST. 100 Points (Pass mark: 80%).",
      "maxScore": 100,
      "passMarkPercentage": 80,
      "rubricLabel": "Institutional Grading Rubric (100 Pts)",
      "cohortBenchmarkLabel": "Cohort Analytics Benchmark: 88.4%"
    }'::jsonb, 4, '2025-11-15 23:59:00-05',
    '[
      {"name": "dataset_q3_raw.xlsx", "sizeLabel": "3.4 MB", "kind": "dataset", "footer": "Replaced 2 days ago"},
      {"name": "starter_pipeline.py", "sizeLabel": "48 KB", "kind": "code", "footer": "Pre-configured template"},
      {"name": "pipeline_architecture_spec.pdf", "sizeLabel": "850 KB", "kind": "doc", "footer": "Verified checksum"}
    ]'::jsonb);

-- Compliance quiz (module 3 of Assignment/Pipeline module) — the enterprise
-- data-governance MCQ bank shown in grade_quiz_screen.dart.
insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting, due_at) values
  ('66666666-6666-6666-6666-666666666612', '55555555-5555-5555-5555-555555555503', 'Lesson Compliance Quiz: Data Protection & Enterprise Governance', 'quiz',
    '{
      "assessmentId": "COMPL-03-Q3",
      "quizLength": 6,
      "attemptsPermitted": 2,
      "timeAllocatedMinutes": 30,
      "passingScore": 80,
      "mcqQuestions": [
        {"label": "Q01 • Pipeline State Isolation", "points": 10, "question": "Which protocol governs enterprise data isolation when caching intermediate pipeline states?", "items": ["A. Public readable S3 staging tier with ACL hashing", "B. Encrypted ephemeral volume with short-lived STS tokens", "C. Uncompressed local node temp directory with UID 0", "D. Shared NFS volume mounts across microservices"], "expectedAns": "B"},
        {"label": "Q02 • Retention Lifecycle", "points": 10, "question": "What is the maximum allowable un-sanitized retention period for raw customer transactional logs?", "items": ["A. 72 Hours in primary database cache", "B. Indefinitely within encrypted cold storage", "C. 24 Hours in a quarantined VPC bucket", "D. Zero retention (in-memory transformation only)"], "expectedAns": "C"},
        {"label": "Q03 • Access Control Layering", "points": 10, "question": "Which access layer enforces least-privilege boundary checks between microservice tenants?", "items": ["A. Mutual TLS with per-tenant scoped service accounts", "B. Shared API key across all tenants", "C. IP allowlisting only", "D. Basic auth over HTTP"], "expectedAns": "A"},
        {"label": "Q04 • Audit Trail Immutability", "points": 10, "question": "What guarantees tamper-evidence for compliance audit logs at rest?", "items": ["A. Plaintext CSV exports", "B. Mutable relational log table", "C. Nightly manual review", "D. Append-only ledger with cryptographic hash chaining"], "expectedAns": "D"},
        {"label": "Q05 • Key Rotation Policy", "points": 10, "question": "What is the maximum rotation interval for envelope encryption keys under the governance policy?", "items": ["A. 30 days manual rotation", "B. 90 days with automated re-wrap", "C. 1 year with audit sign-off", "D. Never, keys are permanent"], "expectedAns": "B"},
        {"label": "Q06 • Cross-Border Transfer", "points": 10, "question": "Which mechanism is required before transferring regulated data across jurisdictional boundaries?", "items": ["A. Verbal manager approval", "B. No mechanism required within same cloud provider", "C. Standard contractual clauses with data residency attestation", "D. Compression of the dataset only"], "expectedAns": "C"}
      ],
      "freeResponseQuestions": [
        {
          "number": "03",
          "prompt": "Explain how you would handle an unmapped categorical value encountered mid-pipeline without breaking downstream consumers or halting the ETL batch.",
          "rubricIntro": "Expected Core Elements: Quarantine isolation, structured error tagging (UNKNOWN_ENUM), alerting steward mechanism, and non-blocking streaming execution.",
          "rubricTags": ["Non-blocking Flow (+6)", "Error Tagging (+5)", "Async Alerting (+5)", "Fallback Schema (+4)"],
          "maxScore": 20
        },
        {
          "number": "04",
          "prompt": "Describe the rollback and disaster recovery procedure if an automated ETL job corrupts a production table partition.",
          "rubricIntro": "Benchmark Rubric: Immediate partition isolation, point-in-time recovery mechanism (time-travel/snapshot), upstream pipeline freeze, and subsequent idempotent replay from raw bronze ingest.",
          "rubricTags": ["Snapshot Time-travel (+8)", "Ingestion Worker Freeze (+6)", "Delta Reconciliation (+6)"],
          "maxScore": 20
        }
      ]
    }'::jsonb, 5, '2025-11-18 23:59:00-05');

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting, is_published, due_at) values
  ('66666666-6666-6666-6666-666666666630', '55555555-5555-5555-5555-555555555503', 'Final Capstone Project Release', 'assignment',
    '{"instruction": "Capstone project brief releases to all students once scheduling is finalized.", "notes": "Scheduled release."}'::jsonb, 6, false, '2025-12-01 00:00:00-05');

-- OSHE course (OSHE-101) — 8-module curriculum matching course_info_screen_2.dart
insert into course_modules (id, section_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555510', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Regulatory Framework', 'OSHA / OSHE regulatory foundations.', 0),
  ('55555555-5555-5555-5555-555555555511', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Hazard Identification & PPE', 'Identifying hazards and selecting PPE.', 1),
  ('55555555-5555-5555-5555-555555555512', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Electrical & Lockout/Tagout', 'LOTO procedures and electrical safety.', 2),
  ('55555555-5555-5555-5555-555555555513', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Chemical Handling & SDS', 'Chemical handling, GHS labeling, and SDS documentation.', 3),
  ('55555555-5555-5555-5555-555555555514', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Fire Protection & Suppression', 'Fire protection systems and suppression protocol.', 4),
  ('55555555-5555-5555-5555-555555555515', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Ergonomics & Physical Safety', 'Workplace ergonomics and physical hazard mitigation.', 5),
  ('55555555-5555-5555-5555-555555555516', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Incident Response & Reporting', 'Incident containment, reporting, and regulatory notification.', 6),
  ('55555555-5555-5555-5555-555555555517', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 'Final Regulatory Audit Exam', 'Comprehensive 50-question regulatory audit exam.', 7);

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting) values
  ('66666666-6666-6666-6666-666666666620', '55555555-5555-5555-5555-555555555510', '01. Regulatory Framework', 'video', '{"durationMinutes": 14, "transcript": "29 CFR 1910 regulatory framework overview."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666621', '55555555-5555-5555-5555-555555555511', '02. Hazard Identification & PPE', 'video', '{"durationMinutes": 22, "transcript": "Hazard identification methodology and PPE selection."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666622', '55555555-5555-5555-5555-555555555512', '03. Electrical & Lockout/Tagout', 'video', '{"durationMinutes": 18, "transcript": "Electrical isolation and lockout/tagout procedures."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666623', '55555555-5555-5555-5555-555555555513', '04. Chemical Handling & SDS', 'video', '{"durationMinutes": 16, "transcript": "GHS labeling, secondary containers, and SDS documentation."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666624', '55555555-5555-5555-5555-555555555514', '05. Fire Protection & Suppression', 'video', '{"durationMinutes": 20, "transcript": "Fire protection systems and suppression equipment."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666625', '55555555-5555-5555-5555-555555555515', '06. Ergonomics & Physical Safety', 'video', '{"durationMinutes": 15, "transcript": "Ergonomic risk assessment and mitigation."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666626', '55555555-5555-5555-5555-555555555516', '07. Incident Response & Reporting', 'video', '{"durationMinutes": 25, "transcript": "Incident containment, evacuation, and regulatory reporting triggers."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666627', '55555555-5555-5555-5555-555555555517', '08. Final Regulatory Audit Exam', 'quiz',
    '{
      "quizLength": 15,
      "attemptsPermitted": 3,
      "timeAllocatedMinutes": 45,
      "passingScore": 80,
      "standard": "29 CFR 1910",
      "passingScoreLabel": "80% Min.",
      "totalQuestions": 15,
      "passingCount": 12,
      "mcqQuestions": [
        {"number": 6, "kicker": "MULTIPLE CHOICE • STANDARD 4 POINTS", "question": "OSHA Secondary Container Labeling GHS Exemptions", "scenario": "At 09:30 AM, an industrial technician decants 2.5 liters of Concentrated Sulfuric Acid (98% H2SO4) from a certified 55-gallon primary drum into an unlabelled polyethylene secondary beaker to neutralize an adjacent alkaline spill basin. The technician intends to execute the spill neutralization immediately and complete the task within 45 minutes of their shift.", "referenceStandard": "OSHA HazCom CFR 1910.1200(f)(8) Portable Container Rule", "prompt": "According to standard GHS alignment and OSHA workplace standards, which regulatory action is required regarding the secondary beaker container?", "items": [
          {"letter": "A", "title": "OSHA General Exception", "description": "No secondary label is mandatory provided the decanted chemical remains under the continuous, direct control of the employee who performed the transfer and is fully consumed within that work shift."},
          {"letter": "B", "title": "Full GHS Relabel", "description": "A full 6-point GHS secondary label (including pictograms, signal word, hazard statements, and manufacturer address) must be affixed prior to transferring any liquid volume greater than 500 mL."},
          {"letter": "C", "title": "Simplified NFPA Diamond", "description": "Only an abbreviated NFPA 704 standard diamond stamp with health rating 3 is required, regardless of usage duration or proximity to other shop personnel."},
          {"letter": "D", "title": "Shift Lead Certification", "description": "The secondary container may be left unmarked only if co-signed on the department whiteboard log by an authorized shift supervisor and environmental officer."}
        ], "expectedAns": "A"}
      ],
      "freeResponseQuestions": [
        {"number": 7, "kicker": "FREE RESPONSE • CASE STUDY • 6 POINTS", "title": "Incident Containment Plan & PPE Protocol Diagnosis", "incidentLabel": "Critical Facility Incident Narrative", "scenario": "During a routine forklift repositioning at the East Chem Bay storage rack, a puncture occurs on an intermediate bulk container (IBC) carrying Glacial Acetic Acid (approx. 450 Liters). Dense pungent vapors are propagating toward an adjacent assembly cell with 18 unevacuated personnel. The ventilation stack has entered automatic fault fallback.", "taskPrompt": "Outline the immediate 4-step emergency containment action sequence. Identify the exact minimum Level PPE required for the entry response team, specific neutralization agent, and mandatory regulatory reporting triggers under EPCRA / OSHA.", "hint": "Draft your step-by-step incident response plan here... Mention evacuation radius, Level B PPE equipment, neutralization chemistry, and regulatory notifications.", "recommendedWordCount": "80 - 250 words", "rubricTags": [
          {"title": "1. Immediate Evacuation (2 pts)", "description": "Must state alarm sounding and 100m upwind muster protocol before physical containment."},
          {"title": "2. Proper PPE Specified (2 pts)", "description": "Must designate Level B minimum with SCBA (due to vapor threshold) and neoprene/butyl gloves."},
          {"title": "3. Neutralizer & Agency (2 pts)", "description": "Must specify dry sodium carbonate / bicarbonate absorbent and National Response Center if threshold exceeded."}
        ], "maxScore": 6}
      ]
    }'::jsonb, 0);

-- ── Syllabus authoring demo content (Dr. Emmett Brown — AI-330 class) ───
-- Exercises every content-block type (text, image, video, file, link) in an
-- orientation session; the exam/assignment block types are exercised by the
-- fully-fleshed-out "Quiz 1" / "Prompt Library Submission" blocks under the
-- Week 1 / Week 2 sessions further below instead of a placeholder here.

insert into course_modules (id, section_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555530', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 'Prompt Engineering Fundamentals', 'Core prompt design patterns and context retrieval basics.', 0);

insert into sessions (id, module_id, session_name, session_description, session_sorting) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001', '55555555-5555-5555-5555-555555555530', 'Week 0 — Orientation & Course Overview', 'How this course is structured, what you''ll build, and how you''ll be assessed.', 0);

insert into content_blocks (id, session_id, block_type, block_content, block_sorting) values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001', 'text',
    '{"body": "Welcome to Prompt Engineering Fundamentals. Over the next few weeks you will learn core prompt design patterns, context retrieval architectures, and how to structure reliable prompt chains for enterprise use cases. Each week pairs a short lesson with a graded checkpoint, so keep an eye on the due dates below.", "delta": [{"insert": "Welcome to Prompt Engineering Fundamentals. Over the next few weeks you will learn core prompt design patterns, context retrieval architectures, and how to structure reliable prompt chains for enterprise use cases. Each week pairs a short lesson with a graded checkpoint, so keep an eye on the due dates below.\n"}]}'::jsonb, 0),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0004', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001', 'image',
    '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/d8490143-f015-4f7f-92a1-d51a0a033904/1789894103088-Screenshot_2026-09-14_at_1.02.43_AM.png", "caption": "Fig. 1 — Anatomy of a well-structured prompt: role, context, instruction, and output format."}'::jsonb, 1),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0005', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001', 'video',
    '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/d8490143-f015-4f7f-92a1-d51a0a033904/1789894247220-Screen_Recording_2026-09-20_at_4.50.16_PM.mov", "caption": "Orientation walkthrough: navigating the course, the weekly cadence, and where to submit your work."}'::jsonb, 2),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0006', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001', 'file',
    '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/d8490143-f015-4f7f-92a1-d51a0a033904/1789894268438-langfuse.pptx", "name": "Prompt_Observability_with_Langfuse.pptx"}'::jsonb, 3),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0007', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0001', 'link',
    '{"url": "https://example.com/reading/prompt-engineering-basics", "label": "Suggested Reading: Prompt Engineering Basics"}'::jsonb, 4);

-- ── Tags ────────────────────────────────────────────────────────────────

insert into tags (id, label, color_hex, icon_name) values
  ('77777777-7777-7777-7777-777777777701', 'Career Essentials', '#0F4C81', null),
  ('77777777-7777-7777-7777-777777777702', 'Quiz Pending', '#B3261E', null),
  ('77777777-7777-7777-7777-777777777703', 'AI UPSKILLING', '#4F46E5', null),
  ('77777777-7777-7777-7777-777777777704', 'SECURITY MANDATORY', '#B3261E', null),
  ('77777777-7777-7777-7777-777777777705', 'Completed', '#059669', 'check');

insert into course_tags (course_id, tag_id) values
  ('44444444-4444-4444-4444-444444444401', '77777777-7777-7777-7777-777777777701'),
  ('44444444-4444-4444-4444-444444444402', '77777777-7777-7777-7777-777777777702'),
  ('44444444-4444-4444-4444-444444444403', '77777777-7777-7777-7777-777777777703'),
  ('44444444-4444-4444-4444-444444444405', '77777777-7777-7777-7777-777777777704'),
  ('44444444-4444-4444-4444-444444444406', '77777777-7777-7777-7777-777777777705');

-- ── Certifications (incl. revoked + executive leadership, matching the
-- credential_detail screens) ─────────────────────────────────────────────

insert into certifications (id, code, title, issuing_body, description, badge_icon, competencies, hash, narrative, accrediting_bodies, metrics) values
  ('88888888-8888-8888-8888-888888888801', 'TN01-CERT-PYAUTO', 'Python Automation Specialist', 'AIEI Enterprise Learning', 'Data pipeline orchestration, API integration, and automated ETL workflows.', 'military_tech', array['Advanced NumPy & Pandas', 'Capstone: Distributed Web Scraping'], '0x1A2B...9F3C', '', array[]::text[], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888802', 'TN01-CERT-CSO25', 'Certified Safety Officer 2025 (CSO-2025)', 'OSHA Accredited Corporate Safety Board & Enterprise EHS Division', 'Comprehensive occupational health and hazardous material incident management, site command protocol, and emergency mitigation.', 'workspace_premium', array['Hazard Identification', 'GHS Rev 8', 'Emergency Evacuation', 'SDS Compliance'], '0x7F2B...C84B (Ledger Status: REVOKED)', '', array['OSHA Accredited Corporate Safety Board', 'Enterprise EHS Division'], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888803', 'TN01-CERT-CYBER', 'Certified Cyber Sentinel', 'SecOps Corporate Division', 'Phishing vectors, social engineering prevention, and live drill response.', 'shield', array['Zero-Day Attack Patterns', 'Final Incident Sim Due'], '0x3D9E...A712', '', array[]::text[], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888804', 'TN01-CERT-EXECLEAD', 'Executive Leadership Communicator', 'AIEI Executive Leadership Academy & Wharton Executive Education Partner Alliance', 'This credential certifies demonstrated exceptional executive presence, strategic narrative design, and high-impact negotiation in mission-critical corporate settings. Completion required passing four intensive boardroom simulation defenses before an executive panel, managing multi-tier crisis communications scenarios, and synthesizing complex enterprise initiatives into actionable operational roadmaps for C-suite stakeholders.', 'record_voice_over', array['Boardroom Presentations', 'Crisis Communications', 'Cross-Functional Negotiation', 'Executive Presence'], '0x94D1...71E0',
   'This credential certifies that the recipient has demonstrated exceptional executive presence, strategic narrative design, and high-impact negotiation in mission-critical corporate settings. Completion required passing four intensive boardroom simulation defenses before an executive panel, managing multi-tier crisis communications scenarios, and synthesizing complex enterprise initiatives into actionable operational roadmaps for C-suite stakeholders.',
   array['AIEI Executive Leadership Academy', 'Wharton Executive Education Partner Alliance'],
   '{"percentileLabel": "Top 5%", "scoreLabel": "Score: 98.4 / 100", "panelResultLabel": "Distinction", "panelResultSubtitle": "Unanimous Board Pass", "accreditedHoursLabel": "16.0 Hours", "accreditedHoursSubtitle": "Accredited Units"}'::jsonb),
  ('88888888-8888-8888-8888-888888888805', 'TN01-CERT-AIPROMPT', 'Enterprise AI & Prompt Engineering', 'AIEI Enterprise Learning', 'LLM prompt chains, context retrieval architectures, and agentic workflows.', 'smart_toy', array['Context Window Design', '6 Lessons Remaining'], '0xB817...2C4D', '', array[]::text[], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888806', 'TN01-CERT-FPA', 'FP&A Certified Financial Analyst', 'AIEI Enterprise Learning', 'Forecasting methodologies, capital expenditure modeling, and budget variance.', 'analytics', array['P&L Mechanics', '8 Lessons Locked'], '0xE203...5A19', '', array[]::text[], '{}'::jsonb);

insert into module_certs (module_id, cert_id) values
  ('55555555-5555-5555-5555-555555555503', '88888888-8888-8888-8888-888888888801'),
  ('55555555-5555-5555-5555-555555555517', '88888888-8888-8888-8888-888888888802');

-- ── Student enrollment + progress (Alex Chen — drives catalogue + badges) ──

insert into student_courses (student_id, course_id, section_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, sponsorship, last_activity_at, is_online_now) values
  (1, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 70, 'B+', 88.4, 96, 'on_track', 'Corporate Sponsored', now() - interval '2 hours', true),
  (1, '44444444-4444-4444-4444-444444444402', (select id from course_sections where section_code = 'TN01-CLS-OSHE101-A1'), 38, 'C+', 76.0, 88, 'at_risk', 'Corporate Sponsored', now() - interval '1 day', false),
  (1, '44444444-4444-4444-4444-444444444403', null, 40, 'B', 82.0, 92, 'on_track', 'Corporate Sponsored', now() - interval '5 hours', false),
  (1, '44444444-4444-4444-4444-444444444404', null, 20, 'B-', 79.5, 90, 'on_track', 'Corporate Sponsored', now() - interval '3 days', false),
  (1, '44444444-4444-4444-4444-444444444405', null, 85, 'A-', 91.0, 97, 'on_track', 'Corporate Sponsored', now() - interval '2 hours', true),
  (1, '44444444-4444-4444-4444-444444444406', null, 100, 'A', 94.0, 100, 'on_track', 'Corporate Sponsored', now() - interval '10 days', false);

insert into student_materials (student_id, material_id, status, score, attempts, completed_at) values
  (1, '66666666-6666-6666-6666-666666666601', 'completed', 100, 1, now() - interval '30 days'),
  (1, '66666666-6666-6666-6666-666666666602', 'completed', 100, 1, now() - interval '29 days'),
  (1, '66666666-6666-6666-6666-666666666603', 'completed', 95, 1, now() - interval '25 days'),
  (1, '66666666-6666-6666-6666-666666666604', 'completed', 90, 1, now() - interval '22 days'),
  (1, '66666666-6666-6666-6666-666666666605', 'completed', 100, 1, now() - interval '19 days'),
  (1, '66666666-6666-6666-6666-666666666606', 'completed', 88, 1, now() - interval '16 days'),
  (1, '66666666-6666-6666-6666-666666666607', 'completed', 92, 1, now() - interval '13 days'),
  (1, '66666666-6666-6666-6666-666666666618', 'completed', 95, 1, now() - interval '10 days'),
  (1, '66666666-6666-6666-6666-666666666608', 'in_progress', null, 1, null),
  (1, '66666666-6666-6666-6666-666666666612', 'in_progress', 60, 1, null);

insert into student_materials (student_id, material_id, status, score, attempts, submission_content, feedback, graded_by, graded_at, completed_at) values
  (1, '66666666-6666-6666-6666-666666666611', 'completed', 94, 1,
    '{
      "writeup": "Handled edge case where column tax_code had null values by defaulting to regional regulatory rate 0.0825. Quarantine routing extracts invalid rows into an isolated parquet buffer with timestamp tracking. Vectorized timestamp transformations yielding a 3.8x execution time reduction compared with standard iteration.",
      "files": [
        {"name": "pipeline_etl_v2_chen.py", "sizeLabel": "48 KB", "description": "Synthesized script with quarantine isolation & unit tests"},
        {"name": "pipeline_execution_report.pdf", "sizeLabel": "1.2 MB", "description": "Execution terminal telemetry and aggregated profit graphs"}
      ],
      "submittedAt": "2025-11-14T16:15:00-05:00",
      "onTime": true
    }'::jsonb,
    'Exceptional submission Alex. Your vectorized transformation logic was one of the most performant in the cohort. Solid edge case handling on the tax code and clean quarantine parquet routing.',
    '11111111-1111-1111-1111-111111111101', now() - interval '2 days', now() - interval '2 days');

-- Alex Chen's OSHE Final Regulatory Audit Exam attempt (in progress, drives compliance_quiz_screen)
insert into student_materials (student_id, material_id, status, score, attempts, submission_content, completed_at) values
  (1, '66666666-6666-6666-6666-666666666627', 'in_progress', null, 1,
    '{
      "answeredQuestions": [1, 2, 3, 4, 5],
      "flaggedQuestions": [3, 8],
      "currentQuestion": 6,
      "timerSecondsRemaining": 1122,
      "freeResponseDraft": "Phase 1: Immediate Personnel Safety. Activate the Bay emergency pull station to trip audible alarm for Assembly Cell 3, mandating immediate evacuation to Upwind Assembly Point Charlie. Prevent any unauthorized shop personnel from approaching the plume corridor.\n\nPhase 2: Responder PPE Gear-Up. Secondary spill response team must don Level B HazMat PPE equipped with Self-Contained Breathing Apparatus (SCBA) due to organic acetic acid vapors exceeding IDLH thresholds, alongside butyl-rubber protective coveralls and chemically resistant footwear.\n\nPhase 3: Containment and Neutralization. Deploy non-combustible polypropylene absorbent berm socks around drain grates. Apply dry sodium bicarbonate gradually to neutralize corrosive runoff while checking pH telemetry."
    }'::jsonb, null);

-- Other PY-402 students' Assignment 02 / Compliance Quiz progress (drives
-- student_directory_screen.dart grading columns and course_dashboard_screen.dart
-- "assignments/quizzes to grade" KPIs; grader is Dr. Sarah Lin).
insert into student_materials (student_id, material_id, status, score, attempts, feedback, graded_by, graded_at, completed_at) values
  (2, '66666666-6666-6666-6666-666666666611', 'completed', 98, 1, 'Outstanding cohort-leading submission.', '11111111-1111-1111-1111-111111111101', now() - interval '1 day', now() - interval '1 day'),
  (2, '66666666-6666-6666-6666-666666666612', 'completed', 98, 1, null, '11111111-1111-1111-1111-111111111101', now() - interval '1 day', now() - interval '1 day'),
  (4, '66666666-6666-6666-6666-666666666611', 'completed', 90, 1, 'Solid work overall, minor edge case gaps.', '11111111-1111-1111-1111-111111111101', now() - interval '2 days', now() - interval '2 days'),
  (4, '66666666-6666-6666-6666-666666666612', 'completed', 88, 1, null, '11111111-1111-1111-1111-111111111101', now() - interval '2 days', now() - interval '2 days'),
  (5, '66666666-6666-6666-6666-666666666611', 'completed', 92, 1, 'Well-structured pipeline.', '11111111-1111-1111-1111-111111111101', now() - interval '3 days', now() - interval '3 days'),
  (5, '66666666-6666-6666-6666-666666666612', 'in_progress', null, 1, null, null, null, null),
  (6, '66666666-6666-6666-6666-666666666611', 'in_progress', null, 1, null, null, null, null);

-- ── Earned / revoked credentials (Alex Chen — credential_detail screens) ──

insert into student_certifications (student_id, cert_id, status, progress_percentage, issued_at, expires_at, revoked_at, revocation_reason, case_ref, inspecting_officer, cohort_label) values
  (1, '88888888-8888-8888-8888-888888888802', 'revoked', 100, '2025-01-15', '2025-12-31', '2025-10-24 08:30:00-05', 'Confiscated due to high-voltage main switchboard isolation failure prior to shift clock-out on Zone 3 Factory Floor (OSHA Standard 29 CFR 1910.147 - Control of Hazardous Energy / Lockout-Tagout Infraction).', 'INC-2025-08492', 'Dr. V. Morales, Sr. EHS Officer', null),
  (1, '88888888-8888-8888-8888-888888888804', 'earned', 100, '2024-10-24', null, null, null, null, null, 'Cohort Fall 2024'),
  (1, '88888888-8888-8888-8888-888888888801', 'in_progress', 70, null, null, null, null, null, null, null),
  (1, '88888888-8888-8888-8888-888888888805', 'in_progress', 40, null, null, null, null, null, null, null),
  (1, '88888888-8888-8888-8888-888888888803', 'in_progress', 85, null, null, null, null, null, null, null),
  (1, '88888888-8888-8888-8888-888888888806', 'in_progress', 20, null, null, null, null, null, null, null);

-- ── Manage Badges (per-course badge awards, admin screen) ───────────────

-- issue_date values are relative to today so the Manage Students "Monthly
-- Credential Grant Rate" chart (last 6 months, derived live from this table)
-- always has recent data to show, regardless of when this seed is run.
insert into badge_awards (student_id, course_id, badge_id, issue_date, is_revoked) values
  (1, '44444444-4444-4444-4444-444444444401', '88888888-8888-8888-8888-888888888801', current_date - interval '3 days', false),
  (1, '44444444-4444-4444-4444-444444444402', '88888888-8888-8888-8888-888888888802', current_date - interval '8 months', true),
  (2, '44444444-4444-4444-4444-444444444401', '88888888-8888-8888-8888-888888888801', current_date - interval '3 weeks', false),
  (4, '44444444-4444-4444-4444-444444444401', '88888888-8888-8888-8888-888888888801', current_date - interval '2 months', false);

-- ── Faculty portal: enrollment rosters for Sarah Lin's 3 courses ─────────
-- (drives student_directory_screen.dart, course_dashboard_screen.dart, my_assigned_courses_screen.dart)

insert into student_courses (student_id, course_id, section_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, last_activity_at) values
  (2, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 92, 'A', 98.0, 98, 'on_track', now() - interval '18 minutes'),
  (3, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 45, 'D', 68.0, 60, 'critical', now() - interval '6 days'),
  (4, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 80, 'B+', 88.5, 90, 'on_track', now() - interval '1 day'),
  (5, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 70, 'A-', 91.0, 94, 'on_track', now() - interval '4 hours'),
  (6, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 60, 'B', 84.0, 82, 'at_risk', now() - interval '3 days');

-- ── Faculty portal: enrollment rosters for Dr. Emmett Brown's 2 classes ──
-- (drives student_directory_screen.dart, course_dashboard_screen.dart, my_assigned_courses_screen.dart)

insert into student_courses (student_id, course_id, section_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, last_activity_at) values
  (1, '44444444-4444-4444-4444-444444444413', (select id from course_sections where section_code = 'TN01-CLS-NLP620-A01'), 55, 'B', 85.0, 92, 'on_track', now() - interval '2 hours'),
  (3, '44444444-4444-4444-4444-444444444413', (select id from course_sections where section_code = 'TN01-CLS-NLP620-A01'), 30, 'C', 74.5, 68, 'at_risk', now() - interval '5 days'),
  (7, '44444444-4444-4444-4444-444444444413', (select id from course_sections where section_code = 'TN01-CLS-NLP620-A01'), 65, 'A-', 90.0, 95, 'on_track', now() - interval '1 day'),
  (5, '44444444-4444-4444-4444-444444444417', (select id from course_sections where section_code = 'TN01-CLS-AI512-01'), 40, 'B+', 87.0, 88, 'on_track', now() - interval '6 hours'),
  (6, '44444444-4444-4444-4444-444444444417', (select id from course_sections where section_code = 'TN01-CLS-AI512-01'), 20, 'C+', 76.0, 70, 'at_risk', now() - interval '3 days'),
  (9, '44444444-4444-4444-4444-444444444417', (select id from course_sections where section_code = 'TN01-CLS-AI512-01'), 50, 'A', 93.0, 97, 'on_track', now() - interval '20 minutes');

-- ── Admin: Course Enrollment roster (SEC-410 Cybersecurity course, admin
-- view — drives course_enrollment_screen.dart; Alex Chen's own SEC-410
-- enrollment above rounds this out to a 5-student roster) ───────────────

insert into student_courses (student_id, course_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, sponsorship, last_activity_at, is_online_now) values
  (2, '44444444-4444-4444-4444-444444444405', 96, 'A+', 96.1, 98, 'on_track', 'Corporate Sponsored', now() - interval '35 minutes', true),
  (9, '44444444-4444-4444-4444-444444444405', 88, 'B+', 88.5, 91, 'on_track', 'Self-Enrolled (Direct)', now() - interval '1 day', true),
  (7, '44444444-4444-4444-4444-444444444405', 60, 'C', 73.2, 55, 'at_risk', 'Corporate Sponsored', now() - interval '4 days', false),
  (10, '44444444-4444-4444-4444-444444444405', 84, 'B+', 89.0, 93, 'on_track', 'Corporate Sponsored', now() - interval '5 hours', true);

-- ── Admin: Enrollment candidates / waitlist for PY-402 (drives
-- enroll_students_screen.dart — its capacity comes from the PY-402
-- 'Sec A01' course_sections row above; enrolled count is derived live
-- from the `student_courses` rows enrolled in that section) ─────────────

insert into enrollment_candidates (student_name, student_employee_id, student_email, department, cohort, role, target_course_id, prerequisite_status, prerequisite_detail, standing_detail, sponsorship, queue_tag, needs_review) values
  ('Daniel Ross', 'EMP-61092', 'daniel.ross@enterprise.com', 'Data Architecture', 'January 2025 Intake', 'IT Support Specialist', '44444444-4444-4444-4444-444444444401', 'met', 'CS-101 Met (GPA 3.9)', 'Academic Good Standing', 'Enterprise Full', 'Staged', false),
  ('Emily Lawson', 'EMP-88231', 'emily.lawson@enterprise.com', 'AI Engineering', 'January 2025 Intake', 'Data Analyst', '44444444-4444-4444-4444-444444444401', 'met', 'MATH-204 Met', 'Academic Good Standing', 'Enterprise Full', 'Waitlist #1', false),
  -- Cloud Engineer's role→course mapping doesn't include PY-402 — demonstrates the role-mismatch flag.
  ('Ravi Kumar', 'EMP-54910', 'ravi.kumar@enterprise.com', 'Cloud & Distributed', 'January 2025 Intake', 'Cloud Engineer', '44444444-4444-4444-4444-444444444401', 'met', 'All Prerequisites Met', 'Ready for section assign', 'Enterprise Full', null, false),
  ('Sophia Martinez', 'EMP-30491', 's.martinez@enterprise.com', 'Data Architecture', 'January 2025 Intake', 'Data Analyst', '44444444-4444-4444-4444-444444444401', 'met', 'Prereq PY-101 Verified', 'Academic Good Standing', 'Self-Enrolled', null, false),
  -- Executive Manager's role→course mapping doesn't include PY-402 — demonstrates the role-mismatch flag.
  ('Jason Todd', 'EMP-77182', 'jason.todd@enterprise.com', 'Executive Operations', 'Executive Cohort 2025', 'Executive Manager', '44444444-4444-4444-4444-444444444401', 'pending', 'Prereq Waiver Required', 'Conditional dean approval', 'Enterprise Full', 'Waitlist #2', true);

-- ── Syllabus authoring tree — PY-402 example (drives course_syllabus_screen,
-- exam_editor_screen, assignment_editor_screen, and the "Mark
-- Assignment"/"Mark Exam" screens). Two sessions under PY-402's existing
-- "Foundations of Enterprise Python" module: one holding a weighted
-- assignment with lecturer-defined criteria, one holding a weighted exam
-- with per-question marks — together 50% of the class's 100% weightage
-- budget, leaving room to add more without tripping the cap. ─────────────

insert into sessions (id, module_id, session_name, session_description, session_sorting) values
  ('cccccccc-cccc-cccc-cccc-cccccccccc01', '55555555-5555-5555-5555-555555555501', 'Week 3 — ETL Capstone', 'Applied assignment covering pipeline design.', 4),
  ('cccccccc-cccc-cccc-cccc-cccccccccc02', '55555555-5555-5555-5555-555555555501', 'Week 4 — Checkpoint Assessment', 'Graded checkpoint exam on core syntax and pandas fundamentals.', 5);

insert into content_blocks (id, session_id, block_type, block_content, block_sorting) values
  ('dddddddd-dddd-dddd-dddd-dddddddddd01', 'cccccccc-cccc-cccc-cccc-cccccccccc01', 'assignment',
    '{"title": "ETL Pipeline Capstone Assignment", "description": "Build an automated ETL pipeline against the enterprise sample dataset.", "instructions": "Submit your pipeline script plus a short write-up covering your design decisions and how you handled schema drift.", "dueDate": "2025-11-24T23:59:00.000", "weightage": 30, "instructionFiles": [{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/grading_rubric.pdf", "name": "grading_rubric.pdf"}]}'::jsonb, 0),
  ('dddddddd-dddd-dddd-dddd-dddddddddd02', 'cccccccc-cccc-cccc-cccc-cccccccccc02', 'exam',
    '{"title": "Python Fundamentals Checkpoint Exam", "description": "Checkpoint covering core syntax and pandas fundamentals.", "instructions": "Answer every question. No external resources for the multiple-choice/true-false section.", "dueDate": "2025-12-01T23:59:00.000", "mode": "normal", "weightage": 20}'::jsonb, 0);

insert into assignment_criteria (id, content_block_id, criterion_label, max_marks, criterion_sorting) values
  ('dddddddd-dddd-dddd-dddd-dddddddddd11', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'Code Correctness', 40, 0),
  ('dddddddd-dddd-dddd-dddd-dddddddddd12', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'Pipeline Design & Architecture', 30, 1),
  ('dddddddd-dddd-dddd-dddd-dddddddddd13', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'Documentation & Write-up', 30, 2);

insert into exam_sections (id, content_block_id, section_name, section_sorting) values
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'dddddddd-dddd-dddd-dddd-dddddddddd02', 'Section A — Core Concepts', 0);

insert into exam_questions (id, exam_section_id, question_text, question_type, marks, question_sorting) values
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'Which keyword defines a function in Python?', 'single_choice', 5, 0),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'Which pandas method removes duplicate rows from a DataFrame?', 'single_choice', 5, 1),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee13', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'Python virtual environments isolate package dependencies per project.', 'boolean', 5, 2),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee14', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'Briefly explain the difference between a Python list and a tuple.', 'text', 10, 3);

insert into exam_question_options (id, question_id, option_text, is_correct, option_sorting) values
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee31', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11', 'def', true, 0),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee32', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11', 'func', false, 1),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee33', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11', 'function', false, 2),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee34', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11', 'lambda', false, 3),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee35', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12', 'drop_duplicates()', true, 0),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee36', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12', 'dedupe()', false, 1),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee37', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12', 'unique_rows()', false, 2),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee38', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12', 'remove_dupes()', false, 3),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee39', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee13', 'True', true, 0),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee40', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee13', 'False', false, 1);

-- Mock submissions: Alex Chen (1) has submitted both but isn't graded yet;
-- Maya Patel (2) and Elena Rostova Jr. (4) are already graded — so the
-- "Mark Assignment"/"Mark Exam" roster shows all three states (not
-- submitted, submitted, graded); the other PY-402 roster students have no
-- row here at all, which reads as "not submitted".
insert into content_block_submissions (id, content_block_id, student_id, status, submission, marks, total_score, feedback, submitted_at, graded_by, graded_at) values
  ('ffffffff-ffff-ffff-ffff-ffffffffff01', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 1, 'submitted',
    '{"writeup": "Implemented a 3-stage ETL pipeline using pandas and SQLAlchemy 2.0 async sessions, with a Celery-scheduled nightly run. Schema drift is handled by validating incoming columns against a versioned schema registry before load.", "files": [{"name": "etl_pipeline.py", "sizeLabel": "18 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/etl_pipeline.py"}, {"name": "design_notes.pdf", "sizeLabel": "212 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/design_notes.pdf"}]}'::jsonb,
    '{}'::jsonb, null, null, now() - interval '2 days', null, null),
  ('ffffffff-ffff-ffff-ffff-ffffffffff02', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 2, 'graded',
    '{"writeup": "Built a modular extract/transform/load pipeline with retry-safe API calls and a pytest suite covering the transform layer.", "files": [{"name": "pipeline_maya.py", "sizeLabel": "22 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/pipeline_maya.py"}]}'::jsonb,
    '{"dddddddd-dddd-dddd-dddd-dddddddddd11": 38, "dddddddd-dddd-dddd-dddd-dddddddddd12": 27, "dddddddd-dddd-dddd-dddd-dddddddddd13": 26}'::jsonb,
    91, 'Solid pipeline implementation with clear documentation — minor deduction for missing an edge-case test on empty source files.', now() - interval '5 days', '11111111-1111-1111-1111-111111111101', now() - interval '3 days'),
  ('ffffffff-ffff-ffff-ffff-ffffffffff03', 'dddddddd-dddd-dddd-dddd-dddddddddd02', 1, 'submitted',
    '{"answers": [{"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11", "selectedOptionIds": ["eeeeeeee-eeee-eeee-eeee-eeeeeeeeee31"]}, {"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12", "selectedOptionIds": ["eeeeeeee-eeee-eeee-eeee-eeeeeeeeee37"]}, {"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee13", "selectedOptionIds": ["eeeeeeee-eeee-eeee-eeee-eeeeeeeeee39"]}, {"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee14", "textAnswer": "A list is mutable and ordered, so items can be changed after creation; a tuple is immutable, so once created its contents cannot change."}]}'::jsonb,
    '{}'::jsonb, null, null, now() - interval '1 day', null, null),
  ('ffffffff-ffff-ffff-ffff-ffffffffff04', 'dddddddd-dddd-dddd-dddd-dddddddddd02', 4, 'graded',
    '{"answers": [{"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11", "selectedOptionIds": ["eeeeeeee-eeee-eeee-eeee-eeeeeeeeee31"]}, {"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12", "selectedOptionIds": ["eeeeeeee-eeee-eeee-eeee-eeeeeeeeee35"]}, {"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee13", "selectedOptionIds": ["eeeeeeee-eeee-eeee-eeee-eeeeeeeeee39"]}, {"questionId": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee14", "textAnswer": "A list is mutable and can grow or shrink; a tuple is fixed-size and immutable, which makes it hashable and usable as a dict key."}]}'::jsonb,
    '{"eeeeeeee-eeee-eeee-eeee-eeeeeeeeee11": 5, "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee12": 5, "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee13": 5, "eeeeeeee-eeee-eeee-eeee-eeeeeeeeee14": 8}'::jsonb,
    23, 'Strong grasp of core concepts; minor clarity issue explaining tuple hashability.', now() - interval '4 days', '11111111-1111-1111-1111-111111111101', now() - interval '2 days');

-- ── Syllabus authoring tree — AI-330 example ("Quiz 1"), for exercising the
-- "Mark Exam" grading flow on a second class/lecturer (Dr. Emmett Brown).
-- Enrolls 5 students into TN01-CLS-AI330-A01 (student 1/Alex Chen is
-- already enrolled in AI-330 from the catalogue seed above, without a
-- section — left as-is), adds a 4-question quiz with per-question marks,
-- and seeds one ungraded + one already-graded submission so both roster
-- states show up on "Mark Exam". ─────────────────────────────────────────

insert into student_courses (student_id, course_id, section_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, last_activity_at) values
  (2, '44444444-4444-4444-4444-444444444403', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 35, 'B+', 87.0, 94, 'on_track', now() - interval '3 hours'),
  (3, '44444444-4444-4444-4444-444444444403', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 15, 'C', 71.0, 58, 'at_risk', now() - interval '7 days'),
  (5, '44444444-4444-4444-4444-444444444403', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 40, 'A-', 91.0, 96, 'on_track', now() - interval '1 hour'),
  (6, '44444444-4444-4444-4444-444444444403', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 25, 'B', 83.0, 85, 'on_track', now() - interval '2 days'),
  (8, '44444444-4444-4444-4444-444444444403', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 30, 'B+', 88.0, 90, 'on_track', now() - interval '5 hours');

insert into sessions (id, module_id, session_name, session_description, session_sorting) values
  ('22222222-2222-2222-2222-222222220001', '55555555-5555-5555-5555-555555555530', 'Week 1 — Prompt Engineering Quiz', 'Graded checkpoint on core prompting concepts.', 1);

insert into content_blocks (id, session_id, block_type, block_content, block_sorting) values
  ('22222222-2222-2222-2222-222222220002', '22222222-2222-2222-2222-222222220001', 'exam',
    '{"title": "Quiz 1", "description": "Checkpoint quiz on prompt engineering fundamentals.", "instructions": "Answer every question. No external resources for the multiple-choice/true-false section.", "dueDate": "2025-12-05T23:59:00.000", "mode": "normal", "weightage": 15, "instructionFiles": [{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/quiz_1_reference_sheet.pdf", "name": "quiz_1_reference_sheet.pdf"}]}'::jsonb, 0);

insert into exam_sections (id, content_block_id, section_name, section_sorting) values
  ('22222222-2222-2222-2222-222222220003', '22222222-2222-2222-2222-222222220002', 'Section A', 0);

insert into exam_questions (id, exam_section_id, question_text, question_type, marks, question_sorting) values
  ('22222222-2222-2222-2222-222222220011', '22222222-2222-2222-2222-222222220003', 'What is prompt engineering primarily concerned with?', 'single_choice', 5, 0),
  ('22222222-2222-2222-2222-222222220012', '22222222-2222-2222-2222-222222220003', 'Larger context windows always guarantee better response accuracy.', 'boolean', 5, 1),
  ('22222222-2222-2222-2222-222222220013', '22222222-2222-2222-2222-222222220003', 'Which of the following are common prompting techniques? (select all that apply)', 'multi_choice', 5, 2),
  ('22222222-2222-2222-2222-222222220014', '22222222-2222-2222-2222-222222220003', 'Explain the difference between zero-shot and few-shot prompting.', 'text', 10, 3),
  ('22222222-2222-2222-2222-222222220015', '22222222-2222-2222-2222-222222220003', 'Upload your annotated prompt-chain diagram (PDF or image).', 'file_upload', 5, 4);

insert into exam_question_options (id, question_id, option_text, is_correct, option_sorting) values
  ('22222222-2222-2222-2222-222222220021', '22222222-2222-2222-2222-222222220011', 'Designing inputs that reliably elicit desired model outputs', true, 0),
  ('22222222-2222-2222-2222-222222220022', '22222222-2222-2222-2222-222222220011', 'Training a model from scratch on labeled data', false, 1),
  ('22222222-2222-2222-2222-222222220023', '22222222-2222-2222-2222-222222220011', 'Compressing model weights for edge deployment', false, 2),
  ('22222222-2222-2222-2222-222222220024', '22222222-2222-2222-2222-222222220011', 'Writing unit tests for a REST API', false, 3),
  ('22222222-2222-2222-2222-222222220025', '22222222-2222-2222-2222-222222220012', 'True', false, 0),
  ('22222222-2222-2222-2222-222222220026', '22222222-2222-2222-2222-222222220012', 'False', true, 1),
  ('22222222-2222-2222-2222-222222220027', '22222222-2222-2222-2222-222222220013', 'Few-shot prompting', true, 0),
  ('22222222-2222-2222-2222-222222220028', '22222222-2222-2222-2222-222222220013', 'Chain-of-thought prompting', true, 1),
  ('22222222-2222-2222-2222-222222220029', '22222222-2222-2222-2222-222222220013', 'Random token injection', false, 2),
  ('22222222-2222-2222-2222-222222220030', '22222222-2222-2222-2222-222222220013', 'Gradient descent fine-tuning', false, 3);

-- Maya Patel (2): submitted, not yet graded — exercises the "needs grading"
-- state. David Kim (5): already graded — exercises the "graded" state.
insert into content_block_submissions (id, content_block_id, student_id, status, submission, marks, total_score, feedback, submitted_at, graded_by, graded_at) values
  ('22222222-2222-2222-2222-222222220041', '22222222-2222-2222-2222-222222220002', 2, 'submitted',
    '{"answers": [{"questionId": "22222222-2222-2222-2222-222222220011", "selectedOptionIds": ["22222222-2222-2222-2222-222222220021"]}, {"questionId": "22222222-2222-2222-2222-222222220012", "selectedOptionIds": ["22222222-2222-2222-2222-222222220025"]}, {"questionId": "22222222-2222-2222-2222-222222220013", "selectedOptionIds": ["22222222-2222-2222-2222-222222220027"]}, {"questionId": "22222222-2222-2222-2222-222222220014", "textAnswer": "Zero-shot prompting asks the model to perform a task with no examples, relying on its pretrained knowledge; few-shot prompting includes a handful of example input/output pairs in the prompt to steer the model toward the desired pattern."}, {"questionId": "22222222-2222-2222-2222-222222220015", "fileUrls": [{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/maya_prompt_chain_diagram.pdf", "name": "maya_prompt_chain_diagram.pdf"}]}]}'::jsonb,
    '{}'::jsonb, null, null, now() - interval '1 day', null, null),
  ('22222222-2222-2222-2222-222222220042', '22222222-2222-2222-2222-222222220002', 5, 'graded',
    '{"answers": [{"questionId": "22222222-2222-2222-2222-222222220011", "selectedOptionIds": ["22222222-2222-2222-2222-222222220021"]}, {"questionId": "22222222-2222-2222-2222-222222220012", "selectedOptionIds": ["22222222-2222-2222-2222-222222220026"]}, {"questionId": "22222222-2222-2222-2222-222222220013", "selectedOptionIds": ["22222222-2222-2222-2222-222222220027", "22222222-2222-2222-2222-222222220028"]}, {"questionId": "22222222-2222-2222-2222-222222220014", "textAnswer": "Zero-shot prompting gives the model only an instruction with no examples; few-shot prompting adds a small number of worked examples in the prompt so the model can infer the expected format and reasoning pattern before answering."}, {"questionId": "22222222-2222-2222-2222-222222220015", "fileUrls": [{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/david_prompt_chain_diagram.pdf", "name": "david_prompt_chain_diagram.pdf"}]}]}'::jsonb,
    '{"22222222-2222-2222-2222-222222220011": 5, "22222222-2222-2222-2222-222222220012": 5, "22222222-2222-2222-2222-222222220013": 5, "22222222-2222-2222-2222-222222220014": 9, "22222222-2222-2222-2222-222222220015": 4}'::jsonb,
    28, 'Excellent — precise definitions, a clear example-driven explanation, and a well-annotated diagram (minor labeling gap on the retrieval step).', now() - interval '3 days', '11111111-1111-1111-1111-111111111106', now() - interval '1 day');

-- ── Syllabus authoring tree — AI-330 example ("Prompt Library Assignment"),
-- for exercising the "Mark Assignment" grading flow with a file-upload-only
-- submission (no writeup, just attached files) on a second class. Reuses
-- the same 5-student AI-330 roster seeded above. ────────────────────────

insert into sessions (id, module_id, session_name, session_description, session_sorting) values
  ('00000000-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555530', 'Week 2 — Prompt Library Assignment', 'Applied assignment building a reusable prompt library.', 2);

insert into content_blocks (id, session_id, block_type, block_content, block_sorting) values
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'assignment',
    '{"title": "Prompt Library Submission", "description": "Build a reusable library of at least 6 prompts covering 3 different enterprise use cases.", "instructions": "Submit your prompt library as a document plus a short test-results log. No writeup required — file upload only.", "dueDate": "2025-12-10T23:59:00.000", "weightage": 25, "instructionFiles": [{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/prompt_library_template.docx", "name": "prompt_library_template.docx"}]}'::jsonb, 0);

insert into assignment_criteria (id, content_block_id, criterion_label, max_marks, criterion_sorting) values
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000002', 'Prompt Variety & Coverage', 25, 0),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000002', 'Clarity & Structure', 25, 1),
  ('00000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000002', 'Effectiveness (Test Results)', 30, 2),
  ('00000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000002', 'Documentation', 20, 3);

-- Marcus Reed (3): submitted via file upload only (no writeup), not yet
-- graded — exercises the "needs grading" state for a file-only submission.
-- Sophia Loren (6): already graded — exercises the "graded" state.
insert into content_block_submissions (id, content_block_id, student_id, status, submission, marks, total_score, feedback, submitted_at, graded_by, graded_at) values
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000002', 3, 'submitted',
    '{"files": [{"name": "marcus_prompt_library.docx", "sizeLabel": "64 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/marcus_prompt_library.docx"}, {"name": "marcus_test_results.xlsx", "sizeLabel": "31 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/marcus_test_results.xlsx"}]}'::jsonb,
    '{}'::jsonb, null, null, now() - interval '2 days', null, null),
  ('00000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000002', 6, 'graded',
    '{"files": [{"name": "sophia_prompt_library.pdf", "sizeLabel": "88 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sophia_prompt_library.pdf"}, {"name": "sophia_test_results.xlsx", "sizeLabel": "28 KB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sophia_test_results.xlsx"}, {"name": "sophia_demo_screenshots.zip", "sizeLabel": "1.4 MB", "url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sophia_demo_screenshots.zip"}]}'::jsonb,
    '{"00000000-0000-0000-0000-000000000011": 22, "00000000-0000-0000-0000-000000000012": 23, "00000000-0000-0000-0000-000000000013": 27, "00000000-0000-0000-0000-000000000014": 18}'::jsonb,
    90, 'Excellent coverage across all three use cases with strong test-result evidence; documentation could be slightly more detailed on edge cases.', now() - interval '4 days', '11111111-1111-1111-1111-111111111106', now() - interval '2 days');


-- ══════════════════════════════════════════════════════════════════════
-- ── Expansion pack: more courses, more lecturers, more students, more
-- content, and fuller department/track/role/specialization ↔ course
-- mappings (department_courses / track_courses were previously unseeded
-- entirely — the admin Department/Track ↔ Course Mapping screens would
-- have shown empty). Everything below is additive; nothing above this
-- point is touched. ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════

-- ── More master data (new courses need matching lookups) ────────────────

insert into departments (code, name) values
  ('TN01-DEPT-FIN', 'Finance'), ('TN01-DEPT-PUX', 'Product & UX');

insert into program_tracks (code, name) values
  ('TN01-TRK-FINA', 'Financial Analytics Track'), ('TN01-TRK-PUX', 'Product & UX Track');

insert into roles (id, code, name) values
  ('99999999-9999-9999-9999-999999999909', 'TN01-ROLE-PM', 'Product Manager');

insert into lecturer_departments (code, name) values
  ('TN01-LDEPT-CSR', 'Cybersecurity & Risk'), ('TN01-LDEPT-FBO', 'Finance & Business Operations'),
  ('TN01-LDEPT-PUXD', 'Product & UX Design'), ('TN01-LDEPT-SCL', 'Supply Chain & Logistics');

insert into specializations (code, name) values
  ('TN01-SPEC-ZTA', 'Zero Trust Security Architecture'), ('TN01-SPEC-FINM', 'Financial Modeling & FP&A'),
  ('TN01-SPEC-PUXR', 'Product Strategy & UX Research'), ('TN01-SPEC-SCF', 'Supply Chain Analytics & Forecasting');

-- ── More lecturers ────────────────────────────────────────────────────

insert into lecturers (id, name, title, lecturer_code, email, department, specialization, credits_max, status, accredited, manageable, join_date) values
  ('11111111-1111-1111-1111-111111111107', 'Dr. Priya Nair', 'Head of Cybersecurity & Risk', 'TN01-EMP-2201', 'priya.nair@aiei.edu', 'Cybersecurity & Risk', 'Zero Trust Security Architecture', 15, 'Active', true, true, '2022-03-04'),
  ('11111111-1111-1111-1111-111111111108', 'Marcus Webb', 'Cloud Infrastructure Lead', 'TN01-EMP-3387', 'marcus.webb@aiei.edu', 'Computer Science & Data', 'Distributed Cloud Governance', 15, 'Active', true, true, '2021-11-19'),
  ('11111111-1111-1111-1111-111111111109', 'Rachel Goh', 'FP&A Program Director', 'TN01-EMP-4456', 'rachel.goh@aiei.edu', 'Finance & Business Operations', 'Financial Modeling & FP&A', 12, 'Active', true, true, '2020-06-08'),
  ('11111111-1111-1111-1111-111111111110', 'Dr. Wei Chen', 'Product & UX Research Lead', 'TN01-EMP-5514', 'wei.chen@aiei.edu', 'Product & UX Design', 'Product Strategy & UX Research', 12, 'Active', true, true, '2023-01-16'),
  ('11111111-1111-1111-1111-111111111111', 'James Park', 'Supply Chain Analytics Lead', 'TN01-EMP-6623', 'james.park@aiei.edu', 'Supply Chain & Logistics', 'Supply Chain Analytics & Forecasting', 12, 'Active', true, true, '2021-09-27');

-- ── More students (ids 11–18) ────────────────────────────────────────

insert into students (id, name, student_code, email, department, title, program_track, cohort, role, gpa, registration_date) overriding system value values
  (11, 'Wei Xin Tan', 'TN01-EMP-10122', 'weixin.tan@enterprise.com', 'Finance', 'FP&A Associate • Finance', 'Financial Analytics Track', 'September 2025 Intake', 'Financial Analyst', 3.45, '2025-09-01'),
  (12, 'Nadia Rahman', 'TN01-EMP-10233', 'nadia.rahman@enterprise.com', 'Product & UX', 'Associate Product Manager', 'Product & UX Track', 'May 2025 Intake', 'Product Manager', 3.60, '2025-01-15'),
  (13, 'Kai Zhang', 'TN01-EMP-10344', 'kai.zhang@enterprise.com', 'Cloud Engineering', 'Cloud Platform Engineer II', 'Cloud & Distributed Computing', 'January 2025 Intake', 'Cloud Engineer', 3.50, '2025-08-25'),
  (14, 'Farah Ibrahim', 'TN01-EMP-10455', 'farah.ibrahim@enterprise.com', 'Supply Chain', 'Demand Planning Analyst', 'General Enterprise Track', 'January 2025 Intake', 'Data Analyst', 3.20, '2025-08-26'),
  (15, 'Ethan Goh', 'TN01-EMP-10566', 'ethan.goh@enterprise.com', 'Data Architecture', 'Data Platform Associate', 'Data Architecture & Analytics', 'September 2025 Intake', 'IT Support Specialist', 3.15, '2025-09-02'),
  (16, 'Priya Sundaram', 'TN01-EMP-10677', 'priya.sundaram@enterprise.com', 'Global Risk', 'Compliance Analyst • Global Risk', 'Workplace Safety Track', 'May 2025 Intake', 'Compliance Officer', 3.65, '2025-01-16'),
  (17, 'Marcus Lee', 'TN01-EMP-10788', 'marcus.lee@enterprise.com', 'Analytics Platform', 'ML Ops Associate • Analytics Platform', 'AI & Machine Learning', 'January 2025 Intake', 'Data Analyst', 3.80, '2025-08-27'),
  (18, 'Hannah Wong', 'TN01-EMP-10899', 'hannah.wong@enterprise.com', 'Business Intelligence', 'BI Associate • BI Group', 'AI Engineering Track', 'January 2025 Intake', 'Data Analyst', 3.72, '2025-08-28');

select setval(pg_get_serial_sequence('students', 'id'), 18, true);

-- ── More courses (ids 418–425) ───────────────────────────────────────

insert into courses (id, course_code, course_title, course_description, category, image_url) values
  ('44444444-4444-4444-4444-444444444418', 'TN01-FIN-420', 'Treasury & Cash Flow Forecasting for Enterprise Finance Teams', 'Rolling cash forecasts, liquidity risk modeling, and treasury dashboard automation for FP&A teams.', 'techData', null),
  ('44444444-4444-4444-4444-444444444419', 'TN01-PROD-310', 'Product Management Fundamentals for Enterprise Teams', 'Discovery frameworks, roadmap prioritization, and stakeholder alignment for enterprise product teams.', 'productivity', null),
  ('44444444-4444-4444-4444-444444444420', 'TN01-UX-215', 'UX Research Methods & Usability Testing', 'Moderated usability testing, survey design, and synthesizing qualitative research into actionable insights.', 'productivity', null),
  ('44444444-4444-4444-4444-444444444421', 'TN01-SC-330', 'Supply Chain Analytics & Demand Forecasting', 'Statistical forecasting models, inventory optimization, and supplier risk analytics for logistics teams.', 'techData', null),
  ('44444444-4444-4444-4444-444444444422', 'TN01-CYBER-330', 'Incident Response & Digital Forensics', 'Incident response playbooks, chain-of-custody evidence handling, and post-breach forensic analysis.', 'compliance', null),
  ('44444444-4444-4444-4444-444444444423', 'TN01-CLOUD-505', 'Multi-Cloud Architecture & Cost Governance', 'Multi-cloud landing zones, FinOps cost governance, and cross-provider resilience design.', 'techData', null),
  ('44444444-4444-4444-4444-444444444424', 'TN01-AI-410', 'Retrieval-Augmented Generation (RAG) Systems', 'Vector store design, chunking strategies, and production RAG pipelines for enterprise knowledge bases.', 'aiTools', null),
  ('44444444-4444-4444-4444-444444444425', 'TN01-DATA-610', 'Data Warehouse Design & dbt Modeling', 'Dimensional modeling, dbt transformation layers, and warehouse testing/documentation practices.', 'techData', null);

-- ── More course sections — including the two previously lecturer-less
-- catalogue courses, FIN-410 and SEC-410, which now get a real class. ────

insert into course_sections (course_id, section_code, role_label, term, schedule_text, day_of_week, start_time, end_time, location, lecturer_id, capacity, delivery_mode, cohort_id, status) values
  ('44444444-4444-4444-4444-444444444404', 'TN01-CLS-FIN410-A01', 'Primary Instructor', 'AY2025 Term 2', 'Monday 15:00–17:00 • Finance Lab 1', 'Monday', '15:00', '17:00', 'Finance Lab 1', '11111111-1111-1111-1111-111111111109', 32, 'physical', (select id from cohorts where name = 'September 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444405', 'TN01-CLS-SEC410-A01', 'Primary Instructor', 'AY2025 Term 2', 'Wednesday 09:00–11:00 • Security Ops Lab', 'Wednesday', '09:00', '11:00', 'Security Ops Lab', '11111111-1111-1111-1111-111111111107', 40, 'physical', (select id from cohorts where name = 'January 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444418', 'TN01-CLS-FIN420-A01', 'Primary Instructor', 'AY2025 Term 2', 'Thursday 15:00–17:00 • Finance Lab 1', 'Thursday', '15:00', '17:00', 'Finance Lab 1', '11111111-1111-1111-1111-111111111109', 30, 'physical', (select id from cohorts where name = 'September 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444419', 'TN01-CLS-PROD310-A01', 'Primary Instructor', 'AY2025 Term 2', 'Tuesday 13:00–15:00 • Product Studio A', 'Tuesday', '13:00', '15:00', 'Product Studio A', '11111111-1111-1111-1111-111111111110', 35, 'physical', (select id from cohorts where name = 'May 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444420', 'TN01-CLS-UX215-A01', 'Primary Instructor', 'AY2025 Term 2', 'Thursday 13:00–15:00 • Product Studio A', 'Thursday', '13:00', '15:00', 'Product Studio A', '11111111-1111-1111-1111-111111111110', 28, 'physical', (select id from cohorts where name = 'May 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444421', 'TN01-CLS-SC330-A01', 'Primary Instructor', 'AY2025 Term 2', 'Monday 10:00–12:00 • Logistics Analytics Lab', 'Monday', '10:00', '12:00', 'Logistics Analytics Lab', '11111111-1111-1111-1111-111111111111', 30, 'physical', (select id from cohorts where name = 'January 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444422', 'TN01-CLS-CYBER330-A01', 'Primary Instructor', 'AY2025 Term 2', 'Friday 09:00–12:00 • Security Ops Lab', 'Friday', '09:00', '12:00', 'Security Ops Lab', '11111111-1111-1111-1111-111111111107', 25, 'physical', (select id from cohorts where name = 'January 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444423', 'TN01-CLS-CLOUD505-A01', 'Primary Instructor', 'AY2025 Term 2', 'Wednesday 14:00–16:00 • Cloud Infra Lab', 'Wednesday', '14:00', '16:00', 'Cloud Infra Lab', '11111111-1111-1111-1111-111111111108', 35, 'online', (select id from cohorts where name = 'September 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444424', 'TN01-CLS-AI410-A01', 'Primary Instructor', 'AY2025 Term 2', 'Friday 14:00–17:00 • AI Research Lab 1', 'Friday', '14:00', '17:00', 'AI Research Lab 1', '11111111-1111-1111-1111-111111111103', 30, 'physical', (select id from cohorts where name = 'January 2025 Intake'), 'in_progress'),
  ('44444444-4444-4444-4444-444444444425', 'TN01-CLS-DATA610-A01', 'Primary Instructor', 'AY2025 Term 2', 'Tuesday 09:00–11:00 • Data Lab 3B', 'Tuesday', '09:00', '11:00', 'Data Lab 3B', '11111111-1111-1111-1111-111111111101', 40, 'physical', (select id from cohorts where name = 'September 2025 Intake'), 'in_progress');

-- Give Marcus Webb the previously-unassigned CLOUD-410 section too
-- (CYBER-202 is left unassigned — keeps the Lecturer Allocation "needs
-- assignment" demo state meaningful).
update course_sections set
  lecturer_id = '11111111-1111-1111-1111-111111111108', role_label = 'Primary Instructor', status = 'in_progress',
  schedule_text = 'Thursday 09:00–11:00 • Cloud Infra Lab', day_of_week = 'Thursday', start_time = '09:00', end_time = '11:00', location = 'Cloud Infra Lab'
  where section_code = 'TN01-CLS-CLOUD410-01';

-- ── Lecturer → Course mapping for all the above ──────────────────────

insert into lecturer_courses (lecturer_id, course_id) values
  ('11111111-1111-1111-1111-111111111109', '44444444-4444-4444-4444-444444444404'), -- Rachel Goh: FIN-410
  ('11111111-1111-1111-1111-111111111109', '44444444-4444-4444-4444-444444444418'), -- Rachel Goh: FIN-420
  ('11111111-1111-1111-1111-111111111107', '44444444-4444-4444-4444-444444444405'), -- Priya Nair: SEC-410
  ('11111111-1111-1111-1111-111111111107', '44444444-4444-4444-4444-444444444422'), -- Priya Nair: CYBER-330
  ('11111111-1111-1111-1111-111111111110', '44444444-4444-4444-4444-444444444419'), -- Wei Chen: PROD-310
  ('11111111-1111-1111-1111-111111111110', '44444444-4444-4444-4444-444444444420'), -- Wei Chen: UX-215
  ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444421'), -- James Park: SC-330
  ('11111111-1111-1111-1111-111111111108', '44444444-4444-4444-4444-444444444423'), -- Marcus Webb: CLOUD-505
  ('11111111-1111-1111-1111-111111111108', '44444444-4444-4444-4444-444444444416'), -- Marcus Webb: CLOUD-410
  ('11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444424'), -- Aris Thorne: AI-410
  ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444425'); -- Sarah Lin: DATA-610

-- ── Role → Course mapping for the new courses ────────────────────────

insert into role_courses (role_id, course_id) values
  ((select id from roles where name = 'Financial Analyst'), '44444444-4444-4444-4444-444444444418'),
  ((select id from roles where name = 'Product Manager'), '44444444-4444-4444-4444-444444444419'),
  ((select id from roles where name = 'Product Manager'), '44444444-4444-4444-4444-444444444420'),
  ((select id from roles where name = 'Data Analyst'), '44444444-4444-4444-4444-444444444421'),
  ((select id from roles where name = 'Data Analyst'), '44444444-4444-4444-4444-444444444425'),
  ((select id from roles where name = 'Data Analyst'), '44444444-4444-4444-4444-444444444424'),
  ((select id from roles where name = 'IT Support Specialist'), '44444444-4444-4444-4444-444444444423'),
  ((select id from roles where name = 'Cloud Engineer'), '44444444-4444-4444-4444-444444444423'),
  ((select id from roles where name = 'Compliance Officer'), '44444444-4444-4444-4444-444444444422');

-- ── Specialization → Course mapping for the new courses ──────────────

insert into specialization_courses (specialization_id, course_id) values
  ((select id from specializations where name = 'Zero Trust Security Architecture'), '44444444-4444-4444-4444-444444444405'),
  ((select id from specializations where name = 'Zero Trust Security Architecture'), '44444444-4444-4444-4444-444444444422'),
  ((select id from specializations where name = 'Zero Trust Security Architecture'), '44444444-4444-4444-4444-444444444415'),
  ((select id from specializations where name = 'Financial Modeling & FP&A'), '44444444-4444-4444-4444-444444444404'),
  ((select id from specializations where name = 'Financial Modeling & FP&A'), '44444444-4444-4444-4444-444444444418'),
  ((select id from specializations where name = 'Product Strategy & UX Research'), '44444444-4444-4444-4444-444444444419'),
  ((select id from specializations where name = 'Product Strategy & UX Research'), '44444444-4444-4444-4444-444444444420'),
  ((select id from specializations where name = 'Supply Chain Analytics & Forecasting'), '44444444-4444-4444-4444-444444444421'),
  ((select id from specializations where name = 'Distributed Cloud Governance'), '44444444-4444-4444-4444-444444444423'),
  ((select id from specializations where name = 'Deep Neural Architectures'), '44444444-4444-4444-4444-444444444424'),
  ((select id from specializations where name = 'Distributed ETL & Python'), '44444444-4444-4444-4444-444444444425');

-- ── Department → Course mapping (previously entirely unseeded — the
-- Department ↔ Course Mapping admin screen would have shown empty) ────

insert into department_courses (department_id, course_id) values
  ((select id from departments where name = 'Operations'), '44444444-4444-4444-4444-444444444401'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444401'),
  ((select id from departments where name = 'Data Architecture'), '44444444-4444-4444-4444-444444444401'),
  ((select id from departments where name = 'Workplace Safety'), '44444444-4444-4444-4444-444444444402'),
  ((select id from departments where name = 'Global Risk'), '44444444-4444-4444-4444-444444444402'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444403'),
  ((select id from departments where name = 'Business Intelligence'), '44444444-4444-4444-4444-444444444403'),
  ((select id from departments where name = 'Data Architecture'), '44444444-4444-4444-4444-444444444403'),
  ((select id from departments where name = 'Finance'), '44444444-4444-4444-4444-444444444404'),
  ((select id from departments where name = 'Treasury Tech'), '44444444-4444-4444-4444-444444444404'),
  ((select id from departments where name = 'Cloud Engineering'), '44444444-4444-4444-4444-444444444405'),
  ((select id from departments where name = 'Global Risk'), '44444444-4444-4444-4444-444444444405'),
  ((select id from departments where name = 'Operations'), '44444444-4444-4444-4444-444444444406'),
  ((select id from departments where name = 'Data Architecture'), '44444444-4444-4444-4444-444444444407'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444407'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444408'),
  ((select id from departments where name = 'Business Intelligence'), '44444444-4444-4444-4444-444444444408'),
  ((select id from departments where name = 'Workplace Safety'), '44444444-4444-4444-4444-444444444409'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444410'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444411'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444412'),
  ((select id from departments where name = 'Business Intelligence'), '44444444-4444-4444-4444-444444444413'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444413'),
  ((select id from departments where name = 'Operations'), '44444444-4444-4444-4444-444444444414'),
  ((select id from departments where name = 'Cloud Engineering'), '44444444-4444-4444-4444-444444444415'),
  ((select id from departments where name = 'Global Risk'), '44444444-4444-4444-4444-444444444415'),
  ((select id from departments where name = 'Cloud Engineering'), '44444444-4444-4444-4444-444444444416'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444417'),
  ((select id from departments where name = 'Finance'), '44444444-4444-4444-4444-444444444418'),
  ((select id from departments where name = 'Treasury Tech'), '44444444-4444-4444-4444-444444444418'),
  ((select id from departments where name = 'Product & UX'), '44444444-4444-4444-4444-444444444419'),
  ((select id from departments where name = 'Business Intelligence'), '44444444-4444-4444-4444-444444444419'),
  ((select id from departments where name = 'Product & UX'), '44444444-4444-4444-4444-444444444420'),
  ((select id from departments where name = 'Supply Chain'), '44444444-4444-4444-4444-444444444421'),
  ((select id from departments where name = 'Cloud Engineering'), '44444444-4444-4444-4444-444444444422'),
  ((select id from departments where name = 'Global Risk'), '44444444-4444-4444-4444-444444444422'),
  ((select id from departments where name = 'Cloud Engineering'), '44444444-4444-4444-4444-444444444423'),
  ((select id from departments where name = 'Data Architecture'), '44444444-4444-4444-4444-444444444423'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444424'),
  ((select id from departments where name = 'Data Architecture'), '44444444-4444-4444-4444-444444444424'),
  ((select id from departments where name = 'Data Architecture'), '44444444-4444-4444-4444-444444444425'),
  ((select id from departments where name = 'Analytics Platform'), '44444444-4444-4444-4444-444444444425');

-- ── Program Track → Course mapping (also previously entirely unseeded) ─

insert into track_courses (track_id, course_id) values
  ((select id from program_tracks where name = 'Data Architecture Specialist'), '44444444-4444-4444-4444-444444444401'),
  ((select id from program_tracks where name = 'Data Architecture Specialist'), '44444444-4444-4444-4444-444444444407'),
  ((select id from program_tracks where name = 'Data Architecture Specialist'), '44444444-4444-4444-4444-444444444425'),
  ((select id from program_tracks where name = 'AI Engineering Track'), '44444444-4444-4444-4444-444444444403'),
  ((select id from program_tracks where name = 'AI Engineering Track'), '44444444-4444-4444-4444-444444444408'),
  ((select id from program_tracks where name = 'AI Engineering Track'), '44444444-4444-4444-4444-444444444424'),
  ((select id from program_tracks where name = 'AI Engineering Track'), '44444444-4444-4444-4444-444444444413'),
  ((select id from program_tracks where name = 'Executive Operations'), '44444444-4444-4444-4444-444444444406'),
  ((select id from program_tracks where name = 'Executive Operations'), '44444444-4444-4444-4444-444444444414'),
  ((select id from program_tracks where name = 'Workplace Safety Track'), '44444444-4444-4444-4444-444444444402'),
  ((select id from program_tracks where name = 'Workplace Safety Track'), '44444444-4444-4444-4444-444444444409'),
  ((select id from program_tracks where name = 'Workplace Safety Track'), '44444444-4444-4444-4444-444444444422'),
  ((select id from program_tracks where name = 'Cloud & Distributed Systems'), '44444444-4444-4444-4444-444444444416'),
  ((select id from program_tracks where name = 'Cloud & Distributed Systems'), '44444444-4444-4444-4444-444444444423'),
  ((select id from program_tracks where name = 'Cloud & Distributed Systems'), '44444444-4444-4444-4444-444444444407'),
  ((select id from program_tracks where name = 'AI & Machine Learning'), '44444444-4444-4444-4444-444444444410'),
  ((select id from program_tracks where name = 'AI & Machine Learning'), '44444444-4444-4444-4444-444444444411'),
  ((select id from program_tracks where name = 'AI & Machine Learning'), '44444444-4444-4444-4444-444444444412'),
  ((select id from program_tracks where name = 'AI & Machine Learning'), '44444444-4444-4444-4444-444444444408'),
  ((select id from program_tracks where name = 'Cloud & Distributed Computing'), '44444444-4444-4444-4444-444444444416'),
  ((select id from program_tracks where name = 'Cloud & Distributed Computing'), '44444444-4444-4444-4444-444444444423'),
  ((select id from program_tracks where name = 'Cloud & Distributed Computing'), '44444444-4444-4444-4444-444444444415'),
  ((select id from program_tracks where name = 'Data Architecture & Analytics'), '44444444-4444-4444-4444-444444444407'),
  ((select id from program_tracks where name = 'Data Architecture & Analytics'), '44444444-4444-4444-4444-444444444425'),
  ((select id from program_tracks where name = 'Data Architecture & Analytics'), '44444444-4444-4444-4444-444444444401'),
  ((select id from program_tracks where name = 'General Enterprise Track'), '44444444-4444-4444-4444-444444444421'),
  ((select id from program_tracks where name = 'General Enterprise Track'), '44444444-4444-4444-4444-444444444414'),
  ((select id from program_tracks where name = 'Financial Analytics Track'), '44444444-4444-4444-4444-444444444404'),
  ((select id from program_tracks where name = 'Financial Analytics Track'), '44444444-4444-4444-4444-444444444418'),
  ((select id from program_tracks where name = 'Product & UX Track'), '44444444-4444-4444-4444-444444444419'),
  ((select id from program_tracks where name = 'Product & UX Track'), '44444444-4444-4444-4444-444444444420');

-- ── Tags for a few of the new courses ─────────────────────────────────

insert into course_tags (course_id, tag_id) values
  ('44444444-4444-4444-4444-444444444422', '77777777-7777-7777-7777-777777777704'), -- CYBER-330: SECURITY MANDATORY
  ('44444444-4444-4444-4444-444444444424', '77777777-7777-7777-7777-777777777703'), -- AI-410: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444425', '77777777-7777-7777-7777-777777777701'); -- DATA-610: Career Essentials

-- Every remaining course gets at least one tag too (Course Tags is now a
-- compulsory field on the admin course form, so every seeded course must
-- already satisfy that — student-side catalogue cards and the tags filter
-- row need at least one tag per course to render meaningfully).
insert into course_tags (course_id, tag_id) values
  ('44444444-4444-4444-4444-444444444404', '77777777-7777-7777-7777-777777777701'), -- FIN-410: Career Essentials
  ('44444444-4444-4444-4444-444444444407', '77777777-7777-7777-7777-777777777701'), -- DATA-501: Career Essentials
  ('44444444-4444-4444-4444-444444444408', '77777777-7777-7777-7777-777777777703'), -- AI-301: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444409', '77777777-7777-7777-7777-777777777704'), -- SAF-204: SECURITY MANDATORY
  ('44444444-4444-4444-4444-444444444410', '77777777-7777-7777-7777-777777777703'), -- ML-800: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444411', '77777777-7777-7777-7777-777777777703'), -- DL-901: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444412', '77777777-7777-7777-7777-777777777703'), -- RL-705: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444413', '77777777-7777-7777-7777-777777777703'), -- NLP-620: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444414', '77777777-7777-7777-7777-777777777701'), -- COMM-102: Career Essentials
  ('44444444-4444-4444-4444-444444444415', '77777777-7777-7777-7777-777777777704'), -- CYBER-202: SECURITY MANDATORY
  ('44444444-4444-4444-4444-444444444416', '77777777-7777-7777-7777-777777777701'), -- CLOUD-410: Career Essentials
  ('44444444-4444-4444-4444-444444444417', '77777777-7777-7777-7777-777777777703'), -- AI-512: AI UPSKILLING
  ('44444444-4444-4444-4444-444444444418', '77777777-7777-7777-7777-777777777701'), -- FIN-420: Career Essentials
  ('44444444-4444-4444-4444-444444444419', '77777777-7777-7777-7777-777777777701'), -- PROD-310: Career Essentials
  ('44444444-4444-4444-4444-444444444420', '77777777-7777-7777-7777-777777777701'), -- UX-215: Career Essentials
  ('44444444-4444-4444-4444-444444444421', '77777777-7777-7777-7777-777777777701'), -- SC-330: Career Essentials
  ('44444444-4444-4444-4444-444444444423', '77777777-7777-7777-7777-777777777701'); -- CLOUD-505: Career Essentials

-- ── Course Badges (`course_badges`) — the badge(s) a student unlocks on
-- completing each course, configured by an admin on the course form. Every
-- course gets at least one, reusing the 6 seeded certifications thematically
-- rather than inventing a badge per course. ─────────────────────────────
insert into course_badges (course_id, badge_id) values
  ('44444444-4444-4444-4444-444444444401', '88888888-8888-8888-8888-888888888801'), -- PY-402: Python Automation Specialist
  ('44444444-4444-4444-4444-444444444402', '88888888-8888-8888-8888-888888888802'), -- OSHE-101: Certified Safety Officer 2025
  ('44444444-4444-4444-4444-444444444403', '88888888-8888-8888-8888-888888888805'), -- AI-330: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444404', '88888888-8888-8888-8888-888888888806'), -- FIN-410: FP&A Certified Financial Analyst
  ('44444444-4444-4444-4444-444444444405', '88888888-8888-8888-8888-888888888803'), -- SEC-410: Certified Cyber Sentinel
  ('44444444-4444-4444-4444-444444444406', '88888888-8888-8888-8888-888888888804'), -- LEAD-400: Executive Leadership Communicator
  ('44444444-4444-4444-4444-444444444407', '88888888-8888-8888-8888-888888888801'), -- DATA-501: Python Automation Specialist
  ('44444444-4444-4444-4444-444444444408', '88888888-8888-8888-8888-888888888805'), -- AI-301: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444409', '88888888-8888-8888-8888-888888888802'), -- SAF-204: Certified Safety Officer 2025
  ('44444444-4444-4444-4444-444444444410', '88888888-8888-8888-8888-888888888805'), -- ML-800: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444411', '88888888-8888-8888-8888-888888888805'), -- DL-901: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444412', '88888888-8888-8888-8888-888888888805'), -- RL-705: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444413', '88888888-8888-8888-8888-888888888805'), -- NLP-620: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444414', '88888888-8888-8888-8888-888888888804'), -- COMM-102: Executive Leadership Communicator
  ('44444444-4444-4444-4444-444444444415', '88888888-8888-8888-8888-888888888803'), -- CYBER-202: Certified Cyber Sentinel
  ('44444444-4444-4444-4444-444444444416', '88888888-8888-8888-8888-888888888801'), -- CLOUD-410: Python Automation Specialist
  ('44444444-4444-4444-4444-444444444417', '88888888-8888-8888-8888-888888888805'), -- AI-512: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444418', '88888888-8888-8888-8888-888888888806'), -- FIN-420: FP&A Certified Financial Analyst
  ('44444444-4444-4444-4444-444444444419', '88888888-8888-8888-8888-888888888804'), -- PROD-310: Executive Leadership Communicator
  ('44444444-4444-4444-4444-444444444420', '88888888-8888-8888-8888-888888888804'), -- UX-215: Executive Leadership Communicator
  ('44444444-4444-4444-4444-444444444421', '88888888-8888-8888-8888-888888888801'), -- SC-330: Python Automation Specialist
  ('44444444-4444-4444-4444-444444444422', '88888888-8888-8888-8888-888888888803'), -- CYBER-330: Certified Cyber Sentinel
  ('44444444-4444-4444-4444-444444444423', '88888888-8888-8888-8888-888888888801'), -- CLOUD-505: Python Automation Specialist
  ('44444444-4444-4444-4444-444444444424', '88888888-8888-8888-8888-888888888805'), -- AI-410: Enterprise AI & Prompt Engineering
  ('44444444-4444-4444-4444-444444444425', '88888888-8888-8888-8888-888888888801'); -- DATA-610: Python Automation Specialist

-- ── Real curriculum content: AI-410 (RAG Systems) and DATA-610 (dbt
-- Modeling) get a full 3-module lesson/quiz/assignment sequence. ────────

insert into course_modules (id, section_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555540', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 'Foundations of Retrieval-Augmented Generation', 'Why RAG, vector embeddings, and retrieval basics.', 0),
  ('55555555-5555-5555-5555-555555555541', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 'Chunking & Indexing Strategies', 'Document chunking, embedding models, and vector store indexing.', 1),
  ('55555555-5555-5555-5555-555555555542', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 'Production RAG Pipelines', 'Query rewriting, re-ranking, and evaluation for production systems.', 2);

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting) values
  ('66666666-6666-6666-6666-666666666700', '55555555-5555-5555-5555-555555555540', 'Lesson 1: Why RAG? Grounding LLMs in Enterprise Knowledge', 'video',
    '{"durationMinutes": 24, "transcript": "Why RAG beats fine-tuning for fast-changing enterprise knowledge, and how retrieval grounds model outputs in source documents."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666701', '55555555-5555-5555-5555-555555555540', 'RAG Foundations Knowledge Check', 'quiz',
    '{"quizLength": 3, "attemptsPermitted": 3, "timeAllocatedMinutes": 10, "passingScore": 80, "questions": [
      {"question": "What is the main advantage of RAG over fine-tuning for frequently changing knowledge?", "mcq": true, "items": ["A. Lower inference latency", "B. No retraining needed when source documents change", "C. Smaller model size", "D. Better handling of code generation"], "expectedAns": "B"},
      {"question": "What does a vector embedding represent?", "mcq": true, "items": ["A. A compressed copy of the raw file", "B. A numerical representation of semantic meaning", "C. A database index on primary keys", "D. A hash of the document title"], "expectedAns": "B"}
    ]}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666702', '55555555-5555-5555-5555-555555555541', 'Lesson 2: Chunking Strategies for Long Documents', 'video',
    '{"durationMinutes": 30, "transcript": "Fixed-size vs. semantic chunking, overlap windows, and preserving document structure across chunk boundaries."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666703', '55555555-5555-5555-5555-555555555541', 'Lesson 3: Choosing & Evaluating Embedding Models', 'video',
    '{"durationMinutes": 27, "transcript": "Comparing open and hosted embedding models on retrieval accuracy, latency, and cost."}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666704', '55555555-5555-5555-5555-555555555542', 'Lesson 4: Query Rewriting & Re-ranking', 'video',
    '{"durationMinutes": 33, "transcript": "Improving retrieval precision with query rewriting, hybrid search, and cross-encoder re-ranking."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666705', '55555555-5555-5555-5555-555555555542', 'Capstone: Build a Production RAG Pipeline', 'assignment',
    '{"instruction": "Design and submit a RAG pipeline over a sample enterprise knowledge base, covering chunking strategy, embedding model choice, retrieval evaluation, and a re-ranking step.", "references": ["https://platform.openai.com/docs/guides/embeddings"], "notes": "Submit source repo link plus a short evaluation report."}'::jsonb, 1);

insert into course_modules (id, section_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555550', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 'Dimensional Modeling Fundamentals', 'Star schemas, fact/dimension tables, and grain.', 0),
  ('55555555-5555-5555-5555-555555555551', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 'dbt Transformation Layers', 'Staging, intermediate, and mart layers with dbt.', 1),
  ('55555555-5555-5555-5555-555555555552', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 'Testing & Documentation', 'dbt tests, documentation, and CI for analytics engineering.', 2);

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting) values
  ('66666666-6666-6666-6666-666666666710', '55555555-5555-5555-5555-555555555550', 'Lesson 1: Star Schemas & Dimensional Modeling', 'video',
    '{"durationMinutes": 26, "transcript": "Fact vs. dimension tables, grain, and designing a star schema from a source ER diagram."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666711', '55555555-5555-5555-5555-555555555550', 'Dimensional Modeling Quiz', 'quiz',
    '{"quizLength": 2, "attemptsPermitted": 3, "timeAllocatedMinutes": 10, "passingScore": 80, "questions": [
      {"question": "What determines the grain of a fact table?", "mcq": true, "items": ["A. The number of columns in the table", "B. What a single row in the table represents", "C. The primary key data type", "D. The refresh schedule"], "expectedAns": "B"},
      {"question": "Which table type typically holds descriptive attributes like customer name or product category?", "mcq": true, "items": ["A. Fact table", "B. Dimension table", "C. Bridge table", "D. Staging table"], "expectedAns": "B"}
    ]}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666712', '55555555-5555-5555-5555-555555555551', 'Lesson 2: Building dbt Staging Models', 'video',
    '{"durationMinutes": 29, "transcript": "Source freshness checks, naming conventions, and light transformations in the staging layer."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666713', '55555555-5555-5555-5555-555555555551', 'Lesson 3: Intermediate & Mart Layer Design', 'video',
    '{"durationMinutes": 31, "transcript": "Reusable intermediate models and building business-facing mart tables on top of them."}'::jsonb, 1),
  ('66666666-6666-6666-6666-666666666714', '55555555-5555-5555-5555-555555555552', 'Lesson 4: dbt Tests & Documentation', 'video',
    '{"durationMinutes": 22, "transcript": "Generic and singular dbt tests, auto-generated documentation, and wiring both into CI."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666715', '55555555-5555-5555-5555-555555555552', 'Capstone: Warehouse Redesign with dbt', 'assignment',
    '{"instruction": "Redesign the provided flat sales export into a staging → intermediate → mart dbt project with tests and generated documentation.", "references": ["https://docs.getdbt.com/docs/build/documentation"], "notes": "Submit your dbt project repo link plus the generated docs site."}'::jsonb, 1);

-- ── Lighter modules for the remaining new/newly-sectioned courses (one
-- video lesson per module — enough to populate the course content screens
-- without a full curriculum on every course). ───────────────────────────

insert into course_modules (id, section_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555560', (select id from course_sections where section_code = 'TN01-CLS-FIN410-A01'), 'Financial Statement Fundamentals', 'Reading and modeling the three core financial statements.', 0),
  ('55555555-5555-5555-5555-555555555561', (select id from course_sections where section_code = 'TN01-CLS-FIN410-A01'), 'Building Dynamic Excel Models', 'Driver-based forecasting models and scenario toggles.', 1),
  ('55555555-5555-5555-5555-555555555562', (select id from course_sections where section_code = 'TN01-CLS-SEC410-A01'), 'Social Engineering & Phishing Vectors', 'Common phishing techniques and human-layer defenses.', 0),
  ('55555555-5555-5555-5555-555555555563', (select id from course_sections where section_code = 'TN01-CLS-SEC410-A01'), 'Live Incident Response Drills', 'Tabletop exercises and live phishing simulation debriefs.', 1),
  ('55555555-5555-5555-5555-555555555564', (select id from course_sections where section_code = 'TN01-CLS-FIN420-A01'), 'Cash Flow Forecasting Basics', '13-week rolling cash forecasts and variance analysis.', 0),
  ('55555555-5555-5555-5555-555555555565', (select id from course_sections where section_code = 'TN01-CLS-FIN420-A01'), 'Treasury Dashboard Automation', 'Automating treasury reporting with live data connections.', 1),
  ('55555555-5555-5555-5555-555555555566', (select id from course_sections where section_code = 'TN01-CLS-PROD310-A01'), 'Product Discovery Frameworks', 'Opportunity sizing, customer interviews, and problem validation.', 0),
  ('55555555-5555-5555-5555-555555555567', (select id from course_sections where section_code = 'TN01-CLS-PROD310-A01'), 'Roadmap Prioritization & Stakeholder Alignment', 'RICE/ICE scoring and cross-functional roadmap reviews.', 1),
  ('55555555-5555-5555-5555-555555555568', (select id from course_sections where section_code = 'TN01-CLS-UX215-A01'), 'Usability Testing Fundamentals', 'Planning and moderating usability test sessions.', 0),
  ('55555555-5555-5555-5555-555555555569', (select id from course_sections where section_code = 'TN01-CLS-UX215-A01'), 'Synthesizing Qualitative Research', 'Affinity mapping and turning research notes into insights.', 1),
  ('55555555-5555-5555-5555-555555555570', (select id from course_sections where section_code = 'TN01-CLS-SC330-A01'), 'Demand Forecasting Models', 'Time-series forecasting methods for demand planning.', 0),
  ('55555555-5555-5555-5555-555555555571', (select id from course_sections where section_code = 'TN01-CLS-SC330-A01'), 'Inventory & Supplier Risk Analytics', 'Safety stock modeling and supplier risk scoring.', 1),
  ('55555555-5555-5555-5555-555555555572', (select id from course_sections where section_code = 'TN01-CLS-CYBER330-A01'), 'Incident Response Playbooks', 'Building and rehearsing a structured incident response plan.', 0),
  ('55555555-5555-5555-5555-555555555573', (select id from course_sections where section_code = 'TN01-CLS-CYBER330-A01'), 'Digital Forensics & Chain of Custody', 'Evidence collection, chain of custody, and forensic reporting.', 1),
  ('55555555-5555-5555-5555-555555555574', (select id from course_sections where section_code = 'TN01-CLS-CLOUD505-A01'), 'Multi-Cloud Landing Zone Design', 'Landing zone architecture across AWS, Azure, and GCP.', 0),
  ('55555555-5555-5555-5555-555555555575', (select id from course_sections where section_code = 'TN01-CLS-CLOUD505-A01'), 'FinOps Cost Governance', 'Cost allocation tagging, budgets, and anomaly alerting.', 1);

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting) values
  ('66666666-6666-6666-6666-666666666720', '55555555-5555-5555-5555-555555555560', 'Lesson: Reading the Income Statement, Balance Sheet & Cash Flow Statement', 'video', '{"durationMinutes": 28, "transcript": "How the three statements link together and what each one tells you about a business."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666721', '55555555-5555-5555-5555-555555555561', 'Lesson: Driver-Based Forecasting in Excel', 'video', '{"durationMinutes": 32, "transcript": "Building a driver-based forecast model with switchable scenario assumptions."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666722', '55555555-5555-5555-5555-555555555562', 'Lesson: Anatomy of a Phishing Campaign', 'video', '{"durationMinutes": 20, "transcript": "Common phishing lures, spoofing techniques, and the psychology behind social engineering."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666723', '55555555-5555-5555-5555-555555555563', 'Lesson: Running a Tabletop Incident Response Exercise', 'video', '{"durationMinutes": 35, "transcript": "Structuring a tabletop exercise and debriefing findings into playbook updates."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666724', '55555555-5555-5555-5555-555555555564', 'Lesson: Building a 13-Week Rolling Cash Forecast', 'video', '{"durationMinutes": 24, "transcript": "Structuring a rolling 13-week cash forecast and reconciling it against actuals weekly."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666725', '55555555-5555-5555-5555-555555555565', 'Lesson: Automating Treasury Dashboards', 'video', '{"durationMinutes": 26, "transcript": "Connecting live bank feeds and ERP data into an automated treasury dashboard."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666726', '55555555-5555-5555-5555-555555555566', 'Lesson: Running Effective Customer Discovery Interviews', 'video', '{"durationMinutes": 27, "transcript": "Structuring discovery interviews to avoid leading questions and surface real problems."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666727', '55555555-5555-5555-5555-555555555567', 'Lesson: RICE Scoring & Roadmap Reviews', 'video', '{"durationMinutes": 23, "transcript": "Using RICE scoring to prioritize a backlog and run a cross-functional roadmap review."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666728', '55555555-5555-5555-5555-555555555568', 'Lesson: Planning & Moderating a Usability Test', 'video', '{"durationMinutes": 25, "transcript": "Writing test scripts, recruiting participants, and moderating without leading the user."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666729', '55555555-5555-5555-5555-555555555569', 'Lesson: Affinity Mapping Research Notes', 'video', '{"durationMinutes": 21, "transcript": "Turning raw session notes into clustered themes and actionable insights."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666730', '55555555-5555-5555-5555-555555555570', 'Lesson: Time-Series Forecasting for Demand Planning', 'video', '{"durationMinutes": 30, "transcript": "Moving averages, exponential smoothing, and seasonal decomposition for demand forecasts."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666731', '55555555-5555-5555-5555-555555555571', 'Lesson: Safety Stock & Supplier Risk Scoring', 'video', '{"durationMinutes": 27, "transcript": "Setting safety stock levels and scoring supplier risk across lead time and reliability."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666732', '55555555-5555-5555-5555-555555555572', 'Lesson: Structuring an Incident Response Playbook', 'video', '{"durationMinutes": 29, "transcript": "The phases of incident response and what each playbook section needs to cover."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666733', '55555555-5555-5555-5555-555555555573', 'Lesson: Evidence Collection & Chain of Custody', 'video', '{"durationMinutes": 33, "transcript": "Preserving forensic evidence integrity and documenting an unbroken chain of custody."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666734', '55555555-5555-5555-5555-555555555574', 'Lesson: Designing a Multi-Cloud Landing Zone', 'video', '{"durationMinutes": 34, "transcript": "Landing zone building blocks across AWS, Azure, and GCP, and where they diverge."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666735', '55555555-5555-5555-5555-555555555575', 'Lesson: Cost Allocation Tagging & Budget Alerts', 'video', '{"durationMinutes": 22, "transcript": "Tagging strategy for cost allocation and setting up budget anomaly alerts."}'::jsonb, 0);

-- ── Wire the previously-sectionless FIN-410 / SEC-410 enrollments into
-- their now-assigned course_sections rows (Rachel Goh's / Dr. Priya
-- Nair's rosters). ───────────────────────────────────────────────────

update student_courses set section_id = (select id from course_sections where section_code = 'TN01-CLS-FIN410-A01') where course_id = '44444444-4444-4444-4444-444444444404';
update student_courses set section_id = (select id from course_sections where section_code = 'TN01-CLS-SEC410-A01') where course_id = '44444444-4444-4444-4444-444444444405';

-- ── More student enrollments: new students into new courses, a couple
-- of new students into existing popular courses, and one extra student
-- each added onto the newly-sectioned FIN-410 / SEC-410 rosters. ───────

insert into student_courses (student_id, course_id, section_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, sponsorship, last_activity_at) values
  (11, '44444444-4444-4444-4444-444444444404', (select id from course_sections where section_code = 'TN01-CLS-FIN410-A01'), 55, 'B+', 87.5, 92, 'on_track', 'Corporate Sponsored', now() - interval '4 hours'),
  (16, '44444444-4444-4444-4444-444444444405', (select id from course_sections where section_code = 'TN01-CLS-SEC410-A01'), 40, 'B', 84.0, 88, 'on_track', 'Corporate Sponsored', now() - interval '1 day'),
  (11, '44444444-4444-4444-4444-444444444418', (select id from course_sections where section_code = 'TN01-CLS-FIN420-A01'), 35, 'A-', 90.5, 95, 'on_track', 'Corporate Sponsored', now() - interval '2 hours'),
  (3, '44444444-4444-4444-4444-444444444418', (select id from course_sections where section_code = 'TN01-CLS-FIN420-A01'), 20, 'C+', 75.0, 62, 'at_risk', 'Corporate Sponsored', now() - interval '8 days'),
  (16, '44444444-4444-4444-4444-444444444418', (select id from course_sections where section_code = 'TN01-CLS-FIN420-A01'), 45, 'B+', 88.0, 90, 'on_track', 'Corporate Sponsored', now() - interval '6 hours'),
  (12, '44444444-4444-4444-4444-444444444419', (select id from course_sections where section_code = 'TN01-CLS-PROD310-A01'), 60, 'A', 94.0, 97, 'on_track', 'Corporate Sponsored', now() - interval '30 minutes'),
  (18, '44444444-4444-4444-4444-444444444419', (select id from course_sections where section_code = 'TN01-CLS-PROD310-A01'), 40, 'B+', 88.5, 91, 'on_track', 'Corporate Sponsored', now() - interval '3 hours'),
  (2, '44444444-4444-4444-4444-444444444419', (select id from course_sections where section_code = 'TN01-CLS-PROD310-A01'), 25, 'B', 84.0, 89, 'on_track', 'Corporate Sponsored', now() - interval '2 days'),
  (12, '44444444-4444-4444-4444-444444444420', (select id from course_sections where section_code = 'TN01-CLS-UX215-A01'), 50, 'A-', 91.5, 96, 'on_track', 'Corporate Sponsored', now() - interval '1 hour'),
  (18, '44444444-4444-4444-4444-444444444420', (select id from course_sections where section_code = 'TN01-CLS-UX215-A01'), 30, 'B', 83.0, 87, 'on_track', 'Corporate Sponsored', now() - interval '5 hours'),
  (14, '44444444-4444-4444-4444-444444444421', (select id from course_sections where section_code = 'TN01-CLS-SC330-A01'), 45, 'B+', 87.0, 90, 'on_track', 'Corporate Sponsored', now() - interval '4 hours'),
  (6, '44444444-4444-4444-4444-444444444421', (select id from course_sections where section_code = 'TN01-CLS-SC330-A01'), 20, 'C', 72.0, 58, 'at_risk', 'Corporate Sponsored', now() - interval '9 days'),
  (17, '44444444-4444-4444-4444-444444444421', (select id from course_sections where section_code = 'TN01-CLS-SC330-A01'), 55, 'A-', 91.0, 95, 'on_track', 'Corporate Sponsored', now() - interval '20 minutes'),
  (13, '44444444-4444-4444-4444-444444444422', (select id from course_sections where section_code = 'TN01-CLS-CYBER330-A01'), 35, 'B', 83.5, 89, 'on_track', 'Corporate Sponsored', now() - interval '3 hours'),
  (8, '44444444-4444-4444-4444-444444444422', (select id from course_sections where section_code = 'TN01-CLS-CYBER330-A01'), 50, 'A-', 90.0, 94, 'on_track', 'Corporate Sponsored', now() - interval '1 hour'),
  (4, '44444444-4444-4444-4444-444444444422', (select id from course_sections where section_code = 'TN01-CLS-CYBER330-A01'), 15, 'C+', 74.0, 60, 'at_risk', 'Corporate Sponsored', now() - interval '10 days'),
  (13, '44444444-4444-4444-4444-444444444423', (select id from course_sections where section_code = 'TN01-CLS-CLOUD505-A01'), 40, 'B+', 86.5, 91, 'on_track', 'Corporate Sponsored', now() - interval '2 hours'),
  (8, '44444444-4444-4444-4444-444444444423', (select id from course_sections where section_code = 'TN01-CLS-CLOUD505-A01'), 30, 'B', 82.0, 85, 'on_track', 'Corporate Sponsored', now() - interval '1 day'),
  (15, '44444444-4444-4444-4444-444444444423', (select id from course_sections where section_code = 'TN01-CLS-CLOUD505-A01'), 20, 'B-', 79.0, 83, 'on_track', 'Corporate Sponsored', now() - interval '6 hours'),
  (17, '44444444-4444-4444-4444-444444444424', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 30, 'A', 93.0, 96, 'on_track', 'Corporate Sponsored', now() - interval '15 minutes'),
  (9, '44444444-4444-4444-4444-444444444424', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 25, 'B+', 87.0, 90, 'on_track', 'Corporate Sponsored', now() - interval '4 hours'),
  (5, '44444444-4444-4444-4444-444444444424', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 45, 'A-', 91.0, 95, 'on_track', 'Corporate Sponsored', now() - interval '2 hours'),
  (18, '44444444-4444-4444-4444-444444444424', (select id from course_sections where section_code = 'TN01-CLS-AI410-A01'), 15, 'B', 84.0, 88, 'on_track', 'Corporate Sponsored', now() - interval '7 hours'),
  (15, '44444444-4444-4444-4444-444444444425', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 35, 'B+', 88.0, 92, 'on_track', 'Corporate Sponsored', now() - interval '1 hour'),
  (9, '44444444-4444-4444-4444-444444444425', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 20, 'B', 83.0, 86, 'on_track', 'Corporate Sponsored', now() - interval '3 hours'),
  (17, '44444444-4444-4444-4444-444444444425', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 40, 'A-', 90.5, 94, 'on_track', 'Corporate Sponsored', now() - interval '30 minutes'),
  (5, '44444444-4444-4444-4444-444444444425', (select id from course_sections where section_code = 'TN01-CLS-DATA610-A01'), 10, 'B-', 78.5, 82, 'on_track', 'Corporate Sponsored', now() - interval '5 hours'),
  (15, '44444444-4444-4444-4444-444444444401', (select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), 25, 'B', 83.5, 88, 'on_track', 'Corporate Sponsored', now() - interval '2 hours'),
  (13, '44444444-4444-4444-4444-444444444407', (select id from course_sections where section_code = 'TN01-CLS-DATA501-B02'), 30, 'B+', 86.0, 90, 'on_track', 'Corporate Sponsored', now() - interval '4 hours'),
  (17, '44444444-4444-4444-4444-444444444408', (select id from course_sections where section_code = 'TN01-CLS-AI301-C01'), 35, 'A-', 90.0, 93, 'on_track', 'Corporate Sponsored', now() - interval '1 hour');

-- ══════════════════════════════════════════════════════════════════════
-- ── Content pack: every course now has at least two modules that live in
-- the real student-facing sessions/content-block tree (the one
-- course_content_screen.dart and course_syllabus_screen.dart actually
-- render), each module with two sessions mixing text/link/file/assignment
-- content. Courses that already had course_modules from the old
-- module_materials system, or partial content_blocks coverage, get a
-- second/third module wired into the new tree rather than duplicated —
-- the old module_materials rows are left untouched. All new assignment
-- blocks carry a real description + instructions, matching the existing
-- ones (dddddddd01/02, the AI-330 Quiz 1 / Prompt Library blocks) that
-- were already proper. ──────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════

-- ── New course_modules (25 rows) for the 12 courses that previously had
-- zero content in the new tree, plus one extra module for AI-330 (which
-- already had one qualifying module via its Week 0/1/2 sessions). ──────

insert into course_modules (id, section_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555604', (select id from course_sections where section_code = 'TN01-CLS-AI330-A01'), 'Context Retrieval & Agentic Workflows', 'Retrieval pipelines and multi-step agent design for prompt-driven systems.', 1),
  ('55555555-5555-5555-5555-555555555580', (select id from course_sections where section_code = 'TN01-CLS-LEAD400-E1'), 'Boardroom Presentation Fundamentals', 'Structuring and delivering high-stakes executive presentations.', 0),
  ('55555555-5555-5555-5555-555555555581', (select id from course_sections where section_code = 'TN01-CLS-LEAD400-E1'), 'Crisis Communication & Conflict Mediation', 'Leading communication through crisis scenarios and mediating cross-functional conflict.', 1),
  ('55555555-5555-5555-5555-555555555582', (select id from course_sections where section_code = 'TN01-CLS-DATA501-B02'), 'Airflow Orchestration Basics', 'DAG design, scheduling, and dependency management with Apache Airflow.', 0),
  ('55555555-5555-5555-5555-555555555583', (select id from course_sections where section_code = 'TN01-CLS-DATA501-B02'), 'Kafka Streams & Schema Validation', 'Real-time event streaming and enforcing schema contracts across producers/consumers.', 1),
  ('55555555-5555-5555-5555-555555555584', (select id from course_sections where section_code = 'TN01-CLS-AI301-C01'), 'Supervised Learning Foundations', 'Regression, classification, and gradient-boosted tree fundamentals.', 0),
  ('55555555-5555-5555-5555-555555555585', (select id from course_sections where section_code = 'TN01-CLS-AI301-C01'), 'Model Governance & Deployment', 'Model registries, approval workflows, and enterprise deployment governance.', 1),
  ('55555555-5555-5555-5555-555555555586', (select id from course_sections where section_code = 'TN01-CLS-SAF204-H03'), 'Chemical Handling & SDS Documentation', 'Safe chemical handling procedures and Safety Data Sheet documentation.', 0),
  ('55555555-5555-5555-5555-555555555587', (select id from course_sections where section_code = 'TN01-CLS-SAF204-H03'), 'Industrial Hazard Mitigation Planning', 'Identifying industrial hazards and building a mitigation plan.', 1),
  ('55555555-5555-5555-5555-555555555588', (select id from course_sections where section_code = 'TN01-CLS-ML800-GRAD'), 'Transformer Architecture Foundations', 'Self-attention, positional encoding, and transformer block design.', 0),
  ('55555555-5555-5555-5555-555555555589', (select id from course_sections where section_code = 'TN01-CLS-ML800-GRAD'), 'Distributed Training Strategies', 'Data/model parallelism and multi-GPU training strategies.', 1),
  ('55555555-5555-5555-5555-555555555590', (select id from course_sections where section_code = 'TN01-CLS-DL901-DOC'), 'Generative Model Deployment Patterns', 'Serving generative models reliably in production environments.', 0),
  ('55555555-5555-5555-5555-555555555591', (select id from course_sections where section_code = 'TN01-CLS-DL901-DOC'), 'Production Monitoring for Generative Systems', 'Drift detection, output monitoring, and rollback strategies.', 1),
  ('55555555-5555-5555-5555-555555555592', (select id from course_sections where section_code = 'TN01-CLS-RL705-ADV'), 'RL Fundamentals for Robotics', 'Reward shaping, policy gradients, and RL fundamentals applied to robotics.', 0),
  ('55555555-5555-5555-5555-555555555593', (select id from course_sections where section_code = 'TN01-CLS-RL705-ADV'), 'Sim-to-Real Transfer', 'Bridging simulation training environments with real-world robotic deployment.', 1),
  ('55555555-5555-5555-5555-555555555594', (select id from course_sections where section_code = 'TN01-CLS-NLP620-A01'), 'Entity Extraction & Summarization', 'Named entity recognition and abstractive/extractive summarization techniques.', 0),
  ('55555555-5555-5555-5555-555555555595', (select id from course_sections where section_code = 'TN01-CLS-NLP620-A01'), 'Retrieval Systems for Enterprise NLP', 'Building retrieval layers for enterprise search and QA systems.', 1),
  ('55555555-5555-5555-5555-555555555596', (select id from course_sections where section_code = 'TN01-CLS-COMM102-C3'), 'Investor Messaging Fundamentals', 'Structuring clear, credible investor and stakeholder messaging.', 0),
  ('55555555-5555-5555-5555-555555555597', (select id from course_sections where section_code = 'TN01-CLS-COMM102-C3'), 'Cross-Functional Stakeholder Alignment', 'Aligning cross-functional stakeholders around a shared narrative.', 1),
  ('55555555-5555-5555-5555-555555555598', (select id from course_sections where section_code = 'TN01-CLS-CYBER202-02'), 'Zero Trust Network Design', 'Micro-segmentation and least-privilege network design principles.', 0),
  ('55555555-5555-5555-5555-555555555599', (select id from course_sections where section_code = 'TN01-CLS-CYBER202-02'), 'Identity-Aware Proxies & Continuous Verification', 'Identity-aware access proxies and continuous trust verification.', 1),
  ('55555555-5555-5555-5555-555555555600', (select id from course_sections where section_code = 'TN01-CLS-CLOUD410-01'), 'Kubernetes Cluster Design', 'Cluster topology, namespaces, and workload isolation design.', 0),
  ('55555555-5555-5555-5555-555555555601', (select id from course_sections where section_code = 'TN01-CLS-CLOUD410-01'), 'Autoscaling & DevOps Pipelines', 'Horizontal pod autoscaling and CI/CD deployment pipelines.', 1),
  ('55555555-5555-5555-5555-555555555602', (select id from course_sections where section_code = 'TN01-CLS-AI512-01'), 'Multi-Agent Coordination Patterns', 'Coordination protocols and role assignment across cooperating agents.', 0),
  ('55555555-5555-5555-5555-555555555603', (select id from course_sections where section_code = 'TN01-CLS-AI512-01'), 'Autonomy Stack Research Methods', 'Research methodology for evaluating autonomy stack performance.', 1);

-- ── Sessions (2 per module, 48 modules = 96 sessions) ────────────────

insert into sessions (id, module_id, session_name, session_description, session_sorting) values
  -- 1: 502 Data Wrangling with Pandas (PY-402)
  ('f2222222-2222-2222-2222-000000000001', '55555555-5555-5555-5555-555555555502', 'Lesson: Data Wrangling with Pandas', '', 5),
  ('f2222222-2222-2222-2222-000000000002', '55555555-5555-5555-5555-555555555502', 'Data Wrangling with Pandas Assessment', '', 6),
  -- 2: 510 Regulatory Framework (OSHE-101)
  ('f2222222-2222-2222-2222-000000000003', '55555555-5555-5555-5555-555555555510', 'Lesson: Regulatory Framework', '', 1),
  ('f2222222-2222-2222-2222-000000000004', '55555555-5555-5555-5555-555555555510', 'Regulatory Framework Assessment', '', 2),
  -- 3: 511 Hazard Identification & PPE (OSHE-101)
  ('f2222222-2222-2222-2222-000000000005', '55555555-5555-5555-5555-555555555511', 'Lesson: Hazard Identification & PPE', '', 1),
  ('f2222222-2222-2222-2222-000000000006', '55555555-5555-5555-5555-555555555511', 'Hazard Identification & PPE Assessment', '', 2),
  -- 4: 604 Context Retrieval & Agentic Workflows (AI-330)
  ('f2222222-2222-2222-2222-000000000007', '55555555-5555-5555-5555-555555555604', 'Lesson: Context Retrieval & Agentic Workflows', '', 0),
  ('f2222222-2222-2222-2222-000000000008', '55555555-5555-5555-5555-555555555604', 'Context Retrieval & Agentic Workflows Assessment', '', 1),
  -- 5: 560 Financial Statement Fundamentals (FIN-410)
  ('f2222222-2222-2222-2222-000000000009', '55555555-5555-5555-5555-555555555560', 'Lesson: Financial Statement Fundamentals', '', 1),
  ('f2222222-2222-2222-2222-000000000010', '55555555-5555-5555-5555-555555555560', 'Financial Statement Fundamentals Assessment', '', 2),
  -- 6: 561 Building Dynamic Excel Models (FIN-410)
  ('f2222222-2222-2222-2222-000000000011', '55555555-5555-5555-5555-555555555561', 'Lesson: Building Dynamic Excel Models', '', 1),
  ('f2222222-2222-2222-2222-000000000012', '55555555-5555-5555-5555-555555555561', 'Dynamic Excel Models Assessment', '', 2),
  -- 7: 562 Social Engineering & Phishing Vectors (SEC-410)
  ('f2222222-2222-2222-2222-000000000013', '55555555-5555-5555-5555-555555555562', 'Lesson: Social Engineering & Phishing Vectors', '', 1),
  ('f2222222-2222-2222-2222-000000000014', '55555555-5555-5555-5555-555555555562', 'Phishing Vectors Assessment', '', 2),
  -- 8: 563 Live Incident Response Drills (SEC-410)
  ('f2222222-2222-2222-2222-000000000015', '55555555-5555-5555-5555-555555555563', 'Lesson: Live Incident Response Drills', '', 1),
  ('f2222222-2222-2222-2222-000000000016', '55555555-5555-5555-5555-555555555563', 'Incident Response Drills Assessment', '', 2),
  -- 9: 580 Boardroom Presentation Fundamentals (LEAD-400)
  ('f2222222-2222-2222-2222-000000000017', '55555555-5555-5555-5555-555555555580', 'Lesson: Boardroom Presentation Fundamentals', '', 0),
  ('f2222222-2222-2222-2222-000000000018', '55555555-5555-5555-5555-555555555580', 'Boardroom Presentation Assessment', '', 1),
  -- 10: 581 Crisis Communication & Conflict Mediation (LEAD-400)
  ('f2222222-2222-2222-2222-000000000019', '55555555-5555-5555-5555-555555555581', 'Lesson: Crisis Communication & Conflict Mediation', '', 0),
  ('f2222222-2222-2222-2222-000000000020', '55555555-5555-5555-5555-555555555581', 'Crisis Communication Assessment', '', 1),
  -- 11: 582 Airflow Orchestration Basics (DATA-501)
  ('f2222222-2222-2222-2222-000000000021', '55555555-5555-5555-5555-555555555582', 'Lesson: Airflow Orchestration Basics', '', 0),
  ('f2222222-2222-2222-2222-000000000022', '55555555-5555-5555-5555-555555555582', 'Airflow Orchestration Assessment', '', 1),
  -- 12: 583 Kafka Streams & Schema Validation (DATA-501)
  ('f2222222-2222-2222-2222-000000000023', '55555555-5555-5555-5555-555555555583', 'Lesson: Kafka Streams & Schema Validation', '', 0),
  ('f2222222-2222-2222-2222-000000000024', '55555555-5555-5555-5555-555555555583', 'Kafka Streams Assessment', '', 1),
  -- 13: 584 Supervised Learning Foundations (AI-301)
  ('f2222222-2222-2222-2222-000000000025', '55555555-5555-5555-5555-555555555584', 'Lesson: Supervised Learning Foundations', '', 0),
  ('f2222222-2222-2222-2222-000000000026', '55555555-5555-5555-5555-555555555584', 'Supervised Learning Assessment', '', 1),
  -- 14: 585 Model Governance & Deployment (AI-301)
  ('f2222222-2222-2222-2222-000000000027', '55555555-5555-5555-5555-555555555585', 'Lesson: Model Governance & Deployment', '', 0),
  ('f2222222-2222-2222-2222-000000000028', '55555555-5555-5555-5555-555555555585', 'Model Governance Assessment', '', 1),
  -- 15: 586 Chemical Handling & SDS Documentation (SAF-204)
  ('f2222222-2222-2222-2222-000000000029', '55555555-5555-5555-5555-555555555586', 'Lesson: Chemical Handling & SDS Documentation', '', 0),
  ('f2222222-2222-2222-2222-000000000030', '55555555-5555-5555-5555-555555555586', 'Chemical Handling Assessment', '', 1),
  -- 16: 587 Industrial Hazard Mitigation Planning (SAF-204)
  ('f2222222-2222-2222-2222-000000000031', '55555555-5555-5555-5555-555555555587', 'Lesson: Industrial Hazard Mitigation Planning', '', 0),
  ('f2222222-2222-2222-2222-000000000032', '55555555-5555-5555-5555-555555555587', 'Hazard Mitigation Planning Assessment', '', 1),
  -- 17: 588 Transformer Architecture Foundations (ML-800)
  ('f2222222-2222-2222-2222-000000000033', '55555555-5555-5555-5555-555555555588', 'Lesson: Transformer Architecture Foundations', '', 0),
  ('f2222222-2222-2222-2222-000000000034', '55555555-5555-5555-5555-555555555588', 'Transformer Architecture Assessment', '', 1),
  -- 18: 589 Distributed Training Strategies (ML-800)
  ('f2222222-2222-2222-2222-000000000035', '55555555-5555-5555-5555-555555555589', 'Lesson: Distributed Training Strategies', '', 0),
  ('f2222222-2222-2222-2222-000000000036', '55555555-5555-5555-5555-555555555589', 'Distributed Training Assessment', '', 1),
  -- 19: 590 Generative Model Deployment Patterns (DL-901)
  ('f2222222-2222-2222-2222-000000000037', '55555555-5555-5555-5555-555555555590', 'Lesson: Generative Model Deployment Patterns', '', 0),
  ('f2222222-2222-2222-2222-000000000038', '55555555-5555-5555-5555-555555555590', 'Generative Model Deployment Assessment', '', 1),
  -- 20: 591 Production Monitoring for Generative Systems (DL-901)
  ('f2222222-2222-2222-2222-000000000039', '55555555-5555-5555-5555-555555555591', 'Lesson: Production Monitoring for Generative Systems', '', 0),
  ('f2222222-2222-2222-2222-000000000040', '55555555-5555-5555-5555-555555555591', 'Production Monitoring Assessment', '', 1),
  -- 21: 592 RL Fundamentals for Robotics (RL-705)
  ('f2222222-2222-2222-2222-000000000041', '55555555-5555-5555-5555-555555555592', 'Lesson: RL Fundamentals for Robotics', '', 0),
  ('f2222222-2222-2222-2222-000000000042', '55555555-5555-5555-5555-555555555592', 'RL Fundamentals Assessment', '', 1),
  -- 22: 593 Sim-to-Real Transfer (RL-705)
  ('f2222222-2222-2222-2222-000000000043', '55555555-5555-5555-5555-555555555593', 'Lesson: Sim-to-Real Transfer', '', 0),
  ('f2222222-2222-2222-2222-000000000044', '55555555-5555-5555-5555-555555555593', 'Sim-to-Real Transfer Assessment', '', 1),
  -- 23: 594 Entity Extraction & Summarization (NLP-620)
  ('f2222222-2222-2222-2222-000000000045', '55555555-5555-5555-5555-555555555594', 'Lesson: Entity Extraction & Summarization', '', 0),
  ('f2222222-2222-2222-2222-000000000046', '55555555-5555-5555-5555-555555555594', 'Entity Extraction Assessment', '', 1),
  -- 24: 595 Retrieval Systems for Enterprise NLP (NLP-620)
  ('f2222222-2222-2222-2222-000000000047', '55555555-5555-5555-5555-555555555595', 'Lesson: Retrieval Systems for Enterprise NLP', '', 0),
  ('f2222222-2222-2222-2222-000000000048', '55555555-5555-5555-5555-555555555595', 'Retrieval Systems Assessment', '', 1),
  -- 25: 596 Investor Messaging Fundamentals (COMM-102)
  ('f2222222-2222-2222-2222-000000000049', '55555555-5555-5555-5555-555555555596', 'Lesson: Investor Messaging Fundamentals', '', 0),
  ('f2222222-2222-2222-2222-000000000050', '55555555-5555-5555-5555-555555555596', 'Investor Messaging Assessment', '', 1),
  -- 26: 597 Cross-Functional Stakeholder Alignment (COMM-102)
  ('f2222222-2222-2222-2222-000000000051', '55555555-5555-5555-5555-555555555597', 'Lesson: Cross-Functional Stakeholder Alignment', '', 0),
  ('f2222222-2222-2222-2222-000000000052', '55555555-5555-5555-5555-555555555597', 'Stakeholder Alignment Assessment', '', 1),
  -- 27: 598 Zero Trust Network Design (CYBER-202)
  ('f2222222-2222-2222-2222-000000000053', '55555555-5555-5555-5555-555555555598', 'Lesson: Zero Trust Network Design', '', 0),
  ('f2222222-2222-2222-2222-000000000054', '55555555-5555-5555-5555-555555555598', 'Zero Trust Network Design Assessment', '', 1),
  -- 28: 599 Identity-Aware Proxies & Continuous Verification (CYBER-202)
  ('f2222222-2222-2222-2222-000000000055', '55555555-5555-5555-5555-555555555599', 'Lesson: Identity-Aware Proxies & Continuous Verification', '', 0),
  ('f2222222-2222-2222-2222-000000000056', '55555555-5555-5555-5555-555555555599', 'Identity-Aware Proxies Assessment', '', 1),
  -- 29: 600 Kubernetes Cluster Design (CLOUD-410)
  ('f2222222-2222-2222-2222-000000000057', '55555555-5555-5555-5555-555555555600', 'Lesson: Kubernetes Cluster Design', '', 0),
  ('f2222222-2222-2222-2222-000000000058', '55555555-5555-5555-5555-555555555600', 'Kubernetes Cluster Design Assessment', '', 1),
  -- 30: 601 Autoscaling & DevOps Pipelines (CLOUD-410)
  ('f2222222-2222-2222-2222-000000000059', '55555555-5555-5555-5555-555555555601', 'Lesson: Autoscaling & DevOps Pipelines', '', 0),
  ('f2222222-2222-2222-2222-000000000060', '55555555-5555-5555-5555-555555555601', 'Autoscaling & DevOps Assessment', '', 1),
  -- 31: 602 Multi-Agent Coordination Patterns (AI-512)
  ('f2222222-2222-2222-2222-000000000061', '55555555-5555-5555-5555-555555555602', 'Lesson: Multi-Agent Coordination Patterns', '', 0),
  ('f2222222-2222-2222-2222-000000000062', '55555555-5555-5555-5555-555555555602', 'Multi-Agent Coordination Assessment', '', 1),
  -- 32: 603 Autonomy Stack Research Methods (AI-512)
  ('f2222222-2222-2222-2222-000000000063', '55555555-5555-5555-5555-555555555603', 'Lesson: Autonomy Stack Research Methods', '', 0),
  ('f2222222-2222-2222-2222-000000000064', '55555555-5555-5555-5555-555555555603', 'Autonomy Stack Research Assessment', '', 1),
  -- 33: 564 Cash Flow Forecasting Basics (FIN-420)
  ('f2222222-2222-2222-2222-000000000065', '55555555-5555-5555-5555-555555555564', 'Lesson: Cash Flow Forecasting Basics', '', 0),
  ('f2222222-2222-2222-2222-000000000066', '55555555-5555-5555-5555-555555555564', 'Cash Flow Forecasting Assessment', '', 1),
  -- 34: 565 Treasury Dashboard Automation (FIN-420)
  ('f2222222-2222-2222-2222-000000000067', '55555555-5555-5555-5555-555555555565', 'Lesson: Treasury Dashboard Automation', '', 0),
  ('f2222222-2222-2222-2222-000000000068', '55555555-5555-5555-5555-555555555565', 'Treasury Dashboard Assessment', '', 1),
  -- 35: 566 Product Discovery Frameworks (PROD-310)
  ('f2222222-2222-2222-2222-000000000069', '55555555-5555-5555-5555-555555555566', 'Lesson: Product Discovery Frameworks', '', 0),
  ('f2222222-2222-2222-2222-000000000070', '55555555-5555-5555-5555-555555555566', 'Product Discovery Assessment', '', 1),
  -- 36: 567 Roadmap Prioritization & Stakeholder Alignment (PROD-310)
  ('f2222222-2222-2222-2222-000000000071', '55555555-5555-5555-5555-555555555567', 'Lesson: Roadmap Prioritization & Stakeholder Alignment', '', 0),
  ('f2222222-2222-2222-2222-000000000072', '55555555-5555-5555-5555-555555555567', 'Roadmap Prioritization Assessment', '', 1),
  -- 37: 568 Usability Testing Fundamentals (UX-215)
  ('f2222222-2222-2222-2222-000000000073', '55555555-5555-5555-5555-555555555568', 'Lesson: Usability Testing Fundamentals', '', 0),
  ('f2222222-2222-2222-2222-000000000074', '55555555-5555-5555-5555-555555555568', 'Usability Testing Assessment', '', 1),
  -- 38: 569 Synthesizing Qualitative Research (UX-215)
  ('f2222222-2222-2222-2222-000000000075', '55555555-5555-5555-5555-555555555569', 'Lesson: Synthesizing Qualitative Research', '', 0),
  ('f2222222-2222-2222-2222-000000000076', '55555555-5555-5555-5555-555555555569', 'Qualitative Research Assessment', '', 1),
  -- 39: 570 Demand Forecasting Models (SC-330)
  ('f2222222-2222-2222-2222-000000000077', '55555555-5555-5555-5555-555555555570', 'Lesson: Demand Forecasting Models', '', 0),
  ('f2222222-2222-2222-2222-000000000078', '55555555-5555-5555-5555-555555555570', 'Demand Forecasting Assessment', '', 1),
  -- 40: 571 Inventory & Supplier Risk Analytics (SC-330)
  ('f2222222-2222-2222-2222-000000000079', '55555555-5555-5555-5555-555555555571', 'Lesson: Inventory & Supplier Risk Analytics', '', 0),
  ('f2222222-2222-2222-2222-000000000080', '55555555-5555-5555-5555-555555555571', 'Supplier Risk Analytics Assessment', '', 1),
  -- 41: 572 Incident Response Playbooks (CYBER-330)
  ('f2222222-2222-2222-2222-000000000081', '55555555-5555-5555-5555-555555555572', 'Lesson: Incident Response Playbooks', '', 0),
  ('f2222222-2222-2222-2222-000000000082', '55555555-5555-5555-5555-555555555572', 'Incident Response Playbook Assessment', '', 1),
  -- 42: 573 Digital Forensics & Chain of Custody (CYBER-330)
  ('f2222222-2222-2222-2222-000000000083', '55555555-5555-5555-5555-555555555573', 'Lesson: Digital Forensics & Chain of Custody', '', 0),
  ('f2222222-2222-2222-2222-000000000084', '55555555-5555-5555-5555-555555555573', 'Digital Forensics Assessment', '', 1),
  -- 43: 574 Multi-Cloud Landing Zone Design (CLOUD-505)
  ('f2222222-2222-2222-2222-000000000085', '55555555-5555-5555-5555-555555555574', 'Lesson: Multi-Cloud Landing Zone Design', '', 0),
  ('f2222222-2222-2222-2222-000000000086', '55555555-5555-5555-5555-555555555574', 'Landing Zone Design Assessment', '', 1),
  -- 44: 575 FinOps Cost Governance (CLOUD-505)
  ('f2222222-2222-2222-2222-000000000087', '55555555-5555-5555-5555-555555555575', 'Lesson: FinOps Cost Governance', '', 0),
  ('f2222222-2222-2222-2222-000000000088', '55555555-5555-5555-5555-555555555575', 'FinOps Cost Governance Assessment', '', 1),
  -- 45: 540 Foundations of Retrieval-Augmented Generation (AI-410)
  ('f2222222-2222-2222-2222-000000000089', '55555555-5555-5555-5555-555555555540', 'Lesson: RAG Foundations Deep Dive', '', 2),
  ('f2222222-2222-2222-2222-000000000090', '55555555-5555-5555-5555-555555555540', 'RAG Foundations Extra Assessment', '', 3),
  -- 46: 541 Chunking & Indexing Strategies (AI-410)
  ('f2222222-2222-2222-2222-000000000091', '55555555-5555-5555-5555-555555555541', 'Lesson: Chunking Strategy Deep Dive', '', 2),
  ('f2222222-2222-2222-2222-000000000092', '55555555-5555-5555-5555-555555555541', 'Chunking Strategies Extra Assessment', '', 3),
  -- 47: 550 Dimensional Modeling Fundamentals (DATA-610)
  ('f2222222-2222-2222-2222-000000000093', '55555555-5555-5555-5555-555555555550', 'Lesson: Dimensional Modeling Deep Dive', '', 2),
  ('f2222222-2222-2222-2222-000000000094', '55555555-5555-5555-5555-555555555550', 'Dimensional Modeling Extra Assessment', '', 3),
  -- 48: 551 dbt Transformation Layers (DATA-610)
  ('f2222222-2222-2222-2222-000000000095', '55555555-5555-5555-5555-555555555551', 'Lesson: dbt Layer Design Deep Dive', '', 2),
  ('f2222222-2222-2222-2222-000000000096', '55555555-5555-5555-5555-555555555551', 'dbt Layer Design Extra Assessment', '', 3);

-- ── Content blocks: text + link on the lesson session, assignment + file
-- on the assessment session, for each of the 48 modules above (192 rows
-- total). Every assignment carries a real description + instructions, per
-- the same shape already used by the existing PY-402/AI-330 assignments. ─

insert into content_blocks (id, session_id, block_type, block_content, block_sorting) values
  -- 1: Data Wrangling with Pandas (PY-402)
  ('f3333333-3333-3333-3333-000000000001', 'f2222222-2222-2222-2222-000000000001', 'text', '{"body": "This lesson goes deeper into pandas performance: chained indexing pitfalls, memory-efficient dtypes, and when to reach for vectorized operations instead of apply(). Work through the guided notebook before attempting the assessment below.", "delta": [{"insert": "This lesson goes deeper into pandas performance: chained indexing pitfalls, memory-efficient dtypes, and when to reach for vectorized operations instead of apply(). Work through the guided notebook before attempting the assessment below.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000002', 'f2222222-2222-2222-2222-000000000001', 'link', '{"url": "https://example.com/reading/data-wrangling-pandas", "label": "Suggested Reading: Pandas Performance Guide"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000003', 'f2222222-2222-2222-2222-000000000002', 'assignment', '{"title": "Data Cleaning Challenge", "description": "Clean and validate a messy enterprise sales export, handling missing values, inconsistent types, and duplicate rows.", "instructions": "Submit your cleaning script plus a short write-up (200-300 words) explaining each transformation decision.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000004', 'f2222222-2222-2222-2222-000000000002', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sales_export_raw.csv", "name": "sales_export_raw.csv"}'::jsonb, 3),
  -- 2: Regulatory Framework (OSHE-101)
  ('f3333333-3333-3333-3333-000000000005', 'f2222222-2222-2222-2222-000000000003', 'text', '{"body": "This lesson unpacks the 29 CFR 1910 regulatory framework that underlies every OSHE compliance decision on the floor, including how federal standards cascade into site-level policy. Pay close attention to how citation categories map to required corrective timelines.", "delta": [{"insert": "This lesson unpacks the 29 CFR 1910 regulatory framework that underlies every OSHE compliance decision on the floor, including how federal standards cascade into site-level policy. Pay close attention to how citation categories map to required corrective timelines.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000006', 'f2222222-2222-2222-2222-000000000003', 'link', '{"url": "https://example.com/reading/regulatory-framework", "label": "Suggested Reading: OSHA Regulatory Framework Overview"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000007', 'f2222222-2222-2222-2222-000000000004', 'assignment', '{"title": "Regulatory Framework Case Study", "description": "Review a simulated OSHA citation report and identify which regulatory standard was violated and the required corrective action.", "instructions": "Submit a one-page memo citing the specific CFR section and your recommended remediation timeline.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000008', 'f2222222-2222-2222-2222-000000000004', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/osha_1910_summary.pdf", "name": "osha_1910_summary.pdf"}'::jsonb, 3),
  -- 3: Hazard Identification & PPE (OSHE-101)
  ('f3333333-3333-3333-3333-000000000009', 'f2222222-2222-2222-2222-000000000005', 'text', '{"body": "This lesson covers systematic hazard identification walkthroughs and matching each hazard class to the correct PPE tier, from safety glasses to full Level B suits. You will practice reading a job hazard analysis (JHA) form end to end.", "delta": [{"insert": "This lesson covers systematic hazard identification walkthroughs and matching each hazard class to the correct PPE tier, from safety glasses to full Level B suits. You will practice reading a job hazard analysis (JHA) form end to end.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000010', 'f2222222-2222-2222-2222-000000000005', 'link', '{"url": "https://example.com/reading/hazard-identification-ppe", "label": "Suggested Reading: PPE Selection Guide"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000011', 'f2222222-2222-2222-2222-000000000006', 'assignment', '{"title": "PPE Selection Assignment", "description": "Given a job hazard analysis for a chemical decanting task, select and justify the correct PPE tier.", "instructions": "Submit your completed JHA form with PPE selections and a short justification for each item.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000012', 'f2222222-2222-2222-2222-000000000006', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/ppe_selection_worksheet.pdf", "name": "ppe_selection_worksheet.pdf"}'::jsonb, 3),
  -- 4: Context Retrieval & Agentic Workflows (AI-330)
  ('f3333333-3333-3333-3333-000000000013', 'f2222222-2222-2222-2222-000000000007', 'text', '{"body": "This lesson covers how retrieval steps feed context into multi-step agent loops, including when to re-retrieve mid-conversation versus caching the initial context window. We will also look at simple tool-calling patterns for agentic workflows.", "delta": [{"insert": "This lesson covers how retrieval steps feed context into multi-step agent loops, including when to re-retrieve mid-conversation versus caching the initial context window. We will also look at simple tool-calling patterns for agentic workflows.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000014', 'f2222222-2222-2222-2222-000000000007', 'link', '{"url": "https://example.com/reading/context-retrieval-agentic-workflows", "label": "Suggested Reading: Designing Agentic Retrieval Loops"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000015', 'f2222222-2222-2222-2222-000000000008', 'assignment', '{"title": "Agentic Workflow Design Brief", "description": "Design a two-step agent workflow that retrieves context, calls a tool, and synthesizes a final answer.", "instructions": "Submit a design document (diagram + 300 words) describing your retrieval and tool-calling sequence.", "dueDate": "2025-12-20T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000016', 'f2222222-2222-2222-2222-000000000008', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/agentic_workflow_template.docx", "name": "agentic_workflow_template.docx"}'::jsonb, 3),
  -- 5: Financial Statement Fundamentals (FIN-410)
  ('f3333333-3333-3333-3333-000000000017', 'f2222222-2222-2222-2222-000000000009', 'text', '{"body": "This lesson walks through how the income statement, balance sheet, and cash flow statement articulate with one another, and where analysts most often make linking errors when building models. We will trace a real revenue line through all three statements.", "delta": [{"insert": "This lesson walks through how the income statement, balance sheet, and cash flow statement articulate with one another, and where analysts most often make linking errors when building models. We will trace a real revenue line through all three statements.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000018', 'f2222222-2222-2222-2222-000000000009', 'link', '{"url": "https://example.com/reading/financial-statement-fundamentals", "label": "Suggested Reading: Reading the Three Financial Statements"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000019', 'f2222222-2222-2222-2222-000000000010', 'assignment', '{"title": "Financial Statement Analysis", "description": "Analyze a sample company''s three financial statements and identify two red flags in its working capital trend.", "instructions": "Submit a one-page analysis memo highlighting the red flags and your supporting calculations.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000020', 'f2222222-2222-2222-2222-000000000010', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_financial_statements.xlsx", "name": "sample_financial_statements.xlsx"}'::jsonb, 3),
  -- 6: Building Dynamic Excel Models (FIN-410)
  ('f3333333-3333-3333-3333-000000000021', 'f2222222-2222-2222-2222-000000000011', 'text', '{"body": "This lesson builds a driver-based Excel model from scratch, with switchable scenario assumptions and named ranges instead of hardcoded values. You will learn why hardcoding breaks auditability in enterprise FP&A models.", "delta": [{"insert": "This lesson builds a driver-based Excel model from scratch, with switchable scenario assumptions and named ranges instead of hardcoded values. You will learn why hardcoding breaks auditability in enterprise FP&A models.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000022', 'f2222222-2222-2222-2222-000000000011', 'link', '{"url": "https://example.com/reading/dynamic-excel-models", "label": "Suggested Reading: Driver-Based Modeling Best Practices"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000023', 'f2222222-2222-2222-2222-000000000012', 'assignment', '{"title": "Dynamic Model Build", "description": "Build a 3-scenario driver-based revenue forecast model using the provided assumptions template.", "instructions": "Submit your completed Excel workbook with a base/upside/downside scenario toggle.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000024', 'f2222222-2222-2222-2222-000000000012', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/revenue_model_template.xlsx", "name": "revenue_model_template.xlsx"}'::jsonb, 3),
  -- 7: Social Engineering & Phishing Vectors (SEC-410)
  ('f3333333-3333-3333-3333-000000000025', 'f2222222-2222-2222-2222-000000000013', 'text', '{"body": "This lesson breaks down the anatomy of a phishing campaign, from spoofed sender domains to urgency-based social engineering triggers, using real anonymized incident examples. You will learn to spot the subtle inconsistencies attackers rely on.", "delta": [{"insert": "This lesson breaks down the anatomy of a phishing campaign, from spoofed sender domains to urgency-based social engineering triggers, using real anonymized incident examples. You will learn to spot the subtle inconsistencies attackers rely on.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000026', 'f2222222-2222-2222-2222-000000000013', 'link', '{"url": "https://example.com/reading/social-engineering-phishing", "label": "Suggested Reading: Anatomy of a Phishing Campaign"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000027', 'f2222222-2222-2222-2222-000000000014', 'assignment', '{"title": "Phishing Simulation Report", "description": "Review a batch of five sample emails and identify which are phishing attempts, citing the specific red flags in each.", "instructions": "Submit your findings as a short report (one paragraph per email) with your confidence rating for each.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000028', 'f2222222-2222-2222-2222-000000000014', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/phishing_sample_emails.pdf", "name": "phishing_sample_emails.pdf"}'::jsonb, 3),
  -- 8: Live Incident Response Drills (SEC-410)
  ('f3333333-3333-3333-3333-000000000029', 'f2222222-2222-2222-2222-000000000015', 'text', '{"body": "This lesson runs through a structured tabletop incident response exercise, from initial detection to containment, eradication, and post-incident review. You will practice assigning the incident commander and communication lead roles.", "delta": [{"insert": "This lesson runs through a structured tabletop incident response exercise, from initial detection to containment, eradication, and post-incident review. You will practice assigning the incident commander and communication lead roles.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000030', 'f2222222-2222-2222-2222-000000000015', 'link', '{"url": "https://example.com/reading/incident-response-drills", "label": "Suggested Reading: Running a Tabletop Exercise"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000031', 'f2222222-2222-2222-2222-000000000016', 'assignment', '{"title": "Tabletop Exercise Write-Up", "description": "Participate in the simulated incident scenario and document your team''s response timeline and decisions.", "instructions": "Submit a timeline document covering detection, containment, and lessons learned.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000032', 'f2222222-2222-2222-2222-000000000016', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/tabletop_exercise_scenario.pdf", "name": "tabletop_exercise_scenario.pdf"}'::jsonb, 3),
  -- 9: Boardroom Presentation Fundamentals (LEAD-400)
  ('f3333333-3333-3333-3333-000000000033', 'f2222222-2222-2222-2222-000000000017', 'text', '{"body": "This lesson covers structuring a boardroom presentation around a single decision the board needs to make, rather than a status update, including how to front-load the recommendation. We will also cover handling pushback questions live.", "delta": [{"insert": "This lesson covers structuring a boardroom presentation around a single decision the board needs to make, rather than a status update, including how to front-load the recommendation. We will also cover handling pushback questions live.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000034', 'f2222222-2222-2222-2222-000000000017', 'link', '{"url": "https://example.com/reading/boardroom-presentation-fundamentals", "label": "Suggested Reading: Structuring a Decision-Focused Board Deck"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000035', 'f2222222-2222-2222-2222-000000000018', 'assignment', '{"title": "Boardroom Deck Critique", "description": "Review a sample 10-slide board deck and rewrite the executive summary slide to lead with the recommendation.", "instructions": "Submit your rewritten slide plus a short rationale (150 words) for your structural changes.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000036', 'f2222222-2222-2222-2222-000000000018', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_board_deck.pptx", "name": "sample_board_deck.pptx"}'::jsonb, 3),
  -- 10: Crisis Communication & Conflict Mediation (LEAD-400)
  ('f3333333-3333-3333-3333-000000000037', 'f2222222-2222-2222-2222-000000000019', 'text', '{"body": "This lesson covers the first-24-hours playbook for crisis communication, including holding statements, stakeholder sequencing, and how to mediate conflicting departmental narratives before they reach the press. Timing discipline matters as much as message content.", "delta": [{"insert": "This lesson covers the first-24-hours playbook for crisis communication, including holding statements, stakeholder sequencing, and how to mediate conflicting departmental narratives before they reach the press. Timing discipline matters as much as message content.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000038', 'f2222222-2222-2222-2222-000000000019', 'link', '{"url": "https://example.com/reading/crisis-communication-conflict-mediation", "label": "Suggested Reading: The First 24 Hours of Crisis Communication"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000039', 'f2222222-2222-2222-2222-000000000020', 'assignment', '{"title": "Crisis Response Memo", "description": "Given a simulated product recall scenario, draft the internal holding statement and stakeholder communication sequence.", "instructions": "Submit your holding statement plus a stakeholder sequencing timeline.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000040', 'f2222222-2222-2222-2222-000000000020', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/crisis_comms_playbook_template.docx", "name": "crisis_comms_playbook_template.docx"}'::jsonb, 3),
  -- 11: Airflow Orchestration Basics (DATA-501)
  ('f3333333-3333-3333-3333-000000000041', 'f2222222-2222-2222-2222-000000000021', 'text', '{"body": "This lesson covers DAG design principles in Apache Airflow, including task dependency structuring, retry policies, and avoiding the common pitfall of overly-coupled tasks. We will walk through converting a linear script into a proper DAG.", "delta": [{"insert": "This lesson covers DAG design principles in Apache Airflow, including task dependency structuring, retry policies, and avoiding the common pitfall of overly-coupled tasks. We will walk through converting a linear script into a proper DAG.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000042', 'f2222222-2222-2222-2222-000000000021', 'link', '{"url": "https://example.com/reading/airflow-orchestration-basics", "label": "Suggested Reading: Airflow DAG Design Patterns"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000043', 'f2222222-2222-2222-2222-000000000022', 'assignment', '{"title": "DAG Design Exercise", "description": "Convert the provided linear ETL script into a properly structured Airflow DAG with retry logic.", "instructions": "Submit your DAG Python file plus a short note on your task dependency choices.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000044', 'f2222222-2222-2222-2222-000000000022', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/linear_etl_script.py", "name": "linear_etl_script.py"}'::jsonb, 3),
  -- 12: Kafka Streams & Schema Validation (DATA-501)
  ('f3333333-3333-3333-3333-000000000045', 'f2222222-2222-2222-2222-000000000023', 'text', '{"body": "This lesson covers enforcing schema contracts across Kafka producers and consumers using a schema registry, and what happens downstream when a producer silently changes its schema. We will trace a real schema-drift incident.", "delta": [{"insert": "This lesson covers enforcing schema contracts across Kafka producers and consumers using a schema registry, and what happens downstream when a producer silently changes its schema. We will trace a real schema-drift incident.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000046', 'f2222222-2222-2222-2222-000000000023', 'link', '{"url": "https://example.com/reading/kafka-streams-schema-validation", "label": "Suggested Reading: Schema Registry Fundamentals"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000047', 'f2222222-2222-2222-2222-000000000024', 'assignment', '{"title": "Schema Contract Design", "description": "Design a versioned Avro schema for the provided event stream and document your backward-compatibility strategy.", "instructions": "Submit your schema file plus a short compatibility strategy note.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000048', 'f2222222-2222-2222-2222-000000000024', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_event_schema.avsc", "name": "sample_event_schema.avsc"}'::jsonb, 3),
  -- 13: Supervised Learning Foundations (AI-301)
  ('f3333333-3333-3333-3333-000000000049', 'f2222222-2222-2222-2222-000000000025', 'text', '{"body": "This lesson compares linear/logistic regression against gradient-boosted trees on the same enterprise dataset, focusing on when the added complexity of boosting is actually justified. We will also cover basic feature importance interpretation.", "delta": [{"insert": "This lesson compares linear/logistic regression against gradient-boosted trees on the same enterprise dataset, focusing on when the added complexity of boosting is actually justified. We will also cover basic feature importance interpretation.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000050', 'f2222222-2222-2222-2222-000000000025', 'link', '{"url": "https://example.com/reading/supervised-learning-foundations", "label": "Suggested Reading: When to Use Gradient Boosting"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000051', 'f2222222-2222-2222-2222-000000000026', 'assignment', '{"title": "Model Comparison Exercise", "description": "Train a logistic regression and a gradient-boosted tree model on the provided dataset and compare their performance.", "instructions": "Submit your notebook plus a short comparison write-up (200 words).", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000052', 'f2222222-2222-2222-2222-000000000026', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/enterprise_churn_dataset.csv", "name": "enterprise_churn_dataset.csv"}'::jsonb, 3),
  -- 14: Model Governance & Deployment (AI-301)
  ('f3333333-3333-3333-3333-000000000053', 'f2222222-2222-2222-2222-000000000027', 'text', '{"body": "This lesson covers model registry workflows, approval gates before production promotion, and what a minimal model card should contain for enterprise governance. We will also touch on rollback triggers for a degrading model.", "delta": [{"insert": "This lesson covers model registry workflows, approval gates before production promotion, and what a minimal model card should contain for enterprise governance. We will also touch on rollback triggers for a degrading model.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000054', 'f2222222-2222-2222-2222-000000000027', 'link', '{"url": "https://example.com/reading/model-governance-deployment", "label": "Suggested Reading: Enterprise Model Governance Basics"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000055', 'f2222222-2222-2222-2222-000000000028', 'assignment', '{"title": "Model Card Exercise", "description": "Write a model card for the classifier you trained in the previous module, covering intended use, limitations, and monitoring plan.", "instructions": "Submit your model card as a one-page document.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000056', 'f2222222-2222-2222-2222-000000000028', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/model_card_template.docx", "name": "model_card_template.docx"}'::jsonb, 3),
  -- 15: Chemical Handling & SDS Documentation (SAF-204)
  ('f3333333-3333-3333-3333-000000000057', 'f2222222-2222-2222-2222-000000000029', 'text', '{"body": "This lesson covers reading and applying Safety Data Sheets (SDS) correctly during chemical handling, including GHS pictogram interpretation and secondary container labeling requirements. We will walk through a real SDS section by section.", "delta": [{"insert": "This lesson covers reading and applying Safety Data Sheets (SDS) correctly during chemical handling, including GHS pictogram interpretation and secondary container labeling requirements. We will walk through a real SDS section by section.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000058', 'f2222222-2222-2222-2222-000000000029', 'link', '{"url": "https://example.com/reading/chemical-handling-sds", "label": "Suggested Reading: Reading a Safety Data Sheet"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000059', 'f2222222-2222-2222-2222-000000000030', 'assignment', '{"title": "SDS Interpretation Exercise", "description": "Given a sample SDS, identify the required PPE, storage conditions, and first-aid measures.", "instructions": "Submit your completed SDS interpretation worksheet.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000060', 'f2222222-2222-2222-2222-000000000030', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_sds_document.pdf", "name": "sample_sds_document.pdf"}'::jsonb, 3),
  -- 16: Industrial Hazard Mitigation Planning (SAF-204)
  ('f3333333-3333-3333-3333-000000000061', 'f2222222-2222-2222-2222-000000000031', 'text', '{"body": "This lesson walks through building a hazard mitigation plan for an industrial facility, prioritizing hazards by likelihood and severity before assigning engineering or administrative controls. We will use a simplified risk matrix.", "delta": [{"insert": "This lesson walks through building a hazard mitigation plan for an industrial facility, prioritizing hazards by likelihood and severity before assigning engineering or administrative controls. We will use a simplified risk matrix.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000062', 'f2222222-2222-2222-2222-000000000031', 'link', '{"url": "https://example.com/reading/industrial-hazard-mitigation-planning", "label": "Suggested Reading: Building a Hazard Mitigation Plan"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000063', 'f2222222-2222-2222-2222-000000000032', 'assignment', '{"title": "Hazard Mitigation Plan", "description": "Draft a mitigation plan for the three highest-priority hazards identified in the facility walkthrough scenario.", "instructions": "Submit your plan using the provided risk matrix template.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000064', 'f2222222-2222-2222-2222-000000000032', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/hazard_mitigation_plan_template.xlsx", "name": "hazard_mitigation_plan_template.xlsx"}'::jsonb, 3),
  -- 17: Transformer Architecture Foundations (ML-800)
  ('f3333333-3333-3333-3333-000000000065', 'f2222222-2222-2222-2222-000000000033', 'text', '{"body": "This lesson breaks down self-attention and positional encoding from first principles, building up to a full transformer block. We will trace how attention weights actually get computed for a short example sequence.", "delta": [{"insert": "This lesson breaks down self-attention and positional encoding from first principles, building up to a full transformer block. We will trace how attention weights actually get computed for a short example sequence.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000066', 'f2222222-2222-2222-2222-000000000033', 'link', '{"url": "https://example.com/reading/transformer-architecture-foundations", "label": "Suggested Reading: The Transformer Architecture Explained"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000067', 'f2222222-2222-2222-2222-000000000034', 'assignment', '{"title": "Attention Mechanism Exercise", "description": "Implement a simplified self-attention layer from scratch and verify its output on the provided test sequence.", "instructions": "Submit your implementation notebook plus the verification output.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000068', 'f2222222-2222-2222-2222-000000000034', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/attention_starter_notebook.ipynb", "name": "attention_starter_notebook.ipynb"}'::jsonb, 3),
  -- 18: Distributed Training Strategies (ML-800)
  ('f3333333-3333-3333-3333-000000000069', 'f2222222-2222-2222-2222-000000000035', 'text', '{"body": "This lesson covers data parallelism versus model parallelism, and when a training job actually needs multi-GPU distribution versus just a bigger single GPU. We will cover gradient synchronization overhead as the key tradeoff.", "delta": [{"insert": "This lesson covers data parallelism versus model parallelism, and when a training job actually needs multi-GPU distribution versus just a bigger single GPU. We will cover gradient synchronization overhead as the key tradeoff.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000070', 'f2222222-2222-2222-2222-000000000035', 'link', '{"url": "https://example.com/reading/distributed-training-strategies", "label": "Suggested Reading: Data vs Model Parallelism"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000071', 'f2222222-2222-2222-2222-000000000036', 'assignment', '{"title": "Distributed Training Plan", "description": "Given the provided model size and dataset, propose a distributed training strategy and justify your parallelism choice.", "instructions": "Submit a one-page proposal with your justification.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000072', 'f2222222-2222-2222-2222-000000000036', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/distributed_training_spec.pdf", "name": "distributed_training_spec.pdf"}'::jsonb, 3),
  -- 19: Generative Model Deployment Patterns (DL-901)
  ('f3333333-3333-3333-3333-000000000073', 'f2222222-2222-2222-2222-000000000037', 'text', '{"body": "This lesson covers serving patterns for generative models in production, including batching strategies, latency/throughput tradeoffs, and canary rollout for a new model version. We will compare synchronous versus streaming response patterns.", "delta": [{"insert": "This lesson covers serving patterns for generative models in production, including batching strategies, latency/throughput tradeoffs, and canary rollout for a new model version. We will compare synchronous versus streaming response patterns.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000074', 'f2222222-2222-2222-2222-000000000037', 'link', '{"url": "https://example.com/reading/generative-model-deployment-patterns", "label": "Suggested Reading: Serving Generative Models in Production"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000075', 'f2222222-2222-2222-2222-000000000038', 'assignment', '{"title": "Deployment Strategy Proposal", "description": "Propose a canary rollout plan for deploying a new generative model version with rollback triggers.", "instructions": "Submit your rollout plan as a short document (250 words).", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000076', 'f2222222-2222-2222-2222-000000000038', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/canary_rollout_template.docx", "name": "canary_rollout_template.docx"}'::jsonb, 3),
  -- 20: Production Monitoring for Generative Systems (DL-901)
  ('f3333333-3333-3333-3333-000000000077', 'f2222222-2222-2222-2222-000000000039', 'text', '{"body": "This lesson covers detecting output drift in a deployed generative system, including sampling strategies for human review and automated quality signals. We will discuss what a useful alerting threshold looks like in practice.", "delta": [{"insert": "This lesson covers detecting output drift in a deployed generative system, including sampling strategies for human review and automated quality signals. We will discuss what a useful alerting threshold looks like in practice.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000078', 'f2222222-2222-2222-2222-000000000039', 'link', '{"url": "https://example.com/reading/production-monitoring-generative-systems", "label": "Suggested Reading: Monitoring Generative Systems in Production"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000079', 'f2222222-2222-2222-2222-000000000040', 'assignment', '{"title": "Monitoring Dashboard Design", "description": "Design a monitoring dashboard spec covering the key drift and quality signals for a deployed generative system.", "instructions": "Submit your dashboard spec listing each metric and its alert threshold.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000080', 'f2222222-2222-2222-2222-000000000040', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/monitoring_dashboard_spec_template.xlsx", "name": "monitoring_dashboard_spec_template.xlsx"}'::jsonb, 3),
  -- 21: RL Fundamentals for Robotics (RL-705)
  ('f3333333-3333-3333-3333-000000000081', 'f2222222-2222-2222-2222-000000000041', 'text', '{"body": "This lesson covers reward shaping and policy gradient methods applied to a simple robotic arm task, including why naive reward functions often lead to unintended behavior. We will trace through one reward-hacking example.", "delta": [{"insert": "This lesson covers reward shaping and policy gradient methods applied to a simple robotic arm task, including why naive reward functions often lead to unintended behavior. We will trace through one reward-hacking example.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000082', 'f2222222-2222-2222-2222-000000000041', 'link', '{"url": "https://example.com/reading/rl-fundamentals-robotics", "label": "Suggested Reading: Reward Shaping Pitfalls"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000083', 'f2222222-2222-2222-2222-000000000042', 'assignment', '{"title": "Reward Function Design", "description": "Design a reward function for the provided robotic reaching task and justify how it avoids the reward-hacking pitfall discussed in class.", "instructions": "Submit your reward function code plus a short justification.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000084', 'f2222222-2222-2222-2222-000000000042', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/reaching_task_environment.py", "name": "reaching_task_environment.py"}'::jsonb, 3),
  -- 22: Sim-to-Real Transfer (RL-705)
  ('f3333333-3333-3333-3333-000000000085', 'f2222222-2222-2222-2222-000000000043', 'text', '{"body": "This lesson covers domain randomization and other techniques for closing the sim-to-real gap when transferring a trained policy to physical hardware. We will look at why naive transfer usually fails on contact-rich tasks.", "delta": [{"insert": "This lesson covers domain randomization and other techniques for closing the sim-to-real gap when transferring a trained policy to physical hardware. We will look at why naive transfer usually fails on contact-rich tasks.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000086', 'f2222222-2222-2222-2222-000000000043', 'link', '{"url": "https://example.com/reading/sim-to-real-transfer", "label": "Suggested Reading: Domain Randomization for Sim-to-Real"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000087', 'f2222222-2222-2222-2222-000000000044', 'assignment', '{"title": "Sim-to-Real Transfer Plan", "description": "Propose a domain randomization strategy for transferring the provided simulated grasping policy to a physical robot.", "instructions": "Submit your strategy as a short proposal (250 words).", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000088', 'f2222222-2222-2222-2222-000000000044', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sim_to_real_checklist.pdf", "name": "sim_to_real_checklist.pdf"}'::jsonb, 3),
  -- 23: Entity Extraction & Summarization (NLP-620)
  ('f3333333-3333-3333-3333-000000000089', 'f2222222-2222-2222-2222-000000000045', 'text', '{"body": "This lesson compares named entity recognition approaches and the tradeoffs between extractive and abstractive summarization for enterprise documents. We will evaluate both approaches on the same sample contract.", "delta": [{"insert": "This lesson compares named entity recognition approaches and the tradeoffs between extractive and abstractive summarization for enterprise documents. We will evaluate both approaches on the same sample contract.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000090', 'f2222222-2222-2222-2222-000000000045', 'link', '{"url": "https://example.com/reading/entity-extraction-summarization", "label": "Suggested Reading: Extractive vs Abstractive Summarization"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000091', 'f2222222-2222-2222-2222-000000000046', 'assignment', '{"title": "Entity Extraction Exercise", "description": "Extract key entities from the provided sample contract and produce a 3-sentence extractive summary.", "instructions": "Submit your entity list and summary as a short document.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000092', 'f2222222-2222-2222-2222-000000000046', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_contract_document.pdf", "name": "sample_contract_document.pdf"}'::jsonb, 3),
  -- 24: Retrieval Systems for Enterprise NLP (NLP-620)
  ('f3333333-3333-3333-3333-000000000093', 'f2222222-2222-2222-2222-000000000047', 'text', '{"body": "This lesson covers building a retrieval layer for enterprise search, including hybrid keyword/semantic search and re-ranking the top results before they reach a QA model. We will discuss when pure semantic search underperforms.", "delta": [{"insert": "This lesson covers building a retrieval layer for enterprise search, including hybrid keyword/semantic search and re-ranking the top results before they reach a QA model. We will discuss when pure semantic search underperforms.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000094', 'f2222222-2222-2222-2222-000000000047', 'link', '{"url": "https://example.com/reading/retrieval-systems-enterprise-nlp", "label": "Suggested Reading: Hybrid Search for Enterprise QA"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000095', 'f2222222-2222-2222-2222-000000000048', 'assignment', '{"title": "Retrieval Layer Design", "description": "Design a hybrid retrieval pipeline for the provided enterprise document set and justify your re-ranking approach.", "instructions": "Submit your design document (300 words) covering the retrieval and re-ranking steps.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000096', 'f2222222-2222-2222-2222-000000000048', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/enterprise_document_set_sample.zip", "name": "enterprise_document_set_sample.zip"}'::jsonb, 3),
  -- 25: Investor Messaging Fundamentals (COMM-102)
  ('f3333333-3333-3333-3333-000000000097', 'f2222222-2222-2222-2222-000000000049', 'text', '{"body": "This lesson covers structuring investor messaging around the three questions every investor actually asks: what changed, why it matters, and what happens next. We will rework a vague quarterly update into a tighter message.", "delta": [{"insert": "This lesson covers structuring investor messaging around the three questions every investor actually asks: what changed, why it matters, and what happens next. We will rework a vague quarterly update into a tighter message.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000098', 'f2222222-2222-2222-2222-000000000049', 'link', '{"url": "https://example.com/reading/investor-messaging-fundamentals", "label": "Suggested Reading: The Three Questions Investors Ask"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000099', 'f2222222-2222-2222-2222-000000000050', 'assignment', '{"title": "Investor Update Rewrite", "description": "Rewrite the provided vague quarterly investor update to clearly answer the three key questions.", "instructions": "Submit your rewritten update (under 400 words).", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000100', 'f2222222-2222-2222-2222-000000000050', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_investor_update_draft.docx", "name": "sample_investor_update_draft.docx"}'::jsonb, 3),
  -- 26: Cross-Functional Stakeholder Alignment (COMM-102)
  ('f3333333-3333-3333-3333-000000000101', 'f2222222-2222-2222-2222-000000000051', 'text', '{"body": "This lesson covers building a shared narrative across stakeholders with conflicting priorities, including how to run a pre-alignment session before the actual decision meeting. We will cover spotting silent disagreement early.", "delta": [{"insert": "This lesson covers building a shared narrative across stakeholders with conflicting priorities, including how to run a pre-alignment session before the actual decision meeting. We will cover spotting silent disagreement early.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000102', 'f2222222-2222-2222-2222-000000000051', 'link', '{"url": "https://example.com/reading/cross-functional-stakeholder-alignment", "label": "Suggested Reading: Running a Stakeholder Pre-Alignment Session"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000103', 'f2222222-2222-2222-2222-000000000052', 'assignment', '{"title": "Stakeholder Alignment Plan", "description": "Draft a pre-alignment session agenda for the provided cross-functional scenario with conflicting priorities.", "instructions": "Submit your agenda plus a short note on how you would surface silent disagreement.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000104', 'f2222222-2222-2222-2222-000000000052', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/stakeholder_alignment_agenda_template.docx", "name": "stakeholder_alignment_agenda_template.docx"}'::jsonb, 3),
  -- 27: Zero Trust Network Design (CYBER-202)
  ('f3333333-3333-3333-3333-000000000105', 'f2222222-2222-2222-2222-000000000053', 'text', '{"body": "This lesson covers micro-segmentation and least-privilege network design principles, including how to scope a segment boundary around a workload rather than a whole subnet. We will walk through a before/after network diagram.", "delta": [{"insert": "This lesson covers micro-segmentation and least-privilege network design principles, including how to scope a segment boundary around a workload rather than a whole subnet. We will walk through a before/after network diagram.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000106', 'f2222222-2222-2222-2222-000000000053', 'link', '{"url": "https://example.com/reading/zero-trust-network-design", "label": "Suggested Reading: Micro-Segmentation Design Principles"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000107', 'f2222222-2222-2222-2222-000000000054', 'assignment', '{"title": "Network Segmentation Exercise", "description": "Redesign the provided flat network diagram into a segmented zero-trust topology.", "instructions": "Submit your redesigned network diagram plus a short rationale for each segment boundary.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000108', 'f2222222-2222-2222-2222-000000000054', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/flat_network_diagram.pdf", "name": "flat_network_diagram.pdf"}'::jsonb, 3),
  -- 28: Identity-Aware Proxies & Continuous Verification (CYBER-202)
  ('f3333333-3333-3333-3333-000000000109', 'f2222222-2222-2222-2222-000000000055', 'text', '{"body": "This lesson covers identity-aware proxies and continuous trust verification, including how session risk scores can trigger step-up authentication mid-session rather than only at login. We will compare this to traditional VPN access.", "delta": [{"insert": "This lesson covers identity-aware proxies and continuous trust verification, including how session risk scores can trigger step-up authentication mid-session rather than only at login. We will compare this to traditional VPN access.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000110', 'f2222222-2222-2222-2222-000000000055', 'link', '{"url": "https://example.com/reading/identity-aware-proxies-continuous-verification", "label": "Suggested Reading: Identity-Aware Proxy Patterns"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000111', 'f2222222-2222-2222-2222-000000000056', 'assignment', '{"title": "Access Policy Design", "description": "Design a continuous verification policy for the provided identity-aware proxy scenario, including step-up authentication triggers.", "instructions": "Submit your policy document (250 words).", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000112', 'f2222222-2222-2222-2222-000000000056', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/iap_policy_template.docx", "name": "iap_policy_template.docx"}'::jsonb, 3),
  -- 29: Kubernetes Cluster Design (CLOUD-410)
  ('f3333333-3333-3333-3333-000000000113', 'f2222222-2222-2222-2222-000000000057', 'text', '{"body": "This lesson covers cluster topology decisions, namespace boundaries, and workload isolation strategies for a multi-tenant Kubernetes cluster. We will walk through why resource quotas matter as much as network policies.", "delta": [{"insert": "This lesson covers cluster topology decisions, namespace boundaries, and workload isolation strategies for a multi-tenant Kubernetes cluster. We will walk through why resource quotas matter as much as network policies.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000114', 'f2222222-2222-2222-2222-000000000057', 'link', '{"url": "https://example.com/reading/kubernetes-cluster-design", "label": "Suggested Reading: Multi-Tenant Kubernetes Design"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000115', 'f2222222-2222-2222-2222-000000000058', 'assignment', '{"title": "Cluster Design Exercise", "description": "Design a namespace and resource-quota layout for the provided multi-tenant cluster scenario.", "instructions": "Submit your namespace design plus resource quota YAML.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000116', 'f2222222-2222-2222-2222-000000000058', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/cluster_design_scenario.pdf", "name": "cluster_design_scenario.pdf"}'::jsonb, 3),
  -- 30: Autoscaling & DevOps Pipelines (CLOUD-410)
  ('f3333333-3333-3333-3333-000000000117', 'f2222222-2222-2222-2222-000000000059', 'text', '{"body": "This lesson covers horizontal pod autoscaling configuration and wiring it into a CI/CD deployment pipeline, including how to avoid scaling thrash from overly aggressive thresholds. We will trace one bad-config incident.", "delta": [{"insert": "This lesson covers horizontal pod autoscaling configuration and wiring it into a CI/CD deployment pipeline, including how to avoid scaling thrash from overly aggressive thresholds. We will trace one bad-config incident.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000118', 'f2222222-2222-2222-2222-000000000059', 'link', '{"url": "https://example.com/reading/autoscaling-devops-pipelines", "label": "Suggested Reading: Horizontal Pod Autoscaler Tuning"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000119', 'f2222222-2222-2222-2222-000000000060', 'assignment', '{"title": "Autoscaling Configuration", "description": "Configure an HPA policy for the provided deployment and justify your scaling thresholds.", "instructions": "Submit your HPA YAML plus a short justification note.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000120', 'f2222222-2222-2222-2222-000000000060', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/hpa_config_template.yaml", "name": "hpa_config_template.yaml"}'::jsonb, 3),
  -- 31: Multi-Agent Coordination Patterns (AI-512)
  ('f3333333-3333-3333-3333-000000000121', 'f2222222-2222-2222-2222-000000000061', 'text', '{"body": "This lesson covers coordination protocols across cooperating agents, including role assignment and avoiding duplicated work when two agents can both handle the same task. We will review a simple contract-net protocol example.", "delta": [{"insert": "This lesson covers coordination protocols across cooperating agents, including role assignment and avoiding duplicated work when two agents can both handle the same task. We will review a simple contract-net protocol example.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000122', 'f2222222-2222-2222-2222-000000000061', 'link', '{"url": "https://example.com/reading/multi-agent-coordination-patterns", "label": "Suggested Reading: Multi-Agent Coordination Protocols"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000123', 'f2222222-2222-2222-2222-000000000062', 'assignment', '{"title": "Coordination Protocol Design", "description": "Design a role-assignment protocol for the provided three-agent scenario to avoid duplicated task handling.", "instructions": "Submit your protocol design as a short document (250 words).", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000124', 'f2222222-2222-2222-2222-000000000062', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/multi_agent_scenario.pdf", "name": "multi_agent_scenario.pdf"}'::jsonb, 3),
  -- 32: Autonomy Stack Research Methods (AI-512)
  ('f3333333-3333-3333-3333-000000000125', 'f2222222-2222-2222-2222-000000000063', 'text', '{"body": "This lesson covers evaluation methodology for autonomy stack research, including how to design a fair benchmark and avoid the common pitfall of overfitting to a single test scenario. We will review a published benchmark''s methodology.", "delta": [{"insert": "This lesson covers evaluation methodology for autonomy stack research, including how to design a fair benchmark and avoid the common pitfall of overfitting to a single test scenario. We will review a published benchmark''s methodology.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000126', 'f2222222-2222-2222-2222-000000000063', 'link', '{"url": "https://example.com/reading/autonomy-stack-research-methods", "label": "Suggested Reading: Benchmarking Autonomy Stacks"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000127', 'f2222222-2222-2222-2222-000000000064', 'assignment', '{"title": "Benchmark Design Exercise", "description": "Design a benchmark protocol for evaluating the provided autonomy stack across three distinct scenarios.", "instructions": "Submit your benchmark protocol document.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000128', 'f2222222-2222-2222-2222-000000000064', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/benchmark_protocol_template.docx", "name": "benchmark_protocol_template.docx"}'::jsonb, 3),
  -- 33: Cash Flow Forecasting Basics (FIN-420)
  ('f3333333-3333-3333-3333-000000000129', 'f2222222-2222-2222-2222-000000000065', 'text', '{"body": "This lesson builds a 13-week rolling cash forecast from scratch, including how to reconcile forecast against actuals each week without losing the model''s structure. We will cover the most common forecasting bias to watch for.", "delta": [{"insert": "This lesson builds a 13-week rolling cash forecast from scratch, including how to reconcile forecast against actuals each week without losing the model''s structure. We will cover the most common forecasting bias to watch for.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000130', 'f2222222-2222-2222-2222-000000000065', 'link', '{"url": "https://example.com/reading/cash-flow-forecasting-basics", "label": "Suggested Reading: Building a 13-Week Cash Forecast"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000131', 'f2222222-2222-2222-2222-000000000066', 'assignment', '{"title": "Rolling Forecast Exercise", "description": "Build a 13-week rolling cash forecast using the provided transaction data and reconcile week 1 against actuals.", "instructions": "Submit your completed forecast workbook.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000132', 'f2222222-2222-2222-2222-000000000066', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/cash_forecast_template.xlsx", "name": "cash_forecast_template.xlsx"}'::jsonb, 3),
  -- 34: Treasury Dashboard Automation (FIN-420)
  ('f3333333-3333-3333-3333-000000000133', 'f2222222-2222-2222-2222-000000000067', 'text', '{"body": "This lesson covers connecting live bank feed and ERP data into an automated treasury dashboard, including how to handle a feed outage gracefully instead of showing stale numbers as current. We will walk through a fallback pattern.", "delta": [{"insert": "This lesson covers connecting live bank feed and ERP data into an automated treasury dashboard, including how to handle a feed outage gracefully instead of showing stale numbers as current. We will walk through a fallback pattern.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000134', 'f2222222-2222-2222-2222-000000000067', 'link', '{"url": "https://example.com/reading/treasury-dashboard-automation", "label": "Suggested Reading: Automating Treasury Reporting"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000135', 'f2222222-2222-2222-2222-000000000068', 'assignment', '{"title": "Dashboard Automation Plan", "description": "Propose a data pipeline design connecting the provided bank feed and ERP sources into a single treasury dashboard.", "instructions": "Submit your pipeline design document (250 words).", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000136', 'f2222222-2222-2222-2222-000000000068', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/treasury_dashboard_spec.pdf", "name": "treasury_dashboard_spec.pdf"}'::jsonb, 3),
  -- 35: Product Discovery Frameworks (PROD-310)
  ('f3333333-3333-3333-3333-000000000137', 'f2222222-2222-2222-2222-000000000069', 'text', '{"body": "This lesson covers structuring customer discovery interviews to avoid leading questions, and sizing an opportunity before committing engineering time. We will critique a real interview transcript for leading-question mistakes.", "delta": [{"insert": "This lesson covers structuring customer discovery interviews to avoid leading questions, and sizing an opportunity before committing engineering time. We will critique a real interview transcript for leading-question mistakes.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000138', 'f2222222-2222-2222-2222-000000000069', 'link', '{"url": "https://example.com/reading/product-discovery-frameworks", "label": "Suggested Reading: Avoiding Leading Questions in Discovery"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000139', 'f2222222-2222-2222-2222-000000000070', 'assignment', '{"title": "Discovery Interview Critique", "description": "Review the provided interview transcript, flag leading questions, and rewrite them as neutral prompts.", "instructions": "Submit your annotated transcript with rewritten questions.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000140', 'f2222222-2222-2222-2222-000000000070', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_discovery_interview_transcript.pdf", "name": "sample_discovery_interview_transcript.pdf"}'::jsonb, 3),
  -- 36: Roadmap Prioritization & Stakeholder Alignment (PROD-310)
  ('f3333333-3333-3333-3333-000000000141', 'f2222222-2222-2222-2222-000000000071', 'text', '{"body": "This lesson covers RICE scoring for backlog prioritization and running a roadmap review that actually resolves disagreement instead of just presenting a list. We will walk through scoring three competing feature requests.", "delta": [{"insert": "This lesson covers RICE scoring for backlog prioritization and running a roadmap review that actually resolves disagreement instead of just presenting a list. We will walk through scoring three competing feature requests.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000142', 'f2222222-2222-2222-2222-000000000071', 'link', '{"url": "https://example.com/reading/roadmap-prioritization-stakeholder-alignment", "label": "Suggested Reading: RICE Scoring for Product Prioritization"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000143', 'f2222222-2222-2222-2222-000000000072', 'assignment', '{"title": "RICE Scoring Exercise", "description": "Score the three provided feature requests using the RICE framework and justify your final prioritization order.", "instructions": "Submit your RICE scoring sheet plus a short justification.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000144', 'f2222222-2222-2222-2222-000000000072', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/rice_scoring_template.xlsx", "name": "rice_scoring_template.xlsx"}'::jsonb, 3),
  -- 37: Usability Testing Fundamentals (UX-215)
  ('f3333333-3333-3333-3333-000000000145', 'f2222222-2222-2222-2222-000000000073', 'text', '{"body": "This lesson covers writing a usability test script and moderating a session without leading the participant toward the answer you expect. We will review a moderation transcript and flag where the moderator over-helped.", "delta": [{"insert": "This lesson covers writing a usability test script and moderating a session without leading the participant toward the answer you expect. We will review a moderation transcript and flag where the moderator over-helped.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000146', 'f2222222-2222-2222-2222-000000000073', 'link', '{"url": "https://example.com/reading/usability-testing-fundamentals", "label": "Suggested Reading: Moderating Without Leading"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000147', 'f2222222-2222-2222-2222-000000000074', 'assignment', '{"title": "Test Script & Moderation Plan", "description": "Write a usability test script for the provided prototype and a moderation plan that avoids leading the participant.", "instructions": "Submit your test script plus your moderation notes.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000148', 'f2222222-2222-2222-2222-000000000074', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/usability_test_script_template.docx", "name": "usability_test_script_template.docx"}'::jsonb, 3),
  -- 38: Synthesizing Qualitative Research (UX-215)
  ('f3333333-3333-3333-3333-000000000149', 'f2222222-2222-2222-2222-000000000075', 'text', '{"body": "This lesson covers turning raw usability session notes into clustered affinity themes, and separating a genuine pattern from a single outlier participant''s opinion. We will cluster a real set of anonymized session notes together.", "delta": [{"insert": "This lesson covers turning raw usability session notes into clustered affinity themes, and separating a genuine pattern from a single outlier participant''s opinion. We will cluster a real set of anonymized session notes together.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000150', 'f2222222-2222-2222-2222-000000000075', 'link', '{"url": "https://example.com/reading/synthesizing-qualitative-research", "label": "Suggested Reading: Affinity Mapping for UX Research"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000151', 'f2222222-2222-2222-2222-000000000076', 'assignment', '{"title": "Affinity Mapping Exercise", "description": "Cluster the provided set of raw session notes into affinity themes and summarize the top three insights.", "instructions": "Submit your affinity map plus a one-paragraph summary of each theme.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000152', 'f2222222-2222-2222-2222-000000000076', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/raw_session_notes_sample.pdf", "name": "raw_session_notes_sample.pdf"}'::jsonb, 3),
  -- 39: Demand Forecasting Models (SC-330)
  ('f3333333-3333-3333-3333-000000000153', 'f2222222-2222-2222-2222-000000000077', 'text', '{"body": "This lesson compares moving averages, exponential smoothing, and seasonal decomposition for demand forecasting, and when each model breaks down on a real seasonal SKU. We will fit all three on the same sample dataset.", "delta": [{"insert": "This lesson compares moving averages, exponential smoothing, and seasonal decomposition for demand forecasting, and when each model breaks down on a real seasonal SKU. We will fit all three on the same sample dataset.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000154', 'f2222222-2222-2222-2222-000000000077', 'link', '{"url": "https://example.com/reading/demand-forecasting-models", "label": "Suggested Reading: Choosing a Demand Forecasting Method"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000155', 'f2222222-2222-2222-2222-000000000078', 'assignment', '{"title": "Forecasting Model Comparison", "description": "Fit the three forecasting methods covered in class to the provided SKU sales history and compare their accuracy.", "instructions": "Submit your forecast comparison notebook plus a short write-up.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000156', 'f2222222-2222-2222-2222-000000000078', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sku_sales_history.csv", "name": "sku_sales_history.csv"}'::jsonb, 3),
  -- 40: Inventory & Supplier Risk Analytics (SC-330)
  ('f3333333-3333-3333-3333-000000000157', 'f2222222-2222-2222-2222-000000000079', 'text', '{"body": "This lesson covers setting safety stock levels and scoring supplier risk across lead time variability and on-time delivery reliability. We will build a simple weighted risk score for three sample suppliers.", "delta": [{"insert": "This lesson covers setting safety stock levels and scoring supplier risk across lead time variability and on-time delivery reliability. We will build a simple weighted risk score for three sample suppliers.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000158', 'f2222222-2222-2222-2222-000000000079', 'link', '{"url": "https://example.com/reading/inventory-supplier-risk-analytics", "label": "Suggested Reading: Supplier Risk Scoring Models"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000159', 'f2222222-2222-2222-2222-000000000080', 'assignment', '{"title": "Supplier Risk Scoring Exercise", "description": "Score the three provided suppliers using the weighted risk framework and recommend a safety stock adjustment for the highest-risk one.", "instructions": "Submit your scoring worksheet plus a short recommendation.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000160', 'f2222222-2222-2222-2222-000000000080', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/supplier_risk_data.xlsx", "name": "supplier_risk_data.xlsx"}'::jsonb, 3),
  -- 41: Incident Response Playbooks (CYBER-330)
  ('f3333333-3333-3333-3333-000000000161', 'f2222222-2222-2222-2222-000000000081', 'text', '{"body": "This lesson covers structuring an incident response playbook section by section, from detection triggers through containment steps to post-incident review. We will critique a real anonymized playbook for missing sections.", "delta": [{"insert": "This lesson covers structuring an incident response playbook section by section, from detection triggers through containment steps to post-incident review. We will critique a real anonymized playbook for missing sections.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000162', 'f2222222-2222-2222-2222-000000000081', 'link', '{"url": "https://example.com/reading/incident-response-playbooks", "label": "Suggested Reading: Structuring an Incident Response Playbook"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000163', 'f2222222-2222-2222-2222-000000000082', 'assignment', '{"title": "Playbook Gap Analysis", "description": "Review the provided incident response playbook and identify which required sections are missing or incomplete.", "instructions": "Submit your gap analysis plus a proposed fix for each missing section.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000164', 'f2222222-2222-2222-2222-000000000082', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_incident_response_playbook.pdf", "name": "sample_incident_response_playbook.pdf"}'::jsonb, 3),
  -- 42: Digital Forensics & Chain of Custody (CYBER-330)
  ('f3333333-3333-3333-3333-000000000165', 'f2222222-2222-2222-2222-000000000083', 'text', '{"body": "This lesson covers evidence collection procedures and maintaining an unbroken chain of custody, including what breaks admissibility in a forensic investigation. We will walk through a sample chain-of-custody log for errors.", "delta": [{"insert": "This lesson covers evidence collection procedures and maintaining an unbroken chain of custody, including what breaks admissibility in a forensic investigation. We will walk through a sample chain-of-custody log for errors.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000166', 'f2222222-2222-2222-2222-000000000083', 'link', '{"url": "https://example.com/reading/digital-forensics-chain-of-custody", "label": "Suggested Reading: Chain of Custody Fundamentals"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000167', 'f2222222-2222-2222-2222-000000000084', 'assignment', '{"title": "Chain of Custody Review", "description": "Review the provided chain-of-custody log and identify the point where the chain was broken.", "instructions": "Submit your findings plus a corrected version of the log.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000168', 'f2222222-2222-2222-2222-000000000084', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/chain_of_custody_log_sample.pdf", "name": "chain_of_custody_log_sample.pdf"}'::jsonb, 3),
  -- 43: Multi-Cloud Landing Zone Design (CLOUD-505)
  ('f3333333-3333-3333-3333-000000000169', 'f2222222-2222-2222-2222-000000000085', 'text', '{"body": "This lesson covers landing zone building blocks across AWS, Azure, and GCP, and where their networking and IAM primitives diverge enough to trip up a naive multi-cloud design. We will compare their account/subscription hierarchies.", "delta": [{"insert": "This lesson covers landing zone building blocks across AWS, Azure, and GCP, and where their networking and IAM primitives diverge enough to trip up a naive multi-cloud design. We will compare their account/subscription hierarchies.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000170', 'f2222222-2222-2222-2222-000000000085', 'link', '{"url": "https://example.com/reading/multi-cloud-landing-zone-design", "label": "Suggested Reading: Multi-Cloud Landing Zone Patterns"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000171', 'f2222222-2222-2222-2222-000000000086', 'assignment', '{"title": "Landing Zone Design Exercise", "description": "Design a landing zone account hierarchy for the provided multi-cloud scenario spanning AWS and Azure.", "instructions": "Submit your account hierarchy diagram plus a short rationale.", "dueDate": "2025-12-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000172', 'f2222222-2222-2222-2222-000000000086', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/multicloud_scenario_brief.pdf", "name": "multicloud_scenario_brief.pdf"}'::jsonb, 3),
  -- 44: FinOps Cost Governance (CLOUD-505)
  ('f3333333-3333-3333-3333-000000000173', 'f2222222-2222-2222-2222-000000000087', 'text', '{"body": "This lesson covers cost allocation tagging strategy and setting up budget anomaly alerts before a runaway resource turns into a surprise invoice. We will review a real cost spike and trace it back to a missing tag.", "delta": [{"insert": "This lesson covers cost allocation tagging strategy and setting up budget anomaly alerts before a runaway resource turns into a surprise invoice. We will review a real cost spike and trace it back to a missing tag.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000174', 'f2222222-2222-2222-2222-000000000087', 'link', '{"url": "https://example.com/reading/finops-cost-governance", "label": "Suggested Reading: FinOps Tagging Strategy"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000175', 'f2222222-2222-2222-2222-000000000088', 'assignment', '{"title": "Cost Governance Plan", "description": "Propose a tagging strategy and budget alert thresholds for the provided cloud spend scenario.", "instructions": "Submit your tagging strategy plus alert threshold table.", "dueDate": "2026-01-15T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000176', 'f2222222-2222-2222-2222-000000000088', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/cloud_spend_scenario.xlsx", "name": "cloud_spend_scenario.xlsx"}'::jsonb, 3),
  -- 45: RAG Foundations deep dive (AI-410)
  ('f3333333-3333-3333-3333-000000000177', 'f2222222-2222-2222-2222-000000000089', 'text', '{"body": "This deep-dive session revisits why RAG beats fine-tuning for fast-changing knowledge, now with a worked cost comparison between re-indexing a vector store versus re-training a model on the same update cadence.", "delta": [{"insert": "This deep-dive session revisits why RAG beats fine-tuning for fast-changing knowledge, now with a worked cost comparison between re-indexing a vector store versus re-training a model on the same update cadence.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000178', 'f2222222-2222-2222-2222-000000000089', 'link', '{"url": "https://example.com/reading/rag-foundations", "label": "Suggested Reading: RAG vs Fine-Tuning Cost Comparison"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000179', 'f2222222-2222-2222-2222-000000000090', 'assignment', '{"title": "Cost Comparison Exercise", "description": "Estimate the cost of keeping a RAG system versus a fine-tuned model current for the provided weekly-update scenario.", "instructions": "Submit your cost comparison as a short spreadsheet plus a one-paragraph recommendation.", "dueDate": "2026-01-20T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000180', 'f2222222-2222-2222-2222-000000000090', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/rag_vs_finetune_cost_template.xlsx", "name": "rag_vs_finetune_cost_template.xlsx"}'::jsonb, 3),
  -- 46: Chunking Strategies deep dive (AI-410)
  ('f3333333-3333-3333-3333-000000000181', 'f2222222-2222-2222-2222-000000000091', 'text', '{"body": "This deep-dive session compares fixed-size chunking against semantic chunking on the same long technical document, and measures how each affects retrieval precision on a held-out query set.", "delta": [{"insert": "This deep-dive session compares fixed-size chunking against semantic chunking on the same long technical document, and measures how each affects retrieval precision on a held-out query set.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000182', 'f2222222-2222-2222-2222-000000000091', 'link', '{"url": "https://example.com/reading/chunking-indexing-strategies", "label": "Suggested Reading: Semantic vs Fixed-Size Chunking"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000183', 'f2222222-2222-2222-2222-000000000092', 'assignment', '{"title": "Chunking Strategy Evaluation", "description": "Chunk the provided document using both strategies and compare retrieval precision on the sample query set.", "instructions": "Submit your comparison notebook plus a short recommendation.", "dueDate": "2026-01-20T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000184', 'f2222222-2222-2222-2222-000000000092', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/long_technical_document_sample.pdf", "name": "long_technical_document_sample.pdf"}'::jsonb, 3),
  -- 47: Dimensional Modeling deep dive (DATA-610)
  ('f3333333-3333-3333-3333-000000000185', 'f2222222-2222-2222-2222-000000000093', 'text', '{"body": "This deep-dive session works through a slowly changing dimension (SCD Type 2) design for the provided customer dimension table, including how to handle a late-arriving attribute change correctly.", "delta": [{"insert": "This deep-dive session works through a slowly changing dimension (SCD Type 2) design for the provided customer dimension table, including how to handle a late-arriving attribute change correctly.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000186', 'f2222222-2222-2222-2222-000000000093', 'link', '{"url": "https://example.com/reading/dimensional-modeling-fundamentals", "label": "Suggested Reading: Slowly Changing Dimensions Explained"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000187', 'f2222222-2222-2222-2222-000000000094', 'assignment', '{"title": "SCD Design Exercise", "description": "Design an SCD Type 2 schema for the provided customer dimension and handle the late-arriving change scenario.", "instructions": "Submit your schema design plus a short explanation of your versioning approach.", "dueDate": "2026-01-20T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000188', 'f2222222-2222-2222-2222-000000000094', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/customer_dimension_sample.csv", "name": "customer_dimension_sample.csv"}'::jsonb, 3),
  -- 48: dbt Layer Design deep dive (DATA-610)
  ('f3333333-3333-3333-3333-000000000189', 'f2222222-2222-2222-2222-000000000095', 'text', '{"body": "This deep-dive session reviews a real dbt project structure end to end, critiquing where staging models leaked business logic that belonged in the intermediate layer instead.", "delta": [{"insert": "This deep-dive session reviews a real dbt project structure end to end, critiquing where staging models leaked business logic that belonged in the intermediate layer instead.\n"}]}'::jsonb, 0),
  ('f3333333-3333-3333-3333-000000000190', 'f2222222-2222-2222-2222-000000000095', 'link', '{"url": "https://example.com/reading/dbt-transformation-layers", "label": "Suggested Reading: dbt Layered Architecture Best Practices"}'::jsonb, 1),
  ('f3333333-3333-3333-3333-000000000191', 'f2222222-2222-2222-2222-000000000096', 'assignment', '{"title": "dbt Project Critique", "description": "Review the provided dbt project structure and flag any staging models that contain business logic that should live in the intermediate layer.", "instructions": "Submit your critique plus a proposed refactor for one flagged model.", "dueDate": "2026-01-20T23:59:00.000", "weightage": 20}'::jsonb, 2),
  ('f3333333-3333-3333-3333-000000000192', 'f2222222-2222-2222-2222-000000000096', 'file', '{"url": "https://phlunvjhqqjdxuivjlzu.supabase.co/storage/v1/object/public/course-content/sample/sample_dbt_project_structure.pdf", "name": "sample_dbt_project_structure.pdf"}'::jsonb, 3);

-- ── Course announcements (Faculty Portal Course Dashboard "Course
-- Announcements" card, mirrored read-only in the student Course Content
-- right sidebar) — seeded for PY-402's class so the demo isn't empty. ─────
insert into course_announcements (section_id, lecturer_id, title, body, created_at) values
  ((select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), '11111111-1111-1111-1111-111111111106', 'Office hours moved to Thursday 3 PM', 'Due to the departmental curriculum council meeting, our usual Wednesday slot is moved. Room 402 or via Zoom bridge.', now() - interval '1 day'),
  ((select id from course_sections where section_code = 'TN01-CLS-PY402-A01'), '11111111-1111-1111-1111-111111111106', 'Starter repo updated for Assignment 02', 'A patch was pushed to address the dataset schema parser warning in Python 3.11. Please run git pull before continuing.', now() - interval '8 days');
