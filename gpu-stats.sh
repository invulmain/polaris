#!/usr/bin/env bash
#GPU temps and fans
#Sorted by pci bus id. It was hard...

###Usage: gpu-stats internal|amd|nvidia



busids=()
brand=()
temps=()
fans=()
load=()
power=()

bus_temp_fan=()

#bus temp fan load
function putstats {
	#echo $1
	#echo $2
	#temps+=($1)
	#fans+=($2)
	bus_temp_fan+=("$1;$2;$3;$4;$5;$6")
	#echo "$1 $2 $3 $4 $5 $6"
}


function internal_stats {
	#detect not NVIDIA and not AMD cards, might be only one internal
	local cards=`lspci | grep -E "VGA|3D controller" | grep -vE "NVIDIA|AMD"`
	cards+=`lspci | grep -E "nForce"` #add internal nForce gpu to the list
	while read -r line; do
		[[ -z $line ]] && continue

		busid=`echo $line | awk '{print $1}'`

		[[ ! -z $busid ]] &&
			putstats $busid "cpu" "0" "0" "0" "0"
	done <<< "$cards"
}

#AMD cards stats
function amd_stats {
	#cardcount=0;
	#/sys/class/drm/card7/device/hwmon/hwmon10
	for hwmondir in /sys/class/drm/card*/device/hwmon/hwmon*/ ; do
		#echo $hwmondir
		#if there are no dirs then there will be 1 string item in loop, skip it
		[[ ! -e $hwmondir ]] && continue

		[[ $hwmondir =~ \/card([0-9a-z]+)\/ ]]

		if [[ -n ${BASH_REMATCH[1]} ]]; then
			cardno=${BASH_REMATCH[1]}
		else
			echo "$0: Unknown card number in $hwmondir"
			continue
		fi

		busid=`realpath /sys/class/drm/card$cardno | rev | cut -d '/' -f 3 | rev | awk '{print tolower($0)}'`
		busid=${busid#0000:} #trim prefix

		speed="0"
		[[ -e ${hwmondir}pwm1_max ]] && fanmax=`head -1 ${hwmondir}pwm1_max` || fanmax=0
		if [ $fanmax -gt 0 ]; then
			[[ -e ${hwmondir}pwm1 ]] && fan=`head -1 ${hwmondir}pwm1` || fan=0
			speed=$(( fan * 100 / fanmax ))
			#echo "GPU $cardno $busid ${temp}C $speed%"
			#echo "${temp}, $speed"
		else
			echo "Error: fanmax unknown for card $cardno" >&2
		fi

		temp="0"
		if [[ -e ${hwmondir}temp1_input ]]; then
			temp=`head -1 ${hwmondir}temp1_input`
			temp=$(( temp / 1000 ))
		else
			echo "Error: temp unknown for card $cardno" >&2
		fi


		local power='0'
		[[ -e /sys/kernel/debug/dri/$cardno/amdgpu_pm_info ]] &&
			power=`cat /sys/kernel/debug/dri/$cardno/amdgpu_pm_info | grep -m1 '(average GPU)' | awk '{printf("%d", $1)}'`
		# inv
			[[ -z power ]] && power='0'
			power_vddc=`cat /sys/kernel/debug/dri/$cardno/amdgpu_pm_info | grep -m1 '(VDDC)' | awk '{printf("%d", $1)}'`
			[[ -z power_vddc ]] && power_vddc='0'
			power=$[$power + $power_vddc]
		# -inv

		[[ -z power ]] && power='0'


		putstats $busid "amd" $temp $speed "0" "$power"


		#cardcount=$(( cardcount + 1 ))
	done
}

function nvidia_stats {
	#72, 81, 00000000:01:00.0
	#71, 54, 00000000:03:00.0
	#68, 46, 00000000:06:00.0
	#68, 83, 00000000:07:00.0
	#timeout should be high enough on high system load
	stats=`timeout -s9 10 nvidia-smi --format=csv,noheader,nounits --query-gpu=temperature.gpu,fan.speed,gpu_bus_id,utilization.gpu,power.draw`

	[[ $? > 0 ]] && return

	#stats='Unable to determine the device handle for GPU 0000:05:00.0: GPU is lost. Reboot the system to recover this GPU'
	#Exec failed, exitcode=15

	#NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.
	[[ $stats =~ NVIDIA-SMI ]] && return

	#echo -e "$stats"
	while read -r s; do
		local busid=`awk -F', ' '{print tolower($3)}' <<< $s`
		busid=${busid#00000000:} #trim prefix
		local temp=`awk -F', ' '{print $1}' <<< $s`
		local fan=`awk -F', ' '{print $2}' <<< $s`
		local load=`awk -F', ' '{print $4}' <<< $s`
		local power=`awk -F', ' '{printf("%d", $5)}' <<< $s`
		[[ $power == "[Not Supported]" ]] && power="0"
		putstats "$busid" "nvidia" "$temp" "$fan" "$load" "$power"
		#echo "$busid" "nvidia" "$temp" "$fan" "$load" "$power"
	done <<<"$stats"
}


function all_stats {
	internal_stats
	amd_stats
	nvidia_stats
}


[[ -z $1 ]] &&
	all_stats ||
	eval ${1}_stats

#echo "# ${#bus_temp_fan[@]}"
#echo "* ${bus_temp_fan[*]}"
#echo "1) ${bus_temp_fan[1]}"
#echo "2) ${bus_temp_fan[2]}"
#echo "bus_temp_fan: ${bus_temp_fan[@]}"

sorted=$(for s in "${bus_temp_fan[@]}"; do echo "$s"; done | sort)
#echo "$sorted"

while read -r s; do
	plines=$(tr ';' '\n' <<< "$s")
	readarray -t params <<< "$plines"

	## declare -p params
	## while read -r p; do
	##	echo "$p" -
	## done <<< `tr ';' "\n" <<< "$s"`
	## params=(${s//;/ })

	busids+=("${params[0]}")
	brand+=("${params[1]}")
	temps+=("${params[2]}")
	fans+=("${params[3]}")
	load+=("${params[4]}")
	power+=("${params[5]}")
done <<< "$sorted"

#echo "Temp: ${temps[@]}"
#echo "Fans: ${fans[@]}"
#echo "Power: ${power[@]}"

jsontemps=`printf '%s\n' "${temps[@]}" | jq --raw-input . | jq --slurp -c .`
jsonfans=`printf '%s\n' "${fans[@]}" | jq --raw-input . | jq --slurp -c .`
jsonload=`printf '%s\n' "${load[@]}" | jq --raw-input . | jq --slurp -c .`
jsonpower=`printf '%s\n' "${power[@]}" | jq --raw-input . | jq --slurp -c .`
jsonbusids=`printf '%s\n' "${busids[@]}" | jq --raw-input . | jq --slurp -c .`
jsonbrand=`printf '%s\n' "${brand[@]}" | jq --raw-input . | jq --slurp -c .`


jq -c -n \
--argjson temp "$jsontemps" \
--argjson fan "$jsonfans" \
--argjson load "$jsonload" \
--argjson power "$jsonpower" \
--argjson busids "$jsonbusids" \
--argjson brand "$jsonbrand" \
'{$temp, $fan, $load, $power, $busids, $brand}'



#
# nvidia-smi --query-gpu=index,gpu_bus_id,gpu_name,power.draw,clocks.sm,clocks.mem,clocks.gr,utilization.gpu,utilization.memory --format=csv
#
#index, timestamp, power.draw [W], clocks.current.sm [MHz], clocks.current.memory [MHz], clocks.current.graphics [MHz]
#0, 2017/10/04 00:54:27.644, 98.29 W, 1974 MHz, 4151 MHz, 1974 MHz
#1, 2017/10/04 00:54:27.650, 138.22 W, 2075 MHz, 4252 MHz, 2075 MHz
#2, 2017/10/04 00:54:27.662, 96.14 W, 1961 MHz, 4151 MHz, 1961 MHz
#3, 2017/10/04 00:54:27.667, 193.98 W, 2025 MHz, 5481 MHz, 2025 MHz
#4, 2017/10/04 00:54:27.674, 193.30 W, 2037 MHz, 5481 MHz, 2037 MHz
#5, 2017/10/04 00:54:27.679, 133.95 W, 2050 MHz, 4252 MHz, 2050 MHz
