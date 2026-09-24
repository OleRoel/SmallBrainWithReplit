package require ::quartus::project
set here [file dirname [file normalize [info script]]]
set root [file normalize [file join $here ../..]]
cd $here
foreach variant {switch_led diagnostic} {
    set project labsland_$variant
    project_new $project -overwrite
    set_global_assignment -name FAMILY "Cyclone V"
    set_global_assignment -name DEVICE 5CSEMA5F31C6
    set_global_assignment -name TOP_LEVEL_ENTITY main
    set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
    set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
    set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
    set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
    set_global_assignment -name VHDL_FILE [file join $root deliverables labsland $project.vhdl]
    set_global_assignment -name SDC_FILE [file join $here timing.sdc]
    source [file join $here pins.tcl]
    export_assignments
    project_close
}