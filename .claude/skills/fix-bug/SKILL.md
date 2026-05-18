---
name: fix-bug
description: >-
  Điều tra và fix bug có hệ thống — explore codebase tìm root cause, viết test reproduce bug,
  fix, review đảm bảo không regression. Dùng khi user phát hiện bug trong development, cần debug
  logic sai, hoặc trace lỗi chưa rõ nguyên nhân. Trigger: "fix bug", "debug", "sửa lỗi",
  "tại sao bị lỗi", "trace bug", "tìm root cause", "bug investigation", "reproduce bug",
  "logic sai", "kết quả sai", "không hoạt động đúng", "intermittent bug", "flaky behavior".
  Do NOT use for production incidents with monitoring/alerts (use respond-incident),
  building new features (use develop), standalone code review (use review),
  refactoring without a specific bug (use refactor), hoặc standalone testing (use test).
argument-hint: "Mô tả bug hoặc error message"
---

# Bug Investigation & Fix

Điều tra và fix bug một cách có hệ thống — hiểu trước khi sửa, test trước khi fix.

## Core Principles

- **Hiểu trước khi sửa** — shotgun debugging tạo ra bugs mới và che giấu root cause thật. Phải xác định root cause có evidence trước
- **Test trước khi fix** — viết failing test reproduce bug giúp lock bug behavior, đảm bảo fix thực sự sửa đúng vấn đề, và ngăn regression
- **Minimal fix** — sửa đúng root cause, không thay đổi code không liên quan. Thay đổi càng nhỏ càng dễ review và ít risk
- **Dùng TodoWrite** — structured tracking persist across agent steps, giúp user theo dõi tiến độ

## References

- Bug classification, investigation strategies: xem `references/debugging-patterns.md`
- Root cause analysis techniques: xem `references/root-cause-analysis.md`

---

## Phase 1: Understand the Bug

**Goal**: Thu thập đủ thông tin để bắt đầu điều tra

Initial request: $ARGUMENTS

**Actions**:
1. Tạo todo list với tất cả phases
2. Nếu có JIRA ticket ID -> dùng Atlassian MCP lấy ticket details, steps to reproduce, environment info
3. Thu thập từ user (nếu chưa rõ):
   - **Symptom**: Gì xảy ra sai? Expected vs actual behavior
   - **Steps to reproduce**: Chính xác làm gì để trigger bug
   - **Frequency**: Luôn xảy ra, intermittent, hay chỉ trong điều kiện cụ thể?
   - **Recent changes**: Có deploy/merge gần đây không? (`git log --oneline -20`)
4. Tóm tắt understanding, confirm với user

---

## Phase 2: Investigate

**Goal**: Tìm root cause với evidence (file:line)

**Actions**:
1. Đọc `references/debugging-patterns.md` để classify bug type và chọn investigation strategy
2. Launch 2-3 **code-explorer** agents song song — target aspects khác nhau:
   - Agent 1: Trace execution path của buggy flow (from entry point to output)
   - Agent 2: Tìm similar logic/patterns trong codebase (bug có thể ảnh hưởng nhiều nơi)
   - Agent 3 (nếu cần): Kiểm tra recent changes liên quan (`git log --all -p -- <file>`)
3. Nếu bug liên quan database (data sai, query chậm, deadlock) -> launch thêm **db-engineer** agent với `sqlserver-expert` references
4. Đọc tất cả files agents xác định — agent summaries có thể miss details
5. Dùng Context7 MCP tra cứu library docs nếu bug liên quan third-party library

---

## Phase 3: Hypothesis & Confirm Root Cause

**Goal**: Xác nhận root cause trước khi sửa — tránh fix symptom thay vì cause

**Actions**:
1. Đọc `references/root-cause-analysis.md`
2. Formulate hypothesis: "Bug xảy ra vì [root cause] tại [file:line], dẫn đến [symptom]"
3. Verify hypothesis bằng evidence: trace code path, check data flow, confirm logic
4. Present cho user:
   - **Root cause**: Mô tả chính xác với file:line references
   - **Evidence**: Tại sao tin đây là root cause
   - **Impact scope**: Bug ảnh hưởng những flows nào khác?
   - **Complexity assessment**: Simple fix hay cần thiết kế approach?
5. **Hỏi user confirm** trước khi tiếp tục

**Nếu root cause chưa rõ** (bug quá complex hoặc nhiều possible causes):
- Present tất cả hypotheses với confidence level
- Đề xuất investigation steps tiếp theo
- **Hỏi user**: investigate thêm hay chọn hypothesis likely nhất để proceed?

**Nếu bug intermittent / hard to reproduce**:
- Document exact conditions khi bug xảy ra
- Check: race conditions, timing dependencies, data-dependent paths
- Propose cách stabilize reproduction (specific data, specific timing, logging thêm)

---

## Phase 4: Write Failing Test (RED)

**Goal**: Viết test reproduce bug — test phải FAIL trước khi fix

Đợi user confirm root cause trước.

**Actions**:
1. Xác định test level phù hợp:
   - **Unit test**: Bug trong pure logic, calculation, data transformation
   - **Integration test**: Bug trong interaction giữa components, DB queries
   - Nếu bug quá khó test (UI-only, infra-dependent) -> explain tại sao, propose alternative verification
2. Viết test:
   - Test name mô tả bug behavior
   - Arrange: setup exact conditions trigger bug
   - Act: execute buggy flow
   - Assert: verify expected (correct) behavior — test sẽ FAIL vì bug chưa fix
3. Run test -> confirm FAIL (RED) — nếu test PASS thì test chưa capture đúng bug, revise

---

## Phase 5: Fix the Bug (GREEN)

**Goal**: Fix root cause, minimal changes, test PASS

**Actions**:
1. Nếu fix đơn giản -> implement trực tiếp
2. Nếu fix cần thiết kế (multiple components, architectural change) -> launch **code-architect** agent thiết kế fix approach, present cho user approve trước khi implement
3. Implement fix — follow codebase conventions
4. Run test từ Phase 4 -> confirm PASS (GREEN)
5. Run full test suite -> confirm không break existing tests

---

## Phase 6: Review & Commit

**Goal**: Đảm bảo fix correct, không introduce regressions

**Actions**:
1. Launch 2 **code-reviewer** agents song song:
   - Agent 1: Verify fix correctness — logic đúng, edge cases covered, root cause thực sự resolved
   - Agent 2: Check regression risk — changes có ảnh hưởng flows khác không, side effects, performance
2. Nếu changes có database code -> launch thêm **db-engineer** agent review
3. Consolidate findings, chỉ giữ issues confidence >= 80% — threshold này lọc false positives mà vẫn bắt real issues
4. Present cho user: fix summary, review findings, files changed
5. **Hỏi user**: proceed to commit, hay adjust fix?
6. Commit với `/commit` skill: `fix(<scope>): <mô tả bug fix>`

---

## Examples

**Example 1: Logic bug đơn giản**
User says: "Tổng tiền đơn hàng tính sai khi có discount"
Actions:
1. Understand: discount 10% nhưng tổng tiền không giảm
2. Investigate: code-explorer trace calculation -> OrderService.CalculateTotal() line 45 apply discount sau tax thay vì trước
3. Hypothesis: discount applied sai thứ tự, confirm với code evidence
4. RED: test `CalculateTotal_Should_ApplyDiscountBeforeTax` -> FAIL
5. GREEN: fix thứ tự calculation -> test PASS
6. Review: 2 agents confirm fix, no regression
Result: Bug fixed, regression test added, 1 file changed

**Example 2: Intermittent bug phức tạp**
User says: "API đôi khi trả 500 nhưng không phải lúc nào cũng lỗi"
Actions:
1. Understand: 500 random, không có pattern rõ ràng
2. Investigate: code-explorer trace -> async service call không await properly, race condition
3. Hypothesis: 2 possible causes — race condition (80% confidence) vs null data (40% confidence). Present cho user -> chọn investigate race condition
4. RED: test concurrent access scenario -> FAIL
5. GREEN: fix async/await pattern -> test stable PASS
6. Review: confirm thread safety
Result: Race condition fixed, concurrency test added

**Example 3: Bug cần discussion**
User says: "Export CSV bị lỗi encoding tiếng Việt"
Actions:
1. Understand: CSV export hiển thị ký tự lạ thay vì tiếng Việt
2. Investigate: encoding set UTF-8 nhưng BOM missing, Excel interpret sai
3. Hypothesis: root cause rõ nhưng fix approach cần user input — thêm BOM (đơn giản, có thể ảnh hưởng non-Excel consumers) vs detect client (phức tạp hơn). Hỏi user chọn
4. User chọn thêm BOM -> RED -> GREEN -> Review
Result: Encoding fixed, user-informed decision

## Troubleshooting

**Không reproduce được bug**: Hỏi user chi tiết hơn — exact data, exact steps, environment. Check git log cho recent changes
**Root cause không rõ**: Dùng binary search trên git history (`git bisect`), thêm logging tạm, narrow down scope
**Test PASS trước khi fix**: Test chưa capture đúng bug — review test conditions, có thể cần specific data hoặc specific state
**Fix break existing tests**: Rollback fix, review impacted tests — tests fail vì behavior thay đổi hay vì fix chưa đúng?
**Bug ở code không thuộc team**: Document root cause, workaround trong code mình, tạo JIRA ticket cho team sở hữu code đó
