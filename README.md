# Vet Scheduler — Setup & Deploy Guide

## What this is
A Node.js/Express backend with a PostgreSQL database that powers the vet staff scheduling app. The frontend HTML file is served from this same server.

---

## Local Setup (test before deploying)

### 1. Install prerequisites
- [Node.js 18+](https://nodejs.org) — download and install
- [PostgreSQL](https://www.postgresql.org/download/) — install and start the service

### 2. Clone / copy this project
Put this folder somewhere on your computer, then open a terminal in it.

### 3. Install dependencies
```bash
npm install
```

### 4. Create your local database
```bash
psql -U postgres
```
Then in the psql prompt:
```sql
CREATE DATABASE vet_scheduler;
\q
```

### 5. Run the schema and seed data
```bash
psql -U postgres -d vet_scheduler -f db/schema.sql
psql -U postgres -d vet_scheduler -f db/seed.sql
```

### 6. Set up your environment file
```bash
cp .env.example .env
```
Edit `.env` and set:
```
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/vet_scheduler
NODE_ENV=development
```

### 7. Copy the frontend into the public folder
```bash
mkdir -p public
# Copy your vet-tech.html file into public/ and rename it index.html
cp /path/to/vet-tech-v12.html public/index.html
```

### 8. Start the server
```bash
npm run dev
```
Open your browser to `http://localhost:3000` — the app should load.

---

## Deploy to Railway

### Step 1 — Create a Railway account
Go to [railway.app](https://railway.app) and sign up (free).

### Step 2 — Create a new project
1. Click **New Project**
2. Choose **Deploy from GitHub repo** (or **Empty project** if not using Git)

### Step 3 — Add a PostgreSQL database
1. In your Railway project, click **+ New**
2. Choose **Database → PostgreSQL**
3. Railway will create the database and show you the connection details

### Step 4 — Get your DATABASE_URL
1. Click on the PostgreSQL service
2. Go to the **Variables** tab
3. Copy the `DATABASE_URL` value — it looks like:
   `postgresql://postgres:abc123@containers-us-west-1.railway.app:5432/railway`

### Step 5 — Run schema and seed on Railway
In the PostgreSQL service on Railway, click **Connect** and use the provided connection string with psql:
```bash
psql "postgresql://postgres:abc123@containers-us-west-1.railway.app:5432/railway" -f db/schema.sql
psql "postgresql://postgres:abc123@containers-us-west-1.railway.app:5432/railway" -f db/seed.sql
```

### Step 6 — Deploy the Node.js app
**Option A — GitHub (recommended):**
1. Push this folder to a GitHub repo
2. In Railway, click **+ New → GitHub Repo**
3. Select your repo — Railway auto-detects Node.js and deploys

**Option B — Railway CLI:**
```bash
npm install -g @railway/cli
railway login
railway link   # link to your project
railway up     # deploy
```

### Step 7 — Set environment variables
In your Node.js service on Railway:
1. Go to **Variables**
2. Add:
   - `DATABASE_URL` = (paste from Step 4)
   - `NODE_ENV` = `production`

### Step 8 — Add the frontend
Copy your `vet-tech-v12.html` into `public/index.html` and redeploy.

### Step 9 — Get your URL
Railway gives you a public URL like `https://vet-scheduler-production.up.railway.app`
Share this with staff — they open it in any browser, no install needed.

---

## Cost on Railway
- **Hobby plan**: $5/month — includes 512MB RAM, shared CPU, 1GB PostgreSQL
- **Pro plan**: $20/month — more resources if needed
- For a small vet practice, the Hobby plan is more than sufficient

---

## Migrating to your own server later
When your tech company is ready:
1. Install Node.js and PostgreSQL on the server
2. Copy this entire folder to the server
3. Run `npm install`
4. Run schema.sql and seed.sql against the new PostgreSQL instance
5. Set up `.env` with the local DATABASE_URL
6. Use PM2 to keep the app running: `npm install -g pm2 && pm2 start server.js`
7. The code is **identical** — just a different server running it

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/employees` | All staff + skills + availability |
| POST | `/api/employees` | Create employee |
| PUT | `/api/employees/:id` | Update employee |
| PUT | `/api/employees/:id/skills` | Replace all skills |
| PUT | `/api/employees/:id/avail` | Replace availability blocks |
| GET | `/api/templates` | All templates + days |
| POST | `/api/templates` | Create template |
| PATCH | `/api/templates/:id` | Rename template |
| DELETE | `/api/templates/:id` | Delete template |
| PUT | `/api/templates/:id/days/:dow` | Update one day of a template |
| GET | `/api/schedule/weeks` | Week → template assignments |
| PUT | `/api/schedule/weeks` | Save week assignment |
| GET | `/api/schedule/overrides/week/:weekStart` | Doctor out-days for a week |
| PUT | `/api/schedule/overrides/week/:weekStart` | Save doctor out-days |
| DELETE | `/api/schedule/overrides/week/:weekStart` | Clear week overrides |
| GET | `/api/schedule/day-overrides` | All day-level area toggles |
| PUT | `/api/schedule/day-overrides` | Save day override |
| GET | `/api/schedule/assignments/:date` | Staff assignments for a date |
| PUT | `/api/schedule/assignments/:date` | Save assignments for a date |
| GET | `/api/rules` | All area demand rules |
| PUT | `/api/rules/:id` | Update a rule |
| GET | `/health` | Server health check |
