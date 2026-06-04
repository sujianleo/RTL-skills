# req_ack_4phase

```verilog
/*
1. 模块一句话职责
   - 用 req/ack 四相闭环把 src 域事件可靠传到 dst 域。

2. 接口语义
   - src_pulse : 源域事件输入
   - dst_pulse : 目标域单拍事件输出
   - req       : 源域保持型请求
   - ack       : 目标域确认回执

3. 模块原理
   - src 发起后保持 req，直到 ack 同步返回才清 req。
   - dst 观察到同步后的请求已经到达且确认仍未置位时，输出 dst_pulse 并拉高 ack。

4. 关键时序场景
   - 发起: 源域事件到来后，请求置位并保持
   - 确认: 目标域首次看到新请求时输出脉冲并拉高确认
   - 收尾: 确认回源后清请求；请求清掉后目标域撤销确认

5. 跨拍事实
   - req 必须跨拍保持直到确认返回。
   - ack 必须跨拍保持直到源域撤销请求。

6. 状态 / 寄存器
   - req, ack
   - req_ff0 / req_ff1
   - ack_ff0 / ack_ff1

7. 每个寄存器的 set / clear / hold
   - req
     - set  : 源域事件到来
     - clear: 确认已经同步回源域
     - hold : 其他周期保持
   - ack
     - set  : 目标域首次看到一个尚未确认的新请求
     - clear: 请求已经被源域撤销
     - hold : 其他周期保持

8. 结构说明
   - 这是四相闭环，天然单 outstanding。
   - RTL 实现阶段再把这些行为映射成 req、ack 以及两边同步链。
*/
module req_ack_4phase (
    // 源时钟域
    input  logic src_clk,
    input  logic src_rst_n,
    input  logic src_pulse,

    // 目标时钟域
    input  logic dst_clk,
    input  logic dst_rst_n,
    output logic dst_pulse
);
  logic req, ack;
  logic req_ff0, req_ff1;
  logic ack_ff0, ack_ff1;

  // 源域把事件保持成请求，直到确认返回。
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) req <= 1'b0;
    else if (src_pulse) req <= 1'b1;
    else if (ack_ff1) req <= 1'b0;
  end

  // 请求同步到目标域。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) {req_ff1, req_ff0} <= 2'b00;
    else {req_ff1, req_ff0} <= {req_ff0, req};
  end

  // 目标域首次看到新请求时输出一拍脉冲。
  assign dst_pulse = req_ff1 && !ack;

  // 目标域确认当前请求。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) ack <= 1'b0;
    else if (!req_ff1) ack <= 1'b0;
    else if (!ack) ack <= 1'b1;
  end

  // 确认同步回源域。
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) {ack_ff1, ack_ff0} <= 2'b00;
    else {ack_ff1, ack_ff0} <= {ack_ff0, ack};
  end
endmodule
```
