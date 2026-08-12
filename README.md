# Netherlands 3PL Procurement Optimisation Model (Project STAR)

**Author:** Saquib Raza | IIT Mandi | Supply Chain & Logistics Analytics
**Stack:** SQL (PostgreSQL) · Excel · Power BI

## Business Question
Which 3PL provider should a Netherlands-based company use for European freight —
DHL Freight, DB Schenker, or Kuehne+Nagel?

## Scope
- **3 trade corridors:** Amsterdam → Frankfurt, Rotterdam → Paris, Eindhoven → Warsaw
- **3 providers compared** on cost per kg, on-time delivery %, and average lead time
- **50 shipment records**, aggregated into monthly performance history (Jan–Apr 2024)

## Headline Finding
**€112,920 in annual savings identified** by switching each corridor to its optimal
provider, on an assumed 2.4M kg annual volume (900K / 700K / 800K kg per lane).
This is a *verified* figure — recalculated directly from the Excel formulas
(`(current rate − optimal rate) × annual volume`, summed across all 3 lanes).

**Provider ranking (weighted scorecard — 40% cost / 35% reliability / 25% lead time):**
1. 🥇 DB Schenker — 100.0 score (cheapest + most reliable overall)
2. 🥈 Kuehne+Nagel — 81.9 score
3. 🥉 DHL Freight — 0.0 score (most expensive, least reliable)

**Live risk flag surfaced by the SLA-breach stored procedure:**
DHL Freight is currently **breaching SLA** on the Amsterdam→Frankfurt lane
(88.05% actual on-time delivery vs. 92% contracted threshold).

## Dashboard Pages
1. **Executive Summary** — KPIs, provider overview, headline savings
2. **Provider Comparison** — DHL Freight vs DB Schenker vs Kuehne+Nagel scorecard
3. **Trend Analysis** — monthly cost/performance trend, Jan–Apr 2024
4. **Shipment Drill-Through** — individual shipment-level detail

## Repo Structure
```
├── 3PL_Procurement_Optimisation_MySQL.sql  # ⭐ USE THIS — MySQL 8.0 version, tested and verified
├── 3PL_Procurement_Optimisation.sql   # Original PostgreSQL version (kept for reference)
├── 3PL_Procurement_Optimisation.xlsx  # Cover | Raw Data | Weighted Scorecard | Sensitivity | Savings
├── 3PL_Procurement_Optimisation_Dashboard.pbix  # Power BI report file (4 pages, see above)
├── powerbi_data/                      # CSV exports of the 3 SQL views, ready to import into Power BI
│   ├── provider_scorecard.csv
│   ├── monthly_trend.csv
│   └── shipment_detail.csv
├── STAR_Project_SQL_Queries.docx      # Annotated reference: all 7 analytical queries explained
├── What_this_Project_is_about.docx    # Project overview / refresher
├── Power_BI_Setup_Guide.md            # Step-by-step Power BI build guide (DAX measures, page layouts)
├── Interview_Prep_and_Project_Explainer.md  # STAR-format interview answers for this project
└── screenshots/                       # Power BI dashboard screenshots
    ├── Page1_Executive_Summary.png
    ├── Page2_Provider_Comparison.png
    ├── Page3_Trend_Analysis.png
    └── Page4_Shipment_DrillThrough.png
```

## How to Reproduce
1. Run `3PL_Procurement_Optimisation_MySQL.sql` in MySQL Workbench (or `mysql -u root -p < file.sql`) —
   creates the `netherlands_3pl` database, schema, seed data, and 3 Power BI views.
2. Either export the views yourself, or use the pre-exported CSVs in `powerbi_data/` (already generated
   from a live run of this exact file — no need to re-run unless you change the data).
3. Follow `Power_BI_Setup_Guide.md` to build the 4-page Power BI report (Executive Summary,
   Provider Comparison, Trend Analysis, Shipment Drill-Through).
4. Open `3PL_Procurement_Optimisation.xlsx` for the underlying scorecard math and sensitivity analysis.

## Data Sources
Freight rate benchmarks based on Freightos 2024 public benchmarks; shipment/performance
history is simulated operational data built to reflect realistic monthly variance.

## Note on MySQL vs PostgreSQL
The original file was written in PostgreSQL. Since MySQL is the target stack, a fully
tested MySQL 8.0 port (`3PL_Procurement_Optimisation_MySQL.sql`) is included — actually
run against a live MySQL 8.0 server, producing identical results to the PostgreSQL
version (same rankings, same €112,920 saving, same SLA breach finding). One MySQL-specific
fix was needed: `delayed` is a reserved keyword in MySQL, so that column alias was
renamed to `delayed_count`.

## Note on the €180K vs €112,920 figure
An earlier draft of this project cited a €180,000 headline saving. That number was
never traceable to the underlying Excel formulas. The Excel Savings sheet
(`(current rate − optimal rate) × annual volume`, summed across 3 lanes) computes to
**€112,920**, and that is the number used throughout this repo, the Power BI dashboard,
and interview prep materials.
