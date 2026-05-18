# .NET / Clean Architecture Review Patterns

> Anti-patterns cần flag khi review .NET Core / C# code. Thêm stack-specific patterns vào đây.

---

## Clean Architecture Layer Violations

| Layer | Contains | Should NOT contain |
|-------|----------|-------------------|
| Domain | Entities, Value Objects, Domain Events, Interfaces | Infrastructure concerns, EF references |
| Application | Use Cases, DTOs, Validators, Interfaces | UI logic, direct DB access |
| Infrastructure | EF DbContext, Repositories, External Services | Business logic |
| API/Presentation | Controllers, Middleware, Filters | Business logic, direct DB queries |

### Common violations

- Domain entity với `[Table]` hoặc `[Column]` EF attributes → move to Infrastructure mapping
- Application service gọi `HttpClient` directly → inject via interface
- Controller chứa business logic → extract to Application use case
- Repository chứa business rules → move to Domain service

---

## Entity Framework Core

### Query optimization — flag khi thấy

```csharp
// ❌ N+1 query — loading related data trong loop
foreach (var order in orders)
{
    var items = await _context.OrderItems
        .Where(i => i.OrderId == order.Id).ToListAsync();
}
// ✅ Eager load hoặc batch query
var orders = await _context.Orders.Include(o => o.Items).ToListAsync();
```

```csharp
// ❌ Load all rồi filter in memory
var allUsers = await _context.Users.ToListAsync();
var activeUsers = allUsers.Where(u => u.IsActive);
// ✅ Filter at database level
var activeUsers = await _context.Users.Where(u => u.IsActive).ToListAsync();
```

### Best practices to verify

- `.AsNoTracking()` cho read-only queries
- `.Select()` projection thay vì load full entities
- Tránh `Include()` chains deeper than 2 levels
- `AsSplitQuery()` cho complex includes tránh cartesian explosion

---

## Multi-Tenant Patterns

### Data isolation

- Mọi query cần filter by TenantId / MerchantId — thiếu filter gây cross-tenant data leakage, là P0 security incident trong multi-tenant systems
- Global query filters configured trong DbContext
- Verify không có cross-tenant data leakage trong joins
- Tenant context phải set trước mọi DB operation

```csharp
// ❌ Missing tenant filter
var invoices = await _context.Invoices
    .Where(i => i.Status == "pending").ToListAsync();

// ✅ Tenant-scoped
var invoices = await _context.Invoices
    .Where(i => i.TenantId == _tenantContext.TenantId)
    .Where(i => i.Status == "pending").ToListAsync();
```

---

## Async/Await

- Prefer `async/await` over `.Result` hoặc `.Wait()` (deadlock risk)
- `ConfigureAwait(false)` trong library code
- Tránh `async void` (trừ event handlers) — `async void` nuốt exceptions âm thầm, gây failures invisible trong production. Dùng `async Task` để callers observe được errors
- Return `Task` từ async methods, không `void`

## Dependency Injection

- Services depend on interfaces, không implementations
- Correct lifetime: Scoped (per-request), Singleton (stateless), Transient (lightweight)
- Tránh inject Scoped services vào Singleton services — Scoped service bị capture và reused across requests, gây stale data và concurrency bugs
- `IOptions<T>` pattern cho configuration
