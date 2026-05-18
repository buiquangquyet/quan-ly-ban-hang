# Refactoring Techniques — Catalog

> Reference cho code-refactorer agent khi thực hiện refactoring. Mỗi technique có vấn đề, giải pháp, và steps cụ thể.

## Table of Contents

1. [Composing Methods](#1-composing-methods) — Extract/Inline Method, Extract Variable, Replace Temp
2. [Moving Features between Objects](#2-moving-features-between-objects) — Move Method/Field, Extract Class
3. [Organizing Data](#3-organizing-data) — Encapsulate Field, Replace Magic Number, Replace Type Code
4. [Simplifying Conditional Expressions](#4-simplifying-conditional-expressions) — Decompose/Consolidate Conditional, Replace with Polymorphism
5. [Simplifying Method Calls](#5-simplifying-method-calls) — Rename Method, Parameterize Method, Replace Parameter
6. [Dealing with Generalization](#6-dealing-with-generalization) — Pull Up/Push Down, Extract Interface/Superclass

---

## 1. Composing Methods

Tinh gọn methods, loại bỏ code trùng lặp, mở đường cho cải tiến.

### Extract Method
- **Vấn đề**: Đoạn code có thể nhóm lại, method quá dài, cần comment giải thích đoạn code
- **Giải pháp**: Di chuyển đoạn code vào method mới, đặt tên mô tả mục đích
- **Steps**: 1) Xác định đoạn code cần tách 2) Tạo method mới với tên mô tả 3) Copy code vào method mới 4) Thay đoạn code gốc bằng method call 5) Xác định variables cần truyền làm parameters 6) Run tests

### Inline Method
- **Vấn đề**: Body method rõ ràng như chính tên method, delegation không cần thiết
- **Giải pháp**: Thay lời gọi method bằng nội dung method, xóa method

### Extract Variable
- **Vấn đề**: Biểu thức phức tạp khó hiểu
- **Giải pháp**: Đặt kết quả biểu thức vào biến riêng có tên tự giải thích
- **Steps**: 1) Xác định biểu thức phức tạp 2) Tạo biến mới với tên mô tả 3) Gán biểu thức cho biến 4) Thay biểu thức gốc bằng biến 5) Run tests

### Inline Temp
- **Vấn đề**: Biến tạm chỉ được gán từ biểu thức đơn giản, không dùng cho mục đích khác
- **Giải pháp**: Thay tham chiếu đến biến bằng chính biểu thức

### Replace Temp with Query
- **Vấn đề**: Kết quả biểu thức lưu vào biến local để dùng sau
- **Giải pháp**: Di chuyển biểu thức vào method riêng, gọi method thay vì dùng biến
- **Steps**: 1) Xác định biến tạm chứa biểu thức 2) Tạo method mới trả về giá trị biểu thức 3) Thay tham chiếu biến bằng method call 4) Xóa biến tạm 5) Run tests

### Replace Method with Method Object
- **Vấn đề**: Method dài, biến local đan xen phức tạp khiến không thể Extract Method
- **Giải pháp**: Chuyển method thành class riêng, biến local thành fields, sau đó tách thành methods nhỏ trong class mới

### Substitute Algorithm
- **Vấn đề**: Muốn thay thuật toán hiện tại bằng thuật toán tốt hơn
- **Giải pháp**: Thay body method bằng thuật toán mới, verify cùng output

---

## 2. Moving Features between Objects

Di chuyển chức năng giữa các class an toàn, tạo class mới, ẩn chi tiết implementation.

### Move Method
- **Vấn đề**: Method sử dụng/phụ thuộc vào data của class khác nhiều hơn class hiện tại
- **Giải pháp**: Tạo method mới trong class sử dụng nhiều nhất, chuyển code sang, biến method cũ thành delegate hoặc xóa
- **Steps**: 1) Xác định method cần move 2) Kiểm tra tất cả features method dùng ở class hiện tại 3) Kiểm tra subclasses/superclasses 4) Tạo method mới trong target class 5) Copy code, adjust references 6) Biến method cũ thành delegate hoặc xóa 7) Run tests

### Move Field
- **Vấn đề**: Field được sử dụng nhiều hơn ở class khác
- **Giải pháp**: Tạo field trong class mới, chuyển hướng tất cả code sử dụng field cũ

### Extract Class
- **Vấn đề**: Một class làm công việc của hai class, có nhóm fields/methods luôn đi cùng nhau
- **Giải pháp**: Tạo class mới, di chuyển fields và methods liên quan vào
- **Steps**: 1) Xác định nhóm fields/methods cần tách 2) Tạo class mới 3) Tạo link từ class cũ sang class mới 4) Move Field cho từng field 5) Move Method cho từng method 6) Review và giảm interface 7) Run tests

### Inline Class
- **Vấn đề**: Class gần như không làm gì, không có trách nhiệm rõ ràng
- **Giải pháp**: Di chuyển tất cả features vào class khác, xóa class rỗng

### Hide Delegate
- **Vấn đề**: Client lấy object B từ A, rồi gọi method của B (Law of Demeter violation: `a.getB().doSomething()`)
- **Giải pháp**: Tạo method mới trong A delegate cuộc gọi đến B. Client không cần biết về B

### Remove Middle Man
- **Vấn đề**: Class có quá nhiều methods chỉ delegate sang object khác
- **Giải pháp**: Xóa delegation methods, để client gọi trực tiếp. Ngược lại với Hide Delegate — cần cân bằng

### Introduce Foreign Method
- **Vấn đề**: Utility class (library) thiếu method cần thiết, không thể sửa library
- **Giải pháp**: Tạo method trong client class, truyền instance của utility class làm argument

### Introduce Local Extension
- **Vấn đề**: Utility class thiếu nhiều methods cần thiết
- **Giải pháp**: Tạo class mới kế thừa hoặc wrap utility class, thêm methods cần thiết

---

## 3. Organizing Data

Xử lý dữ liệu, thay primitives bằng class giàu chức năng, gỡ rối associations.

### Self Encapsulate Field
- **Vấn đề**: Truy cập trực tiếp private field bên trong class
- **Giải pháp**: Tạo getter/setter cho field, sử dụng chúng thay vì truy cập trực tiếp

### Replace Data Value with Object
- **Vấn đề**: Data field có behavior và dữ liệu liên quan riêng (VD: string phone number cần validation)
- **Giải pháp**: Tạo class mới chứa field cũ và behavior, lưu object thay vì raw value
- **Steps**: 1) Tạo class mới cho data value 2) Thêm constructor nhận raw value 3) Thêm getter trả về raw value 4) Thay field type trong class cũ 5) Thay references 6) Run tests

### Change Value to Reference
- **Vấn đề**: Nhiều instances giống hệt nhau cần là single shared object
- **Giải pháp**: Chuyển identical objects thành single reference object (registry/factory)

### Change Reference to Value
- **Vấn đề**: Reference object quá nhỏ, ít thay đổi, overhead quản lý không đáng
- **Giải pháp**: Chuyển thành value object (immutable, so sánh bằng giá trị)

### Replace Array with Object
- **Vấn đề**: Array chứa nhiều loại dữ liệu khác nhau (VD: `data[0]` là name, `data[1]` là age)
- **Giải pháp**: Thay array bằng object có fields riêng cho mỗi element

### Duplicate Observed Data
- **Vấn đề**: Domain data lưu trong class chịu trách nhiệm GUI
- **Giải pháp**: Tách data vào domain class riêng, đồng bộ giữa domain và GUI

### Change Unidirectional Association to Bidirectional
- **Vấn đề**: Hai class cần features của nhau nhưng chỉ có one-way association
- **Giải pháp**: Thêm association ngược lại, quản lý cập nhật cả hai phía

### Change Bidirectional Association to Unidirectional
- **Vấn đề**: Bidirectional association nhưng một class không thực sự cần class kia
- **Giải pháp**: Xóa association không cần thiết → giảm dependency

### Replace Magic Number with Symbolic Constant
- **Vấn đề**: Code sử dụng number có ý nghĩa đặc biệt (magic number)
- **Giải pháp**: Thay bằng constant có tên mô tả

### Encapsulate Field
- **Vấn đề**: Public field truy cập trực tiếp từ bên ngoài
- **Giải pháp**: Tạo getter/setter, chuyển field thành private

### Encapsulate Collection
- **Vấn đề**: Method trả về collection, cho phép modification trực tiếp
- **Giải pháp**: Getter trả về read-only view, tạo methods riêng cho add/remove

### Replace Type Code with Class
- **Vấn đề**: Class có field chứa type code không ảnh hưởng behavior
- **Giải pháp**: Tạo class mới cho type code, sử dụng objects thay values

### Replace Type Code with Subclasses
- **Vấn đề**: Type code ảnh hưởng trực tiếp behavior (dùng trong conditionals)
- **Giải pháp**: Tạo subclasses cho mỗi giá trị type code, dùng polymorphism thay conditional
- **Steps**: 1) Tạo subclass cho mỗi type code value 2) Override method trả về type code 3) Di chuyển behavior từ conditional vào subclass methods 4) Xóa conditional 5) Run tests

### Replace Type Code with State/Strategy
- **Vấn đề**: Type code ảnh hưởng behavior VÀ giá trị thay đổi trong object lifetime (không dùng subclass được)
- **Giải pháp**: Thay type code bằng state object, khi cần thay đổi → swap state object

### Replace Subclass with Fields
- **Vấn đề**: Subclasses chỉ khác nhau ở methods trả về constant data
- **Giải pháp**: Thay subclasses bằng fields trong parent class, xóa subclasses

---

## 4. Simplifying Conditional Expressions

Đơn giản hóa conditionals ngày càng phức tạp.

### Decompose Conditional
- **Vấn đề**: Conditional phức tạp (if-then/else hoặc switch) với logic dài trong mỗi branch
- **Giải pháp**: Tách condition, then-branch, else-branch thành separate methods với tên mô tả
- **Steps**: 1) Extract condition thành method (tên mô tả "what", VD: `isWinter()`) 2) Extract then-branch thành method 3) Extract else-branch thành method 4) Run tests

### Consolidate Conditional Expression
- **Vấn đề**: Nhiều conditionals dẫn đến cùng kết quả/hành động
- **Giải pháp**: Gộp thành single expression. Nested → `AND`, consecutive → `OR`

### Consolidate Duplicate Conditional Fragments
- **Vấn đề**: Code giống nhau xuất hiện trong tất cả branches
- **Giải pháp**: Di chuyển code trùng lặp ra ngoài conditional

### Remove Control Flag
- **Vấn đề**: Boolean variable đóng vai trò control flag cho nhiều expressions
- **Giải pháp**: Sử dụng `break`, `continue`, `return` thay vì control flag

### Replace Nested Conditional with Guard Clauses
- **Vấn đề**: Nested conditionals phức tạp, khó xác định luồng chính
- **Giải pháp**: Tách special checks thành guard clauses (early return) trước main logic
- **Steps**: 1) Xác định special/edge cases 2) Chuyển mỗi case thành guard clause với early return 3) Đặt main logic ở cuối (không cần else) 4) Run tests

### Replace Conditional with Polymorphism
- **Vấn đề**: Conditional thực hiện actions khác nhau dựa trên object type/properties
- **Giải pháp**: Tạo subclasses, shared method, di chuyển code từ branch vào method tương ứng
- **Steps**: 1) Tạo subclass cho mỗi branch 2) Tạo abstract method trong parent 3) Move logic từ mỗi branch vào subclass override 4) Thay conditional bằng polymorphic call 5) Run tests

### Introduce Null Object
- **Vấn đề**: Kiểm tra null lặp đi lặp lại ở nhiều nơi
- **Giải pháp**: Tạo Null Object class implement cùng interface, trả về default values

### Introduce Assertion
- **Vấn đề**: Code chỉ hoạt động đúng khi điều kiện nhất định là true, nhưng assumption ẩn
- **Giải pháp**: Thay assumption bằng assertion rõ ràng

---

## 5. Simplifying Method Calls

Làm lời gọi method đơn giản hơn, đơn giản hóa interfaces giữa classes.

### Rename Method
- **Vấn đề**: Tên method không giải thích method làm gì
- **Giải pháp**: Đổi tên cho phù hợp với mục đích

### Add Parameter
- **Vấn đề**: Method không đủ dữ liệu để thực hiện hành động
- **Giải pháp**: Thêm parameter mới. Xem xét Introduce Parameter Object trước

### Remove Parameter
- **Vấn đề**: Parameter không được sử dụng trong body method
- **Giải pháp**: Xóa parameter không dùng

### Separate Query from Modifier
- **Vấn đề**: Method vừa trả về giá trị vừa thay đổi state (side effect)
- **Giải pháp**: Tách thành 2 methods: 1 query (return value), 1 modifier (change state). Command-Query Separation

### Parameterize Method
- **Vấn đề**: Nhiều methods thực hiện actions tương tự, chỉ khác internal values
- **Giải pháp**: Gộp thành một method, dùng parameter cho giá trị khác nhau

### Replace Parameter with Explicit Methods
- **Vấn đề**: Method chia thành các phần dựa trên giá trị parameter (switch trên parameter)
- **Giải pháp**: Tách mỗi phần thành method riêng, gọi trực tiếp

### Preserve Whole Object
- **Vấn đề**: Lấy nhiều giá trị từ object rồi truyền riêng lẻ làm parameters
- **Giải pháp**: Truyền whole object thay vì từng giá trị

### Introduce Parameter Object
- **Vấn đề**: Nhóm parameters lặp lại ở nhiều methods
- **Giải pháp**: Tạo object chứa nhóm parameters, có thể di chuyển behavior liên quan vào class mới
- **Steps**: 1) Tạo class mới cho parameter group 2) Thêm constructor và getters 3) Thêm parameter mới (object) vào methods 4) Thay từng old parameter bằng getter từ object 5) Xóa old parameters 6) Run tests

### Replace Parameter with Method Call
- **Vấn đề**: Gọi method lấy giá trị rồi truyền kết quả làm parameter, nhưng method nhận có thể tự gọi lấy
- **Giải pháp**: Để method tự gọi query, xóa parameter

### Remove Setting Method
- **Vấn đề**: Field chỉ nên set khi tạo object, không thay đổi sau đó
- **Giải pháp**: Xóa setter, set giá trị qua constructor → immutable

### Hide Method
- **Vấn đề**: Method không được sử dụng bởi class khác
- **Giải pháp**: Chuyển method thành private/protected

### Replace Constructor with Factory Method
- **Vấn đề**: Constructor phức tạp, cần trả về different subtypes
- **Giải pháp**: Tạo factory method, naming rõ nghĩa hơn constructor

### Replace Error Code with Exception
- **Vấn đề**: Method trả về giá trị đặc biệt để chỉ lỗi (VD: return -1)
- **Giải pháp**: Throw exception → tách error handling khỏi logic chính

### Replace Exception with Test
- **Vấn đề**: Exception throw trong trường hợp có thể kiểm tra trước bằng simple test
- **Giải pháp**: Thay exception bằng condition test (check trước khi execute)

---

## 6. Dealing with Generalization

Di chuyển chức năng trong class inheritance hierarchy, tạo interfaces, thay inheritance bằng delegation.

### Pull Up Field
- **Vấn đề**: Hai subclasses có cùng field
- **Giải pháp**: Di chuyển field lên superclass

### Pull Up Method
- **Vấn đề**: Subclasses có methods thực hiện công việc tương tự
- **Giải pháp**: Làm methods giống nhau, di chuyển lên superclass

### Pull Up Constructor Body
- **Vấn đề**: Subclasses có constructors với code gần giống nhau
- **Giải pháp**: Tạo superclass constructor chứa code chung, gọi từ subclass constructors

### Push Down Method
- **Vấn đề**: Behavior chỉ dùng bởi một/vài subclass, nằm ở superclass
- **Giải pháp**: Di chuyển method xuống subclass tương ứng

### Push Down Field
- **Vấn đề**: Field chỉ dùng bởi một/vài subclass
- **Giải pháp**: Di chuyển field xuống subclass tương ứng

### Extract Subclass
- **Vấn đề**: Class có features chỉ dùng trong một số trường hợp nhất định
- **Giải pháp**: Tạo subclass cho các trường hợp đó

### Extract Superclass
- **Vấn đề**: Hai class có chung fields và methods
- **Giải pháp**: Tạo shared superclass, di chuyển identical fields/methods vào
- **Steps**: 1) Tạo abstract superclass 2) Pull Up common fields 3) Pull Up common methods 4) Adjust subclass references 5) Run tests

### Extract Interface
- **Vấn đề**: Nhiều clients dùng cùng phần của class interface, hoặc hai class có methods giống nhau
- **Giải pháp**: Di chuyển phần identical vào interface riêng

### Collapse Hierarchy
- **Vấn đề**: Subclass gần như giống hệt superclass
- **Giải pháp**: Merge subclass và superclass

### Form Template Method
- **Vấn đề**: Subclasses implement algorithms chứa steps tương tự theo cùng thứ tự
- **Giải pháp**: Di chuyển algorithm structure lên superclass, để implementation khác nhau ở subclasses (Template Method Pattern)

### Replace Inheritance with Delegation
- **Vấn đề**: Subclass chỉ dùng phần nhỏ methods của superclass, hoặc vi phạm Liskov Substitution
- **Giải pháp**: Tạo field chứa superclass object, delegate methods, bỏ inheritance
- **Steps**: 1) Tạo field kiểu superclass trong subclass 2) Tạo delegating methods cho methods đang dùng 3) Xóa inheritance relationship 4) Thay extends bằng composition 5) Run tests

### Replace Delegation with Inheritance
- **Vấn đề**: Class chứa nhiều methods chỉ delegate sang tất cả methods của class khác
- **Giải pháp**: Kế thừa delegate class, bỏ delegation. Chỉ dùng khi thực sự IS-A relationship
