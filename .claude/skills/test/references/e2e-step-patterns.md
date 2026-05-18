# E2E Step Definition Patterns

> Reference cho test-engineer agent khi generate E2E test step definitions từ Cucumber feature files.
> Stack: TypeScript + CucumberJS + Playwright.

---

## Project Structure

```
src/
├── page_objects/               # POM classes extend BasePage
│   ├── base_page.ts            # Base: goto, fill, click, waitFor, expect helpers
│   └── {page}_page.ts          # Per-page classes (LoginPage, DashboardPage)
├── step_definitions/
│   └── web/                    # E2E step definitions
│       ├── common_steps.ts     # Shared: navigation, form, assertions, waits
│       ├── auth_steps.ts       # Login/logout steps
│       └── {feature}_steps.ts  # Feature-specific steps
└── support/
    ├── world.ts                # CustomWorld — this.page (Playwright Page)
    ├── helpers/                # Utility functions
    └── fixture/
        └── account.ts          # getAccountCredentials() per tenant/role
```

---

## Page Object Pattern

### Structure

```typescript
export class ExamplePage extends BasePage {
    // Selectors as private readonly object — KHÔNG hardcode trong methods
    private readonly selectors = {
        usernameInput: '[data-testid="username"]',
        submitButton: 'button[type="submit"]',
        // Dynamic selector dùng function
        menuItem: (name: string) => `[data-testid="menu-${name}"]`,
        tableRow: (index: number) => `[data-testid="table-row-${index}"]`,
    };

    // Action methods — verb-based naming
    async enterUsername(username: string): Promise<void> { ... }
    async clickSubmit(): Promise<void> { ... }

    // Compound actions
    async login(username: string, password: string): Promise<void> { ... }

    // Getter methods for assertions
    async getErrorMessage(): Promise<string> { ... }
    async isErrorVisible(): Promise<boolean> { ... }
}
```

### Conventions

- **Class**: `PascalCase` + `Page` suffix → `LoginPage`, `DashboardPage`
- **File**: `snake_case` + `_page.ts` → `login_page.ts`
- **Methods**: `camelCase`, action-based → `clickLoginButton`, `enterUsername`
- **Selectors**: private readonly, grouped by section (header, sidebar, content, modal)
- **NO assertions trong Page Object** — assertions thuộc về test/step definitions

### Selector Priority

1. `[data-testid="..."]` (preferred)
2. `[data-*]` attributes
3. `[aria-label="..."]`
4. `role=button[name="..."]`
5. CSS selectors `.class`, `#id`
6. XPath (last resort)

### Complex Page — Grouped Selectors

```typescript
private readonly selectors = {
    header: {
        logo: '[data-testid="header-logo"]',
        userMenu: '[data-testid="user-menu"]',
        logoutButton: '[data-testid="logout-btn"]',
    },
    sidebar: {
        menuItem: (name: string) => `[data-testid="menu-${name}"]`,
    },
    content: {
        title: 'h1.page-title',
        loadingSpinner: '.loading-spinner',
    },
    modal: {
        container: '[data-testid="modal"]',
        confirmButton: '[data-testid="modal-confirm"]',
    },
};
```

---

## Step Pattern Catalog

### Authentication Steps

| Gherkin step | Implementation |
|---|---|
| `I am logged in as {string} user` | `getAccountCredentials()` → LoginPage → login → wait dashboard |
| `I am logged in to {string} as {string}` | Tenant-specific → `navigateToTenant(merchantCode)` → login |
| `I logout` | Click user menu → click logout button |

### Navigation Steps

| Gherkin step | Implementation |
|---|---|
| `I am on the {string} page` | Page URL map → `page.goto(baseUrl + path)` → `waitForLoadState('networkidle')` |
| `I navigate to {string}` | Direct `page.goto(baseUrl + path)` |
| `I click the {string} menu item` | `page.click([data-testid="menu-{name}"])` |
| `I go back` | `page.goBack()` |
| `I refresh the page` | `page.reload()` → `waitForLoadState('networkidle')` |

### Form Interaction Steps

| Gherkin step | Implementation |
|---|---|
| `I fill in {string} with {string}` | `page.fill([data-testid="{field}"], value)` |
| `I clear the {string} field` | `page.fill([data-testid="{field}"], '')` |
| `I select {string} from {string} dropdown` | Click dropdown → click option |
| `I check/uncheck the {string} checkbox` | `page.check/uncheck([data-testid="{name}"])` |
| `I upload file {string} to {string}` | `locator.setInputFiles('test-data/{filename}')` |

### Button/Click Steps

| Gherkin step | Implementation |
|---|---|
| `I click the {string} button` | `page.click(button:has-text("{name}"))` |
| `I click on {string}` | `page.click(text={text})` |
| `I double click on {string}` | `page.dblclick(text={text})` |

### Assertion Steps

| Gherkin step | Assertion |
|---|---|
| `I should see {string}` | `expect(locator(text={text})).toBeVisible()` |
| `I should not see {string}` | `expect(locator).not.toBeVisible()` |
| `the {string} field should contain {string}` | `expect(input).toHaveValue(value)` |
| `the {string} should be disabled/enabled` | `expect(locator).toBeDisabled/toBeEnabled()` |
| `I should be on the {string} page` | `expect(page).toHaveURL(regex)` |
| `the page title should be {string}` | `expect(page).toHaveTitle(title)` |

### Wait Steps

| Gherkin step | Implementation |
|---|---|
| `I wait for the page to load` | `page.waitForLoadState('networkidle')` |
| `I wait for {string} to be visible` | `page.waitForSelector(selector, { state: 'visible' })` |
| `I wait for {string} to disappear` | `page.waitForSelector(selector, { state: 'hidden' })` |

### Table/List Steps

| Gherkin step | Implementation |
|---|---|
| `the table should have {int} rows` | `locator('table tbody tr').count()` |
| `row {int} should contain {string}` | `expect(row).toContainText(text)` |

### Modal/Dialog Steps

| Gherkin step | Implementation |
|---|---|
| `I confirm/cancel the dialog` | Click modal confirm/cancel button |
| `I close the modal` | Click modal close button |
| `I should see a modal with title {string}` | `expect(modalTitle).toHaveText(title)` |

### Toast/Notification Steps

| Gherkin step | Implementation |
|---|---|
| `I should see a success message {string}` | `expect(locator('.toast-success')).toContainText(message)` |
| `I should see an error message {string}` | `expect(locator('.toast-error')).toContainText(message)` |

---

## Step Definition File Structure

```typescript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { CustomWorld } from '@support/world';
import { LoginPage } from '@page_objects/login_page';

let loginPage: LoginPage;

Given('I am on the login page', async function (this: CustomWorld) {
    loginPage = new LoginPage(this.page);
    await loginPage.navigate();
});
```

### Hooks Integration

```typescript
Before({ tags: '@login' }, async function (this: CustomWorld) {
    await this.page.context().clearCookies();
});

After({ tags: '@login' }, async function (this: CustomWorld) {
    await this.page.evaluate(() => localStorage.clear());
});
```

---

## Waiting Strategies

| Strategy | When to use |
|---|---|
| `waitForSelector(sel)` | Wait cho element xuất hiện |
| `waitForURL('**/path')` | Wait cho navigation |
| `waitForLoadState('networkidle')` | Wait cho page load xong |
| `waitForResponse(url + status)` | Wait cho API response cụ thể |
| `waitForFunction(() => condition)` | Custom wait condition |

**KHÔNG dùng** `waitForTimeout(ms)` trừ khi không có cách nào khác — gây flaky tests.

---

## Error Handling Pattern

Khi step có thể fail do timing:

```typescript
try {
    await this.page.click(selector, { timeout: 5000 });
} catch (error) {
    await this.page.screenshot({ path: `test-results/screenshots/error-${Date.now()}.png` });
    throw new Error(`Failed: ${error.message}`);
}
```

---

## Code Style

- TypeScript strict typing
- async/await for all Playwright operations
- Import order: cucumber → playwright → page objects → support
- Page Object init trong Given step, reuse trong When/Then
- Export all Page Objects từ `src/page_objects/pages.ts`
