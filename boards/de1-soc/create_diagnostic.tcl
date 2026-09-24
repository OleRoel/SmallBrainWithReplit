# Keep the diagnostic image separate from the trained-network project.
set project_name de1_soc_diagnostic
set hdl_dir_name vhdl-de1-soc-diagnostic
source [file join [file dirname [info script]] create_project.tcl]