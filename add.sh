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



for (( i=0; i < $n; ++i )); do

echo -e "\n${YELLOW}===${NOCOLOR} GPU ${CYAN}$i${NOCOLOR} ${YELLOW}===${NOCOLOR}"

# VddcLookupTable[1-15].Vdd
echo -e "${YELLOW}VddcLookupTable[1-14]=${CORE_VDDC[$i]}${NOCOLOR}"
tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
for (( j=1; j < 15; ++j )); do
tek+=" --set VddcLookupTable.Entries[$j].Vdd=${CORE_VDDC[$i]}"
done
tek+=" --write-card-pp"
#echo $tek
eval $tek
echo -e "${YELLOW}VddcLookupTable[15]=${CORE_VDDC[$i]}${NOCOLOR}"
tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp --set VddcLookupTable.Entries[15].Vdd=${CORE_VDDC[$i]} --write-card-pp"
#echo $tek
eval $tek

# VddGfxLookupTable[0-7].Vdd
#echo -e "${YELLOW}VddGfxLookupTable[0-7].Vdd=${CORE_VDDC[$i]}${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#for (( j=0; j < 8; ++j )); do
#tek+=" --set VddGfxLookupTable.Entries[$j].Vdd=${CORE_VDDC[$i]}"
#done
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

## MMDependencyTable[0-7].VddcGfxOffset=0
#echo -e "${YELLOW}MMDependencyTable[0-7].VddcGfxOffset=0${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#for (( j=0; j < 8; ++j )); do
#tek+=" --set MMDependencyTable.Entries[$j].VddcGfxOffset=0"
#done
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

## MemClockDependencyTable[0-1].Vddci
#echo -e "${YELLOW}MemClockDependencyTable[0-1].Vddci=${CORE_VDDC[$i]}${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#for (( j=0; j < 2; ++j )); do
#tek+=" --set MemClockDependencyTable.Entries[$j].Vddci=${CORE_VDDC[$i]}"
#done
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

# MemClockDependencyTable[2].Vddci
#echo -e "${YELLOW}MemClockDependencyTable[2].Mvdd=${CORE_VDDC[$i]}${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#tek+=" --set MemClockDependencyTable.Entries[2].Vddci=${CORE_VDDC[$i]}"
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

## MemClockDependencyTable[0-1].Mvdd
#echo -e "${YELLOW}MemClockDependencyTable[0-1].Mvdd=${CORE_VDDC[$i]}${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#for (( j=0; j < 2; ++j )); do
#tek+=" --set MemClockDependencyTable.Entries[$j].Mvdd=${CORE_VDDC[$i]}"
#done
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

## MemClockDependencyTable[2].Mvdd
#echo -e "${YELLOW}MemClockDependencyTable[2].Mvdd=${CORE_VDDC[$i]}${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#tek+=" --set MemClockDependencyTable.Entries[2].Mvdd=${CORE_VDDC[$i]}"
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

## SocClockDependencyTable[4-7].SocClock=115000
#echo -e "${YELLOW}SocClockDependencyTable[4-7].SocClock=${CORE_CLOCK[$i]}${NOCOLOR}"
#tek="/home/user/amdtweak/amdtweak --verbose --card $i --read-card-pp"
#for (( j=3; j < 8; ++j )); do
#tek+=" --set SocClockDependencyTable.Entries[$j].SocClock=${CORE_CLOCK[$i]}00"
#done
#tek+=" --write-card-pp"
##echo $tek
#eval $tek

done

