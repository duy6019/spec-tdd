<!-- Dán khối này vào CLAUDE.md ở gốc project đích.                            -->
<!-- Đặt NGOÀI cặp <!-- OPENSPEC:START --> … <!-- OPENSPEC:END -->,            -->
<!-- nếu không `openspec update` sẽ ghi đè.                                    -->

## Định tuyến công việc (đọc mỗi phiên)

Repo này dùng schema OpenSpec `sdd-tdd` (hai tầng) ghép với superpowers.

### Việc đầu tiên, trước khi gọi bất kỳ skill nào

Với mọi yêu cầu thêm tính năng hoặc sửa lỗi, hành động đầu tiên là chạy `openspec list`
rồi phân tầng. **Không brainstorm trước bước này.**

- **NHẸ — mặc định.** Thay đổi nằm trong một module, không thêm dependency, không có
  migration dữ liệu, không đụng contract bên ngoài.
- **NẶNG** — chỉ khi có ít nhất một trong: vượt ranh giới module, có migration dữ liệu,
  đụng contract/API bên ngoài, hoặc tôi gõ đúng chữ **LARGE CHANGE**.

Bạn được phép **đề xuất** nâng lên NẶNG. Bạn không được tự quyết, và không được đổi tầng
giữa chừng.

### Tầng NHẸ

Đây là chỉ thị thường trực của tôi, dùng đúng quyền ưu tiên mà `superpowers:using-superpowers`
đã cấp cho user instructions. **Tôi đang nói rõ với bạn rằng hãy bỏ qua các bước dưới đây:**

- **Bỏ `superpowers:writing-plans`.** Tầng nhẹ không có plan file.
- Nếu `superpowers:brainstorming` được gọi, **trạng thái kết thúc của nó trong repo này
  KHÔNG phải `writing-plans`**. Kết quả brainstorm ghi vào `openspec/changes/<name>/proposal.md`
  và `openspec/changes/<name>/specs/`, rồi dừng.
- **Không ghi vào `docs/superpowers/specs/` hay `docs/superpowers/plans/`.** Hai thư mục đó
  không được dùng trong repo này.

Đường đi: `/opsx:propose` → `/opsx:apply` → `openspec archive <name>`.

### Tầng NẶNG

Thêm `design.md`, `tasks.md`, và `<change-name>-plan.md` do `superpowers:writing-plans` viết
(ghi thẳng vào thư mục change, **không** vào `docs/superpowers/plans/`).

Tên file plan phải là `<change-name>-plan.md`, không bao giờ là `plan.md` — `sdd-workspace`
lấy slug từ tên file, đặt trùng tên thì mọi change dùng chung một workspace.

### Chỉ thị thường trực khác

- **Worktree: không dùng, và đừng hỏi.** Làm thẳng trên nhánh hiện tại. (`using-git-worktrees`
  tôn trọng ý muốn đã khai báo sẵn mà không hỏi lại.)
- **Đóng change bằng CLI:** `openspec archive <name>`. Không dùng `/opsx:sync` — đó là đường
  merge do agent tự làm, không có chốt chặn mất scenario.
- **Archive TRƯỚC khi** gọi `superpowers:finishing-a-development-branch`.
- **ADDED nghĩa là "chưa có trong spec", không phải "chưa có trong code."** Hành vi đã chạy
  nhiều năm nhưng chưa ghi vào `openspec/specs/` vẫn viết là ADDED. Dùng MODIFIED cho thứ
  chưa có trong spec chính sẽ khiến `openspec archive` báo lỗi cứng — và chỉ báo lúc archive,
  tức là sau khi đã code xong.
