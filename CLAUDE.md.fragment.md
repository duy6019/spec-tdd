<!-- Dán khối này vào CLAUDE.md ở gốc project đích.                            -->
<!-- Đặt NGOÀI cặp <!-- OPENSPEC:START --> … <!-- OPENSPEC:END -->,            -->
<!-- nếu không `openspec update` sẽ ghi đè.                                    -->
<!-- Sửa ngưỡng nâng tầng ở mục "Việc đầu tiên" cho khớp domain của project.   -->

## Định tuyến công việc (đọc mỗi phiên)

Repo này dùng schema OpenSpec `spec-tdd` (hai tầng) ghép với superpowers.
Bối cảnh project và các nguyên tắc bất di bất dịch nằm trong `openspec/config.yaml`.

### Việc đầu tiên, trước khi gọi bất kỳ skill nào

Với mọi yêu cầu thêm tính năng hoặc sửa lỗi, hành động đầu tiên là chạy `openspec list`
rồi phân tầng. **Không brainstorm trước bước này.**

- **NHẸ — mặc định.** Thay đổi nằm trong một module, không thêm dependency, không đổi
  định dạng dữ liệu hay contract nào.
- **NẶNG** — chỉ khi vượt ranh giới module, có migration dữ liệu, đụng contract bên
  ngoài, hoặc tôi gõ đúng chữ **LARGE CHANGE**.
  <!-- Thay hai gạch đầu dòng trên bằng tiêu chí thật của project. -->

Bạn được phép **đề xuất** nâng lên NẶNG. Bạn không được tự quyết, và không được đổi tầng
giữa chừng.

### Tầng NHẸ

Đây là chỉ thị thường trực của tôi, dùng đúng quyền ưu tiên mà `superpowers:using-superpowers`
đã cấp cho user instructions. **Tôi đang nói rõ với bạn rằng hãy bỏ qua các bước sau:**

- **Bỏ `superpowers:writing-plans`.** Tầng nhẹ không có plan file.
- Nếu `superpowers:brainstorming` được gọi, **trạng thái kết thúc của nó trong repo này
  KHÔNG phải `writing-plans`**. Kết quả ghi vào `openspec/changes/<name>/proposal.md` và
  `openspec/changes/<name>/specs/`, rồi dừng.
- **Không ghi vào `docs/superpowers/`.**

Đường đi: `/opsx:propose` → `/opsx:apply` → `openspec archive <name>`.

### Tầng NẶNG

Thêm `design.md`, `tasks.md`, và `<change-name>-plan.md` do `superpowers:writing-plans`
viết — ghi thẳng vào thư mục change, **không** vào `docs/superpowers/plans/`.

Tên file plan phải là `<change-name>-plan.md`, **không bao giờ** là `plan.md`:
`sdd-workspace` lấy slug từ tên file, đặt trùng thì mọi change dùng chung một workspace
và ghi đè ledger của nhau.

### Chỉ thị thường trực khác

- **Worktree là tuỳ chọn, mặc định KHÔNG tạo.** Làm thẳng trên nhánh hiện tại. Nếu bạn
  thấy thay đổi này thật sự cần cách ly, hãy **hỏi tôi trước** và nói rõ vì sao — tôi
  quyết. Không bao giờ tự tạo worktree rồi mới báo.
- **Commit là quyền của tôi.** Đừng tự commit. Khi một mẩu việc xong, dừng lại và báo tôi
  những gì đã thay đổi; tôi sẽ nói khi nào commit và gộp bao nhiêu vào một commit. Điều
  này ghi đè bước "Commit" mặc định trong plan do `superpowers:writing-plans` sinh ra và
  bước commit trong prompt của implementer subagent.
- **Đóng change bằng CLI:** `openspec archive <name>`. Không dùng `/opsx:sync` — đó là
  đường merge do agent tự làm, không có chốt chặn mất scenario.
- **Archive TRƯỚC khi** gọi `superpowers:finishing-a-development-branch`.
- **ADDED nghĩa là "chưa có trong spec", không phải "chưa có trong code."** Nếu
  `openspec/specs/` mới bắt đầu từ con số không thì gần như mọi delta đầu tiên của một
  capability đều là ADDED. Dùng MODIFIED cho thứ chưa có trong spec chính sẽ khiến
  `openspec archive` báo lỗi cứng — và chỉ báo lúc archive, tức là sau khi đã code xong.
- **Không back-fill spec.** Không dựng lại spec cho phần code đã có. Chỉ viết spec cho
  thứ bạn sắp thay đổi.

### Test trên code chưa có lưới an toàn

Khai loại test **trước khi chạy**:

- **SPEC TEST** dẫn dắt hành vi mới — **phải fail trước**. Pass ngay là test hỏng.
- **CHARACTERIZATION TEST** ghim hành vi đã có — **phải pass trước**. Pass ngay là **điều
  kiện thành công**, không phải red flag. Iron Law chi phối việc sinh production code;
  viết characterization test không sinh production code nên không kích hoạt nó. Kiểm
  chứng bằng cách cố tình làm hỏng production code, xem test fail, rồi hoàn tác.

Không được đổi một spec test thành characterization test **sau khi** thấy nó pass.
Characterization test nằm ở thư mục riêng để việc khai báo kiểm tra được trong diff.
