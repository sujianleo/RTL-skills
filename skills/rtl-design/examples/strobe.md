# strobe

```verilog
/*
1. 模块一句话职责
   - 用最小单向 strobe/data 结构表达“发送端声明当前拍有效”，不提供接收确认或回压能力。

2. 接口语义
   - send      : 发送端这拍是否要发出一个有效指示
   - send_data : 发送端在 send=1 时给出的数据
   - strobe    : 输出到接收端的单向有效指示
   - data      : 与 strobe 对齐输出的数据

3. 模块原理
   - 该结构没有 valid/ready 闭环，也没有 req/ack 回执；发送端完全单方面决定何时把 strobe 拉高。
   - 当 send=1 时，本拍把 send_data 装入 data，并同步给出 strobe=1；当 send=0 时，strobe 拉低，data 保持上次值。
   - 因为没有接收完成语义，所以它只适合 sideband 指示、已知对端必然能采到的场景，不能替代完整握手。

4. 关键时序场景
   - 空闲: send=0，strobe=0，data 保持上次值
   - 发起: send=1，本拍拉高 strobe 并更新 data
   - 连续发送: 若 send 连续为 1，则每拍 strobe 都为 1，data 每拍可更新
   - 接收端阻塞: 本结构无 backpressure，发送端无法得知对端是否真的接收成功

5. 跨拍事实
   - strobe 当前是否拉高必须跨拍保留到下一个时钟沿。
   - data 在 send=0 时需要保持上次值，因此也必须跨拍保留。

6. 状态 / 寄存器
   - strobe : 当前拍是否向外声明有效
   - data   : 当前输出给对端的数据寄存器

7. 每个寄存器的 set / clear / hold
   - strobe
     - set  : send=1 时置位
     - clear: send=0 时清零
   - data
     - load : send=1 时装入 send_data
     - hold : send=0 时保持旧值

8. 结构说明
   - 这是“有效指示”而不是“完整握手”。
   - 若接收端可能阻塞或需要确认，就应升级为 valid/ready、req/ack 或异步 FIFO 等真正带闭环的结构。
*/
module strobe_hold_tx #(
    parameter int WIDTH = 8
) (
    // 时钟与复位
    input  logic             clk,
    input  logic             rst_n,

    // 发送侧接口
    input  logic             send,
    input  logic [WIDTH-1:0] send_data,

    // 输出到接收端
    output logic             strobe,
    output logic [WIDTH-1:0] data
);
  // strobe 和 data 都是本模块向外保持的时序状态。
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      strobe <= 1'b0;
      data   <= '0;
    end else begin
      strobe <= send;
      if (send) data <= send_data;
    end
  end
endmodule
```
