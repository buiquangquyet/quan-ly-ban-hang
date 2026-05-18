---
name: quality-gate
description: >-
  Unified Definition of Done verification — kiểm tra tất cả quality gates trước khi declare feature complete.
  Level 1 (AI automated): unit tests, integration tests, review, docs, @trace coverage.
  Level 2 (Human + AI): BDD/E2E, API contract, performance.
  Trigger: "quality gate", "check done", "kiểm tra quality", "DoD check", "feature complete?",
  "verify done", "quality check". Do NOT use for standalone code review (use review),
  standalone testing (use test), hoặc commit (use commit).
argument-hint: "--level 1" (default) hoặc "--level 2" cho full QA gate
---

# Quality Gate — Definition of Done Verification

Kiểm tra unified quality gates. 2 levels tách biệt AI-automated vs Human-assisted.

## Why 2 Levels?

- **Level 1**: Unit + integration tests — fast, deterministic, AI fully controls. Chạy cuối `/develop`.
- **Level 2**: BDD/E2E tests — complex data prep, environment setup, external dependencies. AI có thể chạy mãi không pass. Chạy riêng via `/test`, cần human assist.

---

## Bước 1: Detect Level

$ARGUMENTS

- Default (no args hoặc `--level 1`) → **Level 1: Developer Gate**
- `--level 2` → **Level 2: QA Gate**
- Nếu có JIRA ticket ID → sẽ update DoD checklist trên JIRA

---

## Bước 2A: Level 1 — Developer Gate (AI Automated)

**Goal**: Verify feature ready for QA/merge từ development perspective

**Checklist**:

| # | Gate | How to Verify | Pass Criteria |
|---|------|--------------|---------------|
| 1 | Unit tests | Run test command (detect from CLAUDE.md) | All PASS, no failures |
| 2 | Integration tests | Run integration test command | All PASS, no failures |
| 3 | Code review | Check git log cho review comments hoặc run `/review` | No BLOCKING findings |
| 4 | Documentation | Check docs updated (README, ADR if applicable) | Relevant docs exist/updated |
| 5 | @trace coverage | Run `/trace {module}/{feature}` → check gaps | All UCs/ACs have code + test artifacts |
| 6 | Conventional commit | Check git log format | Latest commit follows convention |
| 7 | No secrets | Scan staged files cho sensitive patterns | No .env, credentials, API keys |

**Actions**:
1. Run mỗi gate check
2. Collect evidence (test output, file paths, trace report)
3. Generate report:

```
Quality Gate Level 1 — Developer Gate
=====================================
[PASS] Unit tests: 45/45 passed
[PASS] Integration tests: 12/12 passed
[PASS] Code review: no BLOCKING findings (last review: 3 SUGGESTION)
[PASS] Documentation: README updated, ADR-005 created
[WARN] @trace coverage: 3/4 ACs covered — UC-02/AC-01 missing unit test
[PASS] Conventional commit: feat(sales): add revenue export
[PASS] No secrets: clean

Result: 6/7 PASS, 1 WARN
Action needed: Add unit test for UC-02/AC-01
```

4. Nếu có JIRA ticket → dùng `editJiraIssue` update DoD checklist
5. Nếu tất cả PASS → "Feature ready for QA (Level 2) hoặc merge"
6. Nếu có FAIL → list action items cần fix

---

## Bước 2B: Level 2 — QA Gate (Human + AI)

**Goal**: Verify feature ready for production từ QA perspective

**Checklist**:

| # | Gate | How to Verify | Pass Criteria |
|---|------|--------------|---------------|
| 1 | Level 1 gates | Check Level 1 already passed | All Level 1 gates PASS |
| 2 | BDD scenarios | Run Cucumber tests | All scenarios PASS (living docs green) |
| 3 | E2E tests | Run Playwright E2E suite | All flows PASS |
| 4 | API contract tests | Run API test suite | All contracts valid |
| 5 | Performance | Run perf benchmarks (if applicable) | Within SLA thresholds |

**Actions**:
1. Verify Level 1 already passed (skip if just ran)
2. Attempt to run BDD/E2E tests
3. Nếu tests fail vì data/environment issues → **report to user**, không retry endlessly:
   ```
   [BLOCKED] BDD scenarios: 3/5 passed, 2 failed
   Failure: data preparation issue — test database missing seed data for branch "CN001"
   Action: Human needs to prepare test data, then re-run
   ```
4. Generate Level 2 report
5. Update JIRA nếu có ticket

---

## Output Format

Generate JSON report: `docs/quality-reports/{feature}-quality-gate.json`

```json
{
  "feature": "{feature}",
  "level": 1,
  "timestamp": "{ISO}",
  "gates": [
    { "name": "Unit tests", "status": "PASS", "evidence": "45/45 passed", "details": "..." },
    { "name": "@trace coverage", "status": "WARN", "evidence": "3/4 ACs", "gaps": ["UC-02/AC-01"] }
  ],
  "result": "PASS_WITH_WARNINGS",
  "actionItems": ["Add unit test for UC-02/AC-01"],
  "jiraUpdated": true
}
```

---

## Examples

**Example 1: Quick check after develop**
User says: "/quality-gate"
Actions: Run Level 1 checks → all pass
Result: "Feature ready for QA or merge"

**Example 2: Full QA check**
User says: "/quality-gate --level 2"
Actions: Level 1 + BDD/E2E → BDD blocked on data
Result: Report with blocked items, user action needed

**Example 3: With JIRA**
User says: "/quality-gate KV-103"
Actions: Run Level 1 + update KV-103 DoD checklist on JIRA
Result: JIRA ticket updated with quality gate results

---

## Troubleshooting

**Test command unknown**: Check CLAUDE.md cho test scripts, hoặc hỏi user
**BDD tests chạy mãi không pass**: Stop after 2 attempts, report blocked items to user. KHÔNG retry endlessly.
**@trace skill not available**: Fallback to manual grep cho @trace annotations
