---
name: review-prd
description: >-
  Review chất lượng PRD trước khi human review — kiểm tra completeness, AC testability,
  business rules specificity, traceability readiness, consistency, scope clarity.
  Dùng khi PRD vừa viết xong (sau /write-prd) hoặc cần review PRD existing.
  Trigger: "review PRD", "kiểm tra PRD", "check PRD quality", "PRD review",
  "PRD đã ổn chưa", "validate PRD", "PRD quality check".
  Do NOT use for writing PRD (use write-prd), converting PRD to Gherkin (use write-features),
  hoặc code review (use review).
argument-hint: Confluence link, local file path, hoặc paste nội dung PRD
---

# PRD Quality Review

Review chất lượng PRD trước human review — phát hiện gaps, ambiguity, untestable criteria để tránh lãng phí thời gian stakeholder.

## References

- Quality checklist chi tiết: `references/prd-quality-checklist.md`
- Common edge case patterns: `references/edge-case-patterns.md`

## Core Principles

- **Gate, không gatekeep** — mục tiêu là nâng chất lượng, không block process
- **Actionable findings** — mỗi finding phải có suggestion fix cụ thể
- **Confidence-based** — chỉ report issues confidence >= 75%
- **Tôn trọng intent** — review quality của PRD, không rewrite requirements

---

## Bước 1: Thu thập PRD

$ARGUMENTS

**Actions**:
1. Nếu có Confluence link → dùng Atlassian MCP đọc page
2. Nếu có local file path → đọc file
3. Nếu là pasted text → parse trực tiếp
4. Nếu không có input → tìm PRD gần nhất trong `docs/prd/` hoặc hỏi user
5. Đọc `references/prd-quality-checklist.md` cho review criteria

---

## Bước 2: Review theo 8 Dimensions

Đọc `references/prd-quality-checklist.md` rồi review PRD theo 8 dimensions (1-7: structural, 8: logical):

| # | Dimension | Focus |
|---|-----------|-------|
| 1 | **Structure Completeness** | Tất cả sections có mặt, không thiếu, không TBD |
| 2 | **Use Case Quality** | Mỗi UC có trigger, main flow, error cases |
| 3 | **Business Rules Specificity** | Mỗi BR là constraint/validation/calculation cụ thể, không mơ hồ |
| 4 | **AC Testability** | Mỗi AC verify được bằng automated test |
| 5 | **Traceability Readiness** | IDs nhất quán, sẵn sàng cho write-features downstream |
| 6 | **Internal Consistency** | Không mâu thuẫn giữa sections, roles khớp với UCs |
| 7 | **Scope & NFR Clarity** | Out of scope rõ ràng, NFRs có metrics cụ thể |
| 8 | **Logical Completeness** | UC/AC đủ chưa, conflict không, edge/error cases bị miss |

Dimensions 1-7 kiểm tra format/structure. **Dimension 8 kiểm tra logic** — đây là phần quan trọng nhất, cần đọc thêm `references/edge-case-patterns.md` để identify missing scenarios.

Cho mỗi dimension: review → ghi findings → assign severity.

---

## Bước 3: Classify Findings

Format mỗi finding:

```
[PREFIX] Brief issue description — Dimension: {dimension} — confidence: X%

Why: Tại sao đây là vấn đề
Fix: Suggestion cụ thể để fix
```

| Prefix | Meaning | Action |
|--------|---------|--------|
| `[BLOCKING]` | PRD không thể review/implement được nếu không fix — missing UC, untestable AC, contradictions | Must fix |
| `[SUGGESTION]` | Cải thiện chất lượng — vague BR, missing error case, weak NFR | Should fix |
| `[QUESTION]` | Cần stakeholder clarify — ambiguous requirement, missing context | Cần trả lời |
| `[NIT]` | Minor — formatting, naming convention, typo | Optional |

**Filter**: Chỉ report findings confidence >= 75%. Group theo dimension.

---

## Bước 4: Tính Quality Score

Tính score cho mỗi dimension (0-10) theo scoring guide trong `references/prd-quality-checklist.md`.

Output format:

```
PRD Quality Review Report
=========================
PRD: {Feature Name}
Source: {Confluence link / file path}

Dimension Scores:
  {Dimension}:    {score}/10 [PASS|WARN|FAIL] — {brief note nếu không PASS}

Overall: {avg}/10 — {verdict}
Findings: {n} BLOCKING, {n} SUGGESTION, {n} QUESTION, {n} NIT
```

Apply verdict thresholds từ `references/prd-quality-checklist.md` Scoring Guide.

---

## Bước 5: Present & Fix

**Actions**:
1. Present findings grouped theo severity (BLOCKING first)
2. Hỏi user: muốn auto-fix issues nào?
3. Nếu user chọn fix:
   - Fix trực tiếp trong PRD (Confluence hoặc local file)
   - Re-run review sau khi fix để confirm
4. Nếu PRD đạt "READY FOR REVIEW":
   - Suggest: "PRD sẵn sàng — chạy `/approve-prd` để stakeholder sign-off trước khi sync JIRA"
   - Nếu có JIRA epic → comment review result lên epic
5. Suggest next steps:
   - `/approve-prd` để business approval gate (bắt buộc trước `/jira-sync`)
   - `/write-features` để convert PRD → Gherkin (sau khi approved)
   - `/technical-design` để tạo technical design (sau khi approved)

---

## Examples

**Example 1: Review PRD vừa viết**
User says: "/review-prd docs/prd/revenue-export-prd.md"
Actions:
1. Đọc file → parse PRD sections
2. Review 7 dimensions → findings: 1 BLOCKING (AC-03 untestable), 2 SUGGESTION (vague BRs)
3. Score: 6.5/10 NEEDS MINOR REVISION
4. User chọn auto-fix → rewrite AC-03 + clarify BRs → re-review: 8.2/10 READY
Result: PRD improved, ready for stakeholder review

**Example 2: Review Confluence PRD**
User says: "/review-prd https://example.atlassian.net/wiki/..."
Actions:
1. Đọc Confluence page via Atlassian MCP
2. Review → findings: 0 BLOCKING, 3 SUGGESTION, 2 QUESTION
3. Score: 7.8/10 NEEDS MINOR REVISION
4. Present questions cần stakeholder answer
Result: PRD gần ready, cần clarify 2 questions

**Example 3: Quick check sau /write-prd**
User says: "/review-prd" (no args, tìm PRD gần nhất)
Actions:
1. Tìm file mới nhất trong docs/prd/ → đọc
2. Review → 8.5/10 READY FOR REVIEW
3. Suggest next: /write-features
Result: PRD passes quality gate

---

## Troubleshooting

**PRD quá ngắn**: Likely incomplete — check Structure Completeness dimension, flag missing sections
**PRD không theo template**: Vẫn review được — map content vào 7 dimensions, suggest restructure
**Quá nhiều findings**: Focus BLOCKING first, group SUGGESTION theo dimension để không overwhelm
**Sau fix vẫn không pass**: Escalate — PRD có thể cần rewrite, suggest quay lại /write-prd
