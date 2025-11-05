# Remaining Specification Tasks

## High Priority
1. [x] Flesh out Procore fact table schemas (`fact_rfis`, `fact_submittals`, `fact_daily_logs`, `fact_observations`, `fact_schedule_activities`) with grain, measures, foreign keys.
2. [ ] Replace Celery references with Dagster specifics in the orchestration section; outline asset groups, schedules, and configuration.
3. [ ] Draft implementation roadmap covering MVP → full rollout, 12-16 week timeline, resources, testing gates.
4. [ ] Document timeline business rules (bid-to-award, buyout, RFI response, submittal cycle) and automation backfills (Smartsheet updates).
5. [ ] Produce cost estimate (infrastructure, tooling, personnel) for implementation phase.

## Medium Priority
6. [ ] Build comprehensive data dictionary with field-level definitions and example values.
7. [ ] Expand security architecture: OAuth2 flows, API key rotation, audit logging schema, network policies.
8. [ ] Author disaster recovery plan with backup cadence, restore tests, and failover runbooks (RTO 2h, RPO 24h).
9. [ ] Define change management process for schema evolution, config versioning, and rollback procedures.
10. [ ] Automate data retention/archival jobs for Bronze/Silver/Gold layers (move to S3/Azure Blob, restore guidance).

## Low Priority
11. [ ] Create ERD, data flow, and system architecture diagrams.
12. [ ] Write end-user/admin documentation for dashboards and operations.
13. [ ] Generate API documentation (Swagger/OpenAPI, auth examples, rate limits).
