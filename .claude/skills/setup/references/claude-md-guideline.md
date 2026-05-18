# Guideline: Viết CLAUDE.md Đúng Cách

> Tổng hợp best practices từ HumanLayer, research về instruction-following của LLM,
> và kinh nghiệm thực tế optimize CLAUDE.md cho nhiều loại project (.NET, TypeScript, BDD/ATDD).

---

## 1. Hiểu bản chất CLAUDE.md

CLAUDE.md là file duy nhất được **tự động inject vào MỌI session** của Claude Code.
Nó đóng vai trò **onboarding** — giống như bạn onboard một developer mới vào team.

LLM là **stateless** — mỗi session mới, Claude không biết gì về codebase.
CLAUDE.md là cách duy nhất để "dạy" Claude ngay từ đầu.

Claude Code wrap nội dung CLAUDE.md với system reminder:

> "IMPORTANT: this context may or may not be relevant to your tasks.
> You should not respond to this context unless it is highly relevant to your task."

Nghĩa là Claude được **khuyến khích bỏ qua** nội dung không liên quan đến task hiện tại.
Càng nhiều noise → càng cao khả năng Claude **bỏ qua tất cả**, kể cả phần quan trọng.

---

## 2. Sáu nguyên tắc cốt lõi

### Nguyên tắc 1: Nội dung WHAT - WHY - HOW

CLAUDE.md phải trả lời 3 câu hỏi:

| Câu hỏi | Nội dung | Ví dụ |
|----------|----------|-------|
| **WHAT** | Tech stack, project structure, module map | ".NET 8, SQL Server, Kafka, Hexagonal Architecture" |
| **WHY** | Mục đích project, business context | "Hệ thống hóa đơn điện tử cho doanh nghiệp VN" |
| **HOW** | Build, test, run commands | `dotnet build`, `npm run test`, `docker compose up` |

### Nguyên tắc 2: Less Is More

**Research cho thấy:**
- Frontier LLM follow được ~150-200 instructions ổn định
- System prompt của Claude Code đã chiếm ~50 instructions
- Khi instruction tăng, chất lượng follow giảm **đồng đều** (không chỉ bỏ instruction cuối)
- Model nhỏ (Haiku) suy giảm theo hàm mũ, model lớn (Opus) suy giảm tuyến tính

**Target:**
- Dưới 300 dòng (hard limit)
- Dưới 100 dòng (ideal)
- Dưới 60 dòng (best-in-class)
- Ước tính dưới 20 individual instructions

### Nguyên tắc 3: Universally Applicable Only

Vì CLAUDE.md đi vào **mọi session**, chỉ đưa nội dung đúng cho **mọi task**.

**Câu hỏi kiểm tra:** "Nếu Claude đang làm task KHÁC, dòng này có gây nhiễu không?"

| ✅ Universal — giữ trong CLAUDE.md | ❌ Task-specific — tách ra agent_docs/ |
|-------------------------------------|---------------------------------------|
| Build / test / run commands | Database schema conventions |
| Project structure overview | Docker multi-stage build steps |
| Tech stack summary | API error code mapping table |
| Top 3-5 critical rules | Coding style guide chi tiết |
| Danh mục trỏ tới agent_docs/ | Feature file template mẫu |

### Nguyên tắc 4: Progressive Disclosure

Thay vì nhồi mọi thứ vào CLAUDE.md, tách task-specific content ra thư mục riêng:

```
project-root/
├── CLAUDE.md                          # 50-80 dòng, universal
└── agent_docs/
    ├── architecture-patterns.md       # Khi tạo service, module mới
    ├── domain-rules.md                # Khi làm business logic
    ├── testing-guide.md               # Khi viết test
    ├── api-conventions.md             # Khi tạo API endpoint
    ├── database-guidelines.md         # Khi viết SQL, migration
    └── docker-guidelines.md           # Khi tạo/sửa Dockerfile
```

Trong CLAUDE.md, liệt kê với **mô tả ngắn + trigger condition**:

```markdown
## Docs (read when relevant to your task)

- Architecture patterns & DDD conventions → agent_docs/architecture-patterns.md
- Domain rules (accounting, ledger, money) → agent_docs/domain-rules.md
- Testing guide & test patterns → agent_docs/testing-guide.md
```

Mỗi file agent_docs mở đầu bằng trigger:

```markdown
# Domain Rules
> Read this when working on business logic, accounting, or financial transactions.
```

Claude sẽ tự đọc file relevant dựa trên task hiện tại.

### Nguyên tắc 5: Pointers, Not Copies

**Không copy code vào CLAUDE.md hoặc agent_docs.** Code snippets sẽ out-of-date nhanh chóng.

| ❌ Copy (sẽ lỗi thời) | ✅ Pointer (luôn chính xác) |
|------------------------|----------------------------|
| Paste cả class Controller mẫu | "Reference: search for existing controllers in `src/Presentation/`" |
| Paste feature file template | "See example: `features/modules/customer/customer-list.feature`" |
| Paste Docker multi-stage build | "Reference: `Dockerfile.OperationApi` for the established pattern" |

**Ngoại lệ:** Bash commands (build, test, run) NÊN copy trực tiếp vì chúng ngắn và ít thay đổi.

### Nguyên tắc 6: Đừng Biến Claude Thành Linter

LLM chậm, đắt, non-deterministic. Linter nhanh, rẻ, deterministic.

**Không nên đưa vào CLAUDE.md:**
- Naming conventions chi tiết (PascalCase, camelCase...)
- Code style rules (max line length, bracket placement...)
- SOLID principles (SRP, OCP, DIP...)
- Code smell thresholds (method > 50 dòng, class > 500 dòng...)
- Anti-patterns chung chung (DRY, YAGNI, KISS...)

**Thay thế bằng:**
- Cấu hình linter/formatter (ESLint, Biome, .editorconfig, StyleCop)
- Claude Code Hook (Stop hook chạy linter sau mỗi thay đổi)
- Slash Command để check formatting riêng biệt

**Tại sao?** LLM là in-context learner — nếu codebase đã follow convention nhất quán,
Claude sẽ tự học theo khi search code mà không cần nói.

---

## 3. Những gì KHÔNG nên đưa vào CLAUDE.md

### Kiến thức chung mà LLM đã biết

```markdown
# ❌ KHÔNG CẦN — Claude đã biết rồi
- "Single Responsibility Principle: Each class should have one reason to change"
- "Use async/await for I/O operations"
- "Validate all inputs"
- "Use parameterized queries to prevent SQL injection"
- "Design for horizontal scaling"
```

Những thứ này nằm trong training data của Claude. Đưa vào chỉ tốn instruction budget.

### Checklist hành vi chung

```markdown
# ❌ KHÔNG CẦN — Đây là hành vi mặc định
- "LUÔN viết code hoàn chỉnh, KHÔNG có placeholder"
- "Include đầy đủ error handling"
- "Add XML documentation comments"
- "Khi debug, analyze stack trace thoroughly"
- "Khi review, check test coverage"
```

### Coding conventions phổ biến

```markdown
# ❌ KHÔNG CẦN — Dùng linter thay thế
- "PascalCase cho classes, camelCase cho variables"
- "Methods > 50 dòng: refactor"
- "Cyclomatic complexity > 10: simplify"
```

### Nguyên tắc đánh giá: Nếu nó đúng cho MỌI .NET project, không cần nói

Rule of thumb: nếu instruction không chứa thông tin **specific cho project của bạn**,
nó không nên nằm trong CLAUDE.md. Claude đã biết best practices chung rồi.

---

## 4. Template CLAUDE.md

```markdown
# [Project Name]

[1-2 câu mô tả: project làm gì, cho ai, business context chính]
[Tech stack tóm tắt trong 1-2 dòng]

## Project Structure

[ASCII tree của top-level folders với comment ngắn mỗi folder]
[Chỉ cần 2-3 levels deep, focus vào navigation]

## Commands

[Block duy nhất chứa build, test, run, lint commands]
[Đây là phần được dùng nhiều nhất — đặt gần đầu file]

## Critical Rules

[3-7 rules dạng 1 dòng, SPECIFIC cho project]
[Chỉ giữ rules mà nếu vi phạm sẽ gây bug hoặc break architecture]
[Mỗi rule phải pass bài test: "Đúng cho mọi task trong project này?"]

## Existing Skills

[Liệt kê Claude Code skills relevant cho project]

## Docs (read when relevant to your task)

[Danh mục agent_docs/ với mô tả 1 dòng mỗi file]
[Format: "Khi nào cần → file nào"]
```

---

## 5. Template agent_docs/ file

```markdown
# [Topic Name]

> Read this when [trigger condition mô tả cụ thể khi nào cần đọc file này].

## [Section 1]

[Nội dung ngắn gọn, actionable]
[Reference: `path/to/actual/file.cs` cho patterns]

## [Section 2]

[Nội dung...]
[Reference: search for existing examples in `src/some-folder/`]
```

**Nguyên tắc cho agent_docs:**
- Mỗi file dưới 60 dòng
- Mở đầu bằng trigger condition (dòng `> Read this when...`)
- Dùng pointers thay copies
- Không trùng lặp nội dung giữa các file
- Tên file self-descriptive: `writing-features.md` không phải `guide-01.md`

---

## 6. Checklist đánh giá CLAUDE.md

Dùng checklist này để review file CLAUDE.md đã viết:

**Độ dài & Instructions:**
- [ ] Dưới 100 dòng?
- [ ] Ước tính dưới 20 individual instructions?
- [ ] Không có code snippet dài (trừ bash commands)?

**Nội dung:**
- [ ] Có WHAT (tech stack, structure)?
- [ ] Có WHY (mục đích project)?
- [ ] Có HOW (build/test/run commands)?
- [ ] Mọi dòng đều universal — đúng cho mọi task?

**Không chứa noise:**
- [ ] Không có kiến thức chung LLM đã biết (SOLID, async/await...)?
- [ ] Không có coding conventions (dùng linter thay thế)?
- [ ] Không có checklist hành vi mặc định?
- [ ] Không có code snippets dài sẽ out-of-date?

**Progressive Disclosure:**
- [ ] Task-specific content tách ra agent_docs/?
- [ ] Mỗi agent_docs file có trigger condition?
- [ ] CLAUDE.md có danh mục trỏ tới agent_docs/ với mô tả ngắn?

**Pointers:**
- [ ] Trỏ tới file thực tế thay vì copy code?
- [ ] Dùng "Reference: ..." hoặc "See example: ..."?

**Leverage:**
- [ ] Không auto-generated (đã review từng dòng)?
- [ ] Mỗi dòng đều có lý do tồn tại rõ ràng?

---

## 7. Ví dụ thực tế: Before vs After

### Before (~130 dòng, nhiều vấn đề)

```markdown
## Coding Conventions
- PascalCase cho classes
- camelCase cho variables
- _camelCase cho private fields
...20 dòng naming rules...

## Important Principles
- Single Responsibility Principle
- Dependency Inversion Principle
- Open/Closed Principle
- DRY, YAGNI, KISS
...15 dòng principles...

## Anti-Patterns
- KHÔNG tạo placeholder code
- KHÔNG trả về null
- Methods > 50 dòng: refactor
...10 dòng anti-patterns...

## Claude-Specific Instructions
- Khi generate code: viết hoàn chỉnh, có error handling
- Khi review: check conventions, test coverage
- Khi debug: analyze stack trace
...15 dòng instructions...
```

**Vấn đề:** ~60 instructions chỉ riêng phần này, tất cả là kiến thức chung
LLM đã biết hoặc nên dùng linter. Chiếm 40% instruction budget mà không
thêm giá trị nào.

### After (~50 dòng, focused)

```markdown
# KAT

Tax declaration & accounting system for Vietnamese businesses.
.NET 8.0, DDD modular monolith, SQL Server sharding, Kafka integration.

## Project Structure
[Focused ASCII tree]

## Commands
dotnet build Kat.HB.Core.sln
dotnet test
dotnet run --project src/Presentation/CoreApi/CoreApi.csproj
docker-compose up -d

## Critical Rules
- Domain logic in Aggregates only — not in Application Services
- Always resolve MerchantContext before any data access
- Cache idempotency via Redis using message_id from Kafka headers
- Use IShardingService for tenant DB routing — never hardcode connection strings
- Domain events via Outbox pattern — never publish directly to Kafka

## Docs (read when relevant to your task)
- DDD patterns & aggregate rules → agent_docs/ddd-patterns.md
- Kafka message types & handlers → agent_docs/kafka-integration.md
- Database sharding & multi-tenancy → agent_docs/sharding-guide.md
- Tax declaration domain rules → agent_docs/tax-domain.md
```

**Cải thiện:** ~15 instructions, tất cả specific cho project, mọi thứ universal.
Claude biết PascalCase và SOLID rồi — không cần dạy lại.
