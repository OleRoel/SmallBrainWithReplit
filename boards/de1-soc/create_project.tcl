# Run using quartus_sh -t boards/de1-soc/create_project.tcl from the repo root.
package require ::quartus::project
set here [file dirname [file normalize [info script]]]
set hdl [file normalize [file join $here ../../vhdl-de1-soc]]

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
    if {[file tail $path] eq "de1_soc.vhdl"} { set top_found 1 }
}
if {!$top_found} {
    error "Generate HDL first: cabal exec -- sh -c './bin/clash --vhdl DE1SoC.hs -fclash-hdldir vhdl-de1-soc'"
}

cd $here
if {[file exists de1_soc.qpf]} {
    # Refresh only this generated project's HDL list; retain local assignments.
    project_open de1_soc
    remove_all_global_assignments -name VHDL_FILE
    remove_all_global_assignments -name SDC_FILE
} else {
    project_new de1_soc -revision de1_soc
}
source [file join $here pins.tcl]
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
puts "Created/refreshed $here/de1_soc.qpf"