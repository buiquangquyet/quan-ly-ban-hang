---
name: refactor
description: >-
  Refactor legacy/messy code an toàn — phân tích code smells, chọn technique phù hợp,
  refactor incremental với test verification tại mỗi bước. Dùng khi user muốn clean up code,
  fix code smells, simplify complex methods, giảm coupling. Trigger: "refactor",
  "clean up code", "simplify", "fix code smells", "reduce complexity", "code này lớn quá",
  "technical debt", "tối ưu code", "extract class", "split method", "decompose", "break up". Do NOT use for code review without modification
  (use review), writing new features (use develop), hoặc test-only changes (use test).
argument-hint: "File hoặc module cần refactor"
---

# Refactor — Legacy Code Improvement

Refactor legacy code an toàn — từng bước nhỏ có test verification, đảm bảo behavior không đổi trong khi cải thiện internal structure.

## References

- Catalog 22 code smells theo 5 categories: xem `references/code-smells.md`
- Refactoring techniques chi tiết: xem `references/refactoring-techniques.md`
- Decision guide và safety rules: xem `references/quick-decision-guide.md`

## Nguyên tắc

- **Giữ nguyên external behavior** — thay đổi behavior trong lúc refactor mixes hai concerns, gây bugs khó trace
- **Incremental** — từng bước nhỏ, mỗi bước verifiable. Bước lớn fail → khó biết lỗi ở đâu
- **Test-backed** — refactoring không có tests risks breaking behavior âm thầm
- **Dùng TodoWrite** — structured tracking persist across steps, giúp user theo dõi tiến độ

---

## Bước 1: Assess

Yêu cầu: $ARGUMENTS

**Actions**:
1. Tạo todo list
2. **Safety gate**: Code cần rewrite? Deadline gấp? Đang deprecation? → thông báo user, không refactor
3. Launch **code-explorer** agent phân tích code. Include `references/code-smells.md` vào prompt để scan structured theo 5 categories
4. Nếu target code là stored procedures, complex queries, hoặc database access layer → launch thêm **db-engineer** agent đánh giá database-specific smells (missing indexes, N+1 patterns, implicit conversions, deadlock-prone transactions) với `sqlserver-expert` references
5. Present: smells found (by category + severity), dependencies, test coverage, risk

---

## Bước 2: Ensure Test Coverage

Đảm bảo tests cover behavior trước khi refactor — refactoring without tests risks breaking silently.

**Actions**:
1. Nếu đủ tests → tiếp Bước 3
2. Nếu thiếu → viết characterization tests capture behavior hiện tại
3. Run full test suite → establish GREEN baseline

---

## Bước 3: Plan Refactoring

**Actions**:
1. Đọc `references/refactoring-techniques.md` và `references/quick-decision-guide.md`
2. Map mỗi smell → technique phù hợp
3. Prioritize: Change Preventers > Couplers > Bloaters > OO Abusers > Dispensables
4. Chia thành steps nhỏ, mỗi step commit-worthy:

   | # | Smell | Technique | Risk |
   |---|-------|-----------|------|
   | 1 | ... | ... | Low/Med/High |

5. Present plan, **đợi user approve**

---

## Bước 4: Execute

Đợi user approve trước — refactoring sai hướng có thể introduce bugs.

**Actions**:
1. Với mỗi step, launch **code-refactorer** agent với technique details từ references
2. Sau mỗi step: run tests → phải GREEN. Nếu FAIL → rollback, investigate
3. Update todos sau mỗi step

---

## Bước 5: Review & Commit

**Actions**:
1. Launch **code-reviewer** agent verify behavior preservation (API contracts, side effects, error handling, performance)
2. Present: before/after comparison, smells eliminated, metrics, test results
3. Hỏi user proceed to commit hay adjust
4. Commit với `/commit` skill

---

## Examples

**Example 1: Class quá lớn**
User says: "Refactor OrderService 800 dòng"
Actions:
1. Assess: Large Class, Long Methods, Feature Envy (scan với code-smells catalog)
2. Ensure tests: 12 existing tests, thêm 3 characterization tests
3. Plan: Extract Class → OrderValidator, OrderCalculator, OrderNotifier
4. Execute: 3 incremental steps, tests GREEN sau mỗi step
5. Review: behavior preserved, API contracts unchanged
Result: 800 → 200 lines, 3 focused services, all GREEN

**Example 2: Complex method**
User says: "Simplify calculateDiscount quá nhiều if/else"
Actions:
1. Assess: Switch Statements, deep nesting
2. Plan: Strategy Pattern — mỗi discount type = 1 strategy
3. Execute: extract strategies incremental
4. Review: same outputs, cleaner dispatch
Result: 50 lines nested if/else → 15 lines clean dispatch

## Troubleshooting

**Tests fail sau refactoring**: Rollback step cuối, review technique, thử approach nhỏ hơn
**Không có tests**: Viết characterization tests trước (Bước 2)
**User không approve plan**: Đề xuất approach conservative hơn, chia nhỏ scope
