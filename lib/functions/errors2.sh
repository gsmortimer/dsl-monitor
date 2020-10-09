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
	

        local ccsg 
        local et   
        local etr  
        local d    
        local h    
        local m    
        local s    
        local rc=""
        ccsg=$(dsl_cmd pmccsg 0 0 0)      
        et=$(dsl_val "$ccsg" nElapsedTime)
        [ -z "$et" ] && et=0
        d=$(expr $et / 86400)  
        etr=$(expr $et % 86400)
        h=$(expr $etr / 3600)  
        etr=$(expr $etr % 3600)
        m=$(expr $etr / 60)
        s=$(expr $etr % 60)
        [ "${d}${h}${m}${s}" -ne 0 ] && rc="${s}s"  
        [ "${d}${h}${m}" -ne 0 ] && rc="${m}m ${rc}"
        [ "${d}${h}" -ne 0 ] && rc="${h}h ${rc}"
        [ "${d}" -ne 0 ] && rc="${d}d ${rc}"
        [ -z "$rc" ] && rc="down"
#                echo "Line Uptime Seconds:                      ${et}"
#                echo "Line Uptime:                              ${rc}"
	
        echo "Near: FECS: ${fecsn} ES: ${esn} SES: ${sesn} LOSS: ${lossn} UAS: ${uasn} Far: FECS: ${fecsf} ES: ${esf} SES: ${sesf} LOSS: ${lossf} UAS: ${uasf} UP:${et}"
}

errors $1
