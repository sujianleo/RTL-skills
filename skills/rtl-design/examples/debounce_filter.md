# debounce_filter

## 本例 5 要素

| Core | 本例体现 |
|---|---|
| Fact | sampled level、稳定计数器和 filtered output 记住“输入是否已稳定足够久”。 |
| Event | 输入变化重启计数，计数达到阈值后更新 filtered output。 |
| Priority | reset > 输入变化清计数 > 计数未满继续累加 > 达阈值更新输出。 |
| Boundary | 抖动期间不断重置计数，防止短毛刺改变输出。 |
| Contract | 输出只在输入连续稳定达到配置周期后改变。 |

```verilog
/*
1. 模块职责
   对单比特输入 din 做去抖；只有新电平连续稳定 STABLE_CYCLES 拍后，才更新输出 dout。

2. 接口语义
   clk  : 采样时钟。
   rst_n: 低有效复位。
   din  : 待去抖输入。
   dout : 去抖后的稳定输出。

3. 模块原理
   sample_q 记录当前正在观察的新候选值。
   stable_cnt_q 记录该候选值已经连续保持了多少拍。
   若 din 再次变化，则重新锁存候选值并清零计数；
   若 din 连续保持不变达到阈值，则将 dout 更新为该候选值。

4. 关键时序场景
   - 复位后，sample_q / stable_cnt_q / dout 初始化。
   - 输入刚跳变时，锁存新候选值并重新开始计数。
   - 输入持续稳定时，计数递增。
   - 计数达到阈值时，提交到 dout。

5. 状态 / 寄存器列表
   sample_q     : 当前候选输入值。
   stable_cnt_q : 候选值已经连续保持的拍数。
   dout         : 已确认稳定的输出。

6. set / clear / hold
   sample_q     : 输入变化时装入新候选值；其余情况保持。
   stable_cnt_q : 输入变化时清零；候选值持续稳定时递增；输出确认后清零。
   dout         : 只有候选值连续稳定达到阈值时才更新；其余情况保持。
*/
module debounce_filter #(
    parameter int STABLE_CYCLES = 5,
    parameter bit RESET_VALUE   = 1'b1,
    localparam int CNT_W = (STABLE_CYCLES <= 1) ? 1 : $clog2(STABLE_CYCLES)
) (
    input  logic clk,
    input  logic rst_n,
    input  logic din,
    output logic dout
);

logic             sample_q;
logic [CNT_W-1:0] stable_cnt_q;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sample_q     <= RESET_VALUE;
        stable_cnt_q <= '0;
        dout         <= RESET_VALUE;
    end else if (din != sample_q) begin
        sample_q     <= din;
        stable_cnt_q <= '0;
    end else if (dout != sample_q) begin
        if (stable_cnt_q == STABLE_CYCLES-1) begin
            dout         <= sample_q;
            stable_cnt_q <= '0;
        end else begin
            stable_cnt_q <= stable_cnt_q + 1'b1;
        end
    end else begin
        stable_cnt_q <= '0;
    end
end

endmodule
```
