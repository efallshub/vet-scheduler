-- ============================================================
-- VET SCHEDULER — DATABASE SCHEMA
-- Run this once to set up all tables
-- ============================================================

-- ── EMPLOYEES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS employees (
  id          TEXT PRIMARY KEY,          -- 'T1', 'A1', 'P1', etc.
  pool        TEXT NOT NULL,             -- 'LVT' | 'ASST' | 'PSR' | 'PCR' | 'PHARM'
  name        TEXT NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT true,
  ft          BOOLEAN NOT NULL DEFAULT true,
  max_hours   INTEGER,
  min_hours   INTEGER,
  max_days    INTEGER,
  allow_dbl   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── SKILLS ───────────────────────────────────────────────────
-- One row per employee+area combination
CREATE TABLE IF NOT EXISTS skills (
  employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  area        TEXT NOT NULL,             -- 'RUNWAY', 'SURGERY', etc.
  level       TEXT NOT NULL,             -- 'SOLO'|'MENTOR'|'INDIRECT'|'DIRECT'|'NONE'
  PRIMARY KEY (employee_id, area)
);

-- ── AVAILABILITY BLOCKS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS avail_blocks (
  id          TEXT PRIMARY KEY,          -- 'ab-t3-1' etc.
  employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  start_date  DATE NOT NULL,
  end_date    DATE,                      -- NULL = ongoing
  -- Days stored as JSONB: {Sunday:{am,pm}, Monday:{am,pm}, ...}
  days        JSONB NOT NULL DEFAULT '{}'
);

-- ── TEMPLATES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS templates (
  id          TEXT PRIMARY KEY,          -- 't1', 't2', 'tpl_...'
  name        TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── TEMPLATE DAYS ────────────────────────────────────────────
-- One row per template + day-of-week (0=Sun … 6=Sat)
CREATE TABLE IF NOT EXISTS template_days (
  template_id TEXT NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
  dow         INTEGER NOT NULL CHECK (dow BETWEEN 0 AND 6),
  -- Doctor arrays stored as JSONB arrays of initials
  surgery         JSONB NOT NULL DEFAULT '[]',
  dental          JSONB NOT NULL DEFAULT '[]',
  specprocedure   JSONB NOT NULL DEFAULT '[]',
  housecalls      JSONB NOT NULL DEFAULT '[]',
  appt_am         JSONB NOT NULL DEFAULT '[]',
  appt_aft        JSONB NOT NULL DEFAULT '[]',
  appt_eve        JSONB NOT NULL DEFAULT '[]',
  PRIMARY KEY (template_id, dow)
);

-- ── WEEK ASSIGNMENTS ─────────────────────────────────────────
-- Maps a calendar week (Sunday date) → template id
CREATE TABLE IF NOT EXISTS week_assignments (
  week_start  DATE PRIMARY KEY,          -- always a Sunday
  template_id TEXT REFERENCES templates(id) ON DELETE SET NULL
);

-- ── WEEK DOCTOR OVERRIDES ────────────────────────────────────
-- Tracks which doctors are marked OUT for which days in a given week
CREATE TABLE IF NOT EXISTS week_doc_overrides (
  week_start  DATE NOT NULL,
  doc_init    TEXT NOT NULL,
  out_days    JSONB NOT NULL DEFAULT '[]', -- array of dow integers [1,3] = Mon+Wed out
  PRIMARY KEY (week_start, doc_init)
);

-- ── AREA RULES ───────────────────────────────────────────────
-- Editable demand rules (mirrors AREA_RULES constant in frontend)
CREATE TABLE IF NOT EXISTS area_rules (
  id          SERIAL PRIMARY KEY,
  area        TEXT NOT NULL,
  shift       TEXT NOT NULL,             -- 'AM' | 'PM'
  pool        TEXT,                      -- NULL = LVT/ASST inferred from role
  type        TEXT NOT NULL,             -- 'FIXED' | 'PER_DOC'
  source      TEXT,                      -- 'surgery', 'appt_am', etc.
  mult        NUMERIC NOT NULL DEFAULT 1.0,
  round_mode  TEXT NOT NULL DEFAULT 'NONE', -- 'NONE' | 'CEIL'
  role        TEXT NOT NULL DEFAULT 'tech', -- 'tech' | 'asst' | 'tech_or_asst'
  active      BOOLEAN NOT NULL DEFAULT true,
  days        JSONB NOT NULL DEFAULT '[0,1,2,3,4,5,6]', -- array of dow
  section_break TEXT,                    -- label for UI section divider
  note        TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0
);

-- ── DAY OVERRIDES ────────────────────────────────────────────
-- Per-date area toggle overrides (e.g. CIRCULATION_PM manually enabled)
CREATE TABLE IF NOT EXISTS day_overrides (
  date        DATE NOT NULL,
  area        TEXT NOT NULL,
  shift       TEXT NOT NULL,
  active      BOOLEAN NOT NULL,
  PRIMARY KEY (date, area, shift)
);

-- ── ASSIGNMENTS ──────────────────────────────────────────────
-- Actual staff assignments to slots (built during scheduling)
CREATE TABLE IF NOT EXISTS assignments (
  id          SERIAL PRIMARY KEY,
  date        DATE NOT NULL,
  employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  area        TEXT NOT NULL,
  shift       TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── TEMPORARY OVERRIDES ──────────────────────────────────────
-- Date-specific availability exceptions per employee
CREATE TABLE IF NOT EXISTS temp_overrides (
  employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  am          BOOLEAN,
  pm          BOOLEAN,
  note        TEXT,
  PRIMARY KEY (employee_id, date)
);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_skills_employee     ON skills(employee_id);
CREATE INDEX IF NOT EXISTS idx_avail_employee      ON avail_blocks(employee_id);
CREATE INDEX IF NOT EXISTS idx_template_days_tpl   ON template_days(template_id);
CREATE INDEX IF NOT EXISTS idx_week_assign_week    ON week_assignments(week_start);
CREATE INDEX IF NOT EXISTS idx_assignments_date    ON assignments(date);
CREATE INDEX IF NOT EXISTS idx_assignments_emp     ON assignments(employee_id);
CREATE INDEX IF NOT EXISTS idx_overrides_date      ON day_overrides(date);
CREATE INDEX IF NOT EXISTS idx_temp_overrides_emp  ON temp_overrides(employee_id);
