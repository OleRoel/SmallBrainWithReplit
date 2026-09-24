# Run using quartus_sh -t boards/de1-soc/create_project.tcl from the repo root.
package require ::quartus::project
set here [file dirname [file normalize [info script]]]
if {![info exists project_name]} { set project_name de1_soc }
if {![info exists hdl_dir_name]} { set hdl_dir_name vhdl-de1-soc }
set hdl [file normalize [file join $here ../.. $hdl_dir_name]]

proc find_vhdl {directory} {
    set files [glob -nocomplain -directory $directory *.vhdl]
    foreach child [glob -nocomplain -types d -directory $directory *] {
        set files [concat $files [find_vhdl $child]]
    }
    return $files
}

set sources [find_vhdl $hdl]
set top_found 0
foreach path $sources {
    if {[file tail $path] eq "$project_name.vhdl"} { set top_found 1 }
}
if {!$top_found} {
    error "Generate HDL for $project_name into $hdl_dir_name first; see the board README."
}

cd $here
if {[file exists $project_name.qpf]} {
    # Refresh only this generated project's HDL list; retain local assignments.
    project_open $project_name
    remove_all_global_assignments -name VHDL_FILE
    remove_all_global_assignments -name SDC_FILE
} else {
    project_new $project_name -revision $project_name
}
source [file join $here pins.tcl]
set_global_assignment -name TOP_LEVEL_ENTITY $project_name
set_global_assignment -name SDC_FILE [file join $here timing.sdc]

# Include every generated dependency, with type packages listed first.
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
puts "Created/refreshed $here/$project_name.qpf"