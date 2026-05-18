# BDD Quality Checklist

> Reference cho review-bdd skill khi review .feature files.

---

## Dimension 1: Structural Compliance (0-10)

Gherkin syntax và structure tuân thủ chuẩn.

### Checks

| # | Check | Severity nếu vi phạm |
|---|-------|----------------------|
| 1.1 | Mỗi `.feature` file có đúng 1 `Feature:` block | BLOCKING |
| 1.2 | Mọi Scenario nằm trong `Rule:` block (không orphan) | BLOCKING |
| 1.3 | Step order đúng: Given → When → Then (không When sau Then) | BLOCKING |
| 1.4 | Mỗi Scenario có ít nhất Given + When + Then | BLOCKING |
| 1.5 | Step count: 3-5 steps (ideal), max 9 | SUGGESTION nếu >5, BLOCKING nếu >9 |
| 1.6 | And/But chỉ nối steps cùng loại (And Given, And Then) | SUGGESTION |
| 1.7 | Background chỉ chứa Given steps | BLOCKING |
| 1.8 | Feature description có As a / I want / So that | SUGGESTION |
| 1.9 | File name kebab-case, nằm trong `features/[module]/` | NIT |

### Scoring Guide

| Score | Criteria |
|-------|----------|
| 9-10 | Tất cả checks pass |
| 7-8 | Chỉ NIT/SUGGESTION violations |
| 4-6 | 1-2 BLOCKING violations |
| 0-3 | Nhiều BLOCKING — syntax errors, orphan scenarios |

---

## Dimension 2: Semantic Quality (0-10)

Steps mô tả business behavior, không phải technical implementation.

### Checks

| # | Check | Severity |
|---|-------|----------|
| 2.1 | Steps declarative (mô tả "what"), không imperative (mô tả "how") | SUGGESTION |
| 2.2 | 1 Scenario = 1 behavior (không có When→Then→When→Then) | BLOCKING |
| 2.3 | Given = trạng thái (không phải hành động) | SUGGESTION |
| 2.4 | When = 1 hành động duy nhất | SUGGESTION |
| 2.5 | Then = observable result từ góc nhìn user (không phải DB/implementation) | SUGGESTION |
| 2.6 | Present tense + third person (không past, không "tôi") | NIT |
| 2.7 | Scenario title concise, mô tả behavior, không phải "Test 1" | SUGGESTION |
| 2.8 | Rule statement là business rule, không phải technical statement | SUGGESTION |
| 2.9 | Mỗi step có complete subject-predicate (không missing subject) | SUGGESTION |

### Imperative Detection Patterns

Các pattern thường gặp cho imperative steps (nên flag):

```
# UI interaction verbs → imperative
click, tap, bấm, nhấn, chọn menu, mở tab, kéo thả
enter, nhập vào field, điền form, type
navigate, go to, truy cập URL, mở trang

# Technical details → implementation
database, DB, API call, HTTP, request, response
column, field name, table, query, endpoint
status code, JSON, payload
```

### Verification Question

"Nếu implementation thay đổi (đổi UI framework, đổi API), wording scenario có cần thay đổi không?"
- Nếu **yes** → imperative, cần rewrite
- Nếu **no** → declarative, OK

### Scoring Guide

| Score | Criteria |
|-------|----------|
| 9-10 | Tất cả steps declarative, 1 behavior/scenario, business language |
| 7-8 | 1-2 imperative steps hoặc minor semantic issues |
| 4-6 | Multiple imperative steps hoặc multi-behavior scenarios |
| 0-3 | Phần lớn steps imperative, procedure-driven tests |

---

## Dimension 3: Tag Compliance (0-10)

Tags đầy đủ 4 dimensions và values hợp lệ.

### Checks

| # | Check | Severity |
|---|-------|----------|
| 3.1 | Mỗi Scenario có Test Layer tag: `@api` / `@web` / `@integration` | BLOCKING |
| 3.2 | Mỗi Scenario có Execution Scope: `@smoke` / `@regression` / `@wip` / `@future` | BLOCKING |
| 3.3 | Feature block có Domain tag (`@billing`, `@inventory`...) | SUGGESTION |
| 3.4 | Max 2 `@smoke` scenarios per Rule | SUGGESTION |
| 3.5 | Priority tags match PRD MoSCoW: Must Have = default, Should Have = `@p2`, Could/Won't = `@p3 @future` | SUGGESTION |
| 3.6 | Tag names lowercase kebab-case | NIT |
| 3.7 | Không có tag unknown/custom không thuộc taxonomy | NIT |
| 3.8 | `@negative` tag cho error/rejection scenarios | SUGGESTION |

### Valid Tag Values

```
Test Layer:     @api, @web, @integration
Scope:          @smoke, @regression, @wip, @future
Priority:       (none), @p2, @p3
Domain:         @billing, @inventory, @auth, @reporting, @sales, @hr, @accounting (+ custom)
Behavior:       @negative, @boundary, @concurrent
```

### Scoring Guide

| Score | Criteria |
|-------|----------|
| 9-10 | Tất cả scenarios có đủ required tags, values hợp lệ |
| 7-8 | Missing 1-2 optional tags hoặc minor mismatches |
| 4-6 | Missing required tags (Test Layer hoặc Scope) trên nhiều scenarios |
| 0-3 | Không có tag taxonomy, random tags |

---

## Dimension 4: Step Language Consistency (0-10)

Cùng concept dùng cùng term xuyên suốt — step definitions tái sử dụng được.

### Checks

| # | Check | Severity |
|---|-------|----------|
| 4.1 | Cùng concept dùng cùng term (không mix "đơn hàng" và "order" và "đơn") | SUGGESTION |
| 4.2 | Persona names nhất quán (dùng tên từ glossary, không đổi giữa scenarios) | SUGGESTION |
| 4.3 | Steps follow patterns từ Step Phrase Library | NIT |
| 4.4 | Status values dùng consistent format (quoted: "Nháp", "Đã gửi") | NIT |
| 4.5 | Given steps reusable — cùng precondition viết giống nhau across scenarios | SUGGESTION |
| 4.6 | Ngôn ngữ đúng convention: Gherkin keywords tiếng Anh, nội dung tiếng Việt | SUGGESTION |
| 4.7 | Không mix first/third person trong steps | NIT |

### Consistency Detection

Khi review, xây dựng bảng terms đã dùng:

```
| Concept | Terms dùng | Nhất quán? |
|---------|-----------|------------|
| Hóa đơn | "hóa đơn" (x5), "invoice" (x1) | ❌ inconsistent |
| Merchant | "Minh" (x8) | ✅ consistent |
| Trạng thái | "Nháp", "Đã gửi", "Hoàn thành" | ✅ consistent |
```

Flag nếu cùng concept có >1 term.

### Scoring Guide

| Score | Criteria |
|-------|----------|
| 9-10 | Terms nhất quán, personas đúng glossary, steps reusable |
| 7-8 | 1-2 inconsistencies minor |
| 4-6 | Nhiều terms inconsistent, steps khó reuse |
| 0-3 | Mỗi scenario viết khác nhau, không pattern |

---

## Dimension 5: Scenario Outline Correctness (0-10)

Scenario Outline dùng đúng mục đích, không lạm dụng.

### Checks

| # | Check | Severity |
|---|-------|----------|
| 5.1 | Mỗi row trong Examples = different equivalence class (không chỉ data khác) | SUGGESTION |
| 5.2 | Columns relate cùng behavior (independent columns → tách scenarios) | SUGGESTION |
| 5.3 | Reader CẦN thấy data? Nếu không → hide trong step defs | NIT |
| 5.4 | Không dùng Outline cho chỉ 1 row | SUGGESTION |
| 5.5 | N fields × M inputs → verify combination explosion managed | SUGGESTION |
| 5.6 | Mỗi row có khác behavior (Then steps khác nhau) hoặc khác result | SUGGESTION |

### Misuse Detection Patterns

**Pattern 1: Same equivalence class**
```gherkin
# ❌ 3 rows cùng behavior "valid email" — chỉ cần 1
Examples:
  | email            |
  | john@example.com |
  | jane@example.com |  # same class
  | bob@example.com  |  # same class
```

**Pattern 2: Independent columns**
```gherkin
# ❌ name và payment_method independent → tách 2 scenarios
Examples:
  | name | payment_method |
  | Minh | credit_card    |
  | Lan  | bank_transfer  |
```

**Pattern 3: Single row outline**
```gherkin
# ❌ Chỉ 1 row → dùng plain Scenario
Scenario Outline: ...
  Examples:
    | amount |
    | 100000 |
```

### Scoring Guide

| Score | Criteria |
|-------|----------|
| 9-10 | Outlines dùng đúng, equivalence classes rõ, hoặc không dùng Outline |
| 7-8 | 1 Outline có minor misuse |
| 4-6 | Multiple Outlines misused |
| 0-3 | Outlines lạm dụng thay cho plain Scenarios |

Nếu feature file **không có Scenario Outline** → score mặc định 9 (không có gì sai).

---

## Dimension 6: PRD Coverage (0-10) — Weight x2

Feature files cover đầy đủ requirements từ PRD.

### Checks

| # | Check | Severity |
|---|-------|----------|
| 6.1 | Mỗi UC Must Have trong PRD có ít nhất 1 Rule trong feature file | BLOCKING |
| 6.2 | Mỗi AC có ít nhất 1 Scenario với matching behavior | BLOCKING |
| 6.3 | `@trace` IDs khớp với PRD UC/AC numbering | BLOCKING |
| 6.4 | Mỗi Rule có ≥2 scenarios: happy path + error/edge | SUGGESTION |
| 6.5 | Error scenarios cover: invalid data, missing fields, unauthorized | SUGGESTION |
| 6.6 | Edge cases cover: boundary values, empty states, duplicates | SUGGESTION |
| 6.7 | Concurrent access scenarios cho shared resources | SUGGESTION |
| 6.8 | Should Have (P2) requirements có Rules (có thể tagged @p2 @future) | SUGGESTION |
| 6.9 | Business Rules từ PRD map 1:1 với Rule: blocks | SUGGESTION |
| 6.10 | Open questions từ PRD reflected as `# TODO:` comments | NIT |

### Coverage Categories

Cho mỗi UC/AC, classify coverage level:

| Level | Meaning |
|-------|---------|
| **Full** | Happy + error + edge case scenarios |
| **Partial** | Chỉ happy path hoặc thiếu edge cases |
| **Missing** | Không có Rule/Scenario nào |
| **N/A** | Won't Have / explicitly excluded |

### Edge Case Checklist

Cho mỗi Rule, verify đã cover:

- [ ] Precondition không thỏa mãn (user chưa login, gói hết hạn...)
- [ ] Data invalid / thiếu required fields
- [ ] User không đủ quyền (role sai, permission thiếu)
- [ ] Duplicate action (gửi 2 lần, tạo trùng)
- [ ] Boundary values (0, max, empty string, special chars)
- [ ] External system unavailable / timeout
- [ ] Concurrent access (2 users cùng edit)

### Scoring Guide

| Score | Criteria |
|-------|----------|
| 9-10 | 100% UCs covered, ≥90% ACs covered, edge cases đầy đủ |
| 7-8 | >80% coverage, thiếu một số edge cases |
| 4-6 | 50-80% coverage, missing Must Have scenarios |
| 0-3 | <50% coverage, nhiều UCs thiếu hoàn toàn |

Nếu **không có PRD** để cross-check → score mặc định 5 với finding `[QUESTION]` yêu cầu provide PRD.

---

## Overall Scoring

### Formula

**(D1 + D2 + D3 + D4 + D5 + D6×2) / 7**

Dimension 6 weighted x2 vì coverage gaps nghiêm trọng hơn style issues — feature file đẹp mà thiếu scenarios thì vẫn fail khi implement.

### Verdict Thresholds

| Score | Verdict | Action |
|-------|---------|--------|
| >= 8.0 | **READY FOR STEP GENERATION** | Proceed → `/generate-steps` |
| 6.0 - 7.9 | **NEEDS MINOR REVISION** | Fix findings, re-review |
| 4.0 - 5.9 | **NEEDS MAJOR REVISION** | Significant rewrite needed |
| < 4.0 | **REWRITE RECOMMENDED** | Go back → `/write-features` |

### Verdict Escalation

Score-based thresholds có thể bị mask khi D1-D5 cao nhưng coverage gaps nghiêm trọng. Apply escalation rules sau khi tính score:

| Condition | Escalation |
|-----------|------------|
| >= 3 BLOCKING findings | Verdict tối thiểu **NEEDS MAJOR REVISION**, bất kể score |
| >= 5 BLOCKING findings | Verdict tối thiểu **REWRITE RECOMMENDED** |
| Coverage < 50% (khi có PRD) | Verdict tối thiểu **NEEDS MAJOR REVISION** |
| Bất kỳ Must Have UC thiếu hoàn toàn | Verdict không thể là READY FOR STEP GENERATION |

Escalation chỉ kéo verdict **xuống**, không bao giờ kéo **lên**. Ví dụ: score 6.4 (MINOR) + 5 BLOCKING → escalate thành REWRITE RECOMMENDED. Score 3.0 (REWRITE) + 1 BLOCKING → giữ REWRITE (không kéo lên MAJOR).
