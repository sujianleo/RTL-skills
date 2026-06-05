# strobe_hold_tx

## 本例 5 要素

| Core | 本例体现 |
|---|---|
| Fact | hold register 记住“strobe 已发起但 transaction 还没 done”。 |
| Event | start strobe set hold，done/clear 释放 hold。 |
| Priority | reset > done/clear > start > hold。 |
| Boundary | start 和 done 同拍、busy start、abort clear 都必须定义。 |
| Contract | 输出请求是 level，必须保持到外部 done，而不是只打一拍。 |

```verilog
/*
1. 模块一句话职责
   - 提供最小单向 strobe/data 发送结构。

2. 接口语义
   - send / send_data : 发送端输入
   - strobe / data    : 输出到接收端

3. 模块原理
   - strobe 由 send 直接驱动。
   - send=1 时更新 data；send=0 时 data 保持。

4. 关键时序场景
   - send=0: strobe=0，data 保持
   - send=1: strobe=1，data 装入 send_data

5. 跨拍事实
   - strobe 和 data 都是对外保持的时序状态。

6. 状态 / 寄存器
   - strobe
   - data

7. 每个寄存器的 set / clear / hold
   - strobe
     - set  : send=1
     - clear: send=0
   - data
     - load : send=1
     - hold : send=0

8. 结构说明
   - 该结构不含回压与确认，不是完整握手协议。
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
