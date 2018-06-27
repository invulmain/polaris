#!/usr/bin/env bash

miner stop

if [ $1 = "a" ]
then
        n=`gpu-detect AMD`
        for (( i=0; i < $n; ++i )); do
                wolfamdctrl -i $i --set-fanspeed 20
        done
        exit 0
fi

wolfamdctrl -i $1 --set-fanspeed 0
exit 0
