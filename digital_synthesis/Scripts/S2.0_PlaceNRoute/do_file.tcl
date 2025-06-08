##############################################################################
## Innovus Placement Procedure
## By: oghadami@ucsd.edu Aug 2021
##############################################################################

##############################################################################
## Preparing the result folders
##############################################################################
## Setup output folders and structure
set _OUTPUTS_PATH   [getenv _OUTPUTS_PATH]
set _REPORTS_PATH   [getenv _REPORTS_PATH]
set _LOG_PATH       [getenv _LOG_PATH]

set PlacementMode   1

## Suppress warnings
set_message -id TECHLIB-302 -suppress
set_message -id IMPOPT-3564 -suppress
## Suppressing ANTENNAGATEAREA missing warning
## INNOVUS can't use the antenna block of the library because of missing data.
set_message -id IMPOAX-773  -suppress
## BHDHVT issues
set_message -id TECHLIB-1230 -suppress
set_message -id TECHLIB-1154 -suppress
set_message -id IMPTS-417    -suppress

## M1 to silicon surface via errors suppression
set_message -id IMPOAX-1637  -suppress
set_message -id IMPOAX-348   -suppress
## Removing dcore/ccore no standard cell associated 
set_message -id IMPFP-3961   -suppress

## Removing physical-only cells warning
set_message -id IMPDF-200    -suppress

## INNOVUS open access settings
set_db oa_new_lib_compress_level 0


##############################################################################
## Setup the design and configuration
##############################################################################
## Load design configuration
source [getenv DesignConfig]
set_db init_power_nets         ${PowerNet}
set_db init_ground_nets        ${GroundNet}
set_db init_design_uniquify    true

## Timing units
set_db timing_time_unit        1${TimeUnit}
set_db timing_cap_unit         1${CapUnit}

##############################################################################
## Timing Setup
##############################################################################
read_mmmc   $MMMC

##############################################################################
## Physical Setup
##############################################################################
## Technology Data
read_physical -lefs                 [getenv TLEFFile] [getenv MLEFFile]
source [getenv LibConfig]

## Routing Config
set_db design_top_routing_layer     ${TopRoute}
set_db design_bottom_routing_layer  ${BotRoute}
set_db design_process_node          ${TargetProc}

##############################################################################
## Load Design
##############################################################################
## Read Data from GENUS
read_netlist [getenv DesignPath]/Synthesis/${DesignName}.v

## Initialize Design
init_design
#puts "The number of exceptions is [llength [vfind ${DesignName} -exception *]]"

## Check the design
check_timing -verbose > $_REPORTS_PATH/InputData/${DesignName}_Timing.rpt

##############################################################################
## Load Floorplan
##############################################################################
#read_def   [getenv DesignPath]/Synthesis/${DesignName}.def
#check_floorplan -out_file $_REPORTS_PATH/InputData/${DesignName}_FP.rpt

##############################################################################
## Clock Tree Synthesis Setup
##############################################################################
## Report/Optimization switch at different stages of the design
## Normally should be 0-1-1, but it can differ based on the design
set preCTS_OPT      0
set postCTS_OPT     1
set postRoute_OPT   1

set_db opt_effort          high
set_db opt_area_recovery   true
set_db opt_useful_skew     false

## Setup the routing
set_db design_flow_effort           extreme

## Ignore not defined scan chain
set_db place_global_ignore_scan false

##############################################################################
## Floorplan
##############################################################################
if { $PlacementMode == 1 } {
    ## Creat the placement boundary
    create_floorplan -core_size $Width $Height $Offset $Offset $Offset $Offset
    
    ## Place the IO's
    read_io_file      ${IO}
}

# Check the utilization
check_floorplan -report_density -out_file $_REPORTS_PATH/InputData/${DesignName}_fp.rpt

##############################################################################
## Powerplan
##############################################################################
proc CreatPowerLines {VDD_Pin VSS_Pin} {
	delete_global_net_connections
	connect_global_net VDD -type pg_pin -pin_base_name $VDD_Pin -verbose -all
	connect_global_net VDD -type tie_hi 
	connect_global_net VSS -type pg_pin -pin_base_name $VSS_Pin -verbose -all
	connect_global_net VSS -type tie_lo
	commit_global_net_rules
}

CreatPowerLines   ${PowerNet}   ${GroundNet}

## Creat power delivery network
if { $PlacementMode == 1 } {
    set_db add_stripes_stacked_via_top_layer    ${TopMetal}
    set_db add_stripes_stacked_via_bottom_layer ${BotMetal}

    add_rings  \
        -nets                [list ${PowerNet} ${GroundNet}]      \
        -layer               {bottom M6 top M6 right M5 left M5}  \
        -type                core_rings                           \
        -jog_distance        0.4                                  \
        -threshold           0.4                                  \
        -width               1                                    \
        -spacing             1                                    \
        -offset              1

    add_stripes  \
        -nets                [list ${PowerNet} ${GroundNet}]      \
        -layer               M5                                   \
        -direction           vertical                             \
        -start_from          left                                 \
        -over_power_domain   0                                    \
        -width               0.5                                  \
        -spacing             6                                    \
        -start_offset        3                                    \
        -set_to_set_distance 12

    route_special  \
        -nets                [list ${PowerNet} ${GroundNet}]
}

##############################################################################
## Floorplan database generation
##############################################################################
if { $PlacementMode == 1 } {
    ## Generate hand over data for GENUS
    write_def -floorplan -no_std_cells -io_row ${_OUTPUTS_PATH}/${DesignName}.def
    file delete -force $DEF
    file copy   -force ${_OUTPUTS_PATH}/${DesignName}.def $DEF
   
    # Quit
    exit
}

##############################################################################
## Placement
##############################################################################
## Make the placement based on the timing.
place_opt_design 

## Add tie cells
set_db add_tieoffs_cells               [list $TIEHI $TIELO]
add_tieoffs

## Regenerate power 
CreatPowerLines ${PowerNet} ${GroundNet}

## Density check (optional)
check_place

## PreCTS timing report/optimization
if { $preCTS_OPT == 0 } {
    puts "==============================="
    puts "PreCTS timing report"
    time_design -pre_cts              -report_dir ${_REPORTS_PATH}/${DesignName}_preCTS
} else {
    puts "==============================="
    puts "PreCTS timing optimization"
    set_db opt_add_insts              true
    set_db opt_new_inst_prefix        PRECTS
    opt_design  -pre_cts              -report_dir ${_REPORTS_PATH}/${DesignName}_preCTS_opt
    opt_design  -pre_cts -drv         -report_dir ${_REPORTS_PATH}/${DesignName}_preCTS_drv_opt
}

##############################################################################
## CTS
##############################################################################
## Configure cells
set_db cts_buffer_cells                ${CLKBufs}
set_db cts_inverter_cells              ${CLKInvs}

## Clock Tree Spec file is not required but generated for verification
create_clock_tree_spec -out_file ${_OUTPUTS_PATH}/$DesignName.ctstch 

## CTS Synthesis 
ccopt_design         -report_dir ${_REPORTS_PATH}/${DesignName}_cts 
report_clock_trees   -summary -out_file   ${_REPORTS_PATH}/${DesignName}_cts/${DesignName}_clock_trees.rpt
report_skew_groups   -summary -out_file   ${_REPORTS_PATH}/${DesignName}_cts/${DesignName}_clock_skew_groups.rpt

## PostCTS timing report/optimization
if { $postCTS_OPT == 0 } {
    puts "==============================="
    puts "PostCTS timing report"
    time_design -post_cts             -report_dir ${_REPORTS_PATH}/${DesignName}_postCTS
    time_design -post_cts -hold       -report_dir ${_REPORTS_PATH}/${DesignName}_postCTS_hold
} else {
    puts "==============================="
    puts "PostCTS timing optimization"

    # PostCTS Timing optimization
    set_interactive_constraint_modes [all_constraint_modes -active]
    reset_clock_tree_latency [all_clocks]
    set_propagated_clock [all_clocks]
    set_interactive_constraint_modes []

    set_db opt_add_insts              true  
    set_db opt_new_inst_prefix        POSCTS
    opt_design  -post_cts             -report_dir ${_REPORTS_PATH}/${DesignName}_postCTS_opt
    opt_design  -post_cts -hold       -report_dir ${_REPORTS_PATH}/${DesignName}_postCTS_hold_opt
}

##############################################################################
## Routing
##############################################################################
set_db route_design_with_timing_driven                    true
set_db route_design_with_si_driven                        true   
set_db route_design_detail_fix_antenna                    true
set_db route_design_with_via_in_pin                       true
set_db route_design_concurrent_minimize_via_count_effort  High
set_db route_design_antenna_diode_insertion               true
set_db route_design_delete_antenna_reroute                true
set_db route_design_route_clock_nets_first                true
set_db route_design_antenna_cell_name                     ${ANTDiodes}

route_design -global_detail

## Postroute timing analysis
set_db delaycal_enable_si              true
set_db timing_analysis_type            ocv 
set_db timing_analysis_cppr            both

## PostRoute timing report/optimization
if { $postRoute_OPT == 0 } {
    puts "==============================="
    puts "PostRoute timing report"
    time_design -post_route           -report_dir ${_REPORTS_PATH}/${DesignName}_postRoute
    time_design -post_route -hold     -report_dir ${_REPORTS_PATH}/${DesignName}_postRoute_hold
} else {
    puts "==============================="
    puts "PostRoute timing optimization"
    set_db opt_add_insts              true 
    set_db opt_new_inst_prefix        POSROT
    opt_design  -post_route           -report_dir  ${_REPORTS_PATH}/${DesignName}_postRoute_opt
    opt_design  -post_route -drv      -report_dir  ${_REPORTS_PATH}/${DesignName}_postRoute_drv_opt
    opt_design  -post_route -hold     -report_dir  ${_REPORTS_PATH}/${DesignName}_postRoute_hold_opt
}

## Adding fillers and caps
add_fillers -base_cells ${DCAPs}   -prefix FILLCAP
add_fillers -base_cells ${FILLers} -prefix FILLDOM

## Final power planning
CreatPowerLines ${PowerNet} ${GroundNet}

##############################################################################
## VERIFY & OUTPUT
##############################################################################
fix_via -min_cut
fix_via -min_step
fix_via -short
add_notch_fill

delete_drc_markers

time_design -post_route       -report_dir  ${_REPORTS_PATH}/${DesignName}_timing
time_design -post_route -hold -report_dir  ${_REPORTS_PATH}/${DesignName}_timing_hold
check_drc                     -out_file    ${_REPORTS_PATH}/${DesignName}_drc.rpt
check_connectivity -type all  -out_file    ${_REPORTS_PATH}/${DesignName}_connectivity.rpt
report_summary     -no_html   -out_file    ${_REPORTS_PATH}/${DesignName}_summaryReport.rpt
report_gate_count             -out_file    ${_REPORTS_PATH}/${DesignName}_gateCount.rpt

##############################################################################
## Output generation
##############################################################################
## Layout generation
set_db write_stream_virtual_connection false
set_db write_stream_snap_to_mfg        true
set_db write_stream_text_size          0.1

write_stream ${_OUTPUTS_PATH}/${DesignName}.gds    \
    -mode            ALL                           \
    -map_file        [getenv MAPFile]              \
    -lib_name        ${DesignName}                 \
    -structure_name  ${DesignName} 

file delete -force [getenv GDSPath]/${DesignName}.gds
file copy   -force ${_OUTPUTS_PATH}/${DesignName}.gds [getenv GDSPath]/${DesignName}.gds

## Verilog generation
## Insert Power/Ground in the netlist and on the top-level module needs
## phys, include_pg, export_top_pg_nets
## For simulation fillers are exluded from the netlist
## Leaf-cell exlusion stops the verilog code generation for stdcells
## Flat option makes sure that your hierarchical desgin get flatted
write_netlist ${_OUTPUTS_PATH}/${DesignName}_SYN.v \
    -flat                                          \
    -phys                                          \
    -include_pg                                    \
    -export_top_pg_nets                            \
    -exclude_insts_of_cells ${FILLers}             \
    -exclude_leaf_cells                  

file delete -force [getenv HDLPath]/${DesignName}_SYN.v
file copy   -force ${_OUTPUTS_PATH}/${DesignName}_SYN.v [getenv HDLPath]/${DesignName}_Sim.v

## Quit
exit

