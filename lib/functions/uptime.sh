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
# Work out how long the line has been up
#
line_uptime() {
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


	if [ "$action" = "lucistat" ]; then
		echo "dsl.line_uptime=${et}"
		echo "dsl.line_uptime_s=\"${rc}\""
	else

		echo "Line Uptime Seconds:                      ${et}"
		echo "Line Uptime:                              ${rc}"
	fi
}

line_uptime
