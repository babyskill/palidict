# DATA SPEC — gói dữ liệu Từ điển Pāḷi-Việt (Phase 1)

Hai file SQLite do Muse dựng sẵn, lane build chỉ việc dùng:

- **Lite** `lite_final.db` — 12,2 MB, đóng sẵn trong app (assets): 5.000 headwords, 48.727 lookup, 753 roots, toàn bộ lớp Việt.
- **Core** `core_final.db` — 124,2 MB (file tải nén ~29 MB), gói tải trong app: 64.138 headwords, 367.748 lookup, 753 roots, toàn bộ lớp Việt.
  Schema Core giống Lite, chỉ khác bảng `headwords` có thêm cột: `lemma_2` giữ nguyên, cộng `derived_from, neg, verb, trans, plus_case, non_ia, sanskrit, root_base, family_root, family_word, family_compound, family_idioms, family_set, derivative, suffix, compound_type, compound_construction, source_2, sutta_2, example_2, var_phonetic, var_text, commentary, notes, cognate, link, stem, pattern, inflections`.

## Bảng `headwords` (Lite)
`id` (DPD id), `lemma_1` (kèm số nét nghĩa, vd `dhamma 1.03`), `lemma_2`, `pos`, `grammar`, `meaning_1` (Anh, ngữ cảnh), `meaning_lit`, `meaning_2` (Buddhadatta), `root_key`, `root_sign`, `construction`, `phonetic`, `source_1`, `sutta_1`, `example_1` (Pāḷi, từ đang tra được bọc `<b>…</b>`), `antonym`, `synonym`, `ebt_count` (tần suất trong EBT).
- Lemma hiển thị = `lemma_1` bỏ hậu tố số (` 1.03`, ` 2`…) — gọi là lemma_clean.
- Core có thêm `inflections` = danh sách dạng biến cách phân tách bằng dấu phẩy (cho bảng biến cách trên thẻ từ).

## Bảng `lookup`
`lookup_key` (dạng đã biến cách hoặc hợp từ, có dấu đầy đủ), `headwords` (JSON list các `id`, vd `[34626, 34627]`), `deconstructor` (JSON, chỉ có ở gói tách hợp từ — bản Lite/Core cột này rỗng), `grammar` (JSON mô tả cách/ngôi/số của dạng biến cách).
- Tra cứu: chuẩn hoá chuỗi người dùng gõ → so `lookup_key` → lấy danh sách id → mở thẻ các headwords đó.

## Bảng `meaning_vi` — lớp Việt theo lemma (Bửu Chơn)
`lemma_key` (lemma bỏ dấu, thường, bỏ khoảng trắng — khoá join), `lemma`, `pos`, `gloss_main` (nghĩa chính), `gloss_full` (gồm cả tiểu mục hợp từ), `source` = `buuchon1976`.
- Join: `lemma_key = ascii_fold(lemma_clean)`. Thẻ từ hiển thị gloss_main ở vị trí nghĩa Việt chính, ghi nguồn "HT Bửu Chơn (1976)".

## Bảng `meaning_vi_senses` — lớp Việt theo từng nét nghĩa (dịch mới Phase 1)
`entry_id` (= `headwords.id`), `vi_gloss`, `source` = `phase1-draft`.
- 500 mục tần suất cao nhất chưa có trong Bửu Chơn. Hiển thị trên thẻ ở nét nghĩa tương ứng, ghi nhãn "bản dịch mới — đang hiệu đính".

## Audio (luật cứng)
Chỉ giọng nam: URL `https://dpdict.net/audio/<lemma_clean giữ nguyên dấu, URL-encode>?gender=male`. Không có giọng nữ, không chọn giọng, không tải/lưu file.

## Chuẩn hoá tìm kiếm (phía app)
Người dùng gõ được 3 kiểu, đều phải ra cùng kết quả: có dấu (dhammā), không dấu (dhamma), Velthuis (dhammaa, .m, "n…). App tự sinh khoá ascii_fold (bỏ dấu thanh/ký tự Mn, thường hoá) để khớp `meaning_vi.lemma_key` và tra `headwords`, đồng thời tra thẳng `lookup.lookup_key` cho dạng biến cách.
