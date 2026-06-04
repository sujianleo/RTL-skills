# toggle_pulse_cdc

```verilog
/*
1. 模块一句话职责
   - 用 toggle 编码把 src 域事件跨域同步到 dst 域并恢复为单拍脉冲。

2. 接口语义
   - src_pulse : 源域事件
   - dst_pulse : 目标域事件脉冲

3. 模块原理
   - src 每来一次事件翻转一次源域 toggle 状态。
   - dst 用 2FF 同步后，比较同步链前后级是否不同；只要不同，就说明检测到一次事件边沿。

4. 关键时序场景
   - 源域事件触发翻转
   - toggle 通过同步链跨域传播
   - 目标域检测到状态变化后输出 1 拍脉冲

5. 跨拍事实
   - 源域 toggle 状态必须跨拍保持。
   - 目标域同步链前后级必须跨拍保持，才能恢复边沿事件。

6. 状态 / 寄存器
   - src_tgl
   - tgl_ff0 / tgl_ff1
   - dst_pulse

7. 每个寄存器的 set / clear / hold
   - src_tgl
     - toggle: 源域事件到来
     - hold  : 其他周期保持
   - dst_pulse
     - set  : 同步链前后级不同
     - clear: 同步链前后级相同

8. 结构说明
   - 适合低频事件跨域；高密度事件需闭环或 FIFO。
*/
module toggle_pulse_cdc (
    // 源时钟域
    input  logic src_clk,
    input  logic src_rst_n,
    input  logic src_pulse,

    // 目标时钟域
    input  logic dst_clk,
    input  logic dst_rst_n,
    output logic dst_pulse
);
  logic src_tgl;
  logic tgl_ff0, tgl_ff1;

  // 源域事件编码成保持型 toggle 状态。
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) src_tgl <= 1'b0;
    else if (src_pulse) src_tgl <= ~src_tgl;
  end

  // 目标域用 2FF 同步链接收 toggle。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      tgl_ff0 <= 1'b0;
      tgl_ff1 <= 1'b0;
    end else begin
      tgl_ff0 <= src_tgl;
      tgl_ff1 <= tgl_ff0;
    end
  end

  // 目标域当前拍是否检测到一次状态变化。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) dst_pulse <= 1'b0;
    else dst_pulse <= tgl_ff0 ^ tgl_ff1;
  end
endmodule
```
