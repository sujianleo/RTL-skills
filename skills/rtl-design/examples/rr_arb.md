# rr_arb

## 本例 5 要素

| Core | 本例体现 |
|---|---|
| Fact | pointer 记住上次服务位置或下一次搜索起点。 |
| Event | `grant_fire` 表示本次授权被接受，触发 pointer 旋转。 |
| Priority | reset 初始化 pointer；已授权但未完成时保持；完成后再 rotate。 |
| Boundary | 多 requester 同时请求、无请求、最后一位 wrap 到 0 都要稳定处理。 |
| Contract | grant 按 round-robin 公平策略产生，是否保持到 accept 由接口契约决定。 |

```verilog
/*
1. 模块一句话职责
   - 在 N 个请求之间执行 round-robin 仲裁，每次授权后把起始优先级旋转到下一个 requester。

2. 接口语义
   - req : N 路请求向量，1 表示该路请求仲裁
   - gnt : N 路 one-hot 授权向量
   - ptr : 内部轮询起点，决定本拍从哪一路开始找优先请求

3. 模块原理
   - round-robin 的核心不是固定优先级，而是每次仲裁都从“上次获胜者的下一位”开始重新找 winner。
   - 这里通过 rotate-priority-rotate 结构实现：先把 req 按 ptr 旋到统一视角，再做最低位优先选择，最后再旋回原坐标。
   - grant 保持为组合逻辑，ptr 作为唯一时序状态在授权成功后更新，因此结构紧凑但默认不处理多拍 hold-grant 语义。

4. 关键时序场景
   - 无请求: gnt 全 0，ptr 保持
   - 单请求: 该请求直接获胜
   - 多请求: 从 ptr 开始循环查找，最先命中的请求获胜
   - 授权完成: 本拍若有 gnt，则下一拍 ptr 移到获胜者的下一位
   - 环回边界: 若最后一位获胜，ptr 回到 0

5. 跨拍事实
   - 下一次搜索从哪里开始必须跨拍保留，否则 round-robin 公平性无法延续。

6. 状态 / 寄存器
   - ptr : 记录下一次 round-robin 搜索的起始位置

7. 每个寄存器的 set / clear / hold
   - ptr
     - load : 本拍存在授权时，更新为当前 winner 的下一位
     - clear: rst_n 拉低时清 0
     - hold : 无授权时保持当前起点

8. 结构说明
   - 设计推导阶段只讨论“从当前起点开始找下一个获胜者”这个行为。
   - RTL 实现阶段再把它展开成 rotate、最低位优先选择和 ptr 更新。
*/
module rr_arb #(
    parameter int N = 4
) (
    // 时钟与复位
    input  logic         clk,
    input  logic         rst_n,

    // 仲裁请求与授权接口
    input  logic [N-1:0] req,
    output logic [N-1:0] gnt
);
  localparam int PW = (N <= 1) ? 1 : $clog2(N);
  logic [PW-1:0] ptr;
  logic [N-1:0] req_rot, gnt_rot;
  logic [PW-1:0] ptr_next;

  function automatic logic [N-1:0] rotl(input logic [N-1:0] v, input int sh);
    logic [2*N-1:0] vv;
    int s;
    begin
      s  = (N <= 1) ? 0 : (sh % N);
      vv = {v, v};
      return vv[s+:N];
    end
  endfunction

  function automatic logic [N-1:0] rotr(input logic [N-1:0] v, input int sh);
    int s;
    begin
      s = (N <= 1) ? 0 : (sh % N);
      return rotl(v, (N - s) % N);
    end
  endfunction

  function automatic logic [N-1:0] lsb_onehot(input logic [N-1:0] v);
    return v & (~v + 1'b1);
  endfunction

  // 组合仲裁路径：旋转到当前起点，选最低位优先请求，再旋回原坐标。
  always_comb begin
    req_rot = rotl(req, ptr);
    gnt_rot = lsb_onehot(req_rot);
    gnt     = rotr(gnt_rot, ptr);
  end

  // 下一次 round-robin 搜索起点取当前 winner 的下一位。
  always_comb begin
    ptr_next = ptr;
    for (int i = 0; i < N; i++) begin
      if (gnt[i]) ptr_next = (i == N - 1) ? '0 : logic'(i + 1);
    end
  end

  // ptr 是唯一时序状态，记录下一拍从哪里开始搜索。
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ptr <= '0;
    else if (|gnt) ptr <= ptr_next;
  end
endmodule
```
