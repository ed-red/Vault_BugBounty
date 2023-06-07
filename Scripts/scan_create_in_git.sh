#!/bin/bash

# set vars
id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"

timestamp="$(date +%s)"
scan_path="$ppath/scans/$id-$timestamp"

# exit if scope path doesnt exist
if [ ! -d "$scope_path" ]; then
  echo "Path doesn't exist"
  exit 1
fi

mkdir -p "$scan_path"
cd "$scan_path"

### PERFORM SCAN ###
echo "Starting scan against roots:"
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
