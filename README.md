# POSN Biology Exam System — Bento Grid

ระบบเว็บข้อสอบจาก `Posn .pdf` ออกแบบเป็น static HTML + Supabase โดย **ไม่ฝังข้อความ/ภาพข้อสอบซ้ำลงในแพ็กเกจ** ระบบจะอ่าน PDF ต้นฉบับที่ผู้ใช้เลือกในเบราว์เซอร์ หรืออ่านจาก URL ที่เจ้าของไฟล์กำหนดเอง แล้วใช้พิกัดใน `questions.js` แสดงเฉพาะบริเวณของแต่ละข้อ

## โครงสร้าง
- `index.html` หน้าเข้าสอบ + timer 80 นาที + random question order + autosave + result analytics
- `admin.html` หน้า admin สำหรับดู attempts / รายละเอียดผล / answer-key review queue
- `questions.js` manifest 104 ข้อ (page/crop coordinates + topic) **ไม่มีเฉลย**
- `config.js` Supabase URL/anon key + optional PDF URL
- `supabase.sql` schema, RLS/RPC, metadata 104 ข้อ, answer keys ฝั่งฐานข้อมูล

## จำนวนข้อ
ระบบมี 104 question instances เพราะเอกสารมีเลขข้อ 1 ซ้ำ 2 รายการ และหัวข้อ 81 แยกเป็น 81.1–81.4 ระบบเก็บ `source_label` ไว้เพื่ออ้างอิงเลขต้นฉบับ แต่หน้าสอบจะแสดงลำดับ 1–104 หลังสุ่ม

## Setup
1. สร้าง Supabase project แล้วเปิด SQL Editor
2. รัน `supabase.sql`
3. แก้ `config.js` ใส่ `SUPABASE_URL` และ `SUPABASE_ANON_KEY`
4. ถ้าต้องการให้ผู้สอบไม่ต้องเลือก PDF เอง ให้อัปโหลด PDF ต้นฉบับในพื้นที่ที่คุณมีสิทธิ์ใช้งาน แล้วใส่ URL ใน `SOURCE_PDF_URL`; หากเว้นว่าง ผู้สอบจะเลือกไฟล์ PDF จากเครื่องและไฟล์จะไม่ถูกอัปโหลดไป Supabase
5. เปิด `index.html` ผ่าน static hosting เช่น GitHub Pages / Netlify / Vercel
6. สำหรับ admin: สร้างผู้ใช้ใน Supabase Auth แล้วรัน `insert into public.exam_admins(user_id) values ('UUID ของผู้ใช้');` จากนั้นล็อกอินที่ `admin.html`

## กติกา/ความปลอดภัยของระบบ
- เวลา 4,800 วินาที (1:20:00) บันทึก `started_at` ฝั่ง server
- ลำดับข้อสร้างด้วย `order by random()` ใน RPC `start_exam`
- answer key อยู่ใน schema `private` และไม่ถูกส่งให้ browser
- base tables เปิด RLS และไม่ให้ anon อ่าน/เขียนโดยตรง; นักเรียนใช้ SECURITY DEFINER RPC เท่านั้น
- client token เก็บในฐานข้อมูลแบบ SHA-256 hash
- เปลี่ยนแท็บ: เก็บ count เพื่อดูใน admin แต่ไม่ตัดคะแนนอัตโนมัติ
- ไม่สลับตัวเลือก เพราะตัวเลือก ก–ง เป็นส่วนหนึ่งของภาพจากต้นฉบับ

## Topic analysis (11 หมวด)
- ทักษะวิทยาศาสตร์และสารชีวโมเลกุล
- ชีววิทยาเซลล์และการลำเลียงผ่านเยื่อหุ้ม
- การหายใจระดับเซลล์และเมแทบอลิซึม
- พันธุศาสตร์และสารพันธุกรรม
- สรีรวิทยาสัตว์และมนุษย์
- ภูมิคุ้มกัน ระบบประสาท และประสาทสัมผัส
- โครงสร้าง การสืบพันธุ์ และกายวิภาคพืช
- การสังเคราะห์ด้วยแสงและสรีรวิทยาพืช
- จุลชีววิทยา โพรทิสต์ และฟังไจ
- ความหลากหลาย อนุกรมวิธาน และวิวัฒนาการ
- นิเวศวิทยาและประชากร

## Answer-key review flags
มี 3 ข้อที่ตั้ง `key_status='review'` เพื่อให้ตรวจทานกับเฉลยสถาบันก่อนใช้สอบจริง: ข้อ 55, 81.3 และ 85. ระบบมีค่าเริ่มต้นให้แล้วและยังคำนวณคะแนนได้ตามปกติ สามารถแก้ได้ด้วย SQL เช่น:

```sql
update private.exam_answer_keys set correct_option='A', key_status='checked', review_note=null where question_id=...;
```

ดู mapping `question_id` ↔ `source_label` ได้จาก `public.exam_questions` ใน SQL Editor (ใช้ service/admin context)

## หมายเหตุ
ถ้า `config.js` ยังเป็น placeholder ระบบจะเข้า DEMO MODE เพื่อทดสอบ UI และการ render PDF แต่จะไม่คำนวณคะแนน เพราะเฉลยถูกเก็บเฉพาะฝั่ง Supabase เพื่อไม่ให้เปิดดูจาก source code หน้าเว็บได้
