# Documentation Templates

Mỗi template follow 5 principles: Write for the reader, Lede first, Show don't tell, Keep current, Link don't duplicate.

---

## README Template

Reader: developer mới join project hoặc cần overview nhanh.

```markdown
# [Project Name]

[1-2 câu: project làm gì, cho ai — đây là thông tin quan trọng nhất, đặt đầu tiên]

## Quick Start

[Commands copy-paste được — show, don't tell]

​```bash
git clone [repo-url]
cd [project]
[install command]
[run command]
​```

## Architecture

[1 đoạn ngắn hoặc diagram — link đến docs/architecture.md nếu cần chi tiết]

## Development

​```bash
[build command]
[test command]
[lint command]
​```

## Key Concepts

[3-5 bullet points về concepts cần biết — link đến docs chi tiết thay vì giải thích dài]

- [Concept 1] — [1 dòng mô tả]. See [docs/concept-1.md]
- [Concept 2] — [1 dòng mô tả]. See [docs/concept-2.md]

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `VAR_NAME` | [Mô tả] | `value` |

## Contributing

[Link đến CONTRIBUTING.md — don't duplicate]
```

---

## Architecture Doc Template

Reader: developer cần hiểu system design để sửa code hoặc thêm feature.

```markdown
# Architecture — [System/Service Name]

## Overview

[2-3 câu: system này làm gì, vị trí trong tổng thể — lede first]

## System Diagram

[ASCII diagram hoặc link đến diagram file — show, don't tell]

​```
[Client] → [API Gateway] → [Service A] → [Database]
                         → [Service B] → [Message Queue] → [Service C]
​```

## Components

### [Component Name]
- **Responsibility**: [1 dòng]
- **Tech**: [framework/library]
- **Entry point**: `path/to/main/file` — [link, don't duplicate code]

### [Component Name]
- **Responsibility**: [1 dòng]
- **Tech**: [framework/library]
- **Entry point**: `path/to/main/file`

## Data Flow

[Mô tả flow chính qua system — dùng numbered steps]

1. Client sends request to [endpoint]
2. [Service A] validates and processes
3. Result saved to [database]
4. Event published to [queue]
5. [Service C] consumes and [action]

## Key Decisions

[Link đến ADRs thay vì giải thích lại — link, don't duplicate]

- Why [technology]? → See ADR-001
- Why [pattern]? → See ADR-002

## Constraints & Trade-offs

- [Constraint 1 — và tại sao]
- [Trade-off 1 — và decision rationale]
```

---

## Onboarding Guide Template

Reader: developer ngày đầu — cần setup môi trường và chạy được project.

```markdown
# Onboarding Guide — [Project Name]

Goal: từ zero đến chạy được project trong [X phút/giờ].

## Prerequisites

[Liệt kê chính xác — show versions, show install commands]

​```bash
# Check prerequisites
node --version   # >= 18.x
docker --version # >= 24.x
​```

[Link đến install guides nếu cần — don't duplicate install instructions]

## Step 1: Clone & Install

​```bash
git clone [repo-url]
cd [project]
[install command]
​```

## Step 2: Environment Setup

​```bash
cp .env.example .env
# Edit .env — set these values:
# DATABASE_URL=...
# API_KEY=...
​```

[Giải thích cách lấy credentials — show exactly where/how]

## Step 3: Run

​```bash
[run command]
# Open http://localhost:[port]
​```

## Step 4: Verify

[How to know it's working — show expected output]

​```bash
[test or health-check command]
# Expected: "All tests passed" or "200 OK"
​```

## Common Issues

| Symptom | Fix |
|---------|-----|
| [Error message] | [Exact fix command] |
| [Error message] | [Exact fix command] |

## Next Steps

- Read [architecture doc] to understand the system
- Check [CONTRIBUTING.md] for workflow
- Ask [#channel] if stuck
```

---

## ADR (Architecture Decision Record) Template

```markdown
# ADR-[number]: [Title]

**Date**: YYYY-MM-DD
**Status**: Proposed / Accepted / Deprecated / Superseded by ADR-XXX

## Context
[Tại sao cần quyết định này? Problem statement — lede first]

## Decision
[Quyết định là gì? 1-2 câu clear]

## Consequences
- **Positive**: [Lợi ích cụ thể]
- **Negative**: [Trade-offs cụ thể]
```

---

## Inline Comments

Chỉ comment khi code không self-explanatory. Explain **WHY**, not **WHAT**.

```
// WHY: Retry 3 times because payment gateway has 2% transient failure rate
// Workaround for KV-123: API returns 200 with error in body instead of 4xx
// Performance: batch insert instead of loop — 10x faster for >100 records
```
