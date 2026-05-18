---
name: review-bdd
description: >-
  Review chất lượng .feature files (Gherkin/BDD) — kiểm tra structural quality, semantic correctness,
  PRD coverage gaps, step language consistency, tag compliance, Scenario Outline misuse.
  Dùng sau /write-features hoặc khi cần review .feature files existing.
  Trigger: "review feature file", "check BDD quality", "review gherkin", "feature file ổn chưa",
  "kiểm tra feature", "validate BDD", "review scenarios", "BDD quality check",
  "check coverage", "feature file review".
  Do NOT use for writing feature files (use write-features), generating step definitions (use generate-steps),
  hoặc reviewing PRD (use review-prd).
argument-hint: Path tới .feature file, folder features/, hoặc paste nội dung Gherkin
---

# BDD Feature File Quality Review

Review chất lượng `.feature` files trước khi generate step definitions — phát hiện structural issues, coverage gaps, semantic flaws, step language inconsistencies để tránh implement tests cho scenarios thiếu hoặc sai.

## References

- Quality checklist chi tiết với scoring: `references/bdd-quality-checklist.md`
- PRD coverage matrix template: `references/coverage-matrix-template.md`

## Core Principles

- **Gate trước generate-steps** — catch issues rẻ hơn fix sau khi đã viết step definitions
- **Coverage-first** — feature file thiếu scenario nghiêm trọng hơn scenario viết chưa đẹp
- **Actionable findings** — mỗi finding có suggestion fix cụ thể kèm Gherkin example
- **Confidence-based** — chỉ report issues confidence >= 75%

---

## Bước 1: Thu thập Input

$ARGUMENTS

**Actions**:
1. Nếu có file/folder path → đọc `.feature` files
2. Nếu không có path → tìm trong `features/` hoặc `**/*.feature` trong codebase
3. Nếu là pasted Gherkin → parse trực tiếp
4. Tìm PRD source:
   - Check comment `# PRD:` đầu feature file → đọc PRD từ link đó
   - Nếu có Confluence link → dùng Atlassian MCP
   - Nếu không tìm được PRD → vẫn review structural quality, skip coverage analysis, ghi finding `[QUESTION]`
5. Đọc `references/bdd-quality-checklist.md` cho review criteria

---

## Bước 2: Review theo 6 Dimensions

Đọc `references/bdd-quality-checklist.md` rồi review feature files theo 6 dimensions:

| # | Dimension | Focus | Weight |
|---|-----------|-------|--------|
| 1 | **Structural Compliance** | Gherkin syntax, Rule: mandatory, step order, step count | x1 |
| 2 | **Semantic Quality** | Declarative steps, 1 behavior/scenario, business language | x1 |
| 3 | **Tag Compliance** | 4-dimension tags đầy đủ, tag values hợp lệ, @smoke limits | x1 |
| 4 | **Step Language Consistency** | Cùng concept dùng cùng term, personas nhất quán, step reusable | x1 |
| 5 | **Scenario Outline Correctness** | Equivalence classes khác nhau, behavior separation, data transparency | x1 |
| 6 | **PRD Coverage** | Mọi UC/AC có Rule/Scenario, edge cases, negative paths, boundary values | x2 |

**Dimension 6 (PRD Coverage) weighted x2** — feature file đầy đủ scenarios quan trọng hơn scenarios viết hoàn hảo. Cần cross-reference PRD để identify gaps.

Cho mỗi dimension: review → ghi findings → assign severity.

---

## Bước 3: Classify Findings

Format mỗi finding:

```
[PREFIX] Brief issue description — Dimension: {dimension} — confidence: X%

Location: {file}:{line} hoặc Rule: "{rule name}"
Why: Tại sao đây là vấn đề
Fix: Suggestion cụ thể kèm Gherkin example nếu cần
```

| Prefix | Meaning | Action |
|--------|---------|--------|
| `[BLOCKING]` | Feature file không thể implement — missing Rule, broken syntax, orphan scenario, PRD requirement thiếu hoàn toàn | Must fix |
| `[SUGGESTION]` | Cải thiện chất lượng — imperative step, weak title, missing edge case, inconsistent term | Should fix |
| `[QUESTION]` | Cần clarify — ambiguous behavior, PRD không tìm được, unclear scope | Cần trả lời |
| `[NIT]` | Minor — formatting, tag order, naming convention | Optional |

**Filter**: Chỉ report findings confidence >= 75%. Group theo dimension.

---

## Bước 4: Coverage Analysis

Bước này CHỈ chạy khi tìm được PRD source. Đọc `references/coverage-matrix-template.md` cho format.

**Actions**:
1. List tất cả Use Cases (UC) và Acceptance Criteria (AC) từ PRD
2. Map mỗi AC → Rule/Scenario trong feature files qua `@trace` IDs
3. Identify gaps:
   - AC không có Rule nào map → `[BLOCKING]` missing coverage
   - Rule chỉ có happy path, thiếu error/edge → `[SUGGESTION]` incomplete coverage
   - `@trace` ID mismatch giữa PRD và feature file → `[BLOCKING]` broken traceability
4. Output Coverage Matrix (xem template trong references)

---

## Bước 5: Tính Quality Score

Tính score cho mỗi dimension (0-10) theo scoring guide trong `references/bdd-quality-checklist.md`.

Formula: **(D1 + D2 + D3 + D4 + D5 + D6×2) / 7**

Output format:

```
BDD Quality Review Report
==========================
Feature: {Feature Name}
Source: {file path(s)}
PRD: {link hoặc "Not found"}

Dimension Scores:
  {Dimension}:    {score}/10 [PASS|WARN|FAIL] — {brief note nếu không PASS}

Overall: {weighted avg}/10 — {verdict}
Findings: {n} BLOCKING, {n} SUGGESTION, {n} QUESTION, {n} NIT
Coverage: {covered ACs}/{total ACs} ({percent}%)
```

| Score | Verdict |
|-------|---------|
| >= 8.0 | READY FOR STEP GENERATION |
| 6.0 - 7.9 | NEEDS MINOR REVISION |
| 4.0 - 5.9 | NEEDS MAJOR REVISION |
| < 4.0 | REWRITE RECOMMENDED |

**Verdict Escalation**: Sau khi tính score, apply escalation rules từ `references/bdd-quality-checklist.md` — ví dụ: >= 3 BLOCKING → tối thiểu MAJOR, >= 5 BLOCKING → tối thiểu REWRITE. Escalation chỉ kéo verdict xuống, không kéo lên. Điều này ngăn feature files có score cao nhưng coverage gaps nghiêm trọng bị đánh giá quá lạc quan.

---

## Bước 6: Present & Fix

**Actions**:
1. Present report với findings grouped theo severity (BLOCKING first)
2. Present Coverage Matrix (nếu có PRD)
3. Hỏi user: muốn auto-fix issues nào?
4. Nếu user chọn fix:
   - Fix trực tiếp trong `.feature` files
   - Re-run review sau khi fix để confirm score improvement
5. Suggest next steps based on verdict:
   - **READY**: "Feature files sẵn sàng → dùng `/generate-steps` để tạo step definitions"
   - **NEEDS REVISION**: Fix findings rồi re-review
   - **REWRITE**: "Feature files cần rewrite → dùng `/write-features` lại từ PRD"

---

## Examples

**Example 1: Review sau /write-features**
User says: "/review-bdd features/billing/merchant-invoice.feature"
Actions:
1. Đọc feature file → extract PRD link từ comment `# PRD:`
2. Đọc PRD → list 5 UCs, 12 ACs
3. Review 6 dimensions → findings: 1 BLOCKING (UC-03 missing Rule), 2 SUGGESTION (imperative steps)
4. Coverage: 10/12 ACs (83%)
5. Score: 6.8/10 NEEDS MINOR REVISION
6. User auto-fix → add Rule cho UC-03, rewrite steps → re-review: 8.5/10 READY
Result: Suggest `/generate-steps`

**Example 2: Review folder features/**
User says: "/review-bdd features/"
Actions:
1. Glob `features/**/*.feature` → tìm 4 files across 2 modules
2. Review từng file → aggregate findings
3. Coverage matrix per module
4. Overall: 7.2/10, 2 files READY, 2 files NEEDS REVISION
Result: Focused fix list cho 2 files cần revision

**Example 3: Quick check pasted Gherkin**
User says: "/review-bdd" + paste Gherkin content
Actions:
1. Parse Gherkin → no PRD link found
2. Review structural + semantic (skip coverage)
3. 8.0/10 — structural tốt, nhưng `[QUESTION]`: không verify được coverage
Result: Suggest link PRD để full review

---

## Troubleshooting

**Không tìm được PRD**: Vẫn review 5/6 dimensions, skip Coverage, note trong report
**Feature file quá dài (>200 lines)**: Likely cần tách per module — flag as SUGGESTION
**Scenario Outline lạm dụng**: Check equivalence classes, flag nếu rows cùng behavior class
**Steps mix tiếng Anh/Việt**: Flag inconsistency, suggest chuẩn hóa theo domain glossary
**@trace IDs không khớp**: Cross-check PRD UC/AC numbering, suggest correct mapping
