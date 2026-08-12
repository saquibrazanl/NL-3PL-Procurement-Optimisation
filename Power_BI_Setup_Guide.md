# POWER BI SETUP GUIDE
## Netherlands 3PL Procurement Optimisation Model
### Saquib Raza | Supply Chain Analytics Portfolio

---

## HOW THE THREE FILES CONNECT

```
SQL (PostgreSQL)
     │
     ├─── Runs schema + seed data
     ├─── Creates 3 Views (vw_provider_scorecard, vw_monthly_trend, vw_shipment_detail)
     │
     ▼
Export Views as CSV  ──────►  Power BI Desktop
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
              Import CSVs                  Import Excel file
              (3 tables)              (Raw Data sheet as table)
                     │
                     ▼
              Build Data Model → DAX Measures → Visuals
```

**The professional story you tell:** *"I designed a relational database in SQL to store provider performance data, used Excel for the weighted scorecard and sensitivity analysis, then connected both to Power BI for executive-level reporting."*

---

## STEP 1 — EXPORT SQL VIEWS TO CSV

Run these in pgAdmin or DBeaver after executing the .sql file:

```sql
-- Export 1: Provider Scorecard
COPY (SELECT * FROM vw_provider_scorecard) TO 'C:/3PL_Project/data/provider_scorecard.csv' CSV HEADER;

-- Export 2: Monthly Trend
COPY (SELECT * FROM vw_monthly_trend) TO 'C:/3PL_Project/data/monthly_trend.csv' CSV HEADER;

-- Export 3: Shipment Detail
COPY (SELECT * FROM vw_shipment_detail) TO 'C:/3PL_Project/data/shipment_detail.csv' CSV HEADER;
```

If COPY permissions are restricted, use: Right-click query result → Export → CSV in DBeaver.

---

## STEP 2 — LOAD DATA INTO POWER BI

1. Open **Power BI Desktop** (free from Microsoft)
2. Click **Get Data → Text/CSV**
3. Import all three CSV files
4. Also import the Excel file: **Get Data → Excel → Sheet: 📊 Raw Data**

### Power Query Transformations (do these before closing Power Query):

**For provider_scorecard.csv:**
- Change `avg_cost_per_kg` → Decimal Number
- Change `avg_on_time_pct` → Decimal Number
- Change `sla_breach_months` → Whole Number

**For monthly_trend.csv:**
- Change `month_year` → Date (format: YYYY-MM-DD)
- Change `on_time_pct`, `avg_cost_per_kg`, `avg_lead_time_days` → Decimal Number

**For shipment_detail.csv:**
- Change `shipment_date`, `promised_delivery`, `actual_delivery` → Date
- Change `delay_days` → Whole Number
- Change `total_cost_eur`, `actual_cost_per_kg` → Decimal Number

---

## STEP 3 — DATA MODEL (Relationships)

In the **Model View**, create these relationships:

```
provider_scorecard [provider_name + lane]
       │
       │  (many-to-many via lane)
       ▼
monthly_trend [provider_name + lane]
       │
       │
       ▼
shipment_detail [provider_name + lane]
```

**Recommended approach:** Create a separate **DIM_Provider** and **DIM_Lane** table manually:

```
DIM_Provider: DHL Freight | DB Schenker | Kuehne+Nagel
DIM_Lane: AMS→Frankfurt | Rotterdam→Paris | Eindhoven→Warsaw
```

Connect both dimension tables to all three fact tables using provider_name and lane as keys.

---

## STEP 4 — DAX MEASURES (Copy-paste these exactly)

Create a dedicated **Measures Table** (Enter Data → blank table named "Measures").

---

### 📊 CORE KPI MEASURES

```dax
// Total Spend
Total Spend (€) = 
SUM(provider_scorecard[total_spend_eur])

// Average On-Time Delivery %
Avg OTD % = 
AVERAGEX(
    provider_scorecard,
    provider_scorecard[avg_on_time_pct]
)

// Average Cost per KG
Avg Cost per KG = 
AVERAGEX(
    provider_scorecard,
    provider_scorecard[avg_cost_per_kg]
)

// Total Shipments
Total Shipments = 
SUM(provider_scorecard[total_shipments_ytd])

// SLA Breach Count
SLA Breaches = 
SUM(provider_scorecard[sla_breach_months])
```

---

### 🏆 WEIGHTED SCORECARD MEASURES

```dax
// These mirror your Excel scorecard — shows consistency across tools

// Weight inputs (match your Excel B4:B6 values)
Weight Cost = 0.40
Weight Reliability = 0.35
Weight Lead Time = 0.25

// Normalised Cost Score (lower cost = higher score)
Cost Score = 
VAR MinCost = MINX(ALL(provider_scorecard), provider_scorecard[avg_cost_per_kg])
VAR MaxCost = MAXX(ALL(provider_scorecard), provider_scorecard[avg_cost_per_kg])
VAR ProviderCost = AVERAGE(provider_scorecard[avg_cost_per_kg])
RETURN
ROUND(
    (1 - DIVIDE(ProviderCost - MinCost, MaxCost - MinCost, 0)) * 100,
    2
)

// Normalised Reliability Score (higher OTD = higher score)
Reliability Score = 
VAR MinOTD = MINX(ALL(provider_scorecard), provider_scorecard[avg_on_time_pct])
VAR MaxOTD = MAXX(ALL(provider_scorecard), provider_scorecard[avg_on_time_pct])
VAR ProviderOTD = AVERAGE(provider_scorecard[avg_on_time_pct])
RETURN
ROUND(
    DIVIDE(ProviderOTD - MinOTD, MaxOTD - MinOTD, 0) * 100,
    2
)

// Normalised Lead Time Score (lower lead time = higher score)
Lead Time Score = 
VAR MinLead = MINX(ALL(provider_scorecard), provider_scorecard[avg_lead_time_days])
VAR MaxLead = MAXX(ALL(provider_scorecard), provider_scorecard[avg_lead_time_days])
VAR ProviderLead = AVERAGE(provider_scorecard[avg_lead_time_days])
RETURN
ROUND(
    (1 - DIVIDE(ProviderLead - MinLead, MaxLead - MinLead, 0)) * 100,
    2
)

// Weighted Total Score
Weighted Score = 
[Cost Score] * [Weight Cost] +
[Reliability Score] * [Weight Reliability] +
[Lead Time Score] * [Weight Lead Time]
```

---

### 📈 TREND MEASURES

```dax
// Month-over-Month OTD Change
MoM OTD Change = 
VAR CurrentMonth = AVERAGE(monthly_trend[on_time_pct])
VAR PreviousMonth = 
    CALCULATE(
        AVERAGE(monthly_trend[on_time_pct]),
        DATEADD(monthly_trend[month_year], -1, MONTH)
    )
RETURN
ROUND(CurrentMonth - PreviousMonth, 2)

// 3-Month Rolling Average OTD
Rolling 3M OTD = 
CALCULATE(
    AVERAGE(monthly_trend[on_time_pct]),
    DATESINPERIOD(
        monthly_trend[month_year],
        LASTDATE(monthly_trend[month_year]),
        -3, MONTH
    )
)

// Cost Trend (MoM change in avg cost/kg)
MoM Cost Change = 
VAR CurrentCost = AVERAGE(monthly_trend[avg_cost_per_kg])
VAR PreviousCost = 
    CALCULATE(
        AVERAGE(monthly_trend[avg_cost_per_kg]),
        DATEADD(monthly_trend[month_year], -1, MONTH)
    )
RETURN
ROUND(CurrentCost - PreviousCost, 4)
```

---

### 💰 SAVINGS MEASURES

```dax
// Potential Annual Saving vs Most Expensive Provider
Potential Annual Saving = 
VAR MaxCost = MAXX(ALL(provider_scorecard), provider_scorecard[avg_cost_per_kg])
VAR MinCost = MINX(ALL(provider_scorecard), provider_scorecard[avg_cost_per_kg])
VAR EstimatedVolume = 2400000  // 2.4M kg total annual volume
RETURN
ROUND((MaxCost - MinCost) * EstimatedVolume, 0)

// SLA Risk Flag (Red/Amber/Green)
SLA Status = 
VAR OTD = [Avg OTD %]
VAR Threshold = AVERAGE(provider_scorecard[avg_on_time_pct])
RETURN
IF(OTD >= 95, "🟢 Good", IF(OTD >= 90, "🟡 At Risk", "🔴 Breach"))
```

---

## STEP 5 — REPORT PAGES

Build **4 pages** in this order:

---

### PAGE 1: EXECUTIVE SUMMARY

**Purpose:** One-glance overview for a Supply Chain Director

**Visuals:**
1. **KPI Cards** (top row):
   - Total Shipments YTD
   - Avg On-Time Delivery %
   - Total Freight Spend (€)
   - SLA Breaches
   - Potential Annual Saving

2. **Bar Chart** — Weighted Score by Provider
   - X-axis: Provider Name
   - Y-axis: [Weighted Score]
   - Colors: Green for #1, Amber for #2, Red for #3
   - Title: "Overall Provider Ranking (Weighted Scorecard)"

3. **Table** — Provider Summary
   - Columns: Provider | Avg Cost/kg | OTD % | Avg Lead Days | Score | Rank
   - Format: Conditional formatting — green if OTD ≥ 95%, red if < 90%

4. **Slicer** — Lane (AMS→Frankfurt | Rotterdam→Paris | Eindhoven→Warsaw)

---

### PAGE 2: RADAR CHART — PROVIDER COMPARISON

**Purpose:** Visual scorecard comparing all three dimensions simultaneously

**Visuals:**
1. **Radar/Spider Chart** (use custom visual from AppSource: "Radar Chart" by Microsoft)
   - Categories: Cost Score | Reliability Score | Lead Time Score
   - Series: One per provider
   - This is the "hero visual" — most visually impressive

2. **Lane slicer** on left
3. **Data table** showing the three scores per provider below the chart

**Step to add radar chart:**
- Visualizations pane → "Get more visuals" (icon at bottom)
- Search "Radar Chart" → Add → Use it

---

### PAGE 3: TREND ANALYSIS

**Purpose:** Show performance over time — is a provider improving or declining?

**Visuals:**
1. **Line Chart** — OTD % over months
   - X-axis: Month
   - Y-axis: on_time_pct
   - Legend: Provider Name
   - Add constant line at 92% (DHL SLA) and 90% (DB Schenker SLA)

2. **Line Chart** — Average Cost per KG over months
   - X-axis: Month
   - Y-axis: avg_cost_per_kg
   - Legend: Provider Name

3. **Clustered Column Chart** — Shipment Volume by Month
   - Shows whether volume is growing (important for discount threshold)

4. **Provider slicer** and **Lane slicer**

---

### PAGE 4: SHIPMENT DRILL-THROUGH

**Purpose:** Operational detail — what actually happened per shipment?

**Visuals:**
1. **Table** — Full shipment log
   - Columns: Date | Provider | Lane | Weight (kg) | Status | Delay Days | Cost (€) | Complaint

2. **Donut Chart** — Shipment Status breakdown (Delivered vs Delayed)

3. **Bar Chart** — Delay Reasons (Pareto)
   - Sort descending by count
   - Title: "Top Delay Causes"

4. **KPI Card** — Customer Complaints count

5. Set this page as **Drill-Through target:**
   - Drill-through field: Provider Name
   - Right-click any provider in Pages 1-2 → Drill Through → This page

---

## STEP 6 — DESIGN & FORMATTING

### Colour Theme (matches your Excel and resume):
- Primary background: #1B3A6B (navy)
- Card backgrounds: #0D2240 (dark navy)
- Accent: #C9A84C (gold)
- Positive: #1E7B34 (green)
- Alert: #C0392B (red)
- Body text: #FFFFFF (white)

### Apply custom theme:
1. View → Themes → Customize current theme
2. Enter the hex codes above for each element

### Professional touches:
- Add your name + "Supply Chain Analytics Portfolio 2024" in footer text box
- Add "Data Sources: Freightos 2024 Benchmarks | Simulated operational data" as footnote
- Lock all slicers to same position
- Add page navigation buttons (Insert → Buttons → Navigator)

---

## STEP 7 — EXPORT FOR PORTFOLIO

1. **PDF Export:** File → Export → PDF (for static portfolio)
2. **Publish to Power BI Service:** Sign in with free account at app.powerbi.com → Publish → Share link
3. **Screenshot the Radar Chart** specifically — use this as your LinkedIn thumbnail

---

## WHAT TO SAY IN INTERVIEWS ABOUT POWER BI

> "I built a 4-page Power BI report connected to both my SQL database and Excel model. The radar chart on Page 2 was particularly effective because it let procurement managers visualise all three decision criteria simultaneously — cost, reliability, and lead time — which made the provider recommendation much more defensible than a simple ranking table."

---

*This guide assumes Power BI Desktop (free). No Power BI Pro license required for building — only for cloud sharing.*
