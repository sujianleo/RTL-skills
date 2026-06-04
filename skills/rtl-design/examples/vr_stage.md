# vr_stage

```verilog
/*
1. 模块一句话职责
   - 提供 1 级同步 valid/ready 寄存切片，完成单拍缓存与标准 backpressure 握手。

2. 接口语义
   - s_valid / s_ready / s_data : 上游有效、可接收、数据
   - m_valid / m_ready / m_data : 下游有效、可接收、数据

3. 模块原理
   - 内部仅维护 data_reg 和 valid_reg。
   - 通过“空槽可收，或当前拍可被消费则可收”的规则，实现标准单槽位 valid/ready 传输。

4. 关键时序场景
   - 空闲到首拍: 输入被接收后，寄存器槽位变成有效
   - 稳态传输: 下游持续 ready 时可连续一拍一拍流动
   - 下游阻塞: valid 保持，data 保持
   - 下游恢复: 先消费旧 beat，再决定是否同拍补位

5. 跨拍事实
   - 当前缓存的数据内容必须跨拍保留。
   - 当前缓存是否有效必须跨拍保留。

6. 状态 / 寄存器
   - data_reg  : 当前输出数据缓存
   - valid_reg : 当前缓存有效标志

7. 每个寄存器的 set / clear / hold
   - data_reg
     - load : 本拍成功接收输入时装入数据
     - hold : 其他周期保持
   - valid_reg
     - set  : 本拍成功接收输入
     - clear: 当前缓存被消费且本拍没有新补位
     - hold : 其他周期保持

8. 结构说明
   - 设计推导阶段只讨论“槽位为空/占用”和“是否同拍补位”。
   - RTL 实现阶段再把这些行为映射成 in_fire 和 out_fire。
*/
module vr_stage #(
    parameter int WIDTH = 8
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

  // 槽位为空，或者当前拍会被消费时，允许继续接收。
  assign s_ready = !valid_reg || m_ready;

  // 事件线：本拍接收一个新 beat / 本拍送出当前 beat。
  assign in_fire  = s_valid && s_ready;
  assign out_fire = m_valid && m_ready;

  assign m_valid = valid_reg;
  assign m_data  = data_reg;

  // 当前缓存的数据内容。
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= '0;
    end else if (in_fire) begin
      data_reg <= s_data;
    end
  end

  // 当前缓存是否有效。
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
