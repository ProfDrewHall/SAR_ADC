#!/bin/bash

# Tools Configuration
export	RunPath=`pwd`
export	BasePath=$RunPath/../..
export	HDLPath=$BasePath/Design/HDL
export	GDSPath=$BasePath/Design/GDS
export	ConfigPath=$BasePath/Design/Config
export	DesignPath=$BasePath/Design
export	OutputPath=$BasePath/TMP/DBX
export	ReportPath=$BasePath/TMP/Reports
export	TechPath=$BasePath/DigTech

# Technology Configuration
export	TTLibFile="$TechPath/tcbn65gplustc.lib"
export  TTQRCFile="$TechPath/qrcTechFile.typical"
export	TargetLib="DigitalSubsystem"
export	MAPFile="$TechPath/tsmcN65_6X1Z1U.map"
export	MLEFFile="$TechPath/tcbn65gplus_macro.lef"
export	TLEFFile="$TechPath/tsmcN65_HVH_9M_6X1Z1U_RDL.lef"

# Configurations
export	LibConfig="$TechPath/tcbn65gplus.cfg"
export  DesignConfig="$ConfigPath/DesignConfig.cfg"
