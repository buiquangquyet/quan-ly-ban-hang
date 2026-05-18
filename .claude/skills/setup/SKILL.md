---
name: setup
description: >-
  Setup CLAUDE.md cho project — tao moi hoac optimize CLAUDE.md theo best practices.
  Dung khi bat dau project moi, setup moi truong Claude Code, hoac can cai thien CLAUDE.md.
  Trigger: "setup project", "setup", "tao CLAUDE.md", "optimize CLAUDE.md",
  "init project", "cau hinh project", "khoi tao project", "bat dau project moi",
  "cai dat project", "moi clone project", "CLAUDE.md".
  Do NOT use for feature development (use develop), code review (use review),
  commit (use commit), investigate bugs (use fix-bug), hoac write feature files (use write-features).
argument-hint: "Mô tả project (mặc định: thư mục hiện tại)"
---

# Project Setup

Setup CLAUDE.md cho project: detect language stack → chọn template → tạo hoặc optimize CLAUDE.md theo best practices.

## Core Principles

- **User confirm trước khi write** — mỗi thay đổi file cần user approve vì CLAUDE.md ảnh hưởng toàn bộ workflow
- **Less Is More cho CLAUDE.md** — target dưới 60 dòng vì LLM quality giảm khi instruction tăng
- **Dùng TodoWrite** — structured tracking giúp user theo dõi tiến độ setup

## Instructions

### Step 1: Detect Project Stack

Dùng TodoWrite tạo todo list với tất cả steps.

Chạy detection script — deterministic, consistent hơn manual scan:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/setup/scripts/detect-stack.sh"
```

Script trả về JSON:
```json
{
  "languages": ["csharp", "typescript"],
  "submodules": ["services/api", "services/web"],
  "is_monorepo": true
}
```

Present kết quả cho user.

### Step 2: Hướng dẫn LSP (nếu chưa có)

Kiểm tra project đã có LSP config chưa (`.lsp.json` hoặc đã install LSP plugin).

Nếu chưa có → hướng dẫn user cài LSP qua official Anthropic plugins:

> **LSP Setup**: Claude Code hỗ trợ LSP qua plugin system. Để enable code intelligence cho project:
>
> 1. Xem danh sách official LSP plugins: https://code.claude.com/docs/en/discover-plugins
> 2. Install plugin trong Claude Code: `/plugin install <plugin-name>@claude-plugins-official`
> 3. Install binary tương ứng (xem hướng dẫn trong repo trên)
> 4. Restart Claude Code
>
> Ví dụ cho C#: `/plugin install csharp-lsp@claude-plugins-official`
> Ví dụ cho TypeScript: `/plugin install typescript-lsp@claude-plugins-official`

Nếu đã có → skip, tiếp tục Step 3.

### Step 3: Setup CLAUDE.md

**Nếu KHÔNG có CLAUDE.md:**

1. Select template từ `${CLAUDE_PLUGIN_ROOT}/templates/` theo detected stack:
   - C#/.NET → `dotnet-CLAUDE.md`
   - Angular → `angular-CLAUDE.md`
   - Dart/Flutter → `flutter-CLAUDE.md`
   - Khác → dùng generic structure từ `references/claude-md-guideline.md`

2. Explore codebase để thu thập thông tin cho CLAUDE.md — dùng Glob, Grep, Read tools:
   - Tìm build/test/run commands (Makefile, package.json scripts, *.csproj, Dockerfile)
   - Xác định project structure (top-level folders, entry points)
   - Phát hiện critical conventions SPECIFIC cho project (không phải best practices chung)
   - Check: CI config, test framework, existing patterns đặc biệt

3. Fill template với thông tin detected + explorer findings
4. Present draft cho user — **hỏi confirm** trước khi write
5. Gợi ý tạo `agent_docs/` nếu project có domain-specific knowledge cần document

**Nếu ĐÃ có CLAUDE.md:**

1. Đọc CLAUDE.md hiện tại
2. Đọc `references/claude-md-guideline.md` lấy 6 principles + checklist
3. Evaluate:
   - Đếm dòng (target dưới 60, hard limit 300)
   - Đếm instructions (target dưới 20)
   - Phát hiện noise: kiến thức chung LLM đã biết, coding conventions nên dùng linter
   - Kiểm tra progressive disclosure: có task-specific content nên tách ra `agent_docs/`?
   - Kiểm tra pointers: có code snippets nên thay bằng file references?
4. Present optimization suggestions với before/after examples cụ thể
5. **Hỏi user confirm** trước khi modify

### Step 4: Report

Tóm tắt:

```
## Setup Complete

### CLAUDE.md
- Status: [created / optimized / already good]
- Line count: [X lines]
- agent_docs/: [created / suggested / not needed]

### LSP
- Status: [already configured / hướng dẫn đã cung cấp]

### Next Steps
- Dùng `/develop` để bắt đầu phát triển
- Tạo agent_docs/ nếu project có domain knowledge phức tạp
```

## Examples

**Example 1: New .NET project**
User says: "setup project"
Actions: detect C# → hướng dẫn LSP (csharp-lsp plugin) → copy dotnet-CLAUDE.md template → explore project → fill → user confirms
Result: `CLAUDE.md` ~50 lines + LSP guidance

**Example 2: Existing Angular project với CLAUDE.md 200 dòng**
User says: "optimize CLAUDE.md"
Actions: detect TypeScript → LSP đã configured (skip) → evaluate CLAUDE.md → suggest: remove SOLID principles (LLM đã biết), extract vào `agent_docs/`, remove naming conventions (dùng ESLint)
Result: CLAUDE.md optimized 200 → 55 lines + `agent_docs/component-patterns.md`

**Example 3: Go project chưa có gì**
User says: "setup"
Actions: detect Go → hướng dẫn LSP (gopls-lsp plugin) → create CLAUDE.md từ generic template → explore project → fill
Result: `CLAUDE.md` ~40 lines

## References

- CLAUDE.md best practices, evaluation checklist: xem `references/claude-md-guideline.md`
- CLAUDE.md templates per stack: xem `${CLAUDE_PLUGIN_ROOT}/templates/`
- Official LSP plugins: https://code.claude.com/docs/en/discover-plugins

## Troubleshooting

**CLAUDE.md quá dài**: Suggest extract task-specific content vào `agent_docs/` với trigger conditions
**Submodule detection sai**: User override bằng cách chỉ định languages/paths cụ thể
**LSP không hoạt động**: Xem https://code.claude.com/docs/en/discover-plugins — đảm bảo binary có trong PATH
