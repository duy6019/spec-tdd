# spec-tdd

Schema OpenSpec hai tầng, ghép spec-driven development với kỷ luật TDD của superpowers.

Fork từ schema `spec-driven` gốc, không phải bridge cộng đồng. Lý do chọn cách này — và
đánh giá ba bridge cộng đồng — nằm ở
[docs/2026-07-26-tich-hop-sdd-tdd.md](docs/2026-07-26-tich-hop-sdd-tdd.md).

## Ý tưởng một dòng

Số nghi thức do `apply.requires` quyết định, không phải do số artifact. Đặt cổng ở `[specs]`
thì `/opsx:propose` dừng lại sau hai file, và một thay đổi nhỏ chỉ tốn ba lệnh.

| | Lệnh gõ | File viết |
|---|---|---|
| Tầng nhẹ | 3 | 2 |
| Tầng nặng | 4–6 | 5 |

## Về cái tên

Schema tên `spec-tdd`, repo tên `sdd-tdd`. Cố ý khác nhau.

Repo là nơi nghiên cứu việc ghép SDD với TDD nói chung. Schema thì cần một cái tên không va
chạm: superpowers đã dùng `.superpowers/sdd/` cho **s**ubagent-**d**riven-**d**evelopment,
nên một schema tên `sdd-*` nằm cạnh nó trong cùng repo sẽ khiến `sdd` mang hai nghĩa.

## Điều kiện tiên quyết

**1. Git repo có ít nhất một commit.** Các script của `subagent-driven-development` gọi
`git rev-parse --show-toplevel` dưới `set -euo pipefail`; không có git là hỏng ngay lệnh đầu.

**2. Plugin `superpowers` (≥ 6.2.0) phải cài sẵn.** Schema này gọi
`superpowers:test-driven-development`, `superpowers:writing-plans` và
`superpowers:subagent-driven-development` **bằng tên**; thiếu chúng thì `apply.instruction`
dừng theo đúng thiết kế và bạn không implement được gì. Kiểm tra bằng `ls .claude/skills/`
— phải thấy skill của superpowers, không chỉ 6 skill `openspec-*`.

**3. OpenSpec CLI.** Mọi lệnh `openspec ...` bên dưới giả định CLI có trên PATH. Cài một lần
bằng `npm i -g @fission-ai/openspec@1.6.0`, hoặc thay mọi `openspec` bằng
`npx -y @fission-ai/openspec@latest`.

## Cài đặt

### Bước 1 — khởi tạo OpenSpec (bỏ qua nếu project đã có `openspec/`)

```bash
openspec init --tools claude
```

Tạo `openspec/config.yaml`, `.claude/commands/opsx/` (6 lệnh) và `.claude/skills/openspec-*/`
(6 skill). **Nó không tạo `CLAUDE.md`.**

Nếu project đã chạy `init` trước đó, chỉ cần xác nhận `.claude/commands/opsx/` có đủ 6 lệnh:
`propose, explore, apply, update, sync, archive`.

### Bước 2 — chép schema

```bash
mkdir -p <project>/openspec/schemas
cp -r schemas/spec-tdd <project>/openspec/schemas/
```

> Phải `mkdir -p` trước. Nếu `openspec/schemas/` chưa tồn tại, `cp -r` sẽ **đổi tên** thư mục
> nguồn thành `schemas/` thay vì lồng vào — im lặng, exit 0, và schema nằm sai chỗ.

### Bước 3 — trỏ project vào schema

Đổi dòng đầu `openspec/config.yaml` thành:

```yaml
schema: spec-tdd
```

### Bước 4 — mô tả project

Thêm mục `context:` vào `openspec/config.yaml`: tech stack, **lệnh chạy test cụ thể**, và các
nguyên tắc bất di bất dịch nếu có. Phần này được inject vào mọi lần sinh artifact, nên nó là
chỗ đặt thứ riêng của project — **schema giữ nguyên dạng chung, không sửa**.

### Bước 5 — CLAUDE.md

OpenSpec 1.6.0 với `--tools claude` **không** tạo `CLAUDE.md` và **không** chèn cặp marker
`<!-- OPENSPEC:START -->` … `<!-- OPENSPEC:END -->` ở đâu cả.

- **Chưa có `CLAUDE.md`:** tạo mới ở gốc project, dán nội dung
  [CLAUDE.md.fragment.md](CLAUDE.md.fragment.md) vào (bỏ mấy dòng comment hướng dẫn ở đầu).
- **Đã có `CLAUDE.md` chứa cặp marker OPENSPEC** (do bản OpenSpec cũ sinh ra): dán **ngoài**
  cặp marker — bên trong sẽ bị `openspec update` ghi đè.

Sửa ngưỡng nâng tầng trong fragment cho khớp domain của project.

### Bước 6 — kiểm tra

```bash
openspec schema validate spec-tdd     # cấu trúc schema
openspec schemas                       # spec-tdd phải hiện, kèm 5 artifact
head -1 openspec/config.yaml           # phải là: schema: spec-tdd
```

> `schema validate` **không** kiểm `config.yaml` đã trỏ đúng chưa — nó pass kể cả khi project
> vẫn đang dùng `spec-driven`. Ba lệnh trên mới đủ.

**Gỡ ra:** xoá `openspec/schemas/spec-tdd/`, trả `config.yaml` về `schema: spec-driven`, xoá
đoạn fragment trong `CLAUDE.md`.

## Lệnh dùng hằng ngày

Tất cả đều nằm trong profile mặc định. Không cần bật gì thêm.

### Tầng nhẹ — mặc định

```bash
/opsx:propose "mô tả thay đổi"
```
Sinh `proposal.md` + `specs/<capability>/spec.md` rồi **dừng**. Nó dừng vì cổng
`apply.requires: [specs]` đã thoả — không phải vì ai nhắc nó dừng.

```bash
/opsx:apply
```
Đọc `apply.instruction`, phân tầng, gọi `superpowers:test-driven-development`, làm ngay
trong phiên hiện tại. Không worktree, không plan file, không subagent.

```bash
openspec archive <change-name> --yes
```
Gộp delta vào `openspec/specs/`, chuyển change vào `archive/`. Dùng **CLI**, không dùng
`/opsx:sync`.

> `--yes` là bắt buộc khi chạy không tương tác. Thiếu nó, lệnh mở prompt xác nhận; trong
> môi trường không có TTY nó chết với `User force closed the prompt` và exit 1.

### Tầng nặng

Ba lệnh trên, chèn thêm bước sinh artifact nặng sau `propose`:

```bash
openspec instructions design --change <name>
openspec instructions tasks  --change <name>
openspec instructions plan   --change <name>
```

Mỗi lệnh in ra instruction + đường dẫn output cho Claude thực hiện. Trong thực tế thường chỉ
cần bảo Claude "làm design, tasks và plan cho change này" — nó đọc schema và tự chạy.

`design` và `tasks` là tuỳ chọn độc lập; `plan` cần `tasks` tồn tại trước.

### Tạo change ngoài phiên Claude

```bash
openspec new change <kebab-name>
```
Tạo `openspec/changes/<name>/.openspec.yaml` (ghi lại schema đang dùng). Các artifact bạn tự
viết vào đó: `proposal.md`, `specs/<capability>/spec.md`, và ở tầng nặng thêm `design.md`,
`tasks.md`, `<name>-plan.md`.

### Lệnh xem

```bash
openspec list                          # change đang mở, kèm tiến độ task
openspec status --change <name>        # artifact nào xong, cái nào bị chặn
openspec validate <name>               # kiểm cấu trúc delta spec
openspec show <name>                   # xem nội dung
```

### Đừng dùng

| Lệnh | Vì sao |
|---|---|
| `/opsx:sync` | Merge do agent tự làm, không có chốt chặn mất scenario. `openspec archive` là parser tất định, có chốt. |
| Tự tạo `tasks.md` ở tầng nhẹ | Có `tasks.md` là tự nhảy sang tầng nặng. Đừng tạo file đó để "cho đủ". |

## Đồ thị artifact

```
proposal ──> specs ──┬──> design
                     │
                     └──> tasks ──> plan
              ▲
        apply gate ở đây:  apply.requires: [specs], tracks: null
```

- **Tầng nhẹ** dừng ở `specs`.
- **Tầng nặng** đi tiếp. `plan` sinh `<change-name>-plan.md` do `superpowers:writing-plans` viết.

Phân tầng tự hiện trong tooling: change không có `tasks.md` thì `openspec list` báo
`No tasks` và archive sạch; change có `tasks.md` thì báo `0/3 tasks` và archive cảnh báo khi
còn task dở. Không phải cấu hình gì thêm — `findTrackedTasksArtifact` tự quay về tìm artifact
`tasks` khi `tracks` không đặt.

## Repo này chỉ có bốn thứ

`schemas/`, `CLAUDE.md.fragment.md`, `README.md`, `docs/`.

Cố ý không có: CI, drift detector, script cài đặt, version manifest, lệnh bọc, hook, MCP.
Mỗi thứ thêm vào là một thứ phải bảo trì khi hai thượng nguồn đổi — mà superpowers ra 19 bản
trong 6 tháng, trong đó 2 bản major breaking.

## Kiểm lại sau mỗi lần nâng cấp

1. `ls .claude/skills/ .claude/commands/opsx/` — profile OpenSpec nằm ở config **toàn cục**,
   có thể trôi và cài lại lệnh bạn đã bỏ.
2. Mở một `<change>-plan.md` bất kỳ: heading còn là `## Task N:` chứ? Checkbox còn ở cột 0
   chứ? (`task-brief` khớp `^#+[ \t]+Task[ \t]+[0-9]+`; checkbox thụt lề vô hình với OpenSpec.)
3. `subagent-driven-development` đã kích hoạt `test-driven-development` chưa? Tính đến
   superpowers 6.2.0 là **chưa** — nên `apply.instruction` phải gọi tường minh. Nếu thượng
   nguồn sửa, có thể bỏ dòng đó.

Nguyên tắc chống trôi: **chỉ nhắc tên skill, không bao giờ nhắc đường dẫn file, tên script,
hay trích nguyên văn text của skill.** Cả ba bridge cộng đồng sống sót qua hai bản major
breaking chính nhờ điều này.

## Đã kiểm chứng với

OpenSpec CLI `1.6.0` · superpowers `6.2.0` · Node 20+ · Windows 11 / Git Bash · 2026-07-27

Ba lần chạy độc lập: một repo nháp, một project thật, và một lần cài từ đầu bởi agent chỉ đọc
README này. Kết quả khớp cả ba: cổng mở với 2/5 artifact; `apply.instruction` được inject
**khớp từng byte** với `schema.yaml`; `openspec list` báo `No tasks` và exit 0; `archive` gộp
delta vào `openspec/specs/`; change đã archive chứa đúng 2 artifact.

Hai điều đã biết ở 1.6.0:

- Capability mới bị archive chèn `## Purpose TBD - created by archiving change <name>` —
  phải sửa tay.
- `openspec archive --json` không kèm `--yes` trả lỗi `archive_confirmation_required` và
  **exit 1**. Kiểm exit code bình thường được; chỉ cần nhớ luôn truyền `--yes` khi chạy
  không tương tác.
