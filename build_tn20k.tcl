set_device GW2AR-LV18QN88C8/I7 -name GW2AR-18C

add_file boards/tang-nano-20k.cst
add_file boards/tang-nano-20k.sdc

add_file src/rtl/top.v
add_file src/rtl/uart/uart_tx.v
add_file src/rtl/uart/uart_rx.v

set_option -synthesis_tool gowinsynthesis
set_option -output_base_name tango
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008
set_option -top_module top
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -rw_check_on_ram 0
set_option -user_code 00000001
set_option -multi_boot 1
set_option -mspi_jump 0

#run syn
run all