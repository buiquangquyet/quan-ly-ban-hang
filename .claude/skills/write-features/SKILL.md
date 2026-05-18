---
name: write-features
description: >-
  Convert PRD/requirements thành Gherkin .feature files với Rule: blocks gắn @trace IDs
  (module/feature/UC/AC) cho traceability. Include tester mindset: edge cases, negative paths,
  boundary conditions. Steps viết tiếng Việt, Gherkin syntax tiếng Anh.
  Dùng khi user có PRD, spec, requirements và muốn generate feature files.
  Trigger: "tạo feature file", "generate Gherkin", "viết scenarios", "convert PRD to BDD",
  "gen gherkin", "feature file từ PRD", "viết BDD từ spec".
  Do NOT use for implementing step definitions (use test),
  full QC workflow (use test), hoặc reviewing existing .feature files.
argument-hint: PRD link, Confluence page, hoặc paste nội dung requirements
---

# PRD to Gherkin Feature File Writer

Convert PRD/requirements thành Gherkin `.feature` files. Mọi Scenario nằm trong `Rule:` block — để đảm bảo traceability từ test về business requirement gốc (scenario không trong Rule sẽ mất liên kết với PRD).

## References

- Gherkin quality rules, anti-patterns, scenario outline: `references/gherkin-quality-rules.md`
- PRD → Gherkin mapping chi tiết, tag taxonomy, personas: `references/prd-mapping-guide.md`
- Domain glossary template cho step language nhất quán: `references/domain-glossary-template.md`

## Ngôn ngữ

- **Gherkin syntax** (Feature, Rule, Scenario, Given, When, Then...) → **tiếng Anh**
- **Nội dung steps, Rule description, Feature description** → **tiếng Việt**
- **Tag names** → tiếng Anh (lowercase, kebab-case)

---

## Bước 1: Parse PRD

$ARGUMENTS

**Actions**:
1. Nếu có Confluence link → dùng Atlassian MCP đọc page
2. Extract:
   - **Feature name** — đang build gì (1 Feature per PRD/epic)
   - **Primary persona(s)** — user là ai
   - **Business Rules** — mỗi Must Have / Should Have → 1 Rule + @trace ID
   - **Module/Feature hierarchy** — xác định domain module + feature name cho trace IDs
   - **Examples** — behaviors cụ thể, edge cases
   - **Open questions** — chưa resolve → `# TODO:` comments
3. Nếu PRD thiếu thông tin quan trọng → hỏi 1 câu targeted, không hỏi nhiều cùng lúc

---

## Bước 2: Structure Feature Files

**Actions**:
1. Đọc `references/prd-mapping-guide.md` cho mapping rules
2. Đọc `references/domain-glossary-template.md` cho persona naming + step phrases
3. Tạo structure:

```gherkin
# PRD: [link Confluence]
@[domain-tag]
Feature: [Tên Feature]
  As a [persona chính]
  I want [mục tiêu]
  So that [giá trị kinh doanh]

  Background: (optional — chỉ khi TẤT CẢ scenarios cùng setup)
    Given [precondition chung]

  Rule: [Business Rule statement — KHÔNG phải technical statement]
    # @trace {module}/{feature}/{UC-ID}/{AC-ID} @jira {TICKET-ID}

    @[test-layer] @smoke
    Scenario: [Happy path]
      Given / When / Then

    @[test-layer] @regression
    Scenario: [Error/edge case]
      Given / When / Then
```

**File structure**: `features/[module]/[feature-name].feature` (kebab-case)

---

## Bước 3: Apply Quality Rules

**Actions**:
1. Đọc `references/gherkin-quality-rules.md`
2. Verify mỗi Rule:
   - Business rule statement (không phải technical)
   - Trace về PRD requirement (có @trace ID)
   - Ít nhất 2 scenarios (happy + error/edge case)
   - Include tester perspective: negative paths, boundary values, concurrent access
3. Verify mỗi Scenario:
   - 1 scenario = 1 behavior
   - Declarative, không imperative
   - 3–5 steps (max 9)
   - Ngôi thứ ba, thì hiện tại

---

## Bước 4: Apply Tags

Mỗi scenario cần tags từ 3 dimensions:

| Dimension | Tags | Rule |
|-----------|------|------|
| **Test Layer** (required) | `@api` / `@web` / `@integration` | Backend logic = @api, UI flow = @web, cross-service = @integration |
| **Execution Scope** (required) | `@smoke` / `@regression` / `@wip` / `@future` | Happy path = @smoke (max 2/Rule), rest = @regression |
| **Priority** | *(none)* / `@p2` / `@p3 @future` | Must Have = default, Should Have = @p2, Could/Won't = @p3 @future |

Domain tag (`@billing`, `@inventory`...) đặt trên Feature block.

---

## Bước 5: Output

Luôn output:

1. **Feature files** theo structure `features/[module]/[feature].feature`

2. **Traceability Matrix**:
```
| Rule | @trace ID | JIRA | Priority | Scenarios | Tags |
|------|-----------|------|----------|-----------|------|
| Chỉ merchant active mới gửi được | billing/invoice/UC-01/AC-01 | KV-300 | Must Have | 3 | @api @smoke @regression @negative |
```

3. **Open Questions** (nếu có):
```
- [ ] [Question] → Cần cho: Rule "[rule name]"
```

---

## JIRA Integration

Nếu .feature files được generate từ JIRA ticket/epic:
1. Dùng `addCommentToJiraIssue` link generated files:
   ```
   **BDD Scenarios Generated**
   - {count} feature files, {count} scenarios
   - Files: {list of .feature file paths}
   - Trace IDs: {list of @trace IDs}
   ```
2. Nếu có [AI] BDD subtask → dùng `transitionJiraIssue` chuyển sang Done

---

## Examples

**Example 1: Từ Confluence PRD**
User says: "/write-features https://example.atlassian.net/wiki/..."
Actions:
1. Đọc Confluence page via Atlassian MCP
2. Extract: 3 business rules, 2 personas
3. Structure: 1 Feature, 3 Rules with @trace IDs (billing/invoice/UC-01..UC-03)
4. Generate: 7 scenarios (3 smoke, 4 regression)
5. Output: .feature file + traceability matrix + 1 open question
Result: `features/billing/merchant-invoice.feature` với full traceability

**Example 2: Từ paste text**
User says: "/write-features" + paste PRD content
Actions:
1. Parse PRD text → extract requirements
2. Hỏi 1 câu targeted cho requirement mơ hồ
3. Generate .feature files
Result: Feature files ready for step generation

## Troubleshooting

**PRD quá mơ hồ**: Hỏi user "Cụ thể scenario lỗi nào cần cover?"
**PRD nhiều module**: Tách thành nhiều .feature files per module
**Requirement kỹ thuật**: Translate sang user behavior, hoặc skip nếu không có behavior
