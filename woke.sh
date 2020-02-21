#!/bin/bash

# This script tries to determine the time when you woke up.
# Of course, it only applies if you turn your computer on not too long ago after getting out of bed.
# If not, it might still be useful as an indicator of when you turned your computer on.
# It works by getting information from journalctrl, sleep-resume dates and boot dates.
# It then loops through them and tries to find when the difference is above a certain gap (5 hours by default, it can be configured with the -g flag).
# Then it prints the time and "timeago" information of when you probably woke up.

gap=$((8 * 3600))

while [ ! $# -eq 0 ]
do
    case "$1" in
        --help | -h)
            printf "Version: 1.2.1\nFlags:\n\t-g or --gap: Specifies the chunks of time between two dates to determine when you probably woke up (default is 5)\n"
            exit
            ;;
        --gap | -g)
            gap=$(($2 * 3600))
            ;;
    esac
    shift
done

current_date=$(date +%s)
readarray -t sleep_dates < <(journalctl -o short-unix -t systemd-sleep | grep resumed | tail -50 | awk -F. '{print $1}')
readarray -t boot_dates < <(journalctl --list-boots | tail -50 | awk '{ d2ts="date -d \""$3" "$4" " $5"\" +%s"; d2ts | getline $(NF+1); close(d2ts)} 1' | awk 'NF>1{print $NF}')
dates=( "${sleep_dates[@]}" "${boot_dates[@]}" )
dates=("$current_date" "${dates[@]}" )
unset dates[0]
readarray -t sorted_dates < <(printf '%s\n' "${dates[@]}" | sort)

for (( i=${#sorted_dates[@]}-1 ; i>=0; i-- )); do
    diff=$((sorted_dates[i] - sorted_dates[i - 1]))
    diff2=$((sorted_dates[i - 1] - sorted_dates[i - 2]))
    
    if [ "$diff" -gt "$gap" ] && [ "$diff2" -gt "$gap" ]; then
        sdate=$(date --date @${sorted_dates[i]} +"%r")
        diff3=$((current_date - sorted_dates[i]))
        hours_ago=$(echo "scale=2; ${diff3}/3600" | bc)
        whole_hours=$(echo "(${hours_ago})/1" | bc)
        decimals=$(echo "${hours_ago}" | grep -Eo "\.[0-9]+$")
        minutes_ago=$(echo "(${decimals}*60)/1" | bc)

        if [ "$whole_hours" -eq "1" ];
        then
            shours="hour"
        else
            shours="hours"
        fi

        if [ "$minutes_ago" -eq "1" ];
        then
            sminutes="minute"
        else
            sminutes="minutes"
        fi

        message="${whole_hours} ${shours} and ${minutes_ago} ${sminutes} ago ( ${sdate} )"
        echo "$message"
        break
    fi
done