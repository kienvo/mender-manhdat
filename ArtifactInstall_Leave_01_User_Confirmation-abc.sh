#!/usr/bin/env bash

>&2 echo 'Echo to stderr from State script'
# echo artifactIntall_enter >> /data/log.txt

# start run example.py in background
pkill -f 'example.py'	# kill all running process named example.py
chmod +x /home/pi/example.py # grant execute permission
nohup /home/pi/example.py &	# run in background

exit 0
