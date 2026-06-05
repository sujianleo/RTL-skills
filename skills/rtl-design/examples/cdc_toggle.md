# cdc_toggle

## 本例 5 要素

| Core | 本例体现 |
|---|---|
| Fact | `src_tgl` 记住源域事件奇偶状态，目标域 2FF 同步链记住采样历史。 |
| Event | `src_pulse` 触发 toggle 翻转，目标域同步链前后级不同触发 `dst_pulse`。 |
| Priority | reset 清零优先；源域事件翻转；目标域每拍同步并组合比较。 |
| Boundary | 单拍 pulse 不直接跨域；高密度事件可能被折叠，必须由契约限制事件间隔。 |
| Contract | 适合低频单向事件跨域，不提供 backpressure 或每事件确认。 |

```verilog
/*
1. 模块一句话职责
   - 把 src 域单拍事件编码成 toggle，再在 dst 域同步并还原成单拍脉冲。

2. 接口语义
   - src_pulse : src 域输入事件，一次只表示一拍请求
   - dst_pulse : dst 域输出事件，对应检测到一次 toggle 变化
   - src_clk / dst_clk : 两个彼此异步的时钟域
   - src_rst_n / dst_rst_n : 各自时钟域下的低有效复位

3. 模块原理
   - 源域不直接跨域传输单拍 pulse，而是每来一次事件就翻转一次 src_tgl。
   - toggle 是保持型状态，不像 pulse 那样容易在跨域时被漏采；目标域只需 2FF 同步，再比较前后两级是否不同，就能恢复出 1 拍事件。
   - 这个方案结构最轻，但不支持高密度 back-to-back 事件；两次事件之间必须给目标域留出足够采样时间。

4. 关键时序场景
   - 空闲到首个事件: src_pulse 到来，src_tgl 翻转一次
   - 跨域传输: src_tgl 通过同步链逐拍进入 dst 域
   - 目标域出脉冲: 同步链前后级不同时，异或产生 1 拍 dst_pulse
   - 连续事件边界: 若源域翻转过快，目标域可能来不及区分两次变化，从而丢事件

5. 跨拍事实
   - src_tgl 必须在源域保持，直到目标域有机会采到新的状态。
   - 同步链前后级必须跨拍保留，否则目标域无法通过“前后不同”恢复事件。

6. 状态 / 寄存器
   - src_tgl : 记录 src 域事件的奇偶翻转状态
   - tgl_ff0 : dst 域同步链第 1 级
   - tgl_ff1 : dst 域同步链第 2 级
   - dst_pulse : dst 域当前拍是否检测到 toggle 变化

7. 每个寄存器的 set / clear / hold
   - src_tgl
     - toggle: 源域新事件到来时翻转
     - hold  : 其他周期保持
   - tgl_ff0 / tgl_ff1
     - load : 每拍采样前一级值，构成 2FF 同步链
   - dst_pulse
     - set  : 同步链前后级不同，说明检测到一次变化沿
     - clear: 同步链前后级相同，说明当前拍没有新事件

8. 结构说明
   - 设计推导阶段只讨论“源域翻转状态”“目标域检测状态变化”这些行为。
   - RTL 实现阶段再把这些行为映射成同步链和异或逻辑。
*/
module cdc_toggle_min (
    // 源时钟域
    input logic src_clk,
    input logic src_rst_n,
    input logic src_pulse,

    // 目标时钟域
    input logic dst_clk,
    input logic dst_rst_n,
    output logic dst_pulse
);
  logic src_tgl;
  logic tgl_ff0, tgl_ff1;

  // 源域事件不直接跨域，先转成可保持的 toggle 状态。
  always_ff @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) src_tgl <= 1'b0;
    else if (src_pulse) src_tgl <= ~src_tgl;
  end

  // 目标域用 2FF 同步链接收源域 toggle。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      tgl_ff0 <= 1'b0;
      tgl_ff1 <= 1'b0;
    end else begin
      tgl_ff0 <= src_tgl;
      tgl_ff1 <= tgl_ff0;
    end
  end

  // 当前拍是否看到一次 toggle 变化。
  always_ff @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) dst_pulse <= 1'b0;
    else dst_pulse <= tgl_ff0 ^ tgl_ff1;
  end
endmodule
```
