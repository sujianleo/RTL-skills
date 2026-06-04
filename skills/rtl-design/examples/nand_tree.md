# nand_tree

```verilog
/*
1. 模块一句话职责
- 生成逐位 walk-one 测试向量，并把各 PAD 输入压到一棵 NAND 树上，便于做 PAD 连通性观测。

2. 接口语义
- scan_en 为 1 时启动逐位扫描。
- walk_one 是打到 PAD 侧的单热点测试向量。
- pad_in 是从 PAD 或其回读路径采回的观测值。
- nand_tree_out 是所有观测位经过 NAND Tree 汇总后的结果。

3. 模块原理
- 用一个单热点寄存器逐拍左移，依次只激活一个 PAD。
- 把所有 PAD 回读值送进一棵组合 NAND Tree。
- 这样既能逐位激励，又能用一个汇总点快速观察连通是否异常。

4. 关键时序场景
- 空闲进入扫描：scan_en 拉高后，从 bit0 开始输出单热点向量。
- 扫描进行中：单热点每拍左移一次，依次覆盖所有 PAD。
- 扫描结束：最后一位扫描完成后拉高 done。
- 停止扫描：scan_en 拉低后回到初始状态。

5. 跨拍事实
- 当前扫描到哪一位。
- 当前扫描流程是否已经走到最后一位。

6. 状态 / 寄存器
- walk_one：记录当前正在激励的 PAD 位。
- done：记录本轮扫描是否结束。

7. 每个寄存器的 set / clear / hold
- walk_one：scan_en 刚拉高时装入 bit0；扫描过程中左移；scan_en 拉低时回到 bit0。
- done：扫描走到最后一位时置 1；scan_en 拉低时清 0；其余保持。

8. 结构说明
- 这里不做故障判决，只提供逐位激励和 NAND Tree 汇总结果。
*/
module nand_tree_pad_scan #(
    parameter integer PAD_NUM = 8
) (
    // 1. 时钟与复位
    input  wire                 clk,
    input  wire                 rst_n,

    // 2. 测试控制
    input  wire                 scan_en,
    input  wire [PAD_NUM-1:0]   pad_in,

    // 3. 观测输出
    output reg  [PAD_NUM-1:0]   walk_one,
    output wire                 nand_tree_out,
    output reg                  done
);

    wire last_step;

    // 当前单热点已经走到最后一位。
    assign last_step = walk_one[PAD_NUM-1];

    // 所有 PAD 回读值经过一棵 NAND Tree 汇总成单点观测。
    assign nand_tree_out = ~(&pad_in);

    // 逐拍推进单热点扫描位置。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            walk_one <= {{(PAD_NUM-1){1'b0}}, 1'b1};
        end else if (!scan_en) begin
            walk_one <= {{(PAD_NUM-1){1'b0}}, 1'b1};
        end else if (!done) begin
            walk_one <= {walk_one[PAD_NUM-2:0], 1'b0};
        end
    end

    // 标记本轮 walk-one 扫描是否已经完成。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
        end else if (!scan_en) begin
            done <= 1'b0;
        end else if (last_step) begin
            done <= 1'b1;
        end
    end

endmodule
```
