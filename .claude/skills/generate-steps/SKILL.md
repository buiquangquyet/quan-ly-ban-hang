---
name: generate-steps
description: >-
  Generate step definitions từ Cucumber feature files — auto-detect API (@api) hoặc E2E (@web)
  rồi generate code phù hợp: API Client + step defs hoặc Page Object + step defs.
  Dùng khi user có .feature file và muốn generate step definitions, Page Objects, API clients.
  Trigger: "generate steps", "implement steps", "tạo step definitions", "gen steps từ feature",
  "implement feature file", "viết step defs". Do NOT use for full QC workflow (use test),
  writing feature files (use write-features), hoặc unit tests (use develop).
argument-hint: Path tới .feature file hoặc paste nội dung feature
---

# Generate Step Definitions from Feature Files

Generate TypeScript step definitions từ Cucumber `.feature` files. Auto-detect test type và generate code phù hợp.

## Workflow

### Bước 1: Parse Feature File

$ARGUMENTS

**Actions**:
1. Đọc `.feature` file
2. Detect test type từ tags:
   - `@api` → API test steps + API Client class
   - `@web` → E2E steps + Page Object class
   - `@integration` → Integration test steps
   - Không có tag → hỏi user chọn type
3. Extract: feature name, scenarios, steps, parameters, data tables, doc strings

---

### Bước 2: Check Existing Implementations

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

### Bước 3: Determine Additional Input

**Nếu E2E (@web)**:
> Để implement các steps, tôi cần selectors cho elements trên trang.
> 1. **Tự động** — Dùng Playwright MCP đọc page tìm selectors
> 2. **Bạn cung cấp** — Bạn cho selectors cho từng element
> Chọn option nào?

**Nếu API (@api)**:
- Xác định base URL, auth mechanism từ existing code hoặc hỏi user
- Identify request/response types từ feature file data tables

---

### Bước 4: Generate Code

Launch **test-engineer** agent với:
- Feature file content
- Detected type (API / E2E / Integration)
- Existing patterns found in project
- Selectors (nếu E2E) hoặc API specs (nếu API)
- References: agent sẽ đọc `references/api-step-patterns.md` hoặc `references/e2e-step-patterns.md`

**Agent generates**:

| Type | Output files |
|------|-------------|
| **API** | `{domain}_api_client.ts`, `{feature}_api_steps.ts`, `{domain}.ts` (models) |
| **E2E** | `{page}_page.ts`, `{feature}_steps.ts` |
| **Both** | Tất cả files trên nếu feature có cả @api và @web scenarios |

---

### Bước 5: Review & Adjust

**Actions**:
1. Present generated files cho user review
2. Verify: steps match feature file, naming conventions đúng, no duplicate steps
3. Hỏi user: adjust gì không? Run thử?

---

## Examples

**Example 1: API feature file**
User says: "/generate-steps features/billing/invoice-api.feature"
Actions:
1. Parse .feature → detect @api tag
2. Scan existing steps → no duplicates
3. Đọc `references/api-step-patterns.md` cho patterns
4. Generate: InvoiceApiClient, invoice_api_steps.ts, Invoice models
5. Present files cho user review
Result: 3 files generated, ready to run

**Example 2: E2E feature file**
User says: "/generate-steps features/auth/login.feature"
Actions:
1. Parse → detect @web tag
2. Hỏi user: auto-detect selectors via Playwright MCP hay manual?
3. Đọc `references/e2e-step-patterns.md`
4. Generate: LoginPage + login_steps.ts
Result: Page Object + step definitions

**Example 3: Mixed feature file**
User says: "/generate-steps features/order/create-order.feature"
→ Detect @api + @web → generate cả API client + Page Object + step defs

## Troubleshooting

**Không detect được type**: Feature file thiếu tags → hỏi user classify mỗi scenario
**Steps trùng existing**: Skip và báo user, suggest reuse
**Selectors không tìm được qua MCP**: Fallback sang manual input
