set sdc_version 1.7
set_units -capacitance $CapUnit
set_units -time        $TimeUnit

########################################################################################
## Design definition
########################################################################################
set InputList      [remove_from_collection [all_inputs] [list $ClockPort $ResetPort] ]
set OutputList     [all_outputs]

#current_design     $DesignName

########################################################################################
## Clock Constraints
########################################################################################
create_clock -name Clock -period $ClockPeriod [get_ports $ClockPort]

set_clock_uncertainty -setup $ClockSetup [get_clocks Clock]
set_clock_uncertainty -hold  $ClockHold  [get_clocks Clock]
set_clock_transition  $ClockTransit      [get_clocks Clock]
set_clock_latency     $ClockLatency      [get_clocks Clock]

########################################################################################
## I/O Ports Constraints
########################################################################################
# The max input delay set the delay for setup analysis. (GENUS Command Reference)
# Inputs are steady so there is no need to check for hold times
set_input_delay   -max $InputSetup  -clock [get_clocks Clock]  $InputList

# Outputs hold time is the time that outputs must be validated
set_output_delay  -min $OutputHold  -clock [get_clocks Clock]  $OutputList
set_output_delay  -max $OutputSetup -clock [get_clocks Clock]  $OutputList
set_max_transition     $OutputTransit                          $OutputList

# Equivalent input driving cell
set_driving_cell -lib_cell $InputDriver $InputList
set_driving_cell -lib_cell $InputDriver $ClockPort
set_driving_cell -lib_cell $InputDriver $ResetPort

# Equivalent output load
set_load         -pin_load $OutputLoad  $OutputList

########################################################################################
## Set Ideal Network for Reset 
########################################################################################
#set_ideal_network  -no_propagate  [get_ports $ResetPort]

########################################################################################
## Preserve
########################################################################################
set_dont_touch         true          [list $Preserved_Modules]
set_ideal_network      -no_propagate [list $Preserved_Ports]
set_dont_touch_network -no_propagate [get_ports [list $Preserved_Ports]]
