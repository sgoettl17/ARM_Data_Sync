# Unified Construction Data Sync Specification

## Overview
A modular **bidirectional** data synchronization and analytics platform designed to unify:
- Pre-construction estimating pipeline: **Smartsheet** (Webster Tracking)
- Active project financials: **Sage 300** (job cost, pay apps, change orders)
- Field execution tracking: **Procore** (RFIs, submittals, daily logs, observations, schedules)
- Resource planning: **Bridgit Bench** (people, assignments, skills) with **reverse sync** for forecasted manpower

The system tracks the complete project lifecycle from initial bid through execution and closeout, with advanced analytics including schedule validation (comparing Procore/MS Project schedules against pay app S-curve projections to identify unrealistic schedules).

**Key Insights:**
- **End-to-End Visibility:** Bridge pre-construction (estimating), operations (financials), and field execution (daily activities)
- **Schedule Validation:** Detect schedule vs. billing misalignment early
- **Predictive Resourcing:** Push forecasted manpower requirements back to Bridgit Bench based on won bids and project schedules

## Objectives
- **Unify Entire Project Lifecycle:** Bridge estimating pipeline (Smartsheet), active project financials (Sage 300), field execution (Procore), and resource planning (Bridgit Bench).
- **Track Estimate-to-Operations Conversion:** Monitor job number transitions from YY-4-### (estimating) to YY-1-### (operations), including split awards and phased change orders.
- **Validate Schedules Against Financials:** Compare Procore/MS Project schedules with pay application S-curve billing projections to detect unrealistic scheduling.
- **Enable Reverse Sync:** Push forecasted manpower requirements to Bridgit Bench API based on won bids, project schedules, and resource gap analysis.
- **Calculate Predictive Metrics:** Running averages for bid-to-award timelines, buyout durations, RFI response times, submittal approval cycles.
- **Provide Role-Based Dashboards:**
  - **Estimating:** Pipeline value, win rate, revenue forecast, estimator workload
  - **Operations:** Active projects, WIP, change orders, labor hours by cost code
  - **Field/PM:** RFI status, submittal tracking, daily log metrics, schedule health (vs. pay apps)
  - **Leadership:** Resource utilization, company-wide financial performance, project portfolio health
- **Create Governed Data Warehouse:** Bronze, Silver, Gold layers with automated quality checks and audit trails.
- **Simplify Deployment:** Docker Compose (local) and Kubernetes (prod) for scalability.

## Technology Stack
- **ETL/ELT:** Airbyte (connectors) + custom Python connectors where needed.
- **Transformation:** dbt (data modeling, version control, testing).
- **Validation:** Great Expectations (data quality assurance).
- **Storage:** PostgreSQL (primary warehouse) with streaming replication for HA.
- **Orchestration:** Dagster (asset-based workflow orchestration with tight dbt integration).
- **Metadata & Lineage:** OpenMetadata (data catalog, lineage tracking).
- **Visualization:** Metabase.
- **API/Admin Layer:** FastAPI with OAuth2 + API key authentication.
- **Monitoring:** Prometheus (metrics) + Grafana (dashboards).
- **Infrastructure:** Docker Compose (local) / Helm + Kubernetes (prod).

## Architecture

### High-Level Data Flow
```
┌──────────────────────────────────── DATA INGESTION (Read) ────────────────────────────────────┐
│                                                                                                 │
│  [Smartsheet]      [Sage 300]       [Procore]           [Bridgit Bench]                       │
│  Estimating        Financials       Field Execution     Resource Planning                      │
│  YY-4-### jobs     YY-1-### jobs    RFIs, Submittals   People, Assignments                   │
│       │                 │                 │                      │                             │
└───────┼─────────────────┼─────────────────┼──────────────────────┼─────────────────────────────┘
        │                 │                 │                      │
        └─────────────────┴─────────────────┴──────────────────────┘
                                     │
                                     ▼
                       [Airbyte / Custom Connectors]
                                     │
                                     ▼
                       [PostgreSQL - Bronze Layer]
                       - smartsheet_* (raw estimating data)
                       - sage_* (raw financial/project data)
                       - procore_* (raw field execution data)
                       - bridgit_* (raw resource data)
                                     │
                                     ▼
                          [Great Expectations]
                          Bronze validation & profiling
                                     │
                                     ▼
                       [dbt - Silver Layer]
                       - dim_project (unified across all sources)
                       - dim_person, dim_estimator, dim_cost_code
                       - bridge_estimate_to_project (YY-4 → YY-1 mapping)
                       - Normalized facts with SCD Type 2
                                     │
                                     ▼
                       [dbt - Gold Layer]
                       - Estimating: pipeline metrics, win rate, forecast
                       - Operations: WIP, labor, change orders, pay apps
                       - Field: RFI cycle time, submittal status, daily log KPIs
                       - Schedule: S-curve vs. schedule health score
                       - Cross-lifecycle: bid accuracy, timeline predictions
                                     │
                                     ▼
                          [Great Expectations]
                          Gold validation & business rules
                                     │
                    ┌────────────────┴─────────────────┐
                    │                                  │
                    ▼                                  ▼
            [OpenMetadata]                      [FastAPI]
            Catalog & Lineage                   Read/Write API
                    │                                  │
                    │                                  │
        ┌───────────┴──────────────┬───────────────────┴──────────────────┐
        │                          │                                       │
        ▼                          ▼                                       ▼
  [Metabase                 [Prometheus +                    ┌─── REVERSE SYNC (Write) ───┐
   Dashboards]               Grafana]                        │                            │
   - Estimating              Monitoring                      ▼                            │
   - Operations              & Alerts              [Dagster Reverse Sync Assets]          │
   - Field/PM                                                │                            │
   - Leadership                                              ▼                            │
                                                   [Bridgit Bench API ◄──────────────────┘
                                                    Write forecasted
                                                    manpower assignments]
```

### Key Layers
- **Bronze (Raw):** Ingested directly from APIs, databases, or file shares (network folders). Immutable source data.
- **Silver (Normalized):** Cleaned, deduplicated, and standardized schemas. Cross-system entity matching. SCD Type 2 for history tracking.
- **Gold (Curated):** Aggregated KPIs, calculated metrics, and business logic. Optimized for dashboard queries and reverse sync calculations.
- **Reverse Sync:** Gold layer calculations pushed back to source systems (currently Bridgit Bench, extensible to others).

## Data Sources

### Smartsheet (Estimating Pipeline)
- **Purpose:** Pre-construction estimating and bidding pipeline tracking
- **Method:** REST API with access token
- **Primary Sheet:** "Webster Tracking" (estimating jobs)
- **Entities:**
  - Estimating jobs/opportunities with YY-4-### job numbers
  - Estimating status workflow stages (Bidding This Week, Bidding Next Week, Bidding Three Weeks, Arriving, Post Pending)
  - Pipeline probability (% likelihood of winning: 1%, 5%, 15%, 50%, 75%, etc.)
  - Financial projections by year (2025 % Complete, Days in 2025, $ in 2025, Days in 2026, $ in 2026, etc.)
  - Estimator assignments (Lead Estimator, Estimator, Est. Asst.)
  - Project details (Owner, Architect, Market Type, City/State, Approx. Cost, Duration, Start/Finish dates)
  - Factored costs and monthly revenue projections
- **Incremental Key:** `modifiedAt`
- **Key Fields:**
  - Job Outlook for JB (TRUE/FALSE flag for inclusion in outlook reporting)
  - Bid Due Date
  - Approx. Start Date (used for manpower forecasting)
  - Pipeline Probability (for weighted revenue forecasting)
- **Business Logic:** Jobs marked "Post Pending" or status changes to awarded trigger estimate-to-project conversion process

### Sage 300 (Operations - Active Projects)
- **Purpose:** Financial management for active construction projects (YY-1-### jobs)
- **Method:** ODBC/SQL read-only connection; fallback to manual CSV export when ODBC fails
- **Entities:**
  - Job Cost data (actual costs by project, cost code, date)
  - Employee Hours (labor hours, regular/OT, rates)
  - Cost Codes (hierarchical structure)
  - Change Orders (owner/internal/subcontractor COs, amounts, status)
  - Pay Applications (billing, retention, payment tracking)
  - Project master data (project numbers, names, budgets, status)
- **Incremental Key:** `Accounting_Date` or `updated_at`
- **Master Data Authority:** Sage 300 is the source of truth for YY-1-### project numbers
- **Fallback:** Network folder structure (\\armays-fs1\...\Jobs 2025\) when project exists but not yet in Sage 300
- **CSV Fallback Logic:** If ODBC connection fails 3+ times, trigger manual CSV export alert (see Error Handling section)

### Procore (Field Execution Tracking)
- **Purpose:** Field-level project execution, quality, and schedule tracking
- **Method:** REST API v1.0 with OAuth 2.0
- **Entities:**
  - **RFIs (Requests for Information):**
    - RFI number, subject, question, answer, status
    - Created date, due date, response date
    - Responsible parties (assignee, reviewers)
    - Cost impact, schedule impact flags
  - **Submittals:**
    - Submittal number, specification section, description
    - Status workflow (draft, pending review, approved, returned, etc.)
    - Submission date, required approval date, actual approval date
    - Revision history
  - **Daily Logs:**
    - Date, weather conditions
    - Manpower by trade (headcount, hours)
    - Equipment usage
    - Work performed descriptions
    - Delays, issues, observations
  - **Observations:**
    - Observation type (safety, quality, progress)
    - Status, priority, assigned to
    - Photos, attachments
    - Resolution notes
  - **Schedules:**
    - Schedule activities/tasks
    - Start/finish dates (planned vs. actual)
    - % complete
    - Critical path indicators
    - Predecessors/successors
    - **Alternative:** MS Project file references from network folders if not using Procore scheduling
- **Incremental Key:** `updated_at`
- **Schedule Source Preference:**
  1. Primary: Procore schedule data via API
  2. Fallback: MS Project (.mpp) files from project network folders
  3. Parse critical path, milestone dates, resource loading
- **Rate Limits:** 3600 requests/hour per project (Procore API limit)

### Bridgit Bench (Resource Planning)
- **Purpose:** People management, skills tracking, and project staffing
- **Method:** REST API v1.0 via `/rp/api/1.0/` with OAuth
- **Direction:** **BIDIRECTIONAL** (Read + Write)
- **Read Entities:**
  - Projects (all active and planned projects)
  - People (employees with skills, rates, availability)
  - Roles (job titles/classifications)
  - Assignments (person → project allocations with % and dates)
  - Skills (skill taxonomy and proficiency levels)
- **Write Entities (Reverse Sync):**
  - **Forecasted Assignments:** Push predicted manpower requirements based on:
    - Won estimates from Smartsheet (status change to "Awarded")
    - Project start dates from Sage 300 or Smartsheet
    - Historical staffing patterns by project type/size
    - Resource gap analysis (demand vs. current allocations)
  - **Assignment Attributes:**
    - Project ID (Bridgit project linked to Sage YY-1-### job)
    - Person ID (employee)
    - Role name
    - Allocation % (calculated from project size, duration, phase)
    - Start date (project start date minus mobilization time)
    - End date (project end date)
    - Notes: "Auto-generated from data warehouse based on [project name] award"
- **Incremental Key:** `updated_at`
- **Write-Back Frequency:** Daily at 9am after estimating pipeline refresh
- **Write-Back Logic:**
  - Only write assignments for projects starting within next 90 days
  - Flag as "Forecast" (vs. confirmed assignment)
  - Do not overwrite manually created assignments (check `created_by` field)
- **Conflict Resolution:** Manual assignments in Bridgit take precedence; warehouse writes only to "forecast" assignments

## Job Number Conversion Logic

### Numbering System
**Format: YY-C-###**
- **YY** = Year (25 = 2025, 26 = 2026, etc.)
- **C** = Category Code
  - **1** = Operations/Active Projects (paid construction jobs in Sage 300)
  - **4** = Estimating Projects (bids/pipeline in Smartsheet)
  - Other category codes may exist (2, 3, 5, etc.) - to be documented
- **###** = Sequential number within that category and year

### Master Data Source Hierarchy
1. **Primary:** Sage 300 YY-1-### jobs (source of truth for active projects)
2. **Secondary:** Network folder structure `\\armays-fs1\...\Jobs 2025\YY-1-###` when project awarded but not yet in Sage 300
3. **Estimating:** Smartsheet YY-4-### jobs (pipeline/bidding phase only)

### Conversion Scenarios

#### Scenario A: Simple One-to-One Award
- Single estimate `25-4-015` (Caldwell BBQ TI) wins bid
- Operations creates new job `25-1-082` (Caldwell BBQ TI)
- **Mapping Type:** `direct_award`
- **Detection:** Manual entry in mapping table OR fuzzy name match with high confidence

**Example:**
```
Estimate: 25-4-015 "Caldwell BBQ T.I. - Phoenix"
↓ (awarded)
Operations: 25-1-082 "Caldwell BBQ - Phoenix"
Confidence: 95% (Levenshtein distance)
```

#### Scenario B: Split Estimate into Multiple Phases (One-to-Many)
- Single large estimate split into 3 components for pricing:
  - `25-4-020` Site Work
  - `25-4-021` Shell Building
  - `25-4-022` Tenant Improvement
- All three awarded as **phased change orders** to a single operations project `25-1-090`
- **Mapping Type:** `awarded_as_phase`
- **Reason:** Single owner, single contract, phased execution

**Example:**
```
Estimates:
  25-4-020 "Office Complex - Site Work"
  25-4-021 "Office Complex - Shell"
  25-4-022 "Office Complex - TI"
↓ (all awarded as phases)
Operations: 25-1-090 "Office Complex - Full Build"
  - Phase 1: Site
  - Phase 2: Shell
  - Phase 3: TI
```

**Mapping Records:**
```sql
| estimate_job  | operations_job | relationship_type | notes |
|---------------|----------------|-------------------|-------|
| 25-4-020      | 25-1-090       | awarded_as_phase  | Site Work phase |
| 25-4-021      | 25-1-090       | awarded_as_phase  | Shell phase |
| 25-4-022      | 25-1-090       | awarded_as_phase  | TI phase |
```

#### Scenario C: TI with Different Owner (Split Award)
- Estimate has multiple phases, but TI has different owner/contract:
  - `25-4-020` Site/Shell (Owner A)
  - `25-4-022` TI (Owner B - separate contract)
- Creates **two separate** operations jobs:
  - `25-1-090` (Owner A - Site/Shell)
  - `25-1-091` (Owner B - TI only)
- **Mapping Type:** `direct_award` for both

**Example:**
```
Estimates:
  25-4-020 "Retail Center - Site & Shell" (Owner: Developer LLC)
  25-4-022 "Retail Center - TI" (Owner: Tenant LLC)
↓ (separate awards)
Operations:
  25-1-090 "Retail Center - Core & Shell" (Owner: Developer LLC)
  25-1-091 "Retail Center - Tenant Buildout" (Owner: Tenant LLC)
```

### Automated Matching Logic

**Step 1: Detect Awarded Estimates**
- Monitor Smartsheet for status changes to "Post Pending" or custom awarded status
- Extract estimate job number (25-4-###) and project name

**Step 2: Fuzzy Match to Operations Jobs**
- Query Sage 300 for new YY-1-### jobs created within 60 days of estimate bid due date
- Calculate Levenshtein distance between estimate name and operations job name
- Normalize names (lowercase, remove punctuation, trim)

**Step 3: Confidence Scoring**
- **≥90% match:** Auto-link, mark as HIGH confidence
- **75-89% match:** Flag for manual review, mark as MEDIUM confidence
- **<75% match:** No auto-link, mark as LOW confidence (manual entry required)

**Step 4: Manual Review Workflow**
- MEDIUM confidence matches appear in admin dashboard
- Data steward reviews and approves/rejects/overrides
- Can manually map any estimate to any operations job

**Step 5: Store Mapping**
```sql
CREATE TABLE bridge_estimate_to_project (
    mapping_id SERIAL PRIMARY KEY,
    estimate_job_number VARCHAR(20),      -- 25-4-###
    operations_job_number VARCHAR(20),    -- 25-1-###
    relationship_type VARCHAR(50),        -- direct_award, awarded_as_phase, split_award
    project_name VARCHAR(255),            -- unified project name
    confidence_score DECIMAL(5,2),        -- 0.00 to 1.00
    match_method VARCHAR(50),             -- auto/manual/folder_reference/override
    notes TEXT,
    mapped_by VARCHAR(100),               -- username who approved/created mapping
    mapped_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(estimate_job_number, operations_job_number)
);
```

### Network Folder Fallback
- If operations job doesn't exist in Sage 300 yet, check network folder:
  - Path pattern: `\\armays-fs1\Company\Jobs 2025\25-1-###\`
  - Parse folder name for job number
  - Create placeholder in `dim_project` with `_source_system = 'network_folder'`
  - Update when job appears in Sage 300

## Schedule Validation & S-Curve Analysis

### Purpose
Detect unrealistic or poorly aligned project schedules by comparing **planned schedule progress** (from Procore or MS Project) against **actual billing progress** (from Sage 300 pay applications).

### Concept: Schedule vs. Billing Alignment
- **Assumption:** Billing (pay apps) should roughly follow schedule progress
- **Reality Check:** If schedule shows 60% complete but only billed 30%, something is wrong:
  - Schedule is too optimistic (sandbagging)
  - Billing is behind (payment issues)
  - Work is behind (actual delay)

### S-Curve Generation

**Pay App S-Curve (Financial Progress):**
```sql
-- Gold layer calculation
WITH pay_app_cumulative AS (
  SELECT
    project_fk,
    billing_period_end,
    SUM(work_completed_to_date) OVER (
      PARTITION BY project_fk
      ORDER BY billing_period_end
    ) AS cumulative_billed,
    MAX(contract_value) AS total_contract_value
  FROM fact_pay_apps
  WHERE status = 'Approved'
)
SELECT
  project_fk,
  billing_period_end AS date,
  cumulative_billed,
  total_contract_value,
  (cumulative_billed / NULLIF(total_contract_value, 0)) * 100 AS percent_complete_financial
FROM pay_app_cumulative
ORDER BY project_fk, billing_period_end;
```

**Schedule S-Curve (Planned Progress):**
```sql
-- From Procore schedule data or MS Project import
WITH schedule_progress AS (
  SELECT
    project_fk,
    schedule_date,
    SUM(planned_value) OVER (
      PARTITION BY project_fk
      ORDER BY schedule_date
    ) AS cumulative_planned_value,
    MAX(total_planned_value) AS budget_at_completion
  FROM fact_schedule_activities
  WHERE status != 'Cancelled'
)
SELECT
  project_fk,
  schedule_date AS date,
  cumulative_planned_value,
  budget_at_completion,
  (cumulative_planned_value / NULLIF(budget_at_completion, 0)) * 100 AS percent_complete_schedule
FROM schedule_progress
ORDER BY project_fk, schedule_date;
```

### Variance Calculation
```sql
-- Compare schedule vs. financial progress at each reporting period
CREATE TABLE gold_schedule_health AS
SELECT
  s.project_fk,
  s.schedule_date,
  s.percent_complete_schedule,
  p.percent_complete_financial,
  s.percent_complete_schedule - p.percent_complete_financial AS variance_percent,
  CASE
    WHEN ABS(s.percent_complete_schedule - p.percent_complete_financial) <= 5 THEN 'Aligned'
    WHEN s.percent_complete_schedule - p.percent_complete_financial > 5 THEN 'Schedule Ahead (Risk: Sandbagging)'
    WHEN s.percent_complete_schedule - p.percent_complete_financial < -5 THEN 'Schedule Behind (Risk: Delay)'
  END AS health_status,
  CASE
    WHEN ABS(s.percent_complete_schedule - p.percent_complete_financial) <= 5 THEN 'Green'
    WHEN ABS(s.percent_complete_schedule - p.percent_complete_financial) <= 15 THEN 'Yellow'
    ELSE 'Red'
  END AS health_color
FROM schedule_progress s
LEFT JOIN pay_app_cumulative p
  ON s.project_fk = p.project_fk
  AND s.schedule_date = p.billing_period_end;
```

### Alert Thresholds
- **Green (Healthy):** Variance ≤ 5% (schedule and billing aligned)
- **Yellow (Warning):** Variance 5-15% (minor misalignment)
- **Red (Critical):** Variance > 15% (major issue - "call BS on bad schedule")

### Dashboard Visualization
- X-axis: Time (weeks or months)
- Y-axis: % Complete (0-100%)
- Two lines:
  - **Blue:** Planned progress (from schedule)
  - **Green:** Actual progress (from pay apps)
- Shaded regions for variance (red = behind, yellow = warning)

### Business Rules
- Calculate variance **monthly** on pay app submission
- Alert PM if variance > 15% for 2 consecutive months
- Include in executive dashboard: "Projects with Schedule Risk"
- Compare to historical projects of similar type/size to set realistic baselines

### Integration with Procore
- **Primary:** Procore schedule API provides task-level detail
- **Fallback:** Parse MS Project XML export from network folders
- **Data Points Needed:**
  - Task ID, name, duration
  - Planned start, planned finish
  - Actual start, actual finish, % complete
  - Baseline dates (original plan)
  - Critical path flag

## Reverse Sync: Bridgit Bench Write-Back

### Purpose
Automatically populate Bridgit Bench with **forecasted manpower assignments** based on:
1. Newly awarded projects (Smartsheet → Sage 300 conversion)
2. Project start dates and durations
3. Historical staffing patterns by project type/size
4. Current resource availability in Bridgit

### Trigger Events
- **Daily at 9:00 AM:** After overnight ETL run completes
- **Ad-hoc:** When estimate manually marked as "Awarded" in mapping table
- **Weekly:** Resource gap analysis (demand vs. supply for next quarter)

### Calculation Logic

**Step 1: Identify New Awards**
```sql
-- Find estimates converted to operations jobs in last 7 days
SELECT
  e.estimate_job_number,
  e.operations_job_number,
  p.project_name,
  p.project_manager,
  p.start_date,
  p.end_date,
  p.budget_amount,
  p.location
FROM bridge_estimate_to_project e
JOIN dim_project p ON p.project_code = e.operations_job_number
WHERE e.mapped_at >= CURRENT_DATE - INTERVAL '7 days'
  AND e.is_active = TRUE
  AND p.start_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days';
```

**Step 2: Calculate Required Roles**
```sql
-- Historical role requirements by project size and type
WITH historical_staffing AS (
  SELECT
    project_type,
    project_size_category, -- Small <$1M, Medium $1-5M, Large >$5M
    role_name,
    AVG(allocation_percent) AS avg_allocation,
    AVG(duration_days) AS avg_duration
  FROM fact_assignments fa
  JOIN dim_project p ON fa.project_fk = p.project_sk
  WHERE p.status = 'Completed'
    AND fa.end_date >= fa.start_date -- valid assignments
  GROUP BY project_type, project_size_category, role_name
)
SELECT
  new_project.operations_job_number,
  hs.role_name,
  hs.avg_allocation,
  hs.avg_duration,
  -- Adjust based on actual project duration
  LEAST(new_project.duration_days, hs.avg_duration) AS forecasted_duration
FROM new_awards_cte new_project
JOIN historical_staffing hs
  ON new_project.market_type = hs.project_type
  AND new_project.size_category = hs.project_size_category;
```

**Step 3: Match to Available People**
```sql
-- Find people with matching skills and availability
WITH resource_demand AS (
  -- Output from Step 2
),
resource_supply AS (
  SELECT
    person_id,
    role_name,
    skills,
    -- Calculate current utilization
    SUM(allocation_percent) AS current_utilization
  FROM bridgit_assignments_current
  WHERE end_date >= CURRENT_DATE
  GROUP BY person_id, role_name, skills
)
SELECT
  rd.operations_job_number,
  rd.role_name,
  rs.person_id,
  rd.avg_allocation AS recommended_allocation,
  100 - rs.current_utilization AS available_capacity,
  CASE
    WHEN (100 - rs.current_utilization) >= rd.avg_allocation THEN 'Full'
    WHEN (100 - rs.current_utilization) > 0 THEN 'Partial'
    ELSE 'Overallocated'
  END AS assignment_feasibility
FROM resource_demand rd
LEFT JOIN resource_supply rs
  ON rd.role_name = rs.role_name
  AND rs.skills ? rd.required_skills -- JSONB contains check
WHERE rs.current_utilization < 100 -- only available people
ORDER BY rs.current_utilization ASC; -- prioritize least utilized
```

**Step 4: Write to Bridgit API**
```python
# Dagster asset for reverse sync
@asset(
    deps=["gold_forecasted_assignments"],
    group_name="reverse_sync"
)
def bridgit_write_forecasted_assignments(context, bridgit_api_client):
    """
    Push forecasted manpower assignments to Bridgit Bench.
    """
    # Query gold table for assignments to write
    forecasted = context.resources.db.query("""
        SELECT
            bridgit_project_id,
            bridgit_person_id,
            role_name,
            allocation_percent,
            start_date,
            end_date,
            notes
        FROM gold_forecasted_assignments
        WHERE write_status = 'pending'
          AND start_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days'
    """)

    results = []
    for assignment in forecasted:
        # Check if manual assignment already exists
        existing = bridgit_api_client.get_assignment(
            project_id=assignment['bridgit_project_id'],
            person_id=assignment['bridgit_person_id']
        )

        if existing and existing['created_by'] != 'system':
            # Manual assignment exists, skip
            context.log.info(f"Skipping {assignment} - manual assignment exists")
            update_write_status(assignment['id'], 'skipped_manual_override')
            continue

        # Write forecast assignment
        response = bridgit_api_client.create_assignment(
            project_id=assignment['bridgit_project_id'],
            person_id=assignment['bridgit_person_id'],
            role=assignment['role_name'],
            allocation=assignment['allocation_percent'],
            start_date=assignment['start_date'],
            end_date=assignment['end_date'],
            notes=f"AUTO-FORECAST: {assignment['notes']}",
            tags=['forecast', 'auto-generated']
        )

        if response.status_code == 201:
            update_write_status(assignment['id'], 'success', response.json()['id'])
            results.append({'status': 'success', 'assignment': assignment})
        else:
            update_write_status(assignment['id'], 'failed', response.text)
            results.append({'status': 'failed', 'assignment': assignment, 'error': response.text})

    return {"written": len([r for r in results if r['status'] == 'success']),
            "failed": len([r for r in results if r['status'] == 'failed'])}
```

### Write-Back Governance
- **Approval Workflow (Optional):** Require PM approval before writing assignments to Bridgit
- **Audit Trail:** Log all write-backs to `audit_reverse_sync` table
- **Rollback:** If write fails or PM rejects, mark assignment as `write_status = 'cancelled'`
- **Conflict Resolution:**
  - Manual assignments (created by humans in Bridgit) **always take precedence**
  - System only writes to "forecast" tag
  - PMs can convert forecast to confirmed in Bridgit UI

### Error Handling
- **Rate Limit (Bridgit: 100 req/min):** Batch writes, add 600ms delay between requests
- **API Failure:** Retry 3 times with exponential backoff, then alert data engineer
- **Invalid Project/Person ID:** Log to error table, alert data steward to fix mapping
- **Duplicate Assignment:** Skip and log (idempotency)

## Stakeholders & Roles

### Project Stakeholders
- **Sponsor:** CFO / VP of Operations
- **Business Owners:** Construction Management Team, Finance Department
- **End Users:** Project Managers, Finance Analysts, Executive Leadership
- **Technical Owner:** Data Engineering Lead

### RACI Matrix
| Activity | Data Engineer | Business Analyst | Finance | Project Manager | DevOps |
|----------|--------------|------------------|---------|-----------------|--------|
| Requirements Definition | C | R | A | C | I |
| Data Model Design | R/A | C | C | C | I |
| Implementation | R/A | I | I | I | C |
| Testing & Validation | R | A | C | C | I |
| Deployment | C | I | I | I | R/A |
| Ongoing Maintenance | R/A | C | I | I | C |

**Legend:** R=Responsible, A=Accountable, C=Consulted, I=Informed

## Requirements

### Functional Requirements

**FR-001: Multi-Source Data Ingestion**
- **Priority:** P0 (Must Have)
- **Description:** System shall ingest data from Smartsheet (estimating), Sage 300 (financials), Procore (field execution), and Bridgit Bench (resource planning)
- **Acceptance Criteria:**
  - AC1: All four source systems successfully connected and authenticated
  - AC2: Incremental data updates for all sources using appropriate incremental keys
  - AC3: Manual CSV fallback available for Sage 300 ODBC failures (alert after 3 failures)
  - AC4: Procore rate limiting respected (3600 requests/hour per project)
  - AC5: MS Project file parsing available as fallback for schedule data
- **Business Rules:** BR-001 - Use incremental keys per source (Smartsheet: modifiedAt, Sage: Accounting_Date/updated_at, Procore: updated_at, Bridgit: updated_at)

**FR-002: Data Transformation & Modeling**
- **Priority:** P0 (Must Have)
- **Description:** Transform raw data into dimensional model (Bronze → Silver → Gold)
- **Acceptance Criteria:**
  - AC1: All dimension tables populated with deduplicated entities
  - AC2: Fact tables contain metrics with proper foreign key relationships
  - AC3: Transformations are idempotent and reproducible
- **Business Rules:** BR-002 - Use hybrid SCD strategy (Type 2 for critical attributes, Type 1 for non-critical)

**FR-003: Cross-System Entity Matching**
- **Priority:** P0 (Must Have)
- **Description:** Unify projects and people across multiple source systems
- **Acceptance Criteria:**
  - AC1: Projects matched with ≥85% confidence score auto-approved
  - AC2: Matches <85% confidence flagged for manual review
  - AC3: Manual mapping table available for overrides
- **Business Rules:** BR-003 - Use Levenshtein distance algorithm with manual review workflow

**FR-004: Data Quality Validation**
- **Priority:** P0 (Must Have)
- **Description:** Automated data quality checks at each layer
- **Acceptance Criteria:**
  - AC1: Great Expectations test suites run at Bronze, Silver, Gold layers
  - AC2: dbt tests validate referential integrity and schema contracts
  - AC3: End-to-end reconciliation compares source vs. warehouse totals monthly
  - AC4: Failed validations block downstream processing and trigger alerts
- **Business Rules:** BR-004 - All fact tables must pass row count, null, and freshness checks

**FR-005: Dashboard & Visualization**
- **Priority:** P0 (Must Have)
- **Description:** Provide role-based dashboards spanning estimating, operations, field execution, and leadership
- **Acceptance Criteria:**
  - AC1: Estimating dashboards: Pipeline value by status, win rate trends, revenue forecast, estimator workload
  - AC2: Operations dashboards: Labor hours by project, change order summary, WIP exposure, pay app status
  - AC3: Field/PM dashboards: RFI cycle time, submittal status, daily log metrics, schedule health (S-curve variance)
  - AC4: Leadership dashboards: Resource utilization, company-wide financial performance, project portfolio health
  - AC5: All dashboards refresh daily by 9am with T+1 data (previous day's data)
  - AC6: Role-based access controls limit dashboard visibility by user role
- **Business Rules:** BR-005 - Dashboards query Gold layer only, no direct Bronze/Silver access

**FR-006: API Access**
- **Priority:** P1 (Should Have)
- **Description:** Programmatic access to data via FastAPI
- **Acceptance Criteria:**
  - AC1: RESTful API with OAuth2 authentication
  - AC2: API key support for service accounts
  - AC3: Rate limiting (100 requests/minute per user)
  - AC4: API documentation via Swagger/OpenAPI
- **Business Rules:** BR-006 - API access requires explicit user provisioning

**FR-007: Alerting & Notifications**
- **Priority:** P1 (Should Have)
- **Description:** Alert on-call team for pipeline failures and data quality issues
- **Acceptance Criteria:**
  - AC1: Email alerts for pipeline failures within 5 minutes
  - AC2: Slack/Teams integration for data quality warnings
  - AC3: Alert fatigue mitigation (no duplicate alerts within 1 hour)
- **Business Rules:** BR-007 - Critical alerts escalate to phone/SMS after 15 minutes

**FR-008: Audit Logging**
- **Priority:** P1 (Should Have)
- **Description:** Log all user access and system changes
- **Acceptance Criteria:**
  - AC1: Log authentication events (success/failure)
  - AC2: Log all API access with user ID, timestamp, endpoint
  - AC3: Log configuration changes with change author and timestamp
  - AC4: Audit logs retained for 7 years
- **Business Rules:** BR-008 - Audit logs stored in separate database, immutable

**FR-009: Estimate-to-Project Conversion Tracking**
- **Priority:** P0 (Must Have)
- **Description:** Track conversion of estimating jobs (YY-4-###) to operations projects (YY-1-###) with automated fuzzy matching
- **Acceptance Criteria:**
  - AC1: Automated Levenshtein distance matching with ≥90% confidence auto-links, 75-89% flags for review
  - AC2: Support three conversion scenarios: direct award (1:1), phased award (N:1), split award (1:N)
  - AC3: Manual review dashboard for MEDIUM confidence matches
  - AC4: Bridge table stores all mappings with confidence scores, match method, and audit trail
  - AC5: Network folder fallback when operations job not yet in Sage 300
- **Business Rules:** BR-009 - Sage 300 YY-1-### jobs are master data source; Smartsheet YY-4-### for pipeline only

**FR-010: Procore Field Execution Integration**
- **Priority:** P0 (Must Have)
- **Description:** Ingest field execution data from Procore for project execution KPIs
- **Acceptance Criteria:**
  - AC1: RFIs tracked with cycle time metrics (created → responded → closed)
  - AC2: Submittals tracked with approval workflow status and revision history
  - AC3: Daily logs ingested with manpower by trade, weather, work performed
  - AC4: Observations captured with type, status, priority, resolution
  - AC5: Schedule data ingested (tasks, dates, % complete, critical path) OR MS Project file parsing fallback
  - AC6: All Procore entities linked to dim_project via project number
- **Business Rules:** BR-010 - Procore API rate limit 3600 req/hr per project; batch requests and add delays

**FR-011: Schedule Validation & S-Curve Analysis**
- **Priority:** P0 (Must Have)
- **Description:** Compare project schedules (Procore/MS Project) against pay application billing to detect unrealistic schedules
- **Acceptance Criteria:**
  - AC1: Generate financial S-curve from Sage 300 pay applications (cumulative % billed)
  - AC2: Generate schedule S-curve from Procore/MS Project (cumulative % complete)
  - AC3: Calculate variance between schedule and financial progress monthly
  - AC4: Health scoring: Green (≤5% variance), Yellow (5-15%), Red (>15%)
  - AC5: Alert PM when variance >15% for 2 consecutive months
  - AC6: Dashboard visualization with dual S-curves and variance shading
- **Business Rules:** BR-011 - Assumption: billing should roughly follow schedule progress; variance >15% indicates schedule or execution issue

**FR-012: Reverse Sync to Bridgit Bench**
- **Priority:** P0 (Must Have)
- **Description:** Push forecasted manpower assignments to Bridgit Bench based on won bids and historical staffing patterns
- **Acceptance Criteria:**
  - AC1: Daily sync at 9am identifies newly awarded projects (Smartsheet → Sage 300 conversion within last 7 days)
  - AC2: Calculate required roles based on historical staffing by project type/size
  - AC3: Match to available people with appropriate skills and capacity
  - AC4: Write forecasted assignments to Bridgit API with 'forecast' tag for projects starting within 90 days
  - AC5: Skip write if manual assignment already exists (conflict resolution: human takes precedence)
  - AC6: Audit trail logs all write-backs with success/failure status
- **Business Rules:** BR-012 - Only write forecast assignments; respect Bridgit rate limit 100 req/min with 600ms delays; retry 3x with exponential backoff

### Non-Functional Requirements

**NFR-001: Performance**
- Dashboard queries return results within 5 seconds for 95th percentile
- Metabase page load time <3 seconds
- API response time <500ms for 95th percentile

**NFR-002: Scalability**
- Support up to 200 concurrent projects
- Handle 1M+ rows per fact table
- Support 50 concurrent dashboard users

**NFR-003: Availability**
- System uptime: 99.5% (equivalent to ~3.6 hours downtime/month)
- Planned maintenance windows: Sundays 2am-6am
- Recovery Time Objective (RTO): 2 hours
- Recovery Point Objective (RPO): 24 hours (acceptable to lose 1 day of data in disaster)

**NFR-004: Data Freshness**
- SLA: Dashboards updated daily by 9am with T+1 data (previous day's data)
- Bronze layer: Data ingested by 6am daily
- Gold layer: Transformations complete by 8:30am daily

**NFR-005: Data Retention**
- Bronze layer: 1 year active in PostgreSQL, then archive to S3/Azure Blob
- Silver/Gold layers: 3 years active, then archive
- Audit logs: 7 years retention (compliance requirement)

**NFR-006: Security**
- OAuth2 authentication for all user access
- API keys for service accounts with 90-day rotation policy
- TLS 1.3 for all network communications
- Secrets managed via environment variables (no hardcoded credentials)
- Network policies restrict egress to approved endpoints only

**NFR-007: Maintainability**
- New data source onboarding: ≤3 business days
- Bug fix deployment: within 24 hours for critical, 1 week for non-critical
- Version control for all code (Git)
- Infrastructure as code (Terraform/Helm)

**NFR-008: Observability**
- Structured JSON logging to stdout
- Prometheus metrics exported from all services
- Grafana dashboards for system health, pipeline duration, data quality trends
- Log retention: 90 days in hot storage, 1 year in cold storage

## Data Model

### Dimensional Model Overview
**Dimensions:** `dim_project`, `dim_person`, `dim_cost_code`, `dim_client`, `dim_date`
**Facts:** `fact_labor_hours`, `fact_assignments`, `fact_change_orders`, `fact_pay_apps`

### Dimension Tables (Detailed Schema)

#### dim_project
| Column | Type | Description | SCD Type | Source |
|--------|------|-------------|----------|--------|
| project_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_id | VARCHAR(50) | Business key (natural key) | - | All sources |
| project_name | VARCHAR(255) | Project name | Type 1 | All sources |
| project_code | VARCHAR(50) | Project code/number | Type 1 | Sage 300 |
| client_fk | BIGINT | Foreign key to dim_client | Type 2 | All sources |
| project_manager | VARCHAR(255) | PM name | Type 2 | Bridgit/Smartsheet |
| status | VARCHAR(50) | Active/Completed/On Hold | Type 2 | All sources |
| start_date | DATE | Project start date | Type 1 | All sources |
| end_date | DATE | Project end date | Type 1 | All sources |
| budget_amount | DECIMAL(15,2) | Total project budget | Type 2 | Sage 300 |
| location | VARCHAR(255) | Project location | Type 1 | All sources |
| effective_from | TIMESTAMP | SCD effective start timestamp | - | Generated |
| effective_to | TIMESTAMP | SCD effective end timestamp (NULL = current) | - | Generated |
| is_current | BOOLEAN | Current version flag | - | Generated |
| _source_system | VARCHAR(20) | sage300/bridgit/smartsheet | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |
| _hash_key | VARCHAR(64) | MD5 hash for change detection | - | Generated |

#### dim_person
| Column | Type | Description | SCD Type | Source |
|--------|------|-------------|----------|--------|
| person_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| person_id | VARCHAR(50) | Business key (employee ID) | - | All sources |
| first_name | VARCHAR(100) | First name | Type 1 | All sources |
| last_name | VARCHAR(100) | Last name | Type 1 | All sources |
| email | VARCHAR(255) | Email address | Type 1 | All sources |
| department | VARCHAR(100) | Department | Type 2 | Sage 300/Bridgit |
| job_title | VARCHAR(100) | Job title/role | Type 2 | Bridgit |
| hire_date | DATE | Hire date | Type 1 | Sage 300 |
| hourly_rate | DECIMAL(10,2) | Billable rate | Type 2 | Sage 300 |
| active_status | BOOLEAN | Active/Terminated | Type 2 | All sources |
| skills | JSONB | Skills array from Bridgit | Type 1 | Bridgit |
| effective_from | TIMESTAMP | SCD effective start timestamp | - | Generated |
| effective_to | TIMESTAMP | SCD effective end timestamp | - | Generated |
| is_current | BOOLEAN | Current version flag | - | Generated |
| _source_system | VARCHAR(20) | sage300/bridgit | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |
| _hash_key | VARCHAR(64) | MD5 hash for change detection | - | Generated |

#### dim_cost_code
| Column | Type | Description | SCD Type | Source |
|--------|------|-------------|----------|--------|
| cost_code_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| cost_code_id | VARCHAR(50) | Business key (cost code) | - | Sage 300 |
| cost_code_description | VARCHAR(255) | Description | Type 1 | Sage 300 |
| category | VARCHAR(100) | Labor/Material/Equipment | Type 1 | Sage 300 |
| phase | VARCHAR(100) | Project phase | Type 1 | Sage 300 |
| is_active | BOOLEAN | Active status | Type 1 | Sage 300 |
| _source_system | VARCHAR(20) | sage300 | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### dim_client
| Column | Type | Description | SCD Type | Source |
|--------|------|-------------|----------|--------|
| client_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| client_id | VARCHAR(50) | Business key | - | Sage 300/Smartsheet |
| client_name | VARCHAR(255) | Client name | Type 1 | All sources |
| contact_name | VARCHAR(255) | Primary contact | Type 1 | All sources |
| contact_email | VARCHAR(255) | Contact email | Type 1 | All sources |
| contact_phone | VARCHAR(50) | Contact phone | Type 1 | All sources |
| industry | VARCHAR(100) | Industry type | Type 1 | Smartsheet |
| contract_type | VARCHAR(50) | Fixed/T&M/Cost+ | Type 1 | Sage 300 |
| _source_system | VARCHAR(20) | sage300/smartsheet | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### dim_date
| Column | Type | Description | Source |
|--------|------|-------------|--------|
| date_key | INTEGER | YYYYMMDD format (primary key) | Generated |
| date_actual | DATE | Actual date | Generated |
| day_of_week | INTEGER | 1=Monday, 7=Sunday | Generated |
| day_name | VARCHAR(10) | Monday, Tuesday, etc. | Generated |
| week_of_year | INTEGER | ISO week number | Generated |
| month_number | INTEGER | 1-12 | Generated |
| month_name | VARCHAR(10) | January, February, etc. | Generated |
| quarter | INTEGER | 1-4 | Generated |
| year | INTEGER | Year | Generated |
| is_weekend | BOOLEAN | Saturday/Sunday flag | Generated |
| is_holiday | BOOLEAN | US holiday flag | Generated |
| fiscal_year | INTEGER | Fiscal year (if different from calendar) | Generated |
| fiscal_quarter | INTEGER | Fiscal quarter | Generated |

### Fact Tables (Detailed Schema)

#### fact_labor_hours
**Grain:** One row per person, per project, per cost code, per day

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| labor_hours_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| date_fk | INTEGER | Foreign key to dim_date | - | Sage 300 |
| project_fk | BIGINT | Foreign key to dim_project | - | Sage 300 |
| person_fk | BIGINT | Foreign key to dim_person | - | Sage 300 |
| cost_code_fk | BIGINT | Foreign key to dim_cost_code | - | Sage 300 |
| regular_hours | DECIMAL(8,2) | Regular hours worked | Additive | Sage 300 |
| overtime_hours | DECIMAL(8,2) | Overtime hours worked | Additive | Sage 300 |
| total_hours | DECIMAL(8,2) | Total hours (regular + OT) | Additive | Sage 300 |
| labor_cost | DECIMAL(12,2) | Total labor cost | Additive | Sage 300 |
| billable_amount | DECIMAL(12,2) | Billable amount to client | Additive | Sage 300 |
| _source_system | VARCHAR(20) | sage300 | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |
| _batch_id | VARCHAR(50) | Processing batch ID | - | Metadata |

#### fact_assignments
**Grain:** One row per person, per project, per role, per assignment period

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| assignment_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Bridgit |
| person_fk | BIGINT | Foreign key to dim_person | - | Bridgit |
| role_name | VARCHAR(100) | Role on project | - | Bridgit |
| allocation_percent | DECIMAL(5,2) | % allocation (0-100) | Semi-additive | Bridgit |
| start_date | DATE | Assignment start date | - | Bridgit |
| end_date | DATE | Assignment end date | - | Bridgit |
| duration_days | INTEGER | Duration in days | Additive | Calculated |
| is_active | BOOLEAN | Currently active assignment | - | Calculated |
| _source_system | VARCHAR(20) | bridgit | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_change_orders
**Grain:** One row per change order

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| change_order_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Sage 300 |
| change_order_number | VARCHAR(50) | CO number | - | Sage 300 |
| change_order_type | VARCHAR(50) | Owner/Internal/Subcontractor | - | Sage 300 |
| description | TEXT | CO description | - | Sage 300 |
| requested_date | DATE | Date requested | - | Sage 300 |
| approved_date | DATE | Date approved | - | Sage 300 |
| status | VARCHAR(50) | Pending/Approved/Rejected | - | Sage 300 |
| original_amount | DECIMAL(15,2) | Original CO amount | Additive | Sage 300 |
| approved_amount | DECIMAL(15,2) | Approved amount | Additive | Sage 300 |
| cost_impact | DECIMAL(15,2) | Cost impact on project | Additive | Sage 300 |
| schedule_impact_days | INTEGER | Schedule impact (days) | Additive | Sage 300 |
| _source_system | VARCHAR(20) | sage300 | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_pay_apps
**Grain:** One row per project, per billing period

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| pay_app_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Sage 300 |
| application_number | INTEGER | Pay app number (sequential) | - | Sage 300 |
| billing_period_start | DATE | Period start date | - | Sage 300 |
| billing_period_end | DATE | Period end date | - | Sage 300 |
| work_completed_to_date | DECIMAL(15,2) | Total work completed to date | Semi-additive | Sage 300 |
| materials_stored | DECIMAL(15,2) | Materials stored (not installed) | Semi-additive | Sage 300 |
| total_earned | DECIMAL(15,2) | Total earned this period | Additive | Sage 300 |
| retention_percent | DECIMAL(5,2) | Retention % | - | Sage 300 |
| retention_amount | DECIMAL(15,2) | Retention held | Additive | Sage 300 |
| amount_billed | DECIMAL(15,2) | Amount billed this period | Additive | Sage 300 |
| amount_paid | DECIMAL(15,2) | Amount paid | Additive | Sage 300 |
| payment_date | DATE | Date payment received | - | Sage 300 |
| status | VARCHAR(50) | Draft/Submitted/Approved/Paid | - | Sage 300 |
| _source_system | VARCHAR(20) | sage300 | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_rfis
**Grain:** One row per RFI per project

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| rfi_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Procore |
| rfi_number | VARCHAR(50) | RFI identifier | - | Procore |
| subject | VARCHAR(255) | RFI subject/title | - | Procore |
| question | TEXT | Question text | - | Procore |
| status | VARCHAR(50) | Open/Closed/Draft/etc. | - | Procore |
| created_date | DATE | RFI created date | - | Procore |
| due_date | DATE | Response due date | - | Procore |
| response_date | DATE | Date response submitted | - | Procore |
| days_open | INTEGER | Days between created and closed | Additive | Calculated |
| responsible_party_fk | BIGINT | Linked reviewer/assignee (dim_person) | - | Procore |
| cost_impact_flag | BOOLEAN | Indicates potential cost impact | - | Procore |
| schedule_impact_flag | BOOLEAN | Indicates potential schedule impact | - | Procore |
| attachments_count | INTEGER | Number of attachments | Additive | Procore |
| reopened_count | INTEGER | Number of times reopened | Additive | Procore |
| _source_system | VARCHAR(20) | procore | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_submittals
**Grain:** One row per submittal record per revision

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| submittal_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Procore |
| submittal_number | VARCHAR(50) | Submittal identifier | - | Procore |
| revision_number | INTEGER | Revision sequence | - | Procore |
| spec_section | VARCHAR(100) | Specification section | - | Procore |
| status | VARCHAR(50) | Draft/Pending/Approved/Returned | - | Procore |
| submitted_date | DATE | Date submitted | - | Procore |
| required_approval_date | DATE | Required approval date | - | Procore |
| actual_approval_date | DATE | Date approved/returned | - | Procore |
| turnaround_days | INTEGER | Days from submission to decision | Additive | Calculated |
| reviewer_fk | BIGINT | Reviewer (dim_person or dim_client contact) | - | Procore |
| is_overdue | BOOLEAN | Flag if past required approval date | - | Calculated |
| attachments_count | INTEGER | Number of attachments | Additive | Procore |
| revision_notes | TEXT | Reviewer comments | - | Procore |
| _source_system | VARCHAR(20) | procore | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_daily_logs
**Grain:** One row per project, per log date, per trade entry

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| daily_log_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Procore |
| date_fk | INTEGER | Foreign key to dim_date | - | Procore |
| trade_name | VARCHAR(100) | Trade/crew name | - | Procore |
| headcount | INTEGER | Workers onsite for trade | Additive | Procore |
| hours_worked | DECIMAL(8,2) | Total hours for trade | Additive | Procore |
| equipment_used | TEXT | Equipment summary | - | Procore |
| weather_summary | VARCHAR(255) | Weather notes (per log) | - | Procore |
| temperature_high | DECIMAL(5,2) | Recorded high temp (°F) | - | Procore |
| temperature_low | DECIMAL(5,2) | Recorded low temp (°F) | - | Procore |
| delays_flag | BOOLEAN | Indicates delays/issues reported | - | Procore |
| safety_incidents | INTEGER | Count of incidents noted | Additive | Procore |
| notes | TEXT | General notes | - | Procore |
| _source_system | VARCHAR(20) | procore | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_observations
**Grain:** One row per observation issue

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| observation_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Procore |
| observation_id | VARCHAR(50) | Observation identifier | - | Procore |
| observation_type | VARCHAR(50) | Safety/Quality/Progress/etc. | - | Procore |
| priority | VARCHAR(20) | Low/Medium/High/Critical | - | Procore |
| status | VARCHAR(50) | Open/Closed/Overdue | - | Procore |
| created_date | DATE | Observation created date | - | Procore |
| due_date | DATE | Target resolution date | - | Procore |
| closed_date | DATE | Actual resolution date | - | Procore |
| days_open | INTEGER | Days from created to closed | Additive | Calculated |
| assigned_to_fk | BIGINT | Assigned person/team (dim_person) | - | Procore |
| location | VARCHAR(255) | Location on site | - | Procore |
| photos_count | INTEGER | Attached photo count | Additive | Procore |
| corrective_action | TEXT | Resolution notes | - | Procore |
| _source_system | VARCHAR(20) | procore | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

#### fact_schedule_activities
**Grain:** One row per schedule activity per reporting date

| Column | Type | Description | Measure Type | Source |
|--------|------|-------------|--------------|--------|
| schedule_activity_sk | BIGSERIAL | Surrogate key (primary key) | - | Generated |
| project_fk | BIGINT | Foreign key to dim_project | - | Procore/MS Project |
| schedule_id | VARCHAR(50) | Activity identifier | - | Procore/MS Project |
| activity_name | VARCHAR(255) | Activity/task name | - | Procore/MS Project |
| wbs_code | VARCHAR(100) | Work breakdown structure code | - | Procore/MS Project |
| baseline_start_date | DATE | Baseline start | - | Procore/MS Project |
| baseline_finish_date | DATE | Baseline finish | - | Procore/MS Project |
| planned_start_date | DATE | Current planned start | - | Procore/MS Project |
| planned_finish_date | DATE | Current planned finish | - | Procore/MS Project |
| actual_start_date | DATE | Actual start date | - | Procore/MS Project |
| actual_finish_date | DATE | Actual finish date | - | Procore/MS Project |
| percent_complete | DECIMAL(5,2) | % complete (0-100) | Semi-additive | Procore/MS Project |
| critical_path_flag | BOOLEAN | Indicates critical path activity | - | Procore/MS Project |
| total_float_days | INTEGER | Total float/slack in days | Additive | Procore/MS Project |
| reporting_date | DATE | Snapshot date (for S-curve) | - | Procore/MS Project |
| cumulative_planned_value | DECIMAL(15,2) | Cumulative planned value | Additive | Calculated |
| cumulative_actual_value | DECIMAL(15,2) | Cumulative actual value | Additive | Calculated |
| _source_system | VARCHAR(20) | procore/msproject | - | Metadata |
| _ingested_at | TIMESTAMP | Ingestion timestamp | - | Metadata |

## Data Quality & Governance
- Great Expectations test suites:
  - Row count thresholds.
  - Null, range, and uniqueness tests.
  - Referential integrity checks.
  - Freshness (max lag thresholds).
- dbt tests and contracts defined in `schema.yml`.

## Orchestration Workflow
1. Airbyte runs ingestion (incremental).
2. Great Expectations validates Bronze layer.
3. dbt transforms → Silver → Gold.
4. Post-transform GE checks.
5. Load into Metabase.
6. Emit success/failure metrics to monitoring.

## Deployment
### Local (Docker Compose)
- Services: Airbyte, Postgres, Redis, FastAPI, dbt, GE, Metabase.
- `.env.example` defines secrets and endpoints.
- `make init` → bootstrap stack.

### Production (Kubernetes + Helm)
- Namespaces: `data-ingest`, `data-transform`, `data-serve`.
- Components: Postgres, Redis, Airbyte, dbt, GE, FastAPI, Metabase.
- Managed secrets (SealedSecrets), resource limits, ingress with TLS.
- CI/CD pipeline for container build, test, and deploy.

## Security
- Read-only DB users for source systems.
- Secrets stored in environment variables or vault.
- Encrypted data at rest (Postgres + S3 backup).
- Network policies restrict egress.

## Observability
- Logging: Structured JSON → OpenSearch/ELK.
- Metrics: Prometheus → Grafana.
- Alerts: Failing tests, missing data, job duration anomalies.

## Future Source Onboarding Template
1. Define connection & auth details.
2. Add Airbyte connector or custom Python module.
3. Build dbt staging & normalized models.
4. Add GE suite.
5. Update Metabase seed dashboards.
6. Document in `new_source_checklist.md`.

## Acceptance Criteria

### System-Wide Acceptance
- **AC-001:** End-to-end pipeline run completes successfully with all four data sources (Smartsheet, Sage 300, Procore, Bridgit Bench)
- **AC-002:** Incremental updates are idempotent (re-running same data produces same results)
- **AC-003:** Data validation coverage ≥ 95% (Great Expectations + dbt tests across Bronze/Silver/Gold)
- **AC-004:** System uptime meets 99.5% SLA (excluding planned maintenance windows)
- **AC-005:** Daily data refresh completes by 9am with T+1 data (previous day's data available)

### Data Integration Acceptance
- **AC-006:** Smartsheet estimating pipeline data (YY-4-### jobs) ingested with all fields from Webster Tracking sheet
- **AC-007:** Sage 300 financial data (YY-1-### jobs) ingested via ODBC with CSV fallback functional
- **AC-008:** Procore RFIs, submittals, daily logs, observations, and schedules ingested via API
- **AC-009:** Bridgit Bench people and assignments ingested via API
- **AC-010:** Estimate-to-project conversion tracking operational with automated fuzzy matching (≥90% confidence auto-links)

### Advanced Features Acceptance
- **AC-011:** Schedule validation S-curve analysis functional: compare Procore/MS Project schedules vs. pay app billing
- **AC-012:** Schedule health scoring (Green/Yellow/Red) calculated monthly with PM alerts for Red status (>15% variance)
- **AC-013:** Reverse sync to Bridgit Bench operational: forecasted manpower assignments written daily for projects starting within 90 days
- **AC-014:** Reverse sync conflict resolution working: manual Bridgit assignments not overwritten by system forecasts

### Dashboard Acceptance
- **AC-015:** Estimating dashboard: Pipeline value by status, win rate, revenue forecast, estimator workload
- **AC-016:** Operations dashboard: Labor hours by project/cost code, change order summary, WIP exposure, pay app status
- **AC-017:** Field/PM dashboard: RFI cycle time, submittal status, daily log metrics, schedule health with S-curve visualization
- **AC-018:** Leadership dashboard: Resource utilization, company-wide financial performance, project portfolio health
- **AC-019:** All dashboards refresh daily by 9am with role-based access controls functional

### Quality & Governance Acceptance
- **AC-020:** OpenMetadata catalog operational with lineage tracking from source systems through Gold layer
- **AC-021:** Audit logging captures all user access, API calls, configuration changes, and reverse sync writes
- **AC-022:** Data quality monitoring dashboard (Grafana) shows test pass/fail rates, data freshness, row counts
- **AC-023:** Alert system functional: email/Slack notifications for pipeline failures, data quality issues, schedule health alerts

### Extensibility Acceptance
- **AC-024:** New data source onboarding template documented and tested (≤3 business days for new source)
- **AC-025:** Reverse sync framework extensible to additional target systems beyond Bridgit Bench

---
**Author:** Steven Goettl II
**Version:** 2.0
**Date:** November 2025
**Last Updated:** November 4, 2025
