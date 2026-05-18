---
name: write-prd
description: >-
  Structure requirements thành PRD có hệ thống — từ ý tưởng, meeting notes, JIRA epic thành
  structured PRD trên Confluence với features, use cases, business rules, acceptance criteria.
  Dùng khi bắt đầu feature mới cần PRD, hoặc cần structure lại requirements mơ hồ.
  Trigger: "viết PRD", "write PRD", "tạo PRD", "structure requirements", "PRD từ ý tưởng",
  "tạo spec", "viết requirement". Do NOT use for converting PRD to Gherkin (use write-features),
  technical design (use technical-design), hoặc JIRA task breakdown (use jira-sync).
argument-hint: Mô tả ý tưởng, paste meeting notes, hoặc JIRA epic ID
---

# PRD Writer — Structure Requirements

Biến ý tưởng, meeting notes, hoặc JIRA epic thành PRD có cấu trúc. Focus vào Features, Use Cases, Business Rules — không lạm dụng personas.

## Core Principles

- **Features & Use Cases first** — PRD xoay quanh hệ thống làm gì, không phải ai dùng
- **User roles minimal** — chỉ liệt kê roles cần thiết (Admin, Nhân viên, Khách hàng), KHÔNG dùng tên giả (Minh, Lan) gây confuse
- **Business Rules rõ ràng** — mỗi rule là constraint, validation, hoặc calculation cụ thể
- **Acceptance Criteria testable** — mỗi AC có thể verify bằng test
- **Hỏi khi thiếu** — requirements mơ hồ thì hỏi, không assume

---

## Bước 1: Thu thập Input

$ARGUMENTS

**Actions**:
1. Nếu có JIRA epic ID → dùng Atlassian MCP lấy epic description, acceptance criteria, linked issues
2. Nếu có Confluence link → dùng Atlassian MCP đọc existing content
3. Nếu là text (meeting notes, ý tưởng) → parse key information
4. Extract:
   - **Problem statement** — vấn đề gì cần giải quyết
   - **Target users** — roles (không phải personas)
   - **Key capabilities** — hệ thống cần làm gì
   - **Constraints** — business rules, technical limitations, timeline
   - **Out of scope** — cái gì KHÔNG làm
5. Nếu thiếu thông tin quan trọng → hỏi 1-2 câu targeted

---

## Bước 2: Structure PRD

**Actions**:
1. Organize information thành PRD structure:

```markdown
# PRD: {Feature Name}

## Problem Statement
{1-2 paragraphs: vấn đề gì, tại sao cần giải quyết, impact}

## User Roles
| Role | Description |
|------|------------|
| {Role} | {1 sentence} |

## Features & Use Cases

### Feature 1: {Feature Name}

#### UC-01: {Use Case Name}
**Description**: {What the system does}
**Trigger**: {What initiates this use case}
**Main Flow**:
1. {Step}
2. {Step}
3. {Step}

**Business Rules**:
- BR-01: {Specific constraint/validation/calculation}
- BR-02: {Specific constraint/validation/calculation}

**Acceptance Criteria**:
- AC-01: {Testable condition}
- AC-02: {Testable condition}

**Error Cases**:
- {Error scenario → expected behavior}

#### UC-02: {Use Case Name}
...

### Feature 2: {Feature Name}
...

## Non-Functional Requirements (NFRs)
- **Performance**: {specific metrics — response time, throughput}
- **Security**: {auth, data protection requirements}
- **Scalability**: {expected load, growth}

## Out of Scope
- {Explicitly excluded items}

## Open Questions
- {Unresolved items requiring stakeholder input}

## Appendix
- Figma designs: {links}
- Related JIRA tickets: {links}
- Technical constraints: {known limitations}
```

2. Present PRD draft cho user review
3. **Đợi user feedback** — iterate cho đến khi user approve

---

## Bước 3: Publish

**Actions**:
1. Nếu Atlassian MCP available:
   - Dùng `createConfluencePage` tạo PRD trên Confluence
   - Hoặc `updateConfluencePage` nếu update existing
   - Link PRD page to JIRA epic (nếu có)
2. Nếu không có Atlassian MCP:
   - Tạo local file: `docs/prd/{feature-name}-prd.md`
3. Report: PRD location + link

---

## Examples

**Example 1: From rough idea**
User says: "/write-prd Cần tính năng export báo cáo doanh thu ra Excel cho quản lý chi nhánh"
Actions:
1. Hỏi: user roles nào export? Filters gì? Frequency? Data range?
2. Structure: 1 feature, 3 UCs (export by date, by branch, scheduled export)
3. Business rules: data format, permissions, file size limits
4. Publish to Confluence
Result: Structured PRD with 3 UCs, 8 ACs

**Example 2: From JIRA epic**
User says: "/write-prd KV-100"
Actions:
1. Read JIRA epic KV-100 details + linked issues
2. Extract requirements from description + acceptance criteria
3. Structure into PRD format, fill gaps
4. Hỏi user về unclear items
5. Publish to Confluence, link back to KV-100
Result: PRD on Confluence linked to epic

**Example 3: From meeting notes**
User says: "/write-prd [paste meeting notes]"
Actions:
1. Parse meeting notes → extract action items, decisions, requirements
2. Identify features + use cases
3. Structure PRD, mark unknowns as Open Questions
4. User reviews + fills gaps
Result: PRD with clear features + flagged open questions

---

## Troubleshooting

**Requirements quá mơ hồ**: Hỏi specific questions — "user nào?", "khi nào trigger?", "output gì?"
**Scope quá rộng**: Suggest chia thành multiple PRDs theo module/feature boundary
**Atlassian MCP không available**: Tạo local markdown file, user tự copy lên Confluence
