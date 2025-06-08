##############################################################################
## Genus Synthesis (Innovus Preload Script)
## By: oghadami@ucsd.edu Aug 2021
##############################################################################

##############################################################################
## Setup the design and configuration
##############################################################################
## Load design configuration
source [getenv DesignConfig]

## Timing units
set_db timing_time_unit       ${TimeUnit}
set_db timing_cap_unit        ${CapUnit}