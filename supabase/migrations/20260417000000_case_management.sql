-- Case management tables: client_intakes, case_plans, case_programs, case_notes, case_referrals

CREATE TABLE IF NOT EXISTS client_intakes (
  id TEXT PRIMARY KEY,
  client_name TEXT NOT NULL,
  client_phone TEXT,
  client_id TEXT,
  case_manager_id TEXT NOT NULL,
  case_manager_name TEXT NOT NULL,
  intake_date TEXT NOT NULL,
  presenting_situation TEXT,
  needs_identified TEXT,
  emergency_support_desc TEXT,
  emergency_support_amount REAL,
  currency TEXT DEFAULT 'GHC',
  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS case_plans (
  id TEXT PRIMARY KEY,
  intake_id TEXT NOT NULL REFERENCES client_intakes(id),
  client_name TEXT NOT NULL,
  client_id TEXT,
  case_manager_id TEXT NOT NULL,
  case_manager_name TEXT NOT NULL,
  plan_status TEXT DEFAULT 'active',
  next_review_date TEXT,
  review_frequency TEXT DEFAULT 'quarterly',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS case_programs (
  id TEXT PRIMARY KEY,
  case_plan_id TEXT NOT NULL REFERENCES case_plans(id),
  program_number INTEGER DEFAULT 0,
  program_name TEXT NOT NULL,
  goal TEXT,
  current_status_notes TEXT,
  priority TEXT DEFAULT 'medium',
  deadline_label TEXT,
  deadline_date TEXT,
  actions TEXT,
  is_completed INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS case_notes (
  id TEXT PRIMARY KEY,
  case_plan_id TEXT NOT NULL REFERENCES case_plans(id),
  case_program_id TEXT,
  note_text TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS case_referrals (
  id TEXT PRIMARY KEY,
  intake_id TEXT NOT NULL REFERENCES client_intakes(id),
  case_plan_id TEXT,
  direction TEXT NOT NULL,
  referral_date TEXT NOT NULL,
  partner_organization TEXT NOT NULL,
  partner_contact_name TEXT,
  partner_contact_phone TEXT,
  reason TEXT NOT NULL,
  service_type TEXT,
  urgency TEXT DEFAULT 'routine',
  payment_category TEXT,
  payment_amount REAL,
  payment_notes TEXT,
  status TEXT DEFAULT 'pending',
  outcome_notes TEXT,
  recorded_by TEXT NOT NULL,
  country_code TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Enable RLS on all tables
ALTER TABLE client_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_referrals ENABLE ROW LEVEL SECURITY;

-- Staff/admin can read and write all records
CREATE POLICY "staff_all_client_intakes" ON client_intakes FOR ALL USING (true);
CREATE POLICY "staff_all_case_plans" ON case_plans FOR ALL USING (true);
CREATE POLICY "staff_all_case_programs" ON case_programs FOR ALL USING (true);
CREATE POLICY "staff_all_case_notes" ON case_notes FOR ALL USING (true);
CREATE POLICY "staff_all_case_referrals" ON case_referrals FOR ALL USING (true);
