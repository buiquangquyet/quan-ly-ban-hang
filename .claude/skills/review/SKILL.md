---
name: review
description: >-
  Review source code cho bugs, security vulnerabilities, performance issues (N+1, deadlock),
  conventions compliance, code quality với confidence-based filtering. Dùng khi user muốn
  review code changes, check PR, kiểm tra code quality. Trigger: "review code", "review PR",
  "kiểm tra code", "check changes", "code review", "review diff", "security review".
  Do NOT use for implementing fixes (use develop), refactoring (use refactor),
  hoặc writing tests (use test).
argument-hint: "Scope cần review (mặc định: unstaged changes)"
---

# Code Review

Review source code với confidence-based filtering — chỉ report issues thực sự quan trọng.

## References

- Universal review checklist: `references/review-checklist.md`
- Per-stack anti-patterns (đọc theo stack detected từ project):
  - .NET: `references/dotnet-review-patterns.md`
  - Angular: `references/angular-review-patterns.md`
  - Flutter: `references/flutter-review-patterns.md`
  - Thêm stack mới → tạo `references/{stack}-review-patterns.md`
- SQL Server performance patterns: `../sqlserver-expert/references/performance.md` (khi review database code)

## Scope

Từ $ARGUMENTS, xác định scope:
- Mặc định: unstaged changes (`git diff`)
- Có thể chỉ định: file cụ thể, PR, branch, commit range

---

## Bước 1: Thu thập context

**Actions**:
1. Xác định changes cần review (`git diff`, `git diff --staged`, hoặc branch diff)
2. Detect stack từ project (file extensions, framework config) → đọc per-stack reference tương ứng
3. Đọc CLAUDE.md hoặc project guidelines nếu có
4. Đọc `references/review-checklist.md`
5. Hiểu context: feature gì, tại sao thay đổi

---

## Bước 2: Launch Review Agents

Launch 3 **code-reviewer** agents song song — 3 agents giảm single-pass blind spots và cut wall-clock review time. Theo priority order:

1. **Security & Correctness**: Auth bypass, injection, XSS, data exposure, multi-tenant isolation, logic errors, edge cases, data integrity
2. **Performance & Architecture**: N+1 queries, deadlocks, memory leaks, resource leaks, SOLID violations, wrong layer, circular dependencies
3. **Quality & Testing**: DRY, naming, error handling, missing tests, project conventions từ CLAUDE.md

Nếu changes có SQL files (.sql), migration files, stored procedures, hoặc EF Core/Dapper changes đáng kể → launch thêm **db-engineer** agent review database-specific concerns (query performance, index coverage, deadlock potential, CDC correctness) với `sqlserver-expert` references.

Cung cấp cho agents: changes, per-stack reference (nếu có), review checklist.

---

## Bước 3: Consolidate & Present

**Actions**:
1. Gộp findings, chỉ giữ issues **confidence >= 80%**
2. Format mỗi issue:

```
[PREFIX] Brief issue description (file:line) — confidence: X%

Why: Explanation of the problem or risk
Fix: Suggested solution or alternative
```

| Prefix | Meaning | Action |
|--------|---------|--------|
| `[BLOCKING]` | Must fix before merge — bugs, security, data loss | Required |
| `[SUGGESTION]` | Improvement opportunity — performance, architecture | Optional |
| `[QUESTION]` | Need clarification — unclear intent, ambiguous logic | Response needed |
| `[NIT]` | Minor style issue — naming, formatting | Optional |

3. **Feedback principles**:
   - Explain *why* something is problematic, not just *what*
   - Point to exact lines with specific alternatives
   - Acknowledge good patterns when found
   - For large PRs: focus BLOCKING + SUGGESTION first, NITs later
4. **Hỏi user**: muốn fix issues nào?

---

## Bước 4: Fix Issues (nếu user chọn)

1. Fix theo thứ tự: BLOCKING → SUGGESTION → NIT
2. Run tests sau mỗi fix
3. Re-review nếu cần

---

## Examples

**Example 1: Review unstaged changes**
User says: "review code"
Actions:
1. `git diff` → 5 files changed trong .NET project
2. Detect stack → đọc `references/dotnet-review-patterns.md`
3. Launch 3 agents: security, performance, quality
4. Consolidate: [BLOCKING] SQL injection (file:42, 95%), [SUGGESTION] N+1 query (file:78, 85%)
5. Present findings → user chọn fix BLOCKING
Result: 1 blocking fixed, 1 suggestion logged

**Example 2: Review PR**
User says: "review PR #123"
Actions:
1. `git diff main...feature-branch` → detect Angular
2. Đọc angular-review-patterns + review-checklist
3. 3 agents review → findings consolidated
4. Present: 2 suggestions, 0 blocking
Result: PR approved với 2 optional improvements

## Troubleshooting

**Không có changes**: Hỏi user scope cụ thể (branch diff, commit range, files)
**Quá nhiều findings**: Filter confidence >= 80%, focus BLOCKING + SUGGESTION only
**Stack không có reference**: Dùng universal checklist, review theo general principles
