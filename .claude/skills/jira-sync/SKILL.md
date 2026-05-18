---
name: jira-sync
description: >-
  AI-driven JIRA project management — decompose epic thành [AI] sub-tasks, report progress per phase,
  transition status, update DoD checklist, query sprint. Dùng khi AI bắt đầu work trên JIRA ticket
  và cần tạo work breakdown, report tiến độ, hoặc sync status lên JIRA.
  Trigger: "sync jira", "tạo subtasks", "breakdown epic", "report progress", "jira update",
  "cập nhật jira", "decompose task". Do NOT use for reading JIRA ticket details only (skills tự đọc
  qua Atlassian MCP), hoặc tạo JIRA issues cho incidents (use respond-incident).
argument-hint: JIRA Epic/Story ID hoặc "progress" để report tiến độ
---

# JIRA Sync — AI Project Management

Quản lý tasks trên JIRA cho AI workflow. AI tạo tasks, report progress, con người review trên JIRA dashboard.

## Core Principles

- **[AI] prefix** — tất cả tasks AI tạo có prefix `[AI]` để distinguish với human tasks
- **Label `ai-generated`** — filter AI tasks trên JIRA board
- **Human-in-the-loop** — PO review tasks trước khi AI bắt đầu implement
- **Progress transparency** — mỗi phase completion → JIRA comment + status transition

---

## Bước 1: Detect Mode

$ARGUMENTS

Detect mode từ input:
- **JIRA ID** (e.g., KV-100, PROJ-200) → **DECOMPOSE MODE** — breakdown epic thành sub-tasks
- **"progress"** hoặc description of completed work → **PROGRESS MODE** — report progress lên existing ticket
- **"sprint"** hoặc "status" → **QUERY MODE** — query sprint progress

---

## Bước 2A: DECOMPOSE MODE — Epic → Sub-tasks

**Goal**: Breakdown epic/story thành [AI] sub-tasks trên JIRA

**Actions**:
1. Dùng Atlassian MCP lấy epic details: description, acceptance criteria, linked PRD, existing subtasks
2. Nếu có Confluence PRD link → đọc PRD content
3. Phân tích scope → tạo work breakdown:

   | # | Sub-task | Type | Depends On |
   |---|----------|------|------------|
   | 1 | `[AI] Design: {feature}` | Technical Design | — |
   | 2 | `[AI] BDD Scenarios: {feature}` | Test | — |
   | 3 | `[AI] Implement: {feature}` | Development | 1, 2 |
   | 4 | `[AI] Review: {feature}` | Review | 3 |

4. Present breakdown cho user review trước khi tạo trên JIRA
5. **Đợi user approve**

**Tạo JIRA sub-tasks**:
1. Dùng `createJiraIssue` cho mỗi sub-task:
   - Summary: `[AI] {phase}: {feature name}`
   - Description: acceptance criteria, scope, approach
   - Labels: `["ai-generated"]`
   - Parent: epic ID
   - Priority: inherit từ epic hoặc adjust
2. Dùng `createIssueLink` cho dependencies (blocks/is-blocked-by)
3. Report tạo xong: list sub-task IDs + links

---

## Bước 2B: PROGRESS MODE — Report Progress

**Goal**: Update JIRA ticket với progress hiện tại

**Actions**:
1. Xác định ticket ID đang work (từ input hoặc current branch name)
2. Xác định phase vừa complete:
   - Design done → transition "Design" ticket
   - Tests written (RED) → comment on "Implement" ticket
   - Implementation done (GREEN) → transition "Implement" ticket
   - Review done → transition "Review" ticket
3. Dùng `transitionJiraIssue` chuyển status (To Do → In Progress → In Review → Done)
4. Dùng `addCommentToJiraIssue` thêm progress note:

   Format:
   ```
   **Phase: {phase name}** — {status}

   **Summary**: {1-2 sentence summary}
   **Files changed**: {list}
   **Test results**: {pass/fail counts}
   **Next**: {next phase}
   ```

5. Nếu có quality-gate results → dùng `editJiraIssue` update DoD checklist trong description

---

## Bước 2C: QUERY MODE — Sprint Status

**Goal**: Query AI task progress trong sprint hiện tại

**Actions**:
1. Dùng `searchJiraIssuesUsingJql`:
   - All AI tasks: `labels = "ai-generated" AND sprint in openSprints()`
   - By epic: `labels = "ai-generated" AND "Epic Link" = {EPIC-ID}`
   - Blocked: `labels = "ai-generated" AND status = "Blocked"`
2. Present status table:

   | Ticket | Summary | Status | Assignee | Updated |
   |--------|---------|--------|----------|---------|
   | KV-101 | [AI] Design: Export Revenue | Done | AI | 2026-03-30 |
   | KV-103 | [AI] Implement: Export Revenue | In Progress | AI | 2026-03-31 |

3. Highlight: blocked items, overdue, items chưa bắt đầu

---

## Integration Points

Skill này được gọi bởi các skills khác:
- `/develop` Phase 1 → auto-decompose nếu có epic ID
- `/technical-design` Phase 7 → tạo JIRA subtasks (default)
- `/team-develop` → Lead report per phase
- `/write-features` → link .feature files to JIRA
- `/quality-gate` → update DoD checklist
- `/team-three-amigos` → after feature files → auto-decompose

**Không cần user gọi trực tiếp** trong most cases — các skills tự invoke JIRA integration. User gọi khi muốn manual decompose, query sprint, hoặc ad-hoc progress report.

---

## Examples

**Example 1: Decompose epic**
User says: "/jira-sync KV-100"
Actions:
1. Read KV-100 epic details + linked PRD
2. Propose 4 sub-tasks: Design, BDD, Implement, Review
3. User approves → create 4 JIRA issues with [AI] prefix
Result: 4 sub-tasks on JIRA board, linked to epic

**Example 2: Report progress**
User says: "/jira-sync progress — design phase complete for KV-100"
Actions:
1. Find KV-101 ([AI] Design ticket)
2. Transition to Done
3. Add comment: "Design doc: docs/designs/export-revenue-design.md — pragmatic approach chosen"
Result: KV-101 → Done on JIRA board

**Example 3: Sprint query**
User says: "/jira-sync sprint"
Actions:
1. Query all ai-generated tasks in current sprint
2. Present table with status
Result: Overview of AI work progress

---

## Troubleshooting

**Atlassian MCP not available**: Output instructions dạng text cho user manual tạo trên JIRA
**Transition fails**: Check JIRA workflow — target status may need different transition path. Dùng `getTransitionsForJiraIssue` xem available transitions
**Duplicate sub-tasks**: Check existing subtasks trước khi tạo mới — skip nếu đã có
