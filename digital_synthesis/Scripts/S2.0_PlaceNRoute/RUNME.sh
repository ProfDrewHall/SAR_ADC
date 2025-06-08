#!/bin/bash

# Configuring the design setup in the current shell
source ../S0.0_Setup/Setup.sh

# Creating run directories
export  DATE=$(date '+%Y%m%d_%H%M')
export  _OUTPUTS_PATH=${OutputPath}/PLA_${DATE}
export  _REPORTS_PATH=${ReportPath}/PLA_${DATE}
export  _LOG_PATH=${ReportPath}/PLA_${DATE}

if [ ! -d "${_OUTPUTS_PATH}" ]; then 
	mkdir -p ${_OUTPUTS_PATH}
fi

if [ ! -d "${_REPORTS_PATH}" ]; then 
	mkdir -p ${_REPORTS_PATH}
    mkdir -p ${_REPORTS_PATH}/InputData
fi

if [ ! -d "${_LOG_PATH}" ]; then 
	mkdir -p ${_LOG_PATH}
fi

# Start innovus and process the do_file
innovus -stylus -init do_file.tcl

