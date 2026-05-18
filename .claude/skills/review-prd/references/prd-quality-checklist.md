# PRD Quality Checklist — 8 Dimensions

Checklist chi tiết cho mỗi dimension. Mỗi item là 1 check point — PASS/FAIL/WARN.
Dimensions 1-7: structural/format checks. **Dimension 8: logical analysis** — phần quan trọng nhất.

---

## 1. Structure Completeness

Verify PRD có đủ sections theo template chuẩn.

| # | Check | Pass Criteria | Severity nếu thiếu |
|---|-------|--------------|---------------------|
| 1.1 | Problem Statement | Có, >= 2 sentences, nêu rõ vấn đề + impact | BLOCKING |
| 1.2 | User Roles | Có table roles, mỗi role có description | SUGGESTION |
| 1.3 | Features & Use Cases | Có ít nhất 1 Feature với ít nhất 1 UC | BLOCKING |
| 1.4 | Non-Functional Requirements | Section tồn tại, có ít nhất Performance + Security | SUGGESTION |
| 1.5 | Out of Scope | Section tồn tại, có ít nhất 1 item | SUGGESTION |
| 1.6 | Open Questions | Section tồn tại (có thể empty nếu đã resolve hết) | NIT |
| 1.7 | No TBD/TODO | Không có placeholder text "TBD", "TODO", "to be defined" | BLOCKING |

---

## 2. Use Case Quality

Verify mỗi Use Case đủ thông tin để implement và test.

| # | Check | Pass Criteria | Severity nếu thiếu |
|---|-------|--------------|---------------------|
| 2.1 | UC có Description | Mô tả what the system does (không phải what user wants) | BLOCKING |
| 2.2 | UC có Trigger | Rõ ràng event/action nào initiates UC | SUGGESTION |
| 2.3 | UC có Main Flow | Ít nhất 3 steps mô tả happy path | BLOCKING |
| 2.4 | UC có Error Cases | Ít nhất 1 error scenario với expected behavior | SUGGESTION |
| 2.5 | UC có Business Rules | Ít nhất 1 BR linked to UC (hoặc explicit "no BRs") | SUGGESTION |
| 2.6 | UC có Acceptance Criteria | Ít nhất 2 ACs per UC | BLOCKING |
| 2.7 | Steps rõ ràng | Mỗi step là 1 action cụ thể, không gộp nhiều actions | SUGGESTION |
| 2.8 | Actor rõ ràng | Mỗi step nêu rõ ai/cái gì thực hiện (user, system, external) | NIT |

---

## 3. Business Rules Specificity

Verify mỗi Business Rule là constraint cụ thể, không mơ hồ.

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 3.1 | BR là constraint/validation/calculation | Không phải statement chung chung ("hệ thống phải nhanh") | BLOCKING |
| 3.2 | BR có boundary values | Nếu là numeric constraint → có min/max/range cụ thể | SUGGESTION |
| 3.3 | BR không dùng ambiguous words | Không có: "phù hợp", "hợp lý", "khi cần", "nếu có thể", "etc." | SUGGESTION |
| 3.4 | BR testable | Có thể viết assertion cho BR (given input → expected output/behavior) | BLOCKING |
| 3.5 | BR không trùng lặp | Không có 2 BRs nói cùng 1 điều với wording khác | NIT |
| 3.6 | BR có scope | Rõ thuộc UC nào hoặc global | NIT |

**Ambiguous words cần flag**:
- "phù hợp", "hợp lý", "đủ", "nhanh", "tốt", "an toàn"
- "khi cần", "nếu có thể", "trong trường hợp cần thiết"
- "appropriate", "reasonable", "adequate", "fast", "secure"
- "as needed", "if possible", "when necessary"
- "v.v.", "etc.", "and so on", "..."

---

## 4. AC Testability

Verify mỗi Acceptance Criteria có thể verify bằng automated test.

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 4.1 | AC có specific condition | Mô tả given/when/then hoặc input → expected output | BLOCKING |
| 4.2 | AC có measurable outcome | Output observable — data thay đổi, message hiển thị, status change | BLOCKING |
| 4.3 | AC không dùng subjective language | Không có: "dễ dùng", "user-friendly", "trực quan", "mượt" | SUGGESTION |
| 4.4 | AC independent | Mỗi AC verify được standalone, không phụ thuộc AC khác | NIT |
| 4.5 | AC covers happy + edge | Có mix happy path ACs + edge/error ACs per UC | SUGGESTION |
| 4.6 | AC unique | Không có 2 ACs verify cùng 1 behavior | NIT |

**Untestable AC patterns cần flag**:
- "Hệ thống hoạt động mượt mà" → thay bằng "Response time < 200ms"
- "Giao diện thân thiện" → thay bằng "Form hoàn thành trong <= 3 clicks"
- "Dữ liệu chính xác" → thay bằng "Tổng = sum of line items, sai lệch < 0.01"
- "User hài lòng" → không phải AC, remove hoặc convert thành measurable metric

---

## 5. Traceability Readiness

Verify PRD sẵn sàng cho downstream tools (write-features, jira-sync, trace).

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 5.1 | Feature có ID | Mỗi Feature section có identifier (tên hoặc ID) | SUGGESTION |
| 5.2 | UC có ID | UC-01, UC-02... nhất quán | SUGGESTION |
| 5.3 | BR có ID | BR-01, BR-02... nhất quán | SUGGESTION |
| 5.4 | AC có ID | AC-01, AC-02... nhất quán, scoped per UC | SUGGESTION |
| 5.5 | IDs unique | Không trùng ID trong cùng scope | BLOCKING |
| 5.6 | Module identifiable | Có thể derive module name cho @trace prefix | NIT |

**ID convention khuyến nghị**: `UC-{nn}`, `BR-{nn}`, `AC-{nn}` — scoped per Feature.
Downstream trace format: `{module}/{feature}/{UC-ID}/{AC-ID}`

---

## 6. Internal Consistency

Verify không mâu thuẫn giữa các sections.

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 6.1 | Roles used match Roles defined | Mọi role xuất hiện trong UCs đều có trong User Roles table | BLOCKING |
| 6.2 | Features match Problem Statement | Mỗi Feature giải quyết phần nào của Problem Statement | SUGGESTION |
| 6.3 | BRs consistent | Không có 2 BRs contradict nhau (vd: BR-01 says max 100, BR-05 says max 200) | BLOCKING |
| 6.4 | ACs align with BRs | Mỗi BR có ít nhất 1 AC verify nó | SUGGESTION |
| 6.5 | NFRs không contradict UCs | Performance targets realistic cho described flows | SUGGESTION |
| 6.6 | Out of Scope consistent | Items liệt kê out of scope không xuất hiện trong UCs | BLOCKING |

---

## 7. Scope & NFR Clarity

Verify scope boundaries rõ ràng và NFRs có metrics.

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 7.1 | Out of Scope explicit | Có ít nhất 1 item rõ ràng | SUGGESTION |
| 7.2 | No scope creep signals | UCs không chứa "ngoài ra", "thêm vào đó", "future" trong main flow | NIT |
| 7.3 | Performance có metrics | Response time, throughput — số cụ thể, không "nhanh" | SUGGESTION |
| 7.4 | Security requirements specific | Auth method, data encryption, access control — cụ thể | SUGGESTION |
| 7.5 | Scalability có numbers | Expected users, transactions/sec, data volume | NIT |
| 7.6 | NFRs measurable | Mỗi NFR có thể setup monitoring/benchmark | SUGGESTION |

---

## 8. Logical Completeness

Phân tích logic của PRD — đây là dimension quan trọng nhất vì phát hiện lỗi tư duy, không chỉ lỗi format.
Đọc thêm `edge-case-patterns.md` cho common patterns theo domain.

### 8A. UC Coverage — Đủ Use Cases chưa?

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 8A.1 | Happy paths đủ | Mỗi Feature có ít nhất 1 UC mô tả main success flow | BLOCKING |
| 8A.2 | CRUD completeness | Nếu có Create → kiểm tra Read, Update, Delete cũng tồn tại (hoặc explicit out of scope) | SUGGESTION |
| 8A.3 | Lifecycle coverage | Entity có state transitions → tất cả transitions có UC (vd: Order: draft → confirmed → shipped → delivered → cancelled) | BLOCKING |
| 8A.4 | Role coverage | Mỗi role trong User Roles table xuất hiện trong ít nhất 1 UC | SUGGESTION |
| 8A.5 | Reverse operations | Nếu có UC tạo/thêm → kiểm tra có UC huỷ/xoá/rollback không | SUGGESTION |
| 8A.6 | Reporting/Visibility | Nếu có UC thay đổi data → kiểm tra có UC xem/export data đó không | NIT |

**Technique**: Vẽ mental model: actors × actions × entities → tìm ô trống trong matrix.

### 8B. AC Coverage — ACs cover hết behavior chưa?

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 8B.1 | Main flow covered | Mỗi step trong Main Flow có ít nhất 1 AC verify | BLOCKING |
| 8B.2 | BR coverage | Mỗi Business Rule có ít nhất 1 AC verify nó (cross-ref BR → AC) | BLOCKING |
| 8B.3 | Error cases covered | Mỗi Error Case listed có ít nhất 1 AC | SUGGESTION |
| 8B.4 | Boundary ACs | Nếu BR có numeric range → có AC cho min, max, và just-outside boundary | SUGGESTION |
| 8B.5 | State change ACs | UC thay đổi state → AC verify state trước + sau | SUGGESTION |
| 8B.6 | Output ACs | UC produce output (file, email, notification) → AC verify output content/format | SUGGESTION |

**Technique**: Cho mỗi UC, map: Main Flow steps → ACs, BRs → ACs, Error Cases → ACs. Ô trống = gap.

### 8C. Conflict Detection — Có mâu thuẫn logic không?

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 8C.1 | UC-UC conflict | Không có 2 UCs produce contradictory outcomes cho cùng entity/state | BLOCKING |
| 8C.2 | BR-BR conflict | Không có 2 BRs set different constraints cho cùng field/behavior | BLOCKING |
| 8C.3 | BR-UC flow conflict | BRs không block Main Flow steps (vd: BR says "max 5 items" nhưng UC flow doesn't check) | BLOCKING |
| 8C.4 | AC-AC conflict | Không có 2 ACs expect different outcomes cho same input | BLOCKING |
| 8C.5 | Temporal conflict | Ordering assumptions consistent (vd: UC-01 says "after approval" nhưng UC-03 allows action "before approval") | SUGGESTION |
| 8C.6 | Permission conflict | Role permissions consistent across UCs (vd: UC-01 says Admin-only, UC-04 allows Manager) | BLOCKING |

**Technique**: Cross-reference matrix — list tất cả entities × states × roles, check mỗi UC nói gì về combination đó.

### 8D. Edge Case & Error Coverage

| # | Check | Pass Criteria | Severity nếu fail |
|---|-------|--------------|---------------------|
| 8D.1 | Empty/zero state | UC xử lý khi data empty, list rỗng, giá trị = 0 | SUGGESTION |
| 8D.2 | Boundary values | Numeric limits: min-1, min, max, max+1 có được xử lý | SUGGESTION |
| 8D.3 | Concurrent access | Nếu multi-user → xử lý khi 2 users cùng edit, cùng submit | SUGGESTION |
| 8D.4 | Authorization failures | Mỗi UC có error case cho unauthorized access | SUGGESTION |
| 8D.5 | Validation failures | Input fields có validation → error case cho invalid input | SUGGESTION |
| 8D.6 | External system failures | Nếu UC gọi external service → error case cho timeout, unavailable | SUGGESTION |
| 8D.7 | Partial completion | Multi-step UC → xử lý khi user abandon giữa chừng | NIT |
| 8D.8 | Duplicate submission | Form/action submit → xử lý double-click, retry | NIT |
| 8D.9 | Data volume extremes | UC xử lý khi data lớn bất thường (1M records, file 100MB) | NIT |
| 8D.10 | Time-sensitive behavior | Nếu có deadline/expiry → xử lý khi expired, timezone differences | SUGGESTION |

**Technique**: Dùng `edge-case-patterns.md` để match domain của PRD → identify missing patterns.

---

## Scoring Guide

Mỗi dimension score 0-10:

| Score | Meaning |
|-------|---------|
| 9-10 | Excellent — tất cả checks PASS |
| 7-8 | Good — chỉ có NIT/minor SUGGESTION |
| 5-6 | Needs work — có SUGGESTION quan trọng |
| 3-4 | Weak — có BLOCKING items |
| 0-2 | Missing/Empty — section không tồn tại hoặc quá sơ sài |

**Overall score** = weighted average 8 dimensions.
**Dimension 8 (Logical Completeness) weight = 2x** — lỗi logic nghiêm trọng hơn lỗi format.
Formula: `(D1 + D2 + D3 + D4 + D5 + D6 + D7 + D8×2) / 9`

**Verdict**:
- **>= 8.0 và 0 BLOCKING** → `READY FOR REVIEW` — PRD đủ chất lượng cho stakeholder review
- **>= 6.0 và 0 BLOCKING** → `NEEDS MINOR REVISION` — fix SUGGESTION rồi ready
- **< 6.0 hoặc có BLOCKING** → `NEEDS REVISION` — phải fix BLOCKING trước
