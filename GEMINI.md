# GEMINI.md

This file provides guidance to Gemini when working in this repository.

---

## Project Overview

**Construction Data Sync** is a **bidirectional data synchronization and analytics platform** for the construction industry, currently in the **specification development phase**. The system unifies four data sources into a governed data warehouse with advanced analytics and resource forecasting capabilities.

### Data Sources
1.  **Smartsheet** - Pre-construction estimating pipeline
2.  **Sage 300** - Active project financials via ODBC
3.  **Procore** - Field execution tracking
4.  **Bridgit Bench** - Resource planning with **reverse sync** (read + write)

### Key Architectural Patterns
-   **Medallion Architecture:** Bronze (raw) → Silver (normalized) → Gold (curated)
-   **Dimensional Modeling:** Star schema with SCD Type 2 for history tracking.
-   **Job Number Conversion:** Fuzzy matching estimates to operations jobs.
-   **Schedule Validation:** S-curve analysis comparing Procore schedules vs. pay app billing.
-   **Reverse Sync:** Push forecasted manpower assignments back to Bridgit Bench.

---

## Directory Overview

This directory contains the specification and planning documents for the **Construction Data Sync** project. It is currently in the **specification phase**, and no implementation code exists yet.

### Key Files

-   `Planning/construction_data_sync_spec.md`: The primary specification document (v2.0), which is the source of truth for all architectural decisions.
-   `Planning/SESSION_SUMMARY_2025-11-04.md`: A decision log and summary of the work that has been done on the specification.
-   `Planning/TOOLING_RECOMMENDATIONS_2025-11-05.md`: A document that outlines the specialized subagents, skills, and output styles to accelerate the completion of the specification.
-   `CLAUDE.md`: A file that provides guidance to the Claude Code AI assistant.

---

## Usage

The contents of this directory are intended to be used to guide the development of the **Construction Data Sync** project. The project is currently in the **specification phase**.

### Future Implementation

The following directories will be created during the implementation phase:

-   `src/`: Python connectors and orchestration code
-   `dbt/`: Data transformation models
-   `dagster/`: Asset definitions and orchestration workflows
-   `great_expectations/`: Data quality test suites
-   `kubernetes/`: Deployment manifests
-   `docker/`: Container definitions and docker-compose files
-   `tests/`: Unit, integration, and end-to-end tests
-   `docs/`: Generated documentation and API specs
