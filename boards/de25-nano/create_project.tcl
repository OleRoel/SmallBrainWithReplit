# Run with Quartus Prime Pro + Agilex 5 support from the repository root.
# Generate the Clash HDL before invoking this script.
package require ::quartus::project
set here [file dirname [file normalize [info script]]]
set root [file normalize [file join $here ../..]]

proc find_vhdl {directory} {
    set files [glob -nocomplain -directory $directory *.vhdl]
    foreach child [glob -nocomplain -types d -directory $directory *] {
        set files [concat $files [find_vhdl $child]]
    }
    return $files
}

foreach {project dir} {
    de25_nano            vhdl-de25-nano
    de25_nano_diagnostic vhdl-de25-nano-diagnostic
} {
    set sources [find_vhdl [file join $root $dir]]
    if {![llength $sources]} {
        error "Missing $dir; synthesize DE25Nano.hs and DE25NanoDiagnostic.hs first"
    }
    set top_found 0
    foreach path $sources {
        if {[file tail $path] eq "$project.vhdl"} { set top_found 1 }
    }
    if {!$top_found} { error "No top-level VHDL for $project in $dir" }

    cd $here
    project_new $project -overwrite
    source [file join $here pins.tcl]
    set_global_assignment -name TOP_LEVEL_ENTITY $project
    set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
    set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
    set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
    set_global_assignment -name SDC_FILE [file join $here timing.sdc]
    foreach path [lsort $sources] {
        if {[string match "*_types.vhdl" $path]} {
            set_global_assignment -name VHDL_FILE $path
        }
    }
    foreach path [lsort $sources] {
        if {![string match "*_types.vhdl" $path]} {
            set_global_assignment -name VHDL_FILE $path
        }
    }
    export_assignments
    project_close
    puts "Created $project with [llength $sources] VHDL sources"
}