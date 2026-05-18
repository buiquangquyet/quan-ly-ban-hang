# Coverage Matrix Template

> Reference cho review-bdd skill khi cross-check PRD coverage.

---

## Coverage Matrix Format

Output bảng này khi review có PRD source:

```
PRD Coverage Matrix
====================
PRD: {Feature Name}
Feature files: {list of .feature file paths}

| UC | AC | Priority | Rule in Feature | @trace ID | Scenarios | Coverage |
|----|----|----------|-----------------|-----------|-----------|----------|
| UC-01 | AC-01 | Must Have | Rule: "Chỉ merchant active..." | billing/invoice/UC-01/AC-01 | 3 (1 smoke, 2 regression) | Full |
| UC-01 | AC-02 | Must Have | Rule: "MST đúng format..." | billing/invoice/UC-01/AC-02 | 2 (1 smoke, 1 regression) | Partial — thiếu edge case boundary |
| UC-02 | AC-01 | Should Have | (missing) | — | 0 | ❌ Missing |
| UC-03 | AC-01 | Won't Have | — | — | — | N/A |

Summary:
  Must Have:   {n}/{total} covered ({percent}%)
  Should Have: {n}/{total} covered ({percent}%)
  Overall:     {n}/{total} ({percent}%)

Missing Coverage (BLOCKING):
  - UC-02/AC-01: {AC description from PRD}

Partial Coverage (SUGGESTION):
  - UC-01/AC-02: Thiếu boundary value scenarios cho MST length
```

---

## Trace ID Verification

### Cross-check Rules

| Check | How | Severity |
|-------|-----|----------|
| @trace ID exists | Mỗi Rule: block có `# @trace` comment | BLOCKING |
| @trace format valid | `{module}/{feature}/{UC-ID}/{AC-ID}` — 4 segments, slash-separated | BLOCKING |
| @trace maps to PRD | UC-ID và AC-ID match PRD numbering | BLOCKING |
| No duplicate @trace | Mỗi @trace ID unique across all feature files | SUGGESTION |
| @jira present (nếu có JIRA) | `@jira {TICKET-ID}` metadata | NIT |

### Common Mismatches

```
# ❌ Wrong: sai module name
# @trace payment/invoice/UC-01/AC-01   (PRD dùng "billing", không phải "payment")

# ❌ Wrong: AC numbering skip
# @trace billing/invoice/UC-01/AC-03   (PRD có AC-01, AC-02, AC-03 nhưng feature file skip AC-02)

# ❌ Wrong: thiếu AC segment
# @trace billing/invoice/UC-01         (thiếu AC-ID)

# ✅ Correct
# @trace billing/invoice/UC-01/AC-01 @jira KV-300
```

---

## Scenario Coverage per Rule

Cho mỗi Rule, verify scenario mix:

```
Rule: "{business rule statement}"
  Scenarios:
    ✅ Happy path (@smoke)           — {scenario title}
    ✅ Error: invalid data (@regression) — {scenario title}
    ❌ Error: unauthorized            — MISSING
    ❌ Edge: boundary values          — MISSING
    ❌ Edge: concurrent access        — MISSING (nếu applicable)

  Coverage: 2/5 (40%) — SUGGESTION: add missing scenarios
```

### Minimum Scenario Mix per Rule

| Rule type | Minimum scenarios |
|-----------|-------------------|
| Validation rule (format, range) | Happy + invalid + boundary (3) |
| Permission rule (role, plan) | Authorized + unauthorized + expired (3) |
| State transition (status change) | Valid transition + invalid state + already in target state (3) |
| Calculation rule (total, discount) | Normal + zero + boundary + overflow (4) |
| Integration rule (external API) | Success + timeout + error response (3) |

---

## How to Build the Matrix

1. **Extract PRD requirements**: List all UC/AC with IDs and priority
2. **Extract feature file Rules**: List all Rule: blocks with @trace IDs
3. **Map**: Match @trace IDs between PRD and feature files
4. **Identify gaps**: ACs without matching Rules = missing coverage
5. **Assess depth**: Rules with only happy path = partial coverage
6. **Output matrix**: Use format above
