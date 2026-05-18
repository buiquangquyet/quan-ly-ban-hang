# Code Smells — Catalog

> Reference cho code-explorer agent khi scan code. Mỗi smell có dấu hiệu cụ thể để nhận biết và techniques recommended để fix.

---

## 1. Bloaters

Code, method và class phình to đến mức khó làm việc. Tích lũy dần theo thời gian.

### Long Method
- **Dấu hiệu**: Method > ~20 dòng, cần comment giải thích từng đoạn, nhiều indent levels, nhiều biến local
- **Hậu quả**: Khó đọc, khó test, khó reuse logic bên trong
- **Techniques**: Extract Method, Replace Temp with Query, Introduce Parameter Object, Decompose Conditional

### Large Class
- **Dấu hiệu**: Quá nhiều fields (>7), quá nhiều methods (>15), tên class cần từ "And", class gánh nhiều trách nhiệm
- **Hậu quả**: Vi phạm Single Responsibility, khó hiểu toàn bộ class, merge conflicts thường xuyên
- **Techniques**: Extract Class, Extract Subclass, Extract Interface

### Primitive Obsession
- **Dấu hiệu**: Dùng string/int thay vì tạo class riêng (VD: string cho email, phone, money). Dùng constants cho type codes. Dùng string làm field names
- **Hậu quả**: Thiếu validation, logic xử lý rải rác, khó thêm behavior
- **Techniques**: Replace Data Value with Object, Replace Type Code with Class/Subclasses/State-Strategy, Introduce Parameter Object

### Long Parameter List
- **Dấu hiệu**: Method có > 3-4 tham số, khó nhớ thứ tự, dễ truyền sai
- **Hậu quả**: Khó đọc, khó test, dễ bug khi truyền sai thứ tự
- **Techniques**: Replace Parameter with Method Call, Preserve Whole Object, Introduce Parameter Object

### Data Clumps
- **Dấu hiệu**: Nhóm biến giống nhau lặp lại ở nhiều nơi (VD: startDate + endDate + timezone). Xóa 1 biến → các biến còn lại mất ý nghĩa
- **Hậu quả**: Code trùng lặp, thay đổi phải sửa nhiều chỗ
- **Techniques**: Extract Class, Introduce Parameter Object, Preserve Whole Object

---

## 2. Object-Orientation Abusers

Áp dụng OOP principles không đúng hoặc không đầy đủ.

### Switch Statements
- **Dấu hiệu**: switch/case phức tạp hoặc chuỗi if-else dài dựa trên type/condition, bị duplicate ở nhiều nơi trong codebase
- **Hậu quả**: Thêm type mới phải sửa tất cả switch statements, vi phạm Open/Closed Principle
- **Techniques**: Replace Conditional with Polymorphism, Replace Type Code with Subclasses/State-Strategy, Extract Method

### Temporary Field
- **Dấu hiệu**: Object có field chỉ được set trong một số tình huống, còn lại null/empty. Field chỉ có giá trị sau khi gọi method cụ thể
- **Hậu quả**: Người đọc expect tất cả fields có giá trị → confusion, null reference errors
- **Techniques**: Extract Class, Introduce Null Object

### Refused Bequest
- **Dấu hiệu**: Subclass chỉ dùng một phần nhỏ methods/properties kế thừa. Override methods để throw exception hoặc return empty
- **Hậu quả**: Vi phạm Liskov Substitution Principle, hierarchy không đúng
- **Techniques**: Replace Inheritance with Delegation, Extract Superclass

### Alternative Classes with Different Interfaces
- **Dấu hiệu**: Hai class thực hiện chức năng tương tự nhưng tên method khác nhau
- **Hậu quả**: Không thể swap implementations, duplicate logic ẩn
- **Techniques**: Rename Method, Move Method, Extract Superclass

---

## 3. Change Preventers

Thay đổi code ở một chỗ buộc phải thay đổi nhiều chỗ khác. Chi phí phát triển tăng đáng kể.

### Divergent Change
- **Dấu hiệu**: Một class thường xuyên thay đổi theo nhiều hướng khác nhau. VD: thêm product type mới → sửa search, display, order trong cùng 1 class
- **Hậu quả**: Class quá nhiều trách nhiệm, mỗi thay đổi nhỏ ảnh hưởng code không liên quan
- **Techniques**: Extract Class, Extract Superclass, Extract Subclass

### Shotgun Surgery
- **Dấu hiệu**: Một thay đổi nhỏ đòi hỏi sửa nhiều class khác nhau cùng lúc. Logic liên quan rải rác khắp codebase
- **Hậu quả**: Dễ miss một chỗ cần sửa, high risk of bugs
- **Techniques**: Move Method, Move Field, Inline Class

### Parallel Inheritance Hierarchies
- **Dấu hiệu**: Mỗi khi tạo subclass cho class A, phải tạo subclass tương ứng cho class B
- **Hậu quả**: Duplicate hierarchy, thêm type mới tốn gấp đôi effort
- **Techniques**: Move Method, Move Field

---

## 4. Dispensables

Những thứ vô nghĩa, không cần thiết — loại bỏ sẽ làm code sạch và hiệu quả hơn.

### Comments (Excessive)
- **Dấu hiệu**: Method đầy comment giải thích. Comment mô tả "what" thay vì "why". Code cần comment nhiều mới hiểu
- **Hậu quả**: Comment lỗi thời gây misleading, code chưa đủ self-documenting
- **Techniques**: Extract Variable, Extract Method, Rename Method

### Duplicate Code
- **Dấu hiệu**: Hai đoạn code giống hệt hoặc gần giống tồn tại ở nhiều nơi. Copy-paste pattern
- **Hậu quả**: Bug fix ở 1 chỗ quên chỗ kia, maintenance cost nhân đôi
- **Techniques**: Extract Method, Extract Superclass, Form Template Method

### Lazy Class
- **Dấu hiệu**: Class quá nhỏ, gần như không làm gì. Tạo ra để "phòng hờ" nhưng chưa cần
- **Hậu quả**: Thêm indirection không cần thiết, tăng codebase complexity
- **Techniques**: Inline Class, Collapse Hierarchy

### Data Class
- **Dấu hiệu**: Class chỉ chứa fields và getter/setter, không có behavior. Dùng như data container
- **Hậu quả**: Logic xử lý data nằm ở class khác (Feature Envy), vi phạm encapsulation
- **Techniques**: Encapsulate Field, Move Method, Extract Method, Remove Setting Method

### Dead Code
- **Dấu hiệu**: Variable, parameter, field, method hoặc class không còn được sử dụng. Code bị comment out
- **Hậu quả**: Gây confusion, tăng noise, false sense of complexity
- **Techniques**: Delete unused code, Inline Class, Collapse Hierarchy, Remove Parameter

### Speculative Generality
- **Dấu hiệu**: Abstract classes, interfaces, parameters, methods tạo "phòng hờ" cho tương lai nhưng chưa bao giờ dùng. YAGNI violation
- **Hậu quả**: Unnecessary complexity, harder to understand actual flow
- **Techniques**: Collapse Hierarchy, Inline Class, Inline Method, Remove Parameter

---

## 5. Couplers

Coupling quá mức giữa các class, hoặc delegation quá mức.

### Feature Envy
- **Dấu hiệu**: Method truy cập dữ liệu của object khác nhiều hơn dữ liệu của chính nó. Nhiều getter calls đến object khác
- **Hậu quả**: Logic nằm sai chỗ, thay đổi data class buộc sửa class khác
- **Techniques**: Move Method, Extract Method

### Inappropriate Intimacy
- **Dấu hiệu**: Một class sử dụng internal fields/methods của class khác. Hai class biết quá nhiều về nhau. Bidirectional dependencies
- **Hậu quả**: Tight coupling, thay đổi 1 class break class kia
- **Techniques**: Move Method, Move Field, Extract Class, Hide Delegate, Change Bidirectional to Unidirectional

### Message Chains
- **Dấu hiệu**: Chuỗi gọi kiểu `a.getB().getC().getD()`. Client phụ thuộc vào cả navigation chain
- **Hậu quả**: Thay đổi bất kỳ mắt xích nào đều ảnh hưởng client, Law of Demeter violation
- **Techniques**: Hide Delegate, Extract Method, Move Method

### Middle Man
- **Dấu hiệu**: Class chỉ delegate sang class khác. Phần lớn methods đều forward calls
- **Hậu quả**: Class vô nghĩa, thêm indirection không cần thiết
- **Techniques**: Remove Middle Man, Inline Method, Replace Delegation with Inheritance

### Incomplete Library Class
- **Dấu hiệu**: Library/framework không cung cấp đủ tính năng cần thiết, không thể sửa library
- **Hậu quả**: Workarounds rải rác, code khó maintain
- **Techniques**: Introduce Foreign Method, Introduce Local Extension
