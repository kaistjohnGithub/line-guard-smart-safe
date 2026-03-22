#!/bin/bash
# Import CAM-A05 events into database
# Usage: bash import_cam_a05_events.sh [API_BASE_URL]
# Default: http://localhost:8000

API="${1:-http://localhost:8000}"

curl -s -X POST "$API/api/events/bulk" \
  -H "Content-Type: application/json" \
  -d '{
  "camera_id": "CAM-A05",
  "replace": true,
  "events": [
    {"timestamp_mmss":"01:13","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"Person A หยิบกระป๋องจากกล่อง NG (ควรหยิบจาก WAIT) — เริ่มนำกระป๋อง NG กลับเข้าสายการผลิตโดยไม่ผ่านขั้นตอนที่ถูกต้อง"},
    {"timestamp_mmss":"01:16","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา (ไม่พบบันทึกการตรวจสอบที่ 01:15)"},
    {"timestamp_mmss":"01:18","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:20","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:22","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:24","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:26","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:28","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:30","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:32","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:34","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:36","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:36","severity":"low","event_type":"unauthorized_person","event_type_label":"บุคคลอื่นเข้าพื้นที่","description":"Person C เดินเข้าพื้นที่ทำงาน ถือขวดน้ำ"},
    {"timestamp_mmss":"01:37","severity":"low","event_type":"unauthorized_person","event_type_label":"บุคคลอื่นเข้าพื้นที่","description":"Person C ยังอยู่ในพื้นที่ทำงาน — ยื่นขวดน้ำให้ Person B"},
    {"timestamp_mmss":"01:38","severity":"low","event_type":"unauthorized_person","event_type_label":"บุคคลอื่นเข้าพื้นที่","description":"Person C ยังอยู่ในพื้นที่ทำงาน — Person B รับขวดน้ำ"},
    {"timestamp_mmss":"01:39","severity":"low","event_type":"unauthorized_person","event_type_label":"บุคคลอื่นเข้าพื้นที่","description":"Person C ยังอยู่ในพื้นที่ทำงาน"},
    {"timestamp_mmss":"01:39","severity":"medium","event_type":"hygiene_violation","event_type_label":"วางของไม่เกี่ยวข้อง","description":"Person B วางขวดน้ำบนโต๊ะในพื้นที่ทำงาน"},
    {"timestamp_mmss":"01:40","severity":"low","event_type":"unauthorized_person","event_type_label":"บุคคลอื่นเข้าพื้นที่","description":"Person C กำลังเดินออกจากพื้นที่ทำงาน"},
    {"timestamp_mmss":"01:41","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:43","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:45","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:47","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:49","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:51","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:55","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:57","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"01:59","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"02:03","severity":"medium","event_type":"sop_violation","event_type_label":"ทำงานข้ามขั้นตอน","description":"วางกระป๋องใบสุดท้ายจากกล่อง NG ขึ้นสายพานโดยไม่ตรวจสอบด้วยสายตา"},
    {"timestamp_mmss":"02:55","severity":"critical","event_type":"near_miss","event_type_label":"Near-Miss สายพานหนีบมือ","description":"Person B ยื่นมือขวาไปที่ส่วนกลางของเครื่องจักร (ขณะสายพานยังเดิน)"},
    {"timestamp_mmss":"02:59","severity":"medium","event_type":"ppe_violation","event_type_label":"ไม่ใส่อุปกรณ์ PPE","description":"Person B ถอดหมวกออก (ขณะยังอยู่ในพื้นที่ทำงาน)"},
    {"timestamp_mmss":"03:00","severity":"medium","event_type":"ppe_violation","event_type_label":"ไม่ใส่อุปกรณ์ PPE","description":"Person B ยังไม่สวมหมวก (กำลังสวมคืน)"},
    {"timestamp_mmss":"03:35","severity":"medium","event_type":"ppe_violation","event_type_label":"ไม่ใส่อุปกรณ์ PPE","description":"Person B ถอดหมวก + ถุงมือออก (สิ้นสุดการทำงาน — เครื่องยังทำงานอยู่)"},
    {"timestamp_mmss":"03:36","severity":"medium","event_type":"ppe_violation","event_type_label":"ไม่ใส่อุปกรณ์ PPE","description":"Person B ไม่สวมหมวกและถุงมือ (ยืนพูดคุยในพื้นที่ทำงาน)"},
    {"timestamp_mmss":"03:37","severity":"medium","event_type":"ppe_violation","event_type_label":"ไม่ใส่อุปกรณ์ PPE","description":"Person B ไม่สวมหมวกและถุงมือ (Person A ปรับเครื่องจักร)"},
    {"timestamp_mmss":"03:38","severity":"medium","event_type":"ppe_violation","event_type_label":"ไม่ใส่อุปกรณ์ PPE","description":"Person B ไม่สวมหมวกและถุงมือ (Person A ปิดเครื่องจักร)"}
  ]
}' | python3 -m json.tool 2>/dev/null || echo "Done (no json.tool)"
