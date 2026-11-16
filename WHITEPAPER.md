# Từ điển Pāḷi – Việt: Whitepaper

**Ứng dụng tra cứu Pāḷi miễn phí cho người Việt — những gì dự án đã xây dựng trên nền Digital Pāḷi Dictionary**

Phiên bản 1.0 — tháng 11/2026 · Tác giả: Kiên Lê (Giác Ngộ) · Mã nguồn: github.com/babyskill/palidict

---

## 1. Bối cảnh

Người học Phật ở Việt Nam đọc kinh Nikāya qua bản dịch của Hòa thượng Thích Minh Châu, nhưng khi cần tra một từ Pāḷi gốc thì gần như chỉ có các công cụ tiếng Anh. Từ điển Pāḷi – Việt được xây dựng để lấp khoảng trống đó: một ứng dụng miễn phí, chạy ngoại tuyến, lấy dữ liệu từ điển học thuật Digital Pāḷi Dictionary (DPD) làm nền và bổ sung các lớp dữ liệu tiếng Việt do dự án tự xây dựng.

## 2. Phần nền: dữ liệu DPD

Dự án không làm lại từ điển. Phần khung xương thuộc về **Digital Pāḷi Dictionary** của Bhikkhu Bodhirasa (giấy phép CC BY-NC-SA 4.0): hơn 64.000 mục từ có trong gói dữ liệu của ứng dụng, kèm thông tin ngữ pháp, căn từ, cấu tạo từ, ví dụ trích từ kinh điển và bảng tra cứu theo dạng biến cách. Ứng dụng hiển thị các dữ liệu này nguyên trạng và ghi nguồn rõ ràng trong từng thẻ từ.

## 3. Những phần dự án tự xây dựng

### 3.1 Lớp nghĩa tiếng Việt

Đây là lớp dữ liệu lớn nhất của dự án, gồm ba nguồn được xếp theo thứ tự ưu tiên hiển thị:

- **Nghĩa gốc Bửu Chơn**: Tự điển Pāḷi – Việt của Hòa thượng Bửu Chơn (1976) được chuẩn hoá từ bản máy đọc được (9.398 lemma) và nối vào mục từ DPD. Việc nối không làm theo khoá đã lột dấu (cách nối dễ gắn nghĩa của từ này sang từ khác, ví dụ *Taṭa* gắn nhầm cho *tata*), mà nối theo lemma đúng dấu phụ qua nhiều tầng kiểm chứng, kèm cơ chế "cách ly an toàn": mục nào chưa chắc khớp thì không hiển thị. Nguyên tắc xuyên suốt là **thiếu nghĩa còn hơn sai nghĩa** — sau mỗi lần đóng gói dữ liệu đều có bước kiểm toán tự động chứng minh không còn nghĩa nào bị gắn sai từ.
- **Bản dịch mới (9.204 mục)**: các mục DPD chưa có nghĩa Việt được dịch mới theo độ ưu tiên tần suất xuất hiện trong kinh điển — 500 mục hay gặp nhất, rồi 2.153 mục mức tiếp theo, rồi 6.551 mục kế tiếp. Chuẩn dịch thống nhất: dịch sát nghĩa gốc tiếng Anh của DPD, không diễn giải thêm, không gộp "nghĩa đen" vào ô nghĩa. Toàn bộ đã qua rà soát độc lập từng dòng.
- **Lớp hiệu đính thuật ngữ**: các thuật ngữ cốt lõi được giới tu học ngày nay dùng khác với ngôn ngữ năm 1976 (ví dụ *mettā* — "tâm từ; lòng từ ái") được đính chính trong một lớp riêng có nhãn **"Đã hiệu đính"**, hiển thị trên cùng; nguyên văn Bửu Chơn vẫn giữ nguyên bên dưới để đối chiếu.

Nhờ cơ chế kế thừa nghĩa cho các dạng biến cách (một dạng biến cách nhận nghĩa của lemma gốc), độ phủ tiếng Việt hiện đạt: **100% gói Lite** (5.000 từ hay gặp nhất) và **98,3% tính theo tần suất xuất hiện trong kinh điển** ở gói Core đầy đủ.

### 3.2 Cách đọc phát âm

Mỗi mục từ có thêm một thẻ "Cách đọc" do dự án tự sinh cho toàn bộ hơn 64.000 mục từ, gồm: từ Pāḷi tách âm tiết theo quy tắc chuẩn (ví dụ *met-tā*), cách đọc phiên âm theo tiếng Việt (*mết-tā*) và cách đọc phiên âm theo tiếng Anh. Quy ước phiên âm tiếng Việt (phiên bản 2) được xây dựng riêng cho người Việt, với các quy tắc như: âm tiết khép bằng phụ âm tắc thì thêm dấu sắc (*bích-khu, đúc-kha*), nguyên âm dài giữ nguyên ký tự ā ī ū và đọc kéo dài, âm cuối ṃ biến đổi theo phụ âm theo sau. Quy ước này đã được kiểm chứng chéo độc lập trước khi áp dụng. Đây là cách đọc gần đúng để người mới dám đọc thành tiếng; âm chuẩn vẫn là audio giọng nam của DPD, được phát trực tuyến qua liên kết (dự án không sao chép hay lưu trữ lại audio).

### 3.3 Tìm kiếm cho người Việt

Tìm kiếm có ba tầng: khớp đúng dạng có dấu; **gõ không dấu vẫn ra từ có dấu** (*tanha* → *taṇhā*); và gợi ý gần đúng khi gõ thiếu hoặc sai một vài chữ (*meta* → *mettā*). Người dùng cũng tra được bằng bất kỳ dạng biến cách nào của từ, không cần biết lemma gốc. Mỗi thẻ từ còn hiển thị số bài kinh trong văn bản Phật giáo sơ kỳ (EBT) có chứa từ đó, giúp người học nhận biết mức độ phổ biến.

### 3.4 Gói dữ liệu ngoại tuyến hai tầng

Để ứng dụng nhẹ nhưng vẫn đầy đủ, dữ liệu được chia hai gói: gói **Lite** (~14 MB, 5.000 từ hay gặp nhất) đóng sẵn trong ứng dụng, cài xong tra được ngay không cần mạng; gói **Core** (đầy đủ hơn 64.000 mục từ, tải ~31 MB) tải thêm miễn phí ngay trong ứng dụng. Gói Core được phân phối từ hai nguồn độc lập (một máy chủ chính và GitHub dự phòng), tự động chuyển nguồn khi một nguồn lỗi, và mọi lượt tải đều được kiểm chứng bằng kích thước + mã băm SHA-256 trước khi cài.

### 3.5 Ứng dụng đa nền tảng

Ứng dụng viết bằng Flutter, chạy trên Android, iOS, macOS và Windows từ một mã nguồn, giao diện tiếng Việt và tiếng Anh. Một số điểm đáng chú ý: màn hình chính dẫn dắt bằng chọn chạm cho người mới (Từ của ngày chọn từ nhóm từ hay gặp nhất, mục "Hay gặp trong kinh", mục lục theo bảng chữ cái Pāḷi, các từ gần đây); trên máy tính, giao diện tự mở thành hai cột khi cửa sổ đủ rộng; có lưu dấu trang, lịch sử tra cứu, chế độ sáng/tối; toàn bộ tra cứu hoạt động ngoại tuyến.

## 4. Giấy phép và ghi nguồn

- **Mã nguồn ứng dụng**: giấy phép MIT — github.com/babyskill/palidict
- **Dữ liệu DPD**: CC BY-NC-SA 4.0, © Digital Pāḷi Dictionary / Bhikkhu Bodhirasa
- **Lớp nghĩa Bửu Chơn**: ghi nguồn Tự điển Pāḷi – Việt của Hòa thượng Bửu Chơn; dự án phi thương mại
- **Audio phát âm**: thuộc DPD (dpdict.net), ứng dụng chỉ liên kết phát trực tuyến

## 5. Trạng thái và việc còn lại

Phiên bản 1.0 đã phát hành cho macOS và Windows (tải tại trang Releases của GitHub và giacngo.org/tu-dien-pali); bản Android đang thử nghiệm kín trên Google Play và bản iOS đang hoàn thiện hồ sơ App Store. Các phần đang tiếp tục: dịch nốt các mục từ tần suất thấp còn lại của gói Core, hiệu đính thuật ngữ chuyên sâu theo đợt, và chờ chuyên gia Pāḷi hiệu đính lớp dịch mới trước khi coi là bản chính thức.
