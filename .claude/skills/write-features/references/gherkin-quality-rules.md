# Gherkin Quality Rules

> Reference cho write-features skill và test-engineer agent khi viết/review .feature files.

---

## Golden Rules

### 1. Steps phải đúng thứ tự

```gherkin
# ❌ When không được theo sau Then
Given initial state → When action → Then result → When action2 → Then result2

# ✅ Tách thành 2 scenarios
Scenario: First behavior
  Given → When → Then

Scenario: Second behavior
  Given → When → Then
```

### 2. Step types

- **Given**: Establish state (mô tả tình huống đã tồn tại, KHÔNG phải hành động)
- **When**: Execute action (1 hành động duy nhất)
- **Then**: Verify observable result (từ góc nhìn user, KHÔNG phải implementation)
- **And/But**: Connect steps cùng loại

### 3. Tense and Voice

Luôn **present tense + third person**:

```gherkin
# ✅ Correct
Given Minh có gói trả phí đang active
When Minh yêu cầu xuất hóa đơn
Then hóa đơn được tạo với trạng thái "Nháp"

# ❌ Wrong
Given Minh đã đăng ký gói trả phí     # past tense
When tôi yêu cầu xuất hóa đơn          # first person
Then hóa đơn sẽ được tạo               # future tense
```

### 4. Subject + Predicate

Mỗi step phải có complete subject-predicate structure — reusable independently.

```gherkin
# ❌ Missing subject
Then kết quả hiển thị links related to "panda"
And image links                          # missing subject + predicate
And video links                          # cannot be reused

# ✅ Complete
Then trang kết quả hiển thị text links cho "panda"
And trang kết quả hiển thị image links cho "panda"
```

---

## Cardinal Rules

| Rule | Giải thích |
|------|-----------|
| **1 scenario = 1 behavior** | Nếu có When→Then→When→Then → tách thành 2 scenarios |
| **Declarative, không imperative** | Mô tả business intent, KHÔNG mô tả UI actions |
| **3–5 steps** mỗi scenario (max 9) | Dài hơn → abstract vào Background hoặc persona steps |
| **Rule: mandatory** | Mọi scenario nằm trong Rule: block — để trace về business requirement |

### Declarative vs Imperative

```gherkin
# ✅ DECLARATIVE — mô tả "what"
Scenario: Free subscribers only see free articles
  Given Free Frieda has a free subscription
  When Free Frieda logs in with valid credentials
  Then she sees a free article

# ❌ IMPERATIVE — mô tả "how"
Scenario: Free subscribers only see free articles
  Given the user is on the login page
  When I enter "free@example.com" in the Email field
  And I click the "Submit" button
  Then I see "FreeArticle1" on the homepage
```

**Verification**: "Nếu implementation thay đổi, wording có cần thay đổi không?" Nếu yes → rewrite.

---

## Anti-Patterns

### 1. Procedure-Driven Tests

Multiple When-Then pairs trong 1 scenario → tách.

```gherkin
# ❌ 2 behaviors trong 1 scenario
Scenario: Google image search
  When user enters "panda" in search bar
  Then links related to "panda" are displayed
  When user clicks "Images" link             # ❌ second When-Then
  Then images related to "panda" are displayed

# ✅ Tách thành 2
Scenario: Text search
  Given web browser is at Google homepage
  When user enters "panda" in search bar
  Then links related to "panda" are displayed

Scenario: Image search
  Given search results for "panda" are displayed
  When user clicks "Images" link
  Then images related to "panda" are displayed
```

### 2. Overly Imperative

UI details (click, field, button) thay vì business behavior.

```gherkin
# ❌ Imperative
When I enter "Bob" in the "username" field
And I enter "tester" in the "password" field
And I click the "login" button

# ✅ Declarative
When Bob logs in with valid credentials
```

### 3. Misused Scenario Outline

Equivalent class repetition — không add test value.

```gherkin
# ❌ Same equivalence class
Examples:
  | query    |
  | panda    |
  | elephant |    # same class, no additional value
  | tiger    |

# ✅ Meaningful variations — different behavior per row
Examples:
  | user | subscription | accessible |
  | Free | free         | free articles |
  | Pro  | professional | all articles  |
```

### 4. Hardcoded Test Data

Data có thể thay đổi → brittle tests.

```gherkin
# ❌ Hardcoded — sẽ fail nếu data thay đổi
Then results contain "Panda Express"

# ✅ Pattern validation
Then each result is related to search term "panda"
```

---

## Scenario Outline Checklist

Trước khi dùng Scenario Outline, verify 4 criteria:

1. **Equivalence Class**: Mỗi row = different equivalence class (không chỉ data khác)
2. **Combination**: N fields × M inputs = M^N — manage explosion, consider pairwise
3. **Behavior Separation**: Columns phải relate cùng behavior. Columns independent → tách scenarios
4. **Data Transparency**: Reader CẦN thấy data explicitly? Không → hide trong step defs

---

## Scenario Title Guidelines

- **Concise**: 1 line mô tả behavior
- **Clear**: Hiểu được mà không cần biết feature details
- **User-facing**: Mô tả user value
- **Hoàn thành câu**: "Hệ thống hoạt động đúng khi..."

```gherkin
# ✅ Good
Scenario: Merchant active gửi hóa đơn với dữ liệu hợp lệ
Scenario: Hệ thống từ chối mã số thuế sai format

# ❌ Bad
Scenario: Test 1
Scenario: Check permissions
Scenario: Test nút gửi
```

---

## Step Length Reduction Techniques

1. **Declarative thay imperative**: 8 steps click/type → 1 step "user logs in"
2. **Hide implementation**: "Given John is a new user" thay vì setup email/name/phone
3. **Abstract vào Background**: Preconditions chung cho tất cả scenarios
4. **Persona steps**: "Given Minh là merchant active" encapsulates nhiều setup
