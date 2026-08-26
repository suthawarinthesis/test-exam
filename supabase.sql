-- POSN Biology Exam System / Supabase PostgreSQL
-- Run this once in Supabase SQL Editor. Safe to rerun: seeds use UPSERT.

create extension if not exists pgcrypto;
create schema if not exists private;

create table if not exists public.exam_topics (
  id smallint primary key,
  slug text unique not null,
  name_th text not null,
  short_th text not null,
  sort_order smallint not null default 0
);

create table if not exists public.exam_questions (
  id integer primary key,
  source_label text unique not null,
  topic_id smallint not null references public.exam_topics(id),
  crop_segments jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists private.exam_answer_keys (
  question_id integer primary key references public.exam_questions(id) on delete cascade,
  correct_option char(1) not null check (correct_option in ('A','B','C','D')),
  key_status text not null default 'checked' check (key_status in ('checked','review')),
  review_note text
);

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  student_name text not null check (char_length(btrim(student_name)) between 2 and 80),
  client_token_hash text not null,
  question_order integer[] not null,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  status text not null default 'in_progress' check (status in ('in_progress','submitted','expired')),
  time_limit_seconds integer not null default 4800,
  score integer,
  total_questions integer,
  tab_switches integer not null default 0,
  user_agent text
);

create table if not exists public.exam_answers (
  attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
  question_id integer not null references public.exam_questions(id),
  selected_option char(1) not null check (selected_option in ('A','B','C','D')),
  answered_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

create table if not exists public.exam_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.exam_topics enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.exam_answers enable row level security;
alter table public.exam_admins enable row level security;
-- No direct anon policies are intentionally created. Students use SECURITY DEFINER RPCs.

insert into public.exam_topics(id, slug, name_th, short_th, sort_order) values
(1, 'research-biomolecules', 'ทักษะวิทยาศาสตร์และสารชีวโมเลกุล', 'วิธีวิทยา + Biomolecules', 1),
(2, 'cell-membrane', 'ชีววิทยาเซลล์และการลำเลียงผ่านเยื่อหุ้ม', 'Cell + Membrane', 2),
(3, 'cellular-energetics', 'การหายใจระดับเซลล์และเมแทบอลิซึม', 'Cellular Energetics', 3),
(4, 'genetics', 'พันธุศาสตร์และสารพันธุกรรม', 'Genetics', 4),
(5, 'animal-physiology', 'สรีรวิทยาสัตว์และมนุษย์', 'Animal Physiology', 5),
(6, 'immunity-nervous', 'ภูมิคุ้มกัน ระบบประสาท และประสาทสัมผัส', 'Immune + Nervous', 6),
(7, 'plant-structure', 'โครงสร้าง การสืบพันธุ์ และกายวิภาคพืช', 'Plant Structure', 7),
(8, 'plant-physiology', 'การสังเคราะห์ด้วยแสงและสรีรวิทยาพืช', 'Plant Physiology', 8),
(9, 'microbiology', 'จุลชีววิทยา โพรทิสต์ และฟังไจ', 'Microbiology', 9),
(10, 'diversity-evolution', 'ความหลากหลาย อนุกรมวิธาน และวิวัฒนาการ', 'Diversity + Evolution', 10),
(11, 'ecology', 'นิเวศวิทยาและประชากร', 'Ecology', 11)
on conflict (id) do update set slug=excluded.slug, name_th=excluded.name_th, short_th=excluded.short_th, sort_order=excluded.sort_order;

insert into public.exam_questions(id, source_label, topic_id, crop_segments, is_active) values
(1, '1A', 1, '[{"page":4,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":484.18024}]'::jsonb, true),
(2, '1', 1, '[{"page":4,"x0":68.0,"y0":482.18024,"x1":542.0,"y1":792.0},{"page":5,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(3, '2', 1, '[{"page":5,"x0":68.0,"y0":64.41024,"x1":542.0,"y1":261.92024}]'::jsonb, true),
(4, '3', 1, '[{"page":5,"x0":68.0,"y0":259.92024,"x1":542.0,"y1":366.32024}]'::jsonb, true),
(5, '4', 1, '[{"page":5,"x0":68.0,"y0":364.32024,"x1":542.0,"y1":523.18024}]'::jsonb, true),
(6, '5', 1, '[{"page":5,"x0":68.0,"y0":521.18024,"x1":542.0,"y1":792.0},{"page":6,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(7, '6', 2, '[{"page":6,"x0":68.0,"y0":64.41024,"x1":542.0,"y1":194.21024}]'::jsonb, true),
(8, '7', 2, '[{"page":6,"x0":68.0,"y0":192.21024,"x1":542.0,"y1":602.17024}]'::jsonb, true),
(9, '8', 2, '[{"page":6,"x0":68.0,"y0":600.17024,"x1":542.0,"y1":792.0},{"page":7,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(10, '9', 2, '[{"page":7,"x0":68.0,"y0":64.41024,"x1":542.0,"y1":196.85024}]'::jsonb, true),
(11, '10', 2, '[{"page":7,"x0":68.0,"y0":194.85024,"x1":542.0,"y1":607.45024}]'::jsonb, true),
(12, '11', 2, '[{"page":7,"x0":68.0,"y0":605.45024,"x1":542.0,"y1":792.0},{"page":8,"x0":68.0,"y0":55.0,"x1":542.0,"y1":194.69024}]'::jsonb, true),
(13, '12', 2, '[{"page":8,"x0":68.0,"y0":192.69024,"x1":542.0,"y1":468.58024}]'::jsonb, true),
(14, '13', 2, '[{"page":8,"x0":68.0,"y0":466.58024,"x1":542.0,"y1":792.0},{"page":9,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(15, '14', 2, '[{"page":9,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":271.52024}]'::jsonb, true),
(16, '15', 2, '[{"page":9,"x0":68.0,"y0":269.52024,"x1":542.0,"y1":432.46024}]'::jsonb, true),
(17, '16', 2, '[{"page":9,"x0":68.0,"y0":430.46024,"x1":542.0,"y1":569.17024}]'::jsonb, true),
(18, '17', 3, '[{"page":9,"x0":68.0,"y0":567.17024,"x1":542.0,"y1":705.75024}]'::jsonb, true),
(19, '18', 3, '[{"page":9,"x0":68.0,"y0":703.75024,"x1":542.0,"y1":792.0},{"page":10,"x0":68.0,"y0":55.0,"x1":542.0,"y1":152.45024}]'::jsonb, true),
(20, '19', 3, '[{"page":10,"x0":68.0,"y0":150.45024,"x1":542.0,"y1":273.08024}]'::jsonb, true),
(21, '20', 3, '[{"page":10,"x0":68.0,"y0":271.08024,"x1":542.0,"y1":349.0}]'::jsonb, true),
(22, '21', 3, '[{"page":10,"x0":68.0,"y0":347.0,"x1":542.0,"y1":792.0},{"page":11,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(23, '22', 3, '[{"page":11,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":187.13024}]'::jsonb, true),
(24, '23', 3, '[{"page":11,"x0":68.0,"y0":185.13024,"x1":542.0,"y1":496.54024}]'::jsonb, true),
(25, '24', 3, '[{"page":11,"x0":68.0,"y0":494.54024,"x1":542.0,"y1":617.29024}]'::jsonb, true),
(26, '25', 4, '[{"page":11,"x0":68.0,"y0":615.29024,"x1":542.0,"y1":792.0},{"page":12,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(27, '26', 4, '[{"page":12,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":211.13024}]'::jsonb, true),
(28, '27', 4, '[{"page":12,"x0":68.0,"y0":209.13024,"x1":542.0,"y1":535.81024}]'::jsonb, true),
(29, '28', 5, '[{"page":12,"x0":68.0,"y0":533.81024,"x1":542.0,"y1":792.0},{"page":13,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(30, '29', 5, '[{"page":13,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":235.40024}]'::jsonb, true),
(31, '30', 5, '[{"page":13,"x0":68.0,"y0":233.40024,"x1":542.0,"y1":376.06024}]'::jsonb, true),
(32, '31', 5, '[{"page":13,"x0":68.0,"y0":374.06024,"x1":542.0,"y1":472.42024}]'::jsonb, true),
(33, '32', 5, '[{"page":13,"x0":68.0,"y0":470.42024,"x1":542.0,"y1":585.01024}]'::jsonb, true),
(34, '33', 5, '[{"page":13,"x0":68.0,"y0":583.01024,"x1":542.0,"y1":792.0},{"page":14,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(35, '34', 6, '[{"page":14,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":194.93024}]'::jsonb, true),
(36, '35', 6, '[{"page":14,"x0":68.0,"y0":192.93024,"x1":542.0,"y1":327.68024}]'::jsonb, true),
(37, '36', 6, '[{"page":14,"x0":68.0,"y0":325.68024,"x1":542.0,"y1":496.42024}]'::jsonb, true),
(38, '37', 6, '[{"page":14,"x0":68.0,"y0":494.42024,"x1":542.0,"y1":792.0},{"page":15,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(39, '38', 6, '[{"page":15,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":215.36024}]'::jsonb, true),
(40, '39', 6, '[{"page":15,"x0":68.0,"y0":213.36024,"x1":542.0,"y1":323.84024}]'::jsonb, true),
(41, '40', 6, '[{"page":15,"x0":68.0,"y0":321.84024,"x1":542.0,"y1":452.50024}]'::jsonb, true),
(42, '41', 6, '[{"page":15,"x0":68.0,"y0":450.50024,"x1":542.0,"y1":573.25024}]'::jsonb, true),
(43, '42', 6, '[{"page":15,"x0":68.0,"y0":571.25024,"x1":542.0,"y1":792.0},{"page":16,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(44, '43', 6, '[{"page":16,"x0":68.0,"y0":64.41024,"x1":542.0,"y1":170.93024}]'::jsonb, true),
(45, '44', 6, '[{"page":16,"x0":68.0,"y0":168.93024,"x1":542.0,"y1":303.56024}]'::jsonb, true),
(46, '45', 6, '[{"page":16,"x0":68.0,"y0":301.56024,"x1":542.0,"y1":455.26024}]'::jsonb, true),
(47, '46', 6, '[{"page":16,"x0":68.0,"y0":453.26024,"x1":542.0,"y1":792.0},{"page":17,"x0":68.0,"y0":55.0,"x1":542.0,"y1":183.05024}]'::jsonb, true),
(48, '47', 6, '[{"page":17,"x0":68.0,"y0":181.05024,"x1":542.0,"y1":323.84024}]'::jsonb, true),
(49, '48', 6, '[{"page":17,"x0":68.0,"y0":321.84024,"x1":542.0,"y1":432.46024}]'::jsonb, true),
(50, '49', 5, '[{"page":17,"x0":68.0,"y0":430.46024,"x1":542.0,"y1":569.17024}]'::jsonb, true),
(51, '50', 5, '[{"page":17,"x0":68.0,"y0":567.17024,"x1":542.0,"y1":792.0},{"page":18,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(52, '51', 5, '[{"page":18,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":188.21024}]'::jsonb, true),
(53, '52', 5, '[{"page":18,"x0":68.0,"y0":186.21024,"x1":542.0,"y1":524.98024}]'::jsonb, true),
(54, '53', 5, '[{"page":18,"x0":68.0,"y0":522.98024,"x1":542.0,"y1":792.0},{"page":19,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(55, '54', 5, '[{"page":19,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":396.34024}]'::jsonb, true),
(56, '55', 5, '[{"page":19,"x0":68.0,"y0":394.34024,"x1":542.0,"y1":516.94024}]'::jsonb, true),
(57, '56', 5, '[{"page":19,"x0":68.0,"y0":514.94024,"x1":542.0,"y1":792.0},{"page":20,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(58, '57', 5, '[{"page":20,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":154.97024}]'::jsonb, true),
(59, '58', 5, '[{"page":20,"x0":68.0,"y0":152.97024,"x1":542.0,"y1":424.42024}]'::jsonb, true),
(60, '59', 7, '[{"page":20,"x0":68.0,"y0":422.42024,"x1":542.0,"y1":593.29024}]'::jsonb, true),
(61, '60', 7, '[{"page":20,"x0":68.0,"y0":591.29024,"x1":542.0,"y1":673.81024}]'::jsonb, true),
(62, '61', 7, '[{"page":20,"x0":68.0,"y0":671.81024,"x1":542.0,"y1":792.0},{"page":21,"x0":68.0,"y0":55.0,"x1":542.0,"y1":94.61024}]'::jsonb, true),
(63, '62', 7, '[{"page":21,"x0":68.0,"y0":92.61024,"x1":542.0,"y1":223.28024}]'::jsonb, true),
(64, '63', 7, '[{"page":21,"x0":68.0,"y0":221.28024,"x1":542.0,"y1":359.96024}]'::jsonb, true),
(65, '64', 7, '[{"page":21,"x0":68.0,"y0":357.96024,"x1":542.0,"y1":633.85024}]'::jsonb, true),
(66, '65', 7, '[{"page":21,"x0":68.0,"y0":631.85024,"x1":542.0,"y1":792.0},{"page":22,"x0":68.0,"y0":55.0,"x1":542.0,"y1":94.61024}]'::jsonb, true),
(67, '66', 7, '[{"page":22,"x0":68.0,"y0":92.61024,"x1":542.0,"y1":227.24024}]'::jsonb, true),
(68, '67', 7, '[{"page":22,"x0":68.0,"y0":225.24024,"x1":542.0,"y1":371.84024}]'::jsonb, true),
(69, '68', 8, '[{"page":22,"x0":68.0,"y0":369.84024,"x1":542.0,"y1":500.50024}]'::jsonb, true),
(70, '69', 8, '[{"page":22,"x0":68.0,"y0":498.50024,"x1":542.0,"y1":709.59024}]'::jsonb, true),
(71, '70', 8, '[{"page":22,"x0":68.0,"y0":707.59024,"x1":542.0,"y1":792.0},{"page":23,"x0":68.0,"y0":55.0,"x1":542.0,"y1":94.61024}]'::jsonb, true),
(72, '71', 8, '[{"page":23,"x0":68.0,"y0":92.61024,"x1":542.0,"y1":183.05024}]'::jsonb, true),
(73, '72', 8, '[{"page":23,"x0":68.0,"y0":181.05024,"x1":542.0,"y1":263.60024}]'::jsonb, true),
(74, '73', 8, '[{"page":23,"x0":68.0,"y0":261.60024,"x1":542.0,"y1":384.22024}]'::jsonb, true),
(75, '74', 8, '[{"page":23,"x0":68.0,"y0":382.22024,"x1":542.0,"y1":444.58024}]'::jsonb, true),
(76, '75', 8, '[{"page":23,"x0":68.0,"y0":442.58024,"x1":542.0,"y1":565.21024}]'::jsonb, true),
(77, '76', 8, '[{"page":23,"x0":68.0,"y0":563.21024,"x1":542.0,"y1":792.0},{"page":24,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(78, '77', 8, '[{"page":24,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":195.17024}]'::jsonb, true),
(79, '78', 4, '[{"page":24,"x0":68.0,"y0":193.17024,"x1":542.0,"y1":315.92024}]'::jsonb, true),
(80, '79', 4, '[{"page":24,"x0":68.0,"y0":313.92024,"x1":542.0,"y1":436.54024}]'::jsonb, true),
(81, '80', 4, '[{"page":24,"x0":68.0,"y0":434.54024,"x1":542.0,"y1":585.37024}]'::jsonb, true),
(82, '81.1', 4, '[{"page":24,"x0":68.0,"y0":583.37024,"x1":542.0,"y1":792.0},{"page":25,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(83, '81.2', 4, '[{"page":25,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":187.13024}]'::jsonb, true),
(84, '81.3', 4, '[{"page":25,"x0":68.0,"y0":185.13024,"x1":542.0,"y1":307.88024}]'::jsonb, true),
(85, '81.4', 4, '[{"page":25,"x0":68.0,"y0":305.88024,"x1":542.0,"y1":428.50024}]'::jsonb, true),
(86, '82', 9, '[{"page":25,"x0":68.0,"y0":426.50024,"x1":542.0,"y1":549.25024}]'::jsonb, true),
(87, '83', 9, '[{"page":25,"x0":68.0,"y0":547.25024,"x1":542.0,"y1":669.85024}]'::jsonb, true),
(88, '84', 9, '[{"page":25,"x0":68.0,"y0":667.85024,"x1":542.0,"y1":792.0},{"page":26,"x0":68.0,"y0":55.0,"x1":542.0,"y1":106.73024}]'::jsonb, true),
(89, '85', 9, '[{"page":26,"x0":68.0,"y0":104.73024,"x1":542.0,"y1":235.40024}]'::jsonb, true),
(90, '86', 9, '[{"page":26,"x0":68.0,"y0":233.40024,"x1":542.0,"y1":356.12024}]'::jsonb, true),
(91, '87', 9, '[{"page":26,"x0":68.0,"y0":354.12024,"x1":542.0,"y1":476.74024}]'::jsonb, true),
(92, '88', 9, '[{"page":26,"x0":68.0,"y0":474.74024,"x1":542.0,"y1":545.17024}]'::jsonb, true),
(93, '89', 9, '[{"page":26,"x0":68.0,"y0":543.17024,"x1":542.0,"y1":792.0},{"page":27,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(94, '90', 10, '[{"page":27,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":327.92024}]'::jsonb, true),
(95, '91', 10, '[{"page":27,"x0":68.0,"y0":325.92024,"x1":542.0,"y1":448.66024}]'::jsonb, true),
(96, '92', 10, '[{"page":27,"x0":68.0,"y0":446.66024,"x1":542.0,"y1":577.33024}]'::jsonb, true),
(97, '93', 10, '[{"page":27,"x0":68.0,"y0":575.33024,"x1":542.0,"y1":792.0},{"page":28,"x0":68.0,"y0":55.0,"x1":542.0,"y1":291.32024}]'::jsonb, true),
(98, '94', 10, '[{"page":28,"x0":68.0,"y0":289.32024,"x1":542.0,"y1":500.38024}]'::jsonb, true),
(99, '95', 11, '[{"page":28,"x0":68.0,"y0":498.38024,"x1":542.0,"y1":792.0},{"page":29,"x0":68.0,"y0":55.0,"x1":542.0,"y1":94.61024}]'::jsonb, true),
(100, '96', 11, '[{"page":29,"x0":68.0,"y0":92.61024,"x1":542.0,"y1":291.68024}]'::jsonb, true),
(101, '97', 11, '[{"page":29,"x0":68.0,"y0":289.68024,"x1":542.0,"y1":448.42024}]'::jsonb, true),
(102, '98', 11, '[{"page":29,"x0":68.0,"y0":446.42024,"x1":542.0,"y1":792.0},{"page":30,"x0":68.0,"y0":55.0,"x1":542.0,"y1":75.0}]'::jsonb, true),
(103, '99', 11, '[{"page":30,"x0":68.0,"y0":64.53024,"x1":542.0,"y1":187.13024}]'::jsonb, true),
(104, '100', 10, '[{"page":30,"x0":68.0,"y0":185.13024,"x1":542.0,"y1":620.0}]'::jsonb, true)
on conflict (id) do update set source_label=excluded.source_label, topic_id=excluded.topic_id, crop_segments=excluded.crop_segments, is_active=excluded.is_active;

insert into private.exam_answer_keys(question_id, correct_option, key_status, review_note) values
(1, 'D', 'checked', NULL),
(2, 'B', 'checked', NULL),
(3, 'A', 'checked', NULL),
(4, 'B', 'checked', NULL),
(5, 'B', 'checked', NULL),
(6, 'B', 'checked', NULL),
(7, 'B', 'checked', NULL),
(8, 'C', 'checked', NULL),
(9, 'C', 'checked', NULL),
(10, 'C', 'checked', NULL),
(11, 'B', 'checked', NULL),
(12, 'B', 'checked', NULL),
(13, 'C', 'checked', NULL),
(14, 'D', 'checked', NULL),
(15, 'D', 'checked', NULL),
(16, 'C', 'checked', NULL),
(17, 'C', 'checked', NULL),
(18, 'B', 'checked', NULL),
(19, 'D', 'checked', NULL),
(20, 'D', 'checked', NULL),
(21, 'B', 'checked', NULL),
(22, 'D', 'checked', NULL),
(23, 'A', 'checked', NULL),
(24, 'C', 'checked', NULL),
(25, 'B', 'checked', NULL),
(26, 'D', 'checked', NULL),
(27, 'D', 'checked', NULL),
(28, 'A', 'checked', NULL),
(29, 'D', 'checked', NULL),
(30, 'C', 'checked', NULL),
(31, 'B', 'checked', NULL),
(32, 'C', 'checked', NULL),
(33, 'C', 'checked', NULL),
(34, 'C', 'checked', NULL),
(35, 'A', 'checked', NULL),
(36, 'A', 'checked', NULL),
(37, 'C', 'checked', NULL),
(38, 'A', 'checked', NULL),
(39, 'B', 'checked', NULL),
(40, 'A', 'checked', NULL),
(41, 'A', 'checked', NULL),
(42, 'C', 'checked', NULL),
(43, 'D', 'checked', NULL),
(44, 'D', 'checked', NULL),
(45, 'B', 'checked', NULL),
(46, 'B', 'checked', NULL),
(47, 'B', 'checked', NULL),
(48, 'D', 'checked', NULL),
(49, 'B', 'checked', NULL),
(50, 'D', 'checked', NULL),
(51, 'B', 'checked', NULL),
(52, 'D', 'checked', NULL),
(53, 'D', 'checked', NULL),
(54, 'D', 'checked', NULL),
(55, 'B', 'checked', NULL),
(56, 'A', 'review', 'ถ้อยคำเรื่องแหล่ง “สร้างและหลั่ง” ADH มีโอกาสตีความต่างกันในบางเอกสาร; ตั้งค่าเริ่มต้นตามเจตนาข้อสอบเป็น ก.'),
(57, 'D', 'checked', NULL),
(58, 'B', 'checked', NULL),
(59, 'D', 'checked', NULL),
(60, 'D', 'checked', NULL),
(61, 'A', 'checked', NULL),
(62, 'A', 'checked', NULL),
(63, 'A', 'checked', NULL),
(64, 'B', 'checked', NULL),
(65, 'D', 'checked', NULL),
(66, 'A', 'checked', NULL),
(67, 'B', 'checked', NULL),
(68, 'B', 'checked', NULL),
(69, 'A', 'checked', NULL),
(70, 'D', 'checked', NULL),
(71, 'D', 'checked', NULL),
(72, 'B', 'checked', NULL),
(73, 'A', 'checked', NULL),
(74, 'B', 'checked', NULL),
(75, 'B', 'checked', NULL),
(76, 'B', 'checked', NULL),
(77, 'A', 'checked', NULL),
(78, 'C', 'checked', NULL),
(79, 'B', 'checked', NULL),
(80, 'B', 'checked', NULL),
(81, 'A', 'checked', NULL),
(82, 'A', 'checked', NULL),
(83, 'B', 'checked', NULL),
(84, 'C', 'review', 'คำว่า codon โดยเคร่งครัดใช้กับ mRNA; ตั้งค่าเริ่มต้นเป็น ค. และควรเทียบเฉลยสถาบันก่อนสอบจริง'),
(85, 'D', 'checked', NULL),
(86, 'A', 'checked', NULL),
(87, 'B', 'checked', NULL),
(88, 'B', 'checked', NULL),
(89, 'D', 'review', 'โจทย์โพรทิสต์คล้ายรามีตัวเลือกที่อาจอภิปรายเชิงนิยามได้; ตั้งค่าเริ่มต้นเป็น ง. และเปิด flag ให้ admin ตรวจทาน'),
(90, 'B', 'checked', NULL),
(91, 'C', 'checked', NULL),
(92, 'A', 'checked', NULL),
(93, 'D', 'checked', NULL),
(94, 'B', 'checked', NULL),
(95, 'D', 'checked', NULL),
(96, 'B', 'checked', NULL),
(97, 'C', 'checked', NULL),
(98, 'A', 'checked', NULL),
(99, 'C', 'checked', NULL),
(100, 'B', 'checked', NULL),
(101, 'C', 'checked', NULL),
(102, 'C', 'checked', NULL),
(103, 'B', 'checked', NULL),
(104, 'C', 'checked', NULL)
on conflict (question_id) do update set correct_option=excluded.correct_option, key_status=excluded.key_status, review_note=excluded.review_note;

revoke all on schema private from public, anon, authenticated;
revoke all on all tables in schema private from public, anon, authenticated;

-- Public metadata only: no answer keys.
create or replace function public.get_exam_questions()
returns jsonb
language sql
security definer
set search_path = public, private, pg_temp
as $$
  select jsonb_agg(jsonb_build_object(
    'id', q.id,
    'source_label', q.source_label,
    'topic_slug', t.slug,
    'topic_name', t.name_th,
    'segments', q.crop_segments
  ) order by q.id)
  from public.exam_questions q
  join public.exam_topics t on t.id=q.topic_id
  where q.is_active;
$$;

create or replace function public.start_exam(p_student_name text, p_client_token text, p_user_agent text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_id uuid;
  v_order integer[];
  v_started timestamptz := now();
  v_name text := btrim(p_student_name);
begin
  if char_length(v_name) < 2 or char_length(v_name) > 80 then
    raise exception 'student_name_invalid';
  end if;
  if p_client_token is null or char_length(p_client_token) < 20 then
    raise exception 'client_token_invalid';
  end if;
  select array_agg(id order by random()) into v_order
  from public.exam_questions where is_active;

  insert into public.exam_attempts(student_name, client_token_hash, question_order, started_at, time_limit_seconds, user_agent)
  values(v_name, encode(digest(p_client_token,'sha256'),'hex'), v_order, v_started, 4800, left(p_user_agent,500))
  returning id into v_id;

  return jsonb_build_object(
    'attempt_id', v_id,
    'question_order', to_jsonb(v_order),
    'started_at', v_started,
    'deadline', v_started + make_interval(secs => 4800),
    'total_questions', cardinality(v_order)
  );
end;
$$;

create or replace function public.save_exam_answer(p_attempt_id uuid, p_client_token text, p_question_id integer, p_selected_option text)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare v_ok boolean; v_deadline timestamptz;
begin
  select true, started_at + make_interval(secs => time_limit_seconds + 90)
  into v_ok, v_deadline
  from public.exam_attempts
  where id=p_attempt_id
    and client_token_hash=encode(digest(p_client_token,'sha256'),'hex')
    and status='in_progress'
    and p_question_id = any(question_order);
  if coalesce(v_ok,false) is false then raise exception 'attempt_not_found'; end if;
  if now() > v_deadline then raise exception 'attempt_expired'; end if;
  if p_selected_option not in ('A','B','C','D') then raise exception 'invalid_option'; end if;
  insert into public.exam_answers(attempt_id,question_id,selected_option,answered_at)
  values(p_attempt_id,p_question_id,p_selected_option,now())
  on conflict(attempt_id,question_id) do update set selected_option=excluded.selected_option, answered_at=excluded.answered_at;
  return true;
end;
$$;

create or replace function public.update_tab_switches(p_attempt_id uuid, p_client_token text, p_count integer)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  update public.exam_attempts
  set tab_switches = greatest(tab_switches, coalesce(p_count,0))
  where id=p_attempt_id and client_token_hash=encode(digest(p_client_token,'sha256'),'hex');
  return found;
end;
$$;

create or replace function public._exam_result_json(p_attempt_id uuid)
returns jsonb
language sql
security definer
set search_path = public, private, pg_temp
as $$
with a as (
  select * from public.exam_attempts where id=p_attempt_id
), perq as (
  select q.id, q.source_label, t.slug topic_slug, t.name_th topic_name,
         ans.selected_option, k.correct_option,
         (ans.selected_option = k.correct_option) as is_correct
  from a
  cross join unnest(a.question_order) with ordinality qo(qid, ord)
  join public.exam_questions q on q.id=qo.qid
  join public.exam_topics t on t.id=q.topic_id
  join private.exam_answer_keys k on k.question_id=q.id
  left join public.exam_answers ans on ans.attempt_id=p_attempt_id and ans.question_id=q.id
), topic_calc as (
  select topic_slug, topic_name, count(*) total,
         count(*) filter(where is_correct) correct,
         count(*) filter(where selected_option is null) unanswered
  from perq group by topic_slug,topic_name
), topic_json as (
  select jsonb_agg(jsonb_build_object(
    'slug',topic_slug,'name',topic_name,'total',total,'correct',correct,'unanswered',unanswered,
    'accuracy', round((correct::numeric/nullif(total,0))*100,1)
  ) order by (correct::numeric/nullif(total,0)) desc, topic_name) j
  from topic_calc
), missed as (
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'source_label',source_label,'topic_slug',topic_slug,'selected',selected_option) order by id),'[]'::jsonb) j
  from perq where coalesce(is_correct,false)=false
), totals as (
  select count(*) total,
         count(*) filter(where is_correct) correct,
         count(*) filter(where selected_option is null) unanswered
  from perq
)
select jsonb_build_object(
  'attempt_id', a.id,
  'student_name', a.student_name,
  'status', a.status,
  'started_at', a.started_at,
  'submitted_at', a.submitted_at,
  'time_limit_seconds', a.time_limit_seconds,
  'time_used_seconds', greatest(0, least(a.time_limit_seconds, extract(epoch from (coalesce(a.submitted_at,now())-a.started_at))::int)),
  'tab_switches', a.tab_switches,
  'score', totals.correct,
  'total', totals.total,
  'unanswered', totals.unanswered,
  'percent', round((totals.correct::numeric/nullif(totals.total,0))*100,1),
  'topics', topic_json.j,
  'missed_questions', missed.j
)
from a cross join totals cross join topic_json cross join missed;
$$;

create or replace function public.submit_exam(p_attempt_id uuid, p_client_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare v_a public.exam_attempts%rowtype; v_total int; v_correct int; v_expired boolean;
begin
  select * into v_a from public.exam_attempts
  where id=p_attempt_id and client_token_hash=encode(digest(p_client_token,'sha256'),'hex');
  if not found then raise exception 'attempt_not_found'; end if;
  if v_a.status='submitted' then return public._exam_result_json(p_attempt_id); end if;

  v_expired := now() > v_a.started_at + make_interval(secs => v_a.time_limit_seconds + 90);
  select count(*), count(*) filter(where ans.selected_option=k.correct_option)
  into v_total,v_correct
  from unnest(v_a.question_order) qid
  join private.exam_answer_keys k on k.question_id=qid
  left join public.exam_answers ans on ans.attempt_id=p_attempt_id and ans.question_id=qid;

  update public.exam_attempts
  set submitted_at=now(), status=case when v_expired then 'expired' else 'submitted' end,
      score=v_correct, total_questions=v_total
  where id=p_attempt_id;
  return public._exam_result_json(p_attempt_id);
end;
$$;

create or replace function public.get_exam_result(p_attempt_id uuid, p_client_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare v_ok boolean;
begin
  select true into v_ok from public.exam_attempts
  where id=p_attempt_id and client_token_hash=encode(digest(p_client_token,'sha256'),'hex') and status in ('submitted','expired');
  if coalesce(v_ok,false) is false then raise exception 'result_not_available'; end if;
  return public._exam_result_json(p_attempt_id);
end;
$$;

-- Admin functions. Add yourself after creating an Auth user:
-- insert into public.exam_admins(user_id) values ('YOUR_AUTH_USER_UUID');
create or replace function public.admin_list_attempts(p_limit integer default 200)
returns table(id uuid, student_name text, started_at timestamptz, submitted_at timestamptz, status text, score int, total_questions int, tab_switches int)
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if not exists(select 1 from public.exam_admins where user_id=auth.uid()) then raise exception 'admin_required'; end if;
  return query select a.id,a.student_name,a.started_at,a.submitted_at,a.status,a.score,a.total_questions,a.tab_switches
  from public.exam_attempts a order by a.started_at desc limit greatest(1,least(coalesce(p_limit,200),1000));
end;
$$;

create or replace function public.admin_attempt_detail(p_attempt_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if not exists(select 1 from public.exam_admins where user_id=auth.uid()) then raise exception 'admin_required'; end if;
  return public._exam_result_json(p_attempt_id);
end;
$$;

create or replace function public.admin_key_review_queue()
returns table(question_id int, source_label text, correct_option char(1), key_status text, review_note text)
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if not exists(select 1 from public.exam_admins where user_id=auth.uid()) then raise exception 'admin_required'; end if;
  return query select q.id,q.source_label,k.correct_option,k.key_status,k.review_note
  from private.exam_answer_keys k join public.exam_questions q on q.id=k.question_id
  where k.key_status='review' order by q.id;
end;
$$;

grant execute on function public.get_exam_questions() to anon, authenticated;
grant execute on function public.start_exam(text,text,text) to anon, authenticated;
grant execute on function public.save_exam_answer(uuid,text,integer,text) to anon, authenticated;
grant execute on function public.update_tab_switches(uuid,text,integer) to anon, authenticated;
grant execute on function public.submit_exam(uuid,text) to anon, authenticated;
grant execute on function public.get_exam_result(uuid,text) to anon, authenticated;
grant execute on function public.admin_list_attempts(integer) to authenticated;
grant execute on function public.admin_attempt_detail(uuid) to authenticated;
grant execute on function public.admin_key_review_queue() to authenticated;
