# Technical Design: {Title}

## Meta

| Field | Value |
|-------|-------|
| Author | {tên người tạo} |
| Date | {YYYY-MM-DD} |
| Status | Draft / In Review / Approved |
| JIRA | {ticket IDs nếu có} |
| PRD / Spec | {link Confluence hoặc document nếu có} |

---

## 1. Overview

### Problem Statement
{Vấn đề cần giải quyết — tại sao cần thay đổi, pain point hiện tại}

### Goals
- {Goal 1}
- {Goal 2}

### Non-Goals
- {Explicitly out of scope}

### Scope
{Phạm vi: services, modules, teams affected}

---

## 2. Current State Analysis

### Architecture hiện tại
{Mô tả architecture liên quan — modules, layers, data flow hiện có}

### Patterns & Conventions
{Patterns đang dùng trong codebase — với file:line references}

### Dependencies
{External services, libraries, shared modules liên quan}

### Limitations
{Hạn chế của approach hiện tại dẫn đến cần thay đổi}

---

## 3. Proposed Solution

### Architecture Decision
{Approach được chọn + rationale ngắn gọn}

### Component Design

| Component | File Path | Responsibility | Dependencies |
|-----------|-----------|----------------|--------------|
| {name} | {path} | {mô tả} | {deps} |

### API Contracts

```
// Endpoint / Interface / DTO definitions
// Request/Response models
```

### Data Model / Database Changes

{Schema changes, new tables, index changes, stored procedures, migrations}

```sql
-- Schema changes nếu có
```

### Data Flow

```
{Entry Point}
  → {Step 1: component / action}
  → {Step 2: component / action}
  → {Step 3: component / action}
  → {Output / Storage}
```

---

## 4. Alternatives Considered

| Criteria | Proposed (chosen) | Alternative A | Alternative B |
|----------|-------------------|---------------|---------------|
| Approach | {mô tả} | {mô tả} | {mô tả} |
| Complexity | | | |
| Maintainability | | | |
| Performance | | | |
| Risk | | | |
| Pattern Alignment | | | |

**Tại sao chọn Proposed**: {reasoning}

---

## 5. Implementation Plan

### Phase 1: {Foundation}
- [ ] {Task 1} — estimated: {S/M/L}
- [ ] {Task 2}

### Phase 2: {Core Logic}
- [ ] {Task 3} (depends on Phase 1)
- [ ] {Task 4}

### Phase 3: {Integration & Polish}
- [ ] {Task 5}

**JIRA Ticket Suggestions**:
- `{type}({scope}): {title}` — {mô tả ngắn, estimated effort}

---

## 6. Test Strategy

### Unit Tests
- {Component / logic cần test, approach}

### Integration Tests
- {Integration points cần verify}

### E2E Tests
- {User flows cần cover}

---

## 7. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| {risk 1} | High/Medium/Low | High/Medium/Low | {cách giảm thiểu} |

---

## 8. Cross-Cutting Concerns

### Security
{Authentication, authorization, data protection considerations}

### Performance
{Expected load, latency requirements, caching strategy}

### Monitoring & Observability
{Logging, metrics, alerts cần thêm}

### Backward Compatibility
{Breaking changes, migration path cho existing clients/data}

### Migration Plan
{Rollout strategy: feature flag, phased rollout, blue-green, etc.}

---

## 9. Open Questions

- [ ] {Question 1 — ai cần trả lời, deadline}
- [ ] {Question 2}
