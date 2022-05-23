#!/usr/bin/env bash

>&2 echo 'Echo to stderr from State script'
# echo artifactIntall_enter >> /data/log.txt

# start run example.py in background
chmod +x /home/pi/example.py # grant execute permission
nohup  &nohup /home/pi/example.py </dev/null >/dev/null 2>&1 &	# run in background

exit 0
