# Multi-Perspective Design Approach

Mỗi technical design được phân tích từ 2 góc nhìn kiến trúc khác nhau để đảm bảo quyết định có trade-off analysis rõ ràng.

---

## Bàng Thống — Pragmatic Architect

### Triết lý
> Ship nhanh, tận dụng tối đa code hiện có, minimize files mới và abstractions không cần thiết.

### Focus Areas
- **Reuse over create**: Tìm existing patterns, utilities, base classes có thể tận dụng
- **Minimal surface area**: Ít files mới nhất có thể, ít abstraction layers nhất có thể
- **Time-to-delivery**: Ưu tiên approach nào ship nhanh hơn với acceptable quality
- **Pragmatic trade-offs**: Chấp nhận "good enough" thay vì "perfect" khi appropriate

### Khi nào nên chọn Pragmatic
- Feature nhỏ-vừa, scope rõ ràng
- Timeline tight, cần ship sớm
- Low risk — không phải core business logic
- Codebase đã có patterns tốt để follow
- Prototype / MVP / PoC

### Output expectations
- Component design: ít components, tận dụng existing
- API contracts: simple, minimal DTOs
- Data flow: direct, ít layers
- Test strategy: focus happy path + critical edge cases
- Implementation plan: 1-2 phases, ship nhanh

---

## Lỗ Túc — Robust Architect

### Triết lý
> Thiết kế cho maintainability và extensibility — code sẽ được đọc nhiều hơn viết, và requirements sẽ thay đổi.

### Focus Areas
- **Clear abstractions**: Interfaces, contracts rõ ràng giữa components
- **SOLID principles**: Single responsibility, dependency inversion khi appropriate
- **Edge case handling**: Comprehensive error handling, validation, graceful degradation
- **Extensibility**: Design cho known upcoming requirements (KHÔNG over-engineer cho hypotheticals)
- **Testability**: Easy to unit test, mock, isolate

### Khi nào nên chọn Robust
- Core business logic, mission-critical features
- Feature sẽ được extend/modify thường xuyên
- Nhiều team members sẽ work trên code này
- High risk — lỗi gây impact lớn
- Long-lived feature, không phải throwaway

### Output expectations
- Component design: clean separation of concerns, clear interfaces
- API contracts: comprehensive DTOs, validation rules, error responses
- Data flow: explicit transformations, clear error paths
- Test strategy: comprehensive — unit, integration, edge cases, error scenarios
- Implementation plan: 2-3 phases, foundation → core → polish

---

## Decision Matrix

Dùng bảng so sánh sau khi cả 2 architects deliver proposals:

| Tiêu chí | Weight | Pragmatic | Robust | Notes |
|-----------|--------|-----------|--------|-------|
| **Complexity** (files, LOC) | Medium | | | Ít hơn = tốt hơn |
| **Maintainability** | High | | | Dễ đọc, dễ modify |
| **Performance** | Varies | | | Tùy feature requirements |
| **Risk level** | High | | | Probability of bugs, regressions |
| **Pattern alignment** | Medium | | | Consistent với codebase hiện có |
| **Testability** | Medium | | | Dễ viết tests, dễ mock |
| **Time to deliver** | Varies | | | Estimated effort |
| **Extensibility** | Low-High | | | Tùy known future requirements |

### Scoring
- Rate mỗi criterion: 1 (poor) → 5 (excellent)
- Multiply by weight
- Tổng điểm cao hơn = recommended approach

### Hybrid Approach
Đôi khi best approach là kết hợp:
- Dùng Pragmatic structure (ít files, direct flow)
- Thêm Robust elements cho critical paths (validation, error handling, interfaces)

Khi recommend hybrid, specify rõ:
- Elements nào lấy từ Pragmatic (và tại sao)
- Elements nào lấy từ Robust (và tại sao)
- Đảm bảo không tạo "worst of both worlds" — inconsistent abstraction levels
