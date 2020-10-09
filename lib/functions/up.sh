#!/bin/sh
# Copyright (C) 2012-2014 OpenWrt.org
# Edited by george to output dsl status in order to log it
# This script reports if line is up

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
# Is the line up? Or what state is it in?
#
line_state() {
	local lsg=$(dsl_cmd lsg)
	local ls=$(dsl_val "$lsg" nLineState);
	local s;

	case "$ls" in
		"0x0")		s="not initialized" ;;
		"0x1")		s="exception" ;;
		"0x10")		s="not updated" ;;
		"0xff")		s="idle request" ;;
		"0x100")	s="idle" ;;
		"0x1ff")	s="silent request" ;;
		"0x200")	s="silent" ;;
		"0x300")	s="handshake" ;;
		"0x380")	s="full_init" ;;
		"0x400")	s="discovery" ;;
		"0x500")	s="training" ;;
		"0x600")	s="analysis" ;;
		"0x700")	s="exchange" ;;
		"0x800")	s="showtime_no_sync" ;;
		"0x801")	s="showtime_tc_sync" ;;
		"0x900")	s="fastretrain" ;;
		"0xa00")	s="lowpower_l2" ;;
		"0xb00")	s="loopdiagnostic active" ;;
		"0xb10")	s="loopdiagnostic data exchange" ;;
		"0xb20")	s="loopdiagnostic data request" ;;
		"0xc00")	s="loopdiagnostic complete" ;;
		"0x1000000")	s="test" ;;
		"0xd00")	s="resync" ;;
		"0x3c0")	s="short init entry" ;;
		"")		s="not running daemon"; ls="0xfff" ;;
		*)		s="unknown" ;;
	esac

#	if [ "$action" = "lucistat" ]; then
#		echo "dsl.line_state_num=$ls"
#		echo "dsl.line_state_detail=\"$s\""
#		if [ "$ls" = "0x801" ]; then
#			echo "dsl.line_state=\"UP\""
#		else
#			echo "dsl.line_state=\"DOWN\""
#		fi
#	else
		if [ "$ls" = "0x801" ]; then
#			echo "Line State:                               UP [$ls: $s]"
                        echo "UP"
		else
#			echo "Line State:                               DOWN [$ls: $s]"
                        echo "DOWN $ls"
		fi
#	fi
}
line_state
