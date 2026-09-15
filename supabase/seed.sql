-- AIEI LMS — demo seed data. Run once, right after schema.sql, in the
-- Supabase SQL Editor. Re-usable/idempotent: safe to re-run (it wipes and
-- re-inserts the demo rows below).

truncate table
  student_materials, student_courses, lecturer_courses,
  module_certs, course_tags,
  module_materials, course_modules, courses,
  certifications, tags,
  lecturers, students, admins
restart identity cascade;

-- ── People ──────────────────────────────────────────────────────────────

insert into lecturers (id, name, title, employee_id, email, department, specialization, credits_used, credits_max, status, accredited, manageable) values
  ('11111111-1111-1111-1111-111111111101', 'Dr. Sarah Lin', 'Lead Data Architect', 'EMP-7721', 'sarah.lin@aiei.edu', 'Computer Science & Data', 'Distributed ETL & Python', 12, 15, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111102', 'Prof. David Miller', 'Senior EHS Director', 'EMP-5402', 'd.miller@aiei.edu', 'Workplace Safety & EHS', 'OSHA Protocol & Site Risk Analysis', 8, 15, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111103', 'Dr. Aris Thorne', 'Head of AI & Machine Learning', 'EMP-8910', 'a.thorne@aiei.edu', 'Data Science & AI', 'Deep Neural Architectures', 15, 15, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111104', 'Elena Rostova', 'VP Leadership Development', 'EMP-3211', 'e.rostova@aiei.edu', 'Executive Leadership', 'Org Dynamics & Crisis Management', 6, 12, 'Active', true, true),
  ('11111111-1111-1111-1111-111111111105', 'Prof. Kenneth Wu', 'Enterprise Systems Fellow', 'EMP-6129', 'k.wu@aiei.edu', 'Computer Science & Data', 'Distributed Cloud Governance', 0, 15, 'Sabbatical', false, false);

insert into students (id, name, student_id, email, department, title) values
  ('22222222-2222-2222-2222-222222222201', 'Alex Chen', 'SKL-8842-AC', 'alex.chen@enterprise.com', 'Operations', 'Product Analyst • Operations'),
  ('22222222-2222-2222-2222-222222222202', 'Priya Anand', 'SKL-8843-PA', 'priya.anand@enterprise.com', 'Finance', 'Financial Analyst • Finance'),
  ('22222222-2222-2222-2222-222222222203', 'Marcus Reed', 'SKL-8844-MR', 'marcus.reed@enterprise.com', 'Engineering', 'Software Engineer • Platform');

insert into admins (id, name, title, email) values
  ('33333333-3333-3333-3333-333333333301', 'Marcus Vance', 'Chief Academic Administrator', 'marcus.vance@aiei.edu');

-- ── Courses ─────────────────────────────────────────────────────────────

insert into courses (id, course_title, course_description, category, image_url) values
  ('44444444-4444-4444-4444-444444444401', 'Python for Enterprise Data Analysis & Automation', 'Data pipeline orchestration, API integration, and automated ETL workflows for enterprise analytics teams.', 'techData', 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaSQDBQPtWkABa_7PiXVJsRQkHv4xgrG3XiijLhyOTArutGaZK0X05nOVBtjVuJfyRPlFsX9CH0dAMh-kx6LJBba5UjVvkgHx5DOI9Jq8mn98t5FTMg3L8kc9RCcKIG7CvAj6jJG6F1WcCNuMwb1VZ8bFd3wBHxt2crG1xV0Yn7d8UFxNqLPsaE7O7-5zfbPXeU7V1GlQc8GTHdFWmJWqy8fK7RQkfMAqZPyOXl0HpxOWd1hm7qGgiA'),
  ('44444444-4444-4444-4444-444444444402', 'OSHE Workplace Safety & Compliance 2025', 'Comprehensive occupational health and hazardous-material incident management, site command protocol, and emergency mitigation.', 'compliance', 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2OyYsvS_sX1hJ5qFZkMotA7KvbsvzTYWCF8WfETZtN0WSlfNQVhkrHsE2TUvzXjLriYi6LpI1QlVqk-bwOrvw91ojbYoLwM_Zr1ruloQ8yjzkvpR7-HcehL4qrnDrVs_4iMRN5WxJy9eG3JC6tjt3dVRM0B2lNuBugzLz-hsSE78-Mtrn1GPEA4LaZQxrCS24MIdweDmd2qWKW32UpGdY9ti9Vl7Dt6P7vfqp7Sdl2_U4kIgeIc1PhQ'),
  ('44444444-4444-4444-4444-444444444403', 'ChatGPT & Generative AI Prompt Engineering', 'LLM prompt chains, context retrieval architectures, and agentic workflows for enterprise use cases.', 'aiTools', 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4mqWaPlwERSIsIsGlYTZJKCU-zBC91ZVEnzlYmMkcczWZma3JM6Xd_Bxldqi1F87AM_47pV1nWrNbB8_vSI4EgHd-tc9HZTk6oa-8f_DZaUcTrY0U4_TjYRMT3wj1UfvWbLv9Nqo1l7eMPy0V9-fXJakk4e2YAd6AmDfbAMjOTkGMm2YK-zWpw8XIKcFMOPC2lGhe2TLfHCk_j_677br9FSzmugZx2bQc1dk61ey-EtLnrgvHPojdLw'),
  ('44444444-4444-4444-4444-444444444404', 'Advanced Financial Modeling in Microsoft Excel', 'Forecasting methodologies, capital expenditure modeling, and budget variance analysis for FP&A teams.', 'techData', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAR1qa-PQ_EQITTA9fg1r6hu8Tvtdvs1ekcbF5AZPoioMdMTY50_5YruGcysD0SJ6-8HZaOLG_Qi1RpOlkHkhFcFym36_cBZbIzw4jDEtFbKK7ESumokNXWXZQa9jPJ2O4ZxIX8U6iLHNgQlhgiLKciKZmlz6PPi5p7ZCw7-f3gXnx9lREsaOhXDu8f5Q4C42QheRdnHGkL1PjQ_kaMlv2_fAxXfViXwLZTcxB1OlLDwfONXI1h56Jmag'),
  ('44444444-4444-4444-4444-444444444405', 'Corporate Cybersecurity & Phishing Defense', 'Phishing vectors, social engineering prevention, and live incident-response drills.', 'compliance', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXYkMiYXMEX1qK60nUL9gN1pOR3niSrz2k0TccpqxYLosexsrNqafST6KNh4sd_FbxmX-hH9xnHXbRHt13RwK13JgerDi7uZodQ2pDceEI7qvo_-wfHo8dt9ziLjMaEqyFqDr5fKmWhqtY_6q0VBYW0l9fHm_k4wGuXId41QByjT4bpKuozhC1gCtNDrGxyK-cVfV2b8RrGZDXA6ClJmu73mcMOwNQSF_OxxRkT6Lq8q4OOYKGNJkLKg'),
  ('44444444-4444-4444-4444-444444444406', 'Effective Executive Communication & Stakeholder Alignment', 'High-stakes boardroom presentation, cross-functional influence, investor messaging, and conflict mediation.', 'productivity', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAcMjKgfoHEa8G_VzTvz5W-lpWL88zl5gWlksr1wM5y1Xty2v2vyzFbfxeqrX4zS0yP5kTUyqnf8-SakPJEFx-Kzlrnm-6JxqKczG3nftxgNbS2pjH7BNOSUt0j7QnD8hzJE_KcL2EXk87-27cu8uHdG1igavFS1cWXoTyByUiEHo8KL9bipIN0eO8qitDVg30oxij7-vnE9uEDXLEdnUbJU07Uvz2EBfaV3x7C4mGS2oySo_Ai59eOyQ');

-- ── Course → Lecturer mapping ───────────────────────────────────────────

insert into lecturer_courses (lecturer_id, course_id) values
  ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444401'),
  ('11111111-1111-1111-1111-111111111102', '44444444-4444-4444-4444-444444444402'),
  ('11111111-1111-1111-1111-111111111103', '44444444-4444-4444-4444-444444444403'),
  ('11111111-1111-1111-1111-111111111104', '44444444-4444-4444-4444-444444444406'),
  ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444404');

-- ── Modules + Materials (Python course, fully populated as the reference example) ──

insert into course_modules (id, course_id, module_name, module_description, module_sorting) values
  ('55555555-5555-5555-5555-555555555501', '44444444-4444-4444-4444-444444444401', 'Foundations of Enterprise Python', 'Core syntax, environments, and enterprise tooling.', 0),
  ('55555555-5555-5555-5555-555555555502', '44444444-4444-4444-4444-444444444401', 'Data Wrangling with Pandas', 'DataFrames, joins, and cleaning pipelines.', 1),
  ('55555555-5555-5555-5555-555555555503', '44444444-4444-4444-4444-444444444401', 'Building Automated Data Pipelines', 'Scheduling, orchestration, and monitoring ETL jobs.', 2);

insert into module_materials (id, module_id, material_name, material_type, material_content, material_sorting) values
  ('66666666-6666-6666-6666-666666666601', '55555555-5555-5555-5555-555555555501', 'Enterprise Python Environments', 'lesson',
    '{"videoUrl": "https://example.com/video/python-env", "durationMinutes": 18, "transcript": "Setting up virtual environments, dependency pinning, and enterprise proxies."}'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666602', '55555555-5555-5555-5555-555555555502', 'Pandas Fundamentals Quiz', 'quiz',
    '{
      "quizLength": 5,
      "attemptsPermitted": 3,
      "timeAllocatedMinutes": 15,
      "passingScore": 80,
      "questions": [
        {"question": "Which method removes duplicate rows from a DataFrame?", "mcq": true, "items": ["A. drop_na()", "B. drop_duplicates()", "C. dedupe()", "D. unique()"], "expectedAns": "B"},
        {"question": "What does df.merge() perform by default?", "mcq": true, "items": ["A. Outer join", "B. Left join", "C. Inner join", "D. Cross join"], "expectedAns": "C"}
      ]
    }'::jsonb, 0),
  ('66666666-6666-6666-6666-666666666603', '55555555-5555-5555-5555-555555555503', 'Capstone: Distributed Web Scraping', 'assignment',
    '{
      "instruction": "Design and submit an automated pipeline that scrapes, cleans, and loads a public dataset into a warehouse table on a daily schedule.",
      "references": ["https://docs.python.org/3/library/asyncio.html", "https://docs.pydantic.dev"],
      "notes": "Submit source repo link plus a 1-page architecture summary."
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

-- ── Certifications + module_certs ───────────────────────────────────────

insert into certifications (id, title, issuing_body, badge_icon) values
  ('88888888-8888-8888-8888-888888888801', 'Python Automation Specialist', 'AIEI Enterprise Learning', 'military_tech'),
  ('88888888-8888-8888-8888-888888888802', 'Certified Safety Officer', 'OSHA Accredited Corporate Board', 'workspace_premium'),
  ('88888888-8888-8888-8888-888888888803', 'Certified Cyber Sentinel', 'SecOps Corporate Division', 'shield');

insert into module_certs (module_id, cert_id) values
  ('55555555-5555-5555-5555-555555555503', '88888888-8888-8888-8888-888888888801');

-- ── Student enrollment + progress (drives the catalogue's progress bars) ──

insert into student_courses (student_id, course_id, progress_percentage) values
  ('22222222-2222-2222-2222-222222222201', '44444444-4444-4444-4444-444444444401', 70),
  ('22222222-2222-2222-2222-222222222201', '44444444-4444-4444-4444-444444444402', 38),
  ('22222222-2222-2222-2222-222222222201', '44444444-4444-4444-4444-444444444403', 40),
  ('22222222-2222-2222-2222-222222222201', '44444444-4444-4444-4444-444444444404', 20),
  ('22222222-2222-2222-2222-222222222201', '44444444-4444-4444-4444-444444444405', 85),
  ('22222222-2222-2222-2222-222222222201', '44444444-4444-4444-4444-444444444406', 100);

insert into student_materials (student_id, material_id, status, score, attempts, completed_at) values
  ('22222222-2222-2222-2222-222222222201', '66666666-6666-6666-6666-666666666601', 'completed', null, 1, now() - interval '10 days'),
  ('22222222-2222-2222-2222-222222222201', '66666666-6666-6666-6666-666666666602', 'in_progress', null, 1, null),
  ('22222222-2222-2222-2222-222222222201', '66666666-6666-6666-6666-666666666603', 'not_started', null, 0, null);
