# Syntax/elaboration checks only. No physical pin assignments or .sof generation.
# Run from repository root: quartus_sh -t boards/labsland/check_sources.tcl
package require ::quartus::project
package require ::quartus::flow
set root [pwd]
set scratch [file join /tmp labsland-hdl-check-[pid]]
file mkdir $scratch
foreach variant {switch_led diagnostic} {
    set dir [file join $scratch $variant]
    file mkdir $dir
    cd $dir
    project_new check -overwrite
    set_global_assignment -name FAMILY "Cyclone V"
    set_global_assignment -name DEVICE 5CSEMA5F31C6
    set_global_assignment -name TOP_LEVEL_ENTITY main
    set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
    set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
    set_global_assignment -name VHDL_FILE [file join $root deliverables labsland labsland_$variant.vhdl]
    export_assignments
    if {[catch {execute_module -tool map -args "--analysis_and_elaboration"} problem]} {
        project_close
        error "$variant failed: $problem (reports in $dir)"
    }
    project_close
    puts "PASS: $variant analysis and elaboration; reports in $dir"
}
cd $root