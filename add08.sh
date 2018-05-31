#!/usr/bin/env bash

. colors

AMD_OC_CONF="/hive-config/amd-oc.conf"

n=`gpu-detect AMD`

if [[ $n == 0 ]]; then
        echo "No AMD cards detected, exiting"
        exit
fi

if [ ! -f $AMD_OC_CONF ]; then
        echo -e "ERROR: $AMD_OC_CONF does not exist"
        exit
fi

source $AMD_OC_CONF

#pad arrays
[[ ! -z $CORE_CLOCK ]] &&
CORE_CLOCK=($CORE_CLOCK) &&
for (( i=${#CORE_CLOCK[@]}; i < $n; ++i )); do
        CORE_CLOCK[$i]=${CORE_CLOCK[$i-1]}
done

[[ ! -z $CORE_VDDC ]] &&
CORE_VDDC=($CORE_VDDC) &&
for (( i=${#CORE_VDDC[@]}; i < $n; ++i )); do
    CORE_VDDC[$i]=${CORE_VDDC[$i-1]}
done

[[ ! -z $MEM_CLOCK ]] &&
MEM_CLOCK=($MEM_CLOCK) &&
for (( i=${#MEM_CLOCK[@]}; i < $n; ++i )); do
        MEM_CLOCK[$i]=${MEM_CLOCK[$i-1]}
done

[[ ! -z $MEM_STATE ]] &&
MEM_STATE=($MEM_STATE) &&
for (( i=${#MEM_STATE[@]}; i < $n; ++i )); do
        MEM_STATE[$i]=${MEM_STATE[$i-1]}
done

# nomer strapa voltasha pamyati
[[ ! -z $FAN ]] &&
FAN=($FAN) &&
for (( i=${#FAN[@]}; i < $n; ++i )); do
        FAN[$i]=${FAN[$i-1]}
done

for (( i=0; i < $n; ++i )); do

echo -e "\n${YELLOW}===${NOCOLOR} GPU ${CYAN}$i${NOCOLOR}  ${YELLOW}===${NOCOLOR}"
echo -e "${YELLOW}CORE=${CORE_CLOCK[$i]} VDDC=${CORE_VDDC[$i]} MEM=${MEM_CLOCK[$i]}${NOCOLOR}"

tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"

tek+=" --set GoldenRevision=9416"
tek+=" --set PowerTuneTable.TDC=124"
tek+=" --set PowerTuneTable.BatteryPowerLimit=150"
tek+=" --set PowerTuneTable.SmallPowerLimit=150"
tek+=" --set PowerTuneTable.MaximumPowerDeliveryLimit=150"
tek+=" --set ThermalController.FanMaxRPM=52"

tek+=" --set VddcLookupTable.Entries[7].Vdd=${CORE_VDDC[$i]}"
#tek+=" --set VddcLookupTable.Entries[${FAN[$i]}].Vdd=${CORE_VDDC[$i]}"
tek+=" --set MemClockDependencyTable.Entries[${MEM_STATE[$i]}].Vddc=7"
tek+=" --set SocClockDependencyTable.Entries[7].SocClock=${CORE_CLOCK[$i]}00"
tek+=" --set MemClockDependencyTable.Entries[${MEM_STATE[$i]}].MemClock=${MEM_CLOCK[$i]}00"
tek+=" --write-card-pp"
#echo $tek
eval $tek

done

