# reg_slice

```verilog
/*
1. 模块一句话职责
   - 给单个 valid/ready 通道插入 1 级最简单的数据寄存器，用一个拍周期换取更短的前向 data/valid 路径。

2. 接口语义
   - s_valid : 上游这拍是否提供一个有效 beat
   - s_ready : 本模块这拍是否还能接收上游 beat
   - s_data  : 上游这拍送来的数据
   - m_valid : 本模块这拍是否向下游提供一个有效 beat
   - m_ready : 下游这拍是否接收当前 beat
   - m_data  : 本模块当前对下游可见的数据

3. 模块原理
   - 模块内部只有一个可见输出槽位，由 data_reg 和 valid_reg 共同表示。
   - 当槽位为空，或者当前槽位这拍会被下游消费时，可以在同拍接收新的输入 beat。
   - 这个模块只切断前向 data/valid 路径，不切断反向 ready 组合路径，因此它是 simple register slice，不是 skid buffer。

4. 关键时序场景
   - 空闲到首拍传输: 第一个 beat 被接收后，下一拍仍要能继续对下游保持可见。
   - 连续流动: 当下游持续 ready 时，可以一边送出旧 beat，一边装入新 beat。
   - 下游阻塞: 当前已缓存的 beat 不能丢失，阻塞期间必须保持。
   - 下游恢复: 先把已经缓存的 beat 继续送出，再决定是否同拍换成新的输入 beat。

5. 跨拍事实
   - 当前缓存的数据内容必须跨拍保留，否则阻塞后无法继续送出原来的 beat。
   - 当前输出槽位是否占用必须跨拍保留，否则无法区分“寄存器为空”和“寄存器里有尚未消费的数据”。

6. 状态 / 寄存器
   - data_reg  : 当前缓存的 beat 数据
   - valid_reg : data_reg 当前是否有效

7. 每个寄存器的 set / clear / hold
   - data_reg
     - load : 本拍成功接收新 beat 时装入输入数据
     - hold : 其他周期保持原值
   - valid_reg
     - set  : 输出槽位获得了一个新的有效 beat
     - clear: 当前 beat 被消费且本拍没有新的 beat 补位
     - hold : 其他周期保持

8. 结构说明
   - 设计推导阶段只讨论“接收 beat”“送出 beat”“槽位是否占用”这些行为和跨拍事实，不提前假设实现名。
   - RTL 实现阶段再把这些行为映射成 in_fire、out_fire 这类事件线名字。
*/
module simple_register_slice #(
    parameter int WIDTH = 32
) (
    // 时钟与复位
    input  logic             clk,
    input  logic             rst_n,

    // 上游 valid/ready 接口
    input  logic             s_valid,
    output logic             s_ready,
    input  logic [WIDTH-1:0] s_data,

    // 下游 valid/ready 接口
    output logic             m_valid,
    input  logic             m_ready,
    output logic [WIDTH-1:0] m_data
);
  logic [WIDTH-1:0] data_reg;
  logic             valid_reg;
  logic             in_fire;
  logic             out_fire;

  // 当前槽位为空，或者当前槽位这拍会被下游消费时，允许继续接收输入。
  assign s_ready = !valid_reg || m_ready;

  // 事件线：本拍成功接收一个 beat / 本拍成功送出一个 beat。
  assign in_fire  = s_valid && s_ready;
  assign out_fire = m_valid && m_ready;

  // 输出路径直接来自当前缓存槽位。
  assign m_valid = valid_reg;
  assign m_data  = data_reg;

  // 记录当前缓存 beat 的数据内容。
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= '0;
    end else if (in_fire) begin
      data_reg <= s_data;
    end
  end

  // 记录输出槽位当前是否持有有效 beat。
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_reg <= 1'b0;
    end else if (in_fire) begin
      valid_reg <= 1'b1;
    end else if (out_fire) begin
      valid_reg <= 1'b0;
    end
  end
endmodule
```
