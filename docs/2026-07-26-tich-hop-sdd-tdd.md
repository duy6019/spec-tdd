# Tích hợp SDD (OpenSpec) với TDD (superpowers)

**Ngày:** 2026-07-26
**Trạng thái:** Nghiên cứu + quyết định kiến trúc. Bộ cài đã dựng và chạy thử xong trên repo
nháp (xem [../README.md](../README.md)); chưa cài vào codebase thật.
**Bối cảnh:** codebase có sẵn, chưa có spec, làm một mình. Đã cài superpowers 6.2.0. Chưa cài OpenSpec.

---

## 1. Quyết định

Ghép được. Cách ghép: **fork schema `spec-driven` gốc của OpenSpec, ghép vào hai thứ mượn từ cộng đồng.**

Không dùng nguyên bản bridge cộng đồng nào, cũng không fork bridge nào — dù đã có ba bản tồn tại.

Lý do nằm ở một sự thật về cách OpenSpec hoạt động mà cả ba bridge đều bỏ lỡ:

> **Số lượng nghi thức do `apply.requires` quyết định, không phải do số artifact.**

`/opsx:propose` — lệnh có sẵn trong profile mặc định — tự chạy vòng lặp tạo artifact **cho tới khi
thoả cổng `apply.requires` rồi dừng**. Nguyên văn trong `dist/core/templates/workflows/propose.js`:

> *"Continue until all `applyRequires` artifacts are complete … Stop when all `applyRequires`
> artifacts are done"*

Nghĩa là đặt cổng ở `[specs]` thì **một lệnh duy nhất** sinh ra toàn bộ tầng nhẹ. Cả ba bridge phải gõ
`/opsx:continue` từ 4 đến 7 lần mỗi change chỉ vì chúng đặt cổng ở cuối một chuỗi dài.

Kết quả so sánh cho một thay đổi nhỏ:

| | Lệnh phải gõ | File phải viết | Cổng duyệt |
|---|---|---|---|
| **Thiết kế đề xuất** | **3** | **2** | **~2** |
| veath | 8–10 | 6 | 13-bullet preflight |
| danielhanold | 10–11 | 8–9 | ~8 + 4 commit bắt buộc |
| jiangway | 11 | 8 | ~15 |

Ba lệnh đó là: `/opsx:propose` → `/opsx:apply` → `openspec archive`. Tất cả đều nằm trong profile mặc
định, không cần bật gì thêm.

> **Đính chính so với bản trước của tài liệu này.** Tôi từng khuyến nghị "fork `superpowers-bridge`
> rồi cắt bớt" (phương án B). Sai. Cắt bridge đó xuống tầng nhẹ nghĩa là xoá 3 trong 8 artifact, nối
> lại 4 cạnh phụ thuộc, thay toàn bộ khối `apply` 108 dòng, dịch 6 template từ tiếng Trung, và viết
> lại đoạn CLAUDE.md 47 dòng để nó nói **ngược lại** điều đang nói. Phần còn sót lại thực sự của
> bridge chỉ khoảng hai đoạn văn — mà hai đoạn đó lại là bản sao nguyên văn từ schema `spec-driven`
> gốc.

---

## 2. Vấn đề

Hai bộ công cụ, mỗi bộ giỏi một nửa, và **cả hai đều đi đủ bốn bước giống nhau**:

> hiểu yêu cầu → viết kế hoạch → chia task → viết code

| | superpowers 6.2.0 | OpenSpec 1.6.0 |
|---|---|---|
| Kỷ luật test | **Có, rất sâu** — Iron Law, bắt buộc xem test fail | Không có gì |
| Spec tích luỹ qua thời gian | **Không có** | **Có** — archive gộp delta vào spec chính |
| Chia task | `writing-plans`, kèm code test thật | `tasks.md`, checklist |
| Thi công | `subagent-driven-development` | `/opsx:apply` |

Phần giữa là phần lặp. Chạy đủ cả hai = viết kế hoạch hai lần, giữ hai cây tài liệu đồng bộ. Đó là
chỗ sinh over-engineering, không phải bản thân việc ghép.

**Nguyên tắc giải:** không hợp nhất, mà giao quyền sở hữu. Và ở đâu xoá được thì xoá, đừng viết luật.

---

## 3. Vì sao OpenSpec chứ không Spec Kit

| | Spec Kit | OpenSpec |
|---|---|---|
| Spec tích luỹ thành tài liệu sống | **Không** — mỗi feature một thư mục `001/`, `002/` | **Có** |
| Lệnh hợp nhất spec | Không có | `openspec archive` |
| Bề mặt máy móc | `.specify/`, workflow engine, `runs/<id>/state.json`, 7 lệnh | Markdown + một CLI |
| Hợp brownfield | Đánh số feature — hợp greenfield | Mô hình delta — sinh ra cho việc sửa dần |

[Discussion #152](https://github.com/github/spec-kit/discussions/152) ghi nhận đúng lỗ hổng này và
chưa vá: *"để biết hệ thống làm gì tôi phải đọc cả hai spec"*.

**Đính chính:** tôi từng nói Spec Kit ép TDD qua "Article III NON-NEGOTIABLE". Không còn đúng —
`templates/constitution-template.md` giờ là template rỗng, TDD chỉ nằm trong một HTML comment làm ví
dụ. Nguồn tôi trích (`spec-driven.md`) là bài luận cũ còn sót trong repo. Lập luận "hai thẩm quyền TDD
xung đột" **bỏ**; kết luận giữ, dựa trên ba dòng bảng trên.

Cũng đính chính: OpenSpec hỗ trợ 30+ công cụ, **không** hẹp hơn Spec Kit.

---

## 4. Ba bridge cộng đồng — và vì sao cả ba đều trượt

Đã có ba bản tích hợp OpenSpec + superpowers. Tôi đã clone và đọc cả ba.

| | jiangway/superpowers-bridge | veath | danielhanold/superspec |
|---|---|---|---|
| Artifact | 8 | 6 | 9 |
| Xuất xứ | **Có trong docs chính thức OpenSpec**, từ PR #970 | 1 commit, 2026-03-27 | 1 commit, 2026-05-26 |
| Pin phiên bản | OpenSpec 1.4.1 / superpowers **5.1.0** | Không khai | Không khai |
| Phân tầng | **Không** | **Không** | **Không** |
| Git bắt buộc | worktree + branch + PR | **Không có gì** | branch + 4 commit + PR |
| CLAUDE.md kèm theo | Có (Anh + Trung) | Không | Không |

### Điểm chung chí tử: không bản nào có phân tầng

Và lý do nằm ở tầng dưới cả ba: **schema của OpenSpec 1.6.0 về mặt vật lý không diễn đạt được artifact
có điều kiện.** Kiểm chứng trong `dist/core/artifact-graph/types.js`:

```js
ArtifactSchema = z.object({ id, generates, description, template, instruction, requires })
```

Không có khoá `optional`, `condition`, `when`, `mode`, hay `profile`. Phân tầng trong OpenSpec **chỉ**
diễn đạt được bằng hai thứ: **artifact nào nằm phía trên `apply.requires`**, và **`apply.tracks`**.

Cả ba bridge đều đặt artifact nặng phía trên cổng. Nên "thêm phân tầng cho bridge X" không phải là vá
— mà là viết lại đúng phần duy nhất mà bridge đó chứa.

### Cách "giảm nghi thức" của cả ba đều phá yêu cầu của bạn

Cách duy nhất chúng cho phép đi nhẹ là **thoát khỏi schema**. Đoạn CLAUDE.md mà jiangway cài vào
project ghi thẳng:

> `| Bug fix (no contract change) / test backfill / linter tweak / non-breaking upgrade / typo / docs / config value tweak | ✅ Direct PR |`

Tức là toàn bộ nhóm thay đổi bạn làm nhiều nhất sẽ **không sinh delta spec nào**. Đó chính là mô hình
bạn đã loại từ đầu, vì nó làm spec chính lệch dần khỏi code. Cài nguyên bản đoạn này là dặn Claude làm
ngược lại điều bạn muốn.

### Đánh giá riêng từng bản

**jiangway** — tốt nhất về kỹ thuật. Là bản duy nhất có PRECHECK dừng-cứng khi thiếu skill
(*"Do NOT silently fall back"*), khớp chính xác cả hai parser, chỉ tham chiếu superpowers qua **tên
skill** nên sống sót qua hai major breaking. Nhưng nặng nhất, một nửa template là tiếng Trung, và pin
sau bạn nguyên một major.

**veath** — rẻ nhất về nghi thức và là bản duy nhất **không bắt buộc git** (không worktree, không
branch, không commit, không PR) — hợp người làm một mình nhất. Nhưng nó mua sự nhẹ đó bằng cách rút
ruột TDD: TDD là một ô text tự do trong `review.md` ship ra ở trạng thái **chưa đặt**
(`<!-- standard | tdd-preferred | tdd-required -->`), `standard` là giá trị hợp lệ, và động từ là
*"prefer"*. Grep toàn bộ 25 file: **không có** "iron law", "RED/GREEN/REFACTOR", "watch it fail". Nó
còn tham chiếu hai skill **chưa từng tồn tại** (`pre-implementation review`, `verification`).

**danielhanold** — cơ chế schema chặt chẽ nhất, tài liệu tốt nhất. Nhưng `brainstorm` là **gốc** của
đồ thị, nên sửa một cái typo cũng phải bắt đầu bằng một cuộc phỏng vấn nhiều lượt. Và bước `finalize`
là **~370 dòng bash nhúng trong YAML**, dùng `realpath --relative-to`, heredoc, `/tmp` — trên Windows
11 thì hỏng.

---

## 5. Thiết kế đề xuất

### 5.1 Fork và nối lại đồ thị

```bash
openspec schema fork spec-driven sdd-tdd
```

Rồi sửa `openspec/schemas/sdd-tdd/schema.yaml`:

| Sửa gì | Thành | Vì sao |
|---|---|---|
| `design.requires` | `[specs]` | Đẩy **xuống dưới** cổng |
| `tasks.requires` | `[specs]` | Bỏ phụ thuộc `design` (bản gốc là `[specs, design]`, khiến design thành bắt buộc dù instruction của nó nói "chỉ tạo khi cần") |
| thêm artifact `plan` | `requires: [tasks]`, `generates: "*-plan.md"` | Nơi `writing-plans` ghi ra |
| `apply.requires` | `[specs]` | **Đây là công tắc phân tầng** |
| `apply.tracks` | `null` | Cho phép chạy khi không có `tasks.md` |

**Điểm tinh tế dễ sai:** phải để `design` phụ thuộc `specs`, không phải `proposal`. Nếu để phụ thuộc
`proposal`, nó trở thành `ready` cùng lúc với `specs`, sắp trước theo thứ tự chữ cái, và agent sẽ viết
nó ra.

**Một món quà miễn phí:** `task-progress.js` có hàm `findTrackedTasksArtifact` — khi `tracks` không
đặt, nó quay về tìm artifact có `id === 'tasks'`. Nên change lớn (có `tasks.md`) vẫn được `openspec
list` báo "3/7 tasks", còn change nhỏ (không có) báo "No tasks" và archive sạch. **Phân tầng hiện ra
trong tooling mà không phải làm gì thêm.**

### 5.2 Viết khối `apply.instruction` — chỗ mua được TDD

Đã kiểm chứng: với `tracks: null`, `instructions.js:286-289` trả `state: "ready"` và **inject nguyên
văn** `apply.instruction` vào `openspec instructions apply --json`. Đây là điểm chèn chính thức, không
phải hack.

Viết một bộ định tuyến hai nhánh, khoảng 25 dòng:

- **Nhánh nhẹ** — làm ngay trong session hiện tại, và **gọi tường minh**
  `superpowers:test-driven-development`, kèm trích Iron Law ngay trong đó.
- **Nhánh nặng** — worktree + `superpowers:subagent-driven-development`, **cộng thêm một dòng mà cả ba
  bridge đều thiếu**: gọi `test-driven-development` cho từng task (lý do ở mục 7.1).

Để worktree và PR là **tuỳ chọn**, không bắt buộc. Bạn làm một mình; câu *"PR is the LAST step … do
NOT reorder"* của jiangway là hình dạng của một đội.

### 5.3 Hai thứ mượn từ jiangway

1. **Đoạn chuyển hướng output**, chép nguyên văn. Trong 6.2.0, `brainstorming` vẫn ghi ra
   `docs/superpowers/specs/…` và `writing-plans` vẫn ghi ra `docs/superpowers/plans/…`. Cần câu
   *"Do NOT write to `docs/superpowers/plans/`. Instead, write the plan directly to this change's …"*
2. **Mẫu PRECHECK** — xác nhận skill có mặt trước khi gọi, kèm *"If missing, STOP … Do NOT silently
   fall back."*

### 5.4 Đoạn CLAUDE.md, khoảng 15 dòng

Đảo ngược bảng của jiangway:

- **Mọi thay đổi có ảnh hưởng hành vi — kể cả sửa bug — đi tầng nhẹ**: proposal + delta spec + TDD + archive
- **Leo lên tầng nặng** chỉ khi có dấu hiệu rõ: vượt ranh giới module, có migration dữ liệu, đụng
  contract bên ngoài, hoặc bạn không tóm tắt được thay đổi trong một câu

Đặt **ngoài** cặp marker `<!-- OPENSPEC:START -->` … `<!-- OPENSPEC:END -->` để `openspec update`
không ghi đè.

**Căn cứ pháp lý cho việc ghi đè skill:** superpowers tự cấp quyền, ở dòng cuối phần inject vào mọi
session — *"User instructions (CLAUDE.md …) take precedence over skills"* — nhưng kèm điều kiện
*"Only skip skill workflows … when your human partner has explicitly told you to."*

→ Luật phải viết ở **thể mệnh lệnh, ngôi thứ nhất, gọi đích danh skill bị bỏ**. Viết mô tả suông
("thay đổi nhỏ thì không cần plan") **không thoả điều kiện** và sẽ thua trước HARD-GATE của
`brainstorming`.

---

## 6. Những cái bẫy đã kiểm chứng

### 6.1 Đừng bao giờ đặt tên file kế hoạch là `tasks.md`

`dist/utils/task-progress.js:50-51` — `countSingleTopLevelTasksFile` đọc `<changeDir>/tasks.md` **theo
đường dẫn cứng**, bất kể schema khai gì. Đổi `id` của artifact không đủ, phải đổi **tên file**.

Đặt `<change-name>-plan.md` giải quyết ba việc cùng lúc: OpenSpec không đếm nó nữa; hết cổng ảo
`archive_tasks_incomplete`; và mỗi change có workspace riêng cho superpowers (xem 6.3).

### 6.2 Đừng bao giờ xoá cả khối `apply:`

`instruction-loader.js:174`:

```js
const applyRequires = schema.apply?.requires ?? schema.artifacts.map(a => a.id);
```

Không có khối `apply` → **mọi** artifact thành bắt buộc. Phải đặt `apply: requires: [specs], tracks: null`.

### 6.3 `apply.requires` không được validate

`validateRequiresReferences` chỉ duyệt `schema.artifacts`. Gõ sai tên trong `apply.requires` thì
`openspec schema validate` vẫn báo hợp lệ, nhưng **cổng bạn tưởng đã đặt thì không tồn tại**. Phải
test bằng một change thật, không phải bằng `validate`.

### 6.4 Ba parser tranh nhau

| Parser | Ngữ pháp | Thấy gì |
|---|---|---|
| OpenSpec `instructions.ts` | `/^[-*]\s*\[([ xX])\]\s*(.+)\s*$/` | chỉ checkbox, phẳng |
| OpenSpec `task-progress.ts` | `/^[-*]\s+\[[\sx]\]/i` | chỉ checkbox, **luật khoảng trắng khác** |
| superpowers `task-brief` (awk) | `^#+[ \t]+Task[ \t]+[0-9]+` | chỉ heading, có phân cấp |

**Checkbox thụt lề là vô hình** với OpenSpec — cả hai regex neo `^` thẳng vào `[-*]`.

**Heading trong plan phải là `## Task N: <tên>`** để khớp awk. veath bỏ qua điều này và toàn bộ bộ máy
uỷ quyền của nó không dùng được.

### 6.5 Va chạm thư mục làm việc

`sdd-workspace` lấy slug bằng `basename "$plan" .md`. Cả jiangway lẫn danielhanold đều đặt tên plan là
`plan.md`, nên **mọi change đổ vào cùng `.superpowers/sdd/plan/`** — đúng thứ mà bản vá 6.2.0 sinh ra
để chặn. Chỉ được cứu nhờ worktree bắt buộc; bỏ worktree là hỏng.

### 6.6 Hoàn thành artifact = file tồn tại

`state.js` → `artifactOutputExists`. File rỗng vẫn tính `done` và mở khoá mọi bước sau. Đừng dựng cổng
mà bạn tưởng nó sẽ giữ.

### 6.7 Không có gì thật sự chặn

- `openspec validate` **bỏ qua hoàn toàn** `tasks.md` (exit 0 dù không có file)
- Archive chế độ JSON không kèm `--yes` trả lỗi `archive_tasks_incomplete` **nhưng vẫn exit 0**
- Skill archive ghi rõ: *"Don't block archive on warnings - just inform and confirm."*
- `/opsx:verify` chỉ báo cáo *"without blocking anything"*, phần "correctness" của nó là **tìm từ khoá**

### 6.8 `archive` và `sync` không tương đương

| | `openspec archive` (CLI) | `/opsx:sync` (skill) |
|---|---|---|
| Cơ chế | Parser tất định | **Agent tự merge** |
| Chặn mất scenario | **Có** | Không |

**Không có lệnh CLI `openspec sync`.** Chọn `openspec archive` làm đường chính thức.

### 6.9 Không ai đối chiếu spec với code

CLI của OpenSpec **không bao giờ đọc source**. Bộ review của superpowers chỉ nhìn plan, không nhìn
spec — `specs/*/spec.md` không được đưa cho reviewer nào, kể cả vòng cuối.

→ Delta spec có thể merge vào spec chính rồi thành **sự thật sai lâu dài**. Phải thêm bước đối chiếu:
đưa đường dẫn delta spec vào lượt review cuối, và nếu code lệch spec thì **sửa spec trước khi archive**.

---

## 7. Ba phát hiện về superpowers 6.2.0

Ba điều này đúng **bất kể** bạn có dùng OpenSpec hay không.

### 7.1 TDD không còn lan truyền qua `subagent-driven-development`

Grep toàn bộ tham chiếu `superpowers:*` trong `skills/subagent-driven-development/`:

```
SKILL.md:113  superpowers:using-git-worktrees
SKILL.md:399  superpowers:requesting-code-review
SKILL.md:77,106,423,502  superpowers:finishing-a-development-branch
```

`test-driven-development` **không xuất hiện ở đâu cả**. Cái implementer subagent thực sự nhận được
(`implementer-prompt.md:36`) là:

> *"2. Write tests (following TDD if task says to)"*

Cả jiangway lẫn danielhanold đều khẳng định nguyên văn rằng `subagent-driven-development` "internally
enforces … test-driven-development … Implementation code written before a failing test is deleted".
**Sai với 6.2.0.**

**Cái còn sống sót:** RED/GREEN vẫn xảy ra, vì `writing-plans` hardcode sẵn *"Step 1: Write the failing
test / Step 2: Run test to verify it fails … Expected: FAIL"* vào plan. Nên "if task says to" giải ra
thành có.

**Cái chết:** Iron Law như một luật được cưỡng chế. Không có gì trên đường thi công xoá code viết
trước test. **TDD trở thành thuộc tính của văn bản plan, không phải bất biến được đảm bảo.**

→ Cách vá: một dòng trong `apply.instruction` gọi tường minh `superpowers:test-driven-development`, và
nói rõ trong mỗi lượt dispatch rằng task này là TDD-required.

### 7.2 Worktree đổi chỗ

6.2.0 ưu tiên công cụ native của harness và nêu đích danh `EnterWorktree`. Claude Code của bạn **có**
công cụ đó, và hợp đồng của nó khác: worktree nằm ở `.claude/worktrees/` (không phải `.worktrees/`),
tool tự đặt tên branch, và `worktree.baseRef` mặc định là `fresh` = tách từ `origin/<default-branch>`,
**không phải HEAD hiện tại**.

Mọi giả định `.worktrees/<change-name>` trong jiangway và danielhanold đều sai trên máy bạn. Toàn bộ
bước `finalize` của danielhanold dựng trên hai literal đó.

### 7.3 Không gì mang file chưa commit vào worktree

Grep `untracked|uncommitted|stash` trong cả 14 skill: **không có kết quả nào.**

jiangway đã **cố tình xoá** bước tự commit artifact sau khi review PR #970, với lý do "việc xử lý thư
mục change chưa track là trách nhiệm của skill worktree". Skill worktree **không có** trách nhiệm đó,
cả ở 5.x lẫn 6.2.0.

→ Hậu quả: executor được đưa một `plan.md` **không tồn tại trong worktree**. Phải commit artifact
trước khi vào worktree.

Thêm nữa, 6.2.0 `using-git-worktrees` bước 0 giờ **hỏi ý kiến** và tôn trọng việc từ chối (*"If the
user declines consent, work in place and skip to Step 2"*) — nên phải khai báo sẵn ý muốn trong
CLAUDE.md, không thì nó hỏi mỗi lần.

---

## 8. Brownfield

### 8.1 Bootstrap spec: lười có chủ đích

Không dựng lại spec cho toàn bộ codebase. Tài liệu OpenSpec nói thẳng: *"Resist the urge to back-fill
everything."* Lần đầu chạm tới một capability thì **delta đó chính là spec đầu tiên** của nó.

**Luật ADDED vs MODIFIED:**

> **ADDED nghĩa là "chưa có trong spec", không phải "chưa có trong code".**

Hành vi đã chạy production nhiều năm nhưng chưa ghi vào `openspec/specs/` vẫn phải viết **ADDED**. Vì
`openspec archive` throw cứng `MODIFIED failed for header "### Requirement: X" - not found` — và chỉ
nổ **lúc archive**, sau khi đã code xong.

Hai bẫy định dạng: MODIFIED phải mang **toàn bộ** khối requirement (thiếu scenario → archive abort);
scenario header phải đúng **bốn** dấu thăng, ba dấu thì *"will fail silently"*.

**Đừng chạy `/opsx:onboard` trên repo thật** — phase 8 của nó là `/opsx:apply`, viết code không kỷ
luật test.

### 8.2 Hoà giải Iron Law với code chưa có test

Characterization test (ghim hành vi **hiện có**) **pass ngay** — và có **bốn** chỗ trong skill nổ khi
thấy test pass:

1. *"Test passes? You're testing existing behavior. Fix test."*
2. Red flag *"Test passes immediately"*, biện pháp *"Delete code. Start over with TDD."*
3. Checklist *"Watched each test fail before implementing"* + *"Can't check all boxes? … Start over."*
4. Implementer subagent bắt buộc nộp bằng chứng RED

Biện pháp ở (2) **vô nghĩa** với characterization test — không có production code nào để xoá. Agent sẽ
dao động chứ không từ chối dứt khoát. Và nó **không thể tự cho phép**: skill chặn sẵn đường lý luận đó
bằng *"Violating the letter of the rules is violating the spirit of the rules"*.

**Lối ra hợp lệ** nằm ở dòng cuối của chính skill: *"No exceptions without your human partner's
permission."* CLAUDE.md **chính là** sự cho phép đó — nên viết dạng *"Người cộng sự của bạn đã cấp
ngoại lệ thường trực sau đây…"* để agent đọc thành **tuân thủ**.

**Luật cần viết:**

> Mỗi test thuộc đúng một trong hai loại, **khai báo trước khi chạy**.
> **SPEC TEST** dẫn dắt hành vi mới — **phải fail trước**; pass ngay là test hỏng.
> **CHARACTERIZATION TEST** ghim hành vi đã có — **phải pass trước**; pass ngay là **điều kiện thành
> công**, không phải red flag.
> Iron Law chi phối việc **sinh production code**; viết characterization test không sinh production
> code nên không kích hoạt nó.
> Characterization test được kiểm chứng bằng cách **cố tình làm hỏng** production code, xem test fail,
> rồi hoàn tác.

**Điều khoản chống lách:** khai loại **trước** khi chạy; không được đổi spec test thành
characterization test **sau khi** thấy nó pass; characterization test nằm ở `tests/characterization/`
để kiểm tra được trong diff, và commit **trước** thay đổi production mà nó bảo vệ.

| Tình huống | Xung đột? | Làm gì |
|---|---|---|
| Sửa code cũ chưa có test | **Có** | Ghim hành vi → chứng minh lưới bằng mutation → commit riêng → rồi mới TDD phần mới |
| Sửa bug trong code cũ | **Không** | Test tái hiện bug khẳng định hành vi **đúng** nên fail thật. RED chính hiệu. |
| Thêm hàm mới cạnh code cũ | **Không** | TDD bình thường. **Đừng** retro-test code cũ xung quanh. |

Lưu ý: dòng *"Existing code has no tests → You're improving it. Add tests for existing code."* trong
skill **không phải** miễn trừ — nó bảo viết **thêm** test cho code cũ, rồi chính test đó đâm vào luật
Verify-RED. Đây là cửa ngõ agent rơi vào bẫy.

---

## 9. Chi phí bảo trì

**Bên churn nhanh hơn lại chính là bên đã cài.**

| | Release / 6 tháng | Major breaking |
|---|---|---|
| superpowers | 19 | **2** (5.0.0, 6.0.0) |
| OpenSpec | 13 | 0 |

**Tin tốt, và nó quan trọng:** không bridge nào tham chiếu **một tên file nào** của superpowers — grep
`testing-anti-patterns`, `writing-good-tests`, mọi tên file reviewer prompt: **không có kết quả**. Nên
việc 6.0.0 đổi tên reviewer prompt và 6.2.0 đổi `testing-anti-patterns.md` → `writing-good-tests.md`
**không phá gì cả**.

→ **Giữ đúng kỷ luật này trong bản fork của bạn: chỉ nhắc tên skill, không bao giờ nhắc đường dẫn
file, tên script, hay trích nguyên văn text của skill.**

Nguy cơ mới của 6.2.0 không phải tên skill, mà là **xuất xứ worktree** (mục 7.2).

**Việc phải làm sau mỗi lần nâng cấp:**
1. `ls .claude/skills/ .claude/commands/opsx/` — xác nhận không có lệnh nào tự quay lại (profile nằm ở
   config **toàn cục**, có thể trôi)
2. Kiểm lại hợp đồng định dạng plan còn parse được cả hai phía
3. Diff CLAUDE.md quanh cặp marker OPENSPEC

**Tránh `Stores`** — beta, *"expect breaking changes"*, giải bài toán multi-repo bạn không có.

**Cài đặt:** chạy `openspec init` **trước**, viết CLAUDE.md **sau**. Nếu CLAUDE.md có sẵn, init quét
thấy và hỏi *"Legacy files detected. Upgrade and clean up? [Y/n]"* — mặc định YES, **abort nếu trả lời
N**. Và **không bao giờ sửa** `openspec/AGENTS.md` hay `.claude/skills/openspec-*/SKILL.md` —
`openspec update` ghi đè im lặng.

---

## 10. Phương án tối giản và vì sao nó thua

Đối thủ thật: **chỉ superpowers + một file spec viết tay**, không cài gì thêm.

Nó thua vì một lý do hẹp. Superpowers **cố tình huỷ hồ sơ của chính nó**: *"the workspace is deleted
once the final review is clean — git history is the durable record."* Nên file spec viết tay **không
có người viết, không có bộ kiểm, không có từ vựng ADDED/MODIFIED/REMOVED**. Sau sáu tháng nó mục — và
một phần đáng kể trở thành sai mà không phân biệt được phần nào.

**Và file convention cũ kỹ tệ hơn là không có file nào**, vì agent đọc nó như thẩm quyền trong mọi
task. Kiểu hỏng này âm thầm, tích luỹ, và **không sửa được bằng kỷ luật — vì chính kỷ luật lỏng ra là
cơ chế hỏng.**

Cái OpenSpec mua được: **archive là một cái cổng, không phải một lời hứa.** Change không có delta thì
validate trượt; MODIFIED lỗi thời thì dừng chứ không ghi đè. Cập nhật spec thành **sản phẩm phụ của
việc đóng change**.

**Đừng bán quá lời:** cổng đó chỉ ràng buộc nếu bạn thật sự chạy archive. Ngừng archive thì mục y hệt,
cộng một đống thư mục change treo. Khác biệt là sự mục nát **nhìn thấy được** (`openspec list` hiện
change chưa archive) chứ không âm thầm.

---

## 11. Việc cần làm tiếp

Theo thứ tự. Chưa làm gì trong số này.

1. **`git init && git add -A && git commit -m "baseline"`** — chặn cứng. Ba script của
   `subagent-driven-development` gọi `git rev-parse --show-toplevel` dưới `set -euo pipefail`. Thư mục
   hiện chưa phải git repo nên chưa chạy được gì. Chỉ `test-driven-development` là không cần git.
2. `npx @fission-ai/openspec@latest init --tools claude` trên cây sạch, **trước khi** viết CLAUDE.md.
3. `openspec schema fork spec-driven sdd-tdd`, rồi bốn sửa đổi ở mục 5.1.
4. Viết `apply.instruction` hai nhánh (mục 5.2) — đây là chỗ mua TDD.
5. Viết đoạn CLAUDE.md (mục 5.4), đặt ngoài marker OPENSPEC.
6. **Chạy thử một change nhỏ thật** từ đầu đến archive. Kiểm ba thứ: `openspec/specs/<capability>/spec.md`
   có được archive ghi ra không; `openspec list` báo "No tasks" mà không chặn; và git history cho thấy
   một test fail được commit **trước** phần implement của nó.
7. Chạy thử một change lớn thật qua `writing-plans` + `subagent-driven-development`.

---

## Phụ lục A — Mức độ tin cậy

**Đã chạy hết một vòng trên repo nháp** (OpenSpec 1.6.0, 2026-07-26) — thiết kế ở mục 5 hoạt động:
- `openspec init --tools claude` cài đúng 6 lệnh: `propose, explore, apply, archive, sync, update`.
  Không có `new`/`continue`/`ff`/`verify` — khớp `CORE_WORKFLOWS`.
- Schema fork đúng cấu trúc dự đoán: `design.requires: [proposal]`, `tasks.requires: [specs, design]`,
  `apply.requires: [tasks]`, `tracks: tasks.md`, và `apply.instruction` gốc dài **2 dòng**, không
  một chữ nào về test.
- Sau bốn sửa đổi: `openspec status` cho `design` và `tasks` cùng `blocked by: specs` — đúng thiết kế.
- **Cổng mở với 2 trên 5 artifact.** Chỉ có `proposal.md` + `specs/`, `instructions apply` trả
  `state: "ready"`.
- `apply.instruction` được **inject nguyên văn** — đọc lại thấy đúng từng chữ đã viết.
- `openspec list` báo `No tasks`, không chặn. `openspec validate` pass.
- `openspec archive` gộp delta vào `openspec/specs/csv-export/spec.md` và chuyển change vào `archive/`.
- **Phân tầng tự hiện trong tooling:** change có `tasks.md` thì `list` báo `0/3 tasks` và archive
  bật `archive_tasks_incomplete`; change không có thì sạch cả hai.
- Xác nhận hai cảnh báo: spec mới bị chèn `## Purpose TBD - created by archiving change <name>`;
  và `archive --json` không kèm `--yes` trả lỗi nhưng **exit 0**.

**Đã kiểm chứng bằng cách chạy thật** (cài OpenSpec 1.6.0, chạy lệnh, đọc `dist/`):
- `apply: requires: [specs]` + `tracks: null` → tasks.md thành tuỳ chọn thật; apply trả `state: "ready"`
- `apply.instruction` được inject nguyên văn vào `openspec instructions apply --json`
- Đổi tên plan thành `<name>-plan.md` → `openspec list` báo "No tasks", archive không còn cổng task
- `/opsx:propose` chạy vòng lặp tới khi thoả `apply.requires` rồi dừng
- `CORE_WORKFLOWS = ['propose','explore','apply','update','sync','archive']`
- `openspec validate` bỏ qua `tasks.md` hoàn toàn
- Checkbox thụt lề không được đếm; `apply.requires` không được validate
- Xoá khối `apply` → mọi artifact thành bắt buộc
- superpowers không có skill nào ghi `- [x]`; `subagent-driven-development` không nhắc `test-driven-development`
- Không skill nào trong 14 skill xử lý file chưa commit
- Cả ba bridge: không tham chiếu tên file superpowers nào

**Từ tài liệu, chưa chạy thử:**
- `openspec update` ghi đè SKILL.md đã sinh
- Luồng tương tác của `openspec config profile`

**Chưa kiểm được:**
- Hành vi thực tế của `EnterWorktree` với `baseRef: fresh` trong luồng này
- `skip_specs: true` **không có** trong bản npm 1.6.0 đã publish, chỉ có ở repo HEAD — đừng thiết kế dựa vào nó

**Đã sửa so với các bản trước của tài liệu:**
- Spec Kit không còn ép TDD → lập luận "hai thẩm quyền xung đột" bỏ
- OpenSpec hỗ trợ 30+ công cụ, không hẹp hơn Spec Kit
- Mẹo "giữ tên `tasks.md`, superpowers viết nội dung" → **sai**, phải tách hai file
- `/opsx:continue` và `/opsx:ff` không có trong profile mặc định → bề mặt xung đột nhỏ hơn tôi nói
- **Khuyến nghị "fork superpowers-bridge rồi cắt" → đổi thành fork `spec-driven` gốc** (mục 1)
- **TDD không còn lan truyền qua `subagent-driven-development` trong 6.2.0** (mục 7.1) — điều này đúng
  kể cả khi không dùng OpenSpec

## Phụ lục B — Nguồn

OpenSpec: [repo](https://github.com/Fission-AI/OpenSpec) ·
[commands](https://github.com/Fission-AI/OpenSpec/blob/main/docs/commands.md) ·
[customization](https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md) ·
[existing-projects](https://github.com/Fission-AI/OpenSpec/blob/main/docs/existing-projects.md)

Bridge: [jiangway/openspec-schemas](https://github.com/JiangWay/openspec-schemas) ·
[PR #970](https://github.com/Fission-AI/OpenSpec/pull/970) ·
[veath](https://github.com/Veath/openspec-spec-driven-superpowers) ·
[danielhanold/superspec](https://github.com/danielhanold/superspec)

Spec Kit: [repo](https://github.com/github/spec-kit) ·
[constitution-template](https://github.com/github/spec-kit/blob/main/templates/constitution-template.md) ·
[Discussion #152](https://github.com/github/spec-kit/discussions/152)

superpowers: `C:\Users\duyng\.claude\plugins\cache\claude-plugins-official\superpowers\6.2.0\`
