---
name: golang-shipping
description: >
  Guide for developing features in the shipping-report-v5 Go 1.24 service (and similar Go services in this monorepo).
  Use this skill whenever the user is working inside src/shipping-report-v5/ or any Go submodule — adding an API endpoint,
  creating a new domain model, writing a Kafka consumer, adding a repository, wiring up a use case, writing tests, or
  asking how the architecture works. Also trigger when the user mentions Go service, Uber FX, Clean Architecture in Go,
  adding a handler/service/repo in this project, or asks "how do I add X to the Go service".
---

# golang-shipping Skill

This project (`shipping-report-v5`) is a Go 1.24 microservice following **Clean Architecture (Hexagonal / Ports & Adapters)**.
Everything is wired with **Uber FX** for dependency injection.

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────────┐
│  Driving Side (input adapters)                          │
│  internal/drivingside/httpui/    ← HTTP (Gin)           │
│  internal/drivingside/consumer/  ← Kafka consumers      │
│  internal/drivingside/cronjob/   ← Cron jobs            │
├─────────────────────────────────────────────────────────┤
│  Application Core                                       │
│  internal/appcore/usecase/   ← orchestration only       │
│  internal/appcore/dto/       ← API contracts            │
│  internal/appcore/transform/ ← Kafka msg → domain model │
├─────────────────────────────────────────────────────────┤
│  Domain Layer  (no framework imports)                   │
│  internal/domain/model/    ← pure Go structs            │
│  internal/domain/repo/     ← repository interfaces      │
│  internal/domain/service/  ← business rules             │
├─────────────────────────────────────────────────────────┤
│  Driven Side (output adapters)                          │
│  internal/drivenside/persistent/ ← MongoDB/SQL/Redis    │
│  internal/drivenside/producer/   ← Kafka producers      │
│  internal/drivenside/extsvc/     ← external HTTP calls  │
└─────────────────────────────────────────────────────────┘
```

**Rule**: each layer depends only on the layer below it. Domain has **zero** framework imports.

---

## Adding a New Feature: Step-by-Step

Follow this order when adding a new entity (example: `Order`):

### Step 1 — Domain Model

`internal/domain/model/order_model.go`
```go
package model

import "time"

type Order struct {
    ID         string
    RetailerID string
    Status     string
    CreatedAt  time.Time
    UpdatedAt  time.Time
}
```
Plain Go structs only. No BSON/GORM/JSON tags here.

---

### Step 2 — Repository Interface

`internal/domain/repo/order_repo.go`
```go
package repo

import (
    "context"
    "shipping-report-v5/internal/domain/model"
)

type IOrderRepo interface {
    Get(ctx context.Context, id string) (*model.Order, error)
    Create(ctx context.Context, order *model.Order) (string, error)
    Update(ctx context.Context, order *model.Order) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, filter ListOrderFilter) ([]*model.Order, int64, error)
}
```
Interface lives in domain. Implementation lives in drivenside.

---

### Step 3 — Domain Service

`internal/domain/service/order_service.go`
```go
package service

import (
    "context"
    "shipping-report-v5/internal/domain/model"
    "shipping-report-v5/internal/domain/repo"
    "shipping-report-v5/pkg/errbase"
)

type IOrderService interface {
    Create(ctx context.Context, order *model.Order) (*model.Order, error)
    ValidateOrderExists(ctx context.Context, id string) error
}

type OrderServiceFxParams struct {
    fx.In
    OrderRepo repo.IOrderRepo `name:"order_repo"`
}

func NewOrderService(p OrderServiceFxParams) IOrderService {
    return &OrderService{orderRepo: p.OrderRepo}
}

type OrderService struct {
    orderRepo repo.IOrderRepo
}

func (s *OrderService) Create(ctx context.Context, order *model.Order) (*model.Order, error) {
    // business rules here, e.g. validate status transitions
    id, err := s.orderRepo.Create(ctx, order)
    if err != nil {
        return nil, err
    }
    order.ID = id
    return order, nil
}
```

Register in `internal/domain/service/fx_service.go`:
```go
fx.Provide(fx.Annotate(NewOrderService, fx.ResultTags(`name:"order_service"`))),
```

---

### Step 4 — Data Model + Repository Implementation

**Data model** (DB-layer struct with tags):
`internal/drivenside/persistent/datamodel/order_datamodel.go`
```go
package datamodel

import (
    "go.mongodb.org/mongo-driver/v2/bson"
    "time"
)

type OrderDataModel struct {
    ID         bson.ObjectID `bson:"_id,omitempty"`
    RetailerID string        `bson:"retailer_id"`
    Status     string        `bson:"status"`
    CreatedAt  time.Time     `bson:"created_at"`
    UpdatedAt  time.Time     `bson:"updated_at"`
}

// Mapper — always define as a package-level var
var OrderMapper = orderMapper{}

type orderMapper struct{}

func (orderMapper) ToModel(d *OrderDataModel) *model.Order {
    return &model.Order{
        ID:         d.ID.Hex(),
        RetailerID: d.RetailerID,
        Status:     d.Status,
        CreatedAt:  d.CreatedAt,
        UpdatedAt:  d.UpdatedAt,
    }
}

func (orderMapper) ToDataModel(m *model.Order) *OrderDataModel {
    id, _ := bson.ObjectIDFromHex(m.ID)
    return &OrderDataModel{
        ID:         id,
        RetailerID: m.RetailerID,
        Status:     m.Status,
        CreatedAt:  m.CreatedAt,
        UpdatedAt:  m.UpdatedAt,
    }
}
```

**Repository implementation**:
`internal/drivenside/persistent/order_repo_impl.go`
```go
package persistent

import (
    "context"
    "go.mongodb.org/mongo-driver/v2/bson"
    "shipping-report-v5/internal/domain/model"
    "shipping-report-v5/internal/domain/repo"
    "shipping-report-v5/internal/drivenside/persistent/datamodel"
    "shipping-report-v5/pkg/errbase"
    "shipping-report-v5/pkg/log"
)

const orderCollection = "orders"

type OrderRepoFxParams struct {
    fx.In
    MongoManager IMongoManager
}

func NewOrderRepo(p OrderRepoFxParams) repo.IOrderRepo {
    return &OrderRepoImpl{mongoManager: p.MongoManager}
}

type OrderRepoImpl struct {
    mongoManager IMongoManager
}

func (r *OrderRepoImpl) Get(ctx context.Context, id string) (*model.Order, error) {
    objectID, err := bson.ObjectIDFromHex(id)
    if err != nil {
        return nil, errbase.NewNotFoundOrder().WithCause(err)
    }

    var doc datamodel.OrderDataModel
    err = r.mongoManager.Collection(orderCollection).
        FindOne(ctx, bson.M{"_id": objectID}).
        Decode(&doc)
    if err != nil {
        return nil, errbase.NewNotFoundOrder().WithCause(err)
    }
    return datamodel.OrderMapper.ToModel(&doc), nil
}
```

Register in `internal/drivenside/persistent/fx_persistent.go`:
```go
fx.Provide(fx.Annotate(NewOrderRepo, fx.ResultTags(`name:"order_repo"`))),
```

---

### Step 5 — DTO + Mapper

`internal/appcore/dto/order_dto.go`
```go
package dto

import (
    "shipping-report-v5/internal/domain/model"
    "time"
)

// Input structs — add `validate:` tags for validation rules
type CreateOrderInput struct {
    RetailerID string `json:"retailer_id" validate:"required"`
    Status     string `json:"status"      validate:"required,oneof=pending confirmed cancelled"`
}

type GetOrderInput struct {
    ID string `uri:"id" validate:"required"`
}

// Response/DTO struct
type OrderDTO struct {
    ID         string    `json:"id"`
    RetailerID string    `json:"retailer_id"`
    Status     string    `json:"status"`
    CreatedAt  time.Time `json:"created_at"`
    UpdatedAt  time.Time `json:"updated_at"`
}

// Mapper
var OrderDTOMapper = orderDTOMapper{}
type orderDTOMapper struct{}

func (orderDTOMapper) ToDTO(m *model.Order) *OrderDTO {
    return &OrderDTO{
        ID:         m.ID,
        RetailerID: m.RetailerID,
        Status:     m.Status,
        CreatedAt:  m.CreatedAt,
        UpdatedAt:  m.UpdatedAt,
    }
}

func (orderDTOMapper) FromCreateInputToModel(in *CreateOrderInput) *model.Order {
    return &model.Order{
        RetailerID: in.RetailerID,
        Status:     in.Status,
    }
}
```

---

### Step 6 — Use Case

`internal/appcore/usecase/order_usecase.go`
```go
package usecase

import (
    "context"
    "go.uber.org/fx"
    "shipping-report-v5/internal/appcore/dto"
    "shipping-report-v5/internal/domain/service"
    "shipping-report-v5/internal/drivenside/persistent"
)

type IOrderUseCase interface {
    Get(ctx context.Context, input *dto.GetOrderInput) (*dto.OrderDTO, error)
    Create(ctx context.Context, input *dto.CreateOrderInput) (*dto.OrderDTO, error)
}

type OrderUseCaseFxParams struct {
    fx.In
    OrderService  service.IOrderService  `name:"order_service"`
    MongoManager  persistent.IMongoManager
}

func NewOrderUseCase(p OrderUseCaseFxParams) IOrderUseCase {
    return &OrderUseCase{
        orderService: p.OrderService,
        mongoManager: p.MongoManager,
    }
}

type OrderUseCase struct {
    orderService  service.IOrderService
    mongoManager  persistent.IMongoManager
}

func (uc *OrderUseCase) Create(ctx context.Context, input *dto.CreateOrderInput) (*dto.OrderDTO, error) {
    order := dto.OrderDTOMapper.FromCreateInputToModel(input)

    result, err := uc.mongoManager.WithTransaction(ctx, func(txCtx context.Context) (any, error) {
        return uc.orderService.Create(txCtx, order)
    })
    if err != nil {
        return nil, err
    }

    return dto.OrderDTOMapper.ToDTO(result.(*model.Order)), nil
}
```

Register in `internal/appcore/fx_appcore.go`:
```go
fx.Provide(fx.Annotate(NewOrderUseCase, fx.ResultTags(`name:"order_usecase"`))),
```

---

### Step 7 — HTTP Handler

`internal/drivingside/httpui/handler/order_handler.go`
```go
package handler

import (
    "github.com/gin-gonic/gin"
    "go.uber.org/fx"
    "shipping-report-v5/internal/appcore/dto"
    "shipping-report-v5/internal/appcore/usecase"
    "shipping-report-v5/pkg/httpbase"
)

type OrderHandlerFxParams struct {
    fx.In
    OrderUseCase usecase.IOrderUseCase `name:"order_usecase"`
}

func NewOrderHandler(p OrderHandlerFxParams) *OrderHandler {
    return &OrderHandler{orderUseCase: p.OrderUseCase}
}

type OrderHandler struct {
    orderUseCase usecase.IOrderUseCase
}

// @Summary Get order by ID
// @Tags orders
// @Produce json
// @Param id path string true "Order ID"
// @Success 200 {object} httpbase.Response{data=dto.OrderDTO}
// @Router /api/v1/orders/{id} [get]
func (h *OrderHandler) GetOrder(c *gin.Context) {
    var input dto.GetOrderInput
    if err := httpbase.BindInput(c, &input); err != nil {
        httpbase.ReturnError(c, err)
        return
    }

    order, err := h.orderUseCase.Get(c.Request.Context(), &input)
    if err != nil {
        httpbase.ReturnError(c, err)
        return
    }

    httpbase.ReturnSuccess(c, order)
}
```

Register in `internal/drivingside/httpui/fx_httpui.go`:
```go
fx.Provide(fx.Annotate(NewOrderHandler, fx.ResultTags(`name:"order_handler"`))),
```

**Wire the route** in `internal/drivingside/httpui/http_server.go`:
```go
type HttpServerFxParams struct {
    fx.In
    // ... existing fields ...
    OrderHandler *handler.OrderHandler `name:"order_handler"`
}

// In route setup:
auth := authMiddleware.Auth
r.GET("/api/v1/orders/:id",    auth(iam.PermOrderRead),  p.OrderHandler.GetOrder)
r.POST("/api/v1/orders",       auth(iam.PermOrderWrite), p.OrderHandler.CreateOrder)
```

---

## Key Patterns Reference

### Input Binding & Validation
```go
// URI params:  binds :id → struct field with `uri:"id"`
// Query params: binds ?page=1 → struct field with `form:"page"`
// JSON body:   binds body → struct field with `json:"field"`
// validate:"required,min=1,max=100" — uses go-playground/validator
httpbase.BindInput(c, &input)   // panics-safe, returns *errbase.Error on failure
```

### Error Handling
```go
// Always use errbase constructors — they carry HTTP status codes automatically
errbase.NewNotFoundUser()                    // 404
errbase.NewAlreadyExistedUser()              // 409
errbase.NewServerError()                     // 500

// Chain context onto errors
return errbase.NewNotFoundOrder().
    WithMessage("order not found").
    WithCause(originalErr).
    WithDetail(map[string]any{"id": id})
```
Define new error codes in `pkg/errbase/error.go` following the existing pattern.

### Logging
```go
// Always pass ctx — it carries trace_id automatically
log.Info(ctx).Prop("order_id", id).Msg("Order fetched")
log.Error(ctx).Error(err).Prop("order_id", id).Msg("Failed to fetch order")
log.Debug(ctx).Prop("filter", filter).Msg("Executing query")
```

### MongoDB Transactions
```go
result, err := mongoManager.WithTransaction(ctx, func(txCtx context.Context) (any, error) {
    // all repo calls in here share the same session
    // return (value, nil) → auto-commit
    // return (nil, err) → auto-rollback
    return someService.DoWork(txCtx, ...)
})
// cast result to the expected type
```

### MongoDB Sharding (when retailer_id is involved)
```go
// Route to correct shard based on retailer_id
shard := mongoShardManager.GetShard(retailerID)
shard.Collection("orders").FindOne(ctx, filter)
```
Use `MongoShardManager` (not `MongoManager`) when the entity is partitioned by `retailer_id`.

### Config-Driven Features
```go
// In fx_*.go, gate dependencies behind config flags
if config.GetBool("FEATURE_X.IS_ENABLED") {
    opts = append(opts, fx.Provide(NewFeatureXService))
}
```

---

## Naming Conventions

| Thing | Pattern | Example |
|---|---|---|
| Interface | `I<Entity><Layer>` | `IOrderRepo`, `IOrderService` |
| Constructor | `New<Type>` | `NewOrderRepo` |
| FX module func | `BuildFxModule<Layer>` | `BuildFxModuleRepo` |
| FX params struct | `<Type>FxParams` | `OrderRepoFxParams` |
| Mapper var | `<Entity>Mapper` (camelCase) | `orderMapper`, `OrderDTOMapper` |
| Input struct | `<Action><Entity>Input` | `CreateOrderInput`, `GetOrderInput` |
| Response struct | `<Entity>DTO` | `OrderDTO` |
| Error code | `Code<ErrorName>` | `CodeNotFoundOrder` |
| Error constructor | `New<ErrorName>()` | `NewNotFoundOrder()` |
| Collection const | `<entity>Collection` | `orderCollection = "orders"` |
| File names | `<entity>_<type>.go` | `order_model.go`, `order_repo_impl.go` |

---

## FX Wiring Checklist

When adding a new entity, touch these FX registration files:

- [ ] `internal/domain/service/fx_service.go` — register `New<Entity>Service`
- [ ] `internal/drivenside/persistent/fx_persistent.go` — register `New<Entity>Repo`
- [ ] `internal/appcore/fx_appcore.go` — register `New<Entity>UseCase`
- [ ] `internal/drivingside/httpui/fx_httpui.go` — register `New<Entity>Handler`
- [ ] `internal/drivingside/httpui/http_server.go` — add routes + inject handler
- [ ] `internal/common/iam/permissions.go` — add permission constants if needed

---

## Kafka Consumer Pattern

`internal/drivingside/consumer/<domain>_consumer.go`
```go
type OrderConsumer struct {
    orderService service.IOrderService
}

func (c *OrderConsumer) Handle(ctx context.Context, msg *kafka.Message) error {
    var payload OrderKafkaPayload
    if err := json.Unmarshal(msg.Value, &payload); err != nil {
        return errbase.NewJsonUnmarshalFail().WithCause(err)
    }

    order := transform.OrderTransformer.Transform(payload)
    _, err := c.orderService.Upsert(ctx, order)
    return err
}
```
Register in `consumer/fx_consumer.go` and configure topic/group in `config.yaml`.

---

## Reference Files

- `references/architecture-deep-dive.md` — detailed patterns for MongoDB sharding, multi-DB, tracing
- `references/error-codes.md` — full list of existing error codes and when to use them

For project-wide conventions shared across services, see `agent_docs/shared-conventions.md` in the meta repo root.
