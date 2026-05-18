---
name: technical-design
description: >-
  Tạo technical design document / solution design cho feature hoặc system change — explore
  codebase, multi-perspective architecture (pragmatic vs robust), generate structured design
  document với component design, API contracts, data flow, risks, implementation plan.
  Dùng khi cần thiết kế trước khi implement, review architecture với team, hoặc plan sprint.
  Trigger: "technical design", "solution design", "thiết kế technical", "design document",
  "lên design", "architect feature", "tech spec". Do NOT use for implementing code (use develop),
  standalone code review (use review), hoặc production incident (use respond-incident).
argument-hint: Mô tả feature/system change cần thiết kế, kèm JIRA ticket hoặc PRD link nếu có
---

# Technical Design — Solution Design Workflow

Tạo technical design document có hệ thống — từ requirements đến structured design document sẵn sàng cho team review, sprint planning, hoặc publish lên Confluence.

## References

- Design document template: xem `references/design-document-template.md`
- Multi-perspective design approach: xem `references/design-perspectives.md`

## Core Principles

- **Design document là deliverable** — không phải stepping stone sang implementation. Document phải đủ chi tiết để team khác đọc hiểu và review
- **Hiểu trước khi thiết kế** — explore codebase patterns, existing approaches trước khi propose solution. Tránh design trong vacuum
- **Multi-perspective** — luôn có ít nhất 2 góc nhìn (pragmatic vs robust) để trade-off analysis có depth
- **Concrete, not abstract** — file paths, function names, API contracts cụ thể. Không viết design chung chung
- **Dùng TodoWrite** — structured tracking giúp user theo dõi tiến độ qua các phases

---

## Phase 1: Understand Requirements

**Goal**: Thu thập đủ thông tin về feature/task cần design

Initial request: $ARGUMENTS

**Actions**:
1. Tạo todo list với tất cả phases
2. Nếu có JIRA ticket ID → dùng Atlassian MCP lấy ticket details (description, acceptance criteria, linked issues)
3. Nếu có Confluence spec/PRD link → dùng Atlassian MCP đọc nội dung
4. Nếu có Figma link → dùng Figma MCP phân tích design
5. Extract: scope, constraints, stakeholders, timeline, dependencies
6. Tóm tắt understanding cho user
7. **Hỏi user confirm understanding trước khi explore**

Nếu user nói "tuỳ bạn" → đưa assumption cụ thể, xin explicit confirmation.

---

## Phase 2: Codebase Exploration

**Goal**: Map architecture, patterns, integration points liên quan

**Actions**:
1. Launch 2-3 **code-explorer** agents song song — target aspects khác nhau:
   - Agent 1: Similar features đã implement — approach, file structure, patterns
   - Agent 2: Architecture layers, module boundaries, abstraction patterns
   - Agent 3 (nếu cần): Integration points, external dependencies, shared modules
2. Nếu feature liên quan database (schema changes, stored procedures, migrations, CDC) → launch thêm **db-engineer** agent phân tích schema hiện có và database patterns
3. Dùng Context7 MCP tra cứu library/framework docs nếu cần
4. Đọc tất cả files agents xác định là critical
5. Present tóm tắt findings: architecture overview, patterns found, integration points, constraints discovered

---

## Phase 2.5: Impact Analysis (Brownfield Only)

**Goal**: Xác định change impact khi modify existing features. Skip cho greenfield.

**Trigger**: Phase 2 exploration phát hiện existing implementation cho feature này.

**Actions**:
1. Identify tất cả files, services, modules bị ảnh hưởng bởi proposed change
2. Nếu project dùng `@trace` annotations → run trace analysis tìm requirement-level impact (UCs/ACs nào affected?)
3. List tests cần update (unit, integration, BDD scenarios)
4. List documentation có thể stale
5. Identify downstream consumers (API callers, event subscribers, shared library users)
6. Tạo risk assessment:

   | Area | Impact | Risk | Reason |
   |------|--------|------|--------|
   | {file/service} | High/Medium/Low | {description} | {why affected} |

7. Output: Impact Analysis section sẽ include trong design document

---

## Phase 3: Clarifying Questions

**Goal**: Resolve mọi unknowns trước khi design

**Actions**:
1. Compile câu hỏi từ exploration findings:
   - Edge cases chưa rõ trong requirements
   - Performance requirements (expected load, latency SLA)
   - Integration constraints (API versioning, backward compatibility)
   - Security concerns (auth, data sensitivity)
   - Scope boundaries (services nào in/out of scope)
2. Present tất cả câu hỏi cho user dạng organized list theo category
3. **Đợi user trả lời trước khi tiếp tục**

Nếu không có câu hỏi (requirements rõ ràng) → skip phase này, note lý do.

---

## Phase 4: Multi-Perspective Design

**Goal**: 2 architecture proposals từ góc nhìn khác nhau

**Actions**:
1. Đọc `references/design-perspectives.md` để hiểu approach cho mỗi perspective
2. Launch 2 **code-architect** agents song song:
   - **Bàng Thống** (Pragmatic): tận dụng code hiện có, minimize complexity, ship nhanh. Deliver: component design, API contracts, data flow, test strategy, risks
   - **Lỗ Túc** (Robust): maintainability, extensibility, comprehensive error handling. Deliver: component design, API contracts, data flow, test strategy, risks
3. Nếu feature có database changes → launch thêm **db-engineer** agent thiết kế database architecture (schema, indexes, stored procedures, migrations) — kết quả feed vào cả 2 architects
4. Đọc output của cả 2 architects, verify bằng cách đọc source files referenced

---

## Phase 5: Synthesize & Compare

**Goal**: So sánh 2 approaches, đưa recommendation

**Actions**:
1. Tạo comparison table theo Decision Matrix trong `references/design-perspectives.md`:

   | Tiêu chí | Pragmatic (Bàng Thống) | Robust (Lỗ Túc) |
   |-----------|------------------------|------------------|
   | Complexity (files, LOC) | | |
   | Maintainability | | |
   | Performance | | |
   | Risk level | | |
   | Pattern alignment | | |
   | Testability | | |
   | Time to deliver | | |

2. Đề xuất recommendation với rationale — có thể là 1 approach hoặc hybrid
3. **Hỏi user chọn approach** (pragmatic / robust / hybrid / custom)

---

## Phase 6: Generate Design Document

**Goal**: Tạo structured technical design document

**Actions**:
1. Đọc `references/design-document-template.md`
2. Fill template với chosen approach:
   - **Meta**: author, date, status Draft, JIRA/PRD links
   - **Overview**: problem statement, goals, non-goals, scope
   - **Current State**: architecture findings từ Phase 2
   - **Proposed Solution**: chosen architecture, component design, API contracts, data model, data flow
   - **Alternatives Considered**: approach không chọn + reasoning
   - **Implementation Plan**: phased steps với dependencies, JIRA ticket suggestions
   - **Test Strategy**: unit, integration, E2E approach
   - **Risks & Mitigations**: risk matrix
   - **Cross-Cutting Concerns**: security, performance, monitoring, backward compatibility, migration
   - **Open Questions**: unresolved items
3. Hỏi user save location:
   - Default: `docs/designs/{feature-name}-design.md`
   - Custom path nếu user specify
4. Write file

---

## Phase 7: Review & Deliver

**Goal**: Finalize document, create JIRA subtasks, optional publish/actions

**Actions**:
1. Present document summary cho user — highlight key decisions, risks, open questions

### JIRA Integration (default khi có ticket ID)

Nếu user cung cấp JIRA ticket ID từ Phase 1:

1. **Tạo JIRA subtasks**: Dùng Atlassian MCP `createJiraIssue` cho mỗi implementation step trong Implementation Plan
   - Summary format: `[AI] {step}: {feature name}`
   - Labels: `["ai-generated"]`
   - Link to parent ticket
2. **Transition status**: Dùng `transitionJiraIssue` chuyển design ticket sang Done
3. **Add comment**: Summary of design decisions, chosen approach, link to design doc

Nếu Atlassian MCP không available → output JIRA-ready format cho user manual tạo.
Nếu không có JIRA ticket ID → skip silently.

### Next steps

2. Hỏi user next steps:
   - **Review only**: done, user tự share với team
   - **Publish lên Confluence**: dùng Atlassian MCP tạo/update Confluence page
   - **Chuyển sang implement**: suggest user dùng `/develop` hoặc `/team-develop` với design document làm input
3. **User checkpoint**: final approval

---

## Examples

**Example 1: Feature mới từ JIRA**
User says: "Technical design cho KV-789 — export báo cáo doanh thu ra Excel"
Actions:
1. Understand: lấy JIRA details, clarify format requirements
2. Explore: tìm existing export patterns, Excel library đang dùng
3. Questions: file size limits? date range? filters? async or sync?
4. Design: 2 proposals — pragmatic (add method to existing ReportService) vs robust (new ExportModule with strategy pattern)
5. Synthesize: recommend pragmatic — scope nhỏ, pattern đã có
6. Generate: `docs/designs/kv-789-revenue-export-design.md`
7. Deliver: user review, tạo 3 JIRA subtasks

**Example 2: Cross-cutting system change**
User says: "Thiết kế technical cho migration từ SQL Server sang PostgreSQL cho module Inventory"
Actions:
1. Understand: scope module, timeline, backward compatibility requirements
2. Explore: map tất cả SQL Server-specific code (stored procedures, CDC, triggers), schema dependencies
3. Questions: dual-write period? rollback strategy? data volume? downtime acceptable?
4. Design: pragmatic (phased migration, dual-write) vs robust (full abstraction layer, repository pattern)
5. Synthesize: recommend hybrid — repository pattern cho new code, dual-write cho transition
6. Generate: `docs/designs/inventory-postgresql-migration-design.md`
7. Deliver: publish lên Confluence, tạo Epic + subtasks

**Example 3: Quick design từ verbal description**
User says: "Design solution cho real-time notification system"
Actions:
1. Understand: clarify — notification types, channels (email, push, in-app), volume, latency
2. Explore: existing notification code, message queue patterns, WebSocket setup
3. Questions: guaranteed delivery? priority levels? user preferences?
4. Design: pragmatic (SignalR + simple queue) vs robust (event-driven with dedicated notification service)
5. Synthesize: comparison table, recommend based on scale
6. Generate: design document
7. Deliver: user review

## Troubleshooting

**Requirements quá mơ hồ**: Quay lại Phase 1, hỏi user cung cấp thêm context — PRD, JIRA ticket, hoặc user story
**Codebase quá lớn, explore lâu**: Focus scope — hỏi user specific modules/services liên quan, giới hạn exploration area
**Cả 2 approaches đều phức tạp**: Suggest chia nhỏ scope — design cho core feature trước, defer extensions sang follow-up design
**User muốn implement ngay**: Redirect sang `/develop` hoặc `/team-develop`, pass design document làm input
**Không có codebase (greenfield)**: Skip Phase 2, focus Phase 4 với industry patterns và technology selection
