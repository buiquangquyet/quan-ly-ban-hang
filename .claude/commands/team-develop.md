---
description: "Team Develop — full build cycle: architect → implement/fix → autotest → review → document, phased activation"
argument-hint: <feature/task cần build, kèm blueprint hoặc JIRA ticket nếu có>
---

# Team Develop — Full Build Cycle

Orchestrate toàn bộ build pipeline: **Architect → Implement/Fix → AutoTest → Review → Document**. Team lớn nhất, dùng phased activation — chỉ spawn agents khi phase cần.

**Yêu cầu**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## Context

$ARGUMENTS

---

## Quy trình

### Phase A: Architect / Tech Design

**Goal**: Explore codebase → thiết kế architecture → user approve trước khi code.

#### Step A1: Explore Codebase

Tạo team `develop-<short-context>`.

Spawn **Quan Vũ** (agent type: `code-explorer`):
> Khám phá codebase liên quan tới [context]. Bạn là Quan Vũ — Technical Expert.
>
> **Tìm**:
> - Existing patterns, conventions, project structure
> - Similar features đã implement — approach, file structure
> - Test infrastructure: framework, patterns, naming conventions
> - CLAUDE.md guidelines nếu có
> - Database schema nếu liên quan
>
> **Report**: architecture layers, key files với file:line, patterns found, test infrastructure summary.

#### Step A2: Design Architecture

Đợi Quan Vũ xong. Spawn 2 **code-architect** agents song song:

**Bàng Thống** (architect-pragmatic):
> Thiết kế solution cho [context] với approach PRAGMATIC. Bạn là Bàng Thống — Pragmatic Architect. Bạn nhận context từ Quan Vũ.
>
> **Focus**: Balance giữa clean code và delivery speed. Tận dụng tối đa code hiện có, minimize files mới, ship nhanh.
>
> **Deliver**: Component design (file paths, responsibilities), API contracts, data flow, test strategy cho TDD, build sequence, estimated complexity.

**Lỗ Túc** (architect-robust):
> Thiết kế solution cho [context] với approach ROBUST. Bạn là Lỗ Túc — Robust Architect. Bạn nhận context từ Quan Vũ.
>
> **Focus**: Maintainability, extensibility, edge case handling. SOLID principles, clear abstractions, comprehensive error handling.
>
> **Deliver**: Component design (file paths, responsibilities), API contracts, data flow, test strategy cho TDD, build sequence, estimated complexity.

#### Step A3: Choose Architecture

Lead tổng hợp 2 approaches:

| Tiêu chí | Pragmatic | Robust |
|-----------|-----------|--------|
| Complexity (files) | | |
| Maintainability | | |
| Performance | | |
| Risk level | | |
| Pattern alignment | | |
| Testability | | |

Đề xuất recommendation với rationale. **Hỏi user approve architecture** trước khi implement.

Tasks Phase A:
- `explore-codebase` (no deps) → Quan Vũ
- `design-pragmatic` (dep: explore-codebase) → Bàng Thống
- `design-robust` (dep: explore-codebase) → Lỗ Túc
- `choose-architecture` (dep: design-pragmatic, design-robust) → Tào Tháo (lead)

**JIRA Update** (nếu có ticket ID): Lead dùng `addCommentToJiraIssue` report phase completion summary.

---

### Phase B: Implement + AutoTest

**Goal**: TDD — viết tests trước (RED), implement cho PASS (GREEN), generate automation tests nếu có feature files.

#### Step B1: Write Tests (RED)

Spawn **Tư Mã Ý** (agent type: `test-engineer`):
> Viết tests cho [context] theo approved architecture. Bạn là Tư Mã Ý — Test Expert.
>
> **Actions**:
> - Viết unit tests cho business logic dựa trên Test Strategy từ architect
> - Cover: happy path, edge cases, error handling
> - Follow test conventions tìm được từ exploration
> - Run tests → confirm tất cả FAIL (RED)
>
> Nếu có `.feature` files liên quan:
> - Đọc `${CLAUDE_PLUGIN_ROOT}/skills/generate-steps/references/api-step-patterns.md` (cho @api)
> - Đọc `${CLAUDE_PLUGIN_ROOT}/skills/generate-steps/references/e2e-step-patterns.md` (cho @web)
> - Generate step definitions, API Clients, Page Objects theo `generate-steps` skill
>
> **KHÔNG edit implementation files** — chỉ test files.

#### Step B2: Implement (GREEN)

Spawn **code-engineer** agent(s):

**Nếu scope vừa (1 engineer đủ):**

**Triệu Vân** (engineer-1):
> Implement [context] theo approved blueprint. Bạn là Triệu Vân — Code Engineer. Đọc test files TRƯỚC để hiểu expected behavior.
>
> - Follow codebase conventions
> - Implement đúng đủ cho tests PASS (GREEN)
> - **KHÔNG edit test files**
>
> Files assigned: [lead specify non-overlapping file list]

**Nếu scope lớn (cần 2 engineers — components độc lập):**
Spawn 2 code-engineer agents, mỗi agent nhận file set KHÔNG OVERLAP:
- **Triệu Vân** (engineer-1): implement [component A] — files: [list cụ thể]
- **Trương Phi** (engineer-2): implement [component B] — files: [list cụ thể]

#### Step B3: Verify GREEN

Sau khi engineers hoàn thành:
1. Run full test suite
2. GREEN → proceed to Phase C
3. RED → gửi message cho engineer fix, hoặc lead fix trực tiếp

Tasks Phase B:
- `write-tests` (dep: choose-architecture) → Tư Mã Ý
- `generate-automation-tests` (dep: choose-architecture, optional) → Tư Mã Ý
- `implement-core` (dep: write-tests) → Triệu Vân
- `implement-secondary` (dep: write-tests, optional) → Trương Phi
- `verify-green` (dep: implement-core, implement-secondary) → Tào Tháo (lead)

**JIRA Update** (nếu có ticket ID): Lead dùng `addCommentToJiraIssue` report phase completion summary.

---

### Phase C: Review

**Goal**: Multi-perspective code review, chỉ report issues confidence >= 80.

#### Step C1: Parallel Review

Spawn 2-3 **code-reviewer** agents song song:

**Tuân Du** (reviewer-quality, agent type: `code-reviewer`):
> Review code changes focus QUALITY. Bạn là Tuân Du — Quality Expert. Check: bugs, logic errors, code smells, DRY violations, missing error handling, null safety. Chỉ report issues confidence >= 80. Format: severity, confidence, file:line, description, suggested fix.

**Hoàng Trung** (reviewer-performance, agent type: `code-reviewer`):
> Review code changes focus PERFORMANCE. Bạn là Hoàng Trung — Performance Expert. Check: N+1 queries, deadlock possibilities, memory leaks, O(n²) khi có thể O(n), missing caching, unnecessary DB round-trips, large payloads without pagination, connection pool issues. Chỉ report issues confidence >= 80.

**Điêu Thuyền** (reviewer-security, agent type: `code-reviewer`, optional — chỉ spawn nếu feature security-sensitive):
> Review code changes focus SECURITY. Bạn là Điêu Thuyền — Security Expert. Check: OWASP Top 10, injection, XSS/CSRF, auth bypass, sensitive data exposure, insecure deserialization. Chỉ report issues confidence >= 80.

#### Step C2: Consolidate Review

Lead tổng hợp:
1. Deduplicate issues (2+ reviewers flag cùng issue → merge, boost confidence)
2. Sort: Critical > Important > Performance
3. Chỉ giữ confidence >= 80
4. Present cho user: **hỏi fix ngay, fix sau, hoặc proceed**

Nếu user muốn fix → lead hoặc engineer fix, re-run tests verify GREEN.

Tasks Phase C:
- `review-quality` (dep: verify-green) → Tuân Du
- `review-performance` (dep: verify-green) → Hoàng Trung
- `review-security` (dep: verify-green, optional) → Điêu Thuyền
- `consolidate-review` (dep: all reviews) → Tào Tháo (lead)

**JIRA Update** (nếu có ticket ID): Lead dùng `addCommentToJiraIssue` report phase completion summary.

---

### Phase D: Document + Commit

**Goal**: Update docs nếu cần, commit theo Conventional Commits.

#### Step D1: Update Documentation (optional)

Nếu changes cần documentation update (new feature, API changes, config changes):

Spawn **Trần Thọ** (doc-writer, agent type: `code-engineer`):
> Update documentation cho [context]. Bạn là Trần Thọ — Documentation Expert. Check và update nếu cần:
> - README.md — new features, setup changes
> - API documentation — endpoint changes, new DTOs
> - Inline comments — complex logic cần giải thích
> - CHANGELOG — nếu project maintain
>
> **CHỈ edit documentation files**, KHÔNG edit source code hay test files.

#### Step D2: Commit & Summary

1. Stage relevant files
2. Commit theo Conventional Commits: `<type>(<scope>): <subject>`
3. Tóm tắt cho user:

```
## Build Report: [Context]

### Architecture Decision
- Approach: [pragmatic/robust]
- Rationale: [tại sao]

### Files Changed
- [file path] — [mô tả]

### Test Results
- Total: X tests, Passed: X (GREEN)
- Coverage: [areas]

### Review Findings
- Critical: X, Important: X, Performance: X
- [Summary of significant findings]

### Documentation Updated
- [files updated]

### Commit
- [commit hash] [commit message]
```

Tasks Phase D:
- `update-docs` (dep: consolidate-review, optional) → Trần Thọ
- `commit-and-summary` (dep: update-docs) → Tào Tháo (lead)

**JIRA Update** (nếu có ticket ID): Lead dùng `addCommentToJiraIssue` report phase completion summary.

**JIRA Final**: Lead dùng `transitionJiraIssue` chuyển tất cả [AI] subtasks sang Done + add final build report as comment.

---

## File Conflict Prevention

| Phase | Agent | Allowed Files |
|-------|-------|---------------|
| A | Quan Vũ, Bàng Thống, Lỗ Túc | READ-ONLY |
| B | Tư Mã Ý | Test files only |
| B | Triệu Vân, Trương Phi | Implementation files only (assigned set) |
| C | Tuân Du, Hoàng Trung, Điêu Thuyền | READ-ONLY |
| D | Trần Thọ | Documentation files only |

**Rule**: KHÔNG có 2 agents edit cùng 1 file cùng lúc. Lead assign file boundaries rõ ràng.

## Coordination Rules

- Phased activation — chỉ spawn agents khi phase cần, shutdown sau mỗi phase
- **User gates**: approve architecture (Phase A), approve review findings (Phase C)
- Engineers PHẢI đọc test files trước khi implement (hiểu expected behavior)
- Lead verify GREEN sau mỗi implementation/fix
- Nếu task có JIRA ticket → dùng Atlassian MCP lấy details trước

## Examples

**Example 1: Feature mới**
```
/team-develop Implement export báo cáo doanh thu ra Excel — JIRA KV-789
```
→ Phase A: explore + 2 architectures → user chọn pragmatic
→ Phase B: Tư Mã Ý viết 12 tests (RED) → engineer implement ExportService (GREEN)
→ Phase C: 2 reviewers, 1 performance issue found (N+1 query) → fix
→ Phase D: update API docs, commit `feat(report): add revenue export to Excel`

**Example 2: Fix bug + regression test**
```
/team-develop Fix tính sai tổng tiền khi có nhiều discount — KV-456
```
→ Phase A: explore → architect minimal fix
→ Phase B: Tư Mã Ý viết test reproduce bug (RED) → engineer fix (GREEN)
→ Phase C: review → clean
→ Phase D: commit `fix(order): correct total calculation with multiple discounts`

## Troubleshooting

- **Tests không chạy**: Check framework setup, `dotnet restore` / `npm install`
- **File conflict giữa agents**: Lead re-assign file boundaries, hoặc serialize thành sequential
- **Architecture cả 2 approaches đều phức tạp**: Hỏi user giảm scope, chia nhỏ task
- **Review quá nhiều issues**: Focus fix Critical trước, defer Important cho follow-up
