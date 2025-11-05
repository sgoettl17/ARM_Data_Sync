# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Construction Data Sync** is a **bidirectional data synchronization and analytics platform** for the construction industry, currently in **specification development phase (75% complete)**. The system unifies four data sources into a governed data warehouse with advanced analytics and resource forecasting capabilities.

### Data Sources (4 Systems)
1. **Smartsheet** - Pre-construction estimating pipeline (YY-4-### jobs)
2. **Sage 300** - Active project financials via ODBC (YY-1-### jobs)
3. **Procore** - Field execution tracking (RFIs, submittals, daily logs, schedules)
4. **Bridgit Bench** - Resource planning with **reverse sync** (read + write)

### Key Architectural Patterns
- **Medallion Architecture:** Bronze (raw) → Silver (normalized) → Gold (curated)
- **Dimensional Modeling:** Star schema with SCD Type 2 for history tracking
- **Job Number Conversion:** Fuzzy matching estimates (YY-4-###) to operations (YY-1-###)
- **Schedule Validation:** S-curve analysis comparing Procore schedules vs. pay app billing
- **Reverse Sync:** Push forecasted manpower assignments back to Bridgit Bench

---

## Repository Structure

```
ARM_Data_Sync/
├── .claude/
│   ├── agents/               # 15 specialized subagents for spec development
│   │   ├── bridgit-bench-api-guru.md
│   │   ├── claude-md-sync.md
│   │   ├── dagster-expert.md
│   │   ├── dbt-best-practices-guru.md
│   │   ├── docker-expert.md
│   │   ├── file-organizer.md
│   │   ├── great-expectations-guru.md
│   │   ├── meltano-guru.md
│   │   ├── postgresql-guru.md
│   │   ├── procore-api-guru.md
│   │   ├── quick-search.md
│   │   ├── sage300-odbc-expert.md
│   │   ├── smartsheet-api-expert.md
│   │   ├── spec-validator.md
│   │   └── tech-stack-architect.md
│   └── settings.local.json
├── Planning/
│   ├── construction_data_sync_spec.md      # PRIMARY SPECIFICATION (v2.0)
│   ├── SESSION_SUMMARY_2025-11-04.md       # Decision log & remaining work
│   ├── TOOLING_RECOMMENDATIONS_2025-11-05.md # Subagent roadmap
│   └── Sources/                             # Reference materials
│       ├── Bridgitbench/
│       ├── sage300/
│       └── smartsheet/
├── CLAUDE.md                                # This file
└── (Implementation directories will be created during Phase 2)
```

---

## Current Implementation Status

**Phase:** Specification Development (no implementation code yet)

This repository is currently in the **specification phase**. There are no build commands, test suites, or deployment scripts yet because implementation will begin in Phase 2 after specification approval.

**What Exists:**
- Comprehensive specification document (~1,100 lines)
- 15 specialized agents for specification development
- Planning documents and decision logs
- Source system reference materials

**What Will Be Created in Phase 2:**
- `src/` - Python connectors and orchestration code
- `dbt/` - Data transformation models (staging → intermediate → marts)
- `dagster/` - Asset definitions and orchestration workflows
- `great_expectations/` - Data quality test suites
- `kubernetes/` - Deployment manifests
- `docker/` - Container definitions and docker-compose files
- `tests/` - Unit, integration, and end-to-end tests
- `docs/` - Generated documentation and API specs

**Development Commands (Future):**
Once implementation begins, typical commands will include:
```bash
# dbt commands
dbt run --models staging      # Run staging transformations
dbt test                       # Run data quality tests
dbt docs generate && dbt docs serve  # Generate documentation

# Dagster commands
dagster dev                    # Start Dagster web server
dagster asset materialize --select gold_*  # Materialize gold layer

# Testing
pytest tests/                  # Run Python tests
great_expectations checkpoint run bronze_validation  # Run GE tests

# Docker
docker-compose up -d           # Start local environment
```

---

## Working with Specifications

### Primary Document
**`Planning/construction_data_sync_spec.md`** (v2.0, ~1,100 lines)

This is the **source of truth** for all architectural decisions. Always reference this before making recommendations.

**Key Sections:**
- Overview & Objectives (lines 1-30)
- Technology Stack (lines 31-42)
- Architecture & Data Flow (lines 43-110)
- Data Sources (lines 117-224): Smartsheet, Sage 300, Procore, Bridgit
- Job Number Conversion Logic (lines 226-353): Critical business rules
- Schedule Validation & S-Curve (lines 355-472): Advanced analytics
- Reverse Sync (lines 474-650): Bidirectional integration
- Requirements (lines 671-801): FR-001 through FR-012
- Data Model (lines 849-1020): Dimensions, facts, SCD strategy
- Acceptance Criteria (lines 1069-1107): 25 detailed AC

### Completion Status (as of Nov 5, 2025)

| Component | Status | Blocking Issue |
|-----------|--------|----------------|
| Overview & Architecture | ✅ 100% | - |
| Technology Stack | ✅ 100% | - |
| Functional Requirements | ✅ 100% | - |
| Data Model (core) | ⚠️ 70% | Missing 5 Procore fact tables |
| Business Rules | ⚠️ 40% | Timeline rules undefined |
| Implementation Roadmap | ❌ 0% | HIGH PRIORITY - needed before dev |
| Cost Estimation | ❌ 0% | HIGH PRIORITY - needed for approval |
| Orchestration Details | ⚠️ 50% | Still references Celery; needs Dagster update |

---

## Technology Stack

### Core Technologies
- **ETL:** Airbyte + custom Python connectors
- **Transformation:** dbt (data modeling, version control, testing)
- **Validation:** Great Expectations (data quality at Bronze & Gold)
- **Storage:** PostgreSQL with streaming replication (HA)
- **Orchestration:** **Dagster** (asset-based workflow, NOT Celery)
- **Catalog:** OpenMetadata (lineage tracking)
- **Visualization:** Metabase (4 stakeholder dashboards)
- **API:** FastAPI (OAuth2 + API key auth)
- **Monitoring:** Prometheus + Grafana
- **Infrastructure:** Docker Compose (local) / Kubernetes (prod)

### Important Notes
- **Dagster vs. Celery:** Specification is transitioning from Celery to Dagster. Always reference Dagster for orchestration.
- **SCD Type 2:** Dimensions use hybrid strategy (Type 2 for critical attrs like status/budget, Type 1 for descriptive fields)
- **Rate Limits:** Procore: 3600 req/hr per project; Bridgit: 100 req/min (requires 600ms delays)

---

## Job Number System (Critical Business Logic)

### Format: YY-C-###
- **YY** = Year (25 = 2025)
- **C** = Category:
  - **1** = Operations/Active Projects (Sage 300 master)
  - **4** = Estimating Projects (Smartsheet pipeline)
- **###** = Sequential number

### Master Data Hierarchy
1. **Primary:** Sage 300 (YY-1-### jobs)
2. **Secondary:** Network folders `\\armays-fs1\...\Jobs 2025\YY-1-###\` (when not yet in Sage)
3. **Estimating:** Smartsheet (YY-4-### jobs)

### Conversion Scenarios
- **Scenario A (1:1):** Single estimate → single operations job
- **Scenario B (N:1):** Multiple estimates → single job with phased COs
- **Scenario C (1:N):** Single estimate → multiple jobs (different owners)

**Fuzzy Matching Thresholds:**
- ≥90% confidence → Auto-link
- 75-89% confidence → Flag for manual review
- <75% confidence → No auto-link (manual entry required)

---

## Data Model Architecture

### Dimensional Model (Star Schema)

**Dimensions (Conformed):**
- `dim_project` - Unified across all sources (SCD Type 2)
- `dim_person` - Employees with skills & rates (SCD Type 2)
- `dim_cost_code` - Hierarchical cost structure
- `dim_client` - Customer/owner master
- `dim_date` - Time dimension with fiscal calendar

**Facts (Transactional Grain):**
- `fact_labor_hours` - Grain: person × project × cost code × day
- `fact_assignments` - Grain: person × project × role × period
- `fact_change_orders` - Grain: one row per CO
- `fact_pay_apps` - Grain: project × billing period

**Bridge Tables:**
- `bridge_estimate_to_project` - Maps YY-4-### to YY-1-### with confidence scores

### Missing Schemas (URGENT)
The following tables are **referenced but not yet defined** in the specification:

1. **Procore fact tables** (5 tables):
   - `fact_rfis` - RFI tracking
   - `fact_submittals` - Submittal workflow
   - `fact_daily_logs` - Field logs by project × day
   - `fact_observations` - Safety/quality observations
   - `fact_schedule_activities` - Schedule tasks

2. **Gold layer tables** (6 tables):
   - `gold_estimating_pipeline` - Pipeline metrics, win rates
   - `gold_schedule_health` - S-curve variance scoring
   - `gold_forecasted_assignments` - Reverse sync source
   - `gold_rfi_cycle_time` - RFI response times
   - `gold_submittal_performance` - Submittal approval metrics
   - `gold_cross_lifecycle_metrics` - Bid-to-award timelines

3. **Audit tables** (3 tables):
   - `audit_reverse_sync` - Bridgit write-back logs
   - `audit_data_quality` - Great Expectations test results
   - `audit_user_access` - Authentication/API logs

---

## Using Specialized Agents

This repository has **15 specialized agents** configured in `.claude/agents/`. **Always use agents proactively** for domain-specific tasks.

### Available Agents

| Agent | Purpose |
|-------|---------|
| **bridgit-bench-api-guru** | Bridgit Bench API integration, resource planning, reverse sync |
| **claude-md-sync** | Keep CLAUDE.md updated with code changes and patterns |
| **dagster-expert** | Dagster orchestration, asset graphs, workflow design |
| **dbt-best-practices-guru** | dbt modeling, transformations, dimensional design, SQL optimization |
| **docker-expert** | Docker containerization, docker-compose, multi-stage builds |
| **file-organizer** | File system operations, directory organization |
| **great-expectations-guru** | Data quality validation, expectation suites, test design |
| **meltano-guru** | Meltano ELT pipelines, Singer taps/targets |
| **postgresql-guru** | PostgreSQL schema design, query optimization, administration |
| **procore-api-guru** | Procore API integration, field execution tracking |
| **quick-search** | Fast file and code pattern searches |
| **sage300-odbc-expert** | Sage 300 ODBC integration, ERP data extraction |
| **smartsheet-api-expert** | Smartsheet API integration, estimating pipeline |
| **spec-validator** | Validate specifications for completeness and consistency |
| **tech-stack-architect** | Technology stack decisions, architectural recommendations, technical specs |

### Recommended Agent Usage Patterns

#### For Data Model Work
```
Use @postgresql-guru to design fact/dimension table schemas
Use @dbt-best-practices-guru to structure dbt transformations
Use @great-expectations-guru for data quality validation rules
```

#### For API Integration
```
Use @smartsheet-api-expert for estimating pipeline integration
Use @sage300-odbc-expert for financial data extraction (ODBC + CSV fallback)
Use @bridgit-bench-api-guru for resource planning + reverse sync
```

#### For Project Management
```
Use @project-manager to track specification completion tasks
Use @claude-code-optimizer to ensure efficient tool usage
```

### Parallel Agent Invocation (Preferred)
**Always run 3 agents in parallel when possible** to maximize efficiency:

```markdown
# Example: Complete Procore data model
@postgresql-guru Design fact_rfis and fact_submittals schemas
@dbt-best-practices-guru Design staging models for Procore
@great-expectations-guru Define data quality tests for Procore entities
```

---

## Common Development Workflows

### 1. Completing Missing Specifications

**High Priority Tasks (Blocks Implementation):**

1. **Complete Procore Data Model**
   ```
   Agent: @postgresql-guru
   Task: Generate DDL for 5 Procore fact tables
   Input: Review FR-010 and existing fact table patterns
   Output: CREATE TABLE statements with indexes
   ```

2. **Generate Implementation Roadmap**
   ```
   Agent: @project-manager
   Task: Create 12-16 week phased plan (MVP → Production)
   Input: Review SESSION_SUMMARY remaining work
   Output: Gantt chart with milestones and dependencies
   ```

3. **Create Cost Estimation**
   ```
   Agent: @claude-code-optimizer
   Task: Calculate infrastructure, personnel, operational costs
   Input: Review NFR-002 (scalability) and NFR-005 (retention)
   Output: 3-year TCO with ROI analysis
   ```

4. **Document Timeline Business Rules**
   ```
   Agents: @project-manager + @dbt-best-practices-guru
   Task: Formalize bid-to-award, RFI response time calculations
   Output: SQL implementations for running averages
   ```

### 2. Updating Specifications

**Always follow this pattern:**
1. Read `Planning/construction_data_sync_spec.md` to understand context
2. Identify the section to update (use line numbers for precision)
3. Use `Edit` tool to make surgical changes (preserve formatting)
4. Update the "Last Updated" date at bottom of file
5. If adding new requirements, increment FR-### or AC-### numbers

**Example:**
```markdown
# Adding new requirement
Last FR: FR-012 (Reverse Sync to Bridgit Bench)
Next FR: FR-013 (your new requirement)

Last AC: AC-025 (Reverse sync framework extensible)
Next AC: AC-026 (your new acceptance criterion)
```

### 3. Validating Against Requirements

Before proposing any design, validate against:
- **Functional Requirements:** FR-001 through FR-012
- **Non-Functional Requirements:** NFR-001 through NFR-008
- **Business Rules:** BR-001 through BR-012
- **Acceptance Criteria:** AC-001 through AC-025

### 4. Architecture Decision Records

When making architectural decisions:
1. Document rationale in specification
2. Update `SESSION_SUMMARY` decision log
3. Consider impact on 4 data sources
4. Validate against 99.5% uptime SLA (NFR-003)

---

## Data Freshness SLA (Critical)

**Non-Negotiable Timeline (Daily):**
- **6:00am:** Airbyte begins Bronze layer ingestion
- **6:30am:** Great Expectations validates Bronze
- **6:50am:** dbt transformations begin (Silver → Gold)
- **8:15am:** Great Expectations validates Gold
- **8:30am:** Metabase dashboards refresh
- **9:00am:** Dashboards live + Reverse sync to Bridgit runs

**If pipeline fails:**
- Email alert within 5 minutes
- Slack notification for data quality warnings
- PM alert if schedule health Red status (>15% variance)

---

## Key Business Rules to Preserve

### BR-001: Incremental Keys by Source
- Smartsheet: `modifiedAt`
- Sage 300: `Accounting_Date` or `updated_at`
- Procore: `updated_at`
- Bridgit: `updated_at`

### BR-002: Hybrid SCD Strategy
- **Type 2** (track history): status, budget, department, job_title, hourly_rate, active_status
- **Type 1** (overwrite): project_name, email, hire_date

### BR-003: Entity Matching
- **Projects:** Levenshtein distance with manual review workflow
- **People:** Email-based exact match (primary), name-based fuzzy (fallback)

### BR-009: Master Data Hierarchy
1. Sage 300 YY-1-### jobs (source of truth for operations)
2. Network folders (fallback when not yet in Sage)
3. Smartsheet YY-4-### jobs (pipeline only)

### BR-010: Procore Rate Limiting
- 3600 requests/hour per project
- Batch requests and add delays
- Fallback to MS Project XML files from network folders

### BR-011: S-Curve Variance Thresholds
- **Green:** ≤5% variance (schedule aligned with billing)
- **Yellow:** 5-15% variance (warning)
- **Red:** >15% variance (critical - alert PM)

### BR-012: Reverse Sync Governance
- Only write to "forecast" tagged assignments
- Manual assignments (created_by != 'system') take precedence
- Rate limit: 100 req/min (600ms delays)
- Retry 3× with exponential backoff, then alert
- Only write projects starting within 90 days

---

## Anti-Patterns to Avoid

### ❌ DON'T:
- Reference Celery for orchestration (use Dagster)
- Create overly-broad agents (single responsibility per agent)
- Skip agent usage for specialized tasks (agents are faster + more accurate)
- Make architectural changes without validating against requirements
- Propose designs without considering all 4 data sources
- Ignore rate limiting requirements (Procore: 3600/hr, Bridgit: 100/min)
- Overwrite manual assignments in Bridgit Bench
- Skip SCD Type 2 for critical dimension attributes

### ✅ DO:
- Use Dagster for orchestration (asset-based workflow)
- Create focused, single-responsibility agents with YAML frontmatter
- Run 3 agents in parallel whenever possible
- Validate all designs against FR-001 through FR-012
- Consider cross-system entity matching in all designs
- Respect API rate limits with batching and delays
- Preserve manual assignments (human takes precedence)
- Track history for status, budget, department, title, rate changes

---

## Next Steps (Priority Order)

### Week 1-2: Complete Core Specification
1. ✅ **Procore Integration Specialist** → 5 fact tables
2. ✅ **Data Architect** → PostgreSQL DDL for all 13+ tables
3. ✅ **Business Rules Analyst** → Timeline business rules
4. ✅ **S-Curve Analytics** → Schedule health algorithms

### Week 2-3: Strategic Planning
5. ❌ **Implementation Roadmap** → 12-16 week phased plan
6. ❌ **Cost Estimation** → Infrastructure + personnel costs
7. ❌ **Dagster Orchestration** → Update spec with asset graph

### Week 3-4: Technical Design
8. ❌ **Entity Matching Engine** → Fuzzy matching logic
9. ❌ **Reverse Sync Orchestrator** → Bridgit write-back design
10. ❌ **dbt Model Scaffolder** → Generate ~20+ models

### Week 4-5: Documentation & Approval
11. ❌ **Technical Documentation** → Data dictionary, runbooks
12. ❌ **ERD Generator** → Visual diagrams
13. ❌ **Executive Summary** → Stakeholder approval documents

---

## Reference Documents

- **Primary Spec:** `Planning/construction_data_sync_spec.md` (v2.0)
- **Decision Log:** `Planning/SESSION_SUMMARY_2025-11-04.md`
- **Agent Roadmap:** `Planning/TOOLING_RECOMMENDATIONS_2025-11-05.md`

---

## User Preferences

- **Agent Usage:** Utilize agents as much as possible
- **Parallel Execution:** Use 3 agents in parallel to accomplish tasks
- **Decision Making:** Suggest 2 or more solutions to every problem for selection

---

**Last Updated:** November 5, 2025 (updated via /init command)
**Specification Version:** 2.0 (75% complete → targeting 100%)
**Project Phase:** Specification Development (no implementation code yet)
**Repository Status:** Specification-phase only; implementation directories will be created in Phase 2
