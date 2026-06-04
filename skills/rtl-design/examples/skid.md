# skid

```verilog
/*
1. 模块一句话职责
   - 给单个 valid/ready 通道插入 1-entry skid buffer，切断 ready 的反向组合路径，并在阻塞边沿多吸收 1 个 beat。

2. 接口语义
   - s_valid : 上游这拍是否提供有效 beat
   - s_ready : 本模块这拍是否允许上游继续发送
   - s_data  : 上游这拍送来的数据
   - m_valid : 本模块这拍是否向下游提供有效 beat
   - m_ready : 下游这拍是否接收当前 beat
   - m_data  : 本模块当前对下游可见的数据

3. 模块原理
   - 模块内部有一个主输出槽位，用来保存当前对下游可见的 beat。
   - 另外还有一个备用槽位，用来吸收“下游刚阻塞，但上游因 ready 延后一拍又多送来的那个 beat”。
   - 下游恢复后，必须先把备用槽位里更老的 beat 回填到主输出槽位，再重新放开上游接收。

4. 关键时序场景
   - 空闲到首拍传输: 第一个 beat 直接进入主输出槽位。
   - 连续流动: 下游持续 ready 时，可以一边送出当前 beat，一边接收新的 beat。
   - 阻塞边沿: 下游刚变成不 ready，但上游这拍仍可能合法地再送来 1 个 beat，这个 beat 需要进入备用槽位。
   - 阻塞恢复: 下游重新 ready 后，备用槽位中更老的 beat 先回到主输出槽位。
   - 容量边界: 当主槽位和备用槽位都已经占用时，必须阻止继续接收更多数据。

5. 跨拍事实
   - 当前主输出槽位中的数据内容必须跨拍保留，否则阻塞后无法继续送出原 beat。
   - 当前主输出槽位是否有效必须跨拍保留，否则无法区分“空槽位”和“有待发送数据”。
   - 当前备用槽位中是否还缓存着一个更老的 beat 也必须跨拍保留，否则恢复时无法保证顺序。
   - 对上游可见的 ready 必须寄存，否则就没有真正切断 ready 的反向组合路径。

6. 状态 / 寄存器
   - main_reg : 主输出槽位中的数据
   - m_valid  : 主输出槽位当前是否有效
   - skid_reg : 备用槽位中的数据
   - skid_en  : 备用槽位当前是否有效
   - s_ready  : 对上游导出的寄存型 ready

7. 每个寄存器的 set / clear / hold
   - s_ready
     - clear: 阻塞边沿额外吸收的那个 beat 已经进入备用槽位，此时不能再继续接收
     - set  : 备用槽位中的更老 beat 已经可以回到主输出槽位，此时可重新开放上游接收
     - hold : 其他周期保持
   - m_valid
     - set  : 主输出槽位获得一个新的有效 beat，来源可能是输入，也可能是备用槽位回填
     - clear: 当前主输出 beat 被消费且本拍没有新的 beat 补位
     - hold : 其他周期保持
   - main_reg
     - load : 优先从备用槽位回填更老 beat；否则在主槽位可更新时装入新的输入 beat
     - hold : 其他周期保持
   - skid_reg
     - load : 阻塞边沿因 ready 延后一拍而多接收的那个 beat
     - hold : 其他周期保持
   - skid_en
     - set  : 备用槽位成功吸收了额外 beat
     - clear: 备用槽位中的 beat 已经回填到主输出槽位
     - hold : 其他周期保持

8. 结构说明
   - 设计推导阶段只讨论“主槽位装载”“备用槽位吸收额外 beat”“恢复时回填更老 beat”这些行为和跨拍事实。
   - RTL 实现阶段再把这些行为映射成 take_into_main、take_into_skid、refill_main 这类事件线名字。
*/
module skid_buffer #(
    parameter WIDTH = 32
) (
    // 时钟与复位
    input wire clk,
    input wire rst_n,

    // 上游 valid/ready 接口
    input  wire             s_valid,
    output reg              s_ready,
    input  wire [WIDTH-1:0] s_data,

    // 下游 valid/ready 接口
    output reg              m_valid,
    input  wire             m_ready,
    output wire [WIDTH-1:0] m_data
);
  reg  [WIDTH-1:0] main_reg;
  reg  [WIDTH-1:0] skid_reg;
  reg              skid_en;
  wire             in_fire;
  wire             out_fire;
  wire             take_into_skid;
  wire             take_into_main;
  wire             refill_main;

  // 事件线：接收一个 beat、送出一个 beat、主槽位直装、备用槽位吸收、恢复回填。
  assign in_fire        = s_valid && s_ready;
  assign out_fire       = m_valid && m_ready;
  assign take_into_skid = in_fire && m_valid && !m_ready;
  assign take_into_main = in_fire && (!m_valid || m_ready);
  assign refill_main    = skid_en && m_ready;

  // s_ready 记录下一拍是否还允许继续接收上游数据。
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) s_ready <= 1'b1;
    else if (take_into_skid) s_ready <= 1'b0;
    else if (m_ready) s_ready <= 1'b1;
  end

  // m_valid 记录主输出槽位当前是否有效。
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) m_valid <= 1'b0;
    else if (refill_main) m_valid <= 1'b1;
    else if (take_into_main) m_valid <= 1'b1;
    else if (out_fire) m_valid <= 1'b0;
  end

  // main_reg 保存当前对下游可见的数据。
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) main_reg <= {WIDTH{1'b0}};
    else if (refill_main) main_reg <= skid_reg;
    else if (take_into_main) main_reg <= s_data;
  end

  // skid_reg 只在阻塞边沿吸收额外到达的那个 beat。
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) skid_reg <= {WIDTH{1'b0}};
    else if (take_into_skid) skid_reg <= s_data;
  end

  // skid_en 记录备用槽位当前是否占用。
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) skid_en <= 1'b0;
    else if (take_into_skid) skid_en <= 1'b1;
    else if (refill_main) skid_en <= 1'b0;
  end

  // 输出路径直接来自主输出槽位。
  assign m_data = main_reg;
endmodule
```
