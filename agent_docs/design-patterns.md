# Design Patterns

Tổng hợp các design pattern được sử dụng trong Shipping Platform.

---

## Creational Patterns

### Factory
Encapsulate object creation logic; tạo object mà không expose logic khởi tạo.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-api | `database/factories/BillLadingFactory.php` | Generate test data |
| kship-wiki-v2 | `createShippingSettingsApiClient()` | Encapsulate HTTP client + JWT setup |

### Singleton
Đảm bảo chỉ có một instance trong application lifecycle.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| kship-golang-check-price | Redis cache client | Single connection pool |
| shipping-report-v5 | GORM DbContext per shard (FX lifecycle) | One DB connection per shard |
| kship-golang-add-on | `bootstrap/grpc_server.go` | Single gRPC server instance |

---

## Structural Patterns

### Repository
Đóng gói data access logic; cách ly domain khỏi infrastructure.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-api | `app/Core/Clients/Repositories/ClientRepository.php` | CRUD via Eloquent ORM |
| shipping-api | `app/Core/Clients/Repositories/Interfaces/ClientRepositoryInterface.php` | Contract cho DI |
| shipping-merchant | `src/core/domain/shop.go` — `type ShopRepo interface` | Domain repository interface |
| shipping-report-v5 | `internal/domain/repo/bill_lading_report_repo.go` | Interface cho MongoDB/Redis ops |

---

## Behavioral Patterns

### Observer
Trigger side effects khi state thay đổi; loose coupling giữa publisher và subscribers.

Dùng chủ yếu để **xóa cache** khi model thay đổi: sau khi `save()` hoặc `delete()`, observer tự động flush Redis cache tương ứng, đảm bảo dữ liệu cache không bị stale.

```
Model::save() / Model::delete()
  → Eloquent fires event
  → Observer.saved() / Observer.deleted()
  → flush Redis cache key
```

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-api | `app/Observers/BaseObserver.php` | `saved()` / `deleted()` → refresh/flush cache |
| shipping-api | `app/Observers/ClientObserver.php` | Xóa cache client khi client thay đổi |
| shipping-api | `app/Providers/EventServiceProvider.php` | Map Events → Listeners (1 event → nhiều listeners) |
| shipping-api | `app/Listeners/CreateTicketClientListener.php` | Side effects khi domain event xảy ra |

### Strategy
Định nghĩa family of algorithms; encapsulate mỗi cái; cho phép thay đổi nhau.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-cpanel | `app/States/LightConfigState.php`, `HeavyConfigState.php` | Khác nhau logic tạo/update price config |
| kship-golang-check-price | External services cho từng carrier | Mỗi carrier có logic khác nhau |

### Command / Job
Encapsulate request thành object; decouple requester khỏi executor.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-api | `app/Jobs/Webhook/ProcessWebhookToKafka.php` | Async queue job |
| shipping-api | `app/Jobs/UpdateShopBalanceTotal.php` | Decouple HTTP request khỏi heavy processing |
| shipping-api | `app/Core/Commons/OrderCodePrint/Actions/MergeMultiplePDFs.php` | Action object `handle()` |

---

## Architectural Patterns

### Service Layer
Tập hợp business logic; điều phối repositories và external services.

| Service | Ví dụ |
|---------|-------|
| shipping-api | `app/Core/Clients/Services/ClientService.php` |
| shipping-merchant | `src/core/services/merchant_service.go` |
| kship-golang-add-on | `src/core/services/coupon_service.go` |

### Use Case (Clean Architecture)
Application layer orchestrates domain logic; tách biệt với infrastructure.

```
domain/          → Entities, Repository interfaces (không phụ thuộc infrastructure)
appcore/usecase/ → Business logic orchestration
drivingside/     → HTTP/gRPC handlers, Kafka consumers (input adapters)
drivenside/      → Repository implementations, external API adapters (output adapters)
```

| Service | Ví dụ |
|---------|-------|
| shipping-report-v5 | `internal/appcore/usecase/user_usecase.go` — `IUserUseCase` interface + `UserUseCase` impl |

### Dependency Injection
Invert control; pass dependencies từ ngoài vào thay vì tạo bên trong.

| Service | Mechanism | Ví dụ |
|---------|-----------|-------|
| shipping-api | Laravel ServiceProvider | `app/Providers/RepositoryServiceProvider.php` — bind 50+ interfaces |
| shipping-cpanel | Laravel ServiceProvider | `app/Providers/RepositoryServiceProvider.php` |
| shipping-report-v5 | Uber FX | `fx.Provide()`, `fx.In` struct, `fx.Annotate` với named tags |
| shipping-merchant | Manual constructor injection | `NewMerchantService(repo, extService, ...)` |
| kship-golang-add-on | Manual + FX lifecycle hooks | `lc.Append(fx.Hook{OnStart, OnStop})` |

### DTO / Presenter
Decouple domain model khỏi API contract; transform data giữa layers.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-report-v5 | `internal/appcore/dto/user_dto.go` | `CreateUserInput`, `UpdateUserInput`, `UserDTO` |
| shipping-report-v5 | `internal/drivingside/httpui/presenter/user_presenter.go` | DTO → HTTP response |
| shipping-merchant | `src/present/request/create_shop_and_get_subscription_info.go` | Request binding + validation |

### Transformer / Mapper
Convert data giữa các formats (domain ↔ DTO, raw ↔ domain model).

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-report-v5 | `internal/appcore/transform/bill_lading_report_transformer.go` | Raw Kafka message → `BillLadingReport` domain model |
| shipping-api | `app/Api/V3/Transform/MessageBroker/DataUpdateOrderTransform.php` | Business data → Kafka payload |

---

## Distributed System Patterns

### Outbox Pattern
Đảm bảo reliable event publishing; write event + data trong cùng DB transaction, sau đó async dispatcher publish lên Kafka.

```
[shipping-api] DB Transaction:
  → INSERT business_data
  → INSERT outbox_events
  → COMMIT

[Outbox Dispatcher] (async):
  → READ outbox_events WHERE status = 'pending'
  → PUBLISH to Kafka topic
  → UPDATE outbox_events SET status = 'published'
```

### Idempotent Consumer
Đảm bảo Kafka message chỉ được xử lý đúng một lần dù có retry.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-report-v5 | `drivingside/consumer/self_delivery_consumer.go` — check Redis `message_id` trước khi xử lý | Prevent duplicate processing |

### Cache-Aside
Application kiểm soát cache; check cache trước, fallback DB nếu miss.

```
1. Check Redis → HIT → return cached data
2. MISS → Query DB
3. Populate Redis cache (với TTL)
4. Return data
```

| Service | Ví dụ |
|---------|-------|
| kship-golang-check-price | ~15 cache repo wrappers per entity |
| shipping-api | `BaseObserver` flush cache on `saved()` / `deleted()` |

### Multi-Tenancy / Sharding
Route data theo `retailer_id`; isolate tenant data.

```
Request (retailer_id: 123)
  → IShardingService.resolve(retailer_id)
  → shard_id = hash(retailer_id) % N
  → Connect to Shard_{shard_id}
```

| Service | Ví dụ |
|---------|-------|
| shipping-report-v5 | `IShardingService` → shard routing |
| shipping-merchant | All queries filter by `retailer_id` |

### Worker Pool
Bounded parallelism cho Kafka consumers; tránh goroutine explosion.

| Service | Ví dụ | Mục đích |
|---------|-------|---------|
| shipping-report-v5 | `grpool` package trong consumer | Process nhiều Kafka messages song song; giới hạn workers |

---

## Integration Patterns

### Middleware Pipeline
Chain handlers; mỗi middleware xử lý một cross-cutting concern.

**Go services (Gin HTTP):**
```
Request → Auth → Tracing → Logging → Recovery → Handler
```

**gRPC Interceptors (kship-golang-add-on):**
```
Call → OTel Tracing → grpc_recovery → TrackingInterceptor → LogInterceptor → Handler
```

### gRPC
High-performance RPC với Protocol Buffers; dùng cho internal service communication.

| Service | Ví dụ | Port |
|---------|-------|------|
| kship-golang-add-on | `src/pb/voucher.proto`, `present/grpcui/voucher_handler.go` | `:8082` |
| (consumers) | Call `user-svc :8186`, `reg-svc :8188` | internal |

### Event-Driven (Kafka)
Async communication giữa services; decoupled producers và consumers.

```
shipping-api (Producer)
  → Kafka Topics (bill_lading.*, shop.*, delivery.*)
  → shipping-report-v5 (Consumer)
  → shipping-cron (Consumer)
```

### REST API
HTTP + JSON; dùng cho external-facing APIs và inter-service calls.

Chuẩn response format:
```json
{
  "success": true|false,
  "status_code": 2000,
  "message": "...",
  "data": {...},
  "errors": {...}
}
```

---

## Pattern Matrix per Service

| Service | Stack | Patterns |
|---------|-------|---------|
| **shipping-api** | PHP 7/Laravel | Repository, Service, Observer, Event-Listener, Command/Job, Outbox, DI Provider |
| **shipping-cpanel** | PHP/Laravel | Repository, Service, Observer, Strategy (State), DI Provider |
| **shipping-merchant** | Go 1.22 | Service, Repository, Handler, gRPC, Middleware, Multi-Tenancy |
| **shipping-report-v5** | Go 1.24 | Clean Arch (UseCase), Uber FX DI, DTO/Presenter, Transformer, Idempotent Consumer, Sharding, Worker Pool, OTel |
| **kship-golang-check-price** | Go 1.21 | Cache-Aside, Repository, Strategy, Middleware |
| **kship-golang-add-on** | Go 1.24 | gRPC, Interceptor Chain, Service, Uber FX |
| **kship-nodejs-check-price-v3** | Node.js/Express | Middleware, Service (legacy) |
| **kship-wiki-v2** | TypeScript/Cucumber | BDD, Factory (API Clients) |
