create_clock -name G_CLOCK_50 -period 20.000 [get_ports {G_CLOCK_50}]
derive_clock_uncertainty
# Remote controls are asynchronous; preserve timing within synchronizers.
set_false_path -from [get_ports {V_SW[*] V_BT[*]}]
# LEDs are asynchronous visual indicators.
set_false_path -to [get_ports {G_LEDR[*]}]