# Architecture Deep-Dive: shipping-report-v5

## Project Layout Reference

```
cmd/api/
  main.go          ← fx.New() wires everything; Swagger @title annotation here
  config.yaml      ← all runtime config (see Configuration section)
cmd/shared/
  shared.go        ← initializes logging + tracing before fx starts

internal/
  appcore/
    dto/           ← input structs (validation tags) + response structs + mappers
    usecase/       ← orchestration: transactions, calling services, mapping DTOs
    transform/     ← raw map[string]any (Kafka) → domain model
    fx_appcore.go  ← registers all use cases

  common/
    iam/
      permissions.go  ← permission string constants (PermOrderRead, etc.)

  domain/
    model/         ← plain Go structs, no framework deps
    repo/          ← repository interfaces only
    service/       ← business rule interfaces + implementations
    fx_service.go  ← registers all services  (inside service/ dir)

  drivenside/
    persistent/
      mongo_manager.go        ← MongoManager: connection pool, transactions
      mongo_shard_manager.go  ← MongoShardManager: consistent hash on retailer_id
      sql_manager.go          ← SqlManager: GORM wrapper + transactions
      cache_manager.go        ← Redis client wrapper
      datamodel/              ← DB structs with bson/gorm/json tags + Mapper vars
      *_repo_impl.go          ← implements domain/repo interfaces
      fx_persistent.go        ← registers managers + repos (config-gated)
    producer/
      *_producer.go  ← Kafka producers
      fx_producer.go
    extsvc/
      *_ext_service.go  ← outbound HTTP calls
      fx_extsvc.go

  drivingside/
    httpui/
      handler/       ← Gin handlers (bind → call usecase → respond)
      presenter/     ← sometimes used for complex response assembly
      middleware/    ← logging, tracing, metrics, auth, CORS, recovery
      http_server.go ← router setup + route registration
      fx_httpui.go   ← registers handlers + middlewares + server
    consumer/
      *_consumer.go  ← kafka message handlers
      middleware/    ← consumer-level logging/tracing
      fx_consumer.go
    cronjob/       ← (future) scheduled tasks

pkg/               ← reusable, project-agnostic utilities
  config/          ← Viper wrapper (config.GetString, config.GetBool, etc.)
  ctxbase/         ← context attribute helpers (trace ID, user ID, etc.)
  errbase/         ← Error type, error codes, constructors
  log/             ← Zap wrapper with fluent API
  httpbase/        ← BindInput, ReturnSuccess, ReturnError, http client
  kafkabase/       ← consumer/producer builders + middleware
  tracing/         ← OpenTelemetry init + helpers
  cache/           ← Redis wrapper
  mongoutil/       ← MongoDB query helpers
  listing/         ← pagination (page/size → skip/limit)
  grpool/          ← goroutine pool for fan-out work
```

---

## MongoDB Patterns

### Single-instance (non-sharded entities)
```go
// Use MongoManager directly
type MyRepoImpl struct {
    mongoManager IMongoManager
}

func (r *MyRepoImpl) Get(ctx context.Context, id string) (*model.X, error) {
    oid, _ := bson.ObjectIDFromHex(id)
    var doc datamodel.XDataModel
    err := r.mongoManager.Collection("my_collection").
        FindOne(ctx, bson.M{"_id": oid}).
        Decode(&doc)
    if err != nil {
        if errors.Is(err, mongo.ErrNoDocuments) {
            return nil, errbase.NewNotFoundX()
        }
        return nil, errbase.NewDatabaseExecFail().WithCause(err)
    }
    return datamodel.XMapper.ToModel(&doc), nil
}
```

### Sharded (retailer_id partitioned)
```go
type BillLadingRepoImpl struct {
    shardManager IMongoShardManager
}

func (r *BillLadingRepoImpl) Get(ctx context.Context, retailerID, id string) (*model.BillLading, error) {
    shard := r.shardManager.GetShard(retailerID)  // consistent hash routing
    var doc datamodel.BillLadingDataModel
    err := shard.Collection("bill_lading_report").
        FindOne(ctx, bson.M{"_id": id, "retailer_id": retailerID}).
        Decode(&doc)
    ...
}
```

### Insert pattern
```go
func (r *MyRepoImpl) Create(ctx context.Context, m *model.X) (string, error) {
    doc := datamodel.XMapper.ToDataModel(m)
    result, err := r.mongoManager.Collection("xs").InsertOne(ctx, doc)
    if err != nil {
        return "", errbase.NewDatabaseExecFail().WithCause(err)
    }
    return result.InsertedID.(bson.ObjectID).Hex(), nil
}
```

### Update pattern
```go
func (r *MyRepoImpl) Update(ctx context.Context, m *model.X) error {
    oid, _ := bson.ObjectIDFromHex(m.ID)
    doc := datamodel.XMapper.ToDataModel(m)
    doc.UpdatedAt = time.Now()
    _, err := r.mongoManager.Collection("xs").UpdateOne(
        ctx,
        bson.M{"_id": oid},
        bson.M{"$set": doc},
    )
    if err != nil {
        return errbase.NewDatabaseExecFail().WithCause(err)
    }
    return nil
}
```

### List with pagination
```go
import "shipping-report-v5/pkg/listing"

func (r *MyRepoImpl) List(ctx context.Context, f ListXFilter) ([]*model.X, int64, error) {
    filter := bson.M{}
    if f.Status != "" {
        filter["status"] = f.Status
    }

    total, _ := r.mongoManager.Collection("xs").CountDocuments(ctx, filter)

    opts := options.Find().
        SetSkip(int64(listing.CalcSkip(f.Page, f.Size))).
        SetLimit(int64(f.Size)).
        SetSort(bson.D{{Key: "created_at", Value: -1}})

    cursor, err := r.mongoManager.Collection("xs").Find(ctx, filter, opts)
    // decode cursor...
}
```

---

## SQL / GORM Patterns

For entities in the SQL database (MySQL/PostgreSQL):

```go
type MyRepoImpl struct {
    sqlManager ISqlManager
}

func (r *MyRepoImpl) Get(ctx context.Context, id uint) (*model.X, error) {
    var doc datamodel.XDataModel
    result := r.sqlManager.DB(ctx).Where("id = ?", id).First(&doc)
    if result.Error != nil {
        if errors.Is(result.Error, gorm.ErrRecordNotFound) {
            return nil, errbase.NewNotFoundX()
        }
        return nil, errbase.NewDatabaseExecFail().WithCause(result.Error)
    }
    return datamodel.XMapper.ToModel(&doc), nil
}

func (r *MyRepoImpl) Create(ctx context.Context, m *model.X) (uint, error) {
    doc := datamodel.XMapper.ToDataModel(m)
    result := r.sqlManager.DB(ctx).Create(doc)
    if result.Error != nil {
        return 0, errbase.NewDatabaseExecFail().WithCause(result.Error)
    }
    return doc.ID, nil
}
```

SQL data models use GORM tags:
```go
type XDataModel struct {
    ID        uint           `gorm:"primarykey;autoIncrement"`
    Name      string         `gorm:"column:name;not null"`
    CreatedAt time.Time      `gorm:"column:created_at;autoCreateTime"`
    UpdatedAt time.Time      `gorm:"column:updated_at;autoUpdateTime"`
    DeletedAt gorm.DeletedAt `gorm:"index"`  // soft delete
}

func (XDataModel) TableName() string { return "xs" }
```

---

## HTTP Response Shapes

**Success:**
```json
{
  "metadata": { "trace_id": "...", "time": "2025-04-03T10:00:00Z" },
  "data": { ... }
}
```

**Success (list):**
```json
{
  "metadata": { "trace_id": "..." },
  "data": {
    "items": [...],
    "total": 42,
    "page": 1,
    "size": 20
  }
}
```

**Error:**
```json
{
  "metadata": { "trace_id": "..." },
  "error": {
    "code": "NOT_FOUND_ORDER",
    "message": "order not found",
    "detail": { "id": "abc123" }
  }
}
```

In **production mode**, 5xx errors return only `code: SERVER_ERROR` (details hidden for security).

---

## Uber FX Cheat-Sheet

### Named dependency (avoid conflicts when multiple of same type)
```go
// Provider
fx.Provide(fx.Annotate(NewFoo, fx.ResultTags(`name:"foo"`)))

// Consumer
type MyParams struct {
    fx.In
    Foo *Foo `name:"foo"`
}
```

### Interface binding
```go
fx.Provide(fx.Annotate(NewFoo, fx.As(new(IFoo))))
```

### Lifecycle hooks
```go
func NewMyService(lc fx.Lifecycle) *MyService {
    s := &MyService{}
    lc.Append(fx.Hook{
        OnStart: func(ctx context.Context) error { return s.Start(ctx) },
        OnStop:  func(ctx context.Context) error { return s.Stop(ctx) },
    })
    return s
}
```

### Module grouping
```go
func BuildFxModuleXxx() fx.Option {
    return fx.Module("xxx",
        fx.Provide(...),
        fx.Provide(...),
        fx.Invoke(...),  // side-effect only (e.g., start a server)
    )
}
```

---

## Configuration Reference (`cmd/api/config.yaml`)

```yaml
APP_NAME: shipping-report-v5
APP_MODE: development          # or production
LOG_LEVEL: debug               # debug|info|warning|error|panic|fatal

TRACER:
  IS_ENABLED: true
  HTTP_ENDPOINT: localhost:4318
  SAMPLER_RATIO: 1.0

HTTP_SERVER:
  IS_ENABLED: true
  ADDRESS: :8888
  READ_TIMEOUT: 10s

REDIS:
  IS_ENABLED: true
  ADDRESSES: [127.0.0.1:6379]
  PASSWORD: "..."
  POOL_SIZE: 10

MONGODB:
  IS_ENABLED: true
  URI: mongodb://127.0.0.1:27017/boilerplate_db
  DATABASE: boilerplate_db
  MAX_POOL_SIZE: 10
  MIN_POOL_SIZE: 5

SQL:
  IS_ENABLED: true
  DRIVER: mysql
  DSN: root:root@tcp(127.0.0.1:3306)/kvshipping?charset=utf8mb4

KAFKA:
  BOOTSTRAP_SERVERS: localhost:9092
  MY_CONSUMER_GROUP:
    IS_ENABLED: true
    TOPIC: my_topic
    GROUP_ID: my_group_0
    NUM_WORKERS: 1
```

Accessing config in code:
```go
config.GetString("APP_NAME")
config.GetBool("MONGODB.IS_ENABLED")
config.GetInt("MONGODB.MAX_POOL_SIZE")
config.GetDuration("HTTP_SERVER.READ_TIMEOUT")
```

---

## Observability

### Tracing (OpenTelemetry → Tempo)
- Gin, MongoDB, Redis, GORM, Kafka are all auto-instrumented via middleware/plugins
- Propagate context always — `ctx` carries the span
- Custom spans: `span := trace.SpanFromContext(ctx)` then `span.AddEvent(...)`

### Metrics (Prometheus → `/api/metrics`)
- HTTP request counts/latency auto-collected by `metric_middleware.go`
- Add custom metrics via `prometheus.NewCounterVec(...)` registered at startup

### Logging (Zap → structured JSON)
- Always include `ctx` so trace_id appears automatically
- Log at `Error` only for unexpected failures; `Info` for significant events; `Debug` for diagnostic details
- Standard: see `docs/memory/logging_standard.md`

---

## Testing Patterns

### Unit test (transformer/pure logic)
```go
func TestOrderTransformer_Transform(t *testing.T) {
    raw := map[string]any{
        "retailer_id": "r1",
        "status":      "pending",
    }
    order := transform.OrderTransformer.Transform(raw)
    assert.Equal(t, "r1", order.RetailerID)
    assert.Equal(t, "pending", order.Status)
}
```

### Consumer test with fake repo
```go
type FakeOrderRepo struct{ data map[string]*model.Order }

func (f *FakeOrderRepo) Get(ctx context.Context, id string) (*model.Order, error) {
    if o, ok := f.data[id]; ok { return o, nil }
    return nil, errbase.NewNotFoundOrder()
}

func TestOrderConsumer_Handle(t *testing.T) {
    consumer := &OrderConsumer{orderRepo: &FakeOrderRepo{data: map[string]*model.Order{}}}
    msg := &kafka.Message{Value: []byte(`{"id":"1","status":"pending"}`)}
    err := consumer.Handle(context.Background(), msg)
    assert.NoError(t, err)
}
```

Test files go alongside source: `order_consumer_test.go` next to `order_consumer.go`.

---

## Makefile Quick Reference

```bash
make docs-gen      # regenerate Swagger docs (after adding/changing Swagger annotations)
make lint-scan     # run golangci-lint
make vet-scan      # run go vet
make build-docker  # build Docker image
make sonar-scan    # run SonarQube analysis
```
