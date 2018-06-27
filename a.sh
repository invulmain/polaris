#!/usr/bin/env bash
. colors

n=`gpu-detect AMD`

if [ -n "$1" ] ; then

miner stop 1>/dev/null

if [ $1 = "a" ]
then
        for (( i=0; i < $n; ++i )); do
                wolfamdctrl -i $i --set-fanspeed 20 1>/dev/null
        done
else
        wolfamdctrl -i $1 --set-fanspeed 0 1>/dev/null
fi
fi

echo -e "${YELLOW}=====================${NOCOLOR}"

for (( i=0; i < $n; ++i )); do
        tekfan=`wolfamdctrl -i $i --show-fanspeed`
        echo -e "GPU ${CYAN}$i${NOCOLOR} fan: $tekfan"
done

echo -e "${YELLOW}=====================${NOCOLOR}"

exit 0
