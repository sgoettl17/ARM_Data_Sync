# Construction Data Sync - Tooling Recommendations
**Date:** November 5, 2025
**Purpose:** Specialized subagents, skills, MCPs, and output styles to accelerate specification development

---

## Executive Summary

This document outlines **10 specialized subagents**, **6 reusable skills**, **5 MCP integrations**, and **6 output style templates** designed to complete the Construction Data Sync specification from its current 75% completeness to 100% production-ready state.

**Target Completion:** 5-6 weeks across 5 phases
**Primary Focus:** Complete Procore data model, generate implementation roadmap, formalize business rules, create cost estimates, and produce stakeholder documentation.

---

## 🤖 USER SUBAGENTS (Role-Based AI Assistants)

### 1. Data Architect Agent
**Purpose:** Design dimensional models, fact/dimension tables, DDL schemas

**Why You Need It:** You have 5 incomplete Procore fact tables and need consistent SCD Type 2 implementation across 13+ tables

**Key Responsibilities:**
- Generate PostgreSQL DDL for `fact_rfis`, `fact_submittals`, `fact_daily_logs`, `fact_observations`, `fact_schedule_activities`
- Design indexes, constraints, and SCD Type 2 tracking columns
- Create ERD diagrams from specifications
- Validate referential integrity across dimensional model
- Define grain, measures, and foreign keys for each fact table

**Inputs Required:**
- Current specification (construction_data_sync_spec.md)
- Existing dimension table schemas (dim_project, dim_person, dim_cost_code, dim_client, dim_date)
- Procore entity requirements from FR-010

**Expected Outputs:**
- Complete DDL for 5 Procore fact tables
- Index definitions for query optimization
- Foreign key constraint specifications
- SCD Type 2 implementation patterns
- Data type mappings from Procore API to PostgreSQL

---

### 2. Implementation Roadmap Agent
**Purpose:** Create detailed project timelines, resource allocation plans, milestone tracking

**Why You Need It:** Your spec identifies this as HIGH PRIORITY missing work (12-16 week phased roadmap)

**Key Responsibilities:**
- Generate 4-phase implementation plan (MVP → Full Integration → Hardening → Production)
- Break down 75% complete spec into actionable weekly milestones
- Allocate 1 Senior Data Engineer across timeline with dependency mapping
- Define testing strategy checkpoints by phase
- Identify critical path and risk mitigation checkpoints

**Inputs Required:**
- Current specification completeness assessment (75%)
- Resource constraint (1 Senior Data Engineer)
- Complexity estimates from session summary
- Stakeholder availability for reviews

**Expected Outputs:**
- 12-16 week Gantt chart with weekly milestones
- Phase definitions with entry/exit criteria
- Resource allocation calendar
- Testing strategy by phase (unit, integration, E2E)
- Risk mitigation schedule with checkpoints

---

### 3. Cost Estimation Agent
**Purpose:** Calculate infrastructure, personnel, and operational costs with industry benchmarks

**Why You Need It:** Cost estimation section is completely missing from your spec

**Key Responsibilities:**
- Estimate PostgreSQL + Redis infrastructure costs (compute, storage, backup)
- Calculate Kubernetes cluster costs (3 namespaces, multi-replica deployments)
- Personnel cost analysis (1 Senior DE × 12-16 weeks at market rate)
- License cost identification (Dagster, OpenMetadata, Metabase - all open-source but verify)
- 3-year TCO projection

**Inputs Required:**
- Infrastructure requirements (PostgreSQL with HA, Redis Sentinel, Kubernetes)
- Data volume estimates (200 projects, 1M+ rows per fact table)
- 50 concurrent dashboard users
- Data retention policy (1 year Bronze, 3 years Silver/Gold, 7 years audit logs)

**Expected Outputs:**
- Detailed infrastructure cost breakdown (compute, storage, networking, backup)
- Personnel costs with hourly rate assumptions
- Operational costs (monitoring, maintenance, support)
- 3-year TCO with year-over-year projections
- ROI analysis based on efficiency gains and data quality improvements

---

### 4. Technical Documentation Agent
**Purpose:** Generate runbooks, data dictionaries, API documentation, user guides

**Why You Need It:** Medium-priority gap includes data dictionary, security architecture docs, DR plans

**Key Responsibilities:**
- Field-level data dictionary with business definitions and sample values
- Disaster recovery runbooks (backup/restore procedures, RTO/RPO compliance)
- API documentation in OpenAPI/Swagger format
- End-user dashboard guides for 4 stakeholder personas
- Change management process documentation

**Inputs Required:**
- Table schemas from Data Architect Agent
- API endpoint specifications
- Stakeholder roles and information needs
- Security requirements (NFR-006)
- DR requirements (NFR-003: RTO 2 hours, RPO 24 hours)

**Expected Outputs:**
- Comprehensive data dictionary (CSV or searchable HTML)
- DR runbooks with step-by-step procedures
- OpenAPI 3.0 specification for FastAPI endpoints
- User guides tailored to each stakeholder persona
- Security architecture documentation (OAuth2, API keys, TLS)

---

### 5. Business Rules Analyst Agent
**Purpose:** Formalize business logic, calculate metrics, define validation thresholds

**Why You Need It:** Timeline business rules section is undefined (bid-to-award, RFI response times, etc.)

**Key Responsibilities:**
- Formalize bid-to-award duration calculations by owner/project type
- Define buyout duration formulas and Smartsheet "Approx. Start Date" auto-update logic
- Set RFI response time baselines and submittal approval cycle benchmarks
- Document fuzzy matching thresholds and manual review workflows
- Define data quality thresholds and alerting logic

**Inputs Required:**
- Historical project data patterns (if available)
- Stakeholder expectations for timeline predictions
- Current specification business rules (BR-001 through BR-012)
- Fuzzy matching confidence thresholds (≥90% auto, 75-89% review)

**Expected Outputs:**
- Formal business rule definitions with calculation formulas
- SQL implementation for running average calculations
- Threshold specifications for alerts (Green/Yellow/Red)
- Manual review workflow process diagrams
- Data quality validation rule catalog

---

## 📊 PROJECT SUBAGENTS (Domain-Specific Specialists)

### 1. Procore Integration Specialist
**Purpose:** Design complete Procore data model and API integration patterns

**Why You Need It:** Procore entities are the largest missing piece (5 fact tables undefined)

**Key Responsibilities:**
- Complete schemas for all 5 Procore fact tables with grain definitions
- Design rate limiting strategy (3600 req/hr per project)
- Implement MS Project XML fallback parser for schedule data
- Map Procore entities to `dim_project` via YY-1-### job numbers
- Generate Great Expectations tests for Procore data quality

**Technical Details:**
- **API:** Procore REST API v1.0 with OAuth 2.0
- **Rate Limit:** 3600 requests/hour per project (requires batching and delays)
- **Incremental Key:** `updated_at` for all entities
- **Fallback:** MS Project .mpp files from network folders

**Expected Outputs:**
- `fact_rfis` schema (grain: one row per RFI)
- `fact_submittals` schema (grain: one row per submittal revision)
- `fact_daily_logs` schema (grain: one row per project, per day)
- `fact_observations` schema (grain: one row per observation)
- `fact_schedule_activities` schema (grain: one row per schedule task)
- Procore API connector configuration for Airbyte
- Great Expectations test suite for Procore data (nulls, types, ranges, relationships)

---

### 2. S-Curve Analytics Specialist
**Purpose:** Develop schedule validation algorithms and dual S-curve generation logic

**Why You Need It:** S-curve analysis is architecturally complex (financial vs. schedule variance)

**Key Responsibilities:**
- Generate SQL for financial S-curve (cumulative % billed from pay apps)
- Generate SQL for schedule S-curve (cumulative % complete from Procore/MS Project)
- Implement variance calculation and health scoring (Green/Yellow/Red)
- Design PM alert workflow for >15% variance over 2 consecutive months
- Create dashboard visualization specifications (dual S-curves with variance shading)

**Algorithm Requirements:**
- **Financial S-Curve:** `SUM(work_completed_to_date) OVER (PARTITION BY project_fk ORDER BY billing_period_end)`
- **Schedule S-Curve:** `SUM(planned_value) OVER (PARTITION BY project_fk ORDER BY schedule_date)`
- **Variance:** `schedule_percent - financial_percent`
- **Health Scoring:**
  - Green: ≤5% variance (aligned)
  - Yellow: 5-15% variance (warning)
  - Red: >15% variance (critical)

**Expected Outputs:**
- `gold_schedule_health` table schema and dbt model
- SQL queries for dual S-curve generation
- Variance calculation logic with health scoring
- Alert trigger conditions (Red status for 2+ consecutive months)
- Dashboard mockup with dual S-curve visualization

---

### 3. Reverse Sync Orchestrator
**Purpose:** Design bidirectional Bridgit Bench integration with conflict resolution

**Why You Need It:** Reverse sync is HIGH complexity with 4-step calculation logic

**Key Responsibilities:**
- Design Dagster asset for 4-step reverse sync (awards → roles → people → write)
- Implement historical staffing pattern analysis by project type/size
- Create resource availability matching algorithm with capacity constraints
- Design conflict resolution (manual assignments take precedence)
- Implement rate limiting (100 req/min) and audit trail logging

**4-Step Logic:**
1. **Identify New Awards:** Find estimates converted to operations jobs in last 7 days, starting within 90 days
2. **Calculate Required Roles:** Use historical staffing patterns by project type/size
3. **Match to Available People:** Find people with matching skills and capacity (< 100% utilized)
4. **Write to Bridgit API:** Create "forecast" assignments via REST API

**Technical Constraints:**
- **Rate Limit:** 100 requests/minute (requires 600ms delays between writes)
- **Conflict Resolution:** Manual assignments (`created_by != 'system'`) take precedence
- **Scope:** Only projects starting within next 90 days
- **Tagging:** All writes tagged "forecast" or "auto-generated"

**Expected Outputs:**
- `gold_forecasted_assignments` table schema and dbt model
- Dagster asset: `bridgit_write_forecasted_assignments`
- Historical staffing pattern SQL query
- Resource availability matching algorithm (SQL + Python)
- Conflict detection and resolution logic
- Audit trail table: `audit_reverse_sync`

---

### 4. Dagster Orchestration Designer
**Purpose:** Replace Celery references with Dagster asset graph and configurations

**Why You Need It:** Orchestration section is outdated and needs Dagster-specific rewrite

**Key Responsibilities:**
- Design complete Dagster asset graph with dependencies
- Define asset groups (ingestion, validation, transformation, reverse_sync, catalog)
- Create sensor definitions for source update triggers
- Configure daily schedule (Bronze by 6am, Gold by 8:30am, dashboards by 9am)
- Design Great Expectations integration as Dagster assets

**Asset Groups:**
1. **ingestion:** Airbyte connectors (smartsheet, sage300, procore, bridgit)
2. **validation_bronze:** Great Expectations Bronze layer tests
3. **transformation:** dbt Silver → Gold models
4. **validation_gold:** Great Expectations Gold layer tests
5. **reverse_sync:** Bridgit write-back asset
6. **catalog:** OpenMetadata lineage update

**Expected Outputs:**
- Complete Dagster asset graph (Mermaid diagram or Python code)
- Asset group definitions with dependencies
- Daily schedule configuration (SLA-based: Bronze 6am, Gold 8:30am, dashboards 9am)
- Sensor definitions for ad-hoc triggers
- Great Expectations integration pattern
- Update to specification orchestration section

---

### 5. Entity Matching Engine
**Purpose:** Develop job number conversion fuzzy matching algorithm and manual review workflow

**Why You Need It:** Estimate-to-project conversion is CRITICAL complexity (3 scenarios)

**Key Responsibilities:**
- Implement Levenshtein distance algorithm with ≥90% auto-link, 75-89% review threshold
- Design manual review dashboard UI/UX specifications
- Create `bridge_estimate_to_project` table with confidence scoring
- Implement network folder fallback logic for missing Sage 300 jobs
- Handle 3 conversion scenarios (direct 1:1, phased N:1, split 1:N)

**Matching Algorithm:**
1. Detect awarded estimates (Smartsheet status = "Post Pending")
2. Query Sage 300 for new YY-1-### jobs created within 60 days of bid due date
3. Normalize names (lowercase, remove punctuation, trim)
4. Calculate Levenshtein distance between estimate name and operations job name
5. Apply confidence thresholds:
   - **≥90%:** Auto-link, mark HIGH confidence
   - **75-89%:** Flag for manual review, mark MEDIUM confidence
   - **<75%:** No auto-link, mark LOW confidence

**3 Conversion Scenarios:**
- **Scenario A (Direct 1:1):** Single estimate → single operations job
- **Scenario B (Phased N:1):** Multiple estimates → single operations job with phased COs
- **Scenario C (Split 1:N):** Single estimate → multiple operations jobs (different owners)

**Expected Outputs:**
- Python implementation of Levenshtein distance matching
- `bridge_estimate_to_project` table schema (already in spec, validate)
- Manual review dashboard wireframe/requirements
- Network folder parsing logic (\\armays-fs1\...\Jobs 2025\YY-1-###\)
- dbt model for fuzzy matching with confidence scoring

---

## 🛠️ SKILLS (Reusable Capabilities/Plugins)

### 1. SQL DDL Generator
**Input:** Table requirements (columns, types, constraints, SCD strategy)
**Output:** Production-ready PostgreSQL CREATE TABLE statements with indexes

**Use Cases:**
- Generate DDL for 5 Procore fact tables
- Create audit tables (`audit_reverse_sync`)
- Define bridge tables (`bridge_estimate_to_project`)

**Features:**
- SCD Type 2 template (effective_from, effective_to, is_current)
- Metadata columns (_source_system, _ingested_at, _hash_key, _batch_id)
- Index recommendations based on query patterns
- Foreign key constraint definitions
- Check constraints for data validation

---

### 2. dbt Model Scaffolder
**Input:** Source tables, transformation logic, dimensional model structure
**Output:** dbt project with staging → intermediate → marts/gold models + tests

**Use Cases:**
- Scaffold ~20+ dbt models for S-curve analysis
- Generate reverse sync calculations
- Create pipeline metrics aggregations

**Generated Structure:**
```
models/
├── staging/
│   ├── stg_smartsheet_estimates.sql
│   ├── stg_sage300_projects.sql
│   ├── stg_procore_rfis.sql
│   └── stg_bridgit_assignments.sql
├── intermediate/
│   ├── int_project_unified.sql
│   ├── int_schedule_progress.sql
│   └── int_financial_progress.sql
└── marts/
    ├── gold_estimating_pipeline_metrics.sql
    ├── gold_schedule_health.sql
    └── gold_forecasted_assignments.sql
```

**Features:**
- dbt tests (unique, not_null, relationships, accepted_values)
- Schema contracts for upstream dependencies
- Documentation in YAML
- Incremental materialization patterns

---

### 3. API Spec Generator
**Input:** Endpoint requirements (resources, methods, auth, rate limits)
**Output:** OpenAPI 3.0 YAML with request/response schemas and examples

**Use Cases:**
- Document FastAPI endpoints for read/write access
- Reverse sync trigger endpoints
- Manual review workflow API

**Generated Components:**
- Authentication schemes (OAuth2, API key)
- Endpoint definitions (paths, methods, parameters)
- Request/response schemas (JSON Schema)
- Example requests and responses
- Rate limiting documentation

---

### 4. Cost Calculator & ROI Modeler
**Input:** Infrastructure components, personnel requirements, timeline
**Output:** Detailed cost breakdown with 3-year TCO and ROI projections

**Use Cases:**
- Generate missing cost estimation section
- Infrastructure + personnel costs
- Operational expenses

**Cost Categories:**
- **Infrastructure:** PostgreSQL (compute, storage, backup), Redis, Kubernetes cluster
- **Personnel:** 1 Senior Data Engineer × 12-16 weeks at market rate
- **Licenses:** Verify open-source components (Dagster, OpenMetadata, Metabase)
- **Operational:** Monitoring, maintenance, support, training
- **Data Storage:** Bronze (1 year), Silver/Gold (3 years), Audit logs (7 years)

**ROI Factors:**
- Time saved on manual reporting
- Improved decision-making from real-time dashboards
- Reduced project delays from schedule validation
- Better resource allocation from reverse sync

---

### 5. ERD & Architecture Diagram Generator
**Input:** Table schemas, relationships, system components
**Output:** Mermaid ERD diagrams, system architecture diagrams, data flow diagrams

**Use Cases:**
- Visualize dimensional model
- Reverse sync workflow
- Dagster asset graph

**Diagram Types:**
1. **ERD (Entity-Relationship Diagram):** Dimensions, facts, relationships
2. **Data Flow Diagram:** Sources → Bronze → Silver → Gold → Dashboards
3. **Architecture Diagram:** System components (PostgreSQL, Dagster, Metabase, etc.)
4. **Sequence Diagram:** Reverse sync workflow steps
5. **Asset Dependency Graph:** Dagster asset execution order

---

### 6. Timeline/Gantt Chart Builder
**Input:** Project phases, milestones, dependencies, resource allocation
**Output:** Visual roadmap with critical path and milestone dates

**Use Cases:**
- Generate 12-16 week implementation roadmap
- 4 phases with dependencies

**Phases:**
1. **MVP (Weeks 1-4):** Single source integration, basic dashboards
2. **Full Integration (Weeks 5-8):** All 4 sources, advanced analytics (S-curve)
3. **Hardening (Weeks 9-12):** Reverse sync, data quality, HA setup
4. **Production (Weeks 13-16):** User training, monitoring, cutover

**Features:**
- Critical path highlighting
- Resource allocation visualization
- Milestone markers
- Dependency arrows
- Progress tracking

---

## 🔌 MCPs (Model Context Protocol Integrations)

### 1. Database Schema Inspector MCP
**Purpose:** Read existing Sage 300 ODBC schema to understand source structure

**Why You Need It:** Validate source data structures and design accurate staging models

**Capabilities:**
- Query Sage 300 table schemas, primary keys, foreign keys
- Analyze data types and column constraints
- Sample data for profiling and validation
- Detect incremental keys (`Accounting_Date`, `updated_at`)

**Integration Pattern:**
```python
# Example usage
sage_schema = mcp.database_inspector.get_schema(
    connection_string="DSN=Sage300",
    tables=["JOB_COST", "EMPLOYEE_HOURS", "COST_CODES", "CHANGE_ORDERS", "PAY_APPS"]
)
```

---

### 2. Smartsheet API MCP
**Purpose:** Direct read access to Webster Tracking sheet for requirements validation

**Why You Need It:** Verify field names, data types, and pipeline workflow stages

**Capabilities:**
- Read sheet structure and column definitions
- Sample estimating data (YY-4-### jobs)
- Validate incremental key (`modifiedAt`)
- Understand status values and probability percentages

**Integration Pattern:**
```python
# Example usage
webster_tracking = mcp.smartsheet.get_sheet(
    sheet_name="Webster Tracking",
    access_token=os.getenv("SMARTSHEET_ACCESS_TOKEN")
)
columns = webster_tracking.columns
sample_data = webster_tracking.rows[:10]
```

---

### 3. Project Cost Benchmark Database MCP
**Purpose:** Access industry benchmark data for construction project cost estimation

**Why You Need It:** Validate cost estimates and provide industry-standard comparisons

**Capabilities:**
- Construction project cost per square foot by type
- Data engineering hourly rates by seniority/region
- Infrastructure costs for PostgreSQL, Kubernetes clusters
- License costs for commercial tools (if any)

**Benchmark Categories:**
- **Construction:** Cost per SF, project duration by type/size
- **Personnel:** Data Engineer hourly rates (Junior: $75-100, Mid: $100-150, Senior: $150-200)
- **Infrastructure:** AWS/Azure/GCP pricing for PostgreSQL, Kubernetes
- **Software:** Open-source vs. commercial tool costs

---

### 4. Diagram Rendering MCP (Mermaid/PlantUML)
**Purpose:** Generate and render ERD diagrams, architecture diagrams, flowcharts

**Why You Need It:** Low-priority gap includes visual ERD diagrams

**Capabilities:**
- Convert dimensional model to Mermaid ERD syntax
- Render data flow diagrams from text descriptions
- Generate Dagster asset dependency graphs
- Create sequence diagrams for reverse sync workflow

**Mermaid Diagram Types:**
- **ERD:** `erDiagram` for dimensional model
- **Flowchart:** `graph TD` for data flow
- **Sequence:** `sequenceDiagram` for reverse sync
- **Gantt:** `gantt` for implementation roadmap

---

### 5. Code Repository MCP (GitHub/GitLab)
**Purpose:** Search similar data warehouse projects for implementation patterns

**Why You Need It:** Accelerate development with proven patterns for dbt, Dagster, Great Expectations

**Capabilities:**
- Find dbt projects with SCD Type 2 implementations
- Discover Dagster asset examples for API ingestion + reverse sync
- Locate Great Expectations suites for financial data validation
- Reference FastAPI authentication patterns (OAuth2 + API keys)

**Search Queries:**
- "dbt slowly changing dimension type 2 postgres"
- "dagster api ingestion assets incremental"
- "great expectations financial data tests"
- "fastapi oauth2 api key authentication"

---

## 📄 OUTPUT STYLES (Format Templates)

### 1. Executive Summary Style
**Format:** 1-2 page PDF with KPI dashboard, ROI projection, risk matrix

**Audience:** CFO, VP Operations (sponsors)

**Content Sections:**
- Executive overview (3-5 sentences)
- Business value proposition
- Cost-benefit analysis (infrastructure + personnel costs vs. efficiency gains)
- Timeline summary (12-16 weeks, 4 phases)
- Resource requirements (1 Senior Data Engineer)
- Success metrics (dashboards deployed, data freshness SLA, user adoption)
- Risk matrix (likelihood × impact)

**Visual Elements:**
- Cost breakdown pie chart
- Timeline Gantt chart
- Risk heat map

**Use Cases:**
- Present completed specification to sponsors for approval
- Secure budget and resource allocation

---

### 2. Technical Specification Style
**Format:** Multi-section markdown with code blocks, SQL DDL, YAML configs

**Audience:** Data engineers, DevOps team

**Content Sections:**
- Architecture overview
- Complete schemas (13+ tables with DDL)
- API endpoint specifications
- Dagster asset configurations
- dbt model structure
- Great Expectations test suites
- Deployment manifests (Kubernetes YAML, Helm charts)
- Configuration examples (.env templates)

**Code Examples:**
- PostgreSQL CREATE TABLE statements
- dbt model SQL
- Dagster asset definitions (Python)
- Great Expectations expectations (YAML)
- Kubernetes deployment manifests

**Use Cases:**
- Implementation-ready documentation for development team
- Onboarding new engineers
- Code review reference

---

### 3. Visual Architecture Blueprint Style
**Format:** Diagram-heavy presentation with Mermaid/Lucidchart visuals

**Audience:** All stakeholders (cross-functional alignment)

**Visual Components:**
- ERD diagram (dimensional model)
- Data flow diagram (sources → Bronze → Silver → Gold → dashboards)
- System architecture (Kubernetes pods, services, ingress)
- Dagster asset graph (execution order)
- Reverse sync workflow (sequence diagram)
- Network topology (on-prem sources, cloud warehouse)

**Annotations:**
- Data volume estimates
- Processing times
- SLA requirements
- Integration points

**Use Cases:**
- Stakeholder review sessions
- Architecture approval meetings
- System design documentation

---

### 4. Implementation Roadmap Style
**Format:** Gantt chart / timeline with milestones, dependencies, resource allocation

**Audience:** Project managers, business analysts, data engineering lead

**Timeline Structure:**
- **Phase 1: MVP (Weeks 1-4)**
  - Week 1: Smartsheet + Sage 300 integration
  - Week 2: PostgreSQL setup + Bronze layer
  - Week 3: dbt Silver layer + basic transformations
  - Week 4: First dashboard (Estimating pipeline)

- **Phase 2: Full Integration (Weeks 5-8)**
  - Week 5-6: Procore integration (RFIs, submittals, daily logs)
  - Week 7: Bridgit Bench integration (read-only)
  - Week 8: S-curve analysis implementation

- **Phase 3: Hardening (Weeks 9-12)**
  - Week 9-10: Reverse sync to Bridgit Bench
  - Week 11: Data quality validation (Great Expectations)
  - Week 12: High availability setup (PostgreSQL replication, Redis Sentinel)

- **Phase 4: Production (Weeks 13-16)**
  - Week 13: User acceptance testing
  - Week 14: Dashboard training for stakeholders
  - Week 15: Monitoring setup (Prometheus + Grafana)
  - Week 16: Production cutover

**Visual Elements:**
- Gantt bars with duration
- Dependency arrows (finish-to-start, start-to-start)
- Milestones (diamonds)
- Critical path highlighting
- Resource allocation lanes

**Use Cases:**
- Project tracking
- Sprint planning
- Resource scheduling
- Risk checkpoint identification

---

### 5. API Documentation Style
**Format:** Interactive Swagger/OpenAPI HTML with request/response examples

**Audience:** API consumers, integration partners, future developers

**Content Structure:**
- Authentication section (OAuth2 flow, API key usage)
- Endpoint catalog (grouped by resource)
- Request parameters (path, query, body)
- Response schemas (success + error cases)
- Rate limiting documentation
- Error code reference
- Example requests (cURL, Python, JavaScript)

**Endpoint Groups:**
1. **Projects:** GET /projects, GET /projects/{id}, GET /projects/{id}/schedule-health
2. **People:** GET /people, GET /people/{id}/assignments
3. **Estimating:** GET /estimates, GET /estimates/{id}/conversion-status
4. **Reverse Sync:** POST /bridgit/forecast-assignments (admin only)
5. **Admin:** POST /mappings/estimate-to-project, GET /audit-logs

**Use Cases:**
- FastAPI read/write API documentation
- Reverse sync trigger endpoints
- Third-party integrations

---

### 6. Data Dictionary / Catalog Style
**Format:** Searchable HTML table or CSV with field descriptions, sample values, lineage

**Audience:** Business analysts, finance team, dashboard users

**Table Structure:**
| Table | Column | Data Type | Description | Business Definition | Sample Values | Source | Calculation Logic |
|-------|--------|-----------|-------------|-------------------|---------------|--------|------------------|
| dim_project | project_sk | BIGSERIAL | Surrogate key | Unique identifier for project | 1, 2, 3 | Generated | Auto-increment |
| dim_project | project_code | VARCHAR(50) | Project number | YY-1-### format for operations jobs | 25-1-082 | Sage 300 | Master data |
| fact_labor_hours | regular_hours | DECIMAL(8,2) | Regular hours | Non-overtime hours worked | 8.00, 7.50 | Sage 300 | From timesheet |

**Metadata Fields:**
- **Table:** Physical table name
- **Column:** Column name
- **Data Type:** PostgreSQL type
- **Description:** Technical description
- **Business Definition:** User-friendly explanation
- **Sample Values:** Example data
- **Source:** Source system (Smartsheet, Sage 300, Procore, Bridgit, Generated)
- **Calculation Logic:** Formula or derivation rule (for calculated fields)
- **Lineage:** Data flow path (e.g., "Sage 300 → stg_sage300_job_cost → dim_project")

**Use Cases:**
- OpenMetadata catalog entries
- User training materials
- Data governance documentation
- Self-service analytics support

---

## 🎯 RECOMMENDED PRIORITIZATION

### Phase 1: Complete Core Specification (Weeks 1-2)
**Focus:** Fill the largest technical gaps

| Priority | Subagent/Skill | Deliverable | Owner |
|----------|---------------|-------------|-------|
| 🔴 P0 | **Procore Integration Specialist** | 5 Procore fact table schemas | Project Subagent |
| 🔴 P0 | **Data Architect Agent** | Complete DDL for all 13+ tables | User Subagent |
| 🔴 P0 | **SQL DDL Generator Skill** | PostgreSQL CREATE TABLE scripts | Skill |
| 🟡 P1 | **Database Schema Inspector MCP** | Sage 300 schema validation | MCP |

**Exit Criteria:** All fact/dimension tables fully defined with DDL, indexes, and constraints

---

### Phase 2: Formalize Business Logic (Weeks 2-3)
**Focus:** Document business rules and advanced analytics

| Priority | Subagent/Skill | Deliverable | Owner |
|----------|---------------|-------------|-------|
| 🔴 P0 | **Business Rules Analyst Agent** | Timeline business rules documentation | User Subagent |
| 🔴 P0 | **S-Curve Analytics Specialist** | Schedule validation SQL algorithms | Project Subagent |
| 🔴 P0 | **Entity Matching Engine** | Fuzzy matching logic + bridge table | Project Subagent |

**Exit Criteria:** Business rules formalized with SQL implementations and validation thresholds

---

### Phase 3: Planning & Costing (Weeks 3-4)
**Focus:** Strategic planning and financial justification

| Priority | Subagent/Skill | Deliverable | Owner |
|----------|---------------|-------------|-------|
| 🔴 P0 | **Implementation Roadmap Agent** | 12-16 week phased roadmap | User Subagent |
| 🔴 P0 | **Cost Estimation Agent** | Infrastructure + personnel costs | User Subagent |
| 🟡 P1 | **Cost Calculator Skill** | 3-year TCO and ROI model | Skill |
| 🟡 P1 | **Timeline/Gantt Chart Builder Skill** | Visual roadmap | Skill |
| 🟢 P2 | **Project Cost Benchmark Database MCP** | Industry cost validation | MCP |

**Exit Criteria:** Complete cost estimation section and executive-ready implementation roadmap

---

### Phase 4: Technical Design (Weeks 4-5)
**Focus:** Orchestration and bidirectional integration

| Priority | Subagent/Skill | Deliverable | Owner |
|----------|---------------|-------------|-------|
| 🔴 P0 | **Dagster Orchestration Designer** | Asset graph + configurations | Project Subagent |
| 🔴 P0 | **Reverse Sync Orchestrator** | Bridgit write-back architecture | Project Subagent |
| 🟡 P1 | **dbt Model Scaffolder Skill** | ~20+ dbt model stubs | Skill |
| 🟢 P2 | **Code Repository MCP** | Reference implementations | MCP |

**Exit Criteria:** Orchestration section updated to Dagster, reverse sync fully designed

---

### Phase 5: Documentation & Visualization (Weeks 5-6)
**Focus:** Stakeholder-ready deliverables

| Priority | Subagent/Skill | Deliverable | Owner |
|----------|---------------|-------------|-------|
| 🟡 P1 | **Technical Documentation Agent** | Runbooks, data dictionary, DR plans | User Subagent |
| 🟡 P1 | **ERD & Architecture Diagram Generator Skill** | Visual diagrams | Skill |
| 🟡 P1 | **Diagram Rendering MCP** | Rendered Mermaid diagrams | MCP |
| 🟢 P2 | **API Spec Generator Skill** | OpenAPI documentation | Skill |
| 🟢 P2 | **All 6 Output Styles** | Stakeholder-specific docs | Templates |

**Exit Criteria:** Specification at 100% with executive summary, technical specs, visual blueprints, roadmap, API docs, and data dictionary

---

## 📋 SUCCESS METRICS

### Specification Completeness Tracking

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Overall Completeness | 75% | 100% | 🟡 In Progress |
| Data Model Documentation | 60% | 100% | 🔴 Blocked (Procore tables missing) |
| Business Rules Formalization | 40% | 100% | 🔴 Blocked (Timeline rules undefined) |
| Implementation Roadmap | 0% | 100% | 🔴 Missing |
| Cost Estimation | 0% | 100% | 🔴 Missing |
| Technical Documentation | 30% | 100% | 🟡 Partial |
| Architecture Diagrams | 20% | 100% | 🟡 Partial (text-only, no visuals) |

### Deliverables Checklist

#### HIGH PRIORITY (Must Complete Before Implementation)
- [ ] Complete Procore data model (5 fact tables)
- [ ] PostgreSQL DDL for all 13+ tables
- [ ] Update orchestration section (Celery → Dagster)
- [ ] Create 12-16 week implementation roadmap
- [ ] Generate cost estimation section
- [ ] Document timeline business rules
- [ ] Design S-curve analysis algorithms
- [ ] Develop fuzzy matching logic

#### MEDIUM PRIORITY (Complete During Implementation)
- [ ] Data dictionary with field-level documentation
- [ ] Security architecture deep dive
- [ ] Disaster recovery runbooks
- [ ] Change management process documentation
- [ ] Data retention automation scripts

#### LOW PRIORITY (Post-Launch)
- [ ] ERD diagrams (visual)
- [ ] End-user documentation
- [ ] API documentation (Swagger/OpenAPI)

---

## 🚀 NEXT STEPS

### Immediate Actions (This Week)
1. **Create all 10 subagent configurations** in `.claude/agents/` directory
2. **Prioritize Procore Integration Specialist** → Complete 5 missing fact tables
3. **Run Data Architect Agent** → Generate DDL for all schemas
4. **Execute Business Rules Analyst Agent** → Formalize timeline business rules

### Short-Term Goals (Weeks 1-2)
- Complete Phase 1: Core Specification (data model + DDL)
- Complete Phase 2: Business Logic (rules + algorithms)
- Begin Phase 3: Planning & Costing

### Medium-Term Goals (Weeks 3-4)
- Complete Phase 3: Planning & Costing (roadmap + cost estimation)
- Complete Phase 4: Technical Design (Dagster + reverse sync)

### Long-Term Goals (Weeks 5-6)
- Complete Phase 5: Documentation & Visualization
- Achieve 100% specification completeness
- Obtain stakeholder approval for implementation

---

## 📚 APPENDIX: SUBAGENT INVOCATION EXAMPLES

### Example 1: Invoke Procore Integration Specialist
```markdown
@procore-integration-specialist

Please complete the Procore data model for the Construction Data Sync project.

**Input Documents:**
- F:\02_Repositories\Active\ARM_Data_Sync\Planning\construction_data_sync_spec.md
- Specifically review FR-010 (Procore Field Execution Integration)
- Review existing fact table patterns (fact_labor_hours, fact_assignments, fact_change_orders, fact_pay_apps)

**Required Deliverables:**
1. Complete schema for `fact_rfis` (grain: one row per RFI)
2. Complete schema for `fact_submittals` (grain: one row per submittal revision)
3. Complete schema for `fact_daily_logs` (grain: one row per project, per day)
4. Complete schema for `fact_observations` (grain: one row per observation)
5. Complete schema for `fact_schedule_activities` (grain: one row per schedule task)

For each table, provide:
- Column definitions with data types
- Foreign key relationships to dimensions
- Measures (additive, semi-additive, non-additive)
- Metadata columns (_source_system, _ingested_at, _batch_id)
- Index recommendations

**Output Format:** Markdown table format matching existing fact tables in spec
```

### Example 2: Invoke Cost Estimation Agent
```markdown
@cost-estimation-agent

Please generate a comprehensive cost estimation section for the Construction Data Sync project.

**Input Documents:**
- F:\02_Repositories\Active\ARM_Data_Sync\Planning\construction_data_sync_spec.md
- Review infrastructure requirements (NFR-002: Scalability, NFR-005: Data Retention)

**Infrastructure Requirements:**
- PostgreSQL with streaming replication (200 projects, 1M+ rows per fact table)
- Redis Sentinel for HA
- Kubernetes cluster (3 namespaces, multi-replica deployments)
- 50 concurrent dashboard users
- Data retention: Bronze 1 year, Silver/Gold 3 years, Audit logs 7 years
- Monitoring: Prometheus + Grafana

**Personnel Requirements:**
- 1 Senior Data Engineer × 12-16 weeks

**Required Cost Categories:**
1. Infrastructure costs (compute, storage, networking, backup)
2. Personnel costs (market rate assumptions)
3. License costs (verify open-source: Dagster, OpenMetadata, Metabase)
4. Operational costs (monitoring, maintenance, support, training)
5. 3-year TCO projection

**Output Format:** Markdown section matching specification style with cost tables and assumptions documented
```

### Example 3: Invoke Implementation Roadmap Agent
```markdown
@implementation-roadmap-agent

Please create a detailed 12-16 week implementation roadmap for the Construction Data Sync project.

**Input Documents:**
- F:\02_Repositories\Active\ARM_Data_Sync\Planning\construction_data_sync_spec.md
- F:\02_Repositories\Active\ARM_Data_Sync\Planning\SESSION_SUMMARY_2025-11-04.md
- Current specification completeness: 75%

**Resource Constraints:**
- 1 Senior Data Engineer (full-time)
- Stakeholder availability for reviews (weekly)

**Required Phases:**
1. **MVP (Weeks 1-4):** Single source integration + basic dashboard
2. **Full Integration (Weeks 5-8):** All 4 sources + S-curve analytics
3. **Hardening (Weeks 9-12):** Reverse sync + data quality + HA
4. **Production (Weeks 13-16):** UAT + training + cutover

For each phase, provide:
- Weekly milestones with specific deliverables
- Entry/exit criteria
- Testing strategy (unit, integration, E2E)
- Risk checkpoints
- Stakeholder review gates

**Output Format:** Gantt-style markdown table or Mermaid gantt diagram + detailed phase descriptions
```

---

**Document Version:** 1.0
**Author:** Claude Code AI Assistant
**Date Created:** November 5, 2025
**Last Updated:** November 5, 2025
**Related Documents:**
- `construction_data_sync_spec.md` (v2.0)
- `SESSION_SUMMARY_2025-11-04.md`

---

**END OF DOCUMENT**
