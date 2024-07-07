# 定义衍生时钟
set_generated_clock [get_clocks clk_C] -source [get_clocks {clk_A clk_B}]

# 跨时钟域约束
set_clock_groups -asynchronous [get_clocks {clk_A clk_C}]
set_clock_groups -asynchronous [get_clocks {clk_B clk_C}]
set_clock_groups -asynchronous [get_clocks {clk_A clk_B}] -physically_exclusive
