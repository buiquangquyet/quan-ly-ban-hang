---
name: document
description: >-
  Update documentation cho repo — README, architecture docs, onboarding guide, ADR,
  inline comments cho complex logic. Dùng khi user muốn document changes, update docs, hoặc
  keep docs in sync với code. Trigger: "update docs", "document this", "viết docs",
  "cập nhật README", "viết onboarding guide", "architecture doc", "docs outdated",
  "viết ADR". Do NOT use for API docs (dùng Swagger/auto-generated), changelogs,
  writing code comments during active development, hoặc user-facing help articles.
argument-hint: "Scope cần document (mặc định: recent changes)"
---

# Document — Update Documentation

Update documentation cho repo — docs outdated gây onboarding delays và incorrect assumptions về system behavior. Đảm bảo docs in sync với code changes.

## Principles

- **Write for the reader** — Ai đang đọc và họ cần gì?
- **Start with the most useful information** — Đừng chôn thông tin quan trọng
- **Show, don't tell** — Code examples, commands, screenshots
- **Keep it current** — Docs outdated tệ hơn không có docs
- **Link, don't duplicate** — Reference docs khác thay vì copy

## References

- Templates cho từng loại: xem `references/documentation-templates.md`

---

## Bước 1: Xác định Scope

Từ $ARGUMENTS hoặc recent changes, xác định cần document gì.

**Actions**:
1. Kiểm tra recent changes: `git diff --name-only`, `git log --oneline -5`
2. Xác định loại doc:

| Loại | Khi nào | Reader |
|------|---------|--------|
| README | New feature, setup/config changes | Developer mới join |
| Architecture doc | Structural changes, new services | Developer cần hiểu system |
| Onboarding guide | Project setup phức tạp, nhiều steps | Developer ngày đầu |
| ADR | Key technical decisions | Developer cần hiểu WHY |
| Inline comments | Complex logic, non-obvious decisions | Developer đọc code |

---

## Bước 2: Explore & Write

**Actions**:
1. Launch **code-explorer** agent hiểu changes
2. Đọc `references/documentation-templates.md` — chọn template phù hợp
3. Đọc docs hiện tại để match style
4. Viết/update theo principles:
   - **Reader first**: xác định ai đọc → viết cho họ
   - **Lede first**: thông tin quan trọng nhất ở đầu
   - **Show**: include runnable commands, code examples
   - **Link**: reference existing docs thay vì copy content
   - **No redundancy**: skip comments cho self-explanatory code

---

## Bước 3: Review & Present

1. Present tóm tắt: files updated, nội dung chính
2. Hỏi user cần adjust không

---

## Examples

**Example 1: Document new API**
User says: "document the new payment endpoints"
Actions:
1. Explore: PaymentController, routes, DTOs
2. Xác định reader: API consumer (frontend team)
3. Viết: endpoint doc (method, path, request/response example, error codes)
4. Present → user adjusts → done
Result: API doc focused on consumer needs

**Example 2: Update README**
User says: "cập nhật README với feature export mới"
Actions:
1. Explore: ExportService, recent commits
2. Reader: developer mới join
3. Thêm feature description + usage example vào README
Result: README reflects current capabilities

**Example 3: Onboarding guide**
User says: "viết onboarding guide"
→ Explore setup flow → viết step-by-step với commands copy-paste được → reader = developer ngày đầu

## Troubleshooting

**Không biết update docs ở đâu**
Cause: Repo có nhiều nơi đặt docs
Solution: README cho overview, docs/ cho chi tiết, inline cho complex logic

**Changes quá nhiều**
Cause: Large PR với nhiều file changes
Solution: Focus user-facing changes trước, internal chỉ nếu architecture thay đổi significant
