create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

# Mechanical inputs have no timing relationship to CLOCK_50. Only cut the
# port-to-first-register paths; do not cut register-to-register synchronizers
# or the neural-network datapath.
set_false_path -from [get_ports {KEY0 SW[*]}]

# LEDs are indicators, not a synchronous interface to another device.
set_false_path -to [get_ports {LEDR[*]}]