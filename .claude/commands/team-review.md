---
description: "Team Review — multi-perspective code review song song (security, performance, conventions) + test coverage analysis"
argument-hint: <scope cần review — mặc định git diff unstaged>
---

# Team Review — Code Review đa góc nhìn

Spawn team gồm 3 code-reviewer agents (security, performance, conventions) + 1 test-engineer phân tích test coverage, review song song và tổng hợp quality report.

**Yêu cầu**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## Context

Scope review: $ARGUMENTS

Nếu không chỉ định scope, mặc định review `git diff` (unstaged changes).

---

## Quy trình

### Step 1: Determine Scope

1. Nếu user chỉ định scope cụ thể (file paths, PR number, branch) → dùng scope đó
2. Nếu không → `git diff --stat` xác định files changed
3. Nếu scope là PR → `git diff main...HEAD --stat`

Tạo team `review-<short-scope>`.

### Step 2: Spawn 4 Reviewers song song

Tạo 4 tasks song song (no dependencies lẫn nhau):

| Task | Assignee | Agent Type |
|------|----------|------------|
| `review-security` | Điêu Thuyền (dieu-thuyen) | `code-reviewer` |
| `review-performance` | Hoàng Trung (hoang-trung) | `code-reviewer` |
| `review-conventions` | Tuân Du (tuan-du) | `code-reviewer` |
| `analyze-test-coverage` | Tư Mã Ý (tu-ma-y) | `test-engineer` |

Spawn cùng lúc:

**Điêu Thuyền** — Security Review:
> Review [scope] focus SECURITY. Bạn là Điêu Thuyền — Security Expert.
>
> **Check**:
> - OWASP Top 10: injection (SQL, NoSQL, OS command, LDAP), XSS, CSRF
> - Authentication/authorization bypass, broken access control
> - Sensitive data exposure (credentials, PII, tokens in logs/responses)
> - Insecure deserialization, XML external entities
> - Security misconfiguration, missing security headers
> - Dependency vulnerabilities nếu có package changes
>
> **Confidence scoring**: Rate mỗi issue 0-100. Chỉ report issues confidence >= 80.
>
> **Output format** cho mỗi issue:
> - Severity: Critical / Important
> - Confidence: [80-100]
> - Location: file:line
> - Description: mô tả vulnerability
> - Impact: nếu exploit thì ảnh hưởng gì
> - Fix: gợi ý cụ thể

**Hoàng Trung** — Performance Review:
> Review [scope] focus PERFORMANCE. Bạn là Hoàng Trung — Performance Expert.
>
> **Check**:
> - N+1 query problems — loop gọi DB thay vì batch
> - Deadlock possibilities — lock ordering, transaction scope
> - Memory leaks — event listeners không unsubscribe, growing collections
> - Inefficient algorithms — O(n²) khi có thể O(n), unnecessary iterations
> - Missing caching opportunities
> - Unnecessary database round-trips, large payloads without pagination
> - Async/await misuse — blocking calls, missing cancellation tokens
> - Connection pool exhaustion — connections không dispose
>
> **Confidence scoring**: Rate 0-100. Chỉ report confidence >= 80.
>
> **Output**: Severity, confidence, file:line, description, performance impact estimate, fix suggestion.

**Tuân Du** — Conventions & Code Quality Review:
> Review [scope] focus CONVENTIONS và CODE QUALITY. Bạn là Tuân Du — Conventions Expert.
>
> **Check**:
> - Project guidelines compliance (CLAUDE.md rules nếu có)
> - Naming conventions consistency
> - Import/dependency patterns
> - Error handling patterns — missing catches, swallowed exceptions
> - Code duplication — DRY violations
> - SOLID principle violations
> - Design pattern misuse
> - Inconsistent style với codebase hiện có
> - Accessibility issues (nếu frontend)
>
> **Confidence scoring**: Rate 0-100. Chỉ report confidence >= 80.
>
> **Output**: Severity, confidence, file:line, description, convention/guideline reference, fix suggestion.

**Tư Mã Ý** — Test Coverage Analysis:
> Phân tích test coverage cho [scope]. Bạn là Tư Mã Ý — Test Expert.
>
> **Check**:
> - Có unit tests cover code changes không?
> - Integration tests cần thiết cho interactions mới?
> - Edge cases chưa covered trong tests?
> - Test quality: assertions đủ strong? Test names descriptive?
> - Test patterns: consistent với project conventions?
> - Missing negative tests (error paths, invalid inputs)
>
> **Output**: Danh sách test coverage gaps với priority, description, suggested test cases.

### Step 3: Consolidate Report

Tạo task `consolidate-report` (depends on tất cả 4 review tasks).

Lead (Tào Tháo) tổng hợp:

1. **Deduplicate** — 2+ reviewers flag cùng issue → merge thành 1, lấy confidence cao nhất hoặc average + boost
2. **Sort theo severity**: Critical > Important > Performance > Convention
3. **Filter**: chỉ giữ issues confidence >= 80
4. **Enrich**: thêm cross-references nếu issues liên quan nhau

### Step 4: Present Report và Shutdown

Present cho user, sau đó shutdown team.

---

## Output — Review Report

```markdown
## Review Report: [Scope]

### Summary
- 🔴 Critical: X issues
- 🟠 Important: X issues
- 🟡 Performance: X issues
- 🔵 Convention: X issues
- 📋 Test coverage gaps: X

### Critical Issues
| # | Confidence | Location | Reviewer | Description | Fix |
|---|-----------|----------|----------|-------------|-----|

### Important Issues
| # | Confidence | Location | Reviewer | Description | Fix |
|---|-----------|----------|----------|-------------|-----|

### Performance Issues
| # | Confidence | Location | Reviewer | Description | Fix |
|---|-----------|----------|----------|-------------|-----|

### Convention Issues
| # | Confidence | Location | Reviewer | Description | Fix |
|---|-----------|----------|----------|-------------|-----|

### Test Coverage Gaps
| # | Priority | Description | Suggested Test |
|---|----------|-------------|---------------|

### Overall Assessment
[Clean / Needs attention / Significant issues]
[Recommendation: proceed as-is / fix critical first / needs rework]
```

---

## Coordination Rules

- **Tất cả agents READ-ONLY** — không edit bất kỳ file nào
- Mỗi reviewer focus vào domain riêng, tránh overlap
- Confidence scoring là bắt buộc — ngăn false positives
- Lead deduplicate objective, không favor reviewer nào
- Nếu 0 issues confidence >= 80 → report "Clean" với brief positive summary

## Examples

**Example 1: Review git diff**
```
/team-review
```
→ 4 reviewers check unstaged changes → 2 important issues (missing null check, N+1 query), 1 test gap → report

**Example 2: Review specific files**
```
/team-review src/Services/OrderService.cs src/Controllers/OrderController.cs
```
→ Focused review trên 2 files → security review clean, 1 performance issue → report

**Example 3: Review PR branch**
```
/team-review PR changes on branch feat/export-revenue
```
→ `git diff main...feat/export-revenue` → full review → report

## Troubleshooting

- **Scope quá lớn (>50 files)**: Suggest user narrow scope, hoặc chia thành nhiều reviews
- **Reviewer không tìm thấy issues**: Có thể code clean — report "Clean"
- **Quá nhiều false positives**: Tăng threshold lên 90 cho session này
- **CLAUDE.md không có**: reviewer-conventions skip project-specific rules, focus general best practices
