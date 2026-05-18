---
name: approve-prd
description: >
  Business approval gate for PRDs before JIRA decomposition and downstream development phases.
  Invoke this skill when the user wants to approve, sign off, or get stakeholder sign-off on a PRD,
  or when they say things like "approve PRD", "sign off PRD", "duyệt PRD", "xác nhận PRD",
  "PRD đã sẵn sàng chưa", "cho phép dev team làm", "chốt PRD", or "move to JIRA".
  Also trigger when the user finishes writing a PRD and asks "what's next" or "tiếp theo làm gì".
  This skill MUST run before /jira-sync when a PRD exists — it prevents unapproved PRDs from
  flowing into development. Always use this skill if there is even a 1% chance the user wants
  to approve or gate a PRD before the next phase.
---

# approve-prd

Skill này thực hiện **business approval gate** cho PRD — đảm bảo PRD đã đủ chất lượng và được stakeholder xác nhận trước khi decompose sang JIRA và bắt đầu các phase phát triển.

**Vị trí trong workflow**:
```
feature-discovery → write-prd → review-prd → [approve-prd] → jira-sync → write-features → develop
```

---

## Step 1: Xác định PRD cần approve

Xác định PRD từ argument hoặc ngữ cảnh:

| Argument | Hành động |
|----------|-----------|
| File path (`.md`) | Đọc file PRD trực tiếp |
| JIRA epic ID (e.g. `KV-100`) | Fetch epic description qua Atlassian MCP để lấy PRD link |
| Confluence URL | Fetch page content qua Atlassian MCP |
| Không có argument | Tìm file PRD gần nhất trong `docs/prd/` hoặc hỏi user |

Sau khi load được PRD:
1. Hiển thị tóm tắt PRD: Feature name, Feature Key, JIRA Epic, danh sách UC (chỉ ID + tên), số lượng Must/Should/Could Have
2. Xác nhận với user: "Đây có phải PRD bạn muốn approve không?"

---

## Step 2: Kiểm tra Quality Gate (review-prd)

Kiểm tra xem PRD đã chạy qua `/review-prd` chưa:

**Cách kiểm tra**: Tìm section `## Review Report` hoặc `## Approval Record` trong PRD file, hoặc hỏi user.

### Kết quả có thể xảy ra:

**A. Đã review — score >= 8.0 (READY FOR REVIEW)**
→ Tiếp tục sang Step 3 ngay. Hiển thị:
```
✅ Quality Gate: PASSED (score: X.X/10)
```

**B. Đã review — score 6.0–7.9 (NEEDS MINOR REVISION)**
→ Tiếp tục sang Step 3 nhưng cảnh báo:
```
⚠️  Quality Gate: CONDITIONAL (score: X.X/10 — có minor issues)
Có thể approve nhưng team cần xử lý các SUGGESTION trước khi dev bắt đầu.
```

**C. Đã review — BLOCKING issues hoặc score < 6.0**
→ Dừng lại, không tiếp tục:
```
🚫 Quality Gate: FAILED (score: X.X/10 — có BLOCKING issues)
PRD cần được sửa trước khi approve. Chạy /review-prd để xem chi tiết.
```
Đề xuất: Sửa PRD → `/review-prd` lại → quay lại `/approve-prd`

**D. Chưa chạy review-prd**
→ Cảnh báo và hỏi user có muốn tiếp tục không:
```
⚠️  PRD chưa qua quality gate (/review-prd).
Khuyến nghị chạy /review-prd trước để đảm bảo chất lượng.
Bạn vẫn muốn tiến hành approve trực tiếp không? (yes/no)
```
Nếu user đồng ý → Tiếp tục với cảnh báo rủi ro rõ ràng.

---

## Step 3: Business Approval Checklist

Trình bày checklist để user (PO/stakeholder) xác nhận từng mục. Đọc `references/approval-checklist.md` để có chi tiết đầy đủ cho mỗi dimension.

Trình bày checklist theo format sau — user trả lời `yes/no/n/a` cho từng mục, hoặc confirm tất cả cùng lúc:

```
📋 BUSINESS APPROVAL CHECKLIST — {Feature Name}

[1] BUSINESS VALUE
    □ Vấn đề được giải quyết rõ ràng và có impact đo lường được
    □ Lợi ích cho user/business được articulate rõ

[2] STAKEHOLDER ALIGNMENT
    □ Requirements đến từ đúng stakeholders
    □ Các team liên quan (tech, design, ops) đã được tham khảo
    □ Không có ambiguity về ai là owner của feature này

[3] SCOPE & PRIORITY
    □ Scope phù hợp với sprint/release capacity
    □ MoSCoW priority hợp lý (Must Have không bị over-committed)
    □ Out of Scope được explicitly định nghĩa

[4] FEASIBILITY
    □ Không có blocker kỹ thuật rõ ràng
    □ Dependencies với team/system khác đã được xác nhận
    □ Timeline realistic

[5] COMPLIANCE & RISK
    □ Các yêu cầu bảo mật, privacy, pháp lý được đề cập (hoặc N/A)
    □ Rủi ro chính đã được nhận diện

[6] SUCCESS METRICS
    □ Có ít nhất 1 KPI/success metric rõ ràng và đo được
    □ Acceptance criteria đủ cụ thể để verify sau khi ship
```

Cho phép user approve toàn bộ bằng một lệnh ("approve all" / "duyệt hết") hoặc note từng mục.

---

## Step 4: Ghi nhận quyết định

### Nếu APPROVED:

Thêm section sau vào cuối PRD file (`docs/prd/{feature-key}-prd.md`):

```markdown
---

## Approval Record

| Field | Value |
|-------|-------|
| **Status** | ✅ APPROVED |
| **Approved by** | {approver name — hỏi user nếu chưa biết} |
| **Approved at** | {ISO 8601 timestamp — e.g. 2026-04-08T09:30:00+07:00} |
| **Quality Gate** | {score}/10 — {verdict} |
| **Conditions** | {điều kiện nếu có, hoặc "None"} |
| **Notes** | {ghi chú bổ sung nếu có} |
```

Sau đó thực hiện các integration actions theo thứ tự:

**A. Update JIRA Epic** (nếu có Atlassian MCP và JIRA Epic ID):
- Add comment vào epic: `"✅ PRD Approved by {approver} on {date}. Ready for decomposition. PRD: {link}"`
- Thêm label `prd-approved` vào epic nếu có thể

**B. Publish/Update Confluence** (nếu có Atlassian MCP):
- Nếu chưa có Confluence page → tạo mới qua `/write-prd` publish flow
- Nếu đã có → update page với Approval Record section

**C. Thông báo kết quả**:
```
✅ PRD APPROVED — {Feature Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Approved by : {approver}
Approved at : {timestamp}
Quality Gate: {score}/10
Conditions  : {conditions or "None"}

📁 PRD file updated: docs/prd/{feature-key}-prd.md
🔗 JIRA Epic updated: {EPIC-ID} (comment added)
📄 Confluence: {page URL or "N/A"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 NEXT STEPS:

1. /jira-sync {EPIC-ID}      — Decompose epic thành [AI] sub-tasks
2. /write-features {prd-file} — Convert PRD ACs sang Gherkin .feature files
3. /team-three-amigos         — Three Amigos refinement session

Khuyến nghị: Chạy (1) và (2) song song.
```

### Nếu REJECTED:

```
🚫 PRD REJECTED — {Feature Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rejected by : {approver}
Reason      : {lý do từ user}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 NEXT STEPS:

1. /write-prd  — Sửa PRD theo feedback
2. /review-prd — Chạy lại quality gate
3. /approve-prd — Approve lại sau khi sửa
```

Thêm Rejection Record vào PRD file:

```markdown
## Rejection Record — {timestamp}

| Field | Value |
|-------|-------|
| **Status** | 🚫 REJECTED |
| **Rejected by** | {name} |
| **Rejected at** | {timestamp} |
| **Reason** | {reason} |
| **Action required** | {what needs to change} |
```

---

## Notes về MCP Integration

- **Atlassian MCP** (`mcp__claude_ai_Atlassian__authenticate`): Dùng để read/update JIRA epic và Confluence page
- Nếu không có MCP → chỉ update local file, thông báo user cần update JIRA/Confluence thủ công
- Không bao giờ block approval flow chỉ vì MCP unavailable

## Liên kết với các skill khác

| Skill | Quan hệ |
|-------|---------|
| `/write-prd` | Input — tạo PRD cần approve |
| `/review-prd` | Prerequisite — quality gate trước approve |
| `/feature-discovery` | Pre-PRD context nếu cần |
| `/jira-sync` | Next action sau approve |
| `/write-features` | Next action song song với jira-sync |
| `/team-three-amigos` | Refinement sau khi PRD approved |
