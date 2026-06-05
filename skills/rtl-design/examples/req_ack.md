# req_ack

## 本例 5 要素

| Core | 本例体现 |
|---|---|
| Fact | source request level 记住“有一个事件尚未被 ack”，同步链记住跨域 req/ack 状态。 |
| Event | `src_pulse` set request，dst 首次看到 request 产生 `dst_pulse`，ack 返回后 clear request。 |
| Priority | reset > ack clear > new source event set > hold。 |
| Boundary | request busy 时新 `src_pulse` 不形成第二个 outstanding 事务。 |
| Contract | 单 outstanding 闭环 CDC，事件不会静默丢失但吞吐受 ack 往返限制。 |

```verilog
/*
1. 模块一句话职责
   - 用 req/ack 闭环把 src 域事件可靠搬运到 dst 域，并限制为单 outstanding 请求。

2. 接口语义
   - src_pulse : src 域发起一次事件请求
   - dst_pulse : dst 域看到新请求时输出的一拍脉冲
   - req       : src 域发往 dst 域的保持型请求
   - ack       : dst 域返回 src 域的确认信号
   - src_clk / dst_clk : 两个彼此异步的时钟域

3. 模块原理
   - 源域不再发一个瞬时 pulse 就结束，而是把请求固化成保持型 req，直到收到目标域回传的 ack 才撤销。
   - 目标域只要观察到同步后的请求已经到达且确认仍未置位，就知道当前有一笔新请求，于是产生 dst_pulse 并把 ack 拉高。
   - 这个闭环保证事件不会被静默吞掉，但代价是同一时刻只能容纳一个 outstanding 请求，吞吐低于 toggle 方案。

4. 关键时序场景
   - 事件发起: src_pulse 到来后，src 域把 req 置 1 并保持
   - 请求跨域: req 经过 2FF 同步到 dst 域形成稳定可见状态
   - 目标域确认: dst 域首次看到请求有效且确认仍为 0 时输出 dst_pulse，并把 ack 拉高
   - 请求收尾: ack 再同步回 src 域，src 看到确认后清 req
   - 边界情况: req 尚未完成前，再来的 src_pulse 不会形成第二个并行 outstanding 事务

5. 跨拍事实
   - req 必须在源域跨拍保持，否则目标域可能采不到这次请求。
   - ack 必须在目标域跨拍保持，否则源域可能收不到确认返回。
   - 两边的同步链状态都必须跨拍保留，才能完成闭环。

6. 状态 / 寄存器
   - req : 记录 src 域当前是否有未完成请求
   - ack : 记录 dst 域是否已确认当前请求
   - req_ff0 / req_ff1 : req 的 dst 域同步链
   - ack_ff0 / ack_ff1 : ack 的 src 域同步链

7. 每个寄存器的 set / clear / hold
   - req
     - set  : src_pulse 到来时置位
     - clear: 确认已经同步回 src 域
     - hold : 其他周期保持，直到确认返回
   - ack
     - set  : dst 域首次看到一个尚未确认的新请求
     - clear: 源域已经撤销本次请求
     - hold : 其他周期保持
   - req_ff* / ack_ff*
     - load : 每拍采样前一级，完成跨域同步

8. 结构说明
   - 设计推导阶段只讨论“请求保持到确认返回”的闭环，不提前使用实现名。
   - RTL 实现阶段再把这些行为映射成 req、ack 和两边同步链。
*/
module cdc_req_ack (
    // 源时钟域
    input  logic src_clk,
    input  logic src_rst_n,
    input  logic src_pulse,

    // 目标时钟域
    input  logic dst_clk,
    input  logic dst_rst_n,
    output logic dst_pulse
);
  logic req;
  logic ack;
  logic req_ff0, req_ff1;
  logic ack_ff0, ack_ff1;

  // 源域把事件固化成保持型请求，直到确认返回。
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

  // 确认同步回源域。
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) {ack_ff1, ack_ff0} <= 2'b00;
    else {ack_ff1, ack_ff0} <= {ack_ff0, ack};
  end

  // 目标域首次看到新请求时输出 1 拍事件。
  assign dst_pulse = req_ff1 & ~ack;

  // 目标域确认当前请求是否已经接收。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) ack <= 1'b0;
    else if (!req_ff1) ack <= 1'b0;
    else if (!ack) ack <= 1'b1;
  end
endmodule
```
