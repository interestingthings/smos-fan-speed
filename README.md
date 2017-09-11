# smos-fan-speed

## cron command should be

```
root bash -c 'start=`date +'%s'`; while [ $(expr `date +'%s'` - $start) -lt 60 ]; do bash /root/utils/fanspeed.sh; done'
```
