# Shared Conventions

Coding standards áp dụng chung cho tất cả services trong workspace.
Chi tiết từng service xem thêm `CLAUDE.md` trong submodule tương ứng.

---

## PHP / Laravel (shipping-api, shipping-cpanel, shipping-cron, shipping-report)

**Stack:** Laravel PHP 7.3, Eloquent ORM, Artisan, Laravel Queue

### Naming
- **Classes:** `PascalCase`
- **Methods / Variables:** `camelCase`
- **DB tables / columns:** `snake_case`
- **Routes:** `kebab-case`
- **Config keys / env vars:** `SCREAMING_SNAKE_CASE`

### Architecture
```
app/
├── Http/
│   ├── Controllers/    # Nhận request, validate, gọi Service/Action
│   └── Middleware/
├── Models/             # Eloquent models
├── Services/           # Business logic
├── Jobs/               # Queue jobs (async)
├── Events/ Listeners/  # Laravel Events
└── Console/Commands/   # Artisan commands (dùng trong shipping-cron)
```

### Patterns
- **Controllers** — chỉ validate input, gọi Service, trả response; không chứa business logic
- **Eloquent** — cho write operations; raw Query Builder / DB facade cho read phức tạp
- **Queue Jobs** — cho tác vụ async (email, webhook, sync carrier)
- **Kafka produce** — publish event sau khi commit DB, theo Outbox pattern (xem `data-flows.md`)

### Anti-patterns (TRÁNH)
- Business logic trong Controller
- Query N+1 (dùng `with()` eager loading)
- Gọi carrier API trực tiếp trong Controller (bọc qua Service)

---

## Go (shipping-merchant, kship-golang-check-price, kship-golang-add-on, shipping-report-v5)

**Stack:** Go 1.21–1.24, Gin, GORM (report-v5), gRPC, OpenTelemetry

### Naming
- **Exported (public):** `PascalCase`
- **Unexported (private):** `camelCase`
- **Packages:** `lowercase`, ngắn gọn, không dùng `_`
- **Interfaces:** mô tả hành vi, không prefix `I` (e.g., `OrderRepository`, `PriceChecker`)
- **Errors:** `ErrXxx` (sentinel), hoặc custom struct implement `error`

### Architecture — Clean Arch (shipping-report-v5, khuyến khích các Go service khác)
```
domain/         # Entities, Value Objects, Repository interfaces, Domain errors
usecase/        # Business logic — chỉ phụ thuộc domain
infrastructure/ # DB (GORM), Redis, Kafka, external HTTP clients
delivery/       # HTTP handlers (Gin), gRPC handlers
```

### HTTP (Gin)
- Route group theo version: `/api/v1/...`, `/api/v5/...`
- Handler chỉ bind/validate input, gọi UseCase, trả JSON
- Middleware: auth, logging, recovery, OTel tracing

### gRPC
- Proto files định nghĩa contract; generated code không sửa tay
- `shipping-merchant` và `kship-golang-add-on` expose gRPC `:8082`
- `kship-golang-add-on` gọi user-svc `:8186`, reg-svc `:8188`

### Observability (shipping-report-v5, kship-golang-check-price)
- **Tracing:** OpenTelemetry → Tempo / Jaeger
- **Metrics:** Prometheus, expose `/api/metrics`
- Span name: `<layer>.<operation>` (e.g., `usecase.CreateOrder`)

### Patterns
- Luôn trả `error` tường minh — không panic cho expected failures
- Context (`ctx`) truyền xuyên suốt call chain (timeout, tracing, cancellation)
- Redis cache cho check-price: key theo `route + weight`, TTL ngắn
- Kafka consumer xử lý idempotent: check `message_id` trước khi xử lý

### Anti-patterns (TRÁNH)
- Gọi DB / external API trực tiếp trong Gin handler (bọc qua UseCase/Repository)
- Bỏ qua `error` return (`_ = someCall()`)
- Goroutine leak — luôn đảm bảo goroutine có exit condition

---

## Node.js / JavaScript

### kship-nodejs-check-price-v3 (Node.js 16, Express)
- Legacy pricing engine — **chỉ maintain, không thêm feature mới**
- Feature check-price mới → implement trong `kship-golang-check-price` (v5)

### shipping-widget / kship-widget-fnb (JS, Webpack)
- Bundle tĩnh, deploy lên AWS S3 / CDN
- Không chứa business logic — chỉ gọi API và render UI
- Widget flow: check-price → chọn carrier → tạo đơn qua `shipping-api`

---

## Shared Patterns

### Kafka / Async Messaging
- Producer publish sau khi commit DB (Outbox pattern)
- Consumer kiểm tra idempotency key trên Redis trước khi xử lý
- Chi tiết xem `agent_docs/data-flows.md`

### Multi-tenancy
- Đơn vị tenant là **`retailer_id`** — mọi query phải filter theo `retailer_id`
- Shard routing: `retailer_id` → `shard_id` → connection string tương ứng
- Go services: resolve qua `TenantContextResolver` → `IShardingService`
- PHP services: `retailer_id` từ middleware / request header / auth token

### Error Response (HTTP)
```json
{
  "success": false,
  "status_code": 3303,
  "message": "Mô tả lỗi",
  "errors": { "field": ["validation message"] }
}
```

### Logging
- Structured log (JSON) — include `tenant_id`, `request_id`, `service`
- Go: `slog` hoặc `zap`
- PHP: Laravel Log facade → JSON formatter
