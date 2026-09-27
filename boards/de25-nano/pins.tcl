# Terasic DE25-Nano manual rev B, tables 3-6 and 3-8 through 3-10.
# Verify the actual board revision and pin report before programming.
set_global_assignment -name FAMILY "Agilex 5"
set_global_assignment -name DEVICE A5EB013BB23BE4SCS
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"

foreach {port pin standard} {
    CLOCK1_50 V16  "3.3-V LVCMOS"
    KEY0      C8   "3.3-V LVCMOS"
    SW[0]     DK24 "1.1 V"
    SW[1]     DD24 "1.1 V"
    SW[2]     DD27 "1.1 V"
    SW[3]     DF27 "1.1 V"
    LEDR[0]   DF35 "1.1 V"
    LEDR[1]   DJ32 "1.1 V"
    LEDR[2]   DN22 "1.1 V"
    LEDR[3]   DP23 "1.1 V"
    LEDR[4]   DN25 "1.1 V"
    LEDR[5]   DP25 "1.1 V"
    LEDR[6]   DJ27 "1.1 V"
    LEDR[7]   DP30 "1.1 V"
} {
    set_location_assignment PIN_$pin -to $port
    set_instance_assignment -name IO_STANDARD $standard -to $port
}