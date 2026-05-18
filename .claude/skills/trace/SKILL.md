---
name: trace
description: >-
  Extract và query traceability matrix từ embedded @trace annotations trong code, tests, feature files.
  Generate JSON report cho visualization. Reverse trace từ file → impacted requirements.
  Trigger: "trace", "traceability", "trace matrix", "kiểm tra coverage", "impact analysis",
  "which requirements", "trace reverse", "coverage report". Do NOT use for writing @trace annotations
  (handled by develop, write-features, test skills).
argument-hint: "{module}/{feature}" để extract, hoặc "--reverse {file_path}" để reverse trace
---

# Traceability — Extract + Query

Extract traceability matrix từ embedded `@trace` annotations. Output JSON cho visualization tools.

## Trace ID Format

```
@trace {module}/{feature}/{UC-ID}/{AC-ID}    — full trace
@trace {feature}/{UC-ID}/{AC-ID}             — short form (module obvious from context)
@jira {TICKET-ID}                            — JIRA metadata (optional, alongside @trace)
```

Hierarchy: Domain Module → Feature → UseCase → Acceptance Criteria

---

## Bước 1: Detect Mode

$ARGUMENTS

- Input chứa `--reverse` + file path → **REVERSE TRACE MODE**
- Input chứa `--coverage` → **COVERAGE MODE** (scan all)
- Input chứa module/feature path → **EXTRACT MODE**
- Input chứa JIRA ID → tìm module/feature từ @jira annotations → EXTRACT MODE

---

## Bước 2A: EXTRACT MODE — Generate Traceability Matrix

**Goal**: Extract tất cả @trace annotations cho 1 module/feature → JSON report

**Actions**:
1. Search codebase cho `@trace {input}`:
   - Feature files: `*.feature`
   - Source code: `*.cs`, `*.ts`, `*.dart`, `*.java`
   - Tests: `*.test.*`, `*.spec.*`, `*Tests.cs`
   - Step definitions: `*/step_definitions/**`
2. Parse mỗi annotation:
   - File path + line number
   - Artifact type (feature, code, unitTest, integrationTest, bddScenario, stepDefinition)
   - Full trace ID
   - JIRA metadata (nếu có @jira cùng block)
3. Group theo UC → AC hierarchy
4. Generate JSON output:

```json
{
  "module": "{module}",
  "feature": "{feature}",
  "jira": { "epic": "{EPIC-ID}", "subtasks": [...] },
  "useCases": [
    {
      "id": "UC-01",
      "name": "{extracted from feature file Rule: block}",
      "acceptanceCriteria": [
        {
          "id": "AC-01",
          "artifacts": {
            "feature": "{path}:{line}",
            "code": "{path}:{line}",
            "unitTest": "{path}:{line}",
            "bddScenario": "{path}:{line}",
            "stepDefinition": "{path}:{line}"
          }
        }
      ]
    }
  ],
  "coverage": {
    "useCases": "{covered}/{total}",
    "acceptanceCriteria": "{covered}/{total}",
    "gaps": [
      { "traceId": "{id}", "missing": ["unitTest", "bddScenario"] }
    ]
  },
  "generatedAt": "{ISO timestamp}"
}
```

5. Write JSON to `docs/traceability/{module}-{feature}.trace.json`
6. Print human-readable summary:

```
{module}/{feature} (JIRA: {EPIC-ID})
UC-01: {name} — {x}/{y} ACs covered {status}
UC-02: {name} — {x}/{y} ACs covered {status}
Coverage: {UCs}/{total} UCs, {ACs}/{total} ACs, {gaps} gaps
→ docs/traceability/{module}-{feature}.trace.json
```

---

## Bước 2B: REVERSE TRACE MODE — Impact Analysis

**Goal**: Cho 1 file, tìm tất cả requirements bị ảnh hưởng

**Actions**:
1. Đọc file, extract tất cả `@trace` annotations trong file
2. Cho mỗi trace ID found, search codebase tìm tất cả files cùng trace ID:
   - Feature files liên quan
   - Test files liên quan
   - Other code files liên quan
3. Output impact report:

```
Impact analysis for {file_path}:
Trace IDs found: {list}

Per trace ID:
  {module}/{feature}/{UC}/{AC}:
    Feature:  {path}:{line}
    Tests:    {path}:{line}, {path}:{line}
    Other:    {path}:{line}

Summary: {N} feature files, {N} test files, {N} BDD scenarios need review
```

---

## Bước 2C: COVERAGE MODE — Full Project Scan

**Goal**: Scan toàn bộ project cho trace coverage gaps

**Actions**:
1. Search tất cả `@trace` annotations trong project
2. Group theo module → feature → UC → AC
3. Cho mỗi trace ID, check có đủ artifacts:
   - Feature file (Rule: block) ✅/❌
   - Source code ✅/❌
   - Unit test ✅/❌
   - BDD scenario ✅/❌
4. Generate coverage report JSON: `docs/traceability/coverage-report.json`
5. Print gaps:

```
Traceability Coverage Report
=============================
sales/revenue-export: 4/4 ACs ✅
sales/invoice:        3/4 ACs ⚠️ (UC-02/AC-01 missing unit test)
inventory/stock:      2/3 ACs ⚠️ (UC-03 missing entirely)

Overall: 9/11 ACs fully covered (81%)
Gaps: 2 items need attention
→ docs/traceability/coverage-report.json
```

---

## Examples

**Example 1: Extract trace for feature**
User says: "/trace sales/revenue-export"
Actions: grep @trace → parse → group → generate JSON
Result: JSON file + console summary

**Example 2: Reverse trace**
User says: "/trace --reverse src/Services/RevenueExportService.cs"
Actions: read file → extract @trace → find related files
Result: Impact analysis showing affected features + tests

**Example 3: Coverage check**
User says: "/trace --coverage"
Actions: scan all → group → check completeness
Result: Coverage report with gaps highlighted

---

## Troubleshooting

**No @trace annotations found**: Project chưa adopt trace pattern. Suggest bắt đầu với /write-features để gen .feature files có @trace.
**Inconsistent trace IDs**: Check module/feature naming conventions. Run --coverage để tìm inconsistencies.
**Large project slow scan**: Limit scope bằng module/feature argument thay vì --coverage toàn project.
