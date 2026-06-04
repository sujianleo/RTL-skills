# async_fifo

```verilog
/*
1. 模块一句话职责
   - 用 Gray 指针和双向 2FF 同步实现最小异步 FIFO，在两个时钟域之间安全传递数据。

2. 接口语义
   - w_en / w_full  : 写侧请求与可写状态
   - r_en / r_empty : 读侧请求与可读状态
   - w_data / r_data: FIFO 输入输出数据
   - wclk / rclk    : 写时钟域与读时钟域
   - wrst_n / rrst_n: 各自时钟域下的低有效复位

3. 模块原理
   - 真正的数据存储在 mem 中，写侧和读侧各自维护本地二进制指针，用来访问本域地址空间。
   - 跨时钟域时不直接同步二进制指针，而是把它转换成 Gray 码；Gray 码相邻状态只有 1 bit 翻转，更适合跨域同步。
   - 每个时钟域只同步对端的 Gray 指针，再在本地用 next pointer 判断 full/empty，因此可以在不共享时钟的前提下完成流控。

4. 关键时序场景
   - reset: 读写指针和同步链全部清零，FIFO 为空
   - push-only: 写侧在 !w_full 时写 RAM 并推进写指针
   - pop-only: 读侧在 !r_empty 时读 RAM 并推进读指针
   - push/pop 并行: 两侧各自独立前进，依赖同步后的对端 Gray 指针更新状态
   - 边界情况: w_full 阻止越界写入，r_empty 阻止空读，指针 wrap 由扩展位负责区分圈数

5. 跨拍事实
   - 两边的本地指针必须跨拍保留，否则地址推进无法继续。
   - 供对端同步的 Gray 指针必须跨拍保留，否则无法完成跨域流控。
   - 读数据寄存器必须跨拍保留，否则 pop 后的数据无法稳定输出。

6. 状态 / 寄存器
   - mem : FIFO 存储阵列
   - wbin / rbin : 写读侧二进制指针
   - wgray / rgray : 提供给对端同步的 Gray 指针
   - rgray_wff0 / rgray_wff1 : 读指针 Gray 值同步到写域
   - wgray_rff0 / wgray_rff1 : 写指针 Gray 值同步到读域
   - r_data : 读侧输出寄存器

7. 每个寄存器的 set / clear / hold
   - wbin / wgray
     - load : 写侧真正接收一笔数据时前进
     - hold : 其他周期保持
   - rbin / rgray
     - load : 读侧真正弹出一笔数据时前进
     - hold : 其他周期保持
   - r_data
     - load : 读侧真正弹出一笔数据时装入当前地址内容
     - hold : 其他周期保持
   - 同步链寄存器
     - load : 每拍采样前一级值

8. 结构说明
   - 设计推导阶段只讨论“写指针前进”“读指针前进”“对端指针同步后判断满空”这些行为。
   - RTL 实现阶段再把这些行为映射成 push_fire、pop_fire、next Gray pointer 和同步链。
*/
module async_fifo_min #(
    parameter int AW = 2
) (
    // 写时钟域接口
    input  logic       wclk,
    input  logic       wrst_n,
    input  logic       w_en,
    input  logic [7:0] w_data,
    output logic       w_full,

    // 读时钟域接口
    input  logic       rclk,
    input  logic       rrst_n,
    input  logic       r_en,
    output logic [7:0] r_data,
    output logic       r_empty
);
  localparam int DEPTH = (1 << AW);

  logic [7:0] mem[0:DEPTH-1];
  logic [AW:0] wbin, rbin;
  logic [AW:0] wgray, rgray;
  logic [AW:0] rgray_wff0, rgray_wff1;
  logic [AW:0] wgray_rff0, wgray_rff1;
  logic        push_fire, pop_fire;
  logic [AW:0] wbin_next, wgray_next;
  logic [AW:0] rbin_next, rgray_next;

  function automatic logic [AW:0] bin2gray(input logic [AW:0] b);
    return (b >> 1) ^ b;
  endfunction

  // 事件线：写侧真正写入一笔 / 读侧真正弹出一笔。
  assign push_fire = w_en && !w_full;
  assign pop_fire  = r_en && !r_empty;

  // 写侧 RAM 写入和本地写指针推进。
  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin  <= '0;
      wgray <= '0;
    end else if (push_fire) begin
      mem[wbin[AW-1:0]] <= w_data;
      wbin  <= wbin + 1'b1;
      wgray <= bin2gray(wbin + 1'b1);
    end
  end

  // 读侧数据输出和本地读指针推进。
  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin   <= '0;
      rgray  <= '0;
      r_data <= '0;
    end else if (pop_fire) begin
      r_data <= mem[rbin[AW-1:0]];
      rbin   <= rbin + 1'b1;
      rgray  <= bin2gray(rbin + 1'b1);
    end
  end

  // 读指针 Gray 值同步到写域。
  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) {rgray_wff1, rgray_wff0} <= '0;
    else {rgray_wff1, rgray_wff0} <= {rgray_wff0, rgray};
  end

  // 写指针 Gray 值同步到读域。
  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) {wgray_rff1, wgray_rff0} <= '0;
    else {wgray_rff1, wgray_rff0} <= {wgray_rff0, wgray};
  end

  // 写侧满判断使用 next write pointer 与同步过来的读指针比较。
  always_comb begin
    wbin_next  = wbin + (push_fire ? 1'b1 : 1'b0);
    wgray_next = bin2gray(wbin_next);
    w_full     = (wgray_next == {~rgray_wff1[AW:AW-1], rgray_wff1[AW-2:0]});
  end

  // 读侧空判断使用 next read pointer 与同步过来的写指针比较。
  always_comb begin
    rbin_next  = rbin + (pop_fire ? 1'b1 : 1'b0);
    rgray_next = bin2gray(rbin_next);
    r_empty    = (rgray_next == wgray_rff1);
  end
endmodule
```
