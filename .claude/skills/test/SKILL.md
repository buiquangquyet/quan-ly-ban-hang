---
name: test
description: >-
  QC/QA testing workflow — implement step definitions từ .feature files, viết E2E flows,
  API contract tests, integration tests, generate Page Objects và API Clients.
  Dùng khi user muốn implement tests từ feature files, generate step definitions, viết E2E/API tests,
  hoặc chạy QA suite. Trigger: "test feature", "viết test E2E", "tạo test plan", "kiểm thử",
  "QC testing", "API test", "integration test", "generate steps", "implement steps",
  "tạo step definitions", "gen steps từ feature", "implement feature file", "viết step defs".
  Do NOT use for unit tests/TDD RED-GREEN cycle (use develop Phase 6), code review (use review),
  writing .feature files (use write-features), hoặc refactoring (use refactor).
argument-hint: "Mô tả feature cần test" hoặc path tới .feature file
---

# QC/QA Testing Workflow

Implement và chạy tests từ góc nhìn QA — không viết unit tests (thuộc `/develop`), không viết .feature files (thuộc `/write-features`).

## References

- Test strategy và khi nào dùng loại test nào: xem `references/test-strategy-guide.md`
- BDD conventions, Gherkin syntax, CucumberJS: xem `references/bdd-conventions.md`
- API step patterns (BaseApiClient, step catalog): xem `references/api-step-patterns.md`
- E2E step patterns (Page Object, step catalog): xem `references/e2e-step-patterns.md`

## Scope

- **Trong scope**: Step definitions, E2E flows, API contract tests, integration tests, Page Objects, API Clients
- **Ngoài scope**: Unit tests → `/develop`, .feature files → `/write-features`

## Skill Responsibilities

| Responsibility | Skill |
|---|---|
| WHAT to test (define scenarios, edge cases, negative paths) | `/write-features` |
| HOW to test (implement steps, run tests, report) | `/test` (this skill) |

---

## Bước 1: Detect Mode

$ARGUMENTS

Detect mode từ input:
- Input là path tới `.feature` file → **STEP GENERATION MODE** (fast)
- Input là feature description → **FULL QA MODE** (6 steps)
- Input chứa "generate steps" trigger → **STEP GENERATION MODE**

---

## STEP GENERATION MODE

Khi input là .feature file — skip test plan, generate trực tiếp.

### Step G1: Parse Feature File

**Actions**:
1. Đọc `.feature` file
2. Detect test type từ tags:
   - `@api` → API test steps + API Client class
   - `@web` → E2E steps + Page Object class
   - `@integration` → Integration test steps
   - Không có tag → hỏi user chọn type
3. Extract: feature name, scenarios, steps, parameters, data tables, doc strings
4. Extract `@trace` annotations → propagate to generated step definitions

---

### Step G2: Check Existing Implementations

Check trước khi generate — duplicate step definitions gây Cucumber "ambiguous step" errors.

**Actions**:
1. Scan project cho existing step definitions:
   - API: `src/step_definitions/api/*.ts`
   - E2E: `src/step_definitions/web/*.ts`
2. Scan existing Page Objects / API Clients
3. Report:
   - Steps đã implement (skip)
   - Steps cần generate (new)
   - Page Objects / API Clients có thể reuse

---

### Step G3: Determine Additional Input

**Nếu E2E (@web)**:
> Để implement các steps, tôi cần selectors cho elements trên trang.
> 1. **Tự động** — Dùng Playwright MCP đọc page tìm selectors
> 2. **Bạn cung cấp** — Bạn cho selectors cho từng element
> Chọn option nào?

**Nếu API (@api)**:
- Xác định base URL, auth mechanism từ existing code hoặc hỏi user
- Identify request/response types từ feature file data tables

---

### Step G4: Generate Code

Launch **test-engineer** agent với:
- Feature file content
- Detected type (API / E2E / Integration)
- Existing patterns found in project
- Selectors (nếu E2E) hoặc API specs (nếu API)
- References: agent đọc `references/api-step-patterns.md` hoặc `references/e2e-step-patterns.md`

**Agent generates**:

| Type | Output files |
|------|-------------|
| **API** | `{domain}_api_client.ts`, `{feature}_api_steps.ts`, `{domain}.ts` (models) |
| **E2E** | `{page}_page.ts`, `{feature}_steps.ts` |
| **Both** | Tất cả files trên nếu feature có cả @api và @web scenarios |

**@trace propagation**: Generated step definitions include `// @trace {id}` comment từ .feature file.

---

### Step G5: Review & Adjust

**Actions**:
1. Present generated files cho user review
2. Verify: steps match feature file, naming conventions đúng, no duplicate steps
3. Hỏi user: adjust gì không? Run thử?

---

## FULL QA MODE

Khi input là feature description — full QA workflow.

### Step Q1: Understand Feature

**Actions**:
1. Tạo todo list
2. Launch **code-explorer** agent: user-facing behavior, API contracts, integration points, existing test coverage, test framework config
3. Đọc files explorer xác định
4. Present: feature overview, areas chưa cover, framework hiện có

---

### Step Q2: Design Test Plan

**Actions**:
1. Đọc `references/test-strategy-guide.md` và `references/bdd-conventions.md`
2. Thiết kế test plan:

   | # | Type | Scenario | Priority |
   |---|------|----------|----------|
   | 1 | BDD | ... | High/Medium/Low |
   | 2 | E2E | ... | ... |
   | 3 | API | ... | ... |

3. Present plan, **đợi user approve**

---

### Step Q3: Check Feature Files

**Actions**:
1. Check existing `.feature` files cho feature này
2. Nếu .feature files có → proceed to step generation (route to STEP GENERATION MODE)
3. Nếu .feature files thiếu → **suggest user chạy `/write-features` trước**:
   > Feature files chưa có cho feature này. Suggest:
   > `/write-features {feature description}`
   > Sau khi có .feature files, quay lại `/test` để implement steps.
4. **Đợi user decision**: generate .feature via /write-features, hay proceed without BDD?

---

### Step Q4: Implement Tests

**Actions**:
1. Nếu có .feature files → route to STEP GENERATION MODE (G1-G5) cho step definitions
2. Write additional E2E/API/Integration tests theo test plan:
   - **E2E**: Page Object + Playwright, full user flows
   - **API**: Contract testing, schema validation, auth, error responses
   - **Integration**: Multi-component, database ops, event flows
3. Add `@trace` annotations to all test files

---

### Step Q5: Execute & Verify

**Actions**:
1. Run tất cả tests
2. Categorize: PASS (feature OK), FAIL (bug found), SKIP (blocked)
3. Nếu FAIL → report bugs: mô tả, steps to reproduce, expected vs actual
4. **Hỏi user**: fix trước rồi re-test, hay log bugs và proceed?
5. **Nếu BDD tests fail vì data/environment** → report blocked, KHÔNG retry endlessly

---

### Step Q6: QC Report

Present structured report:
- **Coverage**: số tests by type (BDD/E2E/API/Integration)
- **Results**: pass/fail/skip counts
- **Bugs found**: mô tả, severity, steps to reproduce
- **Gaps**: areas chưa cover
- **@trace coverage**: UCs/ACs with test artifacts
- **Recommendations**: next steps, priority fixes

---

## Examples

**Example 1: Generate steps from feature file (STEP GENERATION MODE)**
User says: "/test features/billing/invoice-api.feature"
Actions:
1. Parse .feature → detect @api tag
2. Scan existing steps → no duplicates
3. Generate: InvoiceApiClient + invoice_api_steps.ts + Invoice models
4. Propagate @trace from .feature to step definitions
Result: 3 files generated, ready to run

**Example 2: Full QA for feature (FULL QA MODE)**
User says: "/test Test tính năng login bằng OAuth"
Actions:
1. Explore: login flow, OAuth callbacks, token handling, existing tests
2. Plan: E2E flow + API contract tests
3. Check .feature files → exist → generate steps
4. Write additional E2E tests
5. Run: 5 pass, 1 fail (expired token edge case)
6. Report: QC report với 1 bug
Result: QC report + test files

**Example 3: E2E feature file**
User says: "/test features/auth/login.feature"
Actions:
1. Parse → detect @web tag
2. Hỏi user: auto-detect selectors via Playwright MCP hay manual?
3. Generate: LoginPage + login_steps.ts
Result: Page Object + step definitions

---

## Troubleshooting

**Playwright chưa install**: `npx playwright install`
**Step definitions không match**: Kiểm tra Gherkin wording, dùng `{string}` placeholders
**Tests timeout**: Kiểm tra locators, tăng timeout, verify app đang chạy
**Không detect được type**: Feature file thiếu tags → hỏi user classify mỗi scenario
**Steps trùng existing**: Skip và báo user, suggest reuse
**BDD tests chạy mãi không pass**: Stop after 2 attempts, report blocked items. Likely data/environment issue.
