# Menu Engineering & Food Costing (Monorepo)

ระบบวิเคราะห์เมนูอาหารและคำนวณต้นทุนอาหารอัจฉริยะ (Menu Engineering & Food Costing Web Platform) พร้อมระบบจำลองสถานการณ์ต้นทุน (What-If Cost Simulation)

---

## โครงสร้างโปรเจกต์ (Monorepo Architecture)

โปรเจกต์นี้แยกโครงสร้างออกเป็น 2 ส่วนหลักอย่างชัดเจน:

```
my_first_app/
│
├── frontend/                        # [หน้าบ้าน] Flutter Web Application
│   ├── lib/
│   │   ├── core/                    # Theme, Router (GoRouter), Utils, Layout Shell
│   │   └── features/                # ฟังก์ชันทางธุรกิจ (Feature-First Clean Architecture)
│   │       ├── dashboard/           # Menu Matrix Scatter Plot & Actionable Insights
│   │       ├── ingredients/         # การจัดการวัตถุดิบ & คลัง (BOM Base Unit Costing)
│   │       ├── recipes/             # Recipe Builder & Live Cost Calculation
│   │       ├── reports/             # Export รายงาน PDF & Excel/CSV (BOM)
│   │       └── simulation/          # What-If Cost Impact Sandbox (Sliders & Comparison)
│   ├── test/                        # ชุด Automated Test 18 ข้อ (Unit & Widget Tests)
│   ├── web/                         # เว็บ Assets, index.html, Favicon
│   └── pubspec.yaml                 # Flutter Dependencies
│
├── backend/                         # [หลังบ้าน] REST API & Database Service
│   ├── src/
│   │   ├── routes/                  # REST Endpoints (ingredients, recipes, analytics)
│   │   ├── services/                # Calculator Service & Simulation Service
│   │   ├── utils/                   # Unit Converter
│   │   ├── prisma.ts                # PrismaClient Singleton Instance
│   │   └── index.ts                 # Express Server Entrypoint (Port 5000, CORS enabled)
│   ├── prisma/
│   │   ├── schema.prisma            # PostgreSQL Database Schema
│   │   ├── migrations/              # Database Migration History
│   │   └── seed.ts                  # ข้อมูลตั้งต้นวัตถุดิบไทย 11 ชนิด และเมนู 4 Quadrants
│   ├── docker-compose.yml           # PostgreSQL 16 (Port 5433:5432)
│   ├── package.json                 # Node.js Dependencies & Scripts
│   ├── tsconfig.json                # TypeScript Configuration
│   └── .env.example                 # แม่แบบการตั้งค่า Database Connection
│
└── README.md                        # เอกสารแนะนำและคู่มือการรันโปรเจกต์
```

---

## วิธีการติดตั้งและรันโปรเจกต์

### 1. รันส่วนหลังบ้าน (Backend & Database)
```bash
# 1.1 เข้าสู่โฟลเดอร์ backend
cd backend

# 1.2 ติดตั้ง Dependencies
npm install

# 1.3 เปิดฐานข้อมูล PostgreSQL ผ่าน Docker (Port 5433)
npm run db:up

# 1.4 ซิงค์ Schema และใส่ข้อมูลเริ่มต้น (Seed Data)
npm run prisma:migrate
npm run prisma:seed

# 1.5 เริ่มต้น REST API Server (Port 5000)
npm run server:dev
```
- ตรวจสอบสถานะ API: [http://localhost:5000/api/health](http://localhost:5000/api/health)

---

### 2. รันส่วนหน้าบ้าน (Frontend - Flutter Web)
```bash
# 2.1 เข้าสู่โฟลเดอร์ frontend
cd frontend

# 2.2 ติดตั้ง Flutter Dependencies
flutter pub get

# 2.3 รันชุดทดสอบ (18/18 ผ่าน 100%)
flutter test

# 2.4 เปิดเว็บแอปพลิเคชันบน Chrome
flutter run -d chrome
```

---

## สรุป API Endpoints

| หมวด | Method | Endpoint | หน้าที่ |
|---|---|---|---|
| **Health** | `GET` | `/api/health` | ตรวจสอบสถานะ Server |
| **Ingredients** | `GET, POST` | `/api/ingredients` | จัดการข้อมูลวัตถุดิบและต้นทุน Base Unit |
| **Ingredients** | `PUT, DELETE`| `/api/ingredients/:id` | ปรับปรุงราคาซื้อ/ลบวัตถุดิบ |
| **Recipes** | `GET, POST` | `/api/recipes` | จัดการสูตรอาหารและส่วนประกอบ (BOM) |
| **Costing** | `GET` | `/api/recipes/:id/cost-breakdown` | แจกแจงต้นทุนต่อจานและ % Food Cost |
| **Analytics** | `GET` | `/api/analytics/menu-matrix` | Kasavana & Smith 4 Quadrants Matrix |
| **Simulation** | `POST` | `/api/analytics/simulate-cost` | What-If Cost Impact Simulation Sandbox |
