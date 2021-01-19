#!/bin/bash

path="/uac/gds/cbai/cbai/demo/chipyard/riscv-tools-install/riscv64-unknown-elf/share/riscv-tests"
save_path="/uac/gds/cbai/cbai2/misc/SmallBoomConfig"
power_path="/uac/gds/cbai/cbai/research/synopsys-flow/build/pt-pwr/SmallBoomConfig"
class=("isa" "benchmarks")

function set_env() {
	function handler() {
		exit 1
	}

	trap 'handler' SIGINT
}

function help() {
	cat << EOF
	Usage: bash ptpx.sh [-frh]
	-f: parse failed-list.txt.bak and re-run
	-r: run in parallel
	-h: help
EOF
}

function _ptpx() {
	local bmark=$1
	local _save_path=$2
	local _bmark=$3

	if [[ ! -e ${_save_path}/vcdplus.vpd  ]]
	then
		mkdir -p ${_save_path}

		set -o pipefail && ./simv +permissive +dramsim +max-cycles=1600000 -ucli -do run.tcl \
			+verbose +vcdplusfile=${_save_path}/vcdplus.vpd \
			+permissive-off ${_bmark} </dev/null 2> \
			>(spike-dasm > ${_save_path}/${bmark}.chipyard.TestHarness.SmallBoomConfig.out) | \
			tee ${_save_path}/${bmark}.chipyard.TestHarness.SmallBoomConfig.log
		cat ${_save_path}/${bmark}.chipyard.TestHarness.SmallBoomConfig.out | grep "PASSED"
		ret=$?

		if [[ $ret == 0 ]] || true 
		then
			pushd ${_save_path}

			vpd2vcd vcdplus.vpd vcdplus.vcd
			vcd2saif -input vcdplus.vcd -output vcdplus.saif
			cd /research/d3/cbai/research/synopsys-flow/build/pt-pwr
			make build_pt_dir=${power_path}/"build-pt-"${bmark} \
				cur_build_pt_dir=${power_path}/"current-pt-"${bmark} \
				vcs_dir=${_save_path} \
				icc_dir=/research/d3/cbai/research/chipyard/vlsi/build/chipyard.TestHarness.SmallBoomConfig-ChipTop/syn-rundir
			cd -
			cd ${power_path}
			mv build-pt-${bmark} ${bmark}
			rm -rf current-pt-${bmark}
			cd -
			rm -f ${_save_path}/*.vcd ${_save_path}/*.saif

			pushd +1
			popd +1
		fi
	elif [[ -e ${_save_path}/vcdplus.vpd ]]
	then
		cat ${_save_path}/${bmark}.chipyard.TestHarness.SmallBoomConfig.out | grep "PASSED"
		ret=$?

		if [[ $ret == 0 ]] || true 
		then
			pushd ${_save_path}
			# delete redundant files
			rm -f ${_save_path}/*.vcd ${_save_path}/*.saif

			vpd2vcd vcdplus.vpd vcdplus.vcd
			vcd2saif -input vcdplus.vcd -output vcdplus.saif
			cd /research/d3/cbai/research/synopsys-flow/build/pt-pwr
			make build_pt_dir=${power_path}/"build-pt-"${bmark} \
				cur_build_pt_dir=${power_path}/"current-pt-"${bmark} \
				vcs_dir=${_save_path} \
				icc_dir=/research/d3/cbai/research/chipyard/vlsi/build/chipyard.TestHarness.SmallBoomConfig-ChipTop/syn-rundir
			cd -
			cd ${power_path}
			mv build-pt-${bmark} ${bmark}
			rm -rf current-pt-${bmark}
			cd -
			rm -f ${_save_path}/*.vcd ${_save_path}/*.saif

			pushd +1
			popd +1
		fi
	# This block is left as a candidate
	# elif [[ ! -e ${power_path}/${bmark}/reports/vcdplus.power.avg.max.report ]]
	# then
	# 	cat ${_save_path}/${bmark}.chipyard.TestHarness.SmallBoomConfig.out | grep "PASSED"
	# 	ret=$?

	# 	if [[ $ret == 0 ]] || true 
	# 	then
	# 		pushd ${_save_path}

	# 		vpd2vcd vcdplus.vpd vcdplus.vcd
	# 		vcd2saif -input vcdplus.vcd -output vcdplus.saif
	# 		cd /research/d3/cbai/research/synopsys-flow/build/pt-pwr
	# 		make build_pt_dir=${power_path}/"build-pt-"${bmark} \
	# 			cur_build_pt_dir=${power_path}/"current-pt-"${bmark} \
	# 			vcs_dir=${_save_path} \
	# 			icc_dir=/research/d3/cbai/research/chipyard/vlsi/build/chipyard.TestHarness.SmallBoomConfig-ChipTop/syn-rundir
	# 		cd -
	# 		cd ${power_path}
	# 		mv build-pt-${bmark} ${bmark}
	# 		rm -rf current-pt-${bmark}
	# 		cd -
	# 		rm -f ${_save_path}/*.vcd ${_save_path}/*.saif

	# 		pushd +1
	# 		popd +1
	# 	else
	# 		echo ${bmark} >> failed-list.txt
	# 	fi
	fi

	if [[ ! -e ${power_path}/${bmark}/reports/vcdplus.power.avg.max.report ]]
	then
		echo ${bmark} >> failed-list.txt
	fi
}

function ptpx_f() {
	file=$1
	cat $file | \
		while read bmark
		do
			_save_path=${save_path}/${bmark}
			if [[ ${bmark} == "rv64"* ]] || [[ ${bmark} == "rv32"* ]]
			then
				_bmark=${path}/isa/${bmark}
			else
				_bmark=${path}/benchmarks/${bmark}
			fi
			if [[ -f ${_bmark} ]]
			then
				_ptpx ${bmark} ${_save_path} ${_bmark} &
			else
				echo $file is wrong
				exit 1
			fi
			sleep 5
		done
}

function ptpx() {
	for ((i=0; i < ${#class[@]}; i++))
	do
		for bmark in `ls $path/${class[i]}`
		do
			if [[ ${bmark##*.} == "dump" ]] || [[ ${bmark} == "rv32"* ]]
			then
				continue
			fi
			_save_path=${save_path}/${bmark}
			_bmark=${path}/${class[i]}/${bmark}
			_ptpx ${bmark} ${_save_path} ${_bmark} &
			sleep 5
		done
	done
}

function post() {
	if [[ -f failed-list.txt ]]
	then
		mv failed-list.txt failed-list.txt.bak
	fi
}

set_env

while getopts "f:rh" arg
do
	case $arg in
		f)
			if [[ -f $OPTARG ]]
			then
				ptpx_f
				wait
				post
			else
				echo ${OPTARG} not found.
			fi
			;;
		r)
			ptpx
			wait
			post
			;;
		h | ?)
			help
			;;
		?)
			help
			;;
	esac
done

echo "done."

