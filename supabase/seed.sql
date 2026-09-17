-- AIEI LMS — demo seed data (v2 — full coverage). Run once, right after
-- schema.sql, in the Supabase SQL Editor. Re-usable/idempotent: truncates
-- and re-inserts every row below.
--
-- Demo identity used throughout the app (see lib/core/config/demo_identity.dart):
--   student = Alex Chen  (id 1 — students.id is now a bigint identity column)
--   lecturer = Dr. Sarah Lin (11111111-1111-1111-1111-111111111101)
--   admin = Marcus Vance (33333333-3333-3333-3333-333333333301)

truncate table
  enrollment_monthly_stats, enrollment_candidates, course_sections,
  student_certifications, student_materials, student_courses,
  lecturer_courses, module_certs, course_tags,
  module_materials, course_modules, courses,
  certifications, tags,
  lecturers, students, admins,
  departments, program_tracks, cohorts,
  lecturer_departments, specializations
restart identity cascade;

-- ── Master data (student registry dropdowns) ────────────────────────────

insert into departments (name) values
  ('Operations'), ('Business Intelligence'), ('Treasury Tech'), ('Global Risk'),
  ('Analytics Platform'), ('Supply Chain'), ('Workplace Safety'),
  ('Cloud Engineering'), ('Data Architecture');

insert into program_tracks (name) values
  ('Data Architecture Specialist'), ('AI Engineering Track'), ('Executive Operations'),
  ('Workplace Safety Track'), ('Cloud & Distributed Systems'), ('AI & Machine Learning'),
  ('Cloud & Distributed Computing'), ('Data Architecture & Analytics'),
  ('General Enterprise Track');

insert into cohorts (name) values
  ('Fall 2025 Cohort'), ('Executive Summer 2025'), ('Spring 2025 Cohort'), ('2025-Q1');

-- ── Master data (lecturer registry dropdowns) ───────────────────────────

insert into lecturer_departments (name) values
  ('Computer Science & Data'), ('Workplace Safety & EHS'), ('Data Science & AI'),
  ('Executive Leadership');

insert into specializations (name) values
  ('Distributed ETL & Python'), ('OSHA Protocol & Site Risk Analysis'),
  ('Deep Neural Architectures'), ('Org Dynamics & Crisis Management'),
  ('Distributed Cloud Governance');

-- ── People ──────────────────────────────────────────────────────────────

insert into lecturers (id, name, title, employee_id, email, department, specialization, credits_used, credits_max, status, accredited, manageable) values
  ('11111111-1111-1111-1111-111111111101', 'Dr. Sarah Lin', 'Lead Data Architect', 'EMP-7721', 'sarah.lin@aiei.edu', 'Computer Science & Data', 'Distributed ETL & Python', 12, 15, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111102', 'Prof. David Miller', 'Senior EHS Director', 'EMP-5402', 'd.miller@aiei.edu', 'Workplace Safety & EHS', 'OSHA Protocol & Site Risk Analysis', 8, 15, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111103', 'Dr. Aris Thorne', 'Head of AI & Machine Learning', 'EMP-8910', 'a.thorne@aiei.edu', 'Data Science & AI', 'Deep Neural Architectures', 15, 15, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111104', 'Elena Rostova', 'VP Leadership Development', 'EMP-3211', 'e.rostova@aiei.edu', 'Executive Leadership', 'Org Dynamics & Crisis Management', 6, 12, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111105', 'Prof. Kenneth Wu', 'Enterprise Systems Fellow', 'EMP-6129', 'k.wu@aiei.edu', 'Computer Science & Data', 'Distributed Cloud Governance', 0, 15, 'Sabbatical', false, false);

insert into students (id, name, student_id, email, department, title, program_track, cohort, gpa) overriding system value values
  (1, 'Alex Chen', 'EMP-88219', 'alex.chen@enterprise.com', 'Operations', 'Product Analyst • Operations', 'Data Architecture Specialist', 'Fall 2025 Cohort', 3.76),
  (2, 'Maya Patel', 'EMP-74102', 'maya.patel@enterprise.com', 'Business Intelligence', 'Business Intelligence Analyst • BI Group', 'AI Engineering Track', 'Fall 2025 Cohort', 3.92),
  (3, 'Marcus Reed', 'EMP-91024', 'marcus.reed@enterprise.com', 'Treasury Tech', 'Financial Systems Lead • Treasury Tech', 'Executive Operations', 'Executive Summer 2025', 2.90),
  (4, 'Elena Rostova Jr.', 'EMP-60211', 'e.rostovajr@enterprise.com', 'Global Risk', 'Compliance Engineer • Global Risk', 'Workplace Safety Track', 'Spring 2025 Cohort', 3.40),
  (5, 'David Kim', 'EMP-43890', 'david.kim@enterprise.com', 'Analytics Platform', 'Data Ops Associate • Analytics Platform', 'Cloud & Distributed Systems', 'Fall 2025 Cohort', 3.55),
  (6, 'Sophia Loren', 'EMP-55198', 's.loren@enterprise.com', 'Supply Chain', 'Logistics Analyst • Supply Chain Intelligence', 'AI & Machine Learning', 'Fall 2025 Cohort', 3.10),
  (7, 'Jordan Taylor', 'EMP-99214', 'jordan.taylor@enterprise.com', 'Workplace Safety', 'Safety Compliance Associate', 'Workplace Safety Track', 'Spring 2025 Cohort', 2.60),
  (8, 'Sarah Jenkins', 'EMP-33109', 'sarah.jenkins@enterprise.com', 'Cloud Engineering', 'Cloud Platform Engineer', 'Cloud & Distributed Computing', 'Fall 2025 Cohort', 3.70),
  (9, 'Liam Nguyen', 'EMP-66381', 'liam.nguyen@enterprise.com', 'Data Architecture', 'Data Architecture Associate', 'Data Architecture & Analytics', 'Fall 2025 Cohort', 3.30),
  (10, 'Chloe Bennett', 'EMP-44820', 'chloe.bennett@enterprise.com', 'Data Architecture', 'Junior Data Analyst', 'Data Architecture & Analytics', 'Fall 2025 Cohort', 3.35);

-- Keep the identity sequence ahead of the explicit ids inserted above, so
-- the next `insert into students (name, ...)` (no id given — e.g. Register
-- New Student) auto-assigns 11, not 1.
select setval(pg_get_serial_sequence('students', 'id'), 10, true);

insert into admins (id, name, title, email) values
  ('33333333-3333-3333-3333-333333333301', 'Marcus Vance', 'Chief Academic Administrator', 'marcus.vance@aiei.edu');

-- ── Courses (catalogue courses Alex Chen is enrolled in, codes 1-6; plus
-- additional courses used by the Faculty/Admin allocation views, 7-17) ──

insert into courses (id, course_code, course_title, course_description, category, image_url, schedule_text, capacity) values
  ('44444444-4444-4444-4444-444444444401', 'PY-402', 'Python for Enterprise Data Analysis & Automation', 'Data pipeline orchestration, API integration, and automated ETL workflows for enterprise analytics teams.', 'techData', 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaSQDBQPtWkABa_7PiXVJsRQkHv4xgrG3XiijLhyOTArutGaZK0X05nOVBtjVuJfyRPlFsX9CH0dAMh-kx6LJBba5UjVvkgHx5DOI9Jq8mn98t5FTMg3L8kc9RCcKIG7CvAj6jJG6F1WcCNuMwb1VZ8bFd3wBHxt2crG1xV0Yn7d8UFxNqLPsaE7O7-5zfbPXeU7V1GlQc8GTHdFWmJWqy8fK7RQkfMAqZPyOXl0HpxOWd1hm7qGgiA', 'Mon / Wed 18:00–20:30 UTC', 50),
  ('44444444-4444-4444-4444-444444444402', 'OSHE-101', 'OSHE Workplace Safety & Compliance 2025', 'Comprehensive occupational health and hazardous-material incident management, site command protocol, and emergency mitigation.', 'compliance', 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2OyYsvS_sX1hJ5qFZkMotA7KvbsvzTYWCF8WfETZtN0WSlfNQVhkrHsE2TUvzXjLriYi6LpI1QlVqk-bwOrvw91ojbYoLwM_Zr1ruloQ8yjzkvpR7-HcehL4qrnDrVs_4iMRN5WxJy9eG3JC6tjt3dVRM0B2lNuBugzLz-hsSE78-Mtrn1GPEA4LaZQxrCS24MIdweDmd2qWKW32UpGdY9ti9Vl7Dt6P7vfqp7Sdl2_U4kIgeIc1PhQ', 'Mon/Wed 11:00–12:30 UTC', 56),
  ('44444444-4444-4444-4444-444444444403', 'AI-330', 'ChatGPT & Generative AI Prompt Engineering', 'LLM prompt chains, context retrieval architectures, and agentic workflows for enterprise use cases.', 'aiTools', 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4mqWaPlwERSIsIsGlYTZJKCU-zBC91ZVEnzlYmMkcczWZma3JM6Xd_Bxldqi1F87AM_47pV1nWrNbB8_vSI4EgHd-tc9HZTk6oa-8f_DZaUcTrY0U4_TjYRMT3wj1UfvWbLv9Nqo1l7eMPy0V9-fXJakk4e2YAd6AmDfbAMjOTkGMm2YK-zWpw8XIKcFMOPC2lGhe2TLfHCk_j_677br9FSzmugZx2bQc1dk61ey-EtLnrgvHPojdLw', 'Self-paced', 60),
  ('44444444-4444-4444-4444-444444444404', 'FIN-410', 'Advanced Financial Modeling in Microsoft Excel', 'Forecasting methodologies, capital expenditure modeling, and budget variance analysis for FP&A teams.', 'techData', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAR1qa-PQ_EQITTA9fg1r6hu8Tvtdvs1ekcbF5AZPoioMdMTY50_5YruGcysD0SJ6-8HZaOLG_Qi1RpOlkHkhFcFym36_cBZbIzw4jDEtFbKK7ESumokNXWXZQa9jPJ2O4ZxIX8U6iLHNgQlhgiLKciKZmlz6PPi5p7ZCw7-f3gXnx9lREsaOhXDu8f5Q4C42QheRdnHGkL1PjQ_kaMlv2_fAxXfViXwLZTcxB1OlLDwfONXI1h56Jmag', 'Self-paced', 45),
  ('44444444-4444-4444-4444-444444444405', 'SEC-410', 'Corporate Cybersecurity & Phishing Defense', 'Phishing vectors, social engineering prevention, and live incident-response drills.', 'compliance', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXYkMiYXMEX1qK60nUL9gN1pOR3niSrz2k0TccpqxYLosexsrNqafST6KNh4sd_FbxmX-hH9xnHXbRHt13RwK13JgerDi7uZodQ2pDceEI7qvo_-wfHo8dt9ziLjMaEqyFqDr5fKmWhqtY_6q0VBYW0l9fHm_k4wGuXId41QByjT4bpKuozhC1gCtNDrGxyK-cVfV2b8RrGZDXA6ClJmu73mcMOwNQSF_OxxRkT6Lq8q4OOYKGNJkLKg', 'Self-paced', 500),
  ('44444444-4444-4444-4444-444444444406', 'LEAD-400', 'Effective Executive Communication & Stakeholder Alignment', 'High-stakes boardroom presentation, cross-functional influence, investor messaging, and conflict mediation.', 'productivity', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAcMjKgfoHEa8G_VzTvz5W-lpWL88zl5gWlksr1wM5y1Xty2v2vyzFbfxeqrX4zS0yP5kTUyqnf8-SakPJEFx-Kzlrnm-6JxqKczG3nftxgNbS2pjH7BNOSUt0j7QnD8hzJE_KcL2EXk87-27cu8uHdG1igavFS1cWXoTyByUiEHo8KL9bipIN0eO8qitDVg30oxij7-vnE9uEDXLEdnUbJU07Uvz2EBfaV3x7C4mGS2oySo_Ai59eOyQ', 'Tuesday 18:00–21:00 UTC', 28),
  ('44444444-4444-4444-4444-444444444407', 'DATA-501', 'Automated ETL & Enterprise Data Pipelines', 'Airflow orchestration, real-time Kafka event streams, schema validation, and SQL warehouse data transformations.', 'techData', null, 'Tue / Thu 13:00–14:45 UTC', 45),
  ('44444444-4444-4444-4444-444444444408', 'AI-301', 'Applied Machine Learning in Enterprise', 'Supervised models, gradient boosted trees, scikit-learn optimization, and enterprise model governance.', 'aiTools', null, 'Lab Fridays 14:00–17:00 UTC', 35),
  ('44444444-4444-4444-4444-444444444409', 'SAF-204', 'Industrial Hazard Mitigation', 'Chemical handling, SDS documentation, and industrial hazard mitigation for EHS specialists.', 'compliance', null, 'Thursday 14:00–17:30 UTC', 34),
  ('44444444-4444-4444-4444-444444444410', 'ML-800', 'Deep Neural Architectures', 'Graduate-level deep learning architectures, transformer models, and distributed training.', 'aiTools', null, 'Monday 14:00–18:00 UTC', 50),
  ('44444444-4444-4444-4444-444444444411', 'DL-901', 'Generative Enterprise Systems', 'Doctoral seminar on generative model deployment in enterprise production systems.', 'aiTools', null, 'Wednesday 14:00–18:00 UTC', 45),
  ('44444444-4444-4444-4444-444444444412', 'RL-705', 'Reinforcement Learning in Robotics', 'Advanced lab on reinforcement learning applied to robotics and autonomous systems.', 'aiTools', null, 'Friday 08:30–12:30 UTC', 30),
  ('44444444-4444-4444-4444-444444444413', 'NLP-620', 'Applied NLP Systems', 'Enterprise natural-language processing systems: entity extraction, summarization, and retrieval.', 'aiTools', null, 'Self-paced', 30),
  ('44444444-4444-4444-4444-444444444414', 'COMM-102', 'Strategic Corporate Communication', 'Investor messaging, crisis communications, and cross-functional stakeholder alignment.', 'productivity', null, 'Thursday 16:00–19:00 UTC', 40),
  ('44444444-4444-4444-4444-444444444415', 'CYBER-202', 'Zero Trust Architecture', 'Zero-trust network design, identity-aware proxies, and continuous verification models.', 'compliance', null, 'TBD', 34),
  ('44444444-4444-4444-4444-444444444416', 'CLOUD-410', 'Kubernetes Infrastructure', 'Production Kubernetes cluster design, autoscaling, and DevOps deployment pipelines.', 'techData', null, 'TBD', 50),
  ('44444444-4444-4444-4444-444444444417', 'AI-512', 'Multi-Agent Autonomy Lab', 'Multi-agent coordination, autonomy stacks, and agentic system research.', 'aiTools', null, 'TBD', 22);

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
  ('11111111-1111-1111-1111-111111111104', '44444444-4444-4444-4444-444444444414'); -- Elena Rostova: COMM-102

-- ── Course sections (lecturer_allocation screen: assigned + unassigned) ──

insert into course_sections (course_id, section_code, role_label, term, schedule_text, lecturer_id, capacity, enrolled_count, status) values
  ('44444444-4444-4444-4444-444444444401', 'Sec A01', 'Primary Instructor', 'Fall 2025', 'MWF 09:00–10:30', '11111111-1111-1111-1111-111111111101', 50, 42, 'in_progress'),
  ('44444444-4444-4444-4444-444444444407', 'Sec B02', 'Primary Instructor', 'Fall 2025', 'TTh 13:00–14:45', '11111111-1111-1111-1111-111111111101', 45, 38, 'in_progress'),
  ('44444444-4444-4444-4444-444444444408', 'Sec C01', 'Co-Lecturer', 'Fall 2025', 'Lab Fri 14:00–17:00', '11111111-1111-1111-1111-111111111101', 35, 29, 'in_progress'),
  ('44444444-4444-4444-4444-444444444402', 'Sec A1', 'Lead Instructor', 'Fall 2025', 'Mon/Wed 11:00–12:30', '11111111-1111-1111-1111-111111111102', 56, 56, 'in_progress'),
  ('44444444-4444-4444-4444-444444444409', 'Sec H03', 'Lead Instructor', 'Fall 2025', 'Thursday 14:00–17:30', '11111111-1111-1111-1111-111111111102', 34, 34, 'in_progress'),
  ('44444444-4444-4444-4444-444444444410', 'Graduate', 'Graduate', 'Fall 2025', 'Monday 14:00–18:00', '11111111-1111-1111-1111-111111111103', 50, 50, 'in_progress'),
  ('44444444-4444-4444-4444-444444444411', 'Doctoral Seminar', 'Doctoral Seminar', 'Fall 2025', 'Wednesday 14:00–18:00', '11111111-1111-1111-1111-111111111103', 45, 45, 'in_progress'),
  ('44444444-4444-4444-4444-444444444412', 'Advanced Lab', 'Advanced Lab', 'Fall 2025', 'Friday 08:30–12:30', '11111111-1111-1111-1111-111111111103', 30, 30, 'in_progress'),
  ('44444444-4444-4444-4444-444444444406', 'Sec E1', 'Section E1', 'Fall 2025', 'Tuesday 18:00–21:00', '11111111-1111-1111-1111-111111111104', 28, 28, 'in_progress'),
  ('44444444-4444-4444-4444-444444444414', 'Sec C3', 'Section C3', 'Fall 2025', 'Thursday 16:00–19:00', '11111111-1111-1111-1111-111111111104', 40, 40, 'in_progress'),
  -- Unassigned sections needing lecturer allocation:
  ('44444444-4444-4444-4444-444444444415', 'Sec 02', 'Unassigned', 'Fall 2025', 'TBD', null, 34, 34, 'scheduled'),
  ('44444444-4444-4444-4444-444444444416', 'Sec 01', 'Unassigned', 'Fall 2025', 'TBD', null, 50, 50, 'scheduled'),
  ('44444444-4444-4444-4444-444444444417', 'Sec 01', 'Unassigned', 'Fall 2025', 'TBD', null, 22, 22, 'scheduled');

-- ── Modules + Materials ─────────────────────────────────────────────────
-- Python course (PY-402) — full 10-lesson curriculum matching course_info_screen.dart

insert into course_modules (id, course_id, module_name, module_description, module_sorting, is_published) values
  ('55555555-5555-5555-5555-555555555501', '44444444-4444-4444-4444-444444444401', 'Foundations of Enterprise Python', 'Core syntax, environments, and enterprise tooling.', 0, true),
  ('55555555-5555-5555-5555-555555555502', '44444444-4444-4444-4444-444444444401', 'Data Wrangling with Pandas', 'DataFrames, joins, and cleaning pipelines.', 1, true),
  ('55555555-5555-5555-5555-555555555503', '44444444-4444-4444-4444-444444444401', 'Building Automated Data Pipelines', 'Scheduling, orchestration, and monitoring ETL jobs.', 2, true),
  ('55555555-5555-5555-5555-555555555504', '44444444-4444-4444-4444-444444444401', 'Enterprise Database Connectors & Async Tasks', 'Advanced topics in SQLAlchemy 2.0 async sessions, connection pooling under concurrency, and Celery asynchronous task queues.', 3, false);

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
insert into course_modules (id, course_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555510', '44444444-4444-4444-4444-444444444402', 'Regulatory Framework', 'OSHA / OSHE regulatory foundations.', 0),
  ('55555555-5555-5555-5555-555555555511', '44444444-4444-4444-4444-444444444402', 'Hazard Identification & PPE', 'Identifying hazards and selecting PPE.', 1),
  ('55555555-5555-5555-5555-555555555512', '44444444-4444-4444-4444-444444444402', 'Electrical & Lockout/Tagout', 'LOTO procedures and electrical safety.', 2),
  ('55555555-5555-5555-5555-555555555513', '44444444-4444-4444-4444-444444444402', 'Chemical Handling & SDS', 'Chemical handling, GHS labeling, and SDS documentation.', 3),
  ('55555555-5555-5555-5555-555555555514', '44444444-4444-4444-4444-444444444402', 'Fire Protection & Suppression', 'Fire protection systems and suppression protocol.', 4),
  ('55555555-5555-5555-5555-555555555515', '44444444-4444-4444-4444-444444444402', 'Ergonomics & Physical Safety', 'Workplace ergonomics and physical hazard mitigation.', 5),
  ('55555555-5555-5555-5555-555555555516', '44444444-4444-4444-4444-444444444402', 'Incident Response & Reporting', 'Incident containment, reporting, and regulatory notification.', 6),
  ('55555555-5555-5555-5555-555555555517', '44444444-4444-4444-4444-444444444402', 'Final Regulatory Audit Exam', 'Comprehensive 50-question regulatory audit exam.', 7);

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

-- ── Tags ────────────────────────────────────────────────────────────────

insert into tags (id, label, color_hex, icon_name) values
  ('77777777-7777-7777-7777-777777777701', 'MANDATORY', '#0F4C81', null),
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

insert into certifications (id, title, issuing_body, description, badge_icon, competencies, hash, narrative, accrediting_bodies, metrics) values
  ('88888888-8888-8888-8888-888888888801', 'Python Automation Specialist', 'AIEI Enterprise Learning', 'Data pipeline orchestration, API integration, and automated ETL workflows.', 'military_tech', array['Advanced NumPy & Pandas', 'Capstone: Distributed Web Scraping'], '0x1A2B...9F3C', '', array[]::text[], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888802', 'Certified Safety Officer 2025 (CSO-2025)', 'OSHA Accredited Corporate Safety Board & Enterprise EHS Division', 'Comprehensive occupational health and hazardous material incident management, site command protocol, and emergency mitigation.', 'workspace_premium', array['Hazard Identification', 'GHS Rev 8', 'Emergency Evacuation', 'SDS Compliance'], '0x7F2B...C84B (Ledger Status: REVOKED)', '', array['OSHA Accredited Corporate Safety Board', 'Enterprise EHS Division'], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888803', 'Certified Cyber Sentinel', 'SecOps Corporate Division', 'Phishing vectors, social engineering prevention, and live drill response.', 'shield', array['Zero-Day Attack Patterns', 'Final Incident Sim Due'], '0x3D9E...A712', '', array[]::text[], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888804', 'Executive Leadership Communicator', 'AIEI Executive Leadership Academy & Wharton Executive Education Partner Alliance', 'This credential certifies demonstrated exceptional executive presence, strategic narrative design, and high-impact negotiation in mission-critical corporate settings. Completion required passing four intensive boardroom simulation defenses before an executive panel, managing multi-tier crisis communications scenarios, and synthesizing complex enterprise initiatives into actionable operational roadmaps for C-suite stakeholders.', 'record_voice_over', array['Boardroom Presentations', 'Crisis Communications', 'Cross-Functional Negotiation', 'Executive Presence'], '0x94D1...71E0',
   'This credential certifies that the recipient has demonstrated exceptional executive presence, strategic narrative design, and high-impact negotiation in mission-critical corporate settings. Completion required passing four intensive boardroom simulation defenses before an executive panel, managing multi-tier crisis communications scenarios, and synthesizing complex enterprise initiatives into actionable operational roadmaps for C-suite stakeholders.',
   array['AIEI Executive Leadership Academy', 'Wharton Executive Education Partner Alliance'],
   '{"percentileLabel": "Top 5%", "scoreLabel": "Score: 98.4 / 100", "panelResultLabel": "Distinction", "panelResultSubtitle": "Unanimous Board Pass", "accreditedHoursLabel": "16.0 Hours", "accreditedHoursSubtitle": "Accredited Units"}'::jsonb),
  ('88888888-8888-8888-8888-888888888805', 'Enterprise AI & Prompt Engineering', 'AIEI Enterprise Learning', 'LLM prompt chains, context retrieval architectures, and agentic workflows.', 'smart_toy', array['Context Window Design', '6 Lessons Remaining'], '0xB817...2C4D', '', array[]::text[], '{}'::jsonb),
  ('88888888-8888-8888-8888-888888888806', 'FP&A Certified Financial Analyst', 'AIEI Enterprise Learning', 'Forecasting methodologies, capital expenditure modeling, and budget variance.', 'analytics', array['P&L Mechanics', '8 Lessons Locked'], '0xE203...5A19', '', array[]::text[], '{}'::jsonb);

insert into module_certs (module_id, cert_id) values
  ('55555555-5555-5555-5555-555555555503', '88888888-8888-8888-8888-888888888801'),
  ('55555555-5555-5555-5555-555555555517', '88888888-8888-8888-8888-888888888802');

-- ── Student enrollment + progress (Alex Chen — drives catalogue + badges) ──

insert into student_courses (student_id, course_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, sponsorship, last_activity_at, is_online_now) values
  (1, '44444444-4444-4444-4444-444444444401', 70, 'B+', 88.4, 96, 'on_track', 'Corporate Sponsored', now() - interval '2 hours', true),
  (1, '44444444-4444-4444-4444-444444444402', 38, 'C+', 76.0, 88, 'at_risk', 'Corporate Sponsored', now() - interval '1 day', false),
  (1, '44444444-4444-4444-4444-444444444403', 40, 'B', 82.0, 92, 'on_track', 'Corporate Sponsored', now() - interval '5 hours', false),
  (1, '44444444-4444-4444-4444-444444444404', 20, 'B-', 79.5, 90, 'on_track', 'Corporate Sponsored', now() - interval '3 days', false),
  (1, '44444444-4444-4444-4444-444444444405', 85, 'A-', 91.0, 97, 'on_track', 'Corporate Sponsored', now() - interval '2 hours', true),
  (1, '44444444-4444-4444-4444-444444444406', 100, 'A', 94.0, 100, 'on_track', 'Corporate Sponsored', now() - interval '10 days', false);

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

-- ── Faculty portal: enrollment rosters for Sarah Lin's 3 courses ─────────
-- (drives student_directory_screen.dart, course_dashboard_screen.dart, my_assigned_courses_screen.dart)

insert into student_courses (student_id, course_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, last_activity_at) values
  (2, '44444444-4444-4444-4444-444444444401', 92, 'A', 98.0, 98, 'on_track', now() - interval '18 minutes'),
  (3, '44444444-4444-4444-4444-444444444401', 45, 'D', 68.0, 60, 'critical', now() - interval '6 days'),
  (4, '44444444-4444-4444-4444-444444444401', 80, 'B+', 88.5, 90, 'on_track', now() - interval '1 day'),
  (5, '44444444-4444-4444-4444-444444444401', 70, 'A-', 91.0, 94, 'on_track', now() - interval '4 hours'),
  (6, '44444444-4444-4444-4444-444444444401', 60, 'B', 84.0, 82, 'at_risk', now() - interval '3 days');

-- ── Admin: Course Enrollment roster (SEC-410 Cybersecurity course, admin
-- view — drives course_enrollment_screen.dart; Alex Chen's own SEC-410
-- enrollment above rounds this out to a 5-student roster) ───────────────

insert into student_courses (student_id, course_id, progress_percentage, grade, overall_score, attendance_percentage, risk_status, sponsorship, last_activity_at, is_online_now) values
  (2, '44444444-4444-4444-4444-444444444405', 96, 'A+', 96.1, 98, 'on_track', 'Corporate Sponsored', now() - interval '35 minutes', true),
  (9, '44444444-4444-4444-4444-444444444405', 88, 'B+', 88.5, 91, 'on_track', 'Self-Enrolled (Direct)', now() - interval '1 day', true),
  (7, '44444444-4444-4444-4444-444444444405', 60, 'C', 73.2, 55, 'at_risk', 'Corporate Sponsored', now() - interval '4 days', false),
  (10, '44444444-4444-4444-4444-444444444405', 84, 'B+', 89.0, 93, 'on_track', 'Corporate Sponsored', now() - interval '5 hours', true);

-- ── Admin: Enrollment candidates / waitlist for PY-402 (drives
-- enroll_students_screen.dart — its capacity/enrolled figures come from
-- the PY-402 'Sec A01' course_sections row above: 42/50) ────────────────

insert into enrollment_candidates (student_name, student_employee_id, student_email, department, cohort, target_course_id, prerequisite_status, prerequisite_detail, standing_detail, sponsorship, queue_tag, needs_review) values
  ('Daniel Ross', 'EMP-61092', 'daniel.ross@enterprise.com', 'Data Architecture', 'Fall 2025 Cohort', '44444444-4444-4444-4444-444444444401', 'met', 'CS-101 Met (GPA 3.9)', 'Academic Good Standing', 'Enterprise Full', 'Staged', false),
  ('Emily Lawson', 'EMP-88231', 'emily.lawson@enterprise.com', 'AI Engineering', 'Fall 2025 Cohort', '44444444-4444-4444-4444-444444444401', 'met', 'MATH-204 Met', 'Academic Good Standing', 'Enterprise Full', 'Waitlist #1', false),
  ('Ravi Kumar', 'EMP-54910', 'ravi.kumar@enterprise.com', 'Cloud & Distributed', 'Fall 2025 Cohort', '44444444-4444-4444-4444-444444444401', 'met', 'All Prerequisites Met', 'Ready for section assign', 'Enterprise Full', null, false),
  ('Sophia Martinez', 'EMP-30491', 's.martinez@enterprise.com', 'Data Architecture', 'Fall 2025 Cohort', '44444444-4444-4444-4444-444444444401', 'met', 'Prereq PY-101 Verified', 'Academic Good Standing', 'Self-Enrolled', null, false),
  ('Jason Todd', 'EMP-77182', 'jason.todd@enterprise.com', 'Executive Operations', 'Summer 2025 Cohort', '44444444-4444-4444-4444-444444444401', 'pending', 'Prereq Waiver Required', 'Conditional dean approval', 'Enterprise Full', 'Waitlist #2', true);

-- ── Admin: enrollment monthly trend (Manage Students screen) ────────────

insert into enrollment_monthly_stats (month_label, new_enrollments, sort_order) values
  ('Oct', 48, 0), ('Nov', 64, 1), ('Dec', 82, 2), ('Jan', 96, 3), ('Feb', 110, 4), ('Mar', 132, 5);
