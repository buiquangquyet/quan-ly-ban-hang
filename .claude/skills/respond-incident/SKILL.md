---
name: respond-incident
description: >-
  Incident response workflow — triage severity, investigate root cause bằng monitoring data
  (Grafana, Elasticsearch), đề xuất hotfix + permanent fix, tạo RCA report. Dùng khi có
  production incident, service outage, error spike, hoặc cần điều tra lỗi production.
  Trigger: "production down", "service lỗi", "error rate tăng", "investigate incident",
  "tạo RCA", "postmortem", "hotfix production", "incident". Do NOT use for general bug
  fixing during development (use fix-bug), code review (use review), hoặc writing tests
  (use test).
argument-hint: "Mô tả incident hoặc error message"
---

# Incident Response

Incident response workflow. **Thời gian là yếu tố quan trọng nhất** — ưu tiên tốc độ và chính xác.

## Bước 1: Triage

Thông tin incident: $ARGUMENTS

**Actions**:
1. Thu thập từ user: error message, khi nào bắt đầu, deploy gần đây (`git log --oneline -10`), bao nhiêu users bị ảnh hưởng
2. Đánh giá severity:

| Level | Mô tả | Action |
|-------|--------|--------|
| **Critical** | Service down, data loss, toàn bộ users | Immediate |
| **High** | Service degraded, nhiều users | Priority |
| **Medium** | Partial impact, workaround available | Normal |
| **Low** | Minor issue, ít users | Scheduled |

---

## Bước 2: Investigate

**Actions** (song song — chạy parallel để giảm MTTR, vì thời gian downtime = business impact):
1. Dùng **Grafana MCP** query dashboards: metrics, alerts, error rates
2. Dùng **Elasticsearch MCP** search logs theo timeframe và error pattern
3. Dùng **Atlassian MCP** tìm incidents tương tự đã xử lý
4. Launch **code-explorer** agent trace error path trong codebase
5. Nếu incident liên quan database (connection pool exhaustion, deadlocks, query timeouts, replication lag) → launch thêm **db-engineer** agent với `sqlserver-expert/references/performance.md` điều tra database-specific root cause
6. Đọc files agents xác định

---

## Bước 3: Root Cause Analysis

**Actions**:
1. Xác định: root cause (với evidence file:line), contributing factors, timeline
2. Dùng 5 Whys nếu root cause chưa rõ

---

## Bước 4: Propose Fix

**Actions**:
1. Đề xuất 2 loại fix — tách immediate (khôi phục nhanh) và permanent (fix root cause) để user chọn trade-off giữa speed và thoroughness:
   - **Immediate** (hotfix/workaround): nhanh nhất để khôi phục, trade-offs, risk
   - **Permanent** (long-term): root cause, implementation detail, test plan
2. **Hỏi user**: apply immediate trước hay chờ permanent?

---

## Bước 5: Apply Fix (nếu user chọn)

1. Implement fix
2. Launch **code-reviewer** agent review
3. Run tests verify không break
4. Commit `fix(<scope>): <mô tả>`

---

## Bước 6: RCA Report

Tạo RCA report: summary, impact (users/services/data), timeline, root cause, contributing factors, resolution (immediate + permanent), prevention action items, lessons learned.

Tạo JIRA action items nếu có Atlassian MCP: dùng create issue function cho mỗi action item, link với incident ticket.

---

## Examples

**Example 1: API 500 errors**
User says: "Production API trả 500 từ 2pm"
Actions:
1. Triage: High — nhiều users bị ảnh hưởng
2. Investigate: Grafana error spike, ES logs → NullReferenceException
3. Correlate: deploy 1:45pm → null check thiếu sau schema change
4. Fix: hotfix (add null check) + permanent (add validation layer)
5. RCA report + JIRA action items
Result: Service restored 30 min, RCA documented

**Example 2: DB connection exhaustion**
User says: "Service chậm dần rồi timeout"
Actions:
1. Triage: Critical — service down
2. Grafana: connection pool exhausted
3. Root cause: connection leak trong batch job
4. Immediate: restart service + limit batch concurrency
5. Permanent: fix connection disposal pattern
Result: Service restored, prevention in place

## Troubleshooting

**MCP không available**: Kiểm tra `.mcp.json`, env vars. Nếu không có → hỏi user cung cấp logs/metrics manually
**Không tìm được root cause**: 5 Whys, mở rộng scope sang infrastructure, kiểm tra all related services
**Reference files trống**: Hỏi user mô tả architecture, services, tech stack
