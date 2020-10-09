#!/bin/sh
# Copyright (C) 2012-2014 OpenWrt.org

if [ "$( which vdsl_cpe_control )" ]; then
	XDSL_CTRL=vdsl_cpe_control
else
	XDSL_CTRL=dsl_cpe_control
fi

#
# Basic functions to send CLI commands to the vdsl_cpe_control daemon
#
dsl_cmd() {
	killall -q -0 ${XDSL_CTRL} && (
		lock /var/lock/dsl_pipe
		echo "$@" > /tmp/pipe/dsl_cpe0_cmd
		cat /tmp/pipe/dsl_cpe0_ack
		lock -u /var/lock/dsl_pipe
	)
}
dsl_val() {
	expr "$1" : '.*'$2'=\([-\.[:alnum:]]*\).*'
}
dsl_string() {
	expr "$1" : '.*'$2'=(\([A-Z0-9,]*\))'
}

#
# Simple divide by 10 routine to cope with one decimal place
#
dbt() {
	local a=$(expr $1 / 10)
	local b=$(expr $1 % 10)
	echo "${a}.${b#-}"
}
#
# Take a number and convert to k or meg
#
scale() {
	local val=$1
	local a
	local b

	if [ "$val" -gt 1000000 ]; then
		a=$(expr $val / 1000)
		b=$(expr $a % 1000)
		a=$(expr $a / 1000)
		printf "%d.%03d Mb" ${a} ${b}
	elif [ "$val" -gt 1000 ]; then
		a=$(expr $val / 1000)
		printf "%d Kb" ${a}
	else
		echo "${val} b"
	fi
}

scale_latency() {
	local val=$1
	local a
	local b

	a=$(expr $val / 100)
	b=$(expr $val % 100)
	printf "%d.%d ms" ${a} ${b}
}

scale_latency_us() {
	local val=$1

	expr $val \* 10
}


#
# Errors
#
errors() {
	local lsctg
	local dpctg
	local fecsf
	local fecsn
	local esf
	local esn
	local sesf
	local sesn
	local lossf
	local lossn
	local uasf
	local uasn

	local crc_pf
	local crc_pn
	local crcp_pf
	local crcp_pn
	local hecf
	local hecn

	lsctg=$(dsl_cmd pmlsctg 1)
	fecsf=$(dsl_val "$lsctg" nFECS)
	esf=$(dsl_val "$lsctg" nES)
	sesf=$(dsl_val "$lsctg" nSES)
	lossf=$(dsl_val "$lsctg" nLOSS)
	uasf=$(dsl_val "$lsctg" nUAS)

	lsctg=$(dsl_cmd pmlsctg 0)
	fecsn=$(dsl_val "$lsctg" nFECS)
	esn=$(dsl_val "$lsctg" nES)
	sesn=$(dsl_val "$lsctg" nSES)
	lossn=$(dsl_val "$lsctg" nLOSS)
	uasn=$(dsl_val "$lsctg" nUAS)

	dpctg=$(dsl_cmd pmdpctg 0 1)
	hecf=$(dsl_val "$dpctg" nHEC)
	crc_pf=$(dsl_val "$dpctg" nCRC_P)
	crcp_pf=$(dsl_val "$dpctg" nCRCP_P)

	dpctg=$(dsl_cmd pmdpctg 0 0)
	hecn=$(dsl_val "$dpctg" nHEC)
	crc_pn=$(dsl_val "$dpctg" nCRC_P)
	crcp_pn=$(dsl_val "$dpctg" nCRCP_P)
	if [ "$1" == "fecs" ]; then
		echo "FECS Near: ${fecsn} Far: ${fecsf}"
        elif [ "$1" == "es" ]; then   
		echo "ES Near: ${esn} Far: ${esf}"
        elif [ "$1" == "ses" ]; then
		echo "SES Near: ${sesn} Far: ${sesf}"
        elif [ "$1" == "loss" ]; then
		echo "LOSS Near: ${lossn} Far: ${lossf}"
        else
                echo "FECS Near: ${fecsn} Far: ${fecsf}"
                echo "ES Near: ${esn} Far: ${esf}"
                echo "SES Near: ${sesn} Far: ${sesf}"  
                echo "Loss of Signal Seconds (LOSS):            Near: ${lossn} / Far: ${lossf}"    
		echo "Unavailable Seconds (UAS):                Near: ${uasn} / Far: ${uasf}"
		echo "Header Error Code Errors (HEC):           Near: ${hecn} / Far: ${hecf}"
		echo "Non Pre-emtive CRC errors (CRC_P):        Near: ${crc_pn} / Far: ${crc_pf}"
		echo "Pre-emtive CRC errors (CRCP_P):           Near: ${crcp_pn} / Far: ${crcp_pf}"
	fi
}

errors $1
