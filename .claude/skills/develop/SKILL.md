---
name: develop
description: >-
  Guided feature development theo TDD workflow — explore codebase, design architecture,
  write tests first (RED), implement (GREEN), refactor, review, commit. Dùng khi user
  muốn phát triển feature, implement JIRA ticket, hoặc build tính năng mới end-to-end.
  Trigger: "develop feature", "implement ticket", "build feature", "làm task",
  "phát triển feature", "code feature mới", "TDD". Do NOT use for standalone code review
  (use review), standalone testing (use test), standalone refactoring (use refactor),
  chỉ commit (use commit), hoặc bugs cần deep investigation/unknown root cause (use fix-bug).
argument-hint: Mô tả feature cần phát triển
---

# Feature Development — TDD Workflow

Phát triển feature mới theo TDD workflow có hệ thống.

## Core Principles

- **Hỏi trước khi làm** — tránh rework tốn kém từ assumptions sai. Xác định ambiguities, edge cases. Đợi user trả lời trước khi tiếp
- **Hiểu trước khi code** — đảm bảo consistency với patterns hiện có, tránh reinvent hoặc conflict. Đọc code patterns trước
- **TDD** — viết tests trước khi implement giúp lock expected behavior, tránh implement drift và regression
- **Đọc files từ agents** — agent summaries có thể miss details, reading source code là authoritative
- **Dùng TodoWrite** — structured tracking persist across agent steps, giúp user theo dõi tiến độ

---

## Phase 1: Discovery

**Goal**: Hiểu cần build cái gì

Initial request: $ARGUMENTS

**Actions**:
1. Tạo todo list với tất cả phases
2. Nếu có JIRA ticket ID → dùng Atlassian MCP lấy ticket details
3. Nếu chưa rõ → hỏi user: vấn đề gì, feature làm gì, constraints
4. Nếu ticket là Epic/Story và chưa có sub-tasks → suggest user chạy `/jira-sync {TICKET-ID}` để decompose thành [AI] sub-tasks trước khi bắt đầu
5. Tóm tắt understanding, confirm với user

---

## Phase 2: Create Branch

**Goal**: Tạo feature branch theo convention `[type]/[TICKET-ID]-[description]`

**Actions**:
1. Kiểm tra branch hiện tại — nếu đã ở feature branch → skip
2. Hỏi JIRA ticket ID nếu chưa biết
3. Tạo branch: `feat/PROJ-123-short-description`, `fix/PROJ-456-bug-name`
4. Confirm với user

### JIRA Progress Reporting

Sau mỗi phase completion, nếu có JIRA ticket ID:
1. Dùng `addCommentToJiraIssue` thêm progress note format:
   `**Phase {N}: {name}** — {status}. {1-2 sentence summary}. Files: {count}. Tests: {pass/fail}.`
2. Transition status khi phù hợp: Phase 5 done → "In Progress", Phase 9 done → "In Review", Phase 10 done → "Done"

---

## Phase 3: Codebase Exploration

**Goal**: Hiểu code hiện có và patterns

**Actions**:
1. Launch 2-3 **code-explorer** agents song song — target aspects khác nhau (similar features, architecture, test patterns)
2. Nếu feature liên quan database (schema changes, stored procedures, migrations, CDC) → launch thêm **db-engineer** agent phân tích schema hiện có và database patterns
3. Dùng Context7 MCP tra cứu library docs nếu cần
4. Đọc tất cả files agents xác định
5. Present tóm tắt findings

---

## Phase 4: Clarifying Questions

**Goal**: Resolve mọi ambiguities trước khi design

**Actions**:
1. Xác định aspects chưa rõ: edge cases, error handling, integration points, performance
2. Present tất cả câu hỏi cho user dạng organized list
3. **Đợi user trả lời trước khi tiếp tục**

Nếu user nói "tuỳ bạn" → đưa recommendation cụ thể, xin explicit confirmation.

---

## Phase 5: Architecture Design

**Goal**: Thiết kế architecture với trade-offs

**Actions**:
1. Nếu task có UI → đọc `references/figma-workflow.md`, hỏi user Figma link, phân tích design trước khi architect
2. Launch 2-3 **code-architect** agents với focuses khác nhau (minimal, clean, pragmatic)
3. Nếu task có database schema design hoặc performance-critical queries → launch thêm **db-engineer** agent thiết kế database architecture (schema, indexes, stored procedures) với `sqlserver-expert` references
4. Mỗi architect include Test Strategy cho TDD
5. Present approaches, trade-offs, **recommendation với reasoning**
6. **Hỏi user chọn approach**

---

## Phase 6: Write Tests First (RED)

**Goal**: TDD Red phase — viết tests trước implement

Đợi user approve architecture trước.

**Actions**:
1. Viết tests dựa trên Test Strategy từ architect
2. Cover: happy path, edge cases, error handling
3. Add `// @trace {module}/{feature}/{UC-ID}/{AC-ID}` comments to test files — propagate from .feature files nếu có
4. Run tests → confirm tất cả FAIL (RED)

---

## Phase 7: Implement (GREEN)

**Goal**: Implement đúng đủ để tests PASS

**Actions**:
1. Follow codebase conventions — inconsistent style tạo cognitive overhead cho reviewers và tăng merge conflicts
2. Implement theo chosen architecture
3. Add `/// @trace {module}/{feature}/{UC-ID}` doc comments to source code classes/methods
4. Run tests → confirm PASS (GREEN)

---

## Phase 8: Refactor

**Goal**: Cải thiện code quality, giữ nguyên behavior

**Actions**:
1. Review code vừa implement — có code smells không? (duplication, long methods, tight coupling)
2. Nếu cần → launch **code-refactorer** agent với context: files changed, smells identified, test baseline
3. Verify tests vẫn GREEN sau refactor
4. Nếu code đã clean → skip

---

## Phase 9: Quality Review

**Goal**: Đảm bảo code correct, secure, clean

**Actions**:
1. Launch 3-4 **code-reviewer** agents: simplicity/DRY, bugs/security, conventions, logic
2. Consolidate findings, chỉ giữ issues confidence >= 80 — threshold này lọc false positives mà vẫn bắt real issues, tránh noise cho user
3. Present cho user, hỏi: fix ngay, fix sau, hoặc proceed

---

## Phase 10: Commit & Summary

**Goal**: Commit và document kết quả

**Actions**:
1. Update docs nếu cần (README, API docs, inline comments)
2. Stage files, commit theo Conventional Commits: `<type>(<scope>): <subject>`
3. Nếu có JIRA ticket → dùng `transitionJiraIssue` chuyển sang Done + add final summary comment
4. Tóm tắt: feature built, key decisions, files modified, test coverage, next steps

---

## References

- Figma design workflow (khi task có UI): xem `references/figma-workflow.md`

## Examples

**Example 1: Feature mới**
User says: "Develop export báo cáo doanh thu ra Excel"
Actions:
1. Discovery: clarify format, filters, date range
2. Branch: `feat/PROJ-123-export-revenue`
3. Explore: tìm existing export patterns, Excel library
4. Architect: recommend approach + test strategy
5. RED: viết tests cho happy path + edge cases
6. GREEN: implement ExportService
7. Review: 3 agents check quality
8. Commit: `feat(report): add revenue export to Excel`
Result: Feature complete với tests, reviewed, committed

**Example 2: Bug fix từ JIRA**
User says: "Implement KV-456 — fix tính sai tổng tiền"
Actions:
1. JIRA: lấy ticket details, steps to reproduce
2. Branch: `fix/KV-456-wrong-total`
3. Explore: trace calculation logic
4. RED: test reproduce bug
5. GREEN: fix root cause
6. Commit: `fix(order): correct total calculation with discount`
Result: Bug fixed với regression test

## Troubleshooting

**Tests không chạy**: Kiểm tra test framework setup, chạy `dotnet restore` / `npm install`
**Branch đã tồn tại**: Hỏi user checkout existing hay tạo tên mới
**Agent kết quả không liên quan**: Cung cấp context cụ thể hơn — file paths, function names
