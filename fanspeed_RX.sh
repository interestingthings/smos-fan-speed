#!/bin/bash
# root bash -c 'start=`date +'%s'`; while [ $(expr `date +'%s'` - $start) -lt 60 ]; do bash /root/utils/fanspeed.sh; done'

CONFIG_FILE="/root/config.txt"
source $CONFIG_FILE

ocTempTarget=70
ocFanSpeedMin=20

ocTempTargetUser=`echo $JSON | jq -r .ocTempTarget`
ocFanSpeedMinUser=`echo $JSON | jq -r .ocFanSpeedMin`

# Overclocking
if [ $osSeries == "R" ]; then
    exit
fi
if [ "$ocTempTargetUser" -ge 30  ] && [ "$ocTempTargetUser" -le 85 ]; then
    ocTempTarget="$ocTempTargetUser"
fi
if [ "$ocFanSpeedMinUser" -ge 20  ] && [ "$ocFanSpeedMin" -le 100 ]; then
    ocFanSpeedMin="$ocFanSpeedMinUser"
fi

#przeliczenie na 255
ocFanSpeedMin=$((ocFanSpeedMin*255/100))

x=0
for ITEM in `ls -1 /sys/class/drm/card*/device/hwmon/hwmon*/pwm1`
do

    FAN_UP_STEP=20
    FAN_DOWN_STEP=10

    GPU=`echo $ITEM | sed 's/\/pwm1//g'`
    GPU_TEMP_DEV=$GPU/temp1_input
    GPU_FAN_DEV=$GPU/pwm1
    GPU_TEMP=`cat $GPU_TEMP_DEV`
    GPU_TEMP=$(($GPU_TEMP/1000))
    GPU_FAN=`cat $GPU_FAN_DEV`
    echo 1 > $GPU/pwm1_enable
    NEW_GPU_FAN=$GPU_FAN

    DIFF=`echo "$((ocTempTarget-GPU_TEMP))" | sed 's/-//g'`

if [ $DIFF -ge 7 ]; then
    FAN_UP_STEP=200
    FAN_DOWN_STEP=3
elif [ $DIFF -ge 5 ]; then
    FAN_UP_STEP=70
    FAN_DOWN_STEP=3
elif [ $DIFF -ge 4 ]; then
    FAN_UP_STEP=40
    FAN_DOWN_STEP=3
elif [ $DIFF -ge 3 ]; then
    FAN_UP_STEP=28
    FAN_DOWN_STEP=3
elif [ $DIFF -ge 2 ]; then
    FAN_UP_STEP=12
    FAN_DOWN_STEP=3
elif [ $DIFF -ge 1 ]; then
    FAN_UP_STEP=6
    FAN_DOWN_STEP=3
elif [ $DIFF -ge 0 ]; then
    FAN_UP_STEP=0
    FAN_DOWN_STEP=0
fi

if [ $GPU_TEMP -gt $((ocTempTarget)) ]; then
    NEW_GPU_FAN=$(( GPU_FAN + FAN_UP_STEP ))
fi
if [ $GPU_TEMP -lt $((ocTempTarget-1)) ]; then
    NEW_GPU_FAN=$(( GPU_FAN - FAN_DOWN_STEP ))
fi

if [ $NEW_GPU_FAN -le $ocFanSpeedMin ]; then
    NEW_GPU_FAN=$ocFanSpeedMin
fi

if [ $NEW_GPU_FAN -ge 255 ]; then
    NEW_GPU_FAN=255
fi
    echo $NEW_GPU_FAN > $GPU_FAN_DEV

x=$((x+1))
done
