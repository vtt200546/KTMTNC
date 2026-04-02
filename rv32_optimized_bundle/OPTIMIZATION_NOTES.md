# Những gì đã tối ưu so với bản RTL cũ

## 1) Tách hazard / forwarding ra khỏi top-level
- Thêm `hazard_unit.v` để gom:
  - load-use stall
  - forwarding select từ M/W sang EX
- Lợi ích: top-level ngắn hơn, dễ đọc, dễ debug, dễ mở rộng.

## 2) Regfile có bypass WB->ID
- `regfile.v` mới cho phép nếu cùng chu kỳ vừa ghi `rd` vừa đọc lại đúng thanh ghi đó thì cổng đọc trả luôn `wd`.
- Điều này giảm phụ thuộc vào hành vi read-during-write của tool và giúp pipeline ổn hơn.

## 3) Reset của regfile đổi sang synchronous
- Bản cũ xóa cả RF bằng async reset.
- Bản mới dùng reset đồng bộ để giảm fanout reset bất lợi cho timing/synthesis.

## 4) DMEM gọn và an toàn hơn
- Dùng chỉ số địa chỉ cắt theo `$clog2(BYTES)` thay vì truy cập trực tiếp bằng bus 32-bit.
- Vẫn giữ hỗ trợ `lb/lbu/lh/lhu/lw` và `sb/sh/sw`.

## 5) Forwarding path rõ hơn
- Dùng `fwd_sel_a`, `fwd_sel_b` 2-bit thay vì nhiều if/else lồng trong top.
- `resultM` được gom thành một wire chọn theo `wb_selM`.

## 6) Giữ tương thích giao diện cũ
- Các module stage cũ vẫn dùng lại được.
- Bổ sung top mới:
  - `rv32_pipeline_top_opt.v`
  - `rv32_single_cycle_top_opt.v`
- Thêm testbench tương ứng:
  - `tb_rv32_pipeline_top_opt.sv`
  - `tb_rv32_single_cycle_top_opt.sv`

## 7) Điều chưa làm trong lượt này
- Chưa thêm branch prediction.
- Chưa tách pipeline register thành module riêng.
- Chưa chạy compile/sim tự động trong môi trường hiện tại vì không có simulator Verilog cài sẵn.
