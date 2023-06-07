#!/bin/bash

# set vars
id="$1"
ppath="$HOME/recons"
scope_path="$ppath/scope/$id"

timestamp="$(date +%s)"
scan_path="$ppath/scans/$id-$timestamp"

# check if ppath exists, if not create it
if [ ! -d "$ppath" ]; then
  mkdir -p "$ppath"
fi

# check if scope_path exists, if not create it
if [ ! -d "$scope_path" ]; then
  mkdir -p "$scope_path"
fi

# check if scan_path exists, if not create it
if [ ! -d "$scan_path" ]; then
  mkdir -p "$scan_path"
fi

cd "$scan_path"

### PERFORM SCAN ###
echo "Starting scan against roots:"
touch "$scope_path/roots.txt"
cat "$scope_path/roots.txt"
cp -v "$scope_path/roots.txt" "$scan_path/roots.txt"
sleep 3

### ADD SCAN LOGIC HERE ###

# calculate time diff
end_time=$(date +%s)
seconds="$(expr $end_time - $timestamp)"
time=""

if [[ "$seconds" -gt 59 ]]
then
  minutes=$(expr $seconds / 60)
  time="$minutes minutes"
else
  time="$seconds seconds"
fi

echo "Scan $id took $time"
#echo "Scan $id took $time" | notify
