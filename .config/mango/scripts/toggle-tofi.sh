#!/usr/bin/env bash

if pgrep -x "tofi-drun" > /dev/null
then
    pkill tofi-drun
else
    tofi-drun --drun-launch=true
fi
