# pulse_width_det

```verilog
/*
1. 模块一句话职责
- 检测输入信号连续保持高电平或低电平的宽度，并在达到阈值时给出单拍指示。

2. 接口语义
- sig 是待测输入。
- width_cnt 是当前电平已持续的拍数。
- pulse_hi 表示高电平宽度首次达到阈值。
- pulse_lo 表示低电平宽度首次达到阈值。

3. 模块原理
- 每拍比较当前 sig 与上一拍采样值是否一致。
- 若电平未变，则宽度计数继续累加；若电平翻转，则计数从 1 重新开始。
- 当某一稳定电平的持续时间第一次达到 THRESHOLD 时，输出一个单拍脉冲。

4. 关键时序场景
- 复位后首拍：上一拍电平初始化，计数清零。
- 电平持续不变：width_cnt 逐拍增加。
- 电平发生翻转：重新开始统计新电平宽度。
- 宽度达到阈值：对应电平方向输出单拍脉冲。
- 宽度继续超过阈值：不重复拉脉冲，只保持计数继续增加。

5. 跨拍事实
- 上一拍输入电平是什么。
- 当前这段稳定电平已经持续了多少拍。
- 阈值触发是否正好发生在这一拍。

6. 状态 / 寄存器
- sig_d：记录上一拍输入电平。
- width_cnt：记录当前稳定电平宽度。
- pulse_hi / pulse_lo：记录这一拍是否触发对应方向的阈值脉冲。

7. 每个寄存器的 set / clear / hold
- sig_d：每拍采样当前 sig。
- width_cnt：电平不变时累加；电平翻转时装入 1；复位时清 0。
- pulse_hi / pulse_lo：仅在达到阈值的那个方向上置 1 一拍，其余清 0。

8. 结构说明
- 这里按高电平和低电平分别给脉冲，便于直接区分检测到的是 high width 还是 low width。
*/
module pulse_width_det #(
    parameter integer CNT_W     = 8,
    parameter integer THRESHOLD = 16
) (
    // 1. 时钟与复位
    input  wire             clk,
    input  wire             rst_n,

    // 2. 被测信号
    input  wire             sig,

    // 3. 检测输出
    output reg              pulse_hi,
    output reg              pulse_lo,
    output reg [CNT_W-1:0]  width_cnt
);

    reg sig_d;
    wire same_level;
    wire hit_threshold;

    // 当前输入是否与上一拍保持相同电平。
    assign same_level    = (sig == sig_d);
    assign hit_threshold = (width_cnt == THRESHOLD - 1);

    // 记录上一拍输入电平，供下一拍判断是否翻转。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sig_d <= 1'b0;
        end else begin
            sig_d <= sig;
        end
    end

    // 统计当前稳定电平已经持续的拍数。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            width_cnt <= {CNT_W{1'b0}};
        end else if (!same_level) begin
            width_cnt <= {{(CNT_W-1){1'b0}}, 1'b1};
        end else begin
            width_cnt <= width_cnt + {{(CNT_W-1){1'b0}}, 1'b1};
        end
    end

    // 高电平宽度第一次达到阈值时给单拍脉冲。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_hi <= 1'b0;
        end else begin
            pulse_hi <= same_level && sig && hit_threshold;
        end
    end

    // 低电平宽度第一次达到阈值时给单拍脉冲。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_lo <= 1'b0;
        end else begin
            pulse_lo <= same_level && !sig && hit_threshold;
        end
    end

endmodule
```
