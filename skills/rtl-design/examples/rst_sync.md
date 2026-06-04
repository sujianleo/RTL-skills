# rst_sync

```verilog
/*
1. 模块一句话职责
   - 实现复位异步拉低、同步释放，把外部异步复位安全带入当前时钟域。

2. 接口语义
   - rst_n_in  : 外部异步低有效复位输入
   - rst_n_out : 对 clk 域同步释放后的低有效复位输出
   - clk       : 目标同步时钟域

3. 模块原理
   - 复位拉低时要求尽快作用到本域，所以采用异步清零；复位释放时则不能直接放开，否则不同寄存器可能在不同拍恢复。
   - 用一个短移位寄存器在 clk 域里连续移入 1，可以把“复位释放”变成同步事件。
   - 最终只有当同步链最后一级变成 1 时，rst_n_out 才释放，从而避免释放沿的亚稳扩散。

4. 关键时序场景
   - 异步拉低: rst_n_in 一旦拉低，同步链立即清零
   - 同步释放: rst_n_in 释放后，连续两个 clk 把 1 逐级移入同步链
   - 稳定输出: 当最后一级变成 1 时，rst_n_out 才释放
   - 边界扩展: 若 MTBF 要求更高，可增加同步级数并延后释放更多拍

5. 跨拍事实
   - 同步链当前推进到哪一级必须跨拍保留，否则无法把异步释放转换成同步释放。

6. 状态 / 寄存器
   - shreg[1:0] : 记录当前复位释放同步进行到第几级

7. 每个寄存器的 set / clear / hold
   - shreg
     - clear: rst_n_in 拉低时立即清 0
     - shift: 未复位时每拍移入一个 1

8. 结构说明
   - 核心不是“同步 assert”，而是“异步 assert + 同步 deassert”。
   - 这是标准 2 级 reset synchronizer，重点在 deassert 安全。
*/
module rst_async_assert_sync_deassert_shreg (
    // 目标时钟域接口
    input  logic clk,
    input  logic rst_n_in,
    output logic rst_n_out
);
  logic [1:0] shreg;

  // 复位拉低时异步清零；释放时在本时钟域里逐拍同步推进。
  always_ff @(posedge clk or negedge rst_n_in) begin
    if (!rst_n_in) shreg <= 2'b00;
    else shreg <= {shreg[0], 1'b1};
  end

  // 只有同步链最后一级为 1，才真正释放本域复位。
  assign rst_n_out = shreg[1];
endmodule
```
