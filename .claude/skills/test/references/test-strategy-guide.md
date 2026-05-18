# Test Strategy Guide

> Reference cho test-engineer agent khi quyết định loại test phù hợp, patterns, và best practices.

---

## Test Pyramid

```
        /  E2E/BDD  \          ← Ít nhất, chậm nhất, đắt nhất
       / Integration  \        ← Vừa phải
      /    Unit Tests    \     ← Nhiều nhất, nhanh nhất (develop Phase 6)
     ─────────────────────
```

- **Unit** (developer viết trong TDD — KHÔNG thuộc scope QC): Nhanh, isolated, test logic
- **Integration**: Test tương tác giữa components, services, database
- **E2E/BDD**: Test full user flows, business scenarios — chậm nhưng high confidence

**Nguyên tắc**: Test ở tầng thấp nhất có thể. Chỉ lên tầng cao hơn khi tầng thấp không cover được.

---

## Strategy by Component Type

| Component | Test types | Focus |
|-----------|-----------|-------|
| **API endpoints** | Unit (logic), Integration (HTTP), Contract (consumers) | Schema, status codes, auth, validation |
| **Frontend/Mobile** | Component, Interaction, Visual regression, Accessibility | User flows, states, responsive, a11y |
| **Data pipelines** | Input validation, Transformation, Idempotency | Data integrity, edge cases |
| **Infrastructure** | Smoke, Load, Chaos | Availability, performance, resilience |

### What to Cover
Business-critical paths, error handling, edge cases, security boundaries, data integrity.

### What to Skip
Trivial getters/setters, framework boilerplate, one-off scripts, code already covered bởi framework guarantees.

---

## Khi nào dùng loại test nào

| Cần verify | Loại test | Ví dụ |
|---|---|---|
| Business flow end-to-end | **BDD** | User đặt hàng, thanh toán, nhận xác nhận |
| Acceptance criteria từ PO/BA | **BDD** | Scenario trong user story |
| UI flow across pages | **E2E** | Login → Dashboard → Create Order → Checkout |
| API contract/schema | **API** | POST /orders trả về đúng schema |
| API error handling | **API** | 401 khi thiếu token, 400 khi data invalid |
| Multi-service interaction | **Integration** | Order service gọi Inventory service |
| Database operations | **Integration** | CRUD operations, transactions, migrations |
| Event/message flow | **Integration** | Order created → event published → notification sent |

### BDD vs E2E — Khi nào chọn cái nào?
- **BDD**: Khi cần communicate business behavior với non-tech stakeholders, khi có acceptance criteria rõ ràng
- **E2E** (không BDD): Khi test pure technical flows không cần business language (VD: browser compatibility, performance)

---

## Page Object Pattern

### Structure
```typescript
// pages/BasePage.ts — Base cho tất cả pages
export class BasePage {
  constructor(protected page: Page) {}

  async navigateTo(path: string) {
    await this.page.goto(path);
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }
}

// pages/LoginPage.ts — Specific page
export class LoginPage extends BasePage {
  private emailInput = this.page.getByLabel('Email');
  private passwordInput = this.page.getByLabel('Mật khẩu');
  private loginButton = this.page.getByRole('button', { name: 'Đăng nhập' });
  private errorMessage = this.page.getByRole('alert');

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async getErrorMessage(): Promise<string> {
    return await this.errorMessage.textContent() ?? '';
  }
}
```

### Quy tắc
- Mỗi page/component có 1 Page Object class
- Locators khai báo là properties, KHÔNG hardcode trong methods
- Methods mô tả user actions, KHÔNG phải technical steps
- KHÔNG có assertions trong Page Object — assertions thuộc về test
- Dùng Playwright recommended locators: `getByRole`, `getByLabel`, `getByText`, `getByTestId`

---

## API Testing Patterns

### Contract Testing
```typescript
test('POST /orders returns correct schema', async ({ request }) => {
  const response = await request.post('/api/orders', { data: validOrder });

  expect(response.status()).toBe(201);
  const body = await response.json();
  expect(body).toHaveProperty('id');
  expect(body).toHaveProperty('status', 'pending');
  expect(body).toHaveProperty('createdAt');
  expect(body.items).toBeInstanceOf(Array);
});
```

### Key Areas
- **Happy path**: Correct request → correct response + status code
- **Validation**: Invalid data → 400 + meaningful error message
- **Auth**: No token → 401, invalid role → 403
- **Not found**: Invalid ID → 404
- **Edge cases**: Empty arrays, max lengths, special characters, unicode

---

## Integration Testing Patterns

### Database Integration
```typescript
describe('OrderRepository', () => {
  beforeEach(async () => {
    await db.migrate.latest();
    await db.seed.run();
  });

  afterEach(async () => {
    await db.migrate.rollback();
  });

  test('creates order with items', async () => {
    const order = await orderRepo.create(testOrderData);
    const saved = await orderRepo.findById(order.id);
    expect(saved.items).toHaveLength(2);
  });
});
```

### Service Integration
- Mock external services (3rd party APIs) — dùng MSW hoặc nock
- Test real internal services khi có thể (docker compose)
- Verify event publishing/consuming
- Test retry logic và error handling

---

## Test Data Management

### Factories
```typescript
// test/factories/order.factory.ts
export const createTestOrder = (overrides = {}) => ({
  customerId: faker.string.uuid(),
  items: [{ productId: 'PROD-001', quantity: 1, price: 50000 }],
  ...overrides
});
```

### Quy tắc
- **Factories** cho dynamic test data — KHÔNG hardcode
- **Fixtures** cho static reference data (configs, enums)
- **Cleanup**: Mỗi test tự cleanup data, KHÔNG phụ thuộc shared state
- **Isolation**: Mỗi test tạo data riêng, chạy parallel được

---

## Flaky Test Prevention

| Nguyên nhân | Giải pháp |
|---|---|
| Race conditions | Dùng `waitFor` thay vì `sleep`, Playwright auto-waiting |
| Shared state | Mỗi test có browser context riêng |
| Network timing | `waitForResponse`, `waitForLoadState('networkidle')` |
| Random data conflicts | Unique data per test (UUID, timestamp) |
| External service down | Mock external dependencies |
| Order-dependent tests | Mỗi test setup/teardown riêng, chạy independent |
