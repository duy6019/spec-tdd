# sdd-tdd

Schema OpenSpec hai tầng, ghép spec-driven development với kỷ luật TDD của superpowers.

Fork từ schema `spec-driven` gốc. Không phải bridge cộng đồng — lý do chọn cách này nằm ở
[docs/2026-07-26-tich-hop-sdd-tdd.md](docs/2026-07-26-tich-hop-sdd-tdd.md).

## Ý tưởng một dòng

Số nghi thức do `apply.requires` quyết định, không phải do số artifact. Đặt cổng ở `[specs]`
thì `/opsx:propose` dừng lại sau hai file, và một thay đổi nhỏ chỉ tốn ba lệnh.

| | Lệnh gõ | File viết |
|---|---|---|
| Tầng nhẹ | 3 | 2 |
| Tầng nặng | 5 | 5 |

## Cài vào một project

```bash
git init && git add -A && git commit -m "baseline"          # nếu chưa phải git repo
npx @fission-ai/openspec@latest init --tools claude          # chạy TRƯỚC khi có CLAUDE.md
cp -r schemas/sdd-tdd <project>/openspec/schemas/
```

Rồi đổi dòng đầu `openspec/config.yaml` thành `schema: sdd-tdd`, và dán
[CLAUDE.md.fragment.md](CLAUDE.md.fragment.md) vào `CLAUDE.md` ở gốc project — **ngoài** cặp
marker `<!-- OPENSPEC:START -->` … `<!-- OPENSPEC:END -->`.

Kiểm tra: `openspec schema validate sdd-tdd`

> **Thứ tự quan trọng.** Nếu `CLAUDE.md` đã tồn tại lúc chạy `openspec init`, init sẽ coi nó
> là file cấu hình cũ, hỏi "Legacy files detected. Upgrade and clean up? [Y/n]" và **abort nếu
> trả lời N**. Chạy init trên cây sạch trước, viết CLAUDE.md sau.

Gỡ ra: xoá `openspec/schemas/sdd-tdd/` và đoạn fragment trong CLAUDE.md.

## Đồ thị artifact

```
proposal ──> specs ──┬──> design
                     └──> tasks ──> plan
                     ↑
              apply gate ở đây
```

`apply: requires: [specs]`, `tracks: null`

- **Tầng nhẹ** dừng ở `specs`. Không design, không tasks, không plan.
- **Tầng nặng** đi tiếp. `plan` sinh ra `<change-name>-plan.md` do `superpowers:writing-plans` viết.

Phân tầng tự hiện trong tooling: change không có `tasks.md` thì `openspec list` báo `No tasks`
và archive sạch; change có `tasks.md` thì báo `0/3 tasks` và archive bật cảnh báo khi còn task dở.

## Không có gì trong repo này ngoài bốn thứ

`schemas/`, `CLAUDE.md.fragment.md`, `README.md`, `docs/`.

Cố ý không có: CI, drift detector, script cài đặt, version manifest, lệnh bọc, hook, MCP.
Mỗi thứ thêm vào là một thứ phải bảo trì khi hai thượng nguồn đổi — mà superpowers ra 19 bản
trong 6 tháng.

## Kiểm lại sau mỗi lần nâng cấp

Ba dòng, chạy tay:

1. `ls .claude/skills/ .claude/commands/opsx/` — profile nằm ở config **toàn cục**, có thể trôi
   và cài lại lệnh bạn đã bỏ.
2. Mở `<change>-plan.md` bất kỳ: heading còn là `## Task N:` chứ? Checkbox còn ở cột 0 chứ?
   (`task-brief` khớp `^#+[ \t]+Task[ \t]+[0-9]+`; checkbox thụt lề vô hình với OpenSpec.)
3. `superpowers:subagent-driven-development` đã kích hoạt `test-driven-development` chưa?
   Tính đến 6.2.0 là **chưa** — nên `apply.instruction` phải gọi tường minh. Nếu thượng nguồn
   sửa, có thể bỏ dòng đó.

Nguyên tắc chống trôi: **chỉ nhắc tên skill, không bao giờ nhắc đường dẫn file, tên script, hay
trích nguyên văn text của skill.** Cả ba bridge cộng đồng sống sót qua hai bản major breaking
chính nhờ điều này.

## Đã kiểm chứng với

OpenSpec CLI `1.6.0` · superpowers `6.2.0` · Node 20+ · 2026-07-26

Chạy thật một vòng đầy đủ trên repo nháp: cổng mở với 2/5 artifact, `apply.instruction` được
inject nguyên văn, `archive` gộp delta vào `openspec/specs/`.

Hai điều đã biết ở 1.6.0: capability mới bị archive chèn `## Purpose TBD - created by
archiving change <name>` (phải sửa tay); và `openspec archive --json` không kèm `--yes` trả
lỗi nhưng vẫn **exit 0**, nên đừng viết script dựa vào exit code.
