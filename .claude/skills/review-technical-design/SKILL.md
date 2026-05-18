---
name: review-technical-design
description: >-
  Review và kiểm tra chất lượng technical design document trước khi human review —
  phát hiện completeness gaps, NFR thiếu, architecture issues, weak trade-off analysis,
  và các vấn đề chất lượng khác. Chạy ngay sau khi technical-design skill tạo document xong.
  Trigger khi user nói: "review design doc", "kiểm tra design", "check design trước khi share",
  "design sẵn chưa", "pre-review design", "review technical design trước khi gửi team",
  "AI review design", "check quality design doc". Không dùng cho: implement code, review code PR,
  hoặc thay thế human peer review — đây là AI pre-check để tác giả fix gap trước.
argument-hint: Path tới design document, hoặc tên feature/JIRA ticket ID để tự tìm file
---

# Review Technical Design — AI Pre-Review

Mục tiêu của skill này không phải approve hay reject design, mà giúp tác giả **phát hiện gap trước khi human reviewer đọc** — tiết kiệm review cycle, tránh back-and-forth vì thiếu thông tin cơ bản.

---

## Input Handling

`$ARGUMENTS` có thể là:
- **File path cụ thể** (ví dụ `docs/designs/kv-789-revenue-export-design.md`) → đọc trực tiếp
- **JIRA ticket ID** (format `[A-Z]+-[0-9]+`) → tìm file matching trong `docs/designs/`
- **Feature name / keyword** → glob `docs/designs/**/*.md`, tìm file có title hoặc filename match
- **Empty** → list tất cả design files trong `docs/designs/`, hỏi user chọn

---

## Workflow

### Step 1: Load & Classify

1. Locate và đọc design document
2. Xác định design type: **Feature mới** / **Brownfield change** / **Migration** / **Greenfield**
3. Xác định scope complexity: **Small** (1-2 components) / **Medium** / **Large** (cross-service)
4. Note design type và complexity — dùng để calibrate severity expectations bên dưới

### Step 2: Run 8 Review Dimensions

Chạy từng dimension, collect findings. Với mỗi finding ghi rõ:
- **Severity**: 🔴 BLOCKER / 🟡 MAJOR / 🟢 MINOR
- **Finding**: mô tả cụ thể — trích dẫn section hoặc quote từ document nếu helpful
- **Why it matters**: tại sao ảnh hưởng đến reviewability hoặc implementability
- **Suggestion**: action cụ thể để fix

### Step 3: Write Review Report

Viết review report theo format ở cuối skill. Hỏi user save location:
- Default: cùng folder với design doc, filename `{design-name}-review.md`
- Custom path nếu user specify

---

## Review Dimensions

### D1 — Completeness

Expected sections cho một design document đầy đủ:
- **Meta**: Author, Date, Status, JIRA, PRD/Spec links
- **Overview**: Problem Statement, Goals, Non-Goals, Scope
- **Current State** (hoặc Context cho greenfield): architecture liên quan, patterns, dependencies, limitations
- **Proposed Solution**: Architecture Decision, Component Design, API Contracts, Data Model (nếu có DB changes), Data Flow
- **Alternatives Considered**: ít nhất 1 alternative với comparison table
- **Implementation Plan**: ít nhất 2 phases với tasks và dependencies
- **Test Strategy**: Unit, Integration, E2E coverage approach
- **Risks & Mitigations**: ít nhất 2-3 risks
- **Cross-Cutting Concerns**: Security, Performance, Monitoring, Backward Compatibility, Migration Plan
- **Open Questions**: với owner assigned

Flags:
- BLOCKER: Proposed Solution hoặc Implementation Plan hoàn toàn thiếu hoặc còn trống
- MAJOR: Section còn chứa placeholder `{...}` text, hoặc bị skip không có note giải thích
- MINOR: Sub-section thiếu nhưng có thể justify (ví dụ: không có Migration Plan vì không có breaking changes)

### D2 — Problem & Scope Clarity

Hỏi:
- Problem Statement có **specific và measurable** không? ("users are frustrated" không đủ — "checkout abandonment rate 34% do thiếu payment method" mới đủ)
- Goals có **testable/verifiable** không? ("improve performance" không đủ — "reduce p95 latency từ 800ms xuống <200ms" mới đủ)
- Non-Goals có **explicit** không? Thiếu Non-Goals là dấu hiệu scope creep risk
- Scope có list rõ services/modules bị affected không?

Flags:
- MAJOR: Problem Statement không measurable, hoặc Goals không verifiable
- MAJOR: Hoàn toàn không có Non-Goals cho feature medium/large scope
- MINOR: Scope thiếu team/service ownership

### D3 — NFR Coverage

Check list:
- [ ] **Performance**: expected load (RPS/DAU/concurrent users), latency SLA, peak traffic pattern?
- [ ] **Availability**: uptime requirement, acceptable downtime window?
- [ ] **Scalability**: growth expectation 6-12 months?
- [ ] **Security**: data classification, authentication/authorization requirements, compliance (GDPR, PCI)?

Calibrate theo scope complexity:
- Small feature, không xử lý external/sensitive data: NFR mention ngắn là đủ
- Medium/Large feature hoặc feature xử lý PII/financial data: cần concrete numbers

Flags:
- BLOCKER: Feature xử lý PII hoặc financial data mà không có security/compliance mention
- MAJOR: Medium/Large feature hoàn toàn không có NFRs
- MAJOR: NFRs có nhưng chỉ qualitative ("must be fast") — không có baseline/target numbers
- MINOR: Small feature thiếu scalability projection

### D4 — Architecture Soundness

Hỏi:
- **Component Design**: đủ detail để implement không? (file paths, class/function names, responsibilities rõ ràng — không chỉ box diagram)
- **API Contracts**: cụ thể không? (endpoint paths, request/response fields với types, error responses — không chỉ "POST /endpoint")
- **Data Flow**: traceable từ entry point đến output/storage không? Mỗi step rõ ràng?
- **Data Model**: nếu có schema changes, có đủ definition không? (table names, columns, types, indexes)
- **Internal consistency**: có mâu thuẫn không? (ví dụ: nói synchronous nhưng data flow có async step; nói stateless nhưng dùng session state)

Flags:
- BLOCKER: Internal contradiction rõ ràng trong design
- MAJOR: API contracts chỉ có endpoint names, thiếu request/response schema
- MAJOR: Data flow bị gián đoạn — không traceable từ đầu đến cuối
- MINOR: Component design thiếu file paths (có class names nhưng không rõ nằm ở đâu)

### D5 — Trade-off Analysis Quality

Hỏi:
- Có ít nhất **1 alternative approach** được document không?
- Alternatives Considered table có **substantive comparison** hay chỉ là template placeholder?
- Recommendation có **rationale rõ ràng**: "tại sao chọn approach này thay vì approach kia"?
- Nếu hybrid approach: elements từ mỗi approach có được specify không? Hybrid có risk tạo "worst of both worlds" không?

Flags:
- MAJOR: Chỉ có 1 approach, không có alternatives — đặc biệt cho medium/large scope
- MAJOR: Alternatives table điền nhưng rationale trống hoặc còn là placeholder
- MINOR: Rationale có nhưng shallow (1 câu generic, không address specific trade-offs)

### D6 — Implementation Feasibility

Hỏi:
- Implementation Plan có **chia phases** với task breakdown rõ ràng không?
- Mỗi task có **estimated effort** không? (S/M/L hoặc story points)
- **Dependencies** giữa tasks có explicit không? Có circular dependency không?
- Có **missing prerequisites** trong task order không? (ví dụ: Phase 2 depends on infra mà Phase 1 chưa setup)

Flags:
- MAJOR: Implementation Plan là 1 flat list, không có phases hoặc dependencies
- MAJOR: Không có effort estimates — team không thể plan sprint
- MINOR: Task descriptions quá high-level, không actionable trong 1 sprint

### D7 — Risk Coverage

Hỏi:
- Risk table có **ít nhất 2-3 risks** không?
- Mỗi risk có **mitigation strategy cụ thể** không? ("Monitor it" không phải mitigation — "Add circuit breaker + fallback to cached data" mới là)
- Có **obvious risks bị bỏ sót** không? Ví dụ:
  - Breaking API changes mà không có backward compat risk
  - External dependency mà không có availability risk
  - Schema migration mà không có data integrity risk
- High-impact risks có **contingency/rollback plan** không?

Flags:
- BLOCKER: Breaking change rõ ràng (API schema change, removed field) mà không có backward compat plan
- MAJOR: Risk table trống hoặc chỉ có 1 generic risk
- MAJOR: Mitigation là "monitor" hoặc "test thoroughly" — không đủ cụ thể
- MINOR: Medium risks thiếu contingency plan

### D8 — Cross-Cutting Concerns

Check list:
- [ ] **Security**: expose data mới không? Auth/authz logic đúng không? Input validation được mention không?
- [ ] **Backward Compatibility**: có breaking changes không? Migration path cho existing clients/data rõ không?
- [ ] **Monitoring & Observability**: metrics/alerts mới cần add không? Logging có cần update không?
- [ ] **Performance**: caching strategy? N+1 query risk? Bulk operations handle thế nào?
- [ ] **Migration Plan**: feature flag? phased rollout? blue-green? rollback strategy?

Flags:
- BLOCKER: Security-sensitive feature (auth changes, PII access) không có auth/data protection discussion
- MAJOR: Feature có breaking changes nhưng Migration Plan section trống
- MINOR: Monitoring section thiếu cho medium/large feature

---

## Review Report Format

```markdown
# Technical Design Review — {Document Title}

**Reviewed by**: AI Pre-Review
**Review date**: {YYYY-MM-DD}
**Document**: {file path}
**Design type**: {Feature / Brownfield / Migration / Greenfield} — {Small/Medium/Large}

---

## Overall Verdict

**{✅ READY FOR REVIEW / ⚠️ NEEDS REVISION / 🔴 BLOCKED}**

{1-2 câu tóm tắt lý do verdict}

---

## Findings Summary

| Severity | Count |
|----------|-------|
| 🔴 BLOCKER | N |
| 🟡 MAJOR | N |
| 🟢 MINOR | N |

---

## Findings

### 🔴 Blockers

#### [B1] {Finding title}
**Dimension**: D{N} — {Dimension Name}
**Finding**: {Mô tả cụ thể — quote section/text từ document nếu helpful}
**Why it matters**: {Tại sao ảnh hưởng đến review hoặc implementation}
**Suggestion**: {Action cụ thể để fix}

### 🟡 Major Issues

{Same format — mỗi finding là riêng 1 block}

### 🟢 Minor Suggestions

{Có thể dùng bullet list ngắn thay vì full block cho minor items}

---

## What's Done Well

- {Điểm tích cực 1}
- {Điểm tích cực 2}
- {Điểm tích cực 3}

---

## Next Steps

1. {Action ưu tiên nhất — thường là fix blockers trước}
2. {Action 2}
3. Sau khi fix: re-run `/kv-engineering:review-technical-design` để verify
```

---

## Verdict Criteria

| Verdict | Condition |
|---------|-----------|
| ✅ READY FOR REVIEW | 0 BLOCKERs, ≤ 2 MAJORs |
| ⚠️ NEEDS REVISION | 0 BLOCKERs, > 2 MAJORs |
| 🔴 BLOCKED | ≥ 1 BLOCKER |

Khi không chắc severity, hỏi:
- **BLOCKER** → "Human reviewer đọc bây giờ sẽ không thể evaluate design vì thiếu info này"
- **MAJOR** → "Reviewer sẽ raise concern lớn — fix trước tiết kiệm 1 review round"
- **MINOR** → "Nice-to-have, cải thiện clarity nhưng không block review"

Không inflate severity — 3 BLOCKERs thực sự có giá trị hơn 10 MINORs.

---

## Troubleshooting

**Document không tìm thấy**: List files trong `docs/designs/`, hỏi user confirm path
**Document không theo template**: Review theo spirit của template, note deviation thay vì penalize
**Greenfield — không có current state**: Expected, không penalize D1 cho Current State section
**Feature quá nhỏ (hotfix/config change)**: Calibrate — tập trung D4 (Architecture Soundness) và D7 (Risk) thay vì full NFR suite
