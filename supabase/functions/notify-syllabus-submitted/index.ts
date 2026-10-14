// Emails every admin when a lecturer submits a class syllabus for approval.
// Called by the `trg_syllabus_submitted` database trigger (see schema.sql).
//
// Deploy:  supabase functions deploy notify-syllabus-submitted --no-verify-jwt
// Secrets (any SMTP server works; for Gmail use smtp.gmail.com / 465 and an
// App Password — Google Account > Security > 2-Step Verification > App passwords):
//   supabase secrets set SMTP_HOST=smtp.gmail.com SMTP_PORT=465 \
//     SMTP_USER=you@gmail.com SMTP_PASS=<app password> \
//     MAIL_FROM="AIEI LMS <you@gmail.com>" WEBHOOK_SECRET=<random string> \
//     APP_URL=https://your-app.example.com
import { createClient } from 'npm:@supabase/supabase-js@2';
import nodemailer from 'npm:nodemailer@6';

Deno.serve(async (req) => {
  if (req.headers.get('x-webhook-secret') !== Deno.env.get('WEBHOOK_SECRET')) {
    return new Response('Unauthorized', { status: 401 });
  }
  const { section_id } = await req.json();
  if (!section_id) return new Response('section_id required', { status: 400 });

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: section, error } = await db
    .from('course_sections')
    .select('section_code, syllabus_status, syllabus_submitted_at, courses(course_code, course_title), lecturers(name)')
    .eq('id', section_id)
    .single();
  if (error || !section) return new Response('Section not found', { status: 404 });
  if (section.syllabus_status !== 'submitted') return new Response('Not submitted, skipped');

  const { data: admins } = await db.from('admins').select('email');
  const to = (admins ?? []).map((a) => a.email).filter(Boolean);
  if (to.length === 0) return new Response('No admins to notify');

  const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!);
  const course = section.courses as { course_code: string; course_title: string } | null;
  const lecturer = (section.lecturers as { name: string } | null)?.name ?? 'A lecturer';
  const classCode = section.section_code.replace(/^TN\d+-/, '');
  const subject = `Syllabus submitted for approval: ${classCode}`;
  const appUrl = Deno.env.get('APP_URL');
  const html = `
    <p>${esc(lecturer)} has submitted a syllabus for approval.</p>
    <ul>
      <li><b>Class:</b> ${esc(classCode)}</li>
      <li><b>Course:</b> ${esc(course ? `${course.course_code} – ${course.course_title}` : '')}</li>
    </ul>
    <p>${appUrl ? `<a href="${esc(appUrl)}">Open the Admin Portal</a> and go to Manage Syllabi to review it.` : 'Open the Admin Portal and go to Manage Syllabi to review it.'}</p>`;

  const port = Number(Deno.env.get('SMTP_PORT') ?? '465');
  const transport = nodemailer.createTransport({
    host: Deno.env.get('SMTP_HOST'),
    port,
    secure: port === 465,
    auth: { user: Deno.env.get('SMTP_USER'), pass: Deno.env.get('SMTP_PASS') },
  });
  try {
    // BCC so admins don't see each other's addresses.
    await transport.sendMail({ from: Deno.env.get('MAIL_FROM'), bcc: to, subject, html });
  } catch (e) {
    return new Response(`Email failed: ${e}`, { status: 502 });
  }
  return new Response('Sent');
});
