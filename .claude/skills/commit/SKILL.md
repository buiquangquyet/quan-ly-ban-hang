---
name: commit
description: >-
  Commit code theo Conventional Commits specification — phân tích changes, tạo commit message
  chuẩn, chạy pre-commit checks. Dùng khi user muốn commit, save changes, hoặc finalize work.
  Trigger: "commit", "git commit", "tạo commit", "commit changes", "save my work",
  "commit những thay đổi này", "done, commit". Do NOT use for pushing to remote,
  creating pull requests, hoặc branch management.
argument-hint: "Message bổ sung (optional)"
---

# Commit — Conventional Commits

Commit code changes theo Conventional Commits specification.

## References

- Format, types, examples: xem `references/git-conventions.md`

## Quy trình

### Bước 1: Phân tích Changes

**Actions**:
1. Chạy song song: `git status`, `git diff`, `git diff --staged`, `git log --oneline -10`
2. Đọc `references/git-conventions.md` để lấy commit format
3. Phân tích: feature mới, bug fix, refactoring? Scope nào bị ảnh hưởng? Có file sensitive không?

### Bước 2: Tạo Commit Message

Theo format trong `references/git-conventions.md`: `<type>(<scope>): <subject>`

### Bước 3: Stage & Commit

**Actions**:
1. Stage files cụ thể — tránh `git add -A` vì có thể commit nhầm unrelated/sensitive files
2. Không stage .env, credentials, secrets — committing secrets là security risk và rất khó purge hoàn toàn khỏi git history
3. Chạy pre-commit checks — fix issues thay vì bypass bằng `--no-verify`, vì bypassing ẩn lint/format/test issues mà sẽ fail ở CI sau
4. Present commit message cho user review
5. Commit sau khi user confirm
6. `git status` verify thành công

**Lưu ý**: Không push tự động — user có thể muốn review, squash, hoặc amend trước khi push. Không amend commit trước đó trừ khi user yêu cầu.

---

## Examples

**Example 1: Feature commit**
User says: "commit my changes"
Actions:
1. `git status` → 3 files changed trong payment module
2. `git diff` → phân tích: thêm VNPay integration
3. Generate: `feat(payment): add VNPay payment gateway integration`
4. Present cho user → user approve → commit
Result: Clean commit với conventional format

**Example 2: Bug fix**
User says: "done, commit"
Actions:
1. Phân tích diff → null check thiếu trong order calculation
2. Generate: `fix(order): handle null discount in order calculation`
Result: Targeted fix commit

## Troubleshooting

**Nothing to commit**: `git status` kiểm tra, nhắc user save files
**Pre-commit fail**: Đọc error, fix issues cụ thể, stage lại và retry
