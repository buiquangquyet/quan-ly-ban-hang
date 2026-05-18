---
description: "Team Incident — parallel investigation (Grafana, ES, code, DB) → troubleshoot → RCA → fix → document"
argument-hint: <mô tả incident hoặc error message>
---

# Team Incident — Incident Response

Spawn team agents điều tra production incident song song qua nhiều data sources, tổng hợp evidence, phân tích root cause, fix và document.

**Flow**: Investigate → Troubleshoot → RCA Analysis → Fix → Document

**Yêu cầu**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## Context

Incident: $ARGUMENTS

---

## Phase 0: Triage

**Goal**: Đánh giá severity, quyết định team size. **Thời gian là yếu tố quan trọng nhất.**

1. Thu thập từ user (nếu chưa có trong $ARGUMENTS):
   - Error message / symptoms
   - Khi nào bắt đầu
   - Bao nhiêu users/services bị ảnh hưởng
   - Recent deploys: `git log --oneline -10`

2. Đánh giá severity:

| Severity | Mô tả | Team Size | Approach |
|----------|--------|-----------|----------|
| **Critical** | Service down, data loss, toàn bộ users | Full (4-5 agents) | Proceed fast, spawn tất cả investigators, minimal user gates |
| **High** | Service degraded, nhiều users | 3-4 agents | Core investigators + DB nếu có dấu hiệu |
| **Medium** | Partial impact, workaround available | 3 agents | Confirm scope trước khi investigate |
| **Low** | Minor issue, ít users | — | Gợi ý dùng `/respond-incident` (solo) thay vì team |

3. Tạo team `incident-<short-description>`.

---

## Phase 1: Investigate (Parallel)

**Goal**: Thu thập maximum evidence trong minimum time. Tất cả investigators chạy ĐỒNG THỜI.

Tạo tasks song song (no dependencies lẫn nhau):

| Task | Assignee | Agent Type | Data Source |
|------|----------|------------|-------------|
| `investigate-monitors` | Mã Lương (ma-luong) | `incident-investigator` | Grafana MCP |
| `investigate-logs` | Pháp Chính (phap-chinh) | `incident-investigator` | Elasticsearch MCP |
| `investigate-code` | Quan Vũ (quan-vu) | `code-explorer` | Codebase + Git |
| `investigate-db` (conditional) | Trình Dục (trinh-duc) | `db-engineer` | SQL Server |

Spawn cùng lúc:

**Mã Lương** — Grafana Data:
> Điều tra incident qua MONITORING DATA. Bạn là Mã Lương — Monitoring Expert. Dùng Grafana MCP.
>
> **Actions**:
> - Query dashboards cho error rate, latency, throughput trong timeframe incident
> - Check alert history — alerts nào fired?
> - Tìm resource utilization anomalies: CPU, memory, connections, disk
> - So sánh metrics trước và trong incident
>
> **Report**: Timeline of metric anomalies, affected services, severity indicators, dashboard references.

**Pháp Chính** — Elasticsearch Data:
> Điều tra incident qua LOG DATA. Bạn là Pháp Chính — Log Analyst Expert. Dùng Elasticsearch MCP.
>
> **Actions**:
> - Search logs theo timeframe + error level (ERROR, FATAL, WARN)
> - Tìm error patterns: exception types, stack traces, frequencies
> - Search correlation IDs nếu có — trace request flow
> - Aggregate errors by type, service, endpoint
> - Tìm first occurrence — khi nào lỗi bắt đầu chính xác
>
> **Report**: Top errors by frequency, sample stack traces, first occurrence timestamp, affected endpoints, user impact indicators.

**Quan Vũ** — Codebase & Deploy Analysis:
> Điều tra incident qua CODEBASE. Bạn là Quan Vũ — Technical Expert.
>
> **Actions**:
> - `git log --oneline -20` — recent deploys và changes
> - Nếu có error message/stack trace → trace execution path trong code
> - Xác định code changes liên quan (git diff với previous deploy)
> - Tìm error handling code — có catch đúng exceptions không?
> - Check configuration changes
>
> **Report**: Suspicious code paths với file:line references, recent commits có thể gây issue, code analysis.

**Trình Dục** (conditional — CHỈ spawn nếu symptoms suggest DB issues: timeouts, connection errors, deadlocks, slow queries):
> Điều tra incident qua DATABASE. Bạn là Trình Dục — Database Expert. Đọc `${CLAUDE_PLUGIN_ROOT}/skills/sqlserver-expert/references/performance.md` trước.
>
> **Actions**:
> - Check connection pool status — exhaustion?
> - Query `sys.dm_exec_requests` — blocking/waiting queries
> - Check deadlock history — `sys.dm_tran_locks`
> - Query `sys.dm_os_wait_stats` — top waits
> - Check replication lag nếu applicable
> - Identify slow queries trong timeframe incident
>
> **Report**: Database health indicators, problematic queries, resource bottlenecks, connection metrics.

---

## Phase 2: Troubleshoot

**Goal**: Tổng hợp evidence, correlate, build timeline, narrow down root cause.

Tạo task `troubleshoot` (depends on tất cả investigate tasks).

**Hoa Đà** (lead) thực hiện:

1. **Build Event Timeline** — chronological, correlate across data sources:
   ```
   14:15 — Deploy v2.3.1 (code-investigator)
   14:28 — Error rate tăng từ 0.1% → 5% (monitor-investigator)
   14:28 — NullReferenceException in OrderService (log-investigator)
   14:30 — DB connections tăng 50% (db-investigator)
   14:35 — Alert: Error rate > 10% fired
   ```

2. **Correlate Evidence** across investigators:
   - Metrics spike + error log + recent deploy = likely deploy-related
   - DB connection exhaustion + app timeouts + no deploy = likely DB/infra issue
   - Gradual degradation + no changes = likely load/resource issue

3. **Identify Patterns**:
   - Single service vs multiple services
   - Sudden failure vs gradual degradation
   - Deploy-correlated vs traffic-correlated vs external dependency

4. **Narrow to top 2-3 hypotheses** với confidence levels:
   | # | Hypothesis | Confidence | Evidence |
   |---|-----------|------------|----------|
   | 1 | [Most likely] | [0-100] | [Summary] |
   | 2 | [Alternative] | [0-100] | [Summary] |

5. **Present cho user**: timeline, evidence summary, hypotheses ranked.
   - Critical/High: recommend proceed với top hypothesis
   - Medium: hỏi user confirm hypothesis trước khi RCA

---

## Phase 3: RCA Analysis

**Goal**: Deep root cause analysis với evidence.

Tạo task `rca-analysis` (depends on troubleshoot).

1. **5 Whys** trên top hypothesis — mỗi "why" PHẢI có evidence:
   ```
   Why 1: Tại sao API trả 500? → NullReferenceException tại OrderService.cs:145 (log evidence)
   Why 2: Tại sao null? → Property 'Discount' null khi order không có discount (code evidence)
   Why 3: Tại sao không handle null? → Refactor remove null check trong commit abc123 (git evidence)
   Why 4: Tại sao refactor miss case này? → Không có test cover null discount case (test gap)
   → Root cause: Commit abc123 removed null check without regression test
   ```

2. **Phân biệt rõ**:
   - **Root Cause**: technical failure chính xác (với file:line hoặc infrastructure evidence)
   - **Contributing Factors**: conditions làm incident xảy ra hoặc tệ hơn (thiếu monitoring, no circuit breaker, missing test...)
   - **Symptoms**: những gì observe được (error messages, timeouts, alerts)

3. **Assess blast radius**: services, users, data affected

4. **Hỏi user confirm** root cause trước khi fix

---

## Phase 4: Fix

**Goal**: Two-fix strategy — immediate hotfix + permanent fix. User approval bắt buộc.

Tạo tasks sequential:

| Task | Dependencies | Assignee |
|------|-------------|----------|
| `propose-fixes` | rca-analysis | lead |
| `implement-fix` | propose-fixes + user approval | code-engineer |
| `review-fix` | implement-fix | Điêu Thuyền + code-reviewer |
| `verify-fix` | review-fix | test-engineer |

### Step 4.1: Propose Fixes

Present cho user 2 options:

**Immediate Hotfix** (fastest restore):
- What: [config change / rollback / feature flag / restart / workaround]
- Risk: [potential side effects]
- Trade-offs: [what it doesn't fix]
- Time: [estimated]

**Permanent Fix** (root cause):
- What: [code change, implementation approach]
- Files: [list files cần modify]
- Test plan: [tests cần viết/update]
- Time: [estimated]

**Hỏi user**: Apply immediate hotfix trước? Chờ permanent fix? Cả hai sequential?

### Step 4.2: Implement (3 Quality Gates)

Sau khi user approve:

**Gate 1**: Spawn **code-engineer** → implement chosen fix
**Gate 2**: Spawn **Điêu Thuyền** (code-reviewer, security focus) → review fix cho security + correctness
**Gate 3**: Spawn **test-engineer** → run tests, verify fix không break existing functionality

**User approve** trước khi commit: present diff, review findings, test results.

Commit: `fix(<scope>): <mô tả>` (thêm `[hotfix]` nếu immediate fix)

---

## Phase 5: Document

**Goal**: RCA report, JIRA action items, Confluence page.

Tạo task `document-incident` (depends on verify-fix).

### Step 5.1: Generate RCA Report

```markdown
## Incident: [Tiêu đề ngắn]

### Summary
- **Severity**: [Critical/High/Medium]
- **Impact**: [Users/services/data affected]
- **Duration**: [Start → Resolution]
- **Services affected**: [List]

### Timeline
| Time | Event | Source |
|------|-------|--------|
| [timestamp] | [event] | [monitor/log/code/db] |

### Root Cause
[Mô tả chính xác với evidence — file:line, log entry, metric]

### Contributing Factors
- [Factor 1 — tại sao enabled incident]
- [Factor 2]

### Resolution
- **Immediate fix**: [What was done, khi nào]
- **Permanent fix**: [What was done hoặc planned]

### Prevention — Action Items
- [ ] [Action 1 — cụ thể, assignable]
- [ ] [Action 2]
- [ ] [Action 3]

### Lessons Learned
- **What worked well**: [trong incident response]
- **What to improve**: [process gaps]
```

### Step 5.2: Atlassian Integration (nếu MCP available)

1. **JIRA Action Items**: Dùng `createJiraIssue` tạo ticket cho mỗi prevention action item
2. **Link Incident**: Dùng `createIssueLink` link action items với incident ticket (nếu có)
3. **Confluence RCA Page**: Dùng `createConfluencePage` publish RCA report

Nếu Atlassian MCP không available → output RCA report dạng markdown cho user copy.

### Step 5.3: Cleanup

1. Update runbooks nếu incident revealed gaps
2. Shutdown team
3. Summary cho user: RCA location, action items created, next steps

---

## Coordination Rules

- **Hoa Đà là lead** — PST expertise, focus tốc độ và chính xác
- Phase 1: investigators SONG SONG, READ-ONLY, mỗi agent focus 1 data source
- Phase 2-3: lead synthesize, không delegate
- Phase 4: sequential quality gates — implement → review → test → user approve
- **Evidence-based**: mọi claim phải có file:line, log entry, hoặc metric reference
- **User gates**: confirm hypothesis (Phase 2-3), approve fix (Phase 4)
- Critical severity: minimize gates, proceed fast

## Examples

**Example 1: API 500 surge sau deploy**
```
/team-incident Production API 500 errors tăng vọt từ 2:30pm, nhiều customers complain
```
→ Triage: Critical
→ Investigate (4 agents): Grafana error spike, ES NullRef in OrderService, git deploy 2:15pm, DB normal
→ Troubleshoot: correlate deploy + error → hypothesis: null check removed in refactor
→ RCA: 5 Whys → commit abc123 removed null check, no test coverage
→ Fix: hotfix (add null check) → review → test → commit
→ Document: RCA report + 3 JIRA items (add test, add null validation, update deploy checklist)

**Example 2: Service timeout leo thang**
```
/team-incident Response time tăng dần từ sáng, giờ bắt đầu timeout
```
→ Triage: High (degrading, not yet down)
→ Investigate: Grafana latency climb, ES timeout errors + connection warnings, no deploys, DB pool exhausted
→ Troubleshoot: no deploy, DB connection leak correlates batch job schedule
→ RCA: batch job không dispose connections → pool exhaustion → app timeout
→ Fix: immediate (restart + limit batch concurrency), permanent (fix disposal pattern)
→ Document: RCA + runbook update for connection pool monitoring

## Troubleshooting

- **Grafana MCP không available**: Hỏi user cung cấp metrics/screenshots manually
- **Elasticsearch MCP không available**: Hỏi user paste relevant log entries
- **Không tìm được root cause**: Mở rộng scope — infrastructure, external dependencies, traffic patterns. Dùng 5 Whys với broader hypothesis
- **Investigators conflict (evidence mâu thuẫn)**: Lead hỏi specific investigators deep dive vào targeted area
- **User không approve fix**: Document findings, tạo JIRA ticket cho follow-up, cleanup team
- **DB-related nhưng không có db-engineer agent**: Lead investigate DB manually, hoặc spawn code-explorer với DB focus
