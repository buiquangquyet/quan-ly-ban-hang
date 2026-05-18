# PRD → Gherkin Mapping Guide

> Reference cho write-features skill khi convert PRD sections thành Gherkin constructs.

---

## Core Mapping

```
PRD Section              →  Gherkin Construct
─────────────────────────────────────────────
Feature Name             →  Feature: <tên>
Bối cảnh + User Stories  →  Feature description (As a / I want / So that)
Business Rule Must Have  →  Rule: <statement> # @trace {module}/{feature}/{UC-ID}/{AC-ID}
Business Rule Should Have →  Rule: <statement> # @trace ... (tag @p2)
Business Rule Won't Have →  Không generate scenario (hoặc @future @p3)
Open Questions           →  # TODO: comment trong feature file
```

### Trace ID Hierarchy

Mỗi Rule: block PHẢI có `@trace` annotation thay vì BR-M01 pattern cũ.

```
Format: @trace {module}/{feature}/{UC-ID}/{AC-ID}
        @jira {TICKET-ID}                           (optional metadata)

Module  = domain boundary (sales, inventory, hr, accounting...)
Feature = specific capability (revenue-export, stock-transfer...)
UC-ID   = use case identifier (UC-01, UC-02...)
AC-ID   = acceptance criteria (AC-01, AC-02...)
```

JIRA ID là metadata — KHÔNG phải trace ID. Trace ID dựa trên domain (ổn định), JIRA ID dựa trên project (thay đổi).

### Tester Mindset

Khi generate .feature files, PHẢI include:
- **Happy path** — `@smoke` tag
- **Error scenarios** — invalid data, missing fields, unauthorized
- **Edge cases** — boundary values, empty states, concurrent access
- **Negative paths** — `@negative` tag: what SHOULD NOT happen
- Tags: `@smoke` (happy), `@regression` (edge cases), `@negative` (error paths)

---

## 1. Feature: — Từ Bối cảnh + User Stories

```gherkin
# Mapping: AI + CÁI GÌ + TẠI SAO từ PRD
@[domain-tag]
Feature: [Tên Feature từ PRD]
  As a [persona chính — từ User Stories]
  I want [mục tiêu — từ Bối cảnh]
  So that [giá trị kinh doanh — từ Bối cảnh]
```

---

## 2. Rule: — Từ Business Rules (MoSCoW)

**Mọi Scenario nằm trong Rule:** — đảm bảo traceability từ test về business requirement gốc.

### Must Have → Core Rules (không tag priority)
```gherkin
Rule: Chỉ merchant có gói trả phí active mới được xuất hóa đơn
  # @trace billing/invoice/UC-01/AC-01 @jira KV-300
```

### Should Have → Secondary Rules (tag @p2)
```gherkin
Rule: Merchant có thể lưu hóa đơn nháp để hoàn thành sau
  # @trace billing/invoice/UC-02/AC-01 @jira KV-300 — tag scenarios với @p2
```

### Could Have / Won't Have → Future Rules
```gherkin
Rule: Merchant nhận thông báo khi hóa đơn được duyệt
  # @trace billing/invoice/UC-03/AC-01 — tag @future @p3, có thể chỉ ghi title
```

### Khi requirement có nhiều behaviors → tách thành nhiều Rules
```
PRD: "Validate dữ liệu hóa đơn gồm: format MST, tổng tiền khớp, required fields"

→ Rule: Mã số thuế phải đúng format 10 hoặc 13 chữ số
→ Rule: Tổng tiền hóa đơn phải bằng tổng các dòng chi tiết
→ Rule: Tất cả trường bắt buộc phải có giá trị
```

---

## 3. Scenario: — Từ Pre-condition / Trigger / Expected / Exception

### Happy path — từ Expected Outcome
```gherkin
@smoke
Scenario: Merchant gói trả phí xuất hóa đơn thành công
  Given Minh có gói trả phí đang active
  And Minh có đơn hàng đã hoàn thành
  When Minh yêu cầu xuất hóa đơn cho đơn hàng
  Then hóa đơn được tạo với trạng thái "Nháp"
```

### Error path — từ Exception
```gherkin
@regression
Scenario: Merchant gói miễn phí bị từ chối xuất hóa đơn
  Given Lan có gói miễn phí
  When Lan yêu cầu xuất hóa đơn
  Then hệ thống từ chối với thông báo "Cần nâng cấp gói dịch vụ"
```

### Edge cases cần xem xét cho mỗi Rule
- Precondition KHÔNG thỏa mãn?
- Data invalid / thiếu?
- User không đủ quyền?
- Hệ thống ngoài không available?
- Action đã thực hiện rồi (duplicate)?
- Concurrent access (2 người cùng làm)?

---

## 4. Background: — Precondition chung

Dùng CHỈ KHI **mọi** scenario trong Feature/Rule có cùng setup.

```gherkin
# ✅ TẤT CẢ scenarios cần cùng merchant context
Background:
  Given Minh là merchant đã đăng ký với cơ quan thuế

# ❌ Chỉ một số scenarios cần
Background:
  Given user đã đăng nhập            # Chỉ login scenarios cần
  And form hóa đơn đã mở             # Chỉ invoice scenarios cần
```

---

## 5. Tag Taxonomy (4 Dimensions)

### Dimension 1 — Test Layer (REQUIRED per Scenario)

| Tag | Layer | Khi nào |
|-----|-------|---------|
| `@api` | API | Backend logic (validation, calculation, state machine) VÀ không cần UI |
| `@web` | E2E / Browser | User tương tác qua browser HOẶC acceptance = user NHÌN THẤY gì |
| `@integration` | Cross-service | Scenario span 2+ services riêng biệt |

### Dimension 2 — Execution Scope (REQUIRED)

| Tag | Khi nào |
|-----|---------|
| `@smoke` | Happy path only — 1-2 per Rule max. Chạy mỗi push |
| `@regression` | Tất cả còn lại. Chạy trên PR / nightly |
| `@wip` | Đang develop, expected to fail. Excluded khỏi CI |
| `@future` | Chưa automate. Living documentation |

### Dimension 3 — Priority (map từ PRD MoSCoW)

| PRD Priority | Tag |
|---|---|
| Must Have | *(không tag — default)* |
| Should Have | `@p2` |
| Could Have / Won't Have | `@p3 @future` |

### Dimension 4 — Domain (trên Feature block)

Customize theo product area: `@billing`, `@inventory`, `@auth`, `@reporting`

---

## 6. Step Language Patterns

### Given — Trạng thái, KHÔNG phải hành động
```gherkin
# ✅ Trạng thái
Given Minh có hóa đơn hoàn thành với 3 dòng chi tiết
Given hệ thống đã kết nối với API cơ quan thuế

# ❌ Hành động (nên là When)
Given Minh đăng nhập vào hệ thống
```

### When — 1 hành động duy nhất
```gherkin
# ✅ Rõ ràng
When Minh gửi hóa đơn #INV-2024-001

# ❌ Nhiều hành động
When Minh điền form hóa đơn rồi bấm gửi rồi xác nhận
```

### Then — Kết quả observable (không phải implementation)
```gherkin
# ✅ Observable từ góc nhìn user
Then trạng thái hóa đơn chuyển sang "Đã gửi"

# ❌ Implementation detail
Then database record cập nhật status = 'SUBMITTED'
```

---

## 7. Handling PRD phức tạp

| Tình huống | Xử lý |
|-----------|-------|
| PRD nhiều module | Tách thành nhiều .feature files per module |
| Requirement mơ hồ | Hỏi user cụ thể, hoặc generate common cases + ghi assumption |
| Requirement kỹ thuật | Translate sang behavior, hoặc skip nếu không có behavior |
| Requirement có nhiều behaviors | Tách thành nhiều Rules |

---

## File Structure

```
features/
├── [module]/
│   ├── [feature-name].feature       # kebab-case
│   └── [feature-name-2].feature
└── [module-2]/
    └── ...
```
