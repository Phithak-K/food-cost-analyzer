# Menu Engineering & Food Costing Platform (Monorepo)

ระบบวิเคราะห์เมนูอาหารและคำนวณต้นทุนอาหารอัจฉริยะ (Menu Engineering & Food Costing Web Platform) มาพร้อมระบบจำลองสถานการณ์ต้นทุน (What-If Cost Simulation), ระบบขายหน้าร้าน (POS) ตัดสต็อกวัตถุดิบอัตโนมัติตามสูตร (BOM), หน้าจอแสดงผลห้องครัว (KDS), และระบบควบคุมสิทธิ์ตามบทบาท (RBAC) ด้วยรหัสความปลอดภัย PIN 4 หลัก

---

## สารบัญ (Table of Contents)
1. [ภาพรวมฟีเจอร์เด่น (Key Features)](#ภาพรวมฟีเจอร์เด่น-key-features)
2. [สิทธิ์ผู้ใช้งานและรหัส PIN (Roles & Security PIN)](#สิทธิ์ผู้ใช้งานและรหัส-pin-roles--security-pin)
3. [โครงสร้างโปรเจกต์ (Monorepo Architecture)](#โครงสร้างโปรเจกต์-monorepo-architecture)
4. [สรุปรวมคำสั่งทั้งหมด (Consolidated Commands Cheat Sheet)](#สรุปรวมคำสั่งทั้งหมด-consolidated-commands-cheat-sheet)
   - [ขั้นตอนเริ่มต้นใช้งานแบบด่วน (Quick Start Guide)](#ขั้นตอนเริ่มต้นใช้งานแบบด่วน-quick-start-guide)
   - [คำสั่งสำหรับฐานข้อมูล (Database Commands)](#คำสั่งสำหรับฐานข้อมูล-database-commands)
   - [คำสั่งสำหรับ Backend Server](#คำสั่งสำหรับ-backend-server)
   - [คำสั่งสำหรับ Frontend (Flutter Web)](#คำสั่งสำหรับ-frontend-flutter-web)
   - [คำสั่งรันชุดทดสอบ (Automated Testing)](#คำสั่งรันชุดทดสอบ-automated-testing)
5. [การแก้ไขปัญหาที่พบบ่อย (Troubleshooting & FAQs)](#การแก้ไขปัญหาที่พบบ่อย-troubleshooting--faqs)
6. [ตาราง API Endpoints ทั้งหมด (Backend API Reference)](#ตาราง-api-endpoints-ทั้งหมด-backend-api-reference)

---

## ภาพรวมฟีเจอร์เด่น (Key Features)

- **Kasavana & Smith 4 Quadrants Menu Matrix**: วิเคราะห์ความนิยม (Popularity) และกำไรส่วนเกิน (Contribution Margin) แบ่งเมนูเป็น **Stars**, **Plowhorses**, **Puzzles**, และ **Dogs** พร้อมข้อเสนอแนะเชิงกลยุทธ์
- **BOM (Bill of Materials) Recipe Costing**: คำนวณต้นทุนต่อจานอย่างแม่นยำ รองรับหน่วยชั่งตวงวัด (g, kg, ml, L, ฟอง) และ Yield Loss %
- **What-If Cost Impact Simulation**: แซนด์บ็อกซ์จำลองผลกระทบเมื่อราคาวัตถุดิบผันผวน ปรับเปลี่ยนสัดส่วนสูตร หรือเปลี่ยนราคาขายแบบ Real-Time
- **Point of Sale (POS) & Automated Inventory Deduction**: แคชเชียร์รับออเดอร์หน้าร้าน และระบบตัดสต็อกวัตถุดิบย่อยระดับกรัม/มิลลิลิตรทันที
- **Kitchen Display System (KDS) & Real-Time WebSockets**: หน้าจอคิวออเดอร์สำหรับห้องครัว เมื่อแคชเชียร์กดยืนยันออเดอร์ที่ POS บิลจะเด้งขึ้นหน้าจอครัวทันทีผ่าน WebSocket (`ws://localhost:5000/ws`) พร้อมเสียงกระดิ่งเตือนเชฟ (Bell Chime "Ding!") โดยไม่ต้องกดรีเฟรชหน้าจอ
- **Role-Based Access Control (RBAC) & 4-Digit PIN Security**: แถบสลับบทบาทรวดเร็ว พร้อมระบบล็อกหน้าจอที่มีความสำคัญสูงด้วยรหัสผ่าน PIN 4 หลัก
- **Financial & BOM Export**: ส่งออกรายงานทั้งในรูปแบบไฟล์ PDF และ CSV/Excel

---

## สิทธิ์ผู้ใช้งานและรหัส PIN (Roles & Security PIN)

ระบบจำลองการทำงานของร้านอาหารจริง โดยแบ่งบทบาทออกเป็น 3 ระดับ:

| บทบาท (Role) | สิทธิ์การเข้าถึง | พฤติกรรมหน้าจอ | รหัสผ่าน PIN |
|---|---|---|:---:|
| **ผู้จัดการร้าน (Manager)** | เข้าถึงได้ทุกฟังก์ชัน (Dashboard, Stock, Recipes, Simulation, Orders, POS, KDS) | ปลดล็อกทุกเมนู | ไม่ต้องใส่ PIN |
| **พนักงานแคชเชียร์ (Cashier)** | เข้าถึงหน้า **POS (ขายหน้าร้าน)** และ **Orders (ประวัติออเดอร์)** | เมนูอื่น (สต็อก/สูตร/แดชบอร์ด/ซิมูเลชัน) จะล็อกด้วยกุญแจ 🔒 | `1234` |
| **พนักงานครัว (Kitchen Staff)** | เข้าถึงหน้า **KDS (หน้าจอคิวครัว)** | เมนูอื่นทั้งหมดจะล็อกด้วยกุญแจ 🔒 | `1234` |

> **หมายเหตุ**: หากพนักงานแคชเชียร์หรือครัวต้องการเข้าถึงหน้าเมนูของผู้จัดการ สามารถกดที่เมนูดังกล่าวแล้วกรอกรหัส **`1234`** เพื่อปลดล็อกเข้าใช้งานได้ทันที

---

## โครงสร้างโปรเจกต์ (Monorepo Architecture)

```text
my_first_app/
│
├── frontend/                        # [หน้าบ้าน] Flutter Web Application (Dart)
│   ├── lib/
│   │   ├── core/                    # App Shell, Navigation, Theme, RoleSwitcher, PIN Dialog
│   │   └── features/                # Feature-First Architecture
│   │       ├── dashboard/           # Menu Matrix Scatter Plot & Insights
│   │       ├── ingredients/         # Stock Inventory Management
│   │       ├── recipes/             # Recipe Builder & BOM Costing
│   │       ├── pos/                 # Cashier POS Order Terminal
│   │       ├── kds/                 # Kitchen Display System Queue
│   │       ├── reports/             # PDF & CSV Export Services
│   │       └── simulation/          # What-If Cost Sandbox
│   ├── test/                        # Automated Tests 49 ข้อ (Unit & Widget Tests ผ่าน 100%)
│   ├── web/                         # Web Assets & Configurations
│   └── pubspec.yaml                 # Flutter Dependencies
│
├── backend/                         # [หลังบ้าน] Node.js Express REST API (TypeScript)
│   ├── src/
│   │   ├── routes/                  # Ingredients, Recipes, Orders, Analytics
│   │   ├── services/                # Calculator, Orders & BOM Deduction, Simulation
│   │   ├── utils/                   # Unit Converter (g <-> kg, ml <-> L, count)
│   │   ├── prisma.ts                # PrismaClient Singleton
│   │   └── index.ts                 # Express Server Entrypoint (Port 5000, CORS)
│   ├── prisma/
│   │   ├── schema.prisma            # PostgreSQL Database Schema
│   │   ├── migrations/              # Database Migration History
│   │   └── seed.ts                  # ข้อมูลตั้งต้นวัตถุดิบและสูตรอาหารไทย
│   ├── docker-compose.yml           # PostgreSQL 16 (Port 5433:5432)
│   └── package.json                 # Node.js Dependencies & NPM Scripts
│
└── README.md                        # คู่มือการติดตั้งและสรุปรวมคำสั่ง
```

---

## สรุปรวมคำสั่งทั้งหมด (Consolidated Commands Cheat Sheet)

### ขั้นตอนเริ่มต้นใช้งานแบบด่วน (Quick Start Guide)

เปิด **Terminal 2 หน้าต่าง (หรือ 2 แท็บ)**:

#### 🟢 หน้าต่างที่ 1: รันหลังบ้าน (Backend & Database)
```bash
# 1. เข้าโฟลเดอร์ backend
cd d:\CS67\my_first_app\backend

# 2. เปิดฐานข้อมูล PostgreSQL (Docker)
npm run db:up

# 3. ซิงค์ฐานข้อมูลและลงข้อมูลตั้งต้น (รันเฉพาะครั้งแรก หรือเมื่อต้องการรีเซ็ตข้อมูล)
npx prisma db push
npm run prisma:seed

# 4. เริ่มต้นเซิร์ฟเวอร์ Backend
npm run dev
```
*(Backend จะรันอยู่ที่: `http://localhost:5000`)*

---

#### 🔵 หน้าต่างที่ 2: รันหน้าบ้าน (Frontend - Flutter Web)
```bash
# 1. เข้าโฟลเดอร์ frontend
cd d:\CS67\my_first_app\frontend

# 2. ดาวน์โหลดแพ็กเกจ (รันครั้งแรก)
flutter pub get

# 3. เปิดเว็บแอปพลิเคชันบนเบราว์เซอร์ Chrome
flutter run -d chrome
```

---

### คำสั่งสำหรับฐานข้อมูล (Database Commands)

ทำงานที่พาธ `my_first_app/backend`:

| คำสั่ง | คำอธิบาย |
|---|---|
| `npm run db:up` | สั่งเปิดคอนเทนเนอร์ PostgreSQL 16 ผ่าน Docker ในโหมดเบื้องหลัง (`-d`) |
| `npm run db:down` | สั่งหยุดและปิดคอนเทนเนอร์ฐานข้อมูล PostgreSQL |
| `docker ps` | ตรวจสอบสถานะว่าคอนเทนเนอร์ `foodcost_postgres` กำลังทำงานอยู่หรือไม่ (พอร์ต `5433`) |
| `npx prisma db push` | ซิงค์โครงสร้างตารางจาก `schema.prisma` เข้าสู่ PostgreSQL ทันที |
| `npm run prisma:seed` | นำเข้าข้อมูลตัวอย่าง (วัตถุดิบ 11 รายการ, เมนู 4 ควอดรันต์ และออเดอร์เริ่มต้น) |
| `npx prisma studio` | เปิดหน้าเว็บ UI กราฟิกจัดการดู/แก้ไขข้อมูลใน Database (`http://localhost:5555`) |

---

### คำสั่งสำหรับ Backend Server

ทำงานที่พาธ `my_first_app/backend`:

| คำสั่ง | คำอธิบาย |
|---|---|
| `npm run dev` | เริ่มต้น Backend API Server ด้วย `ts-node` (Port 5000) |
| `npm run server:dev` | คำสั่งทางเลือกสำหรับเปิด Backend Server |
| `npm test` | รันชุด Automated Unit Tests ของ Backend (ตรวจสอบการคำนวณหน่วยและตัดสต็อก BOM) |
| `npm run build` | ตรวจสอบความถูกต้องของ Type ใน TypeScript ทั้งโปรเจกต์ (`tsc --noEmit`) |

---

### คำสั่งสำหรับ Frontend (Flutter Web)

ทำงานที่พาธ `my_first_app/frontend`:

| คำสั่ง | คำอธิบาย |
|---|---|
| `flutter pub get` | ดาวน์โหลดและอัปเดตไลบรารีทั้งหมดใน `pubspec.yaml` |
| `flutter run -d chrome` | รันแอปพลิเคชันบน Google Chrome พร้อมระบบ Hot Reload |
| `flutter run -d chrome --web-port=8080` | รันบนเว็บโดยล็อกพอร์ตให้อยู่ที่ 8080 เสมอ |
| `flutter analyze` | ตรวจสอบคุณภาพโค้ด Dart และกฎเกณฑ์ Linter (0 issues) |
| `flutter build web --release` | บิลด์ไฟล์ Production สำหรับนำไป Deploy บนโฮสติ้งจริง |

---

### คำสั่งรันชุดทดสอบ (Automated Testing)

#### 1. ทดสอบส่วนหลังบ้าน (Backend - 8 ข้อ)
```bash
cd backend
npm test
```
*ครอบคลุม: การแปลงหน่วยกรัม/กิโลกรัม/ลิตร, การคำนวณ Yield %, โครงสร้าง Error เมื่อสต็อกไม่พอ, และการตัดสต็อกวัตถุดิบ BOM*

#### 2. ทดสอบส่วนหน้าบ้าน (Frontend - 49 ข้อ)
```bash
cd frontend
flutter test
```
*ครอบคลุม: Smoke Test, Unit Test, Widget Test, การจำลองสถานการณ์ What-If, การ Export รายงาน, สิทธิ์บทบาทผู้ใช้งาน (RBAC), และการเปิดเมนูบนหน้าจอมือถือโดยไม่เกิดข้อผิดพลาด Scaffold*

---

## การแก้ไขปัญหาที่พบบ่อย (Troubleshooting & FAQs)

### 1. Docker แจ้งเตือน: `Conflict. The container name "/foodcost_postgres" is already in use`
- **สาเหตุ**: คอนเทนเนอร์ PostgreSQL ถูกเปิดทำงานอยู่แล้วในเครื่อง
- **วิธีแก้**: ไม่ต้องทำอะไรเพิ่ม หรือรันคำสั่ง `docker ps` เพื่อดูสถานะ หากพบว่าสถานะเป็น `Up (healthy)` ที่พอร์ต `5433` แสดงว่าฐานข้อมูลพร้อมทำงานอยู่แล้ว สามารถรัน `npm run dev` ได้ทันที

### 2. รัน `npm run dev` แล้วแจ้ง `Missing script: "dev"`
- **วิธีแก้**: ในเวอร์ชันปัจจุบันได้เพิ่ม `"dev": "ts-node src/index.ts"` ลงใน `backend/package.json` เรียบร้อยแล้ว สามารถพิมพ์ `npm run dev` หรือ `npm run server:dev` ได้ทั้งสองแบบ

### 3. ตารางในฐานข้อมูลไม่ตรง หรือฟ้องว่า Table does not exist
- **วิธีแก้**: รันคำสั่งซิงค์ Schema ใหม่ด้วย:
  ```bash
  cd backend
  npx prisma db push
  npm run prisma:seed
  ```

### 4. บนหน้าจอมือถือ/หน้าจอเล็ก กดปุ่มเมนูด้านบนแล้วขึ้น Error `Scaffold.of()`
- **การแก้ไข**: โค้ดใน [app_shell.dart](file:///d:/CS67/my_first_app/frontend/lib/core/widgets/app_shell.dart) ได้รับการครอบด้วย `Builder` เพื่อส่ง Context ใต้ `Scaffold` แล้ว ทำให้เปิด Drawer ได้ลื่นไหล 100% ไม่มีข้อผิดพลาด

---

## ตาราง API Endpoints ทั้งหมด (Backend API Reference)

Base URL: `http://localhost:5000/api`

| หมวดหมู่ | Method | Endpoint | คำอธิบายการทำงาน |
|---|---|---|---|
| **Health** | `GET` | `/health` | ตรวจสอบสถานะการเชื่อมต่อ Server และ Database |
| **Ingredients** | `GET` | `/ingredients` | ดึงรายการวัตถุดิบทั้งหมด ปริมาณคงเหลือ และราคาต่อหน่วย |
| | `POST` | `/ingredients` | เพิ่มวัตถุดิบใหม่เข้าคลัง (คำนวณ Base Unit Cost อัตโนมัติ) |
| | `PUT` | `/ingredients/:id` | แก้ไขข้อมูลวัตถุดิบหรือปรับปรุงราคาซื้อ |
| | `DELETE` | `/ingredients/:id` | ลบวัตถุดิบที่ไม่ใช้งานออกจากระบบ |
| **Recipes** | `GET` | `/recipes` | ดึงรายการสูตรอาหารทั้งหมด พร้อมส่วนผสม BOM |
| | `POST` | `/recipes` | สร้างสูตรอาหารใหม่พร้อมส่วนผสมและสัดส่วน Yield |
| | `GET` | `/recipes/:id/cost-breakdown` | แจกแจงต้นทุนวัตถุดิบแต่ละชนิดต่อจาน และ % Food Cost |
| **Orders** | `GET` | `/orders` | ดึงประวัติรายการสั่งซื้อทั้งหมดล่าสุด |
| | `GET` | `/orders/:id` | ดูรายละเอียดรายการสั่งซื้อรายออเดอร์ |
| | `POST` | `/orders` | บันทึกออเดอร์ใหม่จาก POS พร้อมตัดสต็อกวัตถุดิบ (BOM) ในคลังทันที |
| **Analytics** | `GET` | `/analytics/menu-matrix` | คำนวณ Kasavana & Smith Matrix จัดหมวด 4 Quadrants |
| **Simulation** | `POST` | `/analytics/simulate-cost` | ประมวลผล What-If Sandbox จำลองการเปลี่ยนแปลงต้นทุน |
