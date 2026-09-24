# Terasic DE1-SoC manual v1.2.2 rev E, tables 3-5 through 3-8.
# Source and board checks are documented in README.md in this directory.
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSEMA5F31C6
set_global_assignment -name TOP_LEVEL_ENTITY de1_soc
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"

foreach {port pin} {
    CLOCK_50 AF14
    KEY0 AA14
    SW[0] AB12
    SW[1] AC12
    SW[2] AF9
    SW[3] AF10
    LEDR[0] V16
    LEDR[1] W16
    LEDR[2] V17
    LEDR[3] V18
    LEDR[4] W17
    LEDR[5] W19
    LEDR[6] Y19
    LEDR[7] W20
    LEDR[8] W21
    LEDR[9] Y21
} {
    set_location_assignment PIN_$pin -to $port
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $port
}