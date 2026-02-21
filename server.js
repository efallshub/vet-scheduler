require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const path    = require('path');
const { Pool } = require('pg');

const app  = express();
const PORT = process.env.PORT || 3000;

const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// EMPLOYEES
app.get('/api/employees', async (req, res) => {
  try {
    const emps   = await db.query('SELECT * FROM employees ORDER BY pool, name');
    const skills = await db.query('SELECT employee_id, area, level FROM skills');
    const avail  = await db.query('SELECT * FROM avail_blocks ORDER BY employee_id, start_date');
    const skillMap = {}, availMap = {};
    skills.rows.forEach(s => { if(!skillMap[s.employee_id]) skillMap[s.employee_id]={}; skillMap[s.employee_id][s.area]=s.level; });
    avail.rows.forEach(a  => { if(!availMap[a.employee_id]) availMap[a.employee_id]=[]; availMap[a.employee_id].push({id:a.id,name:a.name,start:a.start_date,end:a.end_date,days:a.days}); });
    res.json(emps.rows.map(e => ({id:e.id,pool:e.pool,name:e.name,active:e.active,ft:e.ft,maxH:e.max_hours,minH:e.min_hours,maxD:e.max_days,dbl:e.allow_dbl,skills:skillMap[e.id]||{},avail:availMap[e.id]||{}})));
  } catch(err) { res.status(500).json({error:err.message}); }
});
app.post('/api/employees', async (req, res) => {
  const {id,pool,name,active,ft,maxH,minH,maxD,dbl} = req.body;
  try { await db.query('INSERT INTO employees (id,pool,name,active,ft,max_hours,min_hours,max_days,allow_dbl) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)',[id,pool,name,active??true,ft??true,maxH,minH,maxD,dbl??false]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/employees/:id', async (req, res) => {
  const {pool,name,active,ft,maxH,minH,maxD,dbl} = req.body;
  try { await db.query('UPDATE employees SET pool=$1,name=$2,active=$3,ft=$4,max_hours=$5,min_hours=$6,max_days=$7,allow_dbl=$8,updated_at=NOW() WHERE id=$9',[pool,name,active,ft,maxH,minH,maxD,dbl,req.params.id]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/employees/:id/skills', async (req, res) => {
  const client = await db.connect();
  try { await client.query('BEGIN'); await client.query('DELETE FROM skills WHERE employee_id=$1',[req.params.id]); for(const [a,l] of Object.entries(req.body.skills)) await client.query('INSERT INTO skills (employee_id,area,level) VALUES ($1,$2,$3)',[req.params.id,a,l]); await client.query('COMMIT'); res.json({ok:true}); }
  catch(err) { await client.query('ROLLBACK'); res.status(500).json({error:err.message}); } finally { client.release(); }
});
app.put('/api/employees/:id/avail', async (req, res) => {
  const client = await db.connect();
  try { await client.query('BEGIN'); await client.query('DELETE FROM avail_blocks WHERE employee_id=$1',[req.params.id]); for(const b of req.body.blocks) await client.query('INSERT INTO avail_blocks (id,employee_id,name,start_date,end_date,days) VALUES ($1,$2,$3,$4,$5,$6)',[b.id,req.params.id,b.name,b.start,b.end||null,JSON.stringify(b.days)]); await client.query('COMMIT'); res.json({ok:true}); }
  catch(err) { await client.query('ROLLBACK'); res.status(500).json({error:err.message}); } finally { client.release(); }
});

// TEMPLATES
app.get('/api/templates', async (req, res) => {
  try {
    const tpls = await db.query('SELECT * FROM templates ORDER BY created_at');
    const days = await db.query('SELECT * FROM template_days ORDER BY template_id, dow');
    const dayMap = {};
    days.rows.forEach(d => { if(!dayMap[d.template_id]) dayMap[d.template_id]={}; dayMap[d.template_id][d.dow]={SURGERY:d.surgery,DENTAL:d.dental,SPECPROCEDURE:d.specprocedure,HOUSECALLS:d.housecalls,APPT_AM:d.appt_am,APPT_AFT:d.appt_aft,APPT_EVE:d.appt_eve}; });
    res.json(tpls.rows.map(t => ({id:t.id,name:t.name,days:dayMap[t.id]||{}})));
  } catch(err) { res.status(500).json({error:err.message}); }
});
app.post('/api/templates', async (req, res) => {
  const {id,name,copyFrom} = req.body;
  const client = await db.connect();
  try { await client.query('BEGIN'); await client.query('INSERT INTO templates (id,name) VALUES ($1,$2)',[id,name]); if(copyFrom) { await client.query('INSERT INTO template_days (template_id,dow,surgery,dental,specprocedure,housecalls,appt_am,appt_aft,appt_eve) SELECT $1,dow,surgery,dental,specprocedure,housecalls,appt_am,appt_aft,appt_eve FROM template_days WHERE template_id=$2',[id,copyFrom]); } else { for(let d=0;d<=6;d++) await client.query('INSERT INTO template_days (template_id,dow) VALUES ($1,$2)',[id,d]); } await client.query('COMMIT'); res.json({ok:true,id}); }
  catch(err) { await client.query('ROLLBACK'); res.status(500).json({error:err.message}); } finally { client.release(); }
});
app.patch('/api/templates/:id', async (req, res) => {
  try { await db.query('UPDATE templates SET name=$1,updated_at=NOW() WHERE id=$2',[req.body.name,req.params.id]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.delete('/api/templates/:id', async (req, res) => {
  try { await db.query('DELETE FROM templates WHERE id=$1',[req.params.id]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/templates/:id/days/:dow', async (req, res) => {
  const {SURGERY,DENTAL,SPECPROCEDURE,HOUSECALLS,APPT_AM,APPT_AFT,APPT_EVE} = req.body;
  try { await db.query('INSERT INTO template_days (template_id,dow,surgery,dental,specprocedure,housecalls,appt_am,appt_aft,appt_eve) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (template_id,dow) DO UPDATE SET surgery=$3,dental=$4,specprocedure=$5,housecalls=$6,appt_am=$7,appt_aft=$8,appt_eve=$9',[req.params.id,req.params.dow,JSON.stringify(SURGERY||[]),JSON.stringify(DENTAL||[]),JSON.stringify(SPECPROCEDURE||[]),JSON.stringify(HOUSECALLS||[]),JSON.stringify(APPT_AM||[]),JSON.stringify(APPT_AFT||[]),JSON.stringify(APPT_EVE||[])]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});

// SCHEDULE
app.get('/api/schedule/weeks', async (req, res) => {
  try { const r=await db.query("SELECT to_char(week_start,'MM/DD/YYYY') as ws, template_id FROM week_assignments"); const m={}; r.rows.forEach(x=>{const[mo,d,y]=x.ws.split('/');m[`${parseInt(mo)}/${parseInt(d)}/${y}`]=x.template_id;}); res.json(m); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/schedule/weeks', async (req, res) => {
  const {weekStart,templateId}=req.body;
  try { if(!templateId){await db.query('DELETE FROM week_assignments WHERE week_start=$1',[weekStart]);}else{await db.query('INSERT INTO week_assignments (week_start,template_id) VALUES ($1,$2) ON CONFLICT (week_start) DO UPDATE SET template_id=$2',[weekStart,templateId]);} res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.get('/api/schedule/overrides/week/:ws', async (req, res) => {
  try { const r=await db.query('SELECT doc_init,out_days FROM week_doc_overrides WHERE week_start=$1',[req.params.ws]); const m={}; r.rows.forEach(x=>{m[x.doc_init]=x.out_days;}); res.json(m); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/schedule/overrides/week/:ws', async (req, res) => {
  const {docInit,outDays}=req.body;
  try { if(!outDays||!outDays.length){await db.query('DELETE FROM week_doc_overrides WHERE week_start=$1 AND doc_init=$2',[req.params.ws,docInit]);}else{await db.query('INSERT INTO week_doc_overrides (week_start,doc_init,out_days) VALUES ($1,$2,$3) ON CONFLICT (week_start,doc_init) DO UPDATE SET out_days=$3',[req.params.ws,docInit,JSON.stringify(outDays)]);} res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.delete('/api/schedule/overrides/week/:ws', async (req, res) => {
  try { await db.query('DELETE FROM week_doc_overrides WHERE week_start=$1',[req.params.ws]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.get('/api/schedule/day-overrides', async (req, res) => {
  try { const r=await db.query("SELECT to_char(date,'MM/DD/YYYY') as d,area,shift,active FROM day_overrides"); const m={}; r.rows.forEach(x=>{const[mo,dy,y]=x.d.split('/');const k=`${parseInt(mo)}/${parseInt(dy)}/${y}`;if(!m[k])m[k]={};m[k][`${x.area}_${x.shift}`]=x.active;}); res.json(m); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/schedule/day-overrides', async (req, res) => {
  const {date,area,shift,active}=req.body;
  try { await db.query('INSERT INTO day_overrides (date,area,shift,active) VALUES ($1,$2,$3,$4) ON CONFLICT (date,area,shift) DO UPDATE SET active=$4',[date,area,shift,active]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.get('/api/schedule/assignments/:date', async (req, res) => {
  try { const r=await db.query('SELECT employee_id,area,shift FROM assignments WHERE date=$1',[req.params.date]); const m={}; r.rows.forEach(x=>{const k=`${x.area}_${x.shift}`;if(!m[k])m[k]=[];m[k].push(x.employee_id);}); res.json(m); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/schedule/assignments/:date', async (req, res) => {
  const client=await db.connect();
  try { await client.query('BEGIN'); await client.query('DELETE FROM assignments WHERE date=$1',[req.params.date]); for(const [key,ids] of Object.entries(req.body.assignments)){const[area,shift]=key.split('_');for(const id of ids)await client.query('INSERT INTO assignments (date,employee_id,area,shift) VALUES ($1,$2,$3,$4)',[req.params.date,id,area,shift]);} await client.query('COMMIT'); res.json({ok:true}); }
  catch(err) { await client.query('ROLLBACK'); res.status(500).json({error:err.message}); } finally { client.release(); }
});

// RULES
app.get('/api/rules', async (req, res) => {
  try { const r=await db.query('SELECT * FROM area_rules ORDER BY sort_order, id'); res.json(r.rows.map(x=>({id:x.id,area:x.area,shift:x.shift,pool:x.pool,type:x.type,source:x.source,mult:parseFloat(x.mult),round:x.round_mode,role:x.role,active:x.active,days:x.days,_sectionBreak:x.section_break,note:x.note}))); }
  catch(err) { res.status(500).json({error:err.message}); }
});
app.put('/api/rules/:id', async (req, res) => {
  const {area,shift,pool,type,source,mult,round,role,active,days,note}=req.body;
  try { await db.query('UPDATE area_rules SET area=$1,shift=$2,pool=$3,type=$4,source=$5,mult=$6,round_mode=$7,role=$8,active=$9,days=$10,note=$11 WHERE id=$12',[area,shift,pool||null,type,source||null,mult,round,role,active,JSON.stringify(days),note||null,req.params.id]); res.json({ok:true}); }
  catch(err) { res.status(500).json({error:err.message}); }
});

// HEALTH + CATCH-ALL
app.get('/health', (req, res) => res.json({ok:true}));
app.get('*', (req, res) => res.sendFile(path.join(__dirname,'public','index.html')));

app.listen(PORT, () => console.log(`Vet Scheduler running on port ${PORT}`));
