-- ============================================================
-- VET SCHEDULER — SEED DATA
-- Migrated from hardcoded frontend data
-- Run AFTER schema.sql
-- ============================================================

-- ── TEMPLATES ────────────────────────────────────────────────
INSERT INTO templates (id, name) VALUES
  ('t1', 'Week 1 Standard'),
  ('t2', 'Week 2 Standard'),
  ('t3', 'Week 3 Standard'),
  ('t4', 'Week 4 Standard'),
  ('t5', 'Week 5 Standard'),
  ('t6', 'Week 6 Standard')
ON CONFLICT (id) DO NOTHING;

-- ── TEMPLATE DAYS — Week 1 (Mon–Fri populated, others blank) ─
-- Sunday (0)
INSERT INTO template_days (template_id, dow, surgery, dental, specprocedure, appt_am)
VALUES ('t1', 0, '["BP","BK"]', '["RF"]', '["AD"]', '["SG","AD","MD","TR","HG"]')
ON CONFLICT (template_id, dow) DO UPDATE SET
  surgery=EXCLUDED.surgery, dental=EXCLUDED.dental,
  specprocedure=EXCLUDED.specprocedure, appt_am=EXCLUDED.appt_am;

-- Mon–Fri (1–5) identical for week 1
INSERT INTO template_days (template_id, dow, surgery, dental, specprocedure, appt_am, appt_aft, appt_eve)
SELECT 't1', d, '["BP","BK"]', '["RF"]', '["AD"]',
       '["MF","SG","AD","HG","BP","C"]',
       '["MD","SG","AD","BK"]',
       '["MD","C","SG","RF"]'
FROM generate_series(1,5) d
ON CONFLICT (template_id, dow) DO UPDATE SET
  surgery=EXCLUDED.surgery, dental=EXCLUDED.dental,
  specprocedure=EXCLUDED.specprocedure, appt_am=EXCLUDED.appt_am,
  appt_aft=EXCLUDED.appt_aft, appt_eve=EXCLUDED.appt_eve;

-- Saturday (6)
INSERT INTO template_days (template_id, dow, surgery, dental, specprocedure, appt_am, appt_aft)
VALUES ('t1', 6, '["BP","BK"]', '["RF"]', '["AD"]', '["MF","SG","MD"]', '["AD","BP"]')
ON CONFLICT (template_id, dow) DO UPDATE SET
  surgery=EXCLUDED.surgery, dental=EXCLUDED.dental,
  specprocedure=EXCLUDED.specprocedure, appt_am=EXCLUDED.appt_am,
  appt_aft=EXCLUDED.appt_aft;

-- Blank days for templates 2–6 (all 7 days, all empty)
INSERT INTO template_days (template_id, dow)
SELECT t.id, d FROM templates t CROSS JOIN generate_series(0,6) d
WHERE t.id IN ('t2','t3','t4','t5','t6')
ON CONFLICT DO NOTHING;

-- ── WEEK ASSIGNMENTS ─────────────────────────────────────────
INSERT INTO week_assignments (week_start, template_id) VALUES
  ('2026-03-01', 't1'),
  ('2026-03-08', 't2')
ON CONFLICT (week_start) DO NOTHING;

-- ── EMPLOYEES — LVT pool ─────────────────────────────────────
INSERT INTO employees (id, pool, name, active, ft, max_hours, min_hours, max_days, allow_dbl) VALUES
  ('T1',  'LVT', 'Ahl, Brook',          true,  true,  39,   30,   null, false),
  ('T2',  'LVT', 'Anziano, Isabella',   true,  true,  39,   30,   null, true),
  ('T3',  'LVT', 'Benson, Natalie',     true,  true,  39,   30,   null, true),
  ('T4',  'LVT', 'Corey, Sarah',        true,  true,  39,   30,   null, false),
  ('T5',  'LVT', 'Foti, Rachel',        false, false, null, null, null, false),
  ('T6',  'LVT', 'Friedman, Charliann', true,  false, null, null, null, false),
  ('T7',  'LVT', 'Grippo, Brittany',    true,  true,  39,   30,   null, true),
  ('T8',  'LVT', 'Hitchcock, Joann',    true,  true,  39,   30,   null, false),
  ('T9',  'LVT', 'LaTorre, Jillian',    true,  true,  39,   30,   null, false),
  ('T10', 'LVT', 'Laurenty, Kaitlyn',   true,  true,  39,   30,   null, true),
  ('T11', 'LVT', 'Mantica, Carlie',     true,  true,  39,   30,   null, false),
  ('T12', 'LVT', 'Rousseas, Kelly',     true,  false, null, null, null, true),
  ('T13', 'LVT', 'Szafran, Shannon',    true,  true,  32,   30,   3,    true),
  ('T14', 'LVT', 'Zeman, Mary',         true,  true,  39,   30,   null, true),
  ('T15', 'LVT', 'Passamore, Kyle',     true,  true,  39,   30,   null, false),
  -- ASST pool (placeholders)
  ('A1',  'ASST', 'Assistant, Sample',  false, false, null, null, null, false),
  -- PSR pool (placeholders)
  ('P1',  'PSR',  'PSR, Sample',        false, false, null, null, null, false),
  -- PCR pool
  ('C1',  'PCR',  'PCR, Sample',        false, false, null, null, null, false),
  -- PHARM pool
  ('PH1', 'PHARM','Pharm, Sample',      false, false, null, null, null, false)
ON CONFLICT (id) DO NOTHING;

-- ── SKILLS ───────────────────────────────────────────────────
INSERT INTO skills (employee_id, area, level) VALUES
  ('T1','RUNWAY','INDIRECT'),('T1','SURGERY','INDIRECT'),('T1','DENTAL','DIRECT'),('T1','SPECPROCEDURE','INDIRECT'),('T1','PROCEDURES','DIRECT'),('T1','TRX','INDIRECT'),('T1','LAB','INDIRECT'),('T1','CIRCULATION','INDIRECT'),('T1','REHAB','INDIRECT'),
  ('T2','RUNWAY','MENTOR'),('T2','SURGERY','MENTOR'),('T2','DENTAL','MENTOR'),('T2','SPECPROCEDURE','MENTOR'),('T2','PROCEDURES','MENTOR'),('T2','TRX','MENTOR'),('T2','LAB','MENTOR'),('T2','CIRCULATION','MENTOR'),('T2','REHAB','MENTOR'),
  ('T3','RUNWAY','SOLO'),('T3','SURGERY','SOLO'),('T3','DENTAL','SOLO'),('T3','SPECPROCEDURE','SOLO'),('T3','PROCEDURES','SOLO'),('T3','TRX','SOLO'),('T3','LAB','SOLO'),('T3','CIRCULATION','SOLO'),('T3','REHAB','SOLO'),
  ('T4','RUNWAY','NONE'),('T4','SURGERY','SOLO'),('T4','DENTAL','SOLO'),('T4','SPECPROCEDURE','SOLO'),('T4','PROCEDURES','SOLO'),('T4','TRX','SOLO'),('T4','LAB','SOLO'),('T4','CIRCULATION','SOLO'),('T4','REHAB','SOLO'),
  ('T5','RUNWAY','MENTOR'),('T5','SURGERY','MENTOR'),('T5','DENTAL','MENTOR'),('T5','SPECPROCEDURE','MENTOR'),('T5','PROCEDURES','MENTOR'),('T5','TRX','MENTOR'),('T5','LAB','SOLO'),('T5','CIRCULATION','MENTOR'),('T5','REHAB','MENTOR'),
  ('T6','RUNWAY','SOLO'),('T6','SURGERY','NONE'),('T6','DENTAL','NONE'),('T6','SPECPROCEDURE','INDIRECT'),('T6','PROCEDURES','NONE'),('T6','TRX','INDIRECT'),('T6','LAB','SOLO'),('T6','CIRCULATION','SOLO'),('T6','REHAB','INDIRECT'),
  ('T7','RUNWAY','MENTOR'),('T7','SURGERY','MENTOR'),('T7','DENTAL','MENTOR'),('T7','SPECPROCEDURE','MENTOR'),('T7','PROCEDURES','MENTOR'),('T7','TRX','MENTOR'),('T7','LAB','MENTOR'),('T7','CIRCULATION','MENTOR'),('T7','REHAB','MENTOR'),
  ('T8','RUNWAY','SOLO'),('T8','SURGERY','MENTOR'),('T8','DENTAL','NONE'),('T8','SPECPROCEDURE','MENTOR'),('T8','PROCEDURES','MENTOR'),('T8','TRX','MENTOR'),('T8','LAB','MENTOR'),('T8','CIRCULATION','MENTOR'),('T8','REHAB','NONE'),
  ('T9','RUNWAY','SOLO'),('T9','SURGERY','MENTOR'),('T9','DENTAL','SOLO'),('T9','SPECPROCEDURE','MENTOR'),('T9','PROCEDURES','MENTOR'),('T9','TRX','MENTOR'),('T9','LAB','MENTOR'),('T9','CIRCULATION','MENTOR'),('T9','REHAB','NONE'),
  ('T10','RUNWAY','MENTOR'),('T10','SURGERY','MENTOR'),('T10','DENTAL','MENTOR'),('T10','SPECPROCEDURE','MENTOR'),('T10','PROCEDURES','MENTOR'),('T10','TRX','MENTOR'),('T10','LAB','MENTOR'),('T10','CIRCULATION','MENTOR'),('T10','REHAB','MENTOR'),
  ('T11','RUNWAY','SOLO'),('T11','SURGERY','MENTOR'),('T11','DENTAL','SOLO'),('T11','SPECPROCEDURE','MENTOR'),('T11','PROCEDURES','MENTOR'),('T11','TRX','MENTOR'),('T11','LAB','MENTOR'),('T11','CIRCULATION','MENTOR'),('T11','REHAB','NONE'),
  ('T12','RUNWAY','MENTOR'),('T12','SURGERY','MENTOR'),('T12','DENTAL','MENTOR'),('T12','SPECPROCEDURE','MENTOR'),('T12','PROCEDURES','MENTOR'),('T12','TRX','MENTOR'),('T12','LAB','MENTOR'),('T12','CIRCULATION','MENTOR'),('T12','REHAB','MENTOR'),
  ('T13','RUNWAY','SOLO'),('T13','SURGERY','SOLO'),('T13','DENTAL','SOLO'),('T13','SPECPROCEDURE','SOLO'),('T13','PROCEDURES','SOLO'),('T13','TRX','SOLO'),('T13','LAB','SOLO'),('T13','CIRCULATION','SOLO'),('T13','REHAB','SOLO'),
  ('T14','RUNWAY','SOLO'),('T14','SURGERY','SOLO'),('T14','DENTAL','SOLO'),('T14','SPECPROCEDURE','SOLO'),('T14','PROCEDURES','SOLO'),('T14','TRX','SOLO'),('T14','LAB','SOLO'),('T14','CIRCULATION','SOLO'),('T14','REHAB','SOLO'),
  ('T15','RUNWAY','INDIRECT'),('T15','SURGERY','INDIRECT'),('T15','DENTAL','INDIRECT'),('T15','SPECPROCEDURE','INDIRECT'),('T15','PROCEDURES','INDIRECT'),('T15','TRX','INDIRECT'),('T15','LAB','INDIRECT'),('T15','CIRCULATION','INDIRECT'),('T15','REHAB','INDIRECT')
ON CONFLICT (employee_id, area) DO NOTHING;

-- ── AVAILABILITY BLOCKS ──────────────────────────────────────
INSERT INTO avail_blocks (id, employee_id, name, start_date, end_date, days) VALUES
  ('ab-t3-1',  'T3',  'Standard Schedule', '2026-01-01', NULL,
   '{"Sunday":{"am":true,"pm":false},"Monday":{"am":true,"pm":true},"Tuesday":{"am":false,"pm":false},"Wednesday":{"am":true,"pm":true},"Thursday":{"am":true,"pm":true},"Friday":{"am":true,"pm":true},"Saturday":{"am":false,"pm":false}}'),
  ('ab-t7-1',  'T7',  'Standard Schedule', '2026-01-01', NULL,
   '{"Sunday":{"am":false,"pm":false},"Monday":{"am":true,"pm":true},"Tuesday":{"am":true,"pm":true},"Wednesday":{"am":true,"pm":false},"Thursday":{"am":true,"pm":true},"Friday":{"am":true,"pm":true},"Saturday":{"am":false,"pm":false}}'),
  ('ab-t12-1', 'T12', 'Part-Time Regular', '2026-01-01', NULL,
   '{"Sunday":{"am":false,"pm":false},"Monday":{"am":false,"pm":false},"Tuesday":{"am":true,"pm":false},"Wednesday":{"am":true,"pm":false},"Thursday":{"am":false,"pm":false},"Friday":{"am":false,"pm":false},"Saturday":{"am":false,"pm":false}}'),
  ('ab-t13-1', 'T13', 'Standard Schedule', '2026-01-01', NULL,
   '{"Sunday":{"am":false,"pm":false},"Monday":{"am":true,"pm":true},"Tuesday":{"am":true,"pm":true},"Wednesday":{"am":false,"pm":false},"Thursday":{"am":true,"pm":true},"Friday":{"am":true,"pm":true},"Saturday":{"am":false,"pm":false}}')
ON CONFLICT (id) DO NOTHING;

-- ── AREA RULES ───────────────────────────────────────────────
INSERT INTO area_rules (area, shift, type, source, mult, round_mode, role, active, days, section_break, note, sort_order) VALUES
  ('RUNWAY','AM','PER_DOC','appt_am',0.5,'CEIL','tech',true,'[0,1,2,3,4,5,6]',NULL,'ceil(appt AM docs × 0.5) — tech',10),
  ('RUNWAY','AM','PER_DOC','appt_am',0.5,'CEIL','asst',true,'[0,1,2,3,4,5,6]',NULL,'ceil(appt AM docs × 0.5) — asst',11),
  ('RUNWAY','PM','PER_DOC','appt_pm',0.5,'CEIL','tech',true,'[0,1,2,3,4,5,6]',NULL,'ceil(max(AFT,EVE) × 0.5) — tech',12),
  ('RUNWAY','PM','PER_DOC','appt_pm',0.5,'CEIL','asst',true,'[0,1,2,3,4,5,6]',NULL,'ceil(max(AFT,EVE) × 0.5) — asst',13),
  ('SURGERY','AM','PER_DOC','surgery',1.0,'NONE','tech',true,'[0,1,2,3,4,5,6]',NULL,'1 tech per surgery doc',20),
  ('SURGERY','AM','PER_DOC','surgery',1.0,'NONE','asst',true,'[0,1,2,3,4,5,6]',NULL,'1 asst per surgery doc',21),
  ('DENTAL','AM','PER_DOC','dental',1.0,'NONE','tech',true,'[0,1,2,3,4,5,6]',NULL,'1 tech per dental doc',30),
  ('SPECPROCEDURE','AM','PER_DOC','specproc',1.0,'NONE','tech',true,'[0,1,2,3,4,5,6]',NULL,'1 tech per special procedures doc',40),
  ('PROCEDURES','AM','FIXED',NULL,1.0,'NONE','tech_or_asst',true,'[1,2,3,4,5]','Fixed / Toggle Areas','Fixed 1 slot AM — tech or asst',50),
  ('LAB','AM','FIXED',NULL,1.0,'NONE','tech_or_asst',true,'[1,2,3,4,5]',NULL,'Fixed 1 slot AM — tech or asst',60),
  ('LAB','PM','FIXED',NULL,1.0,'NONE','tech_or_asst',true,'[1,2,3,4,5]',NULL,'Fixed 1 slot PM — tech or asst',61),
  ('TRX','PM','FIXED',NULL,1.0,'NONE','tech_or_asst',true,'[1,2,3,4,5]',NULL,'Fixed 1 slot PM — tech or asst',70),
  ('CIRCULATION','AM','FIXED',NULL,1.0,'NONE','tech_or_asst',false,'[1,2,3,4,5]',NULL,'Toggle per day — tech or asst',80),
  ('CIRCULATION','PM','FIXED',NULL,1.0,'NONE','tech_or_asst',false,'[1,2,3,4,5]',NULL,'Toggle per day — tech or asst',81),
  ('REHAB','AM','FIXED',NULL,1.0,'NONE','tech_or_asst',false,'[1,2,3,4,5]',NULL,'Toggle per day — tech or asst',90),
  ('HOUSECALLS','AM','PER_DOC','housecalls',1.0,'NONE','asst',true,'[0,1,2,3,4,5,6]',NULL,'1 asst (special clearance) per house call doc',100),
  ('SAT APPT','AM','PER_DOC','appt_am',0.5,'CEIL','tech_or_asst',true,'[6]',NULL,'ceil(sat AM appt docs × 0.5)',110),
  ('SAT APPT','PM','PER_DOC','appt_aft',0.5,'CEIL','tech_or_asst',true,'[6]',NULL,'ceil(sat AFT appt docs × 0.5)',111),
  ('SAT FLOAT','AM','FIXED',NULL,0.0,'NONE','tech_or_asst',false,'[6]',NULL,'Saturday float — off by default',120),
  ('SUN APPT','AM','PER_DOC','appt_am',0.5,'CEIL','tech_or_asst',true,'[0]',NULL,'ceil(sun AM appt docs × 0.5)',130),
  ('SUN FLOAT','AM','FIXED',NULL,0.0,'NONE','tech_or_asst',false,'[0]',NULL,'Sunday float — off by default',140),
  ('PSR_FRONT','AM','FIXED',NULL,2.0,'NONE','tech',true,'[1,2,3,4,5]','PSR — Front Desk & Phone Room','2 PSR Front slots AM — rules TBD',200),
  ('PSR_FRONT','PM','FIXED',NULL,1.0,'NONE','tech',true,'[1,2,3,4,5]',NULL,'1 PSR Front slot PM — rules TBD',201),
  ('PSR_PHONE','AM','FIXED',NULL,1.0,'NONE','tech',true,'[1,2,3,4,5]',NULL,'1 PSR Phone slot AM — rules TBD',202),
  ('PSR_PHONE','PM','FIXED',NULL,1.0,'NONE','tech',false,'[1,2,3,4,5]',NULL,'Phone PM — off by default',203),
  ('PCR','AM','FIXED',NULL,1.0,'NONE','tech',true,'[1,2,3,4,5]','PCR','PCR staffing — rules TBD',210),
  ('PCR','PM','FIXED',NULL,1.0,'NONE','tech',false,'[1,2,3,4,5]',NULL,'PCR PM — rules TBD',211),
  ('PHARM','AM','FIXED',NULL,1.0,'NONE','tech',true,'[1,2,3,4,5]','Pharm','Pharmacy staffing — rules TBD',220),
  ('PHARM','PM','FIXED',NULL,1.0,'NONE','tech',false,'[1,2,3,4,5]',NULL,'Pharm PM — rules TBD',221)
ON CONFLICT DO NOTHING;
