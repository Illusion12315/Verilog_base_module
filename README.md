# Verilog_base_module
手敲的Verilog代码库，里面有FIFO，UART等常用模块。
用于学习和记录。

```
module_base
├─ 📁AD7606
│  ├─ 📄ad7606_ctrl_logic.v
│  └─ 📄ad7606_spi_logic.v
├─ 📁AD9516
│  ├─ 📄ad9516_spi_warpper.v
│  ├─ 📄single_pluse.v
│  ├─ 📄spi_ctrl.v
│  └─ 📄spi_logic.v
├─ 📁Artibiter
│  └─ 📁Round Robin
│     ├─ 📁TB
│     │  └─ 📄round_robin_tb.v
│     └─ 📄round_robin.v
├─ 📁AXI
│  ├─ 📁axi_lite
│  │  ├─ 📁xgui
│  │  │  └─ 📄s_axi_lite_myself_v1_0.tcl
│  │  ├─ 📄component.xml
│  │  └─ 📄s_axi_lite_myself.v
│  ├─ 📁m_axi
│  │  └─ 📄m_axi_master_myself.v
│  └─ 📄axi_slave.v
├─ 📁DDR_to_FIFO
│  ├─ 📄ddr2fifo.v
│  ├─ 📄ddr3_4g_4ch_fsm.v
│  └─ 📄m_axi2ram_rd_and_wr.v
├─ 📁divide
│  └─ 📄divide.v
├─ 📁DS1302
│  ├─ 📁constrs_1
│  │  └─ 📁new
│  │     └─ 📄ds1302.xdc
│  ├─ 📁sim_1
│  │  └─ 📁new
│  │     ├─ 📄top_sim.v
│  │     └─ 📄wr.v
│  └─ 📁sources_1
│     └─ 📁new
│        ├─ 📄divide.v
│        ├─ 📄ds1302_control.v
│        ├─ 📄ds1302_top.v
│        ├─ 📄rst.v
│        ├─ 📄single_pluse.v
│        ├─ 📄spi_rd.v
│        └─ 📄spi_wr.v
├─ 📁FFT
│  ├─ 📁butterfly_module
│  │  ├─ 📄N16_butterfly_base_n4.v
│  │  ├─ 📄N4_butterfly_base_n4.v
│  │  └─ 📄standard_butterfly_base_n4.v
│  ├─ 📁FFT_TOP
│  │  └─ 📄N16_butterfly_base_n4_top.v
│  ├─ 📁matlab_sim
│  │  ├─ 📄butterfly_base_n4.m
│  │  ├─ 📄FFT_B4_N64.m
│  │  ├─ 📄fft_n64_base_n4.m
│  │  ├─ 📄my_fft.m
│  │  ├─ 📄rader.m
│  │  ├─ 📄test_basen4_fft.m
│  │  └─ 📄top.m
│  ├─ 📁TB
│  │  ├─ 📄N16_butterfly_base_n4_tb.v
│  │  └─ 📄N16_FFT_TOP_tb.v
│  ├─ 📄butterfly_n16_base_n4.v
│  ├─ 📄butterfly_n4_base_n4.v
│  ├─ 📄complex_multiplier.v
│  ├─ 📄fft_n4_base_n2.v
│  ├─ 📄fft_n4_base_n4.v
│  ├─ 📄fft_n64_base_n4.v
│  ├─ 📄FFT_Photo.drawio
│  ├─ 📄FFT_Photo.png
│  ├─ 📄my_fft_n2.v
│  └─ 📄wave.txt
├─ 📁FIFO
│  ├─ 📁Async_fifo
│  │  ├─ 📁tb
│  │  │  └─ 📄async_fifo_tb.v
│  │  ├─ 📄async_fifo.v
│  │  ├─ 📄async_fifo_rd_ctrl.v
│  │  └─ 📄async_fifo_wr_ctrl.v
│  ├─ 📁first in first out async fifo
│  │  ├─ 📁tb
│  │  │  └─ 📄first_in_first_out_async_fifo_tb.v
│  │  ├─ 📄async_fifo_rd_ctrl.v
│  │  ├─ 📄async_fifo_wr_ctrl.v
│  │  ├─ 📄beat_it_twice.v
│  │  ├─ 📄bin2gray.v
│  │  ├─ 📄fifo_defines.v
│  │  ├─ 📄first_word_fall_through.v
│  │  ├─ 📄gray2bin.v
│  │  ├─ 📄standard_fifo.v
│  │  └─ 📄wave.txt
│  ├─ 📁new_fifo
│  │  ├─ 📁async_fifo
│  │  │  ├─ 📄async_fifo.v
│  │  │  ├─ 📄beat_it_twice.v
│  │  │  └─ 📄simple_double_port_ram.v
│  │  └─ 📁sync_fifo
│  │     ├─ 📄simple_double_port_ram.v
│  │     └─ 📄sync_fifo.v
│  └─ 📄simple_double_port_ram.v
├─ 📁FRE
│  └─ 📄freq_measure.v
├─ 📁hdmi
│  └─ 📄hdmi_driver.v
├─ 📁i2c
│  ├─ 📁tb
│  │  └─ 📄i2c_interface.v
│  └─ 📄i2c_logic.v
├─ 📁project
│  ├─ 📁Acquisition and storage system
│  │  ├─ 📄Acquisition and storage system.drawio
│  │  └─ 📄Acquisition and storage system.png
│  └─ 📁Communication system
│     ├─ 📄Communication system board.drawio
│     └─ 📄Communication system board.png
├─ 📁SDR_sdram
│  ├─ 📁tb
│  │  ├─ 📄auto_refresh_tb.v
│  │  ├─ 📄init_tb.v
│  │  ├─ 📄sdram_ctrl_tb.v
│  │  └─ 📄sdram_model_plus.v
│  ├─ 📄sdram2fifo.v
│  ├─ 📄sdram_arbit.v
│  ├─ 📄sdram_auto_refresh.v
│  ├─ 📄sdram_ctrl.v
│  ├─ 📄sdram_defines.v
│  ├─ 📄sdram_init.v
│  ├─ 📄sdram_read.v
│  └─ 📄sdram_write.v
├─ 📁speed_test
│  └─ 📄test_speed.v
├─ 📁start_to_reset
│  ├─ 📄rst_and_signal_sync.v
│  ├─ 📄single_pluse.v
│  └─ 📄start_rst_module.v
├─ 📁uart_warpper_v1
│  ├─ 📄pps_uart_warpper.v
│  ├─ 📄rx_logic.v
│  ├─ 📄tx_logic.v
│  ├─ 📄uart_warpper.v
│  ├─ 📄uart_warpper_without_head_and_tail.v
│  └─ 📄uart_warpper_with_head_and_tail.v
└─ 📄README.md
```