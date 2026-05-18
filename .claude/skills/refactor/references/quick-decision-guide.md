# Quick Decision Guide

> Reference nhanh: chọn technique phù hợp dựa trên code smell hoặc triệu chứng.

---

## Khi nào KHÔNG nên Refactor

Dừng lại và thông báo user nếu gặp các trường hợp sau:

- **Code cần viết lại từ đầu** — quá broken để sửa incrementally, architecture sai căn bản
- **Deadline quá gấp** — ghi nhận technical debt, refactor sau. Không refactor dưới áp lực thời gian
- **Không có test coverage** — viết tests trước khi refactor, vì không có tests thì không thể verify behavior preservation
- **Code đang deprecation** — sắp bị xóa/thay thế, refactor là lãng phí effort

---

## Khi nào NÊN Refactor (Rule of Three)

- **Lần đầu**: Cứ làm
- **Lần hai**: Tương tự? OK, tiếp tục
- **Lần ba**: Bắt đầu refactor!

Thời điểm tốt:
- Khi thêm feature mới — refactor trước giúp thêm feature dễ hơn
- Khi fix bug — code bẩn thường che giấu bug
- Khi code review — cơ hội cuối dọn dẹp trước khi merge

---

## Decision Tree

```
Code quá dài?
├── Method dài → Extract Method
├── Class lớn → Extract Class / Extract Subclass
└── Parameter list dài → Introduce Parameter Object

Logic nằm sai chỗ?
├── Method dùng data class khác nhiều hơn → Move Method
├── Field dùng ở class khác nhiều hơn → Move Field
└── Nhóm fields/methods luôn đi cùng → Extract Class

Conditional phức tạp?
├── If-else dài dựa trên type → Replace Conditional with Polymorphism
├── Nested conditions → Replace Nested Conditional with Guard Clauses
├── Nhiều conditions cùng result → Consolidate Conditional Expression
└── Complex condition → Decompose Conditional

Inheritance có vấn đề?
├── Subclass dùng ít parent methods → Replace Inheritance with Delegation
├── Hai class có code chung → Extract Superclass
├── Subclass gần giống parent → Collapse Hierarchy
└── Tạo subclass A → phải tạo subclass B → Move Method/Field

Coupling quá cao?
├── Chain calls a.b().c().d() → Hide Delegate
├── Class biết quá nhiều về class khác → Move Method/Field, Extract Class
└── Class chỉ delegate → Remove Middle Man
```

---

## Smell → Technique Mapping

| Code Smell | Primary Techniques | Secondary Techniques |
|---|---|---|
| **Bloaters** | | |
| Long Method | Extract Method | Replace Temp with Query, Decompose Conditional |
| Large Class | Extract Class | Extract Subclass, Extract Interface |
| Primitive Obsession | Replace Data Value with Object | Replace Type Code with Class/Subclasses/State-Strategy |
| Long Parameter List | Introduce Parameter Object | Preserve Whole Object, Replace Parameter with Method Call |
| Data Clumps | Extract Class | Introduce Parameter Object, Preserve Whole Object |
| **OO Abusers** | | |
| Switch Statements | Replace Conditional with Polymorphism | Replace Type Code with Subclasses/State-Strategy |
| Temporary Field | Extract Class | Introduce Null Object |
| Refused Bequest | Replace Inheritance with Delegation | Extract Superclass |
| Alternative Classes with Different Interfaces | Rename Method | Extract Superclass, Move Method |
| **Change Preventers** | | |
| Divergent Change | Extract Class | Extract Superclass, Extract Subclass |
| Shotgun Surgery | Move Method, Move Field | Inline Class |
| Parallel Inheritance Hierarchies | Move Method, Move Field | — |
| **Dispensables** | | |
| Comments (Excessive) | Extract Method, Rename Method | Extract Variable |
| Duplicate Code | Extract Method | Extract Superclass, Form Template Method |
| Lazy Class | Inline Class | Collapse Hierarchy |
| Data Class | Encapsulate Field, Move Method | Remove Setting Method |
| Dead Code | Delete unused code | Remove Parameter |
| Speculative Generality | Collapse Hierarchy, Inline Class | Remove Parameter, Inline Method |
| **Couplers** | | |
| Feature Envy | Move Method | Extract Method |
| Inappropriate Intimacy | Move Method, Move Field | Hide Delegate, Extract Class |
| Message Chains | Hide Delegate | Extract Method, Move Method |
| Middle Man | Remove Middle Man | Inline Method |
| Incomplete Library Class | Introduce Foreign Method | Introduce Local Extension |

---

## Prioritization Guide

Khi có nhiều smells, ưu tiên theo thứ tự impact:

1. **Change Preventers** (Divergent Change, Shotgun Surgery) — ảnh hưởng mọi thay đổi tương lai, ROI cao nhất
2. **Couplers** (Feature Envy, Inappropriate Intimacy) — tight coupling làm chậm development, high risk
3. **Bloaters** (Long Method, Large Class) — khó đọc, khó maintain, nhưng thường ít risky hơn
4. **OO Abusers** (Switch Statements, Refused Bequest) — cản trở extensibility
5. **Dispensables** (Dead Code, Duplicate Code, Lazy Class) — low risk, easy wins, làm cuối

> **Nguồn tham khảo**: Refactoring.Guru, "Refactoring: Improving the Design of Existing Code" — Martin Fowler
