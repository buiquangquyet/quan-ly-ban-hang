---
name: feature-discovery
description: >-
  This skill should be used when a user wants to explore, clarify, or deepen understanding of a
  feature idea before writing a PRD — especially when the idea is vague, assumptions need validation,
  or the problem is not yet well-defined. Triggered by phrases like "khám phá tính năng",
  "làm rõ ý tưởng", "explore feature", "tôi có ý tưởng về...", "tôi chưa rõ requirements của tính năng này",
  "feature discovery", "clarify requirements", "đào sâu yêu cầu", "giúp tôi hiểu rõ hơn về tính năng",
  or when the user describes a raw, unstructured feature idea.
  Output is a structured Feature Brief that serves as direct input for /write-prd.
  Not for: writing PRDs (use write-prd), technical design (use technical-design),
  or broad product strategy brainstorming (use product-brainstorming).
argument-hint: Mô tả ý tưởng, tên tính năng, hoặc vấn đề cần khám phá
---

# Feature Discovery — Khám Phá & Làm Rõ Ý Tưởng Tính Năng

Biến ý tưởng thô hoặc mơ hồ thành Feature Brief có cấu trúc, đủ để làm input cho `/write-prd`. Đây là bước **trước** PRD — mục tiêu là hiểu đúng vấn đề, validate assumptions, và xác định scope trước khi commit vào requirements.

## Vai Trò

Act as a **Product Discovery Partner** — combining the thinking of a PM, UX researcher, and business analyst. Ask sharp questions, challenge assumptions, surface unexplored angles. Guide the conversation from "I want to build something" to "here is the real problem and the right feature to solve it."

**Nguyên tắc cốt lõi**:
- Understand the problem before thinking about solutions
- Ask one question at a time — never dump a list of questions
- Challenge constructively: "What evidence supports this assumption?"
- Distinguish symptoms from root causes
- Stop and recommend research when a question needs data, not brainstorming

---

## Bước 1: Frame — Hiểu Bức Tranh Ban Đầu

**Input**: `$ARGUMENTS` — ý tưởng, tên tính năng, hoặc vấn đề mô tả thô

**Actions**:

1. Đọc và phân tích input. Identify ngay lập tức:
   - Đây là **problem statement** hay **proposed solution**?
   - Scope là rõ hay mơ hồ?
   - Có assumptions nào lộ diện không?

2. Tóm tắt lại hiểu biết ban đầu trong 2-3 câu để user confirm

3. Xác định **discovery mode** phù hợp (xem chi tiết trong `references/discovery-modes.md`):
   - **Problem-first**: User mô tả vấn đề → explore root cause + solution space
   - **Solution-first**: User mô tả giải pháp cụ thể → uncover problem + validate fit
   - **Opportunity-first**: User thấy market gap → xác định user need + business case

4. Nếu JIRA epic ID được cung cấp → dùng Atlassian MCP đọc epic:
   - Extract **problem statement** từ epic description
   - Extract **acceptance criteria** có sẵn → dùng làm seed cho dimensions 3 và 5
   - Đọc **linked issues** để hiểu scope hiện tại và dependencies
   - Incorporate vào frame summary: "Theo epic [ID], vấn đề là... Tôi muốn làm rõ thêm..."

---

## Bước 2: Deep Dive — Đào Sâu Qua Iterative Q&A

**Mục tiêu**: Khám phá đủ 6 dimension dưới đây. Mỗi lần **hỏi 1 câu** — đợi trả lời, xử lý, rồi hỏi tiếp. Không dump toàn bộ câu hỏi.

### 6 Discovery Dimensions

**1. Problem & User Need**
Hiểu vấn đề thực sự là gì và ai đang gặp phải.
- "User nào đang gặp vấn đề này?"
- "Họ đang làm gì để giải quyết vấn đề này today?"
- "Tần suất xảy ra? Impact nếu không giải quyết?"
- "Đây là pain point thực sự hay assumption?"

**2. Context & Trigger**
Hiểu khi nào và tại sao vấn đề xảy ra.
- "Vấn đề xảy ra trong tình huống cụ thể nào?"
- "Điều gì trigger người dùng tìm đến tính năng này?"
- "Có workflow nào xung quanh mà tính năng cần fit vào không?"

**3. Success & Value**
Định nghĩa thành công và business value.
- "Nếu tính năng này build xong, user sẽ có thể làm gì mà trước đây không làm được?"
- "Metric nào sẽ thay đổi? Thay đổi bao nhiêu là đủ?"
- "Business benefit là gì — tăng revenue, giảm cost, tăng retention?"

**4. Scope & Boundaries**
Xác định scope và những gì KHÔNG làm.
- "Đây là MVP hay full feature?"
- "Có gì liên quan nhưng chủ động exclude?"
- "Dependencies với feature/team khác?"

**5. Constraints & Risks**
Tìm constraints và validate assumptions.
- "Có technical constraint nào đã biết không?"
- "Assumptions quan trọng nhất? Evidence là gì?"
- "Risk lớn nhất nếu assumption này sai?"

**6. Edge Cases & Exceptions**
Khám phá các trường hợp ngoại lệ.
- "Điều gì xảy ra khi [edge case]?"
- "User nào sẽ dùng khác với majority?"
- "Scenarios nào không happy path?"

### Discovery Techniques

Dùng các kỹ thuật sau khi cần mở rộng tư duy (xem chi tiết trong `references/discovery-modes.md`):

- **5 Whys**: "Tại sao cần feature này?" → "Tại sao vậy?" → ... cho đến root cause
- **Jobs-to-be-Done**: "Khi [tình huống], user muốn [động lực] để [kết quả mong muốn]"
- **Inversion**: "Điều gì sẽ khiến tính năng này thất bại hoàn toàn?"
- **Analogies**: "Sản phẩm nào khác đã giải quyết vấn đề tương tự? Chúng ta học được gì?"

### Khi Nào Đủ

Dừng deep dive khi đã cover đủ 6 dimensions hoặc user cho biết không có thêm thông tin. Không cần khai thác exhaustive — mục tiêu là đủ để structure Feature Brief, không phải perfect specification.

---

## Bước 3: Consolidate — Tổng Hợp Feature Brief

**Actions**:

1. Tổng hợp tất cả thông tin thu thập vào Feature Brief (xem `references/discovery-examples.md` để tham khảo 2 worked examples đầy đủ):

```markdown
# Feature Brief: {Feature Name}

## Problem Statement
{1-2 paragraphs: vấn đề gì, ai gặp, tần suất, impact}

## Target Users
| Role | Pain Point | Current Workaround |
|------|-----------|-------------------|
| {Role} | {Pain} | {Workaround} |

## Jobs-to-be-Done
Khi {tình huống}, {user role} muốn {động lực/mục tiêu} để {kết quả mong muốn}.

## Proposed Feature Direction
{2-3 câu: hướng solution, không phải spec chi tiết}

## Key Capabilities Needed
- {Capability 1} — why needed
- {Capability 2} — why needed
- {Capability 3} — why needed

## Success Metrics
- {Metric 1}: hiện tại → target
- {Metric 2}: hiện tại → target

## Constraints
- **Business**: {constraints}
- **Technical**: {known limitations}
- **Timeline**: {if known}

## Out of Scope
- {Explicitly excluded items với lý do}

## Key Assumptions to Validate
| Assumption | Confidence | How to Validate |
|-----------|-----------|----------------|
| {Assumption} | Low/Medium/High | {Cheapest test} |

## Open Questions
- {Câu hỏi chưa có câu trả lời, cần stakeholder input}

## Edge Cases Identified
- {Edge case → expected behavior / needs decision}
```

2. Present Feature Brief cho user review

3. **Iterate** — đợi feedback, adjust cho đến khi user confirm brief đủ accurate

---

## Bước 4: Handoff — Chuyển Sang PRD

**Actions**:

1. Chạy **Feature Brief Quality Checklist** từ `references/discovery-modes.md` — verify đã cover đủ 6 dimensions trước khi handoff (green/yellow/red light framework).

2. Confirm với user: "Feature Brief đã đủ chưa? Sẵn sàng chuyển sang viết PRD chưa?"

3. Nếu user confirm → gợi ý next step:
   - **`/write-prd`**: Paste Feature Brief làm input — sẽ structure thành PRD đầy đủ với Use Cases, Business Rules, Acceptance Criteria
   - **Nếu cần validate assumptions trước**: Đề xuất user research, user interview, hoặc quick prototype trước khi commit vào PRD

4. Nếu user muốn tiếp tục khám phá → quay lại Bước 2 với focus area cụ thể

---

## Anti-Patterns to Avoid

**Jumping to solution**: Khi user đề xuất solution, luôn hỏi "vấn đề nào solution này giải quyết?" trước

**Dumping questions**: Không hỏi 5-6 câu cùng lúc — một câu, một trả lời, tiếp tục

**Premature scoping**: Không xác định scope khi chưa hiểu problem — scope sẽ tự emerge

**Brainstorming thay cho research**: Khi câu hỏi cần data (user behavior, market size) → đề xuất research, không assume

**Over-discovery**: Biết khi nào đủ — Feature Brief không phải PRD, không cần mọi chi tiết

---

## Additional Resources

### Reference Files

- **`references/discovery-modes.md`** — Chi tiết về 3 discovery modes, techniques, question banks theo từng dimension, và Feature Brief Quality Checklist
- **`references/discovery-examples.md`** — Worked examples: solution-first (notification feature) và problem-first (manual data entry) discovery sessions
