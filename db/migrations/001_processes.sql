-- Migration 001: Process / SOP / Safety Rules master tables
-- Run: docker compose exec db psql -U ssg -d ssg_db -f /migrations/001_processes.sql

-- ── Processes (กระบวนการ) ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS processes (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(30) NOT NULL UNIQUE,
    name        VARCHAR(200) NOT NULL,
    name_th     VARCHAR(200),
    description TEXT,
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── SOPs ──────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sops (
    id          SERIAL PRIMARY KEY,
    process_id  INTEGER REFERENCES processes(id) ON DELETE CASCADE,
    code        VARCHAR(30) NOT NULL UNIQUE,
    title       VARCHAR(200) NOT NULL,
    title_th    VARCHAR(200),
    version     VARCHAR(10) DEFAULT '1.0',
    purpose     TEXT,
    responsible TEXT,
    equipment   TEXT,
    kpi         TEXT,
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── SOP Steps ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sop_steps (
    id          SERIAL PRIMARY KEY,
    sop_id      INTEGER REFERENCES sops(id) ON DELETE CASCADE,
    step_no     INTEGER NOT NULL,
    title       VARCHAR(200),
    title_th    VARCHAR(200),
    description TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    UNIQUE(sop_id, step_no)
);

-- ── Safety Rule Sets ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS safety_rule_sets (
    id          SERIAL PRIMARY KEY,
    process_id  INTEGER REFERENCES processes(id) ON DELETE CASCADE,
    title       VARCHAR(200) NOT NULL,
    title_th    VARCHAR(200),
    version     VARCHAR(10) DEFAULT '1.0',
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Safety Rule Items ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS safety_rule_items (
    id          SERIAL PRIMARY KEY,
    rule_set_id INTEGER REFERENCES safety_rule_sets(id) ON DELETE CASCADE,
    category    VARCHAR(50) NOT NULL,
    -- general / before / during / prohibited / unsafe_condition / safe_practice / critical
    rule_text   TEXT NOT NULL,
    rule_text_th TEXT,
    severity    VARCHAR(20) DEFAULT 'medium',  -- critical / high / medium / low
    is_prohibited BOOLEAN DEFAULT FALSE,
    sort_order  INTEGER DEFAULT 0
);

-- ── Link analysis_jobs to process / SOP / rule set ───────────────────────────
ALTER TABLE analysis_jobs
    ADD COLUMN IF NOT EXISTS process_id   INTEGER REFERENCES processes(id),
    ADD COLUMN IF NOT EXISTS sop_id       INTEGER REFERENCES sops(id),
    ADD COLUMN IF NOT EXISTS rule_set_id  INTEGER REFERENCES safety_rule_sets(id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sops_process         ON sops(process_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_sop         ON sop_steps(sop_id);
CREATE INDEX IF NOT EXISTS idx_rule_sets_process     ON safety_rule_sets(process_id);
CREATE INDEX IF NOT EXISTS idx_rule_items_set        ON safety_rule_items(rule_set_id);
CREATE INDEX IF NOT EXISTS idx_rule_items_category   ON safety_rule_items(category);
CREATE INDEX IF NOT EXISTS idx_jobs_process          ON analysis_jobs(process_id);

-- ═════════════════════════════════════════════════════════════════════════════
-- SEED DATA: Forklift Roll Handling
-- ═════════════════════════════════════════════════════════════════════════════

-- Process
INSERT INTO processes (code, name, name_th, description) VALUES
  ('FORKLIFT-ROLL', 'Forklift Roll Handling',
   'การเคลื่อนย้ายม้วนวัสดุด้วย Forklift',
   'กระบวนการเคลื่อนย้ายม้วนวัสดุในโกดังด้วย Forklift อย่างปลอดภัย')
ON CONFLICT (code) DO NOTHING;

-- SOP
INSERT INTO sops (process_id, code, title, title_th, version,
                  purpose, responsible, equipment, kpi)
SELECT
  p.id,
  'SOP-FORKLIFT-ROLL-001',
  'SOP: Forklift Roll Handling',
  'SOP: การเคลื่อนย้ายม้วนวัสดุด้วย Forklift',
  '1.0',
  'เพื่อกำหนดขั้นตอนการเคลื่อนย้ายม้วนวัสดุ (Roll Material) อย่างปลอดภัย ถูกต้อง และมีประสิทธิภาพ',
  'Forklift Operator, Support Operator (Helper)',
  'Forklift พร้อมแกน (Rod/Shaft), ม้วนวัสดุ (Roll), PPE: Safety Shoes, Safety Vest, Gloves',
  'Zero Accident, Zero Roll Damage'
FROM processes p WHERE p.code = 'FORKLIFT-ROLL'
ON CONFLICT (code) DO NOTHING;

-- SOP Steps
INSERT INTO sop_steps (sop_id, step_no, title, title_th, description, is_critical)
SELECT s.id, steps.step_no, steps.title, steps.title_th, steps.description, steps.is_critical
FROM sops s
CROSS JOIN (VALUES
  (1, 'Pre-operation Check', 'ตรวจสอบความพร้อม',
   'ตรวจสอบ Forklift (เบรก/งา/ระบบยก), พื้นที่ปลอดภัย, สภาพม้วนวัสดุ', false),
  (2, 'Position Forklift', 'เตรียมตำแหน่ง Forklift',
   'ขับเข้าใกล้ม้วนวัสดุช้าๆ, ปรับระดับงาให้ตรงกับแกน', false),
  (3, 'Insert Rod into Roll', 'ใส่แกนเข้า Roll',
   'สอดแกน (Rod) เข้าไปในม้วน, Support Operator จัดแนวให้ตรง', true),
  (4, 'Lift Roll', 'ยกม้วนวัสดุ',
   'ยกขึ้นช้าๆ, ตรวจสอบว่า Roll สมดุล ไม่เอียง', true),
  (5, 'Transport', 'เคลื่อนย้าย',
   'ขับด้วยความเร็วต่ำ, Support Operator เดินข้างเพื่อ guide, ห้ามยืนด้านหน้า Roll', true),
  (6, 'Place Roll', 'วางม้วนวัสดุ',
   'ลดระดับลงช้าๆ, วางในตำแหน่งที่กำหนด, ตรวจสอบความมั่นคงก่อนถอนแกน', false),
  (7, 'Withdraw Equipment', 'ถอนอุปกรณ์',
   'ดึงแกนออกอย่างระมัดระวัง, ถอย Forklift ออกจากพื้นที่', false)
) AS steps(step_no, title, title_th, description, is_critical)
WHERE s.code = 'SOP-FORKLIFT-ROLL-001'
ON CONFLICT (sop_id, step_no) DO NOTHING;

-- Safety Rule Set
INSERT INTO safety_rule_sets (process_id, title, title_th, version)
SELECT p.id,
  'Safety Rules: Forklift Roll Handling',
  'กฎความปลอดภัย: การปฏิบัติงานโกดัง Forklift Roll Handling',
  '1.0'
FROM processes p WHERE p.code = 'FORKLIFT-ROLL';

-- Safety Rule Items
INSERT INTO safety_rule_items (rule_set_id, category, rule_text_th, rule_text, severity, is_prohibited, sort_order)
SELECT rs.id, items.category, items.rule_text_th, items.rule_text, items.severity, items.is_prohibited, items.sort_order
FROM safety_rule_sets rs
CROSS JOIN (VALUES
  -- General
  ('general','ต้องสวม PPE ครบถ้วนก่อนเข้าพื้นที่ (Safety Shoes, Safety Vest)','Must wear full PPE before entering area','medium',false,1),
  ('general','อนุญาตเฉพาะผู้ที่ได้รับการอบรมเท่านั้นในการใช้งาน Forklift','Only trained personnel may operate Forklift','high',false,2),
  ('general','ห้ามผู้ที่ไม่เกี่ยวข้องเข้าในพื้นที่ปฏิบัติงาน','Unauthorized persons prohibited in work area','high',true,3),
  ('general','ต้องรักษาความสะอาดและความเป็นระเบียบของพื้นที่ (5S)','Maintain 5S cleanliness in work area','medium',false,4),
  -- Before
  ('before','ต้องตรวจสอบสภาพ Forklift ทุกครั้งก่อนใช้งาน','Inspect Forklift condition before every use','high',false,1),
  ('before','ต้องตรวจสอบพื้นที่ให้ปลอดภัย ไม่มีสิ่งกีดขวาง','Verify work area is clear of obstructions','high',false,2),
  ('before','ต้องตรวจสอบม้วนวัสดุให้อยู่ในสภาพพร้อมใช้งาน','Verify roll material is in good condition','medium',false,3),
  ('before','ห้ามเริ่มงานหากพบอุปกรณ์ชำรุด','Do not start work if equipment is defective','critical',true,4),
  -- During
  ('during','ขับด้วยความเร็วต่ำ เข้าหาม้วนตรงแนว ห้ามกระแทกวัสดุ','Drive slowly, approach roll straight, do not impact material','high',false,1),
  ('during','Helper อยู่ด้านข้างเท่านั้น ห้ามวางมือใกล้จุดหนีบ','Helper stands beside only, do not place hands near pinch points','critical',false,2),
  ('during','ยกขึ้นช้าและควบคุมได้ ตรวจสอบความสมดุลก่อนเคลื่อนย้าย ห้ามยกสูงเกินความจำเป็น','Lift slowly, check balance, do not lift higher than necessary','high',false,3),
  ('during','ต้องมี Helper เดินข้าง ห้ามมีบุคคลอยู่ด้านหน้าม้วน รักษาระยะห่าง 1-2 เมตร','Helper must walk beside, nobody in front of roll, keep 1-2m distance','critical',false,4),
  ('during','ลดระดับลงช้า วางในตำแหน่งที่กำหนด ตรวจสอบความมั่นคงก่อนปล่อย','Lower slowly, place in designated position, check stability before release','high',false,5),
  -- Prohibited
  ('prohibited','ห้ามยืนด้านหน้าม้วนวัสดุ (Danger Zone)','Never stand in front of roll material (Danger Zone)','critical',true,1),
  ('prohibited','ห้ามจับม้วนวัสดุขณะเคลื่อนที่','Never touch roll material while moving','critical',true,2),
  ('prohibited','ห้ามขับ Forklift ด้วยความเร็วสูง','Never drive Forklift at high speed','critical',true,3),
  ('prohibited','ห้ามใช้งาน Forklift ที่ไม่ได้รับการตรวจสอบ','Never use uninspected Forklift','high',true,4),
  ('prohibited','ห้ามใช้งานโดยไม่ได้รับอนุญาต','Never operate without authorization','high',true,5),
  -- Unsafe Conditions
  ('unsafe_condition','พื้นลื่น / เปียก','Slippery/wet floor','high',false,1),
  ('unsafe_condition','พื้นที่แคบ / มีสิ่งกีดขวาง','Narrow area / obstructed path','high',false,2),
  ('unsafe_condition','ม้วนวัสดุไม่ยึดแน่นกับแกน','Roll not securely fastened to shaft','critical',false,3),
  ('unsafe_condition','แสงสว่างไม่เพียงพอ','Insufficient lighting','medium',false,4),
  -- Safe Practices
  ('safe_practice','ใช้สัญญาณมือหรือเสียงในการสื่อสาร','Use hand signals or voice for communication','medium',false,1),
  ('safe_practice','ตรวจสอบความปลอดภัยทุกขั้นตอน','Check safety at every step','high',false,2),
  ('safe_practice','รักษาระยะห่างจาก Forklift และ Load','Maintain distance from Forklift and load','high',false,3),
  ('safe_practice','ปฏิบัติตาม SOP อย่างเคร่งครัด','Follow SOP strictly','high',false,4),
  -- Critical
  ('critical','ห้ามมีคนอยู่ใน Danger Zone โดยเด็ดขาด','Absolutely no persons in Danger Zone','critical',true,1),
  ('critical','ต้องควบคุมความเร็ว Forklift ตลอดเวลา','Must control Forklift speed at all times','critical',false,2),
  ('critical','ต้องตรวจสอบความมั่นคงของ Load ก่อนเคลื่อนย้าย','Must verify load stability before moving','critical',false,3),
  ('critical','Safety มาก่อน Productivity เสมอ','Safety always before Productivity','critical',false,4)
) AS items(category, rule_text_th, rule_text, severity, is_prohibited, sort_order)
WHERE rs.title = 'Safety Rules: Forklift Roll Handling';
