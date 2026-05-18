# Angular Review Patterns

> Anti-patterns cần flag khi review Angular 17+ code. Review lại khi upgrade lên Angular 20+.
> Thêm patterns mới vào đây.

---

## Component Patterns — Flag khi thấy

| Anti-pattern | Correct pattern |
|---|---|
| Missing `ChangeDetectionStrategy.OnPush` | Required — default strategy re-checks entire component tree mỗi change detection cycle, gây frame drops trong large apps |
| Constructor injection | `inject()` function |
| `*ngIf` / `*ngFor` / `[ngSwitch]` | `@if` / `@for` / `@switch` |
| `@Input()` decorator | `input()` / `input.required()` signals |
| `@Output()` / `EventEmitter` | `output()` signal |
| `standalone: true` (explicit) | Default since Angular 17, remove |
| Class binding via `[class]` | `host: { class: '...' }` |

---

## Hexagonal Layer Dependencies

| Layer | Can Depend On | Violation Example |
|-------|---------------|-------------------|
| Domain | Nothing | Importing HttpClient trong domain |
| Application | Domain | Importing a Component trong application |
| Infrastructure | Domain, Application | OK |
| Presentation | Application | Importing directly from infrastructure |

---

## State & Reactivity — Flag khi thấy

| Anti-pattern | Correct pattern |
|---|---|
| `BehaviorSubject` cho simple state | Signals |
| Missing `takeUntilDestroyed` | `takeUntilDestroyed(this.destroyRef)` — pass DestroyRef explicitly |
| `toSignal(obs)` without initial value | `toSignal(obs.pipe(startWith(value)))` |
| Complex state trong component | Signals cho UI state (loading, error, filters) |
| Unnecessary RxJS cho simple values | RxJS chỉ cho async event streams |

---

## Domain Patterns

- Branded types cho IDs: `type EntityId = number & { __brand: 'EntityId' }`
- All domain properties `readonly`
- Factory functions return `Result<T>`
- Static mapper classes (no `@Injectable()`)
- `Result<T>` cho all fallible operations

---

## Import Ordering

1. `@angular/*`
2. Third-party (rxjs, etc.)
3. Project aliases (`@app/*`)
4. Relative imports

## File Size Guidelines

| File type | Max lines |
|-----------|-----------|
| Components | ~200 |
| Services | ~300 |
| Use Cases | ~100 |
| Domain files | ~200 |

Flag nếu exceed — suggest splitting.
