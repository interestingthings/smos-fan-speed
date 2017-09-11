#!/bin/bash
#root bash -c 'start=`date +'%s'`; while [ $(expr `date +'%s'` - $start) -lt 60 ]; do bash /root/utils/fanspeed.sh; done'


CONFIG_FILE="/root/config.txt"
source $CONFIG_FILE

ocTempTarget=60
ocFanSpeedMin=20

ocTempTargetUser=`echo $JSON | jq -r .ocTempTarget`
ocFanSpeedMinUser=`echo $JSON | jq -r .ocFanSpeedMin`

# Overclocking
if [ $osSeries != "NV" ]; then
exit
fi
if [ "$ocTempTargetUser" -ge 30 ] && [ "$ocTempTargetUser" -le 85 ]; then
ocTempTarget="$ocTempTargetUser"
fi
if [ "$ocFanSpeedMinUser" -ge 20 ] && [ "$ocFanSpeedMin" -le 100 ]; then
ocFanSpeedMin="$ocFanSpeedMinUser"
fi

FANS=(`nvidia-smi -a | grep -i fan | sed 's/[^0-9]*//g'`)

x=0
for ITEM in `nvidia-smi -q -d TEMPERATURE | grep "Current" | sed 's/[^0-9]*//g'`
do
FAN_UP_STEP=2
FAN_DOWN_STEP=1
GPU_TEMP="$ITEM"
GPU_FAN="${FANS[$x]}"
NEW_GPU_FAN=$GPU_FAN

DIFF=`echo "$((ocTempTarget-GPU_TEMP))" | sed 's/-//g'`

if [ $DIFF -ge 7 ]; then
FAN_UP_STEP=100
FAN_DOWN_STEP=10
elif [ $DIFF -ge 6 ]; then
FAN_UP_STEP=20
elif [ $DIFF -ge 5 ]; then
FAN_UP_STEP=10
elif [ $DIFF -ge 4 ]; then
FAN_UP_STEP=8
elif [ $DIFF -ge 3 ]; then
FAN_UP_STEP=5
elif [ $DIFF -ge 2 ]; then
FAN_UP_STEP=3
elif [ $DIFF -ge 1 ]; then
FAN_UP_STEP=1
FAN_DOWN_STEP=1
elif [ $DIFF -ge 0 ]; then
FAN_UP_STEP=0
FAN_DOWN_STEP=0
fi
if [ $GPU_TEMP -gt $((ocTempTarget)) ]; then
NEW_GPU_FAN=$(( GPU_FAN + FAN_UP_STEP ))
# echo "GPU $x temp > target temp -> gpu fan speed: $NEW_GPU_FAN"
fi
if [ $GPU_TEMP -lt $((ocTempTarget)) ]; then
NEW_GPU_FAN=$(( GPU_FAN - FAN_DOWN_STEP ))
# echo "GPU $x temp < target temp - 1 -> gpu fan speed: $NEW_GPU_FAN"
fi

if [ $NEW_GPU_FAN -le $ocFanSpeedMin ]; then
NEW_GPU_FAN=$ocFanSpeedMin
# echo "GPU $x fan speed < fan min -> gpu fan speed: $NEW_GPU_FAN"
fi

if [ $NEW_GPU_FAN -ge 100 ]; then
NEW_GPU_FAN=100
# echo "GPU $x fan speed > fan max -> gpu fan speed: $NEW_GPU_FAN"
fi
DISPLAY=:0 nvidia-settings -a "[gpu:$x]/GPUFanControlState=1" -a "[fan:$x]/GPUTargetFanSpeed=$NEW_GPU_FAN" > /dev/null
echo "GPU $x: temp: $GPU_TEMP, diff: $DIFF, fan speed: $GPU_FAN -> $NEW_GPU_FAN"

x=$((x+1))
done
echo "----------"
