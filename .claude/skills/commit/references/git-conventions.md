# Git Conventions

## Commit Message Format

Theo **Conventional Commits specification**:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Type (bắt buộc)

| Type | Khi nào dùng |
|------|-------------|
| `feat` | Feature mới |
| `fix` | Sửa bug |
| `chore` | Maintenance, không ảnh hưởng src/test |
| `docs` | Chỉ thay đổi documentation |
| `style` | Formatting, không thay đổi logic |
| `refactor` | Restructure code, không thay đổi behavior |
| `perf` | Performance improvements |
| `test` | Thêm/sửa tests |
| `build` | Build system, dependencies |
| `ci` | CI/CD pipeline changes |

### Scope (optional)

Service hoặc module bị ảnh hưởng. Ví dụ: `(user-service)`, `(payment)`, `(auth)`, `(mobile-app)`

### Subject (bắt buộc)

- Imperative mood: "add" không phải "added" hoặc "adds"
- Không viết hoa chữ đầu
- Không kết thúc bằng dấu chấm
- Tối đa 72 ký tự

### Ví dụ

```
feat(payment): add VNPay payment gateway integration
fix(auth): resolve token refresh race condition
refactor(order): extract order validation to separate service
test(user): add unit tests for registration flow
docs(api): update payment endpoint documentation
perf(inventory): optimize stock query with indexed lookup
```

## Branching Strategy

### Branch Naming Convention

Tất cả branches theo format sau — đảm bảo traceability từ branch về JIRA ticket và dễ filter trong CI/CD:

```
[type]/[JIRA-TICKET-ID]-[short-description]
```

| Type | Mô tả | Ví dụ |
|------|--------|-------|
| `feat` | Feature mới | `feat/PROJ-123-add-user-login` |
| `fix` | Bug fix | `fix/PROJ-456-broken-link-on-homepage` |
| `chore` | Maintenance, config updates (không thay đổi production code) | `chore/update-dependencies` |
| `refactor` | Code restructuring/cleanup | `refactor/clean-up-legacy-code` |
