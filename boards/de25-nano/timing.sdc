create_clock -name CLOCK1_50 -period 20.000 [get_ports {CLOCK1_50}]
derive_clock_uncertainty
# The physical buttons and switches are asynchronous to the 50 MHz clock.
# Only cut the input-port paths, not the synchronizers or trained datapath.
set_false_path -from [get_ports {KEY0 SW[*]}]
# The indicator LEDs have no external synchronous receiver.
set_false_path -to [get_ports {LEDR[*]}]