# Feature Discovery — Worked Examples

## Example 1: Solution-First Discovery

**Input**: `/feature-discovery Tôi muốn thêm notification khi đơn hàng thay đổi trạng thái`

**Mode identified**: Solution-first — user đề xuất solution cụ thể, cần uncover problem trước.

**Session trace**:

1. **Frame**: Tóm tắt: "User muốn notification system cho order status changes. Trước khi design solution, cần hiểu problem đằng sau."
2. Hỏi: "Ai đang gặp vấn đề thiếu thông tin về trạng thái đơn hàng — seller, buyer, hay admin?"
3. → "Buyer thường không biết đơn hàng đã ship"
4. Hỏi: "Họ đang làm gì để track đơn hàng hiện tại? Call customer support? Tự vào app check?"
5. → "Phần lớn gọi CS để hỏi — team CS cho biết 40% volume là câu hỏi về order status"
6. Hỏi: "Nếu buyer tự biết được status mà không cần gọi CS, 40% volume đó giảm được bao nhiêu?"
7. → "Ước tính giảm được 60-70% những câu hỏi về status nếu notification đúng timing"
8. Hỏi: "Tất cả status changes hay chỉ milestone quan trọng — confirmed, shipped, delivered?"
9. → "Chỉ 3 milestones quan trọng: confirmed, shipped, delivered. Các status intermediate không cần"
10. Hỏi: "Push notification, email, hay SMS? Buyer có app không?"
11. → "70% buyer dùng app mobile — push notification + email fallback"

**Feature Brief output**:

```markdown
# Feature Brief: Order Status Notification

## Problem Statement
40% volume customer support đến từ buyer hỏi về trạng thái đơn hàng — buyers không có cách 
chủ động biết order đã được xử lý, ship, hay delivered mà không cần vào app check hoặc gọi CS.
Impact: CS overloaded, buyer experience kém, trust giảm.

## Target Users
| Role | Pain Point | Current Workaround |
|------|-----------|-------------------|
| Buyer | Không biết order status thay đổi | Gọi CS hoặc vào app check thủ công |
| CS Team | 40% ticket là câu hỏi về order status | Manual lookup và reply |

## Jobs-to-be-Done
Khi đặt hàng xong, buyer muốn được thông báo chủ động khi có milestone quan trọng
để không cần chủ động check hay gọi CS.

## Proposed Feature Direction
Push notification (+ email fallback) cho 3 key milestones: Order Confirmed, Shipped, Delivered.
Không notify tất cả status changes — chỉ những milestones buyer cần hành động hoặc cần biết.

## Key Capabilities Needed
- Trigger notification khi order status đạt 3 milestones: confirmed, shipped, delivered
- Push notification cho buyers có app (70% base)
- Email fallback cho buyers không có app
- Buyer có thể opt-out notification settings

## Success Metrics
- CS ticket về order status: 40% volume → giảm 25%+ trong tháng đầu
- Buyer satisfaction (CSAT): baseline → tăng 5+ points

## Constraints
- **Technical**: Push notification infrastructure cần setup nếu chưa có
- **Business**: Không notify quá nhiều — risk unsubscribe

## Out of Scope
- Notification cho tất cả status intermediate (quá nhiều noise)
- SMS notification (cost, phase 2 nếu cần)
- Seller notification (separate feature)

## Key Assumptions to Validate
| Assumption | Confidence | How to Validate |
|-----------|-----------|----------------|
| 40% CS volume có thể giảm bằng notification | Medium | Pilot với 10% buyers, measure CS ticket rate |
| Buyers prefer push over email | Medium | Survey 50 buyers, check existing app notification opt-in rate |

## Open Questions
- Notification template content — cần UX writer review
- Deep link từ notification vào order detail screen — cần confirm với mobile team
```

**Handoff**: Feature Brief đủ để làm input cho `/write-prd`. Discovery identified root cause (buyer không có proactive update), quantified impact (40% CS volume), narrowed scope (3 milestones only), và flagged 2 assumptions cần validate.

---

## Example 2: Problem-First Discovery

**Input**: `/feature-discovery Nhân viên kho mất nhiều thời gian nhập liệu thủ công`

**Mode identified**: Problem-first — user mô tả vấn đề, cần explore root cause và solution space.

**Session trace**:

1. **Frame**: "Problem: manual data entry ở kho mất nhiều thời gian. Cần hiểu rõ nhập gì, nhập vào đâu, và tại sao manual."
2. Hỏi: "Nhập liệu thủ công cho quy trình nào cụ thể? Nhập inventory, nhập đơn hàng, hay gì khác?"
3. → "Sau mỗi lần kiểm kê kho (cycle count), nhân viên đếm và ghi ra giấy, về phòng nhập vào Excel, sau đó nhập lại vào hệ thống ERP"
4. Hỏi: "Tần suất cycle count? Bao nhiêu SKU mỗi lần?"
5. → "Daily cycle count 200-300 SKU, weekly full count ~2000 SKU. Nhập liệu chiếm 2-3 giờ mỗi ngày"
6. Hỏi: "Tại sao không nhập trực tiếp vào ERP mà phải qua Excel?"
7. → "ERP không có mobile app, nhân viên kho không có laptop — chỉ có máy tính bàn ở phòng"
8. **5 Whys trigger**: "Vậy root cause là ERP không accessible tại điểm count, không phải là 'thiếu tính năng nhập liệu'"
9. Hỏi: "Warehouse có WiFi phủ sóng toàn bộ không?"
10. → "Có WiFi nhưng không ổn định ở khu vực kệ hàng phía trong"
11. Hỏi: "Nhân viên kho có smartphone không? Company device hay personal?"
12. → "Có smartphone cá nhân, nhưng công ty không muốn dùng app trên personal device vì security"
13. **Inversion**: "Điều gì sẽ làm solution này fail? → Network unstable, device management, adoption"
14. Hỏi: "Budget cho hardware (scanner, tablet) như thế nào?"
15. → "Có budget tối đa $200/device, cần 5 devices cho 5 nhân viên kho"

**Feature Brief output**:

```markdown
# Feature Brief: Warehouse Cycle Count Mobile Entry

## Problem Statement
Nhân viên kho mất 2-3 giờ/ngày nhập liệu thủ công kết quả cycle count — do quy trình hiện tại 
yêu cầu 3 bước (giấy → Excel → ERP), xuất phát từ việc ERP không accessible tại điểm count 
trong warehouse. Root cause: thiếu mobile data entry tool cho warehouse floor.

## Target Users
| Role | Pain Point | Current Workaround |
|------|-----------|-------------------|
| Nhân viên kho | Nhập liệu 3-step mất 2-3h/ngày | Ghi giấy → Excel → ERP |
| Warehouse Manager | Data không real-time, lag 3-4 giờ | Accept delay, manual reconcile |

## Jobs-to-be-Done
Khi thực hiện cycle count tại kệ hàng, nhân viên kho muốn ghi nhận số lượng ngay lập tức
tại điểm đếm để không cần quay lại phòng nhập máy tính.

## Proposed Feature Direction
Mobile-optimized data entry cho cycle count — barcode scan + quantity input, 
offline-capable (sync khi có network), chạy trên company-managed tablet ($200 budget, 5 devices).
Loại bỏ giấy và Excel hoàn toàn, sync trực tiếp vào ERP inventory records.

## Key Capabilities Needed
- Barcode/QR scan để identify SKU (không cần nhập tay SKU code)
- Quantity input với numeric keypad
- Offline mode — queue sync khi mất network, tự sync khi restore
- Sync real-time vào ERP inventory module
- Review/correction mode trước khi commit count

## Success Metrics
- Data entry time: 2-3h/ngày → dưới 45 phút
- Data accuracy: giảm nhập sai do double-entry errors
- ERP data freshness: lag 3-4h → real-time (within 15 phút)

## Constraints
- **Hardware**: Company-managed tablets, budget $200/device, 5 devices
- **Network**: WiFi không ổn định ở một số khu vực — offline mode required
- **Security**: Không dùng personal device — app phải chạy trên company device với MDM

## Out of Scope
- Full WMS (Warehouse Management System) replacement
- Receiving / putaway workflows (different team, different process)
- Integration với vendor barcode systems (phase 2)

## Key Assumptions to Validate
| Assumption | Confidence | How to Validate |
|-----------|-----------|----------------|
| Barcode labels đã có trên tất cả SKU | Medium | Physical check với warehouse team |
| ERP API hỗ trợ inventory update | Unknown | Tech spike — check ERP docs/vendor |
| WiFi có thể được cải thiện hoặc offline mode đủ | Medium | Network assessment |

## Open Questions
- ERP vendor có mobile SDK không? Hay cần build custom integration?
- MDM solution nào đang dùng? Có support Android tablets không?
- Approval workflow — count cần manager approve trước khi commit vào ERP?
```

**Handoff**: Feature Brief ready. Discovery shifted từ "tính năng nhập liệu" (vague) thành "mobile offline-capable cycle count tool" (specific). Key insight: root cause là accessibility gap, không phải thiếu feature. 3 assumptions cần validate trước khi commit PRD.

---

## Lessons from Examples

**Solution-first pattern**: Luôn ask "vấn đề gì?" trước khi accept solution. Trong Example 1, solution (notification) đúng hướng nhưng scope cần narrowing (không phải tất cả status).

**Problem-first pattern**: Drill down với 5 Whys — "nhập liệu thủ công" (symptom) → "không có mobile access" (root cause). Solution space mở ra khi hiểu đúng root cause.

**Assumption identification**: Cả 2 examples đều có assumptions cần validate trước khi write PRD. Feature Brief Quality Checklist giúp ensure không miss critical unknowns.
