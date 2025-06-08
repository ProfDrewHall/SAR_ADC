##############################################################################
## Genus Synthesis
## By: oghadami@ucsd.edu Aug 2021
##############################################################################

##############################################################################
## Preset global variables and attributes
##############################################################################
## Diectories and server configurations
set _OUTPUTS_PATH  [getenv _OUTPUTS_PATH]
set _REPORTS_PATH  [getenv _REPORTS_PATH]
set _LOG_PATH      [getenv _LOG_PATH]

## Set MODUS_WORKDIR <MODUS work directory>
set_db init_lib_search_path  [getenv TechPath] 
set_db script_search_path    [getenv ConfigPath]
set_db init_hdl_search_path  [getenv HDLPath]

## Super-threading
set_db max_cpus_per_server    4

## Information at the output (REC=6, MAX=9)
set_db information_level      1

## Default undriven/unconnected setting is 'none'.  
set_db hdl_unconnected_value  0

## Supress Joules Power Scalling Info
set_db joules_silent true

## Suppress library/physical warnings
suppress_messages {LBR-9 LBR-40 LBR-101 LBR-518 LBR-705}
suppress_messages {PHYS-12 PHYS-15 PHYS-20 PHYS-129 PHYS-232 PHYS-279}

##############################################################################
## Setup the design and configuration
##############################################################################
## Load design configuration
source [getenv DesignConfig]
set_db init_power_nets         ${PowerNet}
set_db init_ground_nets        ${GroundNet}
#set_db init_design_uniquify    true

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
read_physical -lef                  [getenv TLEFFile]
read_physical -add_lef              [getenv MLEFFile]
source [getenv LibConfig]

## Routing Config
set_db design_top_routing_layer     ${TopRoute}
set_db design_bottom_routing_layer  ${BotRoute}
set_db design_process_node          ${TargetProc}

##############################################################################
## Load Design
##############################################################################
read_hdl  $HDL
elaborate $DesignName
puts "Runtime & Memory after 'read_hdl'"
time_info Elaboration

## Initialize Design
init_design
puts "The number of exceptions is [llength [vfind ${DesignName} -exception *]]"

## Check the design
check_design -unresolved
check_design -all        > $_REPORTS_PATH/InputData/${DesignName}_ValidationSummary.rpt
report        ple        > $_REPORTS_PATH/InputData/${DesignName}_PLE.rpt
report_timing -lint      > $_REPORTS_PATH/InputData/${DesignName}_TimingConstraint.rpt

##############################################################################
## Load Floorplan
##############################################################################
read_def   $DEF
check_floorplan -detailed -out_file $_REPORTS_PATH/InputData/${DesignName}_FP.rpt

##############################################################################
## iSpatial Setup
##############################################################################
## Efort levels
set_db syn_generic_effort  high
set_db syn_map_effort      high
set_db syn_opt_effort      extreme

## Optimizing every path 
set_db tns_opto                true

## Setup the routing
set_db design_flow_effort           extreme

## Ensures proper and consistent library handling between Genus and Innovus
#set_db library_setup_ispatial true

## Optional power optimization settings (defaults to none)
#set_db leakage_power_effort low
#set_db dynamic_power_effort low
    
## Optionally, you can turn off useful skew for iSpatial (not recommended in general)
#set_db opt_spatial_useful_skew false
    
## Background Innovus config
#set_db invs_preload_script invs_preload.tcl
#set_db invs_temp_dir       ${_OUTPUTS_PATH}/iSpatial_INV_TMP

###############################################################################
## Cost Group Setting (clock-clock, clock-output, input-clock, input-output) ##
###############################################################################
## Uncomment to remove already existing costgroups before creating new ones.
#delete_obj [vfind /designs/* -cost_group *]
    
## Defining cost groups, 
##     I2C -> Input to Register;
##     C2O -> Register to output;
##     C2C -> register to register;
##     I2O -> Input to output paths
foreach view [get_db analysis_views -if {.is_setup == true}] {
    if {[llength [all_registers]] > 0} { 
        define_cost_group -name I2C -design ${DesignName}
        path_group -from [all_inputs]    -to [all_registers] -group I2C -name I2C -view $view
        define_cost_group -name C2O -design ${DesignName}
        path_group -from [all_registers] -to [all_outputs]   -group C2O -name C2O -view $view
        define_cost_group -name C2C -design ${DesignName}
        path_group -from [all_registers] -to [all_registers] -group C2C -name C2C -view $view
        }
        define_cost_group -name I2O -design ${DesignName}
        path_group -from [all_inputs]    -to [all_outputs]   -group I2O -name I2O -view $view
    }
    
##############################################################################
## Synthesizing to generic 
##############################################################################
syn_generic -physical
puts "Runtime & Memory after 'syn_generic'"
time_info GENERIC

# Generate a summary for the current stage of synthesis
write_reports  -directory $_REPORTS_PATH/generic -tag generic
write_db       $_OUTPUTS_PATH/${DesignName}_generic.db

# Report timing with cost group
foreach cg [get_db cost_groups *] {
    report_timing -group [list $cg] >> $_REPORTS_PATH/generic/${DesignName}_[vbasename $cg].rpt
    }

##############################################################################
## Synthesizing to gates
##############################################################################
syn_map -physical
puts "Runtime & Memory after 'syn_map'"
time_info MAPPED

# Generate a summary for the current stage of synthesis
write_reports  -directory $_REPORTS_PATH/mapped -tag mapped
write_db       $_OUTPUTS_PATH/${DesignName}_mapped.db

# Report timing with cost group
foreach cg [get_db cost_groups *] {
    report_timing -group [list $cg] > $_REPORTS_PATH/mapped/${DesignName}_[vbasename $cg]_.rpt
    }

##############################################################################
## Optimize Netlist
##############################################################################
syn_opt -spatial 
puts "Runtime & Memory after 'syn_opt'"
time_info iSpatial

# Generate a summary for the current stage of synthesis
write_reports  -directory $_REPORTS_PATH/optimized -tag optimized
write_db       $_OUTPUTS_PATH/${DesignName}_optimized.db

# Report timing with cost group
foreach cg [get_db cost_groups *] {
    report_timing -group [list $cg] > $_REPORTS_PATH/optimized/${DesignName}_[vbasename $cg]_.rpt
    }

##############################################################################
## Write reports
##############################################################################
report_messages > $_REPORTS_PATH/${DesignName}_messages.rpt
report_gates    > $_REPORTS_PATH/${DesignName}_gates.rpt
report_power    > $_REPORTS_PATH/${DesignName}_power.rpt

##############################################################################
## Write design - handoff to Innovus
##############################################################################
write_design -innovus -base_name [getenv _OUTPUTS_PATH]/PSynthesis/${DesignName}
file delete -force [getenv DesignPath]/PSynthesis
file copy   -force [getenv _OUTPUTS_PATH]/PSynthesis [getenv DesignPath]/PSynthesis

##############################################################################
### write_do_lec
##############################################################################
## TODO:
## Formal verification steps.
#write_do_lec -golden_design fv_map -revised_design ${_OUTPUTS_PATH}/${DesignName}.v.gz -no_exit -logfile  ${_LOG_PATH}/fv_map_2_final.lec.log > ${_OUTPUTS_PATH}/fv_map_2_final.lec.do

puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "PSynthesis Finished ........"
puts "============================"

file copy [get_db stdout_log ] ${_LOG_PATH}/.

##quit
exit
