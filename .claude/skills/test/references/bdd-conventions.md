# BDD Conventions — CucumberJS + PlaywrightJS

> Reference cho test-engineer agent khi viết BDD tests. Bao gồm Gherkin syntax, project structure, step definitions, và anti-patterns.

---

## Gherkin Syntax

### Feature File Structure
```gherkin
@module-name
Feature: Tên feature (business-readable)
  Mô tả ngắn feature này làm gì, ai dùng, tại sao quan trọng.

  Background:
    Given user đã đăng nhập thành công
    And user đang ở trang dashboard

  @smoke
  Scenario: Mô tả scenario cụ thể
    Given [precondition — trạng thái ban đầu]
    When [action — hành động người dùng thực hiện]
    Then [expected result — kết quả mong đợi]
    And [additional verification]

  @regression
  Scenario Outline: Mô tả scenario với nhiều bộ data
    Given user có sản phẩm "<product>" trong giỏ hàng
    When user áp dụng mã giảm giá "<code>"
    Then tổng tiền phải là "<total>"

    Examples:
      | product   | code    | total   |
      | Áo thun   | SALE10  | 90,000  |
      | Quần jean | SALE20  | 320,000 |
```

### Keywords
- **Feature**: Mô tả business feature, KHÔNG phải technical implementation
- **Background**: Preconditions chung cho TẤT CẢ scenarios trong feature
- **Scenario**: Một test case cụ thể
- **Scenario Outline + Examples**: Data-driven testing — cùng flow, khác data
- **Given**: Setup trạng thái ban đầu
- **When**: Action người dùng thực hiện
- **Then**: Verify kết quả
- **And/But**: Nối thêm steps cùng loại

### Tags
- `@smoke` — Critical tests, chạy mỗi deploy
- `@regression` — Full regression suite
- `@wip` — Đang develop, chưa stable
- `@skip` — Tạm skip (ghi rõ lý do)
- `@module-name` — Phân loại theo module/feature

---

## Project Structure

```
tests/
├── features/
│   ├── auth/
│   │   ├── login.feature
│   │   └── register.feature
│   ├── order/
│   │   ├── create-order.feature
│   │   └── cancel-order.feature
│   └── ...
├── step_definitions/
│   ├── auth.steps.ts
│   ├── order.steps.ts
│   └── common.steps.ts
├── pages/                          # Page Object classes
│   ├── LoginPage.ts
│   ├── DashboardPage.ts
│   └── OrderPage.ts
├── support/
│   ├── world.ts                    # Custom World (shared state)
│   ├── hooks.ts                    # Before/After hooks
│   └── helpers.ts                  # Utility functions
└── cucumber.config.ts
```

---

## Step Definitions + Playwright

### Pattern
```typescript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

Given('user đã đăng nhập thành công', async function () {
  const loginPage = new LoginPage(this.page);
  await loginPage.login(this.testUser.email, this.testUser.password);
});

When('user click vào nút {string}', async function (buttonText: string) {
  await this.page.getByRole('button', { name: buttonText }).click();
});

Then('user thấy thông báo {string}', async function (message: string) {
  await expect(this.page.getByText(message)).toBeVisible();
});
```

### Quy tắc Step Definitions
- Mỗi step definition PHẢI dùng Page Object, KHÔNG interact trực tiếp với selectors
- Dùng Playwright locators: `getByRole`, `getByText`, `getByLabel`, `getByTestId`
- Tránh CSS/XPath selectors khi có thể
- Parameterize steps với `{string}`, `{int}`, `{float}` cho reusability
- Common steps (login, navigation) đặt trong `common.steps.ts`

---

## Page Object Pattern cho BDD

```typescript
// pages/OrderPage.ts
import { Page, Locator } from '@playwright/test';

export class OrderPage {
  readonly page: Page;
  readonly productList: Locator;
  readonly totalAmount: Locator;
  readonly submitButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.productList = page.getByTestId('product-list');
    this.totalAmount = page.getByTestId('total-amount');
    this.submitButton = page.getByRole('button', { name: 'Đặt hàng' });
  }

  async addProduct(name: string, quantity: number) {
    await this.page.getByText(name).click();
    await this.page.getByLabel('Số lượng').fill(String(quantity));
    await this.page.getByRole('button', { name: 'Thêm' }).click();
  }

  async submitOrder() {
    await this.submitButton.click();
  }

  async getTotal(): Promise<string> {
    return await this.totalAmount.textContent() ?? '';
  }
}
```

---

## Anti-patterns — TRÁNH

| Anti-pattern | Ví dụ sai | Nên viết |
|---|---|---|
| Technical language | "When API returns 200" | "When đơn hàng được tạo thành công" |
| UI-coupled Given | "Given user ở URL /orders/new" | "Given user đang tạo đơn hàng mới" |
| Too many steps | Scenario 15+ steps | Chia nhỏ hoặc dùng Background |
| Imperative style | "When click button, fill input..." | "When user submit form đăng ký" |
| No business value | "Then div.success is visible" | "Then user thấy thông báo thành công" |
| Dependent scenarios | Scenario B dùng data từ A | Mỗi scenario independent, setup riêng |

---

## Hooks (Before/After)

```typescript
// support/hooks.ts
import { Before, After, BeforeAll, AfterAll } from '@cucumber/cucumber';

BeforeAll(async function () {
  // Setup global: database seed, server start
});

Before(async function () {
  // Mỗi scenario: new browser context
  this.context = await this.browser.newContext();
  this.page = await this.context.newPage();
});

After(async function (scenario) {
  // Screenshot on failure
  if (scenario.result?.status === 'FAILED') {
    await this.page.screenshot({
      path: `reports/screenshots/${scenario.pickle.name}.png`
    });
  }
  await this.context?.close();
});
```

> **Nguồn tham khảo**: CucumberJS docs, Playwright docs, "BDD in Action" — John Ferguson Smart
