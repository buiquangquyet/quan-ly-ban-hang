---
description: "Three Amigos — 3 perspectives (PO, Tech, Test) refine PRD song song → BDD feature files với traceability"
argument-hint: <PRD link, Confluence page, hoặc paste requirements>
---

# Team Three Amigos — Refinement PRD → BDD Feature Files

Spawn team 3 agents đại diện cho 3 perspectives (Business, Technical, Test) cùng phân tích và refine PRD, sau đó generate BDD feature files có traceability.

**Yêu cầu**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## Context

$ARGUMENTS

---

## Quy trình

### Step 1: Parse PRD

1. Nếu có Confluence link → dùng Atlassian MCP đọc page content
2. Nếu text → parse trực tiếp từ $ARGUMENTS
3. Extract sơ bộ: feature name, personas, business rules, examples, open questions

### Step 2: Tạo Team và Tasks

Tạo team `three-amigos-<short-feature-name>`.

Tạo tasks:

| Task | Dependencies | Assignee |
|------|-------------|----------|
| `analyze-business` | none | gia-cat-luong |
| `analyze-technical` | none | quan-vu |
| `analyze-testability` | none | tu-ma-y |
| `debate-and-refine` | analyze-business, analyze-technical, analyze-testability | tao-thao (lead) |
| `generate-features` | debate-and-refine | tao-thao (lead) |
| `cross-review` | generate-features | gia-cat-luong, quan-vu, tu-ma-y |

### Step 3: Spawn Three Amigos song song

Spawn 3 teammates cùng lúc, mỗi agent nhận PRD content và focus vào perspective riêng:

**Gia Cát Lượng** — Product Owner perspective (dùng agent type: `code-architect`):
> Phân tích PRD từ góc nhìn BUSINESS. Bạn là Gia Cát Lượng — Product Owner đại diện cho stakeholders.
>
> **Focus**:
> - Extract business rules → mỗi rule gắn BR-ID (BR-M01, BR-M02... cho Must Have, BR-S01... cho Should Have)
> - Xác định primary personas và goals
> - Phân loại priority: Must Have / Should Have / Could Have
> - Acceptance criteria cho mỗi business rule
> - Edge cases từ góc nhìn business (không phải technical)
> - Identify requirements mơ hồ cần clarify
>
> **Output**: Danh sách business rules với BR-IDs, personas, priorities, acceptance criteria, open questions business.

**Quan Vũ** — Technical Expert perspective (dùng agent type: `code-explorer`):
> Phân tích PRD từ góc nhìn TECHNICAL. Bạn là Quan Vũ — Technical Expert đánh giá feasibility.
>
> **Focus**:
> - Đánh giá technical feasibility cho từng requirement
> - Xác định integration points với systems hiện có
> - Performance concerns (data volume, concurrency, latency)
> - Technical constraints và limitations
> - Architecture impact — cần thay đổi gì trong codebase
> - Missing technical requirements PRD chưa đề cập
> - Security implications
>
> **Output**: Technical feasibility assessment, integration points, constraints, missing technical reqs, architecture impact.

**Tư Mã Ý** — Test Expert perspective (dùng agent type: `test-engineer`):
> Phân tích PRD từ góc nhìn TESTING. Bạn là Tư Mã Ý — Test Expert đảm bảo testability.
>
> **Focus**:
> - Test scenarios cho mỗi business rule: happy path + error/edge cases
> - Negative test paths PRD chưa đề cập
> - Test type classification: @api (backend logic), @web (UI flow), @integration (cross-service)
> - Data setup requirements cho mỗi scenario
> - Testability concerns — requirements nào khó test, cần refine
> - Test priority: @smoke (happy path, max 2/Rule) vs @regression
>
> **Output**: Danh sách test scenarios với classification, negative paths, data requirements, testability concerns.

### Step 4: Three Amigos Debate

Sau khi cả 3 agents hoàn thành, lead (Tào Tháo) tổng hợp:

1. **Merge findings** — gộp business rules + technical assessment + test scenarios
2. **Identify conflicts**:
   - Business muốn feature X nhưng Tech nói infeasible → propose alternative
   - Test thấy edge case mà PO chưa consider → bổ sung requirement
   - Tech thấy missing requirement mà PO chưa nghĩ tới → thêm vào scope
3. **Resolve gaps** — với mỗi conflict/gap, đề xuất resolution
4. **Hỏi user** clarify open questions từ cả 3 perspectives. Gộp tất cả câu hỏi thành 1 organized list, đợi user trả lời trước khi tiếp.

### Step 5: Generate Feature Files

Sau khi user trả lời questions, áp dụng workflow từ skill `write-features`:

1. Đọc references:
   - `${CLAUDE_PLUGIN_ROOT}/skills/write-features/references/gherkin-quality-rules.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/write-features/references/prd-mapping-guide.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/write-features/references/domain-glossary-template.md`

2. Structure feature files:
   ```gherkin
   # PRD: [link/source]
   @[domain-tag]
   Feature: [Tên Feature]
     As a [persona]
     I want [mục tiêu]
     So that [giá trị kinh doanh]

     Rule: [Business Rule statement]
       # BR-M01

       @[test-layer] @smoke
       Scenario: [Happy path — tiếng Việt]
         Given / When / Then

       @[test-layer] @regression
       Scenario: [Error/edge case — tiếng Việt]
         Given / When / Then
   ```

3. Apply quality rules:
   - Mỗi Rule: business statement (không technical), có BR-ID, ít nhất 2 scenarios
   - Mỗi Scenario: 1 behavior, declarative, 3-5 steps (max 9)
   - Tags: @api/@web + @smoke/@regression + priority

4. File structure: `features/[module]/[feature-name].feature`

### Step 6: Cross-Review

Gửi feature files cho cả 3 amigos review lần cuối:

- **Gia Cát Lượng**: business rules covered đầy đủ? Priorities đúng? Acceptance criteria đủ?
- **Quan Vũ**: scenarios feasible? Technical constraints reflected? Integration points covered?
- **Tư Mã Ý**: scenarios complete? Edge cases đủ? Test types đúng? Data setup realistic?

Tổng hợp feedback, chỉnh sửa nếu cần.

---

## Output

1. **Feature files** — `features/[module]/[feature].feature`

2. **Traceability Matrix**:
   | Rule | @trace ID | JIRA | Priority | Scenarios | Tags |
   |------|-----------|------|----------|-----------|------|

3. **JIRA Integration** (nếu có epic ID):
   - Auto-trigger `/jira-sync` decompose epic → [AI] sub-tasks
   - Dùng `addCommentToJiraIssue` link feature files + traceability matrix
   - Transition [AI] BDD subtask → Done

4. **Three Amigos Summary**:
   - Agreements: những gì 3 perspectives đồng ý
   - Decisions: conflicts đã resolve và rationale
   - Deferred: items cần investigate thêm
   - Open Questions: chưa resolve

4. **Open Questions** (nếu còn):
   - [ ] [Question] → Cần cho: Rule "[rule name]"

---

## Coordination Rules

- 3 amigos phân tích SONG SONG, KHÔNG bias lẫn nhau
- Mỗi amigo chỉ focus vào perspective của mình
- Lead tổng hợp và resolve conflicts — KHÔNG để 1 perspective dominate
- **Hỏi user** trước khi generate feature files — đợi confirm
- Tất cả agents READ-ONLY đối với codebase (chỉ write feature files)
- Feature files viết steps tiếng Việt, Gherkin syntax tiếng Anh

## Examples

**Example 1: PRD từ Confluence**
```
/team-three-amigos https://kiotviet.atlassian.net/wiki/.../merchant-invoice
```
→ 3 amigos phân tích → debate → 1 feature file `features/billing/merchant-invoice.feature` với 3 Rules, 8 scenarios, traceability matrix

**Example 2: PRD paste text**
```
/team-three-amigos
Feature: Export báo cáo doanh thu
- Merchant có thể export báo cáo theo ngày/tuần/tháng
- Format: Excel và PDF
- Chỉ merchant active mới được export
```
→ 3 amigos refine → bổ sung edge cases (data rỗng, file size limit, concurrent export) → feature file + matrix

## Troubleshooting

- **Atlassian MCP không available**: Hỏi user paste PRD content trực tiếp
- **PRD quá mơ hồ**: Gia Cát Lượng lead câu hỏi clarification, đợi user trả lời
- **3 amigos conflict không resolve được**: Present cả options cho user quyết định
- **Feature file quá lớn**: Tách thành nhiều .feature files per module
