#!/bin/bash

# Configuring the design setup in the current shell
source ../S0.0_Setup/Setup.sh

# Creating run directories
export  DATE=$(date '+%Y%m%d_%H%M')
export  _OUTPUTS_PATH=${OutputPath}/SYN_${DATE}
export  _REPORTS_PATH=${ReportPath}/SYN_${DATE}
export  _LOG_PATH=${ReportPath}/SYN_${DATE}

if [ ! -d "${_OUTPUTS_PATH}" ]; then 
	mkdir -p ${_OUTPUTS_PATH}
fi

if [ ! -d "${_REPORTS_PATH}" ]; then 
	mkdir -p ${_REPORTS_PATH}
fi

if [ ! -d "${_LOG_PATH}" ]; then 
	mkdir -p ${_LOG_PATH}
fi

if [ -d "${SynthPath}" ]; then 
	rm -rf ${SynthPath}
fi

# Start genus and process the do_file
genus -f do_file.tcl

# lec -xl -nogui -dofile rtl2final.do
